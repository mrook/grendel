{
	Summary:
		Damage & experience routines
	
	## $Id: fight.pas,v 1.4 2004/02/27 22:24:21 ***REMOVED*** Exp $
}

unit fight;

interface

uses
	Math,
	SysUtils,
	player,
	chars;


{ fighting constants }
const 
	FG_NONE = 0;
	FG_PUNCH = 1;
	FG_SLASH = 2;      { gsn_slashing }
	FG_PIERCE = 3;     { gsn_piercing }
	FG_CLEAVE = 4;     { gsn_slashing }
	FG_BLAST = 5;
	FG_CRUSH = 6;      { gsn_concussion }
	FG_BITE = 7;
	FG_CLAW = 8;
	FG_WHIP = 9;       { gsn_whipping }
	FG_STAB = 10;      { gsn_piercing }
	FG_GAZE = 11;      { gaze from a spirit? }
	FG_BREATH = 12;    { breath }
	FG_STING = 13;     { sting (bee, fly) }
	FG_MAX = FG_STING;

{ damage types }
const 
	TYPE_UNDEFINED = 0;
	TYPE_SLAY = 1;
	TYPE_SILENT = 2;
	TYPE_HIT = 3;
	TYPE_OTHER = TYPE_HIT + FG_MAX + 1;

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

procedure stopfighting(ch : GCharacter);
procedure death_cry(ch, killer : GCharacter);

procedure gain_xp(ch : GPlayer; xp : cardinal);

function damage(ch, oppnt : GCharacter; dam : integer; dt : integer) : integer;
function one_hit(ch, victim : GCharacter) : integer;
function in_melee(ch, vict : GCharacter) : boolean;
procedure multi_hit(ch, vict : GCharacter);

procedure update_fighting;

implementation

uses
	timers,
	area,
	constants,
	skills,
	conns,
	mudsystem,
	commands,
	dtypes,
	console,
	util,
	update,
	Channels;

var
  dual_flip : boolean;

// Stop the fighting
procedure stopfighting(ch : GCharacter);
var 
	vict : GCharacter;
	iterator : GIterator;
begin
	iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.fighting = ch) then
      begin
      vict.fighting := nil;
      vict.state := STATE_IDLE;
      end;
    end;

	iterator.Free();
  ch.fighting := nil;
  ch.state := STATE_IDLE;
end;

// Death cry
procedure death_cry(ch, killer : GCharacter);
var
	chance : integer;
  s_room : GRoom;
  vict : GCharacter;
  pexit : GExit;
  iterator_exit, iterator_char : GIterator;
