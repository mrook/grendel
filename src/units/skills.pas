{
  Summary:
  	Various skill related functions
  
  ##	$Id: skills.pas,v 1.6 2004/02/27 22:24:21 ***REMOVED*** Exp $
}

unit skills;

interface


uses
	SysUtils,
	chars,
	dtypes,
	util,
	constants;


type
	GSkill = class;

	SPEC_FUNC = procedure(ch, victim : GCharacter; sn : GSkill);

	GModifier = record
		apply_type : GApplyTypes;
		modifier : longint;
	end;

	GAffect = class
	private
		_name : PString;      
		_wear_msg : string;
		_duration : integer;

	public
		modifiers : array of GModifier;
		node : GListNode;

		procedure modify(ch : GCharacter; add : boolean);
		procedure applyTo(ch : GCharacter);

		procedure setName(const name : string);
		function getName() : string;

	published
		property name : string read getName write setName;
		property wear_msg : string read _wear_msg write _wear_msg;
		property duration: integer read _duration write _duration;
	end;

	GSkill = class
	private
		_name : PString;

	public      
		id : integer;

		func : SPEC_FUNC;

		affects : GDLinkedList;
		prereqs : GDLinkedList;

		skill_type : integer;
		min_mana : integer;
		min_lvl : integer;
		beats : integer;
		target : integer;

		dicenum, dicesize, diceadd : integer;

		dam_msg : string;
		start_char, start_vict, start_room : string;
		hit_char, hit_vict, hit_room : string;
		miss_char, miss_vict, miss_room : string;
		die_char, die_vict, die_room : string;
		imm_char, imm_vict, imm_room : string;

		constructor Create();
		destructor Destroy(); override;

		procedure setName(const name : string);
		function getName() : string;

	published
		property name : string read getName write setName;    	
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
	gsn_lockpick : GSkill;


procedure load_skills();

function findSkill(s : string) : GSkill;
function findSkillPlayer(ch : GCharacter; const s : string) : GSkill;

procedure improve_skill(ch : GCharacter; sn : GSkill);
function skill_success(ch : GCharacter; sn : GSkill) : boolean;

function findApply(s : string) : GApplyTypes;
function printApply(apply : GApplyTypes) : string;
function findAffect(ch : GCharacter; const name : string) : GAffect;
procedure removeAffect(ch : GCharacter; aff : GAffect);
function removeAffectName(ch : GCharacter; const name : string):boolean;
function removeAffectFlag(ch : GCharacter; flag : integer):boolean;
procedure update_affects();

procedure initSkills();
procedure cleanupSkills();


implementation


uses
	strip,
	fsys,
	magic,
	fight,
	console,
	player,
	update,
	mudsystem;


// Find skill by name
function findSkill(s : string) : GSkill;
var
	iterator : GIterator;
	sk : GSkill;
begin
  s := trim(uppercase(s));
  Result := nil;
  iterator := skill_table.iterator();

  while (iterator.hasNext()) do
    begin
    sk := GSkill(iterator.next());

    if (s = uppercase(sk.name)) or (pos(s, uppercase(sk.name)) = 1) then
      begin
      Result := sk;
      break;
      end;
    end;
  
  iterator.Free();
end;

function findSkillPlayer(ch : GCharacter; const s : string) : GSkill;
var
   sk : GSkill;
begin
  sk := findSkill(s);
  Result := nil;

  if (ch.LEARNED(sk) > 0) then
    Result := sk;
end;

function assign_gsn(const name : string) : GSkill;
var
   gsn : GSkill;
