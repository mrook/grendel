unit fight;

interface

uses
    Math,
    SysUtils,
    area,
    constants,
    skills,
    conns,
    mudsystem,
    mudthread,
    dtypes,
    util,
    chars;

{ damage types }
const TYPE_UNDEFINED=-1;
      TYPE_HIT=5000;
      TYPE_SLAY=6000;
      TYPE_SILENT=6001;

{ fighting constants }
const FG_NONE=0;
      FG_PUNCH=1;
      FG_SLASH=2;      { gsn_slashing }
      FG_PIERCE=3;     { gsn_piercing }
      FG_CLEAVE=4;     { gsn_slashing }
      FG_BLAST=5;
      FG_CRUSH=6;      { gsn_concussion }
      FG_BITE=7;
      FG_CLAW=8;
      FG_WHIP=9;       { gsn_whipping }
      FG_STAB=10;      { gsn_piercing }
      FG_GAZE=11;      { gaze from a spirit? }
      FG_BREATH=12;    { breath }
      FG_STING=13;     { sting (bee, fly) }

const attack_table:array[FG_NONE..FG_STING,1..2] of string=(('nothing','nothings'),
                                                      ('punch','punches'),
                                                      ('slash','slashes'),
                                                      ('pierce','pierces'),
                                                      ('cleave','cleaves'),
                                                      ('blast','blasts'),
                                                      ('crush','crushes'),
                                                      ('bite','bites'),
                                                      ('claw','claws'),
                                                      ('whip','whips'),
                                                      ('stab','stabs'),
                                                      ('gaze','gazes'),
                                                      ('breath','breaths'),
                                                      ('sting','stings'));

const
     dual_flip : boolean = false;

procedure stopfighting(ch : GCharacter);
procedure death_cry(ch, killer : GCharacter);

procedure gain_xp(ch : GCharacter; xp : cardinal);

function damage(ch, oppnt : GCharacter; dam : integer; dt : integer) : integer;
function one_hit(ch, victim : GCharacter) : integer;
function in_melee(ch, vict : GCharacter) : boolean;
procedure multi_hit(ch, vict : GCharacter);

procedure update_fighting;

implementation

uses
    progs,
    timers,
    update;

procedure stopfighting(ch : GCharacter);
var vict : GCharacter;
    node : GListNode;
begin
  node := char_list.head;

  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.fighting = ch) then
      begin
      vict.fighting:=nil;
      vict.position:=POS_STANDING;
      end;

    node := node.next;
    end;

  ch.fighting := nil;
  ch.position := POS_STANDING;
  // ch.fought_by.clear;
end;

procedure death_cry(ch, killer : GCharacter);
var chance:integer;
    s_room : GRoom;
    vict : GCharacter;
    pexit : GExit;
    node_exit, node_char : GListNode;
