// $Id: skills.pas,v 1.14 2001/06/14 18:19:42 ***REMOVED*** Exp $

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
    GSkill = class;

    SPEC_FUNC = procedure(ch, victim : GCharacter; sn : GSkill);

    GAffect = class
      skill : GSkill;
      apply_type : GApplyTypes;
      modifier : longint;
      duration : longint;

      node : GListNode;

      procedure modify(ch : GCharacter; add : boolean);
      procedure applyTo(ch : GCharacter);
    end;

    GSkill = class
      id : integer;

      func : SPEC_FUNC;

      affects : GDLinkedList;
      prereqs : GDLinkedList;

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

      constructor Create;
      destructor Destroy; override;
    end;

var
   skill_table : GDLinkedList;

{ gsn's }
var
   gsn_slashing_weapons : GSkill;
   gsn_second_attack : GSkill;
   gsn_third_attack : GSkill;
   gsn_fourth_attack : GSkill;
   gsn_fifth_attack : GSkill;
   gsn_enhanced_damage : GSkill;
   gsn_dual_wield : GSkill;
   gsn_slashing : GSkill;
   gsn_piercing : GSkill;
   gsn_concussion : GSkill;
   gsn_whipping : GSkill;
   gsn_kick : GSkill;
   gsn_bash : GSkill;
   gsn_poison : GSkill;
   gsn_sneak : GSkill;
   gsn_swim : GSkill;
   gsn_searching : GSkill;
   gsn_backstab : GSkill;
   gsn_circle : GSkill;
   gsn_rescue : GSkill;
   gsn_dodge : GSkill;
   gsn_track : GSkill;
   gsn_peek : GSkill;
   gsn_hide : GSkill;


procedure load_skills;

function findSkill(s : string) : GSkill;
function findSkillPlayer(ch : GCharacter; s : string) : GSkill;

procedure improve_skill(ch : GCharacter; sn : GSkill);
function skill_success(ch : GCharacter; sn : GSkill) : boolean;

function findApply(s : string) : GApplyTypes;
function printApply(apply : GApplyTypes) : string;
function findAffect(ch : GCharacter; sn : GSkill) : GAffect;
procedure removeAffect(ch : GCharacter; aff : GAffect);
function removeAffectSkill(ch:GCharacter; sn : GSkill):boolean;
function removeAffectFlag(ch:GCharacter;flag:integer):boolean;
procedure update_affects;


implementation

uses
    strip,
    magic,
    fight,
    update,
    mudsystem;


function findSkill(s : string) : GSkill;
var
   node : GListNode;
   sk : GSkill;
begin
  s := trim(uppercase(s));
  Result := nil;
  node := skill_table.head;

  while (node <> nil) do
    begin
    sk := node.element;

    if (s = uppercase(sk.name)) or (pos(s, uppercase(sk.name)) = 1) then
      begin
      Result := sk;
      break;
      end;

    node := node.next;
    end;
end;

function findSkillPlayer(ch : GCharacter; s : string) : GSkill;
var
   sk : GSkill;
begin
  sk := findSkill(s);
  Result := nil;

  if (ch.LEARNED(sk) > 0) then
    Result := sk;
end;

function assign_gsn(name : string) : GSkill;
var
   gsn : GSkill;
begin
  gsn := findSkill(name);

  if (gsn = nil) then
    bugreport('assign_gsn', 'skills.pas', 'skill '''+name+''' not found',
              'The specified skill could not be found.');

  assign_gsn := gsn;
end;

procedure process_affect(skill : GSkill; format : string);
var
   aff : GAffect;
begin
  aff := GAffect.Create;
  aff.skill := skill;

  with aff do
    begin
    apply_type := findApply(left(format, ' '));

    format := right(format, ' ');

    modifier := cardinal(findSkill(left(format, ' ')));

    if (modifier = 0) then
      modifier := strtointdef(left(format, ' '), 0);

    format := right(format, ' ');
    duration := strtointdef(left(format, ' '), 0);
    end;

  aff.node := skill.affects.insertLast(aff);
end;

procedure load_skills;
var f:textfile;
    s,g,a:string;
    num : integer;
    sk, skill : GSkill;
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

  num := 0;

  repeat
    repeat
      readln(f,s);
    until (uppercase(s) = '#SKILL') or (eof(f));

    if (eof(f)) then
      break;

    skill := GSkill.Create;
    skill.id := num;

    with skill do
      repeat
      readln(f, s);

      g := uppercase(left(s,':'));

      if (g = 'TYPE') then
        begin
        s := uppercase(right(s,' '));

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
        name := right(s,' ')
      else
      if g='ROUNDS' then
        beats:=strtoint(right(s,' '))
      else
      if g='MINLEVEL' then
        min_lvl:=strtoint(right(s,' '))
      else
      if g='MANA' then
        min_mana:=strtoint(right(s,' '))
      else
      if g='TARGET' then
        target:=strtoint(right(s,' '))
      else
      if g='FUNCTION' then
        func := findFunc(right(s,' '))
      else
      if g='STARTCHAR' then
        start_char := right(s,' ')
      else
      if g='STARTVICT' then
        start_vict := right(s,' ')
      else
      if g='STARTROOM' then
        start_room := right(s,' ')
      else
      if g='HITCHAR' then
        hit_char := right(s,' ')
      else
      if g='HITVICT' then
        hit_vict := right(s,' ')
      else
      if g='HITROOM' then
        hit_room := right(s,' ')
      else
      if g='MISSCHAR' then
        miss_char := right(s,' ')
      else
      if g='MISSVICT' then
        miss_vict := right(s,' ')
      else
      if g='MISSROOM' then
        miss_room := right(s,' ')
      else
      if g='DAMMSG' then
        dam_msg := right(s,' ')
      else
      if g='WEAROFF' then
        wear_msg := right(s,' ')
      else
      if g='DICE' then
        begin
        a:=uppercase(right(s,' '));
        dicenum:=strtoint(left(a,'D'));
        a:=right(a,'D');
        dicesize:=strtoint(left(a,'+'));
        a:=right(a,'+');
        diceadd:=strtoint(left(a,' '));
        end
      else
      if g='AFFECTS' then
        process_affect(skill, right(s,' '))
      else
      if g='PREREQ' then
        begin
        a := right(s, ' ');
        sk := findSkill(a);

        if (sk <> nil) then
          prereqs.insertLast(sk)
        else
          bugreport('load_skills', 'skills.pas', 'Could not find prereq skill ' + a,
                    'The specified skill could not be found.');
        end;
      until uppercase(s)='#END';

    skill_table.insertLast(skill);

    inc(num);
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

procedure improve_skill(ch : GCharacter; sn : GSkill);
var chance, percent : integer;
begin
  if (ch.LEARNED(sn) = 100) then
    exit;

  chance := ch.LEARNED(sn) - (ch.wis div 5);

  percent := number_percent;

  if (percent <= chance div 3) then
    begin
    act(AT_WHITE, '[You have become better at ' + sn.name + '!]',false,ch,nil,nil,TO_CHAR);
    ch.SET_LEARNED(UMin(ch.LEARNED(sn) + 1, 100), sn);
    end;
end;

function skill_success(ch : GCharacter; sn : GSkill) : boolean;
begin
  skill_success := (number_percent <= ch.LEARNED(sn));
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
      APPLY_STRIPSPELL: exit;
    end;

    modif := -modif;
    end;

  case apply_type of
    APPLY_STR: ch.str := UMin(ch.str + modif, 100);
    APPLY_DEX: ch.dex := UMin(ch.dex + modif, 100);
    APPLY_INT: ch.int := UMin(ch.int + modif, 100);
    APPLY_WIS: ch.wis := UMin(ch.wis + modif, 100);
    APPLY_CON: ch.con := UMin(ch.con + modif, 100);
    APPLY_HP: ch.hp := UMin(ch.hp + modif, ch.max_hp);
    APPLY_MAX_HP: ch.max_hp := UMin(ch.max_hp + modif, 15000);
    APPLY_MV: ch.mv := UMin(ch.mv + modif, ch.max_mv);
    APPLY_MAX_MV: ch.max_mv := UMin(ch.max_mv + modif, 15000);
    APPLY_MANA: ch.mana := UMin(ch.mana + modif, ch.max_mana);
    APPLY_MAX_MANA: ch.max_mana := UMin(ch.max_mana + modif, 15000);
    APPLY_AC: begin
              inc(ch.ac, modif);
              ch.calcAC;
              end;
    APPLY_APB: ch.apb := ch.apb + modif;
    APPLY_AFFECT: SET_BIT(ch.aff_flags, modif);
    APPLY_REMOVE: REMOVE_BIT(ch.aff_flags, modif);
    APPLY_STRIPSPELL: removeAffectSkill(ch, GSkill(pointer(modif)));
    APPLY_FULL: gain_condition(ch, COND_FULL, modif);
    APPLY_THIRST: gain_condition(ch, COND_THIRST, modif);
    APPLY_DRUNK: gain_condition(ch, COND_DRUNK, modif);
    APPLY_CAFFEINE: gain_condition(ch, COND_CAFFEINE, modif);
  end;
end;

procedure GAffect.applyTo(ch : GCharacter);
var
   aff : GAffect;
begin
  if (duration > 0) then
    begin
    aff := GAffect.Create;
    aff.skill := Self.skill;
    aff.apply_type := Self.apply_type;
    aff.duration := Self.duration;
    aff.modifier := Self.modifier;

    if (findAffect(ch, Self.skill) = nil) then // not yet affected
      aff.node := ch.affects.insertLast(aff);

    aff.modify(ch, true);
    end
  else
    modify(ch, true);
end;

function findApply(s : string) : GApplyTypes;
begin
  s := uppercase(s);

  if (s = 'APPLY_STR') then
    Result := APPLY_STR
  else
  if (s = 'APPLY_DEX') then
    Result := APPLY_DEX
  else
  if (s = 'APPLY_INT') then
    Result := APPLY_INT
  else
  if (s = 'APPLY_WIS') then
    Result := APPLY_WIS
  else
  if (s = 'APPLY_CON') then
    Result := APPLY_CON
  else
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
  if (s = 'APPLY_APB') then
    Result := APPLY_APB
  else
  if (s = 'APPLY_STRIPSPELL') then
    Result := APPLY_STRIPSPELL
  else
  if (s = 'APPLY_FULL') then
    Result := APPLY_FULL
  else
  if (s = 'APPLY_THIRST') then
    Result := APPLY_THIRST
  else
  if (s = 'APPLY_DRUNK') then
    Result := APPLY_DRUNK
  else
  if (s = 'APPLY_CAFFEINE') then
    Result := APPLY_CAFFEINE
  else
    begin
    bugreport('findApply', 'skills.pas', 'Illegal apply type "' + s + '"', '');
    Result := APPLY_NONE;
    end;
end;

function printApply(apply : GApplyTypes) : string;
begin
  case apply of
    APPLY_STR: Result := 'apply_str';
    APPLY_CON: Result := 'apply_con';
    APPLY_INT: Result := 'apply_int';
    APPLY_WIS: Result := 'apply_wis';
    APPLY_DEX: Result := 'apply_dex';
    APPLY_AC : Result := 'apply_ac';
    APPLY_APB : Result := 'apply_apb';
    APPLY_STRIPSPELL : Result := 'apply_stripspell';
    APPLY_AFFECT : Result := 'apply_affect';
    APPLY_REMOVE : Result := 'apply_remove';
    APPLY_FULL : Result := 'apply_full';
    APPLY_THIRST : Result := 'apply_thirst';
    APPLY_DRUNK : Result := 'apply_drunk';
    APPLY_CAFFEINE : Result := 'apply_caffeine';
    APPLY_HP : Result := 'apply_hp';
    APPLY_MAX_HP : Result := 'apply_max_hp';
    APPLY_MV : Result := 'apply_mv';
    APPLY_MAX_MV : Result := 'apply_max_mv';
    APPLY_MANA : Result := 'apply_mana';
    APPLY_MAX_MANA : Result := 'apply_max_mana';
    else Result := 'apply_none';
  end;
end;

function findAffect(ch : GCharacter; sn : GSkill) : GAffect;
var
   node : GListNode;
   aff : GAffect;
begin
  findAffect := nil;

  node := ch.affects.head;

  while (node <> nil) do
    begin
    aff := node.element;

    if (aff.skill = sn) then
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

function removeAffectSkill(ch:GCharacter; sn : GSkill):boolean;
var
   aff : GAffect;
begin
  aff := findAffect(ch, sn);

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
var ch : GCharacter;
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
      damage(ch,ch,6, cardinal(gsn_poison));
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
        act(AT_REPORT, aff.skill.wear_msg, false,ch,nil,nil,TO_CHAR);
        removeAffect(ch, aff);
        end;

      node_aff := node_aff.next;
      end;

    node := node.next;
    end;
end;

{ GSkill }
constructor GSkill.Create;
begin
  inherited Create;

  affects := GDLinkedList.Create;
  prereqs := GDLinkedList.Create;
end;

destructor GSkill.Destroy;
begin
  affects.clean;
  affects.Free;

  prereqs.smallClean;
  prereqs.Free;
  
  inherited Destroy;
end;

begin
  skill_table := GDLinkedList.Create;
end.

