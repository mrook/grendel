const room_flags:array[0..30] of pchar=('dark','death','nomob',
                                        'indoors','good','evil',
                                        'nocast','tunnel','private',
                                        'safe','solitary','norecall',
                                        'nodropall','nosummon',
                                        'clanstore','teleport',
                                        'nofloor','manaroom','bv18',
                                        'bv19','bv20','bv21','bv22',
                                        'bv23','bv24','bv25','bv26',
                                        'bv27','bv28','bv29','proto');

const exit_flags:array[0..12] of pchar=('isdoor','closed','locked',
                                        'pickproof','secret','swim',
                                        'fly','clibm','portal',
                                        'nobreak','nomob','enter',
                                        'underwater');

(* procedure do_rstat(ch:GCharacter;param:string);
var a:integer;
    buf:string;
    pexit:GExit;
begin
  with ch.room do
    begin
    act(AT_REPORT,'['+name+']'#13#10,false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Vnum:         '+inttostr(vnum),false,ch,nil,nil,TO_CHAR);

    buf := 'Flags:       ';

    if (flags=0) then
      buf := buf + ' none'
    else
    for a:=0 to High(room_flags) do
     if IS_SET(flags,1 shl a) then
      buf := buf + ' ' + room_flags[a];

    act(AT_REPORT,buf,false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Sector:       '+sector_types[sector],false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Teledelay:    '+inttostr(teledelay),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Televnum:     '+inttostr(televnum),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Min. level:   '+inttostr(min_level),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Max. level:   '+inttostr(max_level),false,ch,nil,nil,TO_CHAR);

    (* if (exits_first<>nil) then
      begin
      act(AT_REPORT,#13#10'Exits:',false,ch,nil,nil,TO_CHAR);
      pexit:=exits_first;
      while (pexit<>nil) do
        begin
        strpcopy(buf,'('+pad_integer(pexit.vnum,6)+') '+pad_string(headings[pexit.direction],10)+' [');
        if (pexit.exit_flag=0) then
          strcat(buf,' none')
        else
        for a:=0 to High(exit_flags) do
         if IS_SET(pexit.exit_flag,1 shl a) then
          strpcopy(strend(buf),' '+exit_flags[a]);
        strcat(buf,' ]');
        act(AT_REPORT,buf,false,ch,nil,nil,TO_CHAR);
        pexit:=pexit.next;
        end;
      end;
    end;
end; *)

{Jago 10/Jan/2001 : new imm commands, copied from MERC }
{RSTAT : return data about a room}
procedure do_rstat(ch : GCharacter; param : string);
var
	buf, buf1, arg : string;
  location : GRoom;
  location_node : GListNode;
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
  buf := Format('Name: %s.' + #13#10 + 'Area: %s.' + #13#10 + 'Author: %s' + #13#10#13#10,
                 [location.name, location.area.name, location.area.author]);

  buf1 := buf1 + buf;

  buf := Format('Vnum %d, sector [%s].' + #13#10,
                [location.vnum, sector_types[location.sector]]);

  buf1 := buf1 + buf;

  buf := '';

  if (location.flags = 0) then
    buf := 'none'
  else
  for a:=0 to High(room_flags) do
   if IS_SET(location.flags, 1 shl a) then
    buf := buf + room_flags[a] + ' ';

  buf := Format('Room flags: [%s].' + #13#10#13#10 + 'Description: ' + #13#10 + '%s'#13#10,
                [buf, location.description]);

  buf1 := buf1 + buf;

  buf1 := buf1 + 'Characters: ';

  rch_node := location.chars.head;
  while rch_node <> nil do
  begin
    rch := GCharacter(rch_node.element);

//    one_argument( rch.name, buf ); // first name only
		 buf := rch.name;
    buf1 := buf1 + buf;
    buf1 := buf1 + ', ';

    rch_node := rch_node.next;
  end;

  buf1 := buf1 + #13#10;
  buf1 := buf1 + 'Objects: ';

  obj_node := location.objects.head;
  while obj_node <> nil do
  begin
    obj_data := GObject(obj_node.element);

//    one_argument( obj_data.name, buf ); // first name only
	   buf := obj_data.name;
    buf1 := buf1 + buf;
    buf1 := buf1 + ', ';

    obj_node := obj_node.next;
  end;

  buf1 := buf1 + #13#10#13#10;

  door := 0;
  exit_node := location.exits.head;
  while exit_node <> nil do begin
    exit_data := GExit(exit_node.element);

    inc(door);

    if (exit_data.exit_flag=0) then
      buf := 'none'
    else
      begin
      buf := '';
      for a:=0 to High(exit_flags) do
       if IS_SET(exit_data.exit_flag,1 shl a) then
        buf := buf + exit_flags[a] + ' ';
      end;

    buf := Format('Door: %d.  To: %d.  Key: %d.  Exit flags: [%s].' +
    							 #13#10 + 'Keyword: "%s".',
                  [door,
                  exit_data.to_room.vnum,
                  exit_data.key,
                  buf,
                  exit_data.keyword]);

    buf1 := buf1 + buf;
    buf1 := buf1 + #13#10;

    exit_node := exit_node.next;
  end;

  buf1 := buf1 + #13#10;
  ch.sendBuffer(buf1);
end;

{Jago 10/Jan/2001 - utility function}
function actBitName(vector : integer) : String;
begin
  Result := '';

	if (vector and ACT_NPC) = ACT_NPC then Result := Result + ' npc';
	if (vector and ACT_SENTINEL) = ACT_SENTINEL then Result := Result + 'sentinel';
	if (vector and ACT_SCAVENGER) = ACT_SCAVENGER then Result := Result + 'scavenger';
	if (vector and ACT_AGGRESSIVE) = ACT_AGGRESSIVE then Result := Result + 'aggressive';
	if (vector and ACT_STAY_AREA) = ACT_STAY_AREA then Result := Result + 'stay_area';
	if (vector and ACT_TEACHER) = ACT_TEACHER then Result := Result + 'teacher';
end;

{Jago 10/Jan/2001 - utility function}
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

{Jago 10/Jan/2001 - utility function}
function affectLocName(location : integer) : string;
begin
	Result := '';    // dummy func, affect locations not implemented yet??
end;

{Jago 10/Jan/2001
MSTAT : return data about a mobile - can also be used on players}
procedure do_mstat(ch : GCharacter; param : string);
var
	buf, buf1, arg, gender, exp, vnum, room_vnum, wimpy : string;
fighting, master, leader : string;
affect_node, victim_node, paf_node : GListNode;
paf : GAffect;
victim : GCharacter;
begin

  one_argument( param, arg );

  if length(arg) = 0 then
  begin
    ch.SendBuffer('Mstat whom?' + #13#10);
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
   if victim.npc_index <> nil then
    vnum := IntToStr(victim.npc_index.vnum)
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
                [victim.ability.str,
                victim.ability.int,
                victim.ability.wis,
                victim.ability.dex,
                victim.ability.con]);

  buf1 := buf1 + buf;

  buf := Format('Hp: %d/%d.  Mana: %d/%d.  Move: %d/%d.' + #13#10,
                [victim.point.hp, victim.point.max_hp,
                victim.point.mana, victim.point.max_mana,
                victim.point.mv, victim.point.max_mv]);

  buf1 := buf1 + buf;

  if victim.IS_NPC then
  	exp := 'none'
  else
  	exp := IntToStr(victim.player.xptot);

  buf := Format('Level: %d.  Align: %d.  AC: %d.  Gold: %d.  Exp: %s.' + 
#13#10,
                [victim.level, victim.alignment, victim.point.ac,
                victim.gold, exp]);

  buf1 := buf1 + buf;

  if victim.IS_NPC then
  	wimpy := 'none'
  else
  	wimpy := IntToStr(victim.player.wimpy);

  buf := Format('Hitroll: %d.  Position: %d.  Wimpy: %s.' + #13#10,
                [victim.point.hitroll,
                victim.position,
                wimpy]);

  buf1 := buf1 + buf;

  if not victim.IS_NPC then
  	buf1 := buf1 + 'Page Lines: ' + IntToStr(victim.player.pagerlen) + '.' + 
#13#10;

  if victim.fighting <> nil then
    buf1 := buf1 + 'Fighting: ' + victim.fighting.name + '.' + #13#10
  else
    buf1 := buf1 + 'Fighting: (none).' + #13#10;

  if not victim.IS_NPC then
  begin
  	buf := Format('Thirst: %d.  Full: %d.  Drunk: %d.  Saving throw: %d.' + 
#13#10,
                 [victim.player.condition[COND_THIRST],
                 victim.player.condition[COND_FULL],
                 victim.player.condition[COND_DRUNK]]);
   buf1 := buf1 + buf;

   // how to get # of items carried?
   buf := Format('Carry number: .  Carry weight: %d.' + #13#10,
                [victim.carried_weight]);

   buf1 := buf1 + buf;

   buf := Format('Age: %d.  Played: %d.  Timer: %d.  Act: %s.' + #13#10,
                [victim.player.age,
                round(victim.player.played),
                victim.wait,
                actBitName(victim.act_flags)]);

   buf1 := buf1 + buf;
  end;

  if victim.master <> nil then
  	master := victim.master.name
  else
  	master := '(none)';

  if victim.leader <> nil then
  	master := victim.leader.name
  else
  	master := '(none)';

  buf := Format('Master: %s.  Leader: %s.  Affected by: %s.' + #13#10,
                [master, leader, affectBitName(victim.aff_flags)]);

  buf1 := buf1 + buf;

  buf := Format('Short description: %s.' + #13#10 + 'Long  description: %s' 
+ #13#10,
                [victim.short, victim.long]);

  buf1 := buf1 + buf;


  if victim.IS_NPC then
     if victim.npc_index <> nil then
     	if (victim.npc_index.programs.getSize > 0) then
       	buf1 := buf1 + 'Mobile has mobprogs.' + #13#10;


  paf_node := victim.affects.head;
  while paf_node <> nil do
  begin
  	paf := GAffect(paf_node.element);

   buf := Format('Spell: "%s" modifies %s by %d for %d hours with bits %s.' 
+ #13#10,
                 [skill_table[paf.sn].name,
                 '?', // affLocName(paf.location
                 paf.modifier,
                 paf.duration,
                 affectBitName(paf.aff_flag)]);

   buf1 := buf1 + buf;

   paf_node := paf_node.next;
  end;

  act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);
end;

{Jago 10/Jan/2001 - utility function (- move it to area.pas)}
function getObjectWorld(ch : GCharacter; param : string) : GObject;
var
	arg : string;
  obj : GObject;
  obj_node : GListNode;
  number, count : integer;
begin

  one_argument(param, arg);
  number := findNumber(arg); // eg 2.sword

  count := 0;

  // first try looking in inventory
  if ch.objects <> nil then
    obj := ch.findInventory(param);

  if obj <> nil then
  begin
     Result := obj;
     exit;
  end;

  // then try the current room
  if ch.room <> nil then
    obj := ch.room.findObject(param);

  if obj <> nil then
  begin
     Result := obj;
     exit;
  end;

  // then try the world!
  obj_node := object_list.head;
  while obj_node <> nil do
  begin
     obj := GObject(obj_node.element);
     // assume ch can see obj, after all ch is an imm
     if isName(obj.name, arg) then
     begin
      inc(count);
       if count = number then
       begin
         Result := obj;
         exit;
       end;
     end;
    obj_node := obj_node.next;
  end;

	Result := nil;
end;

{Jago 10/Jan/2001
OSTAT : return data about an object}
procedure do_ostat(ch : GCharacter; param : string);
var
	buf, buf1, arg : string;
aff_node, obj_node : GListNode;
aff_data : GAffect;
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

  obj:= getObjectWorld(ch, arg);
  if obj= nil then
  begin
    ch.sendBuffer('Nothing like that in hell, earth, or heaven.' + #13#10);
    exit;
  end;

  buf1 := 'Name: ' + obj.name + '.' + #13#10;

  buf := Format('Vnum: %d.  Type: %s.' + #13#10 +
                'Short description: %s.' + #13#10 +
                'Long description: %s' + #13#10,
                [obj.obj_index.vnum,
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

  {if obj.carried_by = nil then
  	carried_by := ''
  else
  	carried_by := obj.carried_by.name;}
  carried_by := '(none)';

  buf := Format('In room: %d.  In object: %s.  Carried by: %s.  {Wear_loc:}.' + #13#10,
                [room, in_obj, carried_by]);

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
  obj_index : GObjectIndex;
  obj : GObject;
  node : GListNode;
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
  obj_index := findObjectIndex(strtoint(arg1));

  if obj_index = nil then
  begin
     ch.sendBuffer('No object has that vnum.' + #13#10);
     exit;
  end;

  // create the obj
  obj := instanceObject(obj_index);

  // give obj to ch
  ch.objects.insertLast(obj);

  act(AT_WHITE, '$n has created $p!', false, ch, obj, nil, TO_ROOM);
  ch.sendBuffer('Ok.');
end;

{jago - utility func, move to area.pas}
function instanceNPC(npcindex : GNPCIndex) : GCharacter;
var
npc : GCharacter;
begin

  // note : this func doesnt check
  // npcindex.count + 1 < reset.max
  // this is so imms can mload more npcs than the reset maximum

  // this func does not place the npc in a room, the calling func is
  // responsible for that

  if (npcindex = nil) then
  begin
    bugreport('instanceNPC', 'area.pas', 'npc_index null',
              'The index to create a npc from is invalid.');
    Result := nil;
    exit;
  end;

  npc := GCharacter.Create;

  with npc do
  begin
    ability.str:=npcindex.str;
    ability.con:=npcindex.con;
    ability.dex:=npcindex.dex;
    ability.int:=npcindex.int;
    ability.wis:=npcindex.wis;
    point.hp:=npcindex.hp;
    point.max_hp:=npcindex.hp;
    point.mv:=npcindex.mv;
    point.max_mv:=npcindex.mv;
    point.mana:=npcindex.mana;
    point.max_mana:=npcindex.mana;
    point.natural_ac:=npcindex.natural_ac;
    point.ac_mod:=0;
    point.hitroll:=npcindex.hitroll;

    point.damnumdie:=npcindex.damnumdie;
    point.damsizedie:=npcindex.damsizedie;
    point.apb:=npcindex.apb;
    move(npcindex.learned,learned,sizeof(learned));
    clan:=npcindex.clan;
    conn:=nil;

    npc.room := nil;//findRoom(reset.arg2);

    position:=POS_STANDING;
    npc.npc_index := npcindex;

    name := hash_string(npcindex.name);
    short := hash_string(npcindex.short);
    long := hash_string(npcindex.long);

    sex:=npcindex.sex;
    race:=npcindex.race;
    alignment:=npcindex.alignment;
    level:=npcindex.level;
    weight:=npcindex.weight;
    height:=npcindex.height;
    act_flags:=npcindex.act_flags;
  end; {with}

  inc(npcindex.count);
  npc.node_world := char_list.insertLast(npc);

  npc.calcAC;

  Result := npc;
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
  ch.sendBuffer('Ok.');
end;


{Jago 18/Jan/2001 - OFIND - find an object}
procedure do_ofind(ch : GCharacter; param : string);
var
top_obj_index, vnum, nMatch : integer;
buf, buf1, arg : string;
obj_index : GObjectIndex;
found, fAll : boolean;
obj_node : GListNode;
begin
  one_argument( param, arg );

  if length(arg) = 0 then
  begin
   ch.sendBuffer('Ofind what?' + #13#10);
   exit;
  end;

  buf := '';
  buf1 := '';
  fAll := (UpperCase(arg) = 'ALL');  //fAll	= !str_cmp( arg, "all" );
  found := False;
  nMatch := 0;

  // need to find a good way of doing this
  // iterating over all objects is SLOW!

  // does it make a difference if we iterate over object_list or obj_reset?

  obj_node := obj_reset.head;
  while obj_node <> nil do
  begin
    obj_index := GObjectIndex(obj_node.element);
    if (fAll) or (isName(obj_index.name, arg)) then
    begin
      found := True;
      buf := Format('[%5d] %s' + #13#10, [obj_index.vnum, obj_index.short]);

      if not fAll then
        buf1 := buf1 + buf
      else
        act(AT_REPORT, buf, false, ch, nil, nil, TO_CHAR);
    end;
    obj_node := obj_node.next;
  end;

  if not found then
  begin
   ch.sendBuffer('Nothing like that in hell, earth, or heaven.' + #13#10);
   exit;
  end;

  if not fAll then
   act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);
end;

{Jago 18/Jan/2001 - MFIND - find a NPC}
procedure do_mfind(ch : GCharacter; param : string);
var
top_npc_index, vnum, nMatch : integer;
buf, buf1, arg : string;
npc_index : GNPCIndex;
found, fAll : boolean;
npc_node : GListNode;
begin
  one_argument( param, arg );

  if length(arg) = 0 then
  begin
   ch.sendBuffer('Mfind whom?' + #13#10);
   exit;
  end;

  buf := '';
  buf1 := '';
  fAll := (UpperCase(arg) = 'ALL');  //fAll	= !str_cmp( arg, "all" );
  found := False;
  nMatch := 0;

  // need to find a good way of doing this
  // iterating over all npcs is SLOW!

  // does it make a difference if we iterate over character_list or
  // npc_reset?

  npc_node := npc_reset.head;
  while npc_node <> nil do
  begin
    npc_index := GNPCIndex(npc_node.element);
    if (fAll) or (isName(npc_index.name, arg)) then
    begin
      found := True;
      buf := Format('[%5d] %s' + #13#10, [npc_index.vnum, npc_index.short]);

      if not fAll then
        buf1 := buf1 + buf
      else
        act(AT_REPORT, buf, false, ch, nil, nil, TO_CHAR);
    end;
    npc_node := npc_node.next;
  end;

  if not found then
  begin
    ch.sendBuffer('Nothing like that in hell, earth, or heaven.' + #13#10);
    exit;
  end;

  if not fAll then
    act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);
end;


