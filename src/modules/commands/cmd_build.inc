// $Id: cmd_build.inc,v 1.1 2003/12/12 13:19:49 ***REMOVED*** Exp $

{Jago 10/Jan/2001 : new imm commands, copied from MERC }
{RSTAT : return data about a room}
procedure do_rstat(ch : GCharacter; param : string);
var
  buf, buf1, arg, buf_flags, str : string;
  location : GRoom;
  obj_data : GObject;
  obj_node : GListNode;
  rch : GCharacter;
  rch_node : GListNode;
  door : integer;
  exit_data : GExit;
  exit_node : GListNode;
  a : integer;
begin
  param := one_argument( param, arg );

  if arg = '' then
    location := ch.room
  else
    location := findLocation(ch, arg);

  if location = nil then
  begin
    ch.sendBuffer('No such location' + #13#10);
    exit;
  end;

  // allow rstat of private rooms

  buf1 := '';
  buf := Format('Name:   %s.' + #13#10 + 'Area:   %s.' + #13#10 + 'Vnum:   %d'#13#10#13#10,
                 [location.name, location.area.name, location.vnum]);

  buf1 := buf1 + buf;

  buf := 'Areacoords: ';
  if (location.areacoords <> nil) then
    buf := buf + location.areacoords.toString()
  else
    buf := buf + '(none)';
  buf := buf + '. Worldcoords: ';
  if (location.worldcoords <> nil) then
    buf := buf + location.worldcoords.toString()
  else
    buf := buf + '(none)';
  buf1 := buf1 + buf + #13#10;

  buf1 := buf1 + 'Characters: ';

  buf := '';
  rch_node := location.chars.head;
  while rch_node <> nil do
  begin
    rch := GCharacter(rch_node.element);

    if (length(buf) <> 0) then
      buf := buf + ', ';

    buf := buf + rch.name;

    rch_node := rch_node.next;
  end;

  buf1 := buf1 + buf + '.'#13#10;

  buf1 := buf1 + 'Objects:    ';

  buf := '';
  obj_node := location.objects.head;
  while obj_node <> nil do
  begin
    obj_data := GObject(obj_node.element);

    if (length(buf) <> 0) then
      buf := buf + ', ';

    buf := buf + obj_data.name;
    
    obj_node := obj_node.next;
  end;

  if (length(buf) <> 0) then
    buf1 := buf1 + buf + '.';
  buf1 := buf1 + #13#10#13#10;

  buf := Format('Sectortype: [%s].' + #13#10,
                [sector_types[location.sector]]);

  buf1 := buf1 + buf;

  buf := '';
  
  if (location.flags.value = 0) then
    buf := 'none'
  else
    for a:=0 to High(room_flags) do
      if (location.flags.isBitSet(1 shl a)) then
        begin
        if (length(buf) <> 0) then
          buf := buf + ' ';
   
        buf := buf + room_flags[a];
        end;

  buf1 := buf1 + Format('Room flags: [%s].' + #13#10,
                [buf]);
  buf1 := buf1 + Format('Light:      %d.' + #13#10,
                [location.light]);
  
  buf1 := buf1 + #13#10;

  buf1 := buf1 +
    Format('Televnum: %d. Teledelay: %d.'#13#10, [location.televnum, location.teledelay]);

  buf1 := buf1 +
    Format('Min_level: %d. Max_level: %d.'#13#10#13#10, [location.minlevel, location.maxlevel]);
  
  buf1 := buf1 +
    Format('Description: ' + #13#10 + '%s'#13#10, [location.description]);
  
  door := 0;
  buf := '';
  exit_node := location.exits.head;
  while (exit_node <> nil) do
  begin
    exit_data := GExit(exit_node.element);

    inc(door);

    if (exit_data.flags = 0) then
      buf_flags := 'none'
    else
    begin
      buf_flags := '';
      for a:=0 to High(exit_flags) do
        if IS_SET(exit_data.flags,1 shl a) then
        begin
          if (length(buf_flags) <> 0) then
            buf_flags := buf_flags + ' ';
          buf_flags := buf_flags + exit_flags[a];
        end;
    end;

    if (exit_data.keywords <> nil) then
      str := exit_data.keywords^
    else
      str := '(none)';
      
    buf := buf + Format('Door: %d.  To: %d.  Key: %d.  Keyword: [%s].'#13#10'  Exit flags: [%s]'#13#10,
                  [door,
                  exit_data.to_room.vnum,
                  exit_data.key,
                  str,
                  buf_flags]);
                  
    exit_node := exit_node.next;
  end;

  if (length(buf) = 0) then
    buf1 := buf1 + 'No exits.'#13#10
  else
    buf1 := buf1 + buf;

  ch.sendBuffer(buf1);
end;

{Jago 10/Jan/2001 - utility function}
function actBitName(vector : integer) : String;
begin
  Result := '';

  if (vector and ACT_SENTINEL) = ACT_SENTINEL then Result := Result + 'sentinel';
  if (vector and ACT_SCAVENGER) = ACT_SCAVENGER then Result := Result + 'scavenger';
  if (vector and ACT_AGGRESSIVE) = ACT_AGGRESSIVE then Result := Result + 'aggressive';
  if (vector and ACT_STAY_AREA) = ACT_STAY_AREA then Result := Result + 'stay_area';
  if (vector and ACT_TEACHER) = ACT_TEACHER then Result := Result + 'teacher';
end;

{Jago 10/Jan/2001 - utility function}
{ // this is now obsolete
function affectBitName(vector : integer) : String;
begin
  Result := '';

  if (vector and AFF_BLIND) = AFF_BLIND then Result := Result + ' blind';
  if (vector and AFF_INVISIBLE) = AFF_INVISIBLE then Result := Result + 'invisible';
  if (vector and AFF_DETECT_INVIS) = AFF_DETECT_INVIS then Result := Result +' detect invis';
  if (vector and AFF_DETECT_HIDDEN) = AFF_DETECT_HIDDEN then Result := Result+ ' detect hidden';
  if (vector and AFF_SANCTUARY) = AFF_SANCTUARY then Result := Result + 'sanctuary';
  if (vector and AFF_POISON) = AFF_POISON then Result := Result + ' poison';
  if (vector and AFF_SNEAK) = AFF_SNEAK then Result := Result + ' sneak';
  if (vector and AFF_HIDE) = AFF_HIDE then Result := Result + ' hide';
  if (vector and AFF_FLYING) = AFF_FLYING then Result := Result + ' flying';
  if (vector and AFF_INFRAVISION) = AFF_INFRAVISION then Result := Result + 'infravision';
  if (vector and AFF_BERSERK) = AFF_BERSERK then Result := Result + 'beserk';
  if (vector and AFF_AQUA_BREATH) = AFF_AQUA_BREATH then Result := Result + 'aqua breath';
  if (vector and AFF_PLAGUE) = AFF_PLAGUE then Result := Result + ' plague';
  if (vector and AFF_ENCHANT) = AFF_ENCHANT then Result := Result + 'enchant';

  if Result = '' then
    Result := 'none';
end;
}

{Jago 10/Jan/2001 - utility function}
function affectLocName(location : integer) : string;
begin
  Result := '';    // dummy func, affect locations not implemented yet??
end;

{Jago 10/Jan/2001
MSTAT : return data about a mobile - can also be used on players}
{ Xenon 20/Feb/2001: renamed do_mstat() to do_pstat() }
procedure do_pstat(ch : GCharacter; param : string);
var
  buf, buf1, arg, gender, exp, vnum, room_vnum, wimpy : string;
  master, leader : string;
  victim : GCharacter;
  iterator : GIterator;
  g : GLearned;
  sk : GSkill;
  aff : GAffect;
begin

  one_argument( param, arg );

  if length(arg) = 0 then
  begin
    ch.SendBuffer('Pstat whom?' + #13#10);
    exit;
  end;

  victim := findCharWorld(ch, arg);

  if victim = nil then
  begin
    ch.sendBuffer('They aren''t here.' + #13#10);
    exit;
  end;

  buf1 := '';
  buf := 'Name: ' + victim.name + '.' + #13#10;
  buf1 := buf1 + buf;

  if victim.IS_NPC then
    begin
    if GNPC(victim).npc_index <> nil then
      vnum := IntToStr(GNPC(victim).npc_index.vnum)
    else
      vnum := '?';
    end
  else
    vnum := '0';

  if victim.sex = 0 then
    gender := 'male'
  else if victim.sex = 1 then
    gender := 'female'
  else if victim.sex = 2 then
    gender := 'neutral'
  else
    gender := 'unknown!';

  if victim.room = nil then
    room_vnum := ''
  else
   room_vnum := IntToStr(victim.room.vnum);

  buf := Format('Vnum: %s. Sex: %s. Room: %s' + #13#10,
                [vnum, gender, room_vnum]);

  buf1 := buf1 + buf;

  buf := Format('Str: %d.  Int: %d.  Wis: %d.  Dex: %d.  Con: %d.' + #13#10,
                [victim.str,
                victim.int,
                victim.wis,
                victim.dex,
                victim.con]);

  buf1 := buf1 + buf;

  buf := Format('Hp: %d/%d.  Mana: %d/%d.  Move: %d/%d.' + #13#10,
                [victim.hp, victim.max_hp,
                victim.mana, victim.max_mana,
                victim.mv, victim.max_mv]);

  buf1 := buf1 + buf;

  if victim.IS_NPC then
    exp := 'none'
  else
    exp := IntToStr(GPlayer(victim).xptot);

  buf := Format('Level: %d.  Align: %d.  AC: %d.  Gold: %d.  Exp: %s.' + #13#10,
                [victim.level, victim.alignment, victim.ac,
                victim.gold, exp]);

  buf1 := buf1 + buf;

  if (not victim.IS_NPC) then
  begin
    buf := Format('Max skillslots: %d.  Max spellslots: %d.  Practices left: %d.' + #13#10,
                  [GPlayer(victim).max_skills, GPlayer(victim).max_spells, GPlayer(victim).pracs]);

    buf1 := buf1 + buf;
  end;
  
  if victim.IS_NPC then
    wimpy := 'none'
  else
    wimpy := IntToStr(GPlayer(victim).wimpy);

  buf := Format('Hitroll: %d.  Position: %d.  Wimpy: %s.' + #13#10,
                [victim.hitroll,
                victim.position,
                wimpy]);

  buf1 := buf1 + buf;

  if not victim.IS_NPC then
    buf1 := buf1 + 'Page Lines: ' + IntToStr(GPlayer(victim).pagerlen) + '.' + #13#10;

  if victim.fighting <> nil then
    buf1 := buf1 + 'Fighting: ' + victim.fighting.name + '.' + #13#10
  else
    buf1 := buf1 + 'Fighting: (none).' + #13#10;

  if not victim.IS_NPC then
  begin
    buf := Format('Thirst: %d.  Full: %d.  Drunk: %d.' + #13#10,
                 [GPlayer(victim).condition[COND_THIRST],
                 GPlayer(victim).condition[COND_FULL],
                 GPlayer(victim).condition[COND_DRUNK]]);
   buf1 := buf1 + buf;

   // how to get # of items carried?
   buf := Format('Carry number: .  Carry weight: %d.' + #13#10,
                [victim.carried_weight]);

   buf1 := buf1 + buf;

   buf := Format('Age: %d.  Played: %d.  Timer: %d. ' + #13#10,
                [GPlayer(victim).age,
                round(GPlayer(victim).played),
                victim.wait]);

   buf1 := buf1 + buf;
  end;

  if victim.master <> nil then
    master := victim.master.name
  else
    master := '(none)';

  if victim.leader <> nil then
    leader := victim.leader.name
  else
    leader := '(none)';

  buf := Format('Master: %s.  Leader: %s.' + #13#10,
                [master, leader]);

  buf1 := buf1 + buf;

  buf := Format('Short description: %s.' + #13#10 + 'Long description: %s' + #13#10,
                [victim.short, victim.long]);

  buf1 := buf1 + buf;

  if (victim.affects.size() > 0) then
    begin
    buf := 'Affected by:'#13#10;
    iterator := victim.affects.iterator();
    while (iterator.hasNext()) do
      begin
      aff := GAffect(iterator.next());

      if (aff.name <> nil) then
        buf := buf + Format('  %20s (duration: %d)'#13#10, [aff.name^, aff.duration]);
      end;
    iterator.Free();
    
    buf1 := buf1 + buf + #13#10;
    end;

  if (victim.skills_learned.size() > 0) then
    with victim do
    begin
      buf1 := buf1 + #13#10;
      
      iterator := skills_learned.iterator();
      while (iterator.hasNext()) do
        begin
        g := GLearned(iterator.next());
        sk := g.skill;
        
        if (sk.skill_type = SKILL_SPELL) then
          buf := '  Spell: '
        else
          buf := '  Skill: ';

        buf1 := buf1 + buf + Format('%20s %d%%'#13#10, [sk.name^, g.perc]);        
        end;
      iterator.Free();
    end;
  
  act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);
end;

{Jago 10/Jan/2001 OSTAT : return data about an object}
{ Revised 28/Jan/2001 - Nemesis }
{ 19/Feb/2001 - Xenon : fixed bug that made grendel crash on ostat <object> }
procedure do_ostat(ch : GCharacter; param : string);
var buf, buf1, arg : string;
{    aff_node, obj_node : GListNode;
    aff_data : GAffect; }
    obj: GObject;
    room :integer;
    in_obj, carried_by : string;
begin

  one_argument( param, arg );

  if length(arg) = 0 then
    begin
    ch.sendBuffer('Ostat what?' + #13#10);
    exit;
    end;

  obj := ch.findInventory(arg);

  if (obj = nil) then
    obj := ch.room.findObject(arg);

  if (obj = nil) then
    obj := findObjectWorld(arg);

  if (obj = nil) then
    begin
    ch.sendBuffer('Nothing like that in hell, earth, or heaven.' + #13#10);
    exit;
    end;

  buf1 := 'Name: ' + obj.name + '.' + #13#10;

  buf := Format('Vnum: %d.  Type: %s.' + #13#10 +
                'Short description: %s.' + #13#10 +
                'Long description: %s$A$7' + #13#10,
                [obj.vnum,
                obj.name,
                obj.short,
                obj.long]);

  buf1 := buf1 + buf;

  buf := Format('Wear bits: %d.' + #13#10,
                [obj.flags]);

  buf1 := buf1 + buf;

  // note : objects dont have a level??
  buf := Format('Weight: %d. Cost: %d.  Timer: %d.  {Level: 0.}' + #13#10,
                [obj.getWeight,
                obj.cost,
                obj.timer]); //, obj.level]);

  buf1 := buf1 + buf;

  if obj.room = nil then
    room := 0
  else
    room := obj.room.vnum;

  if obj.in_obj = nil then
    in_obj := '(none)'
  else
   in_obj := obj.in_obj.name;

  if obj.carried_by = nil then
    carried_by := ''
  else
    carried_by := GCharacter(obj.carried_by).name;
    
  //carried_by := '(none)';

  buf := Format('In room: %d.  In object: %s.  Carried by: %s.  {Wear_loc: %s %s}.' + #13#10,
                [room, in_obj, carried_by, obj.wear_location1, obj.wear_location2]);

  buf1 := buf1 + buf;

  buf := Format('Values: %d %d %d %d.' + #13#10,
                [obj.value[1],
                obj.value[2],
                obj.value[3],
                obj.value[4]]);

  buf1 := buf1 + buf;

  // [no extra descriptions]
  // [no obj affects]

  act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);
end;

{Jago 17/Jan/2001 - utility function, move to util.pas}
function is_number( param : string ) : boolean;
var
temp : integer;
begin
  Result := True;
  try
    temp := StrToInt(param);
  except
    Result := False;
  end;
end;

{Jago 17/Jan/2001 - OLOAD - load an object}
procedure do_oload(ch : GCharacter; param : string);
var
  arg1, arg2 : string;
  newobj, obj : GObject;
  level : integer;
begin
  param := one_argument( param, arg1 );
  param := one_argument( param, arg2 );
  if (length(arg1) = 0) or (not is_number(arg1)) then
  begin
     ch.sendBuffer('Syntax: oload <vnum> <level>.' + #13#10);
     exit;
  end;

  if length(arg2) = 0 then
     level := umax(ch.level, ch.getTrust)
  else if (not is_number(arg2)) then
  begin
     ch.sendBuffer('Syntax: oload <vnum> <level>.' + #13#10);
     exit;
  end else begin
     level := StrToInt(arg2);

     if (level < 0) or (level > ch.getTrust) then
     begin
       ch.sendBuffer('Limited to your trust level.' + #13#10);
       exit;
     end;
  end;

  // get the obj index
  newobj := GObject(objectIndices[StrToInt(arg1)]);

  if (newobj = nil) then
    begin
    ch.sendBuffer('No object has that vnum.' + #13#10);
    exit;
    end;

  // create the obj
  obj := newobj.clone();

  // give obj to ch
  obj.toChar(ch);

  act(AT_WHITE, '$n has created $p!', false, ch, obj, nil, TO_ROOM);
  ch.sendBuffer('Ok.');
end;

{Jago 17/Jan/2001 - MLOAD - load a NPC}
procedure do_mload(ch : GCharacter; param : string);
var
  arg : string;
  mob_index : GNPCIndex;
  victim : GCharacter;
begin
  one_argument(param, arg);

  if length(arg) = 0 then
  begin
     ch.sendBuffer('Syntax: mload <vnum>.' + #13#10);
     exit;
  end;

  if not is_number(arg) then
  begin
     ch.sendBuffer('Mload what?.' + #13#10);
     exit;
  end;

  mob_index := findNPCIndex(StrToInt(arg));

  if mob_index = nil then
  begin
     ch.sendBuffer('No mob has that vnum.' + #13#10);
     exit;
  end;

  victim := instanceNPC(mob_index);

  if victim = nil then
  begin
     ch.sendBuffer('Mload who?.' + #13#10);
     exit;
  end;

  victim.toRoom(ch.room);
  act(AT_WHITE, '$n has created $N!', false, ch, nil, victim, TO_ROOM);
  ch.sendBuffer('Ok.'#13#10);
end;

{Jago 18/Jan/2001 - OFIND - find an object}
{ Revised 25/Feb/2001 - Nemesis }
procedure do_ofind(ch : GCharacter; param : string);
var buf : string;
    obj : GObject;
    iterator : GIterator;
    found, fAll : boolean;
begin
  found := false;
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Ofind what?' + #13#10);
    exit;
    end;

  fAll := (uppercase(param) = 'ALL');
  buf := #13#10 + '[Vnum] [Name]' + #13#10;

  iterator := objectIndices.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (fAll) or (isName(obj.name, param)) then
      begin
      found := true;
      buf := buf + pad_integer_front(obj.vnum,5) + '   ' + obj.name + #13#10;
      end;
    end;

  if (not found) then
    begin
    ch.sendBuffer('Nothing like that in hell, earth, or heaven.' + #13#10);
    exit;
    end;

  ch.sendPager(buf);
end;

{Jago 18/Jan/2001 - MFIND - find a NPC}
{ Revised 25/Feb/2001 - Nemesis }
procedure do_mfind(ch : GCharacter; param : string);
var 
  buf : string;
  found, fAll : boolean;
  iterator : GIterator;
  npc : GNPCIndex;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Mfind whom?' + #13#10);
    exit;
    end;

  found := False;
  fAll := (uppercase(param) = 'ALL');
  buf := #13#10 + '[Vnum] [Name]' + #13#10;

  iterator := npc_list.iterator();
  while (iterator.hasNext()) do
    begin
    npc := GNPCIndex(iterator.next());

    if (fAll) or (isName(npc.name^, param)) then
      begin
      found := True;
      buf := buf + pad_integer_front(npc.vnum,5) + '   ' + npc.name^ + #13#10;
      end;
    end;
  iterator.Free();

  if (not found) then
    begin
    ch.sendBuffer('Nothing like that in hell, earth, or heaven.' + #13#10);
    exit;
    end;

  ch.sendPager(buf);
end;

{ Adjust scores NPC's and PC's - Nemesis }
{ Xenon 20/Feb/2001: renamed do_ascore() to do_pset() }
procedure do_pset(ch:GCharacter;param:string);
var arg,arg2,arg3 : string;
    vict : GCharacter;
    value : integer;
    buf : string;
begin
  param := one_argument(param, arg);
  param := one_argument(param, arg2);
  one_argument(param, arg3);

  if (length(arg) = 0) then
    begin
    ch.sendBuffer('Usage:  PSET <victim> <type> <value>'#13#10#13#10);
    ch.sendBuffer('Types for both NPC and PC: hp, mana, moves, strength,'#13#10);
    ch.sendBuffer('wisdom, intelligence, dexterity, constitution, ac, apb,'#13#10);
    ch.sendBuffer('hitroll, alignment, gold, sex, level.'#13#10#13#10);
    ch.sendBuffer('Types for PC only: bank, xptnl, maxskills, maxspells, pracs.'#13#10);
    exit;
    end;

  if (length(arg) <> 0) and (length(arg2) = 0) then
    begin
    ch.sendBuffer('Please select <type> and <value>.'#13#10);
    exit;
    end;

  if (length(arg) <> 0) and (length(arg2) <> 0) and (length(arg3) = 0) then
    begin
    ch.sendBuffer('Please enter a <value>.'#13#10);
    exit;
    end;

  try                            // Xenon 21/Feb/2001: added try..except block
    value := StrToInt(arg3);
  except
    on EConvertError do
    begin
      ch.sendBuffer('Value must be a number.'#13#10);
      exit;
    end;
  else
    ch.sendBuffer('Couldn''t convert value.'#13#10);
    exit;
  end;

  if (uppercase(arg) = 'SELF') then
    vict := ch
  else
    vict := FindCharWorld(ch,arg);

  if (vict = nil) then
    begin
    ch.sendBuffer('That player cannot be found.'#13#10);
    exit;
    end;

  if (uppercase(arg2) = 'HP') then
    begin
    if (value <= 0) then
      begin
      ch.sendBuffer('Value must be > 0.'#13#10);
      exit;
      end;

    vict.max_hp := value;
    buf := 'Max HP';
    end
  else
  if (uppercase(arg2) = 'MANA') then
    begin
    if (value <= 0) then
      begin
      ch.sendBuffer('Value must be > 0.'#13#10);
      exit;
      end;

    vict.max_mana := value;
    buf := 'Max MANA';
    end
  else
  if (uppercase(arg2) = 'STAMINA') then
    begin
    if (value <= 0) then
      begin
      ch.sendBuffer('Value must be > 0.'#13#10);
      exit;
      end;
      
    vict.max_mv := value;
    buf := 'Max STAMINA';
    end
  else
  if (uppercase(arg2) = 'STRENGTH') then
    begin
    if (value >= 100) then
      begin
      ch.sendBuffer('Max value is 99.'#13#10);
      exit;
      end;

    vict.str := value;
    buf := 'STRENGTH';
    end
  else
  if (uppercase(arg2) = 'WISDOM') then
    begin
    if (value >= 100) then
      begin
      ch.sendBuffer('Max value is 99.'#13#10);
      exit;
      end;

    vict.wis := value;
    buf := 'WISDOM';
    end
  else
  if (uppercase(arg2) = 'DEXTERITY') then
    begin
    if (value >= 100) then
      begin
      ch.sendBuffer('Max value is 99.'#13#10);
      exit;
      end;

    vict.dex := value;
    buf := 'DEXTERITY';
    end
  else
  if (uppercase(arg2) = 'INTELLIGENCE') then
    begin
    if (value >= 100) then
      begin
      ch.sendBuffer('Max value is 99.'#13#10);
      exit;
      end;

    vict.int := value;
    buf := 'INTELLIGENCE';
    end
  else
  if (uppercase(arg2) = 'CONSTITUTION') then
    begin
    if (value >= 100) then
      begin
      ch.sendBuffer('Max value is 99.'#13#10);
      exit;
      end;

    vict.con:=value;
    buf := 'CONSTITUTION';
    end
  else
  if (uppercase(arg2) = 'AC') then
    begin
    vict.ac := value;
    buf := 'AC';
    end
  else
  if (uppercase(arg2) = 'HITROLL') then
    begin
    vict.hitroll := value;
    buf := 'HITROLL';
    end
  else
  if (uppercase(arg2) = 'ALIGNMENT') then
    begin
    vict.alignment := value;
    buf := 'ALIGNMENT';
    end
  else
  if (uppercase(arg2) = 'APB') then
    begin
    vict.apb := value;
    buf := 'APB';
    end
  else
  if (uppercase(arg2) = 'BANK') then
    begin
    if (vict.IS_NPC) then
      begin
      ch.sendBuffer('Type not possible for NPC.'#13#10);
      exit;
      end;

    if (value <= 0) then
      begin
      ch.sendBuffer('Value must be > 0.'#13#10);
      exit;
      end;

    GPlayer(vict).bankgold := value;
    buf := 'BANK';
    end
  else
  if (uppercase(arg2) = 'GOLD') then
    begin
    if (value <= 0) then
      begin
      ch.sendBuffer('Value must be > 0.'#13#10);
      exit;
      end;

    vict.gold := value;
    buf := 'GOLD';
    end
  else
  if (uppercase(arg2) = 'XPTNL') then
    begin
    if (vict.IS_NPC) then
      begin
      ch.sendBuffer('Type not possible for NPC.'#13#10);
      exit;
      end;

    if (value <= 0) then
      begin
      ch.sendBuffer('Value must be > 0.'#13#10);
      exit;
      end;
      
    GPlayer(vict).xptogo := value;
    buf := 'XP TNL';
    end
  else
  if (uppercase(arg2) = 'MAXSKILLS') then
  begin
    if (vict.IS_NPC) then
    begin
      ch.sendBuffer('Type not possible for NPC.'#13#10);
      exit;
    end;
      
    if (value <= 0) then
    begin
      ch.sendBuffer('Value must be > 0.'#13#10);
      exit;
    end;

    GPlayer(vict).max_skills := value;
    buf := 'MAXSKILLS';
  end
  else
  if (uppercase(arg2) = 'MAXSPELLS') then
  begin
    if (vict.IS_NPC) then
    begin
      ch.sendBuffer('Type not possible for NPC.'#13#10);
      exit;
    end;
    
    if (value <= 0) then
    begin
      ch.sendBuffer('Value must be >= 0.'#13#10);
      exit;
    end;
    
    GPlayer(vict).max_spells := value;
    buf := 'MAXSPELLS';
  end
  else
  if (uppercase(arg2) = 'PRACS') then
  begin
    if (vict.IS_NPC) then
    begin
      ch.sendBuffer('Type not possible for NPC.'#13#10);
      exit;
    end;
    
    if (value <= 0) then
    begin
      ch.sendBuffer('Value must be >= 0.'#13#10);
      exit;
    end;
    
    GPlayer(vict).pracs := value;
    buf := 'PRACS';
  end
  else
  if (uppercase(arg2) = 'SEX') then
    begin
    if (value > 2) or (value < 0) then
      begin
      ch.sendBuffer('Value must be 0 (male), 1 (female) or 2 (neutral).'#13#10);
      exit;
      end;

    vict.sex := value;
    buf := 'SEX';
    end
  else
  if (uppercase(arg2) = 'LEVEL') then
  begin
    if (vict.IS_NPC) then // if mob
    begin
      if (value < 0) or (value >= LEVEL_IMMORTAL) then
      begin
        ch.sendBuffer(Format('For NPCs value must be > 0 and < %d.'#13#10, [LEVEL_IMMORTAL]));
        exit;
      end;
    end
    else // if player
      if (value < 0) or (value > LEVEL_MAX) then
      begin
        ch.sendBuffer(Format('For players value must be > 0 and <= %d.'#13#10, [LEVEL_MAX]));
        exit;
      end;
    
    vict.level := value;
    buf := 'LEVEL';
  end
  else
    begin
    ch.sendBuffer('Wrong <type>, use PSET to see available types.'#13#10);
    exit;
    end;

  act(AT_REPORT,buf + ' of $N set to ' + inttostr(value) + '.',false,ch,nil,vict,TO_CHAR);
end;


procedure do_ocreate(ch : GCharacter; param : string);
var
   oindex, obj : GObject;
   sub : string;
   vnum : integer;
begin
  if (GPlayer(ch).area_fname='') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  if (GPlayer(ch).area=nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: OCREATE <objectvnum> <name>'#13#10#13#10);
    ch.sendBuffer('Creates a new object index.'#13#10);
    exit;
    end;

  param := one_argument(param,sub);

  try
    vnum := strtoint(sub);
  except
    ch.sendBuffer('Invalid numeric format.'#13#10);
    exit;
  end;

  if (vnum < GPlayer(ch).o_lo) or (vnum > GPlayer(ch).o_hi) then
    begin
    ch.sendBuffer('That vnum is outside your range.'#13#10);
    exit;
    end;

  if (objectIndices[vnum] <> nil) then
    begin
    ch.sendBuffer('That vnum has been used.'#13#10);
    exit;
    end;

  oindex := GObject.Create();
  oindex.area := GPlayer(ch).area;
  oindex.vnum := vnum;
  oindex.name := param;
  oindex.short := param;
  oindex.long := param;
  oindex.flags := OBJ_PROTO;
  
  objectIndices[vnum] := oindex;

  obj := oindex.clone();
  obj.toChar(ch);

  act(AT_REPORT,'You utter a few words and you create $p!',false,ch,obj,nil,TO_CHAR);
  act(AT_REPORT,'$n utters a few words and creates $p!',false,ch,obj,nil,TO_ROOM);
end;

const object_flags:array[0..30] of string=('nopickup','glow','hum',
                                          'antigood','antievil',
                                          'loyal','noremove',
                                          'nodrop','clanobject',
                                          'hidden','poison','missile',
                                          'nosac','bv13','bv14',
                                          'bv15','bv16','bv17','bv18',
                                          'bv19','bv20','bv21','bv22',
                                          'bv23','bv24','bv25','bv26',
                                          'bv27','bv28','bv29','proto');

const item_types:array[1..14] of string=('weapon','armor','food',
                                        'drink','light','trash',
                                        'money','special','gem',
                                        'container','corpse',
                                        'fountain','blood','portal');

const wear_types:array[1..26] of string=('rfinger','lfinger','neck1',
                                        'neck2','body','head','legs',
                                        'feet','hands','arms',
                                        'shield','about','waist',
                                        'rwrist','lwrist','float',
                                        'rhand','lhand','rshoulder',
                                        'lshoulder','face','rear',
                                        'lear','rankle','lankle','eyes');

procedure do_oedit(ch : GCharacter; param : string);
var sub : string;
    a : integer;
    obj, idx : GObject;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  OEDIT <object> <field> [value]'#13#10#13#10);
    ch.sendBuffer('Field can be one of the following:'#13#10);
    ch.sendBuffer('  name short long flags'#13#10);
    ch.sendBuffer('  type wear1 wear2 weight cost'#13#10);
    ch.sendBuffer('  value1 value2 value3 value4'#13#10);
    exit;
    end;

  param := one_argument(param,sub);
  obj := ch.findInventory(sub);

  if (obj = nil) then
    begin
    ch.sendBuffer('Could not find that object.'#13#10);
    exit;
    end;
    
  idx := GObject(objectIndices[obj.vnum]);

  if (IS_SET(obj.flags, OBJ_PROTO)) and (idx = nil) then
    begin
    ch.sendBuffer('Illegal proto.'#13#10);
    exit;
    end;

  { make sure builders don't overwrite other areas }
  if (obj.vnum < GPlayer(ch).o_lo) or (obj.vnum > GPlayer(ch).o_hi) then
    begin
    ch.sendBuffer('This vnum is not in your range.'#13#10);
    exit;
    end;

  param := one_argument(param,sub);

  if (sub = 'name') then
    begin
    obj.name := param;

    if (IS_SET(obj.flags,OBJ_PROTO)) then
      idx.name := param;
    end
  else
  if (sub = 'short') then
    begin
    obj.short := param;

    if (IS_SET(obj.flags,OBJ_PROTO)) then
      idx.short := param;
    end
  else
  if (sub = 'long') then
    begin
    obj.long := param;

    if (IS_SET(obj.flags,OBJ_PROTO)) then
      idx.long := param;
    end
  else
  if (sub = 'flags') then
    begin
    for a:=0 to High(object_flags) do
     if (pos(object_flags[a], param) > 0) then
      begin
      if IS_SET(obj.flags,1 shl a) then
        REMOVE_BIT(obj.flags,1 shl a)
      else
        SET_BIT(obj.flags,1 shl a);
      end;

    if (IS_SET(obj.flags,OBJ_PROTO)) then
      idx.flags := obj.flags - OBJ_PROTO;
    end
  else
  if (sub = 'type') then
    begin
    for a:=0 to High(item_types) do
     if (pos(item_types[a], param ) > 0) then
      begin
      obj.item_type:=a;
      break;
      end;

    if (IS_SET(obj.flags,OBJ_PROTO)) then
      idx.item_type := obj.item_type;
    end
  else
  if (sub = 'wear1') then
    begin
    obj.wear_location1 := param;
    
    if (IS_SET(obj.flags,OBJ_PROTO)) then
      idx.wear_location1 := obj.wear_location1;
    end
  else
  if (sub = 'wear2') then
    begin
    obj.wear_location2 := param;
    
    if (IS_SET(obj.flags,OBJ_PROTO)) then
      idx.wear_location2 := obj.wear_location2;
    end
  else
    begin
    ch.sendBuffer('Unknown option.'#13#10);
    exit;
    end;

  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_olist(ch : GCharacter; param : string);
var 
  num:integer;
  area : GArea;
  obj : GObject;
  iterator : GIterator;
begin
  if (GPlayer(ch).area_fname = '') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  area := GPlayer(ch).area;
  if (area = nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  num:=0;
  act(AT_REPORT, '$B$1[$B$7Nr$B$1] [$B$7VNum$B$1]  [$B$7Name$B$1]$A$7',false,ch,nil,nil,TO_CHAR);
  
  iterator := objectIndices.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (obj.area = area) then
      begin
      act(AT_REPORT, pad_integer_front(num, 4) + ' ' + pad_integer(obj.vnum,8) + ' $p',false, ch, obj, nil, TO_CHAR);
      inc(num);
      end;
    end;
    
  iterator.Free();
end;

procedure do_redit(ch : GCharacter; param : string);
var
   location : GRoom;
   sub : string;
   a : integer;
   pexit : GExit;
begin
  if (ch.IS_NPC) then
    exit;

  if (ch.substate = SUB_ROOM_DESC) then
    begin
    location := GPlayer(ch).edit_dest;
    location.description := GPlayer(ch).edit_buffer;
    GPlayer(ch).stopEditing;

    ch.substate := SUB_NONE;
    exit;
    end;

  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  REDIT <field> [value]'#13#10#13#10);
    ch.sendBuffer('Field can be one of the following:'#13#10);
    ch.sendBuffer('  name desc flags sector'#13#10);
    ch.sendBuffer('  televnum teledelay minlevel maxlevel'#13#10);
    ch.sendBuffer('  exflags'#13#10);
    exit;
    end;

  { make sure builders don't overwrite other areas }
  if (ch.room.vnum < GPlayer(ch).r_lo) or (ch.room.vnum > GPlayer(ch).r_hi) then
    begin
    ch.sendBuffer('You can''t edit rooms outside of your assigned area!'#13#10);
    exit;
    end;

  param := one_argument(param,sub);
  if (sub = 'name') then
    if (length(param) = 0) then
    begin
      ch.sendBuffer('Roomname is currently ''' + ch.room.name + '''.'#13#10);
      exit;
    end
    else
      ch.room.name := param
  else
  if (sub = 'desc') then
    begin
    ch.substate := SUB_ROOM_DESC;
    GPlayer(ch).edit_dest := ch.room;
    GPlayer(ch).startEditing(ch.room.description);
    exit;
    end
  else
  if (sub = 'flags') then
    begin
    for a:=0 to High(room_flags) do
     if (pos(room_flags[a], param) > 0) then
      begin
      if (ch.room.flags.isBitSet(1 shl a)) then
        ch.room.flags.removeBit(1 shl a)
      else
        ch.room.flags.setBit(1 shl a);
      end;
    end
  else
  if (sub = 'sector') then
    begin
    for a := 0 to High(sector_types) do
     if (pos(sector_types[a], param ) > 0) then
      begin
      ch.room.sector := a;
      break;
      end;
    end
  else
  if (sub = 'televnum') then
    ch.room.televnum := strtointdef(param, 0)
  else
  if (sub = 'teledelay') then
    ch.room.teledelay := strtointdef(param, 0)
  else
  if (sub = 'minlevel') then
    ch.room.minlevel := strtointdef(param, 0)
  else
  if (sub = 'maxlevel') then
    ch.room.maxlevel:=strtoint(param)
  else
  if (sub = 'exflags') then
    begin
    param := one_argument(param,sub);

    a := findHeading(sub);
    pexit := ch.room.findExit(a);

    if (pexit=nil) then
      begin
      ch.sendBuffer('Cannot find that exit.'#13#10);
      exit;
      end;

    for a:=0 to High(exit_flags) do
     if (pos(exit_flags[a], param) > 0) then
      begin
      if IS_SET(pexit.flags, 1 shl a) then
        REMOVE_BIT(pexit.flags, 1 shl a)
      else
        SET_BIT(pexit.flags, 1 shl a);
      end;
    end
  else
    begin
    ch.sendBuffer('Unknown option.'#13#10);
    exit;
    end;
    
  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_rlink(ch : GCharacter; param : string);
var dir:integer;
    vnum:integer;
    to_room : GRoom;
    to_exit, from_exit : GExit;
    sub : string;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: RLINK <direction> <vnum>'#13#10#13#10);
    ch.sendBuffer('Creates a double linked exit to the designated vnum.'#13#10);
    exit;
    end;

  if (ch.getTrust < LEVEL_GOD) and (GPlayer(ch).area_fname = '') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  if (ch.getTrust < LEVEL_GOD) and (GPlayer(ch).area = nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  if (ch.room.vnum < GPlayer(ch).r_lo) or (ch.room.vnum > GPlayer(ch).r_hi) then
    begin
    ch.sendBuffer('You can''t create exits in rooms outside of your assigned area!'#13#10);
    exit;
    end;

  param := one_argument(param,sub);
  dir := findHeading(sub);
  if (dir=-1) then
    begin
    ch.sendBuffer('Invalid direction.'#13#10);
    exit;
    end;

  one_argument(param,sub);

  try
    vnum := strtoint(sub);
  except
    ch.sendBuffer('Invalid numeric format.'#13#10);
    exit;
  end;

  to_room := findRoom(vnum);

  if (to_room = nil) then
    begin
    ch.sendBuffer('That vnum does not exist.'#13#10);
    exit;
    end;

  if (ch.room.findExit(dir) <> nil) then
    begin
    ch.sendBuffer('An exit in that direction already exists!'#13#10);
    exit;
    end;

  to_exit := GExit.Create;
  to_exit.direction := dir;
  to_exit.vnum := vnum;
  to_exit.to_room := to_room;

  ch.room.exits.insertLast(to_exit);

  from_exit := GExit.Create;
  from_exit.direction := dir_inv[dir];
  from_exit.vnum := ch.room.vnum;
  from_exit.to_room := ch.room;

  to_room.exits.insertLast(from_exit);

  ch.sendBuffer('Ok.'#13#10);
end;

function findFreeVNum(ch : GCharacter) : integer;
var
   room : GRoom;
   iterator : GIterator;
   vnum, h : integer;
begin
  vnum := GPlayer(ch).r_lo;

  iterator := room_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    room := GRoom(iterator.next());
    
    if (room.area <> GPlayer(ch).area) then
      continue;

    if (room.vnum > vnum) then
      vnum := room.vnum;

    end;
    
  iterator.free();

  inc(vnum);
  
  if (vnum >= GPlayer(ch).r_hi) then
    Result := -1
  else
    Result := vnum;
end;

procedure do_rmake(ch : GCharacter; param : string);
var dir:integer;
    new_vnum:integer;
    to_exit, from_exit : GExit;
    new_room : GRoom;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: RMAKE <direction>'#13#10#13#10);
    ch.sendBuffer('Creates a new room within your vnum range linked to the current room,'#13#10);
    ch.sendBuffer('name and sector type are copied to the new room.'#13#10);
    exit;
    end;

  if (ch.getTrust() < LEVEL_GOD) and (GPlayer(ch).area_fname='') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  if (ch.getTrust() < LEVEL_GOD) and (GPlayer(ch).area=nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;
    
  if (ch.room.vnum < GPlayer(ch).r_lo) or (ch.room.vnum > GPlayer(ch).r_hi) then
    begin
    ch.sendBuffer('You can''t create rooms outside of your assigned area!'#13#10);
    exit;
    end;

  dir := findHeading(param);

  if (dir = -1) then
    begin
    ch.sendBuffer('Invalid direction.'#13#10);
    exit;
    end;

  new_vnum:=FindFreeVNum(ch);
  if (new_vnum=-1) then
    begin
    ch.sendBuffer('No more vnums available in your range. Try decreasing the size'#13#10);
    ch.sendBuffer('of your area or asking another immortal for a bigger range.'#13#10);
    exit;
    end;

  if (ch.room.findExit(dir) <> nil) then
    begin
    ch.sendBuffer('An exit in that direction already exists!'#13#10);
    exit;
    end;

  ch.sendBuffer('Creating room #' + inttostr(new_vnum) + ' [' + headings[dir] + '].'#13#10);

  new_room := createRoom(new_vnum, ch.room.area);

  new_room.name := ch.room.name;
  new_room.sector := ch.room.sector;

  to_exit := GExit.Create;
  to_exit.direction := dir;
  to_exit.vnum := new_vnum;
  to_exit.to_room := new_room;

  ch.room.exits.insertLast(to_exit);

  from_exit := GExit.Create;
  from_exit.direction := dir_inv[dir];
  from_exit.vnum := ch.room.vnum;
  from_exit.to_room := ch.room;

  new_room.exits.insertLast(from_exit);

  interpret(ch, headings[dir]);
end;

procedure do_rdelete(ch : GCharacter; param : string);
var
  room, room2 : GRoom;
  ex, ex2 : GExit;
  node,node2 : GListNode;
begin
  if (ch.IS_NPC()) then
    begin
    ch.sendBuffer('This command is not available for mobs.'#13#10);
    exit;
    end;
  
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: RDELETE <vnum>'#13#10#13#10);
    ch.sendBuffer('Deletes room with given vnum.'#13#10);
    exit;
    end;

  if (ch.room.vnum < GPlayer(ch).r_lo) or (ch.room.vnum > GPlayer(ch).r_hi) then
    begin
    ch.sendBuffer('You can''t delete rooms outside of your assigned area!'#13#10);
    exit;
    end;

  try
    room := findRoom(StrToInt(param));
  except
    on E: EConvertError do
      begin
      ch.sendBuffer('That vnum doesn''t exit.');
      exit;
      end;
  end;

  if (room = ch.room) then
    begin
    ch.sendBuffer('Removing the room you''re in would not be wise.'#13#10);
    exit;
    end;
  
  ch.sendBuffer('Unlinking all exits pointing to the room...'#13#10);
  node := room.exits.head;
  while (node <> nil) do
    begin
    ex := GExit(node.element);

    room2 := ex.to_room;
    node2 := room2.exits.head;
    while (node2 <> nil) do
      begin
      ex2 := GExit(node2.element);
      
      if (ex2.to_room = room) then
        begin
        ch.sendBuffer(Format('Removing in room #%d the %s-exit.'#13#10, [room2.vnum, headings[ex2.direction]]));
        room2.exits.remove(node2);
        ex2.Free();
        end;
      node2 := node2.next;
      end;
    
    node := node.next;
    end;

  room_list.remove(room.vnum);
  
  room.Free();
end;

procedure do_rclone(ch : GCharacter; param : string);
var dir : integer;
    new_vnum : integer;
    to_exit, from_exit : GExit;
    new_room : GRoom;
    area : GArea;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: RCLONE <direction>'#13#10#13#10);
    ch.sendBuffer('Creates a new room within your vnum range linked to the current room,'#13#10);
    ch.sendBuffer('cloning all the information, except for the exits.'#13#10);
    exit;
    end;

  if (ch.getTrust() < LEVEL_GOD) and (GPlayer(ch).area_fname = '') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  if (ch.getTrust() < LEVEL_GOD) and (GPlayer(ch).area = nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  if (ch.room.vnum < GPlayer(ch).r_lo) or (ch.room.vnum > GPlayer(ch).r_hi) then
    begin
    ch.sendBuffer('You can''t create rooms outside of your assigned area!'#13#10);
    exit;
    end;

  dir := FindHeading(param);
  if (dir = -1) then
    begin
    ch.sendBuffer('Invalid direction. Please use north, south, west, east, down or up.'#13#10);
    exit;
    end;

  new_vnum := findFreeVNum(ch);
  if (new_vnum = -1) then
    begin
    ch.sendBuffer('No more vnums available in your range. Try decreasing the size'#13#10);
    ch.sendBuffer('of your area or asking another immortal for a bigger range.'#13#10);
    exit;
    end;

  if (ch.room.findExit(dir) <> nil) then
    begin
    ch.sendBuffer('An exit in that direction already exists!'#13#10);
    exit;
    end;

  ch.sendBuffer('Creating room #' + inttostr(new_vnum) + ' [' + headings[dir] + '].'#13#10);

  area := GPlayer(ch).area;
  new_room := createRoom(new_vnum, area);
  new_room.name := ch.room.name;
  new_room.description := ch.room.description;
  new_room.flags.value := ch.room.flags.value;
  new_room.televnum := ch.room.televnum;
  new_room.teledelay := ch.room.teledelay;
  new_room.minlevel := ch.room.minlevel;
  new_room.maxlevel := ch.room.maxlevel;
  new_room.sector := ch.room.sector;

  to_exit := GExit.Create;
  to_exit.direction := dir;
  to_exit.vnum := new_vnum;
  to_exit.to_room := new_room;

  ch.room.exits.insertLast(to_exit);

  from_exit := GExit.Create;
  from_exit.direction := dir_inv[dir];
  from_exit.vnum := ch.room.vnum;
  from_exit.to_room := ch.room;

  new_room.exits.insertLast(from_exit);

  interpret(ch,headings[dir]);
end;

procedure do_rlist(ch : GCharacter; param : string);
var
  i : integer;
  room : GRoom;
  area : GArea;
  iterator : GIterator;
begin
  if (ch.IS_NPC()) then
    begin
    ch.sendBuffer('This command is not available for mobs.'#13#10);
    exit;
    end;
  
  if (length(param) = 0) then
    begin
    if ((GPlayer(ch).area = nil) and (ch.level < LEVEL_GOD)) then
      begin
      if (length(GPlayer(ch).area_fname) = 0) then
        ch.sendBuffer('You don''t have an area assigned to you.'#13#10)
      else
        ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
      exit;
      end;

    if (ch.level < LEVEL_GOD) then
      area := GPlayer(ch).area
    else
      area := ch.room.area;
    end
  else
    begin
    area := findArea(param);

    if (area = nil) then
      begin
      ch.sendBuffer('That area could not be found.'#13#10);
      exit;
      end;
    end;
  
  iterator := room_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    room := GRoom(iterator.next());

    if (room.area <> area) then
      continue;

    ch.sendPager(Format('Vnum #%6d  Name: %s'#13#10, [room.vnum, room.name]));
    end;
    
  iterator.Free();
end;

{ Re-added area assign - Nemesis }
procedure do_aassign(ch:GCharacter;param:string);
var vict : GCharacter;
    area : GArea;
    sub : string;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: AASSIGN <player> <filename>'#13#10#13#10);
    ch.sendBuffer('Assigns an area to a player for online construction.'#13#10);
    ch.sendBuffer('Specify just a player name to unassign an assigned area.'#13#10);
    exit;
    end;

  param := one_argument(param,sub);
  vict := findCharWorld(ch,sub);

  if (vict = nil) or (vict.IS_NPC) then
    ch.sendBuffer('That player cannot be found.'#13#10)
  else
  if (vict.level < LEVEL_BUILD) then
    ch.sendBuffer('That character has not attained the proper level.'#13#10)
  else
    begin
    area := findArea(param);

    if (area <> nil) then
      begin
      act(AT_REPORT,'Area ' + param + ' assigned to $N.',false,ch,nil,vict,TO_CHAR);

      if (vict <> ch) then
        act(AT_REPORT,ch.name + ' has assigned ' + param + ' to you.',false,vict,nil,ch,TO_CHAR);

      GPlayer(vict).area := area;
      GPlayer(vict).area_fname := param;
      GPlayer(vict).r_lo := area.r_lo;
      GPlayer(vict).r_hi := area.r_hi;
      GPlayer(vict).m_lo := area.m_lo;
      GPlayer(vict).m_hi := area.m_hi;
      GPlayer(vict).o_lo := area.o_lo;
      GPlayer(vict).o_hi := area.o_hi;
      end
    else
      if (length(param) = 0) then
      begin
        if (GPlayer(vict).area_fname <> '') then
        begin
          act(AT_REPORT,'Unassigned area ' + GPlayer(vict).area_fname + ' from $N.',false,ch,nil,vict,TO_CHAR);

          if (vict <> ch) then
            act(AT_REPORT,ch.name + ' has unassigned area ' + GPlayer(vict).area_fname + ' from you.',false,vict,nil,ch,TO_CHAR);

          GPlayer(vict).area := nil;
          GPlayer(vict).area_fname := '';
          GPlayer(vict).r_lo := High(integer);
          GPlayer(vict).r_hi := -1;
          GPlayer(vict).m_lo := High(integer);
          GPlayer(vict).m_hi := -1;
          GPlayer(vict).o_lo := High(integer);
          GPlayer(vict).o_hi := -1;
        end
        else
        begin
          ch.sendBuffer('There is no area assigned to that player.'#13#10);
        end;
      end
      else
      begin
        ch.sendBuffer('That area cannot be found.'#13#10);
      end;
    end;
end;

procedure do_ranges(ch : GCharacter; param : string);
var
   vict : GCharacter;
   sub : string;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: RANGES <player> <roomlo> <roomhi> <moblo> <mobhi> <objlo> <objhi>'#13#10#13#10);
    ch.sendBuffer('Manually assigns ranges to a player, and overrides those'#13#10);
    ch.sendBuffer('automatically assigned by AASSIGN.'#13#10);
    exit;
    end;

  param := one_argument(param,sub);
  vict := findCharWorld(ch,sub);

  if (vict = nil) or (vict.IS_NPC()) then
    ch.sendBuffer('Cannot find that character.'#13#10)
  else
  if (vict.level < LEVEL_BUILD) then
    ch.sendBuffer('That character has not attained the proper level.'#13#10)
  else
    begin
    try
      with GPlayer(vict) do
        begin
        param := one_argument(param,sub);
        r_lo := strtoint(sub);

        param := one_argument(param,sub);
        r_hi := strtoint(sub);

        param := one_argument(param,sub);
        m_lo := strtoint(sub);

        param:= one_argument(param,sub);
        m_hi := strtoint(sub);

        param:= one_argument(param,sub);
        o_lo := strtoint(sub);

        one_argument(param,sub);
        o_hi := strtoint(sub);
        end;

      act(AT_REPORT,'Assigned appropiate ranges to $N.',false,ch,nil,vict,TO_CHAR);
      act(AT_REPORT,'You have been assigned new ranges by $N.',false,vict,nil,ch,TO_CHAR);
    except
      ch.sendBuffer('Invalid numeric format.'#13#10);
    end;
    end;
end;

function createArea(fn : string) : GArea;
var
   area : GArea;
begin
  area := GArea.create;

  area.m_lo := High(integer);
  area.m_hi := -1;
  area.r_lo := High(integer);
  area.r_hi := -1;
  area.o_lo := High(integer);
  area.o_hi := -1;

  area.fname := fn;
  area.author := 'No author';
  area.resetmsg := 'No reset message';
  area.name := 'New area';

  area.maxage := 10;
  area.flags.value := 0;

  with area.weather do
    begin
    mmhg := 1000;
    sky := SKY_CLOUDLESS;
    change := 0;
    temp := 20;
    temp_avg := 20;
    temp_mult := 5;
    end;

  Result := area;
end;

procedure do_acreate(ch : GCharacter; param : string);
var
   area : GArea;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: ACREATE <filename>'#13#10#13#10);
    ch.sendBuffer('Creates a new area file using default values.'#13#10);
    exit;
    end;

  area := findArea(param);
  if (area <> nil) then
    begin
    ch.sendBuffer('Area already exists.'#13#10);
    exit;
    end;

  area := createArea(param);
  area.author := ch.name;
  area.flags.value := AREA_NOPC or AREA_PROTO;           { not for mortals, proto }
  act(AT_REPORT,'Area '+param+' created.',false,ch,nil,nil,TO_CHAR);
end;

const area_flags : array[0..2] of string = ('noreset','nopc','proto');

procedure do_aset(ch : GCharacter; param : string);
var
   area : GArea;
   sub : string;
   a : integer;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: ASET <field> <value>'#13#10#13#10);
    ch.sendBuffer('Field can be one of the following:'#13#10#13#10);
    ch.sendBuffer('  author name resetmsg age flags'#13#10);
    exit;
    end;

  if (GPlayer(ch).area_fname='') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  if (GPlayer(ch).area=nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  area := GPlayer(ch).area;
  param := one_argument(param,sub);

  if (sub = 'author') then
    area.author := param
  else
  if (sub = 'name') then
    area.name := param
  else
  if (sub = 'resetmsg') then
    area.resetmsg := param
  else
  if (sub = 'age') then
    area.maxage := strtointdef(param, 0)
  else
  if (sub = 'flags') then
    begin
    for a:=0 to High(area_flags) do
     if (pos(area_flags[a], param) > 0) then
      begin
      if (area.flags.isBitSet(1 shl a)) then
        area.flags.removeBit(1 shl a)
      else
        area.flags.setBit(1 shl a);
      end;
    end
  else
    begin
    ch.sendBuffer('Unknown option.'#13#10);
    exit;
    end;

  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_astat(ch : GCharacter; param : string);
var
   area : GArea;
   buf : string;
   a : integer;
begin
  if (GPlayer(ch).area_fname='') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  area := GPlayer(ch).area;
  if (area=nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  act(AT_REPORT, '['+area.fname+']'#13#10,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT, 'Name:             '+area.name,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT, 'Author:           '+area.author,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT, 'Reset message:    '+area.resetmsg,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT, 'Maximum age:      '+inttostr(area.maxage),false,ch,nil,nil,TO_CHAR);

  buf := 'Ranges:         ';

  if (area.r_lo <> High(integer)) then
    buf := buf + '  R: ' + inttostr(area.r_lo)+'-'+inttostr(area.r_hi);

  if (area.m_lo <> High(integer)) then
    buf := buf + '  M: ' + inttostr(area.m_lo)+'-'+inttostr(area.m_hi);

  if (area.o_lo <> High(integer)) then
    buf := buf + '  O: ' + inttostr(area.o_lo)+'-'+inttostr(area.o_hi);

  act(AT_REPORT,buf,false,ch,nil,nil,TO_CHAR);

  buf := 'Flags:           ';

  if (area.flags.value = 0) then
    buf := buf + ' none'
  else
  for a:=0 to High(area_flags) do
   if (area.flags.isBitSet(1 shl a)) then
    buf := buf + ' ' + area_flags[a];

  act(AT_REPORT,buf,false,ch,nil,nil,TO_CHAR);

  act(AT_REPORT,'Nr. of resets:    '+inttostr(area.resets.size()),false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'Nr. of players:   '+inttostr(area.nplayer),false,ch,nil,nil,TO_CHAR);
end;

procedure do_checkarea(ch : GCharacter; param : string);
var
  room : GRoom;
  area : GArea;
  iterator : GIterator;
  no_errors : boolean;
  h : integer;
begin
  if (GPlayer(ch).area_fname='') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  area := GPlayer(ch).area;
  if (area=nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  ch.sendBuffer('Checking area '+area.fname+'...'#13#10#13#10);
  no_errors := true;

  iterator := room_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    room := GRoom(iterator.next());

    if (room.area = area) then
      begin
      if (length(room.name) = 0) then
        begin
        no_errors := false;
        ch.sendBuffer('('+inttostr(room.vnum)+') WARNING room name empty'#13#10);
        end;
      { else
      if (find_last(room.name) = '.') then
        begin
        no_errors:=false;
        ch.sendBuffer('('+inttostr(room.vnum)+') '+room.name+': dot not allowed in room name'#13#10));
        end; }

      if (length(room.description) = 0) then
        begin
        no_errors := false;
        ch.sendBuffer('('+inttostr(room.vnum)+') WARNING room description null'#13#10);
        end;
      { else
      if (find_last(room.description)<>'.') then
        begin
        no_errors:=false;
        ch.sendBuffer(pchar('('+inttostr(room.vnum)+') '+room.name+': dot required in room description'#13#10));
        end; }
      end;
    end;
  iterator.Free();

  { obj := obj_reset_first;
  while (obj <> nil) do
    begin
    if (obj.area=area) then
      begin
      if (obj.name[0] in ['A'..'Z']) then
        begin
        no_errors:=false;
        ch.sendBuffer(pchar('('+inttostr(obj.vnum)+') '+obj.name+': capitals not allowed at start of name'));
        end;
      if (obj.short[0] in ['A'..'Z']) then
        begin
        no_errors:=false;
        ch.sendBuffer(pchar('('+inttostr(obj.vnum)+') '+obj.name+': capitals not allowed at start of short description'));
        end;
      if (obj.long[0] in ['A'..'Z']) then
        begin
        no_errors:=false;
        ch.sendBuffer(pchar('('+inttostr(obj.vnum)+') '+obj.name+': capitals not allowed at start of long description'));
        end;
      if (find_last(obj.name)='.') then
        begin
        no_errors:=false;
        ch.sendBuffer(pchar('('+inttostr(obj.vnum)+') '+obj.name+': dot not allowed at end of name'));
        end;
      if (find_last(obj.short)='.') then
        begin
        no_errors:=false;
        ch.sendBuffer(pchar('('+inttostr(obj.vnum)+') '+obj.name+': dot not allowed at end of short description'));
        end;
      if (find_last(obj.long)='.') then
        begin
        no_errors:=false;
        ch.sendBuffer(pchar('('+inttostr(obj.vnum)+') '+obj.name+': dot not allowed at end of long description'));
        end;
      end;
    obj:=obj.next;
    end;
  mob:=mob_reset_first;
  while (mob<>nil) do
    begin
    if (mob.area=area) then
      begin
      if (find_last(mob.name)='.') then
        begin
        ch.sendBuffer(pchar('('+inttostr(mob.vnum)+') '+mob.name+': dot not allowed at end of name'));
        exit;
        end;
      if (find_last(mob.short)='.') then
        begin
        ch.sendBuffer(pchar('('+inttostr(mob.vnum)+') '+mob.name+': dot not allowed at end of short description'));
        exit;
        end;
      if (find_last(mob.long)='.') then
        begin
        ch.sendBuffer(pchar('('+inttostr(mob.vnum)+') '+mob.name+': dot not allowed at end of long description'));
        exit;
        end;
      end;
    mob:=mob.next;
    end; }

  if (no_errors) then
    ch.sendBuffer('Your area is perfectly fine.'#13#10);
end;

procedure do_savearea(ch : GCharacter; param : string);
var
   area : GArea;
begin
  if (ch.getTrust() < LEVEL_GOD) and (GPlayer(ch).area_fname = '') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  if ((ch.getTrust() < LEVEL_GOD) or (length(param) = 0)) and (GPlayer(ch).area = nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  if (length(param) = 0) then
    area:=GPlayer(ch).area
  else
    begin
    if (ch.getTrust() < LEVEL_GOD) then
      begin
      ch.sendBuffer('You can only save your own area.'#13#10);
      exit;
      end;

    area := findArea(param);

    if (area = nil) then
      begin
      ch.sendBuffer('Area not found.'#13#10);
      exit;
      end;
    end;

  ch.sendBuffer('Saving ' + area.fname + '...');

  area.save(area.fname);

  ch.sendBuffer('Done.'#13#10);
end;

procedure do_loadarea(ch : GCharacter; param : string);
var
   area : GArea;
   fn : string;
begin
  if (length(param) = 0) then
  begin
    if (GPlayer(ch).area_fname = '') then
    begin
      ch.sendBuffer('You have not yet been assigned an area.'#13#10);
      exit;
    end;

    fn := GPlayer(ch).area_fname
  end
  else
    begin
    if (ch.getTrust() < LEVEL_GOD) then
      begin
      ch.sendBuffer('You can only load your own area.'#13#10);
      exit;
      end;

    fn := param;
    end;

  area := findArea(fn);
  if (area <> nil) then
    begin
    ch.sendBuffer('That area is already loaded.'#13#10);
    exit;
    end;

  area := GArea.Create;
  area.load(fn);
  GPlayer(ch).area := area;
  act(AT_REPORT,'Area ' + fn + ' loaded.',false,ch,nil,nil,TO_CHAR);
end;

procedure do_reset(ch: GCharacter; param : string);
var
  area : GArea;
  iterator : GIterator;
begin
  area := nil;

  if (length(param) > 0) and (ch.getTrust() < LEVEL_GOD) then
    begin
    ch.sendBuffer('You can only reset your own area.'#13#10);
    exit;
    end;

  if (ch.getTrust() < LEVEL_GOD) and (GPlayer(ch).area_fname = '') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  if ((ch.getTrust() < LEVEL_GOD) or (length(param) = 0)) and (GPlayer(ch).area = nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  if (length(param) = 0) then
    area := GPlayer(ch).area
  else
  if (length(param) > 0) and (param = 'all') then
    begin
    act(AT_WHITE,'All areas reset.',false,ch,nil,nil,TO_CHAR);

    { reset the areas }
    iterator := area_list.iterator();

    while (iterator.hasNext()) do
      begin
      area := GArea(iterator.next());
      area.reset();
      end;
      
    iterator.Free();

    exit;
    end
  else
  if (length(param) > 0) then
    area := findArea(param);

  if (area = nil) then
    begin
    ch.sendBuffer('Area not found.'#13#10);
    exit;
    end;

  act(AT_WHITE, 'Area '+area.fname+' reset.',false,ch,nil,nil,TO_CHAR);
  area.reset();
end;

procedure do_map(ch : GCharacter; param : string);
{

^
|
y

x ->

lower left corner : (1, 1)

}
         
type
  TPos = record
           x, y : integer;
         end;
  TMapString = string[10];
  TGrid = record
            curpos : TPos;
            grid : array[1..(MAP_SIZE_X * 2 + 1), 1..(MAP_SIZE_Y * 2)] of TMapString;
          end;
         
const
  MAP_EXIT_N_S : TMapString = '|';
  MAP_EXIT_W_E : TMapString = '-';
  MAP_NOT_CONNECTED : TMapString = ' ';
  MAP_ROOM_EXIST : TMapString = '*';
  MAP_ROOM_NOT_EXIST : TMapString = '$B$0.$A$7';
  MAP_EMPTY : TMapString = ' ';
  MAP_CHAR_POSITION : TMapString = '$B$6@$A$7';
  MAP_NIL : TMapString = ' ';
  MAP_UP : TMapString = '$B$6U$A$7';
  MAP_DOWN : TMapString = '$B$6D$A$7';
  MAP_NPC : TMapString = '$B$6*$A$7';
  MAP_PC : TMapString = '$B$4*$A$7';
  MAP_DOOR_CLOSED : TMapString = '$B$4+$A$7';
  MAP_DOOR_OPEN : TMapString = '$B$1+$A$7';
  MAP_ROOM = -1;
  
function build_grid() : TGrid;
var
  gr : TGrid;
  xpos, ypos : integer;
begin
  fillchar(gr.grid, sizeof(gr.grid), 0);

  for ypos := 1 to (MAP_SIZE_Y * 2) do
  begin
    for xpos := 1 to (MAP_SIZE_X) do
    begin
      if (odd(ypos)) then
      begin
        gr.grid[(xpos * 2), ypos] := MAP_ROOM_NOT_EXIST;
        gr.grid[(xpos * 2) + 1, ypos] := MAP_EMPTY;
      end
      else
      begin
        gr.grid[(xpos * 2), ypos] := MAP_EMPTY;
        gr.grid[(xpos * 2) + 1, ypos] := MAP_EMPTY;
      end;
    end;
  end;
  
  gr.curpos.x := (MAP_SIZE_X div 2) + 1;
  gr.curpos.y := (MAP_SIZE_Y div 2) + 1;
  
  build_grid := gr;
end;
         
procedure grid_insert(var gr : TGrid; dir : integer; what : TMapString);
var
  hor, vert : integer;
  ch : TMapString;
begin
  hor := 0;
  vert := 0;
  ch := '';

  if (what <> MAP_NIL) then
    ch := what;
  
  case dir of
    0:
      begin
        ch := what;
      end;
    DIR_NORTH:
      begin
        if (what = MAP_NIL) then
          ch := MAP_EXIT_N_S;
        vert := -1;
      end;
    DIR_SOUTH:
      begin
        if (what = MAP_NIL) then
          ch := MAP_EXIT_N_S;
        vert := 1;
      end;
    DIR_WEST:
      begin
        if (what = MAP_NIL) then
          ch := MAP_EXIT_W_E;
        hor := -1;
      end;
    DIR_EAST:
      begin
        if (what = MAP_NIL) then
          ch := MAP_EXIT_W_E;
        hor := 1;
      end;
  end;
  with gr do
    grid[(curpos.x * 2 + hor), (curpos.y * 2 + vert - 1)] := ch;
end;

function been_there(var gr : TGrid; dir : integer) : boolean;
var
  hor, vert : integer;
  ch : TMapString;
begin
  hor := 0;
  vert := 0;
  been_there := false;

  case dir of
    DIR_NORTH:
      begin
        ch := MAP_EXIT_N_S;
        vert := -1;
      end;
    DIR_SOUTH:
      begin
        ch := MAP_EXIT_N_S;
        vert := 1;
      end;
    DIR_WEST:
      begin
        ch := MAP_EXIT_W_E;
        hor := -1;
      end;
    DIR_EAST:
      begin
        ch := MAP_EXIT_W_E;
        hor := 1;
      end
{    else
      begin
        write_console('None of expected dirs found.');
        exit;
      end;}
  end;
  with gr do
    if (grid[(curpos.x * 2 + hor), (curpos.y * 2 + vert - 1)] = ch) or
       (grid[(curpos.x * 2 + hor), (curpos.y * 2 + vert - 1)] = MAP_DOOR_CLOSED) or
       (grid[(curpos.x * 2 + hor), (curpos.y * 2 + vert - 1)] = MAP_DOOR_OPEN) then
      been_there := true
    else
      been_there := false;
end;

procedure build_map(var gr : TGrid; var room : GRoom);
var
  new_room : GRoom;
  iterator : GIterator;
  vict : GCharacter;
  pcs, npcs : integer;
  pexit : GExit;
  direction : integer;
begin
  if (room = nil) then
    exit;

  pcs := 0;
  npcs := 0;
  
  grid_insert(gr, 0, MAP_ROOM_EXIST);

  iterator := room.chars.iterator();
  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_NPC()) then
      inc(npcs)
    else
      inc(pcs);
    end;
  iterator.Free();

  if (npcs > 0) then
    grid_insert(gr, 0, MAP_NPC);

  if (pcs > 0) then
    grid_insert(gr, 0, MAP_PC);
  
  for direction := DIR_NORTH to DIR_UP do
    begin
    if (direction = DIR_NORTH) and not(gr.curpos.y > 1) then
      continue;
    if (direction = DIR_EAST) and not(gr.curpos.x < MAP_SIZE_X) then
      continue;
    if (direction = DIR_WEST) and not(gr.curpos.x > 1) then
      continue;
    if (direction = DIR_SOUTH) and not(gr.curpos.y < MAP_SIZE_Y) then
      continue;

    if (room.isConnectedTo(direction) <> nil) then
      begin
      if (direction = DIR_UP) then
        begin
        grid_insert(gr, 0, MAP_UP);
        continue;
        end;
        
      if (direction = DIR_DOWN) then
        begin
        grid_insert(gr, 0, MAP_DOWN);
        continue;
        end;
          
      if not(been_there(gr, direction)) then
        begin
        pexit := room.findExit(direction);
        if (IS_SET(pexit.flags, EX_ISDOOR)) then
          if (IS_SET(pexit.flags, EX_CLOSED)) then
            grid_insert(gr, direction, MAP_DOOR_CLOSED)
          else
            grid_insert(gr, direction, MAP_DOOR_OPEN)
        else
          grid_insert(gr, direction, MAP_NIL);

        if (direction = DIR_NORTH) then
          dec(gr.curpos.y);
        if (direction = DIR_EAST) then
          inc(gr.curpos.x);
        if (direction = DIR_WEST) then
          dec(gr.curpos.x);
        if (direction = DIR_SOUTH) then
          inc(gr.curpos.y);
          
        new_room := room.isConnectedTo(direction);
        build_map(gr, new_room);

        if (direction = DIR_NORTH) then
          inc(gr.curpos.y);
        if (direction = DIR_EAST) then
          dec(gr.curpos.x);
        if (direction = DIR_WEST) then
          inc(gr.curpos.x);
        if (direction = DIR_SOUTH) then
          dec(gr.curpos.y);
        end;
      end;
    end;
end;

procedure show_legenda();
var
  buf : string;
begin
  buf := Format('Legenda:' + #13#10 + #13#10 +
                '  %s %s    Passage' + #13#10 +
                '  %s      Open door' + #13#10 +
                '  %s      Closed door' + #13#10 +
                '  %s      You' + #13#10 +
                '  %s      Room with a mob' + #13#10 +
                '  %s      Room with a player' + #13#10 +
                '  %s      Up exit' + #13#10 +
                '  %s      Down exit',
                [MAP_EXIT_N_S, MAP_EXIT_W_E,
                 MAP_DOOR_OPEN, MAP_DOOR_CLOSED,
                 MAP_CHAR_POSITION, MAP_NPC, MAP_PC,
                 MAP_UP, MAP_DOWN]);
  act(AT_REPORT, buf, false, ch, nil, nil, TO_CHAR);
end;

var
  buf : string;
  gr : TGrid;
  xpos, ypos : integer;
begin
  if length(param) <> 0 then
  begin
    show_legenda();
    exit;
  end;

  gr := build_grid();

  gr.curpos.x := (MAP_SIZE_X div 2) + 1;
  gr.curpos.y := (MAP_SIZE_Y div 2) + 1;
  build_map(gr, ch.room);
  gr.curpos.x := (MAP_SIZE_X div 2) + 1;
  gr.curpos.y := (MAP_SIZE_Y div 2) + 1;
  grid_insert(gr, 0, MAP_CHAR_POSITION);

  for ypos := 1 to (MAP_SIZE_Y * 2 - 1) do
  begin
    buf := '';
    for xpos := 1 to (MAP_SIZE_X * 2) do
    begin
      buf := buf + gr.grid[xpos, ypos];
    end;
    act(AT_REPORT, buf, false, ch, nil, nil, TO_CHAR);
  end;
end;

{Xenon 28/Apr/2001 : assign ranges to area. }
procedure do_aranges(ch : GCharacter; param : string);
var
  area : GArea;
  areaname, sub : string;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: ARANGES <area filename> <roomlo> <roomhi> <moblo> <mobhi> <objlo> <objhi>'#13#10#13#10);
    ch.sendBuffer('Manually assigns ranges to an area.'#13#10);
    exit;
    end;

  param := one_argument(param, areaname);
  
  area := findArea(areaname);

  if (area = nil) then
  begin
    ch.sendBuffer('That area could not be found.'#13#10);
    exit;
  end;
  
  try
    with area do
    begin
      param := one_argument(param,sub);
      r_lo := strtoint(sub);

      param := one_argument(param,sub);
      r_hi := strtoint(sub);

      param := one_argument(param,sub);
      m_lo := strtoint(sub);

      param:= one_argument(param,sub);
      m_hi := strtoint(sub);

      param:= one_argument(param,sub);
      o_lo := strtoint(sub);

      one_argument(param,sub);
      o_hi := strtoint(sub);
    end;

    act(AT_REPORT, 'Assigned ranges to area ' + area.name + '.', false, ch, nil, nil, TO_CHAR);
  except
    ch.sendBuffer('Invalid numeric format.'#13#10);
  end;
end;

procedure do_resedit(ch : GCharacter; param : string);
begin
end;

