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

    GSkill = class
      func : SPEC_FUNC;
      affect : GAffect;

      name : string;
      skill_type:integer;
      min_mana:integer;
      min_lvl:integer;
      beats:integer;
      target:integer;

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


procedure load_skills;
procedure done_skills;

function findSkill(s : string) : integer;
function findSkillPlayer(ch : GCharacter; s : string) : integer;

procedure improve_skill(ch : GCharacter; sn : integer);
function skill_success(ch : GCharacter; sn : integer) : boolean;

function findAffect(ch:GCharacter;sn:integer) : GAffect;
procedure doAffect(ch:GCharacter;affect:GAffect);
procedure removeAffect(ch : GCharacter; aff : GAffect);
function removeAffectSkill(ch:GCharacter;gsn:integer):boolean;
function removeAffectFlag(ch:GCharacter;flag:integer):boolean;
procedure update_affects;


implementation

uses
    strip,
    magic,
    fight,
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

procedure process_affect(skill : GSkill; s : integer; format:string);
begin
  skill.affect := GAffect.Create;
  with skill.affect do
    begin
    sn:=s;
    aff_type:=upcase(format[1]);
    format:=striprbeg(format,' ');
    modifier:=strtoint(stripl(format,' '));
    format:=striprbeg(format,' ');
    duration:=strtoint(stripl(format,' '));
    format:=striprbeg(format,' ');
    aff_flag:=strtoint(stripl(format,' '));
    end;
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

  num_skills := 0;

  repeat
    repeat
      readln(f,s);
    until (uppercase(s) = '#SKILL');

    skill := GSkill.Create;

    skill.affect := nil;

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
        name := hash_string(striprbeg(s,' '))
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
        process_affect(skill, num_skills, striprbeg(s,' '));
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

procedure doAffect(ch:GCharacter;affect:GAffect);
var
   aff : GAffect;
   node : GListNode;
begin
  if (affect = nil) then
    exit;
    
  with ch do
  { first check if the damn affect doesn't exist already }
    begin
    aff := findAffect(ch,affect.sn);

    if (aff <> nil) then
      begin
      aff.duration := affect.duration; {reset duration }
      exit;
      end;

    aff := GAffect.Create;
    aff.sn := affect.sn;
    aff.aff_type := affect.aff_type;
    aff.aff_flag := affect.aff_flag;
    aff.duration := affect.duration;
    aff.modifier := affect.modifier;

    if (aff.duration > 0) then
      begin
      SET_BIT(ch.aff_flags, affect.aff_flag);
      aff.node := ch.affects.insertLast(aff);
      end;

    with aff do
      case aff_type of
          'H':inc(ch.point.max_hp, modifier);
          'M':inc(ch.point.max_mv, modifier);
          'N':inc(ch.point.max_mana, modifier);
          'S':inc(ch.ability.str, modifier);
          'C':inc(ch.ability.con, modifier);
          'D':inc(ch.ability.dex, modifier);
          'I':inc(ch.ability.int, modifier);
          'W':inc(ch.ability.wis, modifier);
          'F':ch.startFlying;
          'A':begin
              inc(ch.point.ac_mod,modifier);

              ch.calcAC;
              end;
      end;
    end;
end;

procedure removeAffect(ch : GCharacter; aff : GAffect);
begin
  with aff do
    begin
    REMOVE_BIT(ch.aff_flags,aff_flag);

    case aff_type of
      'H':dec(ch.point.max_hp, modifier);
      'M':dec(ch.point.max_mv, modifier);
      'N':dec(ch.point.max_mana, modifier);
      'S':dec(ch.ability.str, modifier);
      'C':dec(ch.ability.con, modifier);
      'D':dec(ch.ability.dex, modifier);
      'I':dec(ch.ability.int, modifier);
      'W':dec(ch.ability.wis, modifier);
      'F':ch.stopFlying;
      'A':begin
          dec(ch.point.ac_mod,modifier);
          ch.calcAc;
          end;
    end;
    end;

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
    bugreport('removeAffectSkill', 'skills.pas', 'skill number null, ch ' + ch.name,
              'An attempt was made to remove an unexisting affect.');
    exit;
    end;

  removeAffect(ch, aff);

  removeAffectSkill := true;
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
    if (GAffect(node.element).aff_flag = flag) then
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