begin
	iterator_exit := ch.room.exits.iterator();

  while (iterator_exit.hasNext()) do
    begin
    pexit := GExit(iterator_exit.next());

    s_room := findRoom(pexit.vnum);

    iterator_char := s_room.chars.iterator();

    while (iterator_char.hasNext()) do
      begin
      vict := GCharacter(iterator_char.next());

      vict.sendBuffer('You hear a chilling death cry.'#13#10);
      end;

		iterator_char.Free();
    end;
    
  iterator_exit.Free();

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

// Gain XP
procedure gain_xp(ch : GPlayer; xp : cardinal);
var
   hp_gain, mv_gain, ma_gain : integer;
   pracs_gain : integer;
begin
  if (ch.IS_IMMORT) then exit;

  { no message here, could spam a level 500 off the floor - Grimlord }

  if (ch.level >= LEVEL_MAX) then
    exit;

  with GPlayer(ch) do
    begin
    inc(xptot,xp);
    dec(xptogo,xp);

    while (xptogo<=0) do
      begin
      pracs_gain := round(wis / 20) + random(6) - 1; // base prac gain on wis
      hp_gain := (con div 4)+random(6)-3;
      mv_gain := dex div 4;

      if odd(level) then
        ma_gain := round((int + wis) / 10) // base mana gain on int and wis
      else
        ma_gain := 0;

      inc(pracs, pracs_gain);

      max_hp := max_hp + hp_gain;
      max_mv := max_mv + mv_gain;
      max_mana := max_mana + ma_gain;

      hp := max_hp;
      mv := max_mv;

      level := level + 1;

      act(AT_WHITE,Format('>> You have advanced to level %d!', [level]),false,ch,nil,nil,TO_CHAR);
      act(AT_REPORT, 'You gain $B$1' + inttostr(hp_gain) + '$A$7 health, $B$1' + inttostr(mv_gain) + '$A$7 moves, $B$1' + inttostr(ma_gain) + '$A$7 mana and $B$1' + inttostr(pracs_gain) + '$A$7 practice sessions.', false, ch, nil, nil, TO_CHAR);

      if (level>=LEVEL_MAX) then
        begin
        level:=LEVEL_MAX;
        act(AT_WHITE,'>> You have achieved the maximum level possible!',false,ch,nil,nil,TO_CHAR);
        end;

      inc(xptogo, ch.calcxp2lvl);

      hitroll := UMax((level div 5)+50,100);

      ch.calcRank;
      end;
    end;
end;

function get_exp_worth(ch : GCharacter) : integer;
begin
  get_exp_worth := longint(ch.level) * longint(ch.max_hp);
end;

// XP formula
function xp_compute(ch, victim : GCharacter) : cardinal;
var
   xp, range : cardinal;
begin
  if (not ch.IS_NPC) and (not victim.IS_NPC) and (ch.IS_SAME_ALIGN(victim)) then
    begin
    xp_compute := 1;
    exit;
    end;

  if (ch.IS_IMMORT) or (ch.IS_NPC) or (ch = victim) then
    begin
    xp_compute := 0;
    exit;
    end;

  xp := get_exp_worth(victim);
  range := URange(1, (victim.level - ch.level) + 10,13);
  xp_compute := (xp*range) div 10;

//  xp_compute := UMin((victim.level - ch.level + 1) * 20, 1);
end;

// Find damage message
function findDamage(dam : integer) : GDamMessage;
var
	iterator : GIterator;
	dm : GDamMessage;
begin
  Result := nil;

  iterator := dm_msg.iterator();

  while (iterator.hasNext()) do
    begin
    dm := GDamMessage(iterator.next());

    if (dam >= dm.min) and (dam <= dm.max) then
      begin
      Result := dm;
      break;
      end;
    end;
    
  iterator.Free();
end;

// Handle damage
function damage(ch, oppnt : GCharacter; dam : integer; dt : integer) : integer;
var
	xp,r : integer;
	dm : GDamMessage;
	a : array[1..3] of string;
	s1, s2 : string;
	p : integer;
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

  if (IS_SET(ch.aff_flags, AFF_BASHED) or IS_SET(ch.aff_flags, AFF_STUNNED)) then
    begin
    damage := RESULT_CHARBASHED;
    exit; { can't fight when bashed! }
    end;

  if (ch.room <> oppnt.room) and (dt <> TYPE_SILENT) then
    begin
    ch.fighting := nil;
    ch.state := STATE_IDLE;
    oppnt.fighting := nil;
    oppnt.state := STATE_IDLE;
    damage := RESULT_VICTDIED;
    exit;
    end;

  if (dam > 25) and (hasTimer(ch, 'cast') <> nil) then
    begin
    act(AT_FIGHT_HIT, '$B$4OUCH$7!$A$7 You just lost your concentration!',false,oppnt,nil,ch,TO_CHAR);

    unregisterTimer(oppnt, TIMER_ACTION);

    oppnt.state := STATE_FIGHTING;
    end; 

  if (ch.state <> STATE_FIGHTING) and (oppnt <> ch) then
    begin
    unregisterTimer(oppnt, TIMER_ACTION);
    
    ch.state := STATE_FIGHTING;
    ch.position := POS_STANDING;
    ch.fighting := oppnt;
    end;

  if (oppnt.state <> STATE_FIGHTING) and (oppnt <> ch) then
    begin
    oppnt.state := STATE_FIGHTING;
    oppnt.position := POS_STANDING;
    oppnt.fighting := ch;
    end;

(*  if (dam>10) and (dt<>TYPE_UNDEFINED) then
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
    end; *)

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
  if (dt > TYPE_OTHER) then
    begin
    s1 := GSkill(pointer(dt)).dam_msg;
    s2 := GSkill(pointer(dt)).dam_msg;
    end
  else
  if (dt > TYPE_HIT) then
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
    bugreport('damage', 'fight.pas', 'unknown damagetype ' + inttostr(dt));
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

  if (s1 <> '') and (s2 <> '') and (dt <> integer(gsn_backstab)) then
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
  if (not oppnt.IS_IMMORT) or ((not oppnt.IS_NPC) and oppnt.IS_IMMORT) and (GPlayer(oppnt).bg_status = BG_PARTICIPATE) then
    oppnt.hp := oppnt.hp - dam;

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
      gain_xp(GPlayer(ch),xp);
      inc(GPlayer(ch).fightxp,xp);
      end;
    end
  else
    begin
    damage:=RESULT_CHARDIED;
    exit;
    end;

  if (oppnt.hp<0) then
    begin
    unregisterTimer(oppnt, TIMER_ACTION);
    unregisterTimer(oppnt, TIMER_COMBAT);

    oppnt.state := STATE_IDLE;
    ch.state := STATE_IDLE;
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
        begin
        act(AT_REPORT,'You gain ' + inttostr(xp)+' XP for the kill and '+IntToStr(GPlayer(ch).fightxp)+' XP for fighting.',false,ch,nil,nil,TO_CHAR);
        gain_xp(GPlayer(ch),xp);
        end;
      end;

    if (oppnt.IS_NPC) then
      begin
      p := GNPC(oppnt).context.findSymbol('onDeath');

      if (p <> -1) then
        begin
        GNPC(oppnt).context.push(integer(ch));
        GNPC(oppnt).context.push(integer(oppnt));
        GNPC(oppnt).context.setEntryPoint(p);
        GNPC(oppnt).context.Execute;
        end;

      if (oppnt.snooped_by <> nil) and (GPlayer(oppnt.snooped_by).switching = oppnt) then
        interpret(oppnt, 'return sub');

      oppnt.die();

      if (not ch.IS_NPC) then
        begin
        if (IS_SET(GPlayer(ch).cfg_flags,CFG_AUTOLOOT)) then
          interpret(ch, 'get all ''corpse of ' + oppnt.name + '''');

        if (IS_SET(GPlayer(ch).cfg_flags,CFG_AUTOSAC)) then
          interpret(ch, 'sac ''corpse of ' + oppnt.name + '''');
        end;
      end
    else
      begin
      oppnt.die;

      { Regain 10% of xp needed when killed by NPC,
        4% when killed by PC  - Grimlord}
      if (ch.IS_NPC) then
        begin
        inc(GPlayer(oppnt).xptogo, oppnt.calcxp2lvl div 10);
        ch.hunting := nil;
        REMOVE_BIT(GNPC(ch).act_flags, ACT_HUNTING);
        end
      else
        begin
        inc(ch.kills);

        { get a point when killing one in bg - Grimlord }
        if (GPlayer(ch).bg_status = BG_PARTICIPATE) then
          inc(GPlayer(ch).bg_points);

        if (GPlayer(oppnt).bg_status <> BG_PARTICIPATE) then
          inc(GPlayer(oppnt).xptogo,  oppnt.calcxp2lvl div 4);

        if (IS_SET(GPlayer(ch).cfg_flags, CFG_AUTOSCALP)) then
          interpret(ch, 'scalp corpse of '+oppnt.name);
        end;

      if (oppnt.clan <> nil) then
        to_channel(oppnt, '*CLAN NOTIFY*: '+oppnt.name+' has been'+
        ' killed by '+ch.name+'!',CHANNEL_CLAN,AT_WHITE);

      if (not ch.IS_NPC) then
        begin
        if (ch.clan<>nil) then
          to_channel(ch, '*CLAN NOTIFY*: '+ch.name+' has just'+
          ' killed '+oppnt.name+'!',CHANNEL_CLAN,AT_WHITE);

        if not (ch.IS_SAME_ALIGN(oppnt)) then
          begin
          if (GPlayer(ch).taunt <> '') then
            act(AT_WHITE, '$N taunts: ' + GPlayer(ch).taunt, false, oppnt, nil, ch, TO_CHAR);

          // update_trophy(ch,oppnt);
          end;
        end;
      end;

    damage := RESULT_VICTDIED;
    exit;
    end;

  if (not oppnt.IS_NPC) then
   if (oppnt.hp <= GPlayer(oppnt).wimpy) then
    interpret(oppnt,'flee');
end;

function one_hit(ch, victim : GCharacter) : integer;
var chance,ds,dam:integer;
    wield : GObject;
//    fly_bonus, prof_gsn : integer;
    prof_bonus : integer;
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
    
  if (ch.state <> STATE_FIGHTING) and (victim <> ch) then
    begin
    unregisterTimer(victim, TIMER_ACTION);
    
    ch.state := STATE_FIGHTING;
    ch.position := POS_STANDING;
    ch.fighting := victim;
    end;

  if (victim.state <> STATE_FIGHTING) and (victim <> ch) then
    begin
    victim.state := STATE_FIGHTING;
    victim.position := POS_STANDING;
    victim.fighting := ch;
    end;    

  { get the weapon }
  wield := ch.getDualWield;

  if (wield <> nil) then
    begin
    if (not dual_flip) then
      begin
      dual_flip := true;
      wield := ch.getEQ('rightwield');
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

  vict_ac := victim.ac;
  hit_roll := ch.hitroll;

  if (not ch.CAN_SEE(victim)) then          { -10 penalty to hitroll when not able to see target }
    dec(hit_roll,10);

  // prof_bonus := get_prof_bonus(ch,wield,prof_gsn);
  prof_bonus := 0;

  dec(hit_roll,prof_bonus);
  dec(hit_roll,vict_ac);

  roll := rolldice(1,100);

  { undead or spirits: attack will go right through them if it's non-magical - Grimlord }
  if (victim.IS_NPC) and (IS_SET(GNPC(victim).act_flags, ACT_SPIRIT)) and (not ch.IS_AFFECT(AFF_ENCHANT)) then
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
    if (number_percent <= victim.LEARNED(gsn_dodge) div 2) then
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
    if (ch.damnumdie<>0) and (ch.damsizedie<>0) then
      dam := rolldice(ch.damnumdie,ch.damsizedie)
    else
      dam := rolldice(1,3);

    inc(dam,ch.apb);
    inc(dam,prof_bonus div 4);

    chance := ch.LEARNED(gsn_enhanced_damage);

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_enhanced_damage);
      inc(dam, 10);
      end;

    dam := (dam * ch.str) div 50;

    one_hit:=damage(ch,victim,dam, TYPE_HIT + ds);
    end
  else
  if (roll+((victim.dex-50) div 12)<=hit_roll) then
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
	iterator : GIterator;
	t : GCharacter;
	num : integer;
begin
  in_melee := true;

  if (ch = vict.fighting) then
    exit;

  num := 0;

  iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    t := GCharacter(iterator.next());

    if (t.state = STATE_FIGHTING) and (t.fighting = vict) then
      begin
      inc(num);

      if (t = ch) then
        begin
        if (num > 4) then
          in_melee := false;

        exit;
        end;
      end;
    end;
  
  iterator.Free();
end;

procedure multi_hit(ch, vict : GCharacter);
var
	chance, dual_bonus : integer;
begin
  if (ch.fighting <> vict) then
    begin
    ch.fighting := nil;
    ch.state := STATE_IDLE;

    bugreport('multi_hit', 'fight.pas', 'desync error: ch.fighting & vict not same');
    writeConsole('System is unstable - prepare for a rough ride');

    exit;
    end;

  if (ch.CHAR_DIED) then
    exit;

  if (vict.CHAR_DIED) then
    begin
    ch.fighting := nil;
    ch.state := STATE_IDLE;
    exit;
    end;

  if (IS_SET(ch.aff_flags, AFF_BASHED) or IS_SET(ch.aff_flags, AFF_STUNNED)) then 
    exit;
    
  if (ch.state = STATE_FIGHTING) or (Assigned(ch.fighting)) then
    begin
    if (not in_melee(ch,vict)) then
      begin
      act(AT_REPORT,'$10- You are not in melee range! -',false,ch,nil,nil,TO_CHAR);
      exit;
      end;

    if (one_hit(ch, vict) <> RESULT_NONE) then
      exit;

    if (ch.getDualWield <> nil) then
      begin
      dual_bonus := ch.LEARNED(gsn_dual_wield) div 10;

      if skill_success(ch,gsn_dual_wield) then
        begin
        improve_skill(ch, gsn_dual_wield);
        if (one_hit(ch, vict) <> RESULT_NONE) then
          exit;
        end;
      end
    else
      dual_bonus := 0;

    if (ch.mv < 10) then
      dec(dual_bonus, 20);

    chance := ch.LEARNED(gsn_second_attack) + dual_bonus;

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_second_attack);

      if (one_hit(ch,vict) <> RESULT_NONE) then
        exit;
      end;

    chance := ch.LEARNED(gsn_third_attack) + dual_bonus;

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_third_attack);

      if (one_hit(ch,vict) <> RESULT_NONE) then
        exit;
      end;

    chance := ch.LEARNED(gsn_fourth_attack) + dual_bonus;

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_fourth_attack);

      if (one_hit(ch,vict) <> RESULT_NONE) then
        exit;
      end;

    chance := ch.LEARNED(gsn_fifth_attack) + dual_bonus;

    if (number_percent <= chance) then
      begin
      improve_skill(ch, gsn_fifth_attack);

      if (one_hit(ch,vict) <> RESULT_NONE) then
        exit;
      end;
    end;