begin
  node_exit := ch.room.exits.head;

  while (node_exit <> nil) do
    begin
    pexit := node_exit.element;

    s_room := findRoom(pexit.vnum);

    node_char := s_room.chars.head;

    while (node_char <> nil) do
      begin
      vict := node_char.element;

      vict.sendBuffer('You hear a chilling death cry.'#13#10);

      node_char := node_char.next;
      end;

    node_exit := node_exit.next;
    end;

  chance:=random(14);
  if (ch.room = killer.room) then
    case chance of
      1,2,3: act(AT_REPORT,'$n falls to the ground... DEAD.',false,ch,nil,killer,TO_VICT);
      4,5,6: act(AT_REPORT,'$n splatters blood on your armor.',false,ch,nil,killer,TO_VICT);
      7,8,9: act(AT_REPORT,'$n screams out in terror and dies.',false,ch,nil,killer,TO_VICT);
       else act(AT_REPORT,'You hear $n''s death cry.',false,ch,nil,killer,TO_VICT);
    end;

  act(AT_REPORT,'You hear $n''s death cry.',false,ch,nil,killer,TO_NOTVICT);
end;

procedure gain_xp(ch : GCharacter; xp : cardinal);
var
   hp_gain,mv_gain,ma_gain : integer;
begin
  if (ch.IS_NPC) or (ch.IS_IMMORT) then exit;

  { no message here, could spam a level 500 off the floor - Grimlord }

  if (ch.level >= LEVEL_MAX) then
    exit;

  with ch do
    begin
    inc(player^.xptot,xp);
    dec(player^.xptogo,xp);

    while (player^.xptogo<=0) do
      begin
      act(AT_WHITE,'>> You have advanced a level!',false,ch,nil,nil,TO_CHAR);

      hp_gain:=(ability.con div 4)+random(6)-3;
      mv_gain:=ability.dex div 4;
      if odd(level) then
        ma_gain:=round((ability.int+ability.wis)/10)
      else
        ma_gain:=0;

      act(AT_REPORT, 'You gain $B$1' + inttostr(hp_gain) + '$A$7 health, $B$1' + inttostr(mv_gain) + '$A$7 moves and $B$1' + inttostr(ma_gain) + '$A$7 mana.', false, ch, nil, nil, TO_CHAR);
        
      with point do
        begin
        inc(max_hp,hp_gain);
        inc(max_mv,mv_gain);
        inc(max_mana,ma_gain);
        hp:=max_hp;
        mv:=max_mv;
        end;

      inc(level);
      if (level>=LEVEL_MAX) then
        begin
        level:=LEVEL_MAX;
        act(AT_WHITE,'>> You have achieved the maximum level possible!',false,ch,nil,nil,TO_CHAR);
        end;

      inc(player^.xptogo, ch.calcxp2lvl);

      point.hitroll := UMax((level div 5)+50,100);

      ch.calcRank;
      end;
    end;
end;

function get_exp_worth(ch : GCharacter) : integer;
begin
  get_exp_worth := longint(ch.level) * longint(ch.point.max_hp);
end;

function xp_compute(ch, victim : GCharacter) : cardinal;
var
   xp, range : cardinal;
begin
  if (not ch.IS_NPC) and (not victim.IS_NPC) and (ch.IS_SAME_ALIGN(victim)) then
    begin
    xp_compute:=1;
    exit;
    end;

  if (ch.IS_IMMORT) or (ch.IS_NPC) or (ch = victim) then
    begin
    xp_compute:=0;
    exit;
    end;

  xp := get_exp_worth(victim);
  range := URange(1, (victim.level - ch.level) + 10,13);
  xp_compute := (xp*range) div 10;

//  xp_compute := UMin((victim.level - ch.level + 1) * 20, 1);
end;

function findDamage(dam : integer) : GDamMessage;
var
   node : GListNode;
   dm : GDamMessage;
begin
  findDamage := nil;

  node := dm_msg.head;

  while (node <> nil) do
    begin
    dm := node.element;

    if (dam >= dm.min) and (dam <= dm.max) then
      begin
      findDamage := dm;
      exit;
      end;

    node := node.next;
    end;
end;

function damage(ch, oppnt : GCharacter; dam : integer; dt : integer) : integer;
var xp,r,dameq:integer;
    damobj : GObject;
    dm : GDamMessage;
    a : array[1..3] of string;
    s1, s2 : string;
begin
  damage := RESULT_NONE;

  if (ch.CHAR_DIED) then
    begin
    damage := RESULT_CHARDIED;
    exit;
    end;

  if (oppnt.CHAR_DIED) then
    begin
    damage := RESULT_VICTDIED;
    exit;
    end;

  if (ch.position = POS_BASHED) then
    begin
    damage := RESULT_CHARBASHED;
    exit; { can't fight when bashed! }
    end;

  if (ch.room <> oppnt.room) and (dt <> TYPE_SILENT) then
    begin
    ch.fighting := nil;
    ch.position := POS_STANDING;
    oppnt.fighting := nil;
    oppnt.position := POS_STANDING;
    damage := RESULT_VICTDIED;
    exit;
    end;

  if (ch.position <> POS_FIGHTING) and (ch.position <> POS_CASTING)
   and (oppnt <> ch) then
    begin
    ch.position := POS_FIGHTING;
    ch.fighting := oppnt;
    end;

  if (oppnt.position <> POS_FIGHTING) and (oppnt.position <> POS_BASHED) and (oppnt.position <> POS_CASTING)
   and (oppnt <> ch) then
    begin
    oppnt.position := POS_FIGHTING;
    oppnt.fighting := ch;
    end;

  if (dam > 5) and (oppnt.position = POS_CASTING) then
    begin
    act(AT_FIGHT_HIT, '$B$4OUCH$7!$A$7 You lost your concentration!',false,oppnt,nil,ch,TO_CHAR);

    unregisterTimer(oppnt, TIMER_CAST);

    oppnt.position := POS_FIGHTING;
    end;

  if (dam>10) and (dt<>TYPE_UNDEFINED) then
    begin
    dameq := random(MAX_WEAR)+1;
    damobj := oppnt.getEQ(dameq);

    if (damobj <> nil) then
      begin
      { damage the object }
      dec(dam,5);
      end
    else
      inc(dam,5);
    end;

  { check for damage type }
  dm := findDamage(dam);

  if (dm <> nil) then
    begin
    a[1] := dm.msg[1];
    a[2] := dm.msg[2];
    a[3] := dm.msg[3];
    end;

  if (dt = TYPE_UNDEFINED) then
    begin
    s1 := 'hit';
    s2 := 'hits';
    end
  else
  if (dt > TYPE_UNDEFINED) and (dt < TYPE_HIT) then
    begin
    s1 := skill_table[dt].dam_msg;
    s2 := skill_table[dt].dam_msg;
    end
  else
  if (dt>TYPE_HIT) and (dt<TYPE_SLAY) then
    begin
    s1 := attack_table[dt - TYPE_HIT, 1];
    s2 := attack_table[dt - TYPE_HIT, 2];
    end
  else
  if (dt = TYPE_SLAY) then
    begin
    s1 := 'cold breath';
    s2 := 'breaths';
    end
  else
  if (dt = TYPE_SILENT) then
    begin
    { nothing here }
    end
  else
    begin
    bugreport('damage', 'fight.pas', 'unknown damagetype ' + inttostr(dt),
              'The specified damage type is unknown.');
    exit;
    end;

  if (ch.CHAR_DIED) then
    begin
    damage:=RESULT_CHARDIED;
    exit;
    end;

  if (oppnt.CHAR_DIED) then
    begin
    damage:=RESULT_VICTDIED;
    exit;
    end;

  if (s1 <> '') and (s2 <> '') and (dt <> gsn_backstab) then
    begin
    r := pos('#w',a[1]);

    if (r <> 0) then
      begin
      delete(a[1], r, 2);
      insert(s1 + mudAnsi(AT_FIGHT_YOU), a[1], r);
      end;

    r:=pos('#W',a[1]);
    if r<>0 then
      begin
      delete(a[1],r,2);
      insert(s2 + mudAnsi(AT_FIGHT_YOU),a[1],r);
      end;

    r:=pos('#w',a[2]);
    if r<>0 then
      begin
      delete(a[2],r,2);
      insert(s1 + mudAnsi(AT_FIGHT_HIT),a[2],r);
      end;

    r:=pos('#W',a[2]);
    if r<>0 then
      begin
      delete(a[2],r,2);
      insert(s2 + mudAnsi(AT_FIGHT_HIT),a[2],r);
      end;

    r:=pos('#w',a[3]);
    if r<>0 then
      begin
      delete(a[3],r,2);
      insert(s1 + mudAnsi(AT_FIGHT),a[3],r);
      end;

    r:=pos('#W',a[3]);
    if r<>0 then
      begin
      delete(a[3],r,2);
      insert(s2 + mudAnsi(AT_FIGHT),a[3],r);
      end;

    act(AT_FIGHT_YOU,a[1],false,ch,nil,oppnt,TO_CHAR);
    act(AT_FIGHT_HIT,a[2],false,oppnt,nil,ch,TO_CHAR);
    act(AT_FIGHT,a[3],false,oppnt,nil,ch,TO_NOTVICT);
    end;

  { in a battleground, immortals should receive damage - Grimlord }
  if (not oppnt.IS_IMMORT) or ((not oppnt.IS_NPC) and oppnt.IS_IMMORT) and (oppnt.player^.bg_status = BG_PARTICIPATE) then
    dec(oppnt.point.hp, dam);

  { ermmz... you shouldn't receive xp when damaged by poison - Grimlord }
  if (oppnt <> ch) then
    xp:=round(3.1*dam)+10
  else
    xp:=0;

  if (oppnt.CHAR_DIED) then
    begin
    damage := RESULT_VICTDIED;
    exit;
    end;

  if (not ch.CHAR_DIED) then
    begin
    if (not ch.IS_IMMORT) and (not ch.IS_NPC) then
      begin
      gain_xp(ch,xp);
      inc(ch.player^.fightxp,xp);
      end;
    end
  else
    begin
    damage:=RESULT_CHARDIED;
    exit;
    end;

  if (oppnt.point.hp<0) then
    begin
    unregisterTimer(oppnt, TIMER_CAST);
    unregisterTimer(oppnt, TIMER_COMBAT);

    oppnt.position:=POS_STANDING;
    ch.position:=POS_STANDING;
    stopfighting(oppnt);
    oppnt.fighting:=nil;
    ch.fighting:=nil;

    oppnt.bash_timer:=-2;
    death_cry(oppnt,ch);

    act(AT_KILLED,'You have been killed!',false,oppnt,nil,nil,TO_CHAR);
    act(AT_KILLED,'$N has been killed!',true,ch,nil,oppnt,TO_NOTVICT);

    if (ch<>oppnt) then
      begin
      act(AT_KILLED,'$N has been killed!',false,ch,nil,oppnt,TO_CHAR);

      xp := xp_compute(ch, oppnt);

      if (not ch.IS_NPC) then
        act(AT_REPORT,'You gain ' + inttostr(xp)+' XP for the kill and '+IntToStr(ch.player^.fightxp)+' XP for fighting.',false,ch,nil,nil,TO_CHAR);

      gain_xp(ch,xp);
      end;

    if (oppnt.IS_NPC) then
      begin
      deathTrigger(oppnt, ch);

      { if switched, let go }
      if (oppnt.conn <> nil) then
        interpret(oppnt, 'return sub');

      oppnt.die;

     if (not ch.IS_NPC) then
        begin
        if (IS_SET(ch.player^.cfg_flags,CFG_AUTOLOOT)) then
          interpret(ch, 'get all ''corpse of ' + oppnt.name^ + '''');

        if (IS_SET(ch.player^.cfg_flags,CFG_AUTOSAC)) then
          interpret(ch, 'sac ''corpse of ' + oppnt.name^ + '''');
        end;
      end
    else
      begin
      oppnt.die;

      { Regain 10% of xp needed when killed by NPC,
        4% when killed by PC  - Grimlord}
      if (ch.IS_NPC) then
        begin
        inc(oppnt.player^.xptogo, oppnt.calcxp2lvl div 10);
        ch.hunting := nil;
        REMOVE_BIT(ch.act_flags, ACT_HUNTING);
        end
      else
        begin
        inc(ch.kills);

        { get a point when killing one in bg - Grimlord }
        if (ch.player^.bg_status = BG_PARTICIPATE) then
          inc(ch.player^.bg_points);

        if (oppnt.player^.bg_status <> BG_PARTICIPATE) then
          inc(oppnt.player^.xptogo,  oppnt.calcxp2lvl div 4);

        if (IS_SET(ch.player^.cfg_flags, CFG_AUTOSCALP)) then
          interpret(ch, 'scalp corpse of '+oppnt.name^);
        end;

      if (oppnt.clan <> nil) then
        to_channel(oppnt, '*CLAN NOTIFY*: '+oppnt.name^+' has been'+
        ' killed by '+ch.name^+'!',CHANNEL_CLAN,AT_WHITE);

      if (not ch.IS_NPC) then
        begin
        if (ch.clan<>nil) then
          to_channel(ch, '*CLAN NOTIFY*: '+ch.name^+' has just'+
          ' killed '+oppnt.name^+'!',CHANNEL_CLAN,AT_WHITE);

        if not (ch.IS_SAME_ALIGN(oppnt)) then
          begin
          if (ch.player^.taunt <> '') then
            act(AT_WHITE, '$N taunts: ' + ch.player^.taunt, false, oppnt, nil, ch, TO_CHAR);

          // update_trophy(ch,oppnt);
          end;
        end;
      end;

    damage := RESULT_VICTDIED;
    exit;
    end;

  if (not oppnt.IS_NPC) then
   if (oppnt.point.hp <= oppnt.player^.wimpy) then
    interpret(oppnt,'flee');
end;

function one_hit(ch, victim : GCharacter) : integer;
var chance,ds,dam:integer;
    wield : GObject;
    fly_bonus, prof_bonus, prof_gsn : integer;
    vict_ac : integer;
    hit_roll, roll : integer;
begin
  one_hit := RESULT_NONE;

  if (ch.CHAR_DIED) then
    begin
    one_hit := RESULT_CHARDIED;
    exit;
    end;

  if (victim.CHAR_DIED) then
    begin
    one_hit := RESULT_VICTDIED;
    exit;
    end;

  { get the weapon }
  wield := ch.getDualWield;

  if (wield <> nil) then
    begin
    if (not dual_flip) then
      begin
      dual_flip := true;
      wield := ch.getEQ(WEAR_RHAND);
      end
    else
      dual_flip := false;
    end;

  if (wield = nil) or (wield.item_type <> ITEM_WEAPON) then
    wield := ch.getWield(ITEM_WEAPON);

  if (wield = nil) then
    ds := FG_PUNCH
  else
    begin
    ds := wield.value[4];

    if (ds = 0) then
      ds := FG_PUNCH;
    end;

  if (victim.CHAR_DIED) then
    begin
    one_hit := RESULT_VICTDIED;
    exit;
    end;

  if (ch.position <> POS_FIGHTING) and (ch.position <> POS_CASTING)
   and (victim <> ch) then
    begin
    ch.position := POS_FIGHTING;
    ch.fighting := victim;
    end;

  if (victim.position<>POS_FIGHTING) and (victim.position<>POS_BASHED) and (victim.position<>POS_CASTING)
   and (victim<>ch) then
    begin
    victim.position:=POS_FIGHTING;
    victim.fighting:=ch;
    end;

  vict_ac := victim.point.ac;
  hit_roll := ch.point.hitroll;

  if (not ch.CAN_SEE(victim)) then          { -10 penalty to hitroll when not able to see target }
    dec(hit_roll,10);

  // prof_bonus := get_prof_bonus(ch,wield,prof_gsn);
  prof_bonus := 0;

  dec(hit_roll,prof_bonus);
  dec(hit_roll,vict_ac);

  roll := rolldice(1,100);

  { undead or spirits: attack will go right through them if it's non-magical - Grimlord }
  if (victim.IS_NPC) and (IS_SET(victim.act_flags, ACT_SPIRIT)) and (not ch.IS_AFFECT(AFF_ENCHANT)) then
    begin
    act(AT_REPORT,'Your attack goes right through your victim as if it was not there!', false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'$n''s attack just doesn''t seem to have any effect!', false,ch,nil,victim,TO_ROOM);
    end
  else
  { mortals fighting immortals get this boney message - Grimlord }
  if (victim.IS_IMMORT) and (not ch.IS_IMMORT) then
    begin
    act(AT_REPORT, 'Your blow bounces off $N''s holy shield!',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT, '$n''s blow bounces off your holy shield!',false,ch,nil,victim,TO_VICT);
    act(AT_REPORT, '$n''s blow bounces off $N''s holy shield!',false,ch,nil,victim,TO_NOTVICT);
    end
  else
  if (roll <= hit_roll) then
    begin
    { check for dodge }
    if (number_percent <= victim.learned[gsn_dodge] div 2) then
      begin
      improve_skill(victim,gsn_dodge);

      if number_percent<50 then
        begin
        act(AT_REPORT,'$N ducks left, dodging your attack.',false,ch,nil,victim,TO_CHAR);
        act(AT_REPORT,'You duck left, dodging $n''s attack.',false,ch,nil,victim,TO_VICT);
        act(AT_REPORT,'$N ducks left, dodging $n''s attack.',false,ch,nil,victim,TO_NOTVICT);
        end
      else
        begin
        act(AT_REPORT,'$N ducks right, dodging your attack.',false,ch,nil,victim,TO_CHAR);
        act(AT_REPORT,'You duck right, dodging $n''s attack.',false,ch,nil,victim,TO_VICT);
        act(AT_REPORT,'$N ducks right, dodging $n''s attack.',false,ch,nil,victim,TO_NOTVICT);
        end;

      exit;
      end;

    if (wield <> nil) then
      dam := rolldice(wield.value[2],wield.value[3])
    else
    if (ch.point.damnumdie<>0) and (ch.point.damsizedie<>0) then
      dam := rolldice(ch.point.damnumdie,ch.point.damsizedie)
    else
      dam := rolldice(1,3);

    // improve_skill(ch,prof_gsn);

    inc(dam,ch.point.apb);
    inc(dam,prof_bonus div 4);

    chance := ch.learned[gsn_enhanced_damage];

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_enhanced_damage);
      inc(dam, 10);
      end;

    dam := (dam * ch.ability.str) div 50;

    one_hit:=damage(ch,victim,dam, TYPE_HIT + ds);
    end
  else
  if (roll+((victim.ability.dex-50) div 12)<=hit_roll) then
    begin
    if (victim.IS_FLYING) then
      begin
      act(AT_REPORT,'You swing wide as $N quickly flies out of the way.',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'$n swings wide as you quickly fly out of the way.',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'$n swings wide as $N quickly flies out of the way.',false,ch,nil,victim,TO_NOTVICT);
      end
    else
      begin
      act(AT_REPORT,'You swing wide, and miss $N completely.',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'$n swings wide, and misses you completely.',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'$n swings wide, and misses $N completely.',false,ch,nil,victim,TO_NOTVICT);
      end;
    end
  else
    begin
    act(AT_REPORT,'Your '+attack_table[ds,1]+' is completely absorbed by $N''s armor!',
        false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'$n''s '+attack_table[ds,1]+' is completely absorbed by your armor!',
        false,ch,nil,victim,TO_VICT);
    act(AT_REPORT,'$n''s '+attack_table[ds,1]+' is completely absorbed by $N''s armor!',
        false,ch,nil,victim,TO_NOTVICT);
    end;
end;

function in_melee(ch, vict : GCharacter) : boolean;
var
   node : GListNode;
   t : GCharacter;
   num : integer;
begin
  in_melee := true;

  if (ch = vict.fighting) then
    exit;

  num := 0;

  node := char_list.head;

  while (node <> nil) do
    begin
    t := node.element;

    if (t.position = POS_FIGHTING) and (t.fighting = vict) then
      begin
      inc(num);

      if (t = ch) then
        begin
        if (num > 4) then
          in_melee := false;

        exit;
        end;
      end;

    node := node.next;
    end;
end;

procedure multi_hit(ch, vict : GCharacter);
var chance,dual_bonus:integer;
begin
  if (ch.fighting <> vict) then
    begin
    ch.fighting := nil;
    ch.position := POS_STANDING;

    bugreport('multi_hit', 'fight.pas', 'desync error: ch.fighting & vict not same',
              'Character information has been desynced heavily.');
    write_console('System is unstable - prepare for a rough ride');

    exit;
    end;

  if (ch.CHAR_DIED) then
    exit;

  if (vict.CHAR_DIED) then
    begin
    ch.fighting := nil;
    ch.position := POS_STANDING;
    exit;
    end;

  if (ch.position=POS_BASHED) or (ch.position=POS_CASTING) then exit;
  if ch.position=POS_FIGHTING then
    begin
    if (vict.position<POS_FIGHTING) then
      begin
      vict.position:=POS_FIGHTING;
      vict.fighting:=ch;
      end;

    if not in_melee(ch,vict) then
      begin
      act(AT_REPORT,'$10- You are not in melee range! -',false,ch,nil,nil,TO_CHAR);
      exit;
      end;

    if (one_hit(ch, vict) <> RESULT_NONE) then
      exit;

    if (ch.getDualWield <> nil) then
      begin
      dual_bonus := ch.learned[gsn_dual_wield] div 10;

      if skill_success(ch,gsn_dual_wield) then
        begin
        improve_skill(ch, gsn_dual_wield);
        if (one_hit(ch, vict) <> RESULT_NONE) then
          exit;
        end;
      end
    else
      dual_bonus := 0;

    if (ch.point.mv < 10) then
      dec(dual_bonus, 20);

    chance := ch.learned[gsn_second_attack] + dual_bonus;

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_second_attack);

      if (one_hit(ch,vict) <> RESULT_NONE) then
        exit;
      end;

    chance := ch.learned[gsn_third_attack] + dual_bonus;

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_third_attack);

      if (one_hit(ch,vict) <> RESULT_NONE) then
        exit;
      end;

    chance := ch.learned[gsn_fourth_attack] + dual_bonus;

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_fourth_attack);

      if (one_hit(ch,vict) <> RESULT_NONE) then
        exit;
      end;

    chance := ch.learned[gsn_fifth_attack] + dual_bonus;

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_fifth_attack);

      if (one_hit(ch,vict) <> RESULT_NONE) then
        exit;
      end;
    end;