begin
  gsn := findSkill(name);

  if (gsn = nil) then
    bugreport('assign_gsn', 'skills.pas', 'skill '''+name+''' not found');

  assign_gsn := gsn;
end;

// Load the skills
procedure load_skills();
var
  af : GFileReader;
  s, g, a : string;
  num, x : integer;
  sk, skill : GSkill;
  aff : GAffect;
  modif : integer;
begin
  try
    af := GFileReader.Create('system\skills.dat');
  except
    exit;
  end;

  num := 0;

  repeat
    repeat
      s := af.readLine();
//      writeln('line: ', s);
    until (uppercase(s) = '#SKILL') or (af.eof());

    if (af.eof()) then
      break;

    skill := GSkill.Create;
    skill.id := num;

    with skill do
      repeat
      g := uppercase(left(af.readToken(), ':'));

      if (g = 'TYPE') then
        begin
        s := uppercase(af.readToken());

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
        name := af.readLine()
      else
      if g='ROUNDS' then
        beats := af.readInteger()
      else
      if g='MINLEVEL' then
        min_lvl := af.readInteger()
      else
      if g='MANA' then
        min_mana := af.readInteger()
      else
      if g='TARGET' then
        target := af.readInteger()
      else
      if g='FUNCTION' then
        func := findFunc(af.readToken())
      else
      if g='STARTCHAR' then
        start_char := af.readLine()
      else
      if g='STARTVICT' then
        start_vict := af.readLine()
      else
      if g='STARTROOM' then
        start_room := af.readLine()
      else
      if g='HITCHAR' then
        hit_char := af.readLine()
      else
      if g='HITVICT' then
        hit_vict := af.readLine()
      else
      if g='HITROOM' then
        hit_room := af.readLine()
      else
      if g='MISSCHAR' then
        miss_char := af.readLine()
      else
      if g='MISSVICT' then
        miss_vict := af.readLine()
      else
      if g='MISSROOM' then
        miss_room := af.readLine()
      else
      if g='DAMMSG' then
        dam_msg := af.readLine()
      else
      if g='DICE' then
        begin
        a:=uppercase(af.readLine());
        dicenum:=strtoint(left(a,'D'));
        a:=right(a,'D');
        dicesize:=strtoint(left(a,'+'));
        a:=right(a,'+');
        diceadd:=strtoint(left(a,' '));
        end
      else
      if g='AFFECTS' then
        begin
        aff := GAffect.Create();

        aff.name := af.readToken();
        aff.wear_msg := af.readToken();

        aff.duration := af.readInteger();
        x := 1;
              
        while (not af.eol) and (af.readToken = '{') do
          begin
          setLength(aff.modifiers, x);
          
          s := af.readToken();

          aff.modifiers[x - 1].apply_type := findApply(s);

          s := af.readToken();

          modif := StrToIntDef(s, 0);
          
          if (modif = 0) then
            modif := cardinal(hash_string(s));

          aff.modifiers[x - 1].modifier := modif;

          s := af.readToken();
          
          inc(x);
          end;

        aff.node := affects.insertLast(aff);
        end
      else
      if g='PREREQ' then
        begin
        a := af.readToken();
        sk := findSkill(a);

        if (sk <> nil) then
          prereqs.insertLast(sk)
        else
          bugreport('load_skills', 'skills.pas', 'Could not find prereq skill ' + a);
        end;
      until g='#END';

    skill_table.insertLast(skill);

    inc(num);
  until (af.eof());

  af.Free;

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
  gsn_lockpick := assign_gsn('lockpick');
end;

// Improve skill
procedure improve_skill(ch : GCharacter; sn : GSkill);
var
	chance, percent : integer;
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

// Check whether a skill is succesful or not
function skill_success(ch : GCharacter; sn : GSkill) : boolean;
begin
  skill_success := (number_percent <= ch.LEARNED(sn));
end;

// Apply modifiers
procedure GAffect.modify(ch : GCharacter; add : boolean);
var
  modif : integer;
  a : integer;
begin
  for a := 0 to length(modifiers) - 1 do
    begin
    modif := modifiers[a].modifier;

    if (not add) then
      begin
      case (modifiers[a].apply_type) of
        APPLY_AFFECT: begin
                      REMOVE_BIT(ch.aff_flags, modif);
                      continue;
                      end;
        APPLY_REMOVE: begin
                      SET_BIT(ch.aff_flags, modif);
                      continue;
                      end;
        APPLY_STRIPNAME: continue;
      end;

      modif := -modif;
      end;

    case (modifiers[a].apply_type) of
      APPLY_STR: ch.str := ch.str + modif;
      APPLY_DEX: ch.dex := ch.dex + modif;
      APPLY_INT: ch.int := ch.int + modif;
      APPLY_WIS: ch.wis := ch.wis + modif;
      APPLY_CON: ch.con := ch.con + modif;
      APPLY_HP: ch.hp := ch.hp + modif;
      APPLY_MAX_HP: ch.max_hp := ch.max_hp + modif;
      APPLY_MV: ch.mv := ch.mv + modif;
      APPLY_MAX_MV: ch.max_mv := ch.max_mv + modif;
      APPLY_MANA: ch.mana := ch.mana + modif;
      APPLY_MAX_MANA: ch.max_mana := ch.max_mana + modif;
      APPLY_AC: begin
                inc(ch.ac_mod, modif);
                ch.calcAC;
                end;
      APPLY_APB: ch.apb := ch.apb + modif;
      APPLY_AFFECT: SET_BIT(ch.aff_flags, modif);
      APPLY_REMOVE: REMOVE_BIT(ch.aff_flags, modif);
      APPLY_STRIPNAME: removeAffectName(ch, PString(modif)^);
      APPLY_FULL: gain_condition(ch, COND_FULL, modif);
      APPLY_THIRST: gain_condition(ch, COND_THIRST, modif);
      APPLY_DRUNK: gain_condition(ch, COND_DRUNK, modif);
      APPLY_CAFFEINE: gain_condition(ch, COND_CAFFEINE, modif);
    end;
  end;
end;

// Apply affect to char
procedure GAffect.applyTo(ch : GCharacter);
var
	aff : GAffect;
begin
  if (duration > 0) then
    begin
    aff := GAffect.Create();
    aff.name := Self.name;
    aff.wear_msg := Self.wear_msg;
    aff.duration := Self.duration;

    aff.modifiers := Self.modifiers;

    if (findAffect(ch, Self.name) = nil) then // not yet affected
      aff.node := ch.affects.insertLast(aff);

    aff.modify(ch, true);
    end
  else
    modify(ch, true);
end;

procedure GAffect.setName(const name : string);
begin 
  if (_name <> nil) then
    unhash_string(_name);
    
  _name := hash_string(name);
end;

function GAffect.getName() : string;
begin
  if (_name <> nil) then
    Result := _name^
  else
    Result := '';
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
  if (s = 'APPLY_STRIPNAME') then
    Result := APPLY_STRIPNAME
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
    bugreport('findApply', 'skills.pas', 'Illegal apply type "' + s + '"');
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
    APPLY_STRIPNAME : Result := 'apply_stripname';
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

// Find affect by name on char
function findAffect(ch : GCharacter; const name : string) : GAffect;
var
	iterator : GIterator;
	aff : GAffect;
begin
  Result := nil;

  iterator := ch.affects.iterator();

  while (iterator.hasNext()) do
    begin
    aff := GAffect(iterator.next());

    if (aff.name = name) then
      begin
      Result := aff;
      exit;
      end;
    end;
    
  iterator.Free();
end;

// Remove affect <aff> from char
procedure removeAffect(ch : GCharacter; aff : GAffect);
begin
  aff.modify(ch, false);

  ch.affects.remove(aff.node);

  aff.Free;
end;

// Remove affect by name from char
function removeAffectName(ch : GCharacter; const name : string) : boolean;
var
   aff : GAffect;
begin
  Result := false;
  
  if (length(name) = 0) then
    exit;
    
  aff := findAffect(ch, name);

  if (aff = nil) then
    exit;

  removeAffect(ch, aff);

  Result := true;
end;

// Remove affect flag from char
function removeAffectFlag(ch : GCharacter; flag : integer) : boolean;
var
	iterator : GIterator;
	aff, taff : GAffect;
	a : integer;
begin
  removeAffectFlag := false;
  aff := nil;
  iterator := ch.affects.iterator();

  while (iterator.hasNext()) do
    begin
    taff := GAffect(iterator.next());

    for a := 0 to length(taff.modifiers) - 1 do
      begin
      if (taff.modifiers[a].apply_type = APPLY_AFFECT) and (taff.modifiers[a].modifier = flag) then
        begin
        aff := taff;
        break;
        end;
      end;
    end;
    
  iterator.Free();

  if (aff = nil) then
    exit;

  removeAffect(ch, aff);

  removeAffectFlag := true;
end;

// Update affects
procedure update_affects();
var 
	ch : GCharacter;
	aff : GAffect;
	iterator_char, iterator_aff : GIterator;
begin
  iterator_char := char_list.iterator();

  while (iterator_char.hasNext()) do
    begin
    ch := GCharacter(iterator_char.next());

    if (IS_SET(ch.aff_flags,AFF_POISON)) then
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

    iterator_aff := ch.affects.iterator();

    while (iterator_aff.hasNext()) do
      begin
      aff := GAffect(iterator_aff.next());

      aff.duration := aff.duration - 1;

      if (aff.duration = 0) then
        begin
        act(AT_REPORT, aff.wear_msg, false,ch,nil,nil,TO_CHAR);
        removeAffect(ch, aff);
        end;
      end;
      
    iterator_aff.Free();
    end;
    
	iterator_char.Free();    
end;

{ GSkill }
constructor GSkill.Create();
begin
  inherited Create();

  affects := GDLinkedList.Create();
  prereqs := GDLinkedList.Create();
end;

destructor GSkill.Destroy;
begin
  affects.clean();
  affects.Free();

  prereqs.smallClean();
  prereqs.Free();
  
  inherited Destroy();
end;

procedure GSkill.setName(const name : string);
begin 
  if (_name <> nil) then
    unhash_string(_name);
    
  _name := hash_string(name);
end;

function GSkill.getName() : string;
begin
  if (_name <> nil) then
    Result := _name^
  else
    Result := '';
end;

procedure initSkills();
begin
  skill_table := GDLinkedList.Create();
end;

procedure cleanupSkills();
begin
  skill_table.clean();
  skill_table.Free();
end;

end.

