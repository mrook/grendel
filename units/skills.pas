unit skills;

interface

uses
    SysUtils,
    chars,
    dtypes,
    conns,
    util,
    constants;

type
    SPEC_FUNC = procedure(ch, victim : GCharacter; sn : integer);

    GAffect = class
      sn : integer;
      apply_type : GApplyTypes;
      modifier : longint;
      duration : longint;

      node : GListNode;

      procedure modify(ch : GCharacter; add : boolean);
      procedure applyTo(ch : GCharacter);
    end;

    GSkill = class
      func : SPEC_FUNC;

      affects : GDLinkedList;
      prereqs : GDLinkedList;

      name : string;
      skill_type:integer;
      min_mana:integer;
      min_lvl:integer;
      beats:integer;
      target:integer;
      sn : integer;

      dicenum,dicesize,diceadd:integer;

      dam_msg,wear_msg:string;
      start_char,start_vict,start_room:string;
      hit_char,hit_vict,hit_room:string;
      miss_char,miss_vict,miss_room:string;
      die_char,die_vict,die_room:string;
      imm_char,imm_vict,imm_room:string;
    end;

var
   skill_table : array[0..MAX_SKILLS-1] of GSkill;
   num_skills : integer;

{ gsn's }
var
   gsn_slashing_weapons : integer;
   gsn_second_attack : integer;
   gsn_third_attack : integer;
   gsn_fourth_attack : integer;
   gsn_fifth_attack : integer;
   gsn_enhanced_damage : integer;
   gsn_dual_wield : integer;
   gsn_slashing : integer;
   gsn_piercing : integer;
   gsn_concussion : integer;
   gsn_whipping : integer;
   gsn_kick : integer;
   gsn_bash : integer;
   gsn_poison : integer;
   gsn_sneak : integer;
   gsn_swim : integer;
   gsn_searching : integer;
   gsn_backstab : integer;
   gsn_circle : integer;
   gsn_rescue : integer;
   gsn_dodge : integer;
   gsn_track : integer;
   gsn_peek : integer;
   gsn_hide : integer;


procedure load_skills;
procedure done_skills;

function findSkill(s : string) : integer;
function findSkillPlayer(ch : GCharacter; s : string) : integer;

procedure improve_skill(ch : GCharacter; sn : integer);
function skill_success(ch : GCharacter; sn : integer) : boolean;

function findApply(s : string) : GApplyTypes;
function findAffect(ch : GCharacter; sn : integer) : GAffect;
procedure removeAffect(ch : GCharacter; aff : GAffect);
function removeAffectSkill(ch:GCharacter;gsn:integer):boolean;
function removeAffectFlag(ch:GCharacter;flag:integer):boolean;
procedure update_affects;


implementation

uses
    strip,
    magic,
    fight,
    update,
    mudsystem;


function findSkill(s : string) : integer;
var h, r : integer;
begin
  s := uppercase(s);
  r := -1;

  for h := 0 to num_skills - 1 do
   if (s = uppercase(skill_table[h].name)) or (pos(s,uppercase(skill_table[h].name)) <> 0) then
    begin
    r := h;
    break;
    end;

  findSkill := r;
end;

function findSkillPlayer(ch : GCharacter; s : string) : integer;
var h, r : integer;
begin
  s := uppercase(s);
  r := -1;

  for h := 0 to num_skills - 1 do
   if (s = uppercase(skill_table[h].name)) or (pos(s,uppercase(skill_table[h].name)) <> 0) then
    begin
    r := h;
    break;
    end;

  if (r <> -1) and (ch.learned[r] = 0) then
    findSkillPlayer := -1
  else
    findSkillPlayer := r;
end;

function assign_gsn(name : string) : integer;
var
   gsn : integer;
begin
  gsn := findSkill(name);

  if (gsn = -1) then
    bugreport('assign_gsn', 'skills.pas', 'skill '''+name+''' not found',
              'The specified skill could not be found.');

  assign_gsn := gsn;
end;

procedure process_affect(skill : GSkill; s : integer; format : string);
var
   aff : GAffect;
begin
  aff := GAffect.Create;

  with aff do
    begin
    sn := s;

    apply_type := findApply(stripl(format, ' '));

    format := striprbeg(format, ' ');

    modifier := findSkill(stripl(format, ' '));

    if (modifier = -1) then
      modifier := strtointdef(stripl(format, ' '), 0);

    format := striprbeg(format, ' ');
    duration := strtointdef(stripl(format, ' '), 0);
    end;

  aff.node := skill.affects.insertLast(aff);
end;

procedure load_skills;
var f:textfile;
    s,g,a:string;
    h:integer;
    skill : GSkill;
begin
  assignfile(f, 'system\skills.dat');
  {$I-}
  reset(f);
  {$I+}

  if (IOResult <> 0) then
    begin
    bugreport('load_skills', 'skills.pas', 'could not open system\skills.dat',
              'The system file skills.dat could not be opened.');
    exit;
    end;

  FillChar(skill_table, sizeof(skill_table), 0);
  num_skills := 0;

  repeat
    repeat
      readln(f,s);
    until (uppercase(s) = '#SKILL') or (eof(f));

    if (eof(f)) then
      break;

    skill := GSkill.Create;

    skill.affects := GDLinkedList.Create;
    skill.prereqs := GDLinkedList.Create;
    skill.sn := num_skills;

    with skill do
      repeat
      readln(f, s);

      g := uppercase(stripl(s,':'));

      if (g = 'TYPE') then
        begin
        s := uppercase(striprbeg(s,' '));

        if (s = 'SPELL') then
          skill_type := SKILL_SPELL
        else
        if (s = 'SKILL') then
          skill_type := SKILL_SKILL
        else
        if (s = 'WEAPON') then
          skill_type := SKILL_WEAPON;
        end
      else
      if (g = 'NAME') then
        name := striprbeg(s,' ')
      else
      if g='ROUNDS' then
        beats:=strtoint(striprbeg(s,' '))
      else
      if g='MINLEVEL' then
        min_lvl:=strtoint(striprbeg(s,' '))
      else
      if g='MANA' then
        min_mana:=strtoint(striprbeg(s,' '))
      else
      if g='TARGET' then
        target:=strtoint(striprbeg(s,' '))
      else
      if g='FUNCTION' then
        func := findFunc(striprbeg(s,' '))
      else
      if g='STARTCHAR' then
        start_char := striprbeg(s,' ')
      else
      if g='STARTVICT' then
        start_vict := striprbeg(s,' ')
      else
      if g='STARTROOM' then
        start_room := striprbeg(s,' ')
      else
      if g='HITCHAR' then
        hit_char := striprbeg(s,' ')
      else
      if g='HITVICT' then
        hit_vict := striprbeg(s,' ')
      else
      if g='HITROOM' then
        hit_room := striprbeg(s,' ')
      else
      if g='MISSCHAR' then
        miss_char := striprbeg(s,' ')
      else
      if g='MISSVICT' then
        miss_vict := striprbeg(s,' ')
      else
      if g='MISSROOM' then
        miss_room := striprbeg(s,' ')
      else
      if g='DAMMSG' then
        dam_msg := striprbeg(s,' ')
      else
      if g='WEAROFF' then
        wear_msg := striprbeg(s,' ')
      else
      if g='DICE' then
        begin
        a:=uppercase(striprbeg(s,' '));
        dicenum:=strtoint(stripl(a,'D'));
        a:=striprbeg(a,'D');
        dicesize:=strtoint(stripl(a,'+'));
        a:=striprbeg(a,'+');
        diceadd:=strtoint(stripl(a,' '));
        end
      else
      if g='AFFECTS' then
        process_affect(skill, num_skills, striprbeg(s,' '))
      else
      if g='PREREQ' then
        begin
        a := striprbeg(s, ' ');
        h := findSkill(a);

        if (h >= 0) then
          prereqs.insertLast(skill_table[h])
        else
          bugreport('load_skills', 'skills.pas', 'Could not find prereq skill ' + a,
                    'The specified skill could not be found.');
        end;
      until uppercase(s)='#END';

    skill_table[num_skills] := skill;

    inc(num_skills);
  until eof(f);

  closefile(f);

  gsn_second_attack := assign_gsn('second attack');
  gsn_third_attack := assign_gsn('third attack');
  gsn_fourth_attack := assign_gsn('fourth attack');
  gsn_fifth_attack := assign_gsn('fifth attack');
  gsn_enhanced_damage := assign_gsn('enhanced damage');
  gsn_dual_wield := assign_gsn('dual wield');
  gsn_slashing := assign_gsn('slashing weapons');
  gsn_piercing := assign_gsn('piercing weapons');
  gsn_concussion := assign_gsn('concussion weapons');
  gsn_whipping := assign_gsn('whipping weapons');
  gsn_kick := assign_gsn('kick');
  gsn_bash := assign_gsn('bash');
  gsn_poison := assign_gsn('poison');
  gsn_sneak := assign_gsn('sneaking');
  gsn_swim := assign_gsn('swim');
  gsn_searching := assign_gsn('searching');
  gsn_backstab := assign_gsn('backstab');
  gsn_circle := assign_gsn('circle');
  gsn_rescue := assign_gsn('rescue');
  gsn_dodge := assign_gsn('dodge');
  gsn_track := assign_gsn('track');
  gsn_peek := assign_gsn('peek');
  gsn_hide := assign_gsn('hide');
end;

procedure done_skills;
var
   a : integer;
begin
  for a := 0 to num_skills - 1 do
    begin
    skill_table[a].Free;
    end;
end;

procedure improve_skill(ch : GCharacter; sn : integer);
var chance, percent : integer;
begin
  if (ch.learned[sn] = 100) then
    exit;

  chance := ch.learned[sn] - (ch.ability.wis div 5);

  percent := number_percent;

  if (percent <= chance div 3) then
    begin
    act(AT_WHITE, '[You have become better at '+skill_table[sn].name+'!]',false,ch,nil,nil,TO_CHAR);
    ch.learned[sn] := UMAX(ch.learned[sn]+1,100);
    end;
end;

function skill_success(ch : GCharacter; sn : integer) : boolean;
begin
  skill_success := (number_percent <= ch.learned[sn]);
end;

procedure GAffect.modify(ch : GCharacter; add : boolean);
var
   modif : integer;
begin
  modif := modifier;

  if (not add) then
    begin
    case apply_type of
      APPLY_AFFECT: begin
                    REMOVE_BIT(ch.aff_flags, modif);
                    exit;
                    end;
      APPLY_REMOVE: begin
                    SET_BIT(ch.aff_flags, modif);
                    exit;
                    end;
    end;

    modif := -modif;
    end;

  case apply_type of
    APPLY_STR: inc(ch.ability.str, modif);
    APPLY_DEX: inc(ch.ability.dex, modif);
    APPLY_INT: inc(ch.ability.int, modif);
    APPLY_WIS: inc(ch.ability.wis, modif);
    APPLY_CON: inc(ch.ability.con, modif);
    APPLY_HP: ch.point.hp := UMin(ch.point.hp + modif, ch.point.max_hp);
    APPLY_MAX_HP: inc(ch.point.max_hp, modif);
    APPLY_MV: ch.point.mv := UMin(ch.point.mv + modif, ch.point.max_mv);
    APPLY_MAX_MV: inc(ch.point.max_mv, modif);
    APPLY_MANA: ch.point.mana := UMin(ch.point.mana + modif, ch.point.max_mana);
    APPLY_MAX_MANA: inc(ch.point.max_mana, modif);
    APPLY_APB: inc(ch.point.apb, modif);
    APPLY_AFFECT: SET_BIT(ch.aff_flags, modif);
    APPLY_REMOVE: REMOVE_BIT(ch.aff_flags, modif);
    APPLY_STRIPSPELL: removeAffectSkill(ch, modif);
    APPLY_FULL: gain_condition(ch, COND_FULL, modif);
    APPLY_THIRST: gain_condition(ch, COND_THIRST, modif);
    APPLY_DRUNK: gain_condition(ch, COND_DRUNK, modif);
    APPLY_CAFFEINE: gain_condition(ch, COND_CAFFEINE, modif);
  end;
end;

procedure GAffect.applyTo(ch : GCharacter);
var
   aff : GAffect;
   node : GListNode;
begin
  if (duration > 0) then
    begin
    aff := GAffect.Create;
    aff.sn := Self.sn;
    aff.apply_type := Self.apply_type;
    aff.duration := Self.duration;
    aff.modifier := Self.modifier;

    aff.node := ch.affects.insertLast(aff);

    aff.modify(ch, true);
    end
  else
    modify(ch, true);
end;

function findApply(s : string) : GApplyTypes;
begin
  s := uppercase(s);

  if (s = 'APPLY_HP') then
    Result := APPLY_HP
  else
  if (s = 'APPLY_MAX_HP') then
    Result := APPLY_MAX_HP
  else
  if (s = 'APPLY_MV') then
    Result := APPLY_MV
  else
  if (s = 'APPLY_MAX_MV') then
    Result := APPLY_MAX_MV
  else
  if (s = 'APPLY_MANA') then
    Result := APPLY_MANA
  else
  if (s = 'APPLY_MAX_MANA') then
    Result := APPLY_MAX_MANA
  else
  if (s = 'APPLY_AFFECT') then
    Result := APPLY_AFFECT
  else
  if (s = 'APPLY_REMOVE') then
    Result := APPLY_REMOVE
  else
  if (s = 'APPLY_AC') then
    Result := APPLY_AC
  else
  if (s = 'APPLY_STRIPSPELL') then
    Result := APPLY_STRIPSPELL
  else
    begin
    bugreport('findApply', 'skills.pas', 'Illegal apply type "' + s + '"', '');
    Result := APPLY_NONE;
    end;
end;

function findAffect(ch:GCharacter;sn:integer) : GAffect;
var
   node : GListNode;
   aff : GAffect;
begin
  findAffect := nil;

  node := ch.affects.head;

  while (node <> nil) do
    begin
    aff := node.element;

    if (aff.sn = sn) then
      begin
      findAffect := aff;
      exit;
      end;

    node := node.next;
    end;
end;

procedure removeAffect(ch : GCharacter; aff : GAffect);
begin
  aff.modify(ch, false);

  ch.affects.remove(aff.node);

  aff.Free;
end;

function removeAffectSkill(ch:GCharacter;gsn:integer):boolean;
var
   aff : GAffect;
begin
  aff := findAffect(ch,gsn);

  if (aff = nil) then
    begin
    Result := false;
    exit;
    end;

  removeAffect(ch, aff);

  Result := true;
end;

function removeAffectFlag(ch:GCharacter;flag:integer):boolean;
var
   node : GListNode;
   aff : GAffect;
begin
  removeAffectFlag := false;
  aff := nil;
  node := ch.affects.head;

  while (node <> nil) do
    begin
    if (GAffect(node.element).apply_type = APPLY_AFFECT) and (GAffect(node.element).modifier = flag) then
      begin
      aff := node.element;
      break;
      end;

    node := node.next;
    end;

  if (aff = nil) then
    exit;

  removeAffect(ch, aff);

  removeAffectFlag := true;
end;

procedure update_affects;
var i : integer;
    ch : GCharacter;
    node, node_aff : GListNode;
    aff : GAffect;
begin
  node := char_list.head;

  while (node <> nil) do
    begin
    ch := node.element;

    if IS_SET(ch.aff_flags,AFF_POISON) then
      begin
      act(AT_REPORT,'You shiver and suffer.',false,ch,nil,nil,TO_CHAR);
      act(AT_REPORT,'$n shivers and suffers.',false,ch,nil,nil,TO_ROOM);
      ch.mental_state:=URANGE(20,ch.mental_state+4,100);
      damage(ch,ch,6,gsn_poison);
      end;
{    if IS_SET(ch.aff_flags,AFF_COLD) then
      begin
      i:=random(5);
      case i of
        1:begin
          act(AT_REPORT,'You sneeze loudly... do you need a tissue?',false,ch,nil,nil,TO_CHAR);
          act(AT_REPORT,'$n sneezes loudly... maybe $e needs a tissue?',false,ch,nil,nil,TO_ROOM);
          end;
        2:begin
          act(AT_REPORT,'You sniff a bit.',false,ch,nil,nil,TO_CHAR);
          act(AT_REPORT,'$n sniffs a bit.',false,ch,nil,nil,TO_ROOM);
          end;
        3:begin
          act(AT_REPORT,'You don''t feel very well.',false,ch,nil,nil,TO_CHAR);
          act(AT_REPORT,'$n doesn''t look very well.',false,ch,nil,nil,TO_ROOM);
          ch.mental_state:=URANGE(20,ch.mental_state+1,100);
          end;
      end;
      end; }

    node_aff := ch.affects.head;

    while (node_aff <> nil) do
      begin
      aff := node_aff.element;

      dec(aff.duration);

      if (aff.duration = 0) then
        begin
        act(AT_REPORT, skill_table[aff.sn].wear_msg,false,ch,nil,nil,TO_CHAR);
        removeAffect(ch, aff);
        end;

      node_aff := node_aff.next;
      end;

    node := node.next;
    end;
end;

end.