end;

// Update the fighting
procedure update_fighting();
var 
  ch, vch, gch : GCharacter;
  iter_world, iter_room : GIterator;
  conn : GPlayerConnection;
  p : integer;
begin
  iter_world := char_list.iterator();

  while (iter_world.hasNext()) do
    begin
    ch := GCharacter(iter_world.next());

    if (ch.bash_timer > -2) then
      dec(ch.bash_timer);

    if (ch.bashing > -2) then
      dec(ch.bashing);

    if (ch.cast_timer > 0) then
      dec(ch.cast_timer);

    if (ch.bash_timer = 1) then
      begin
      if (IS_SET(ch.aff_flags, AFF_BASHED)) then
        begin
        REMOVE_BIT(ch.aff_flags, AFF_BASHED);

        act(AT_REPORT,'You recover from the bash and stand quickly.',false,ch,nil,nil,TO_CHAR);
        act(AT_REPORT,'$n recovers from the bash and stands quickly.',false,ch,nil,nil,TO_ROOM);
        end
      else
      if (IS_SET(ch.aff_flags, AFF_STUNNED)) then
        begin
        REMOVE_BIT(ch.aff_flags, AFF_STUNNED);

        act(AT_REPORT,'You shake your head and stand quickly.',false,ch,nil,nil,TO_CHAR);
        act(AT_REPORT,'$n recovers from the stun and stands quickly.',false,ch,nil,nil,TO_ROOM);
        end;
      end;

    vch := ch.fighting;

    if (ch.state = STATE_FIGHTING) or (Assigned(ch.fighting)) then
      begin
      multi_hit(ch,vch);

      if (vch.CHAR_DIED) or (ch.CHAR_DIED) then
        break;

      { Group members AUTO-assist other group members }
      iter_room := ch.room.chars.iterator();

      while (iter_room.hasNext()) do
        begin
        gch := GCharacter(iter_room.next());

        if (gch <> ch) and (gch.leader=ch.leader) and (gch.room = ch.room) then
         if (gch.fighting = nil) and (gch.state = STATE_IDLE) then
          if (gch.IS_NPC) or (IS_SET(GPlayer(gch).cfg_flags, CFG_ASSIST)) then
            begin
            if (vch.CHAR_DIED) then
              break;

            act(AT_REPORT,'You assist $N!',false,gch,nil,ch,TO_CHAR);
            act(AT_REPORT,'$n assists $N!',false,gch,nil,ch,TO_ROOM);

            gch.fighting := vch;
            gch.position := POS_STANDING;
            gch.state := STATE_FIGHTING;
            end;
        end;
        
      iter_room.Free();

      { NPC's of same type assist each other }
      if (ch.IS_NPC) then
        begin
        iter_room := ch.room.chars.iterator();

        while (iter_room.hasNext()) do
          begin
          gch := GCharacter(iter_room.next());

          if (vch.CHAR_DIED) then
            break;

          if (gch <> ch) and (gch.IS_NPC) and (gch.IS_AWAKE) then
           if (gch.state = STATE_IDLE) and (GNPC(gch).npc_index.vnum = GNPC(ch).npc_index.vnum) then
            if (number_percent <= 25) then
             begin
             if (vch.CHAR_DIED) then
               break;

             gch.fighting := vch;
             gch.state := STATE_FIGHTING;

             // in_melee(gch,vch);

             act(AT_FIGHT,'$n charges into the battle against $N!',false,gch,nil,vch,TO_NOTVICT);
             act(AT_FIGHT_HIT,'$N charges into the battle against you!',false,vch,nil,gch,TO_CHAR);

             multi_hit(gch,vch);
             end;
          end;

        iter_room.Free();
        end;
      end
    else
    if (ch.IS_NPC) then
      begin
      // aggress mode
      if (ch.hunting <> nil) and (ch.hunting.room = ch.room) then
        interpret(ch, 'kill '+ch.hunting.name);

      if (IS_SET(GNPC(ch).act_flags, ACT_AGGRESSIVE)) then
        begin
        vch := ch.room.findRandomChar;

        if (vch <> nil) and (not vch.IS_NPC) then
          interpret(ch, 'kill ' + vch.name);
        end;
      end;
    end;

  iter_world.Free();
  iter_world := connection_list.iterator();

  while (iter_world.hasNext()) do
    begin
    conn := GPlayerConnection(iter_world.next());

    if (conn.state = CON_PLAYING) and (not conn.ch.in_command) then
      conn.ch.emptyBuffer();
    end;  

  iter_world.Free();
  iter_world := char_list.iterator();

  while (iter_world.hasNext()) do
    begin
    ch := GCharacter(iter_world.next());

    if (ch.IS_NPC) and (ch.fighting <> nil) then
      begin
      p := GNPC(ch).context.findSymbol('onFight');

      if (p <> -1) then
        begin
        GNPC(ch).context.push(integer(ch.fighting));
        GNPC(ch).context.push(integer(ch));
        GNPC(ch).context.setEntryPoint(p);
        GNPC(ch).context.Execute;
        end;
      end;
    end;

  iter_world.Free();
end;

begin
  dual_flip := false;
end.