end;

procedure update_fighting;
var ch, vch, gch : GCharacter;
    node_world, node_room : GListNode;
    conn : GConnection;
begin
  node_world := char_list.head;

  while (node_world <> nil) do
    begin
    ch := node_world.element;

    if (ch.bash_timer > -2) then
      dec(ch.bash_timer);

    if (ch.bashing > -2) then
      dec(ch.bashing);

    if (ch.cast_timer > 0) then
      dec(ch.cast_timer);

    if (ch.bash_timer = 1) and (ch.position = POS_BASHED) then
      begin
      if (ch.fighting <> nil) then
        ch.position := POS_FIGHTING
      else
        ch.position := POS_STANDING;

      act(AT_REPORT,'You recover from the bash and stand quickly.',false,ch,nil,nil,TO_CHAR);
      act(AT_REPORT,'$n recovers and stands quickly.',false,ch,nil,nil,TO_ROOM);
      end;

    vch := ch.fighting;

    if (ch.position = POS_FIGHTING) then
      begin
      multi_hit(ch,vch);

      if (vch.CHAR_DIED) or (ch.CHAR_DIED) then
        break;

      { Group members AUTO-assist other group members }
      node_room := ch.room.chars.head;

      while (node_room <> nil) do
        begin
        gch := node_room.element;

        if (gch <> ch) and (gch.leader=ch.leader) and (gch.room = ch.room) then
         if (gch.fighting = nil) and (gch.position = POS_STANDING) then
          if (gch.IS_NPC) or (IS_SET(gch.player^.cfg_flags, CFG_ASSIST)) then
            begin
            if (vch.CHAR_DIED) then
              break;

            act(AT_REPORT,'You assist $N!',false,gch,nil,ch,TO_CHAR);
            act(AT_REPORT,'$n assists $N!',false,gch,nil,ch,TO_ROOM);

            gch.fighting := vch;
            gch.position := POS_FIGHTING;
            end;

        node_room := node_room.next;
        end;

      { NPC's of same type assist each other }
      if (ch.IS_NPC) then
        begin
        node_room := ch.room.chars.head;

        while (node_room <> nil) do
          begin
          gch := node_room.element;

          if (vch.CHAR_DIED) then
            break;

          if (gch.IS_NPC) and (gch.IS_AWAKE) then
           if (gch.position = POS_STANDING) and (gch.npc_index.vnum = ch.npc_index.vnum) then
            if (number_percent <= 25) then
             begin
             if (vch.CHAR_DIED) then
               break;

             gch.fighting := vch;
             gch.position := POS_FIGHTING;

             // in_melee(gch,vch);

             act(AT_FIGHT,'$n charges into the battle against $N!',false,gch,nil,vch,TO_NOTVICT);
             act(AT_FIGHT_HIT,'$N charges into the battle against you!',false,vch,nil,gch,TO_CHAR);

             multi_hit(gch,vch);
             end;

          node_room := node_room.next;
          end;
        end;
      end
    else
    if (ch.IS_NPC) then
      begin
      // aggress mode
      if (ch.hunting <> nil) and (ch.hunting.room = ch.room) then
        interpret(ch, 'kill '+ch.hunting.name^);

      if (IS_SET(ch.act_flags, ACT_AGGRESSIVE)) then
        begin
        vch := ch.room.findRandomChar;

        if (vch <> nil) then
          interpret(ch, 'kill ' + vch.name^);
        end;
      end;

    node_world := node_world.next;
    end;

  node_world := connection_list.head;

  while (node_world <> nil) do
    begin
    conn := node_world.element;

    if (conn.state = CON_PLAYING) and (not conn.ch.in_command) then
      conn.ch.emptyBuffer;

    node_world := node_world.next;
    end;

  node_world := char_list.head;

  while (node_world <> nil) do
    begin
    ch := node_world.element;

    if (ch.IS_NPC) and (ch.fighting <> nil) then
      fightTrigger(ch, ch.fighting);

    node_world := node_world.next;
    end;
end;

end.
