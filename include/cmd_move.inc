procedure makeblood(ch : GCharacter; pexit : GExit);
var obj : GObject;
    node : GListNode;
begin
  node := ch.room.objects.head;

  while (node <> nil) do
    begin
    obj := node.element;

    if (obj.item_type=ITEM_BLOOD) and (obj.value[2]=pexit.direction) then
      begin
      exit;
      break;
      end;

    node := node.next;
    end;

  obj := nil;

  obj := GObject.Create;

  with obj do
    begin
    name := hash_string('a trail of blood');
    short := hash_string('a trail of $B$4blood$A$7');
    long := hash_string('a trail of $B$4blood$A$3 goes ' + headings[pexit.direction]);

    item_type:=ITEM_BLOOD;
    SET_BIT(flags,OBJ_NOPICKUP);
    SET_BIT(flags,OBJ_NOSAC);

    value[2]:=pexit.direction;
    wear1:=0; wear2:=0;
    weight:=0;
    obj_index:=nil;
    timer := 60;
    end;

  obj.node_world := object_list.insertLast(obj);

  obj.toRoom(ch.room);
end;

procedure maketrack(ch : GCharacter; pexit : GExit);
var
   node : GListNode;
   track : GTrack;
begin
  // first check wether tracks already exist
  node := ch.room.tracks.head;

  while (node <> nil) do
    begin
    track := node.element;

    if (track.who = ch.name^) and (track.direction = pexit.direction) then
      begin
      track.life := 150;
      exit;
      end;

    node := node.next;
    end;

  track := GTrack.Create;

  track.who := ch.name^;
  track.direction := pexit.direction;
  track.life := 150;

  ch.room.tracks.insertLast(track);
end;

function do_move(ch : GCharacter; pexit : GExit) : boolean;
var vict,vict_next:GCharacter;
    sneaking:boolean;
    txt_ch,txt_room:array[0..32] of char;
    room_pos,room_to : GRoom;
    mv_cost:integer;
    drunk:boolean;
    node, node_next : GListNode;
begin
  do_move:=false;
  room_pos:=ch.room;

  if (not ch.IS_NPC) and (number_percent<ch.player^.condition[COND_DRUNK]) then
    drunk := true
  else
    drunk := false;

  if (drunk) then
    pexit := room_pos.findExit(random(6)+1);

  { if exit is hidden or it is secret and closed then no exit - Grimlord }
  if (pexit=nil) or (IS_SET(pexit.flags, EX_SECRET) and IS_SET(pexit.flags, EX_CLOSED)) then
    begin
    ch.sendBuffer('You can''t go in that direction.'#13#10);
    exit;
    end
  else
    begin
    room_to := findRoom(pexit.vnum);

    if (room_to = nil) then
      begin
      ch.sendBuffer('You can''t go in that direction.'#13#10);

      bugreport('do_move', 'cmd_move.inc', 'room_to (' + inttostr(room_pos.vnum) + ' -> ' + inttostr(pexit.vnum) + ') is null',
                'The room this exit links to does not exist. Please check this area.');
      exit;
      end;
    end;

  if (ch.position = POS_FIGHTING) then
    begin
    ch.sendBuffer('You are fighting and cannot move.'#13#10);
    exit;
    end;

  if (ch.position = POS_BASHED) then
    begin
    ch.sendBuffer('You are bashed and cannot move.'#13#10);
    exit;
    end;

  if (ch.position <= POS_STUNNED) then
    begin
    ch.sendBuffer('You are hurt too badly.'#13#10);
    exit;
    end;

  if (ch.position <> POS_STANDING) then
    begin
    ch.sendBuffer('You must stand up first.'#13#10);
    exit;
    end;

  if (ch.IS_NPC) and (IS_SET(pexit.flags, EX_NOMOB)) then
    begin
    ch.sendBuffer('Sorry, you cannot pass.'#13#10);
    exit;
    end;

  if (ch.IS_NPC) and (IS_SET(pexit.flags, EX_PORTAL)) then
    begin
    ch.sendBuffer('Sorry, you cannot use portals.'#13#10);
    exit;
    end;

  if (not ch.IS_IMMORT) and (IS_SET(pexit.to_room.flags,ROOM_PRIVATE)) then
    begin
    ch.sendBuffer('That room is private.'#13#10);
    exit;
    end;

  if (ch.IS_EVIL) and (IS_SET(pexit.to_room.flags,ROOM_GOOD)) then
    begin
    ch.sendBuffer('An irritating holy force prevents you from entering.'#13#10);
    exit;
    end;

  if (ch.IS_GOOD) and (IS_SET(pexit.to_room.flags,ROOM_EVIL)) then
    begin
    ch.sendBuffer('A distinct evil force prevents you from entering.'#13#10);
    exit;
    end;

  if (IS_SET(pexit.to_room.flags,ROOM_SOLITARY)) and (pexit.to_room.chars.getSize > 0) then
    begin
    ch.sendBuffer('Only one person can enter that room at a time.'#13#10);
    exit;
    end;

  if (IS_SET(pexit.flags, EX_CLOSED)) then
    begin
    act(AT_REPORT, 'The $d is closed.', false, ch, nil, pexit, TO_CHAR);
    exit;
    end;

  if (room_pos.sector=SECT_AIR) or (room_to.sector=SECT_AIR) or
   IS_SET(pexit.flags, EX_FLY) then
    if (not ch.IS_FLYING) then
     begin
     ch.sendBuffer('You''d need to fly to get there.'#13#10);
     exit;
     end;

  if (room_pos.sector = SECT_NOPASSAGE) then
    begin
    ch.sendBuffer('You cannot fly, walk or swim there... it''s too dangerous.'#13#10);
    exit;
    end;

  if (room_pos.sector = SECT_WATER_NOSWIM) or (room_to.sector = SECT_WATER_NOSWIM) then
    begin
    ch.sendBuffer('That water is too deep to swim in, you need a boat!'#13#10);
    exit;
    end;

  if (ch.level<room_to.min_level) or (ch.level>room_to.max_level) and
   (not ch.IS_IMMORT) and (not ch.IS_NPC) then
    begin
    ch.sendBuffer('A strange force prevents you from travelling there.'#13#10);
    exit;
    end;

  node := ch.room.chars.head;

  while (node <> nil) do
    begin
    { when this mob blocks ch, we don't want to continue - Grimlord }
    vict := node.element;
    
    if blockTrigger(vict, ch, pexit.vnum) then
      begin
      ch.sendBuffer('A strange force prevents you from travelling there.'#13#10);
      exit;
      end;

    node := node.next;
    end;

  if (not ch.IS_FLYING) then
    mv_cost := movement_loss[room_pos.sector]
  else
    mv_cost := 1;

  if (ch.point.mv < mv_cost) then
    begin
    ch.sendBuffer('You are too exhausted.'#13#10);
    exit;
    end;

  if (not ch.IS_NPC) then
    begin
    if (ch.point.hp < ch.point.max_hp div 2) then
      makeblood(ch, pexit);

    maketrack(ch, pexit);
    end;

  sneaking := (IS_SET(ch.aff_flags,AFF_SNEAK) and skill_success(ch,gsn_sneak));

  if sneaking then
    improve_skill(ch, gsn_sneak)
  else
    begin
    if (ch.IS_FLYING) then
      begin
      txt_ch:='fly';
      txt_room:='flies';
      end
    else
    if (IS_SET(pexit.flags, EX_SWIM)) then
      begin
      txt_ch:='swim';
      txt_room:='swims';
      end
    else
    if IS_SET(pexit.flags, EX_CLIMB) then
      begin
      txt_ch:='climb';
      txt_room:='climbs';
      end
    else
      begin
      txt_ch:='walk';
      txt_room:='walks';
      end;

    if IS_SET(pexit.flags, EX_PORTAL) or IS_SET(pexit.flags, EX_ENTER) then
      act(AT_REPORT,'$n leaves through the $d.',true,ch,nil, pexit,TO_ROOM)
    else
      act(AT_REPORT,'$n '+txt_room+' ' + headings[pexit.direction] + '.',true,ch,nil,nil,TO_ROOM);
    end;

  ch.fromRoom;
  ch.toRoom(room_to);

  dec(ch.point.mv, mv_cost);
  if (ch.point.mv < 6) then
    act(AT_REPORT,'You start breathing heavily... you are very tired.',false,ch,nil,nil,TO_CHAR);

  if not sneaking then
    begin
    if IS_SET(pexit.flags, EX_PORTAL) or IS_SET(pexit.flags, EX_ENTER) then
      begin
      act(AT_REPORT,'$n enters from somewhere.',true,ch,nil,nil,TO_ROOM);
      act(AT_REPORT,'You enter the $d.',false,ch,nil,pexit,TO_CHAR);
      end
    else
      begin
      act(AT_REPORT,'$n ' + txt_room + ' in from ' + headingsi[pexit.direction] + '.',true,ch,nil,nil,TO_ROOM);
      act(AT_REPORT,'You ' + txt_ch + ' ' + headings[pexit.direction] + '.',false,ch,nil,nil,TO_CHAR);
      end;
    end;

  if (not ch.IS_OUTSIDE) then
   if (ch.IS_FLYING) then
    begin
    ch.sendBuffer('You cannot fly while indoors!'#13#10);
    ch.stopFlying;
    end;

  do_look(ch,'_AUTO');

  if (ch.tracking <> '') then
    begin
    removeTimer(ch, TIMER_TRACK);
    interpret(ch, 'track');
    end;

  node := room_pos.chars.head;

  while (node <> nil) do
    begin
    node_next := node.next;
    vict := node.element;

    if (vict.master = ch) then
      begin
      vict.in_command := true;

      act(AT_REPORT,'You follow $N '+headings[pexit.direction]+'.',false,vict,nil,ch,TO_CHAR);
      do_move(vict,pexit);
      vict.emptyBuffer;

      vict.in_command := false;
      end;

    node := node_next;
    end;

  if (not ch.IS_NPC) then
    greetTrigger(ch);

  do_move := true;
end;

procedure do_north(ch:GCharacter;param:string);
begin
  do_move(ch, ch.room.findExit(DIR_NORTH));
end;

procedure do_east(ch:GCharacter;param:string);
begin
  do_move(ch, ch.room.findExit(DIR_EAST));
end;

procedure do_south(ch:GCharacter;param:string);
begin
  do_move(ch, ch.room.findExit(DIR_SOUTH));
end;

procedure do_west(ch:GCharacter;param:string);
begin
  do_move(ch, ch.room.findExit(DIR_WEST));
end;

procedure do_down(ch:GCharacter;param:string);
begin
  do_move(ch, ch.room.findExit(DIR_DOWN));
end;

procedure do_up(ch:GCharacter;param:string);
begin
  do_move(ch, ch.room.findExit(DIR_UP));
end;

procedure do_sleep(ch:GCharacter;param:string);
begin
  with ch do
   case position of
     POS_FIGHTING:act(AT_REPORT,'You are fighting!',false,ch,nil,nil,TO_CHAR);
       POS_BASHED:act(AT_REPORT,'You are bashed to the ground!',false,ch,nil,nil,TO_CHAR);
     POS_DEAD,POS_MORTAL,POS_INCAP,POS_STUNNED:act(AT_REPORT,'You are hurt to badly.',false,ch,nil,nil,TO_CHAR);
     POS_SLEEPING:act(AT_REPORT,'You are already sleeping!',false,ch,nil,nil,TO_CHAR);
     POS_MEDITATE:begin
                  act(AT_REPORT,'You stop meditating and fall sleep.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stops meditating and falls asleep.',true,ch,nil,nil,TO_ROOM);
                  position:=POS_SLEEPING;
                  end;
     POS_RESTING,POS_SITTING:begin
                  act(AT_REPORT,'You fall asleep.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n falls asleep.',true,ch,nil,nil,TO_ROOM);
                  position:=POS_SLEEPING;
                  end;
     POS_STANDING:begin
									ch.stopFlying;
                  act(AT_REPORT,'You lie down and fall sleep.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n lies down and falls asleep.',true,ch,nil,nil,TO_ROOM);
                  position:=POS_SLEEPING;
                  end;
   end;
end;

procedure do_stand(ch:GCharacter;param:string);
begin
  with ch do
   case position of
     POS_FIGHTING,POS_STANDING:act(AT_REPORT,'You are already standing.',false,ch,nil,nil,TO_CHAR);
       POS_BASHED:act(AT_REPORT,'You are bashed to the ground!',false,ch,nil,nil,TO_CHAR);
     POS_DEAD,POS_MORTAL,POS_INCAP,POS_STUNNED:act(AT_REPORT,'You are hurt to badly.',false,ch,nil,nil,TO_CHAR);
     POS_SLEEPING:begin
                  position:=POS_STANDING;
                  act(AT_REPORT,'You awake and stand up.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n awakes and stands up.',true,ch,nil,nil,TO_ROOM);
                  end;
     POS_MEDITATE:begin
                  position:=POS_STANDING;
                  act(AT_REPORT,'You stop meditating and stand up.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stops meditating and stands up.',true,ch,nil,nil,TO_ROOM);
                  end;
     POS_RESTING,POS_SITTING:begin
                  position:=POS_STANDING;
                  act(AT_REPORT,'You stand up.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stands up.',true,ch,nil,nil,TO_ROOM);
                  end;
   end;
end;

procedure do_meditate(ch:GCharacter;param:string);
begin
  with ch do
   case position of
     POS_FIGHTING:act(AT_REPORT,'You are fighting!',false,ch,nil,nil,TO_CHAR);
       POS_BASHED:act(AT_REPORT,'You are bashed to the ground!',false,ch,nil,nil,TO_CHAR);
     POS_DEAD,POS_MORTAL,POS_INCAP,POS_STUNNED:act(AT_REPORT,'You are hurt to badly.',false,ch,nil,nil,TO_CHAR);
     POS_SLEEPING:act(AT_REPORT,'You are asleep.',false,ch,nil,nil,TO_CHAR);
     POS_MEDITATE:begin
                  position:=POS_STANDING;
                  act(AT_REPORT,'You stop meditating and stand up.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stops meditating and stands up.',true,ch,nil,nil,TO_ROOM);
                  end;
     POS_RESTING,POS_SITTING:begin
                  position:=POS_STANDING;
                  act(AT_REPORT,'You start meditating.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n starts meditating.',true,ch,nil,nil,TO_ROOM);
                  end;
     POS_STANDING:begin
                  position:=POS_MEDITATE;
									ch.stopFlying;
                  act(AT_REPORT,'You sit down cross-legged and begin meditating.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n sits down cross-legged and begins meditating.',true,ch,nil,nil,TO_ROOM);
                  end;
   end;
end;

procedure do_rest(ch:GCharacter;param:string);
begin
  with ch do
   case position of
     POS_FIGHTING:act(AT_REPORT,'You are fighting!',false,ch,nil,nil,TO_CHAR);
       POS_BASHED:act(AT_REPORT,'You are bashed to the ground!',false,ch,nil,nil,TO_CHAR);
     POS_DEAD,POS_MORTAL,POS_INCAP,POS_STUNNED:act(AT_REPORT,'You are hurt to badly.',false,ch,nil,nil,TO_CHAR);
     POS_SLEEPING:begin
                  position:=POS_RESTING;
                  act(AT_REPORT,'You wake up and rest.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n wakes up and rests.',false,ch,nil,nil,TO_ROOM);
                  end;
     POS_MEDITATE:begin
                  position:=POS_RESTING;
                  act(AT_REPORT,'You stop meditating and go to rest.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stops meditating and rests.',true,ch,nil,nil,TO_ROOM);
                  end;
      POS_RESTING:begin
                  position:=POS_STANDING;
                  act(AT_REPORT,'You stop resting and stand up.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stops resting and stands up.',false,ch,nil,nil,TO_ROOM);
                  end;
      POS_SITTING:begin
                  position:=POS_RESTING;
                  act(AT_REPORT,'You rest.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n rests.',true,ch,nil,nil,TO_ROOM);
                  end;
     POS_STANDING:begin
                  position:=POS_RESTING;
									ch.stopFlying;
                  act(AT_REPORT,'You sit down comfortably and rest.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n sits down comfortably and rests.',true,ch,nil,nil,TO_ROOM);
                  end;
   end;
end;

procedure do_sit(ch:GCharacter;param:string);
begin
  with ch do
   case position of
     POS_FIGHTING:act(AT_REPORT,'You are fighting!',false,ch,nil,nil,TO_CHAR);
       POS_BASHED:act(AT_REPORT,'You are bashed to the ground!',false,ch,nil,nil,TO_CHAR);
     POS_DEAD,POS_MORTAL,POS_INCAP,POS_STUNNED:act(AT_REPORT,'You are hurt to badly.',false,ch,nil,nil,TO_CHAR);
     POS_SLEEPING:begin
                  position:=POS_SITTING;
                  act(AT_REPORT,'You wake up and sit down.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n wakes up and sits down.',false,ch,nil,nil,TO_ROOM);
                  end;
     POS_MEDITATE:begin
                  position:=POS_SITTING;
                  act(AT_REPORT,'You stop meditating.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stops meditating.',true,ch,nil,nil,TO_ROOM);
                  end;
      POS_RESTING:begin
                  position:=POS_SITTING;
                  act(AT_REPORT,'You stop resting.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stops resting.',false,ch,nil,nil,TO_ROOM);
                  end;
      POS_SITTING:begin
                  position:=POS_STANDING;
                  act(AT_REPORT,'You stand up.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n stands up.',false,ch,nil,nil,TO_ROOM);
                  end;
     POS_STANDING:begin
                  position:=POS_SITTING;
									ch.stopFlying;
                  act(AT_REPORT,'You sit down.',false,ch,nil,nil,TO_CHAR);
                  act(AT_REPORT,'$n sits down.',true,ch,nil,nil,TO_ROOM);
                  end;
   end;
end;

procedure do_wake(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Wake whom?'#13#10);
    exit;
    end;

  vict := ch.room.findChar(ch, param);

  if (vict=nil) then
    ch.sendBuffer('They aren''t here.'#13#10)
  else
  if (vict=ch) then
    do_stand(ch,'')
  else
  if (vict.position<>POS_SLEEPING) then
    act(AT_REPORT,'$N is not sleeping.',false,ch,nil,vict,TO_CHAR)
  else
    begin
    act(AT_REPORT,'You wake $N.',false,ch,nil,vict,TO_CHAR);
    act(AT_REPORT,'$n wakes $N.',false,ch,nil,vict,TO_ROOM);
    vict.position:=POS_STANDING;
    end;
end;

procedure do_enter(ch:GCharacter;param:string);
var pexit, lexit : GExit;
    node : GListNode;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Enter what?'#13#10);
    exit;
    end;

  pexit:=nil;

  node := ch.room.exits.head;

  while (node <> nil) do
    begin
    lexit := node.element;

    if (IS_SET(lexit.flags, EX_PORTAL) or IS_SET(lexit.flags, EX_ENTER))
     and (pos(param, lexit.keywords^) <> 0) then
      begin
      pexit:=lexit;
      break;
      end;

    node := node.next;
    end;

  do_move(ch,pexit);
end;

procedure do_open(ch:GCharacter;param:string);
var room_pos : GRoom;
    pexit : GExit;
    dir:integer;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Open what?'#13#10);
    exit;
    end;

  room_pos:=ch.room;
  dir := findHeading(param);
  pexit := room_pos.findExit(dir);

  if (pexit <> nil) and (IS_SET(pexit.flags, EX_SECRET)) then
    pexit := nil;

  if (pexit = nil) then
    pexit := room_pos.findExitKeyword(param);

  if (pexit = nil) then
    begin
    ch.sendBuffer('That door cannot be found.'#13#10);
    exit;
    end;

  dir:=pexit.direction;

  if not IS_SET(pexit.flags, EX_ISDOOR) then
    begin
    ch.sendBuffer('That is not a door.'#13#10);
    exit;
    end;

  if not IS_SET(pexit.flags, EX_CLOSED) then
    begin
    ch.sendBuffer('That door is already open.'#13#10);
    exit;
    end;

  if IS_SET(pexit.flags, EX_LOCKED) then
    begin
    ch.sendBuffer('That door is locked.'#13#10);
    exit;
    end;

  REMOVE_BIT(pexit.flags, EX_CLOSED);

  act(AT_REPORT,'You open the $d.', false, ch, nil, pexit, TO_CHAR);
  act(AT_REPORT,'$n opens the $d.', false, ch, nil, pexit, TO_ROOM);

  { get reverse exit }
  room_pos := findRoom(pexit.vnum);

  if (room_pos = nil) then
    begin
    bugreport('do_open', 'cmd_move.inc', 'room_to (' + inttostr(ch.room.vnum) + ' -> ' + inttostr(pexit.vnum) + ') is null',
              'The room this exit links to does not exist. Please check this area.');
    exit;
    end;

  pexit := room_pos.findExit(dir_inv[dir]);

  if (pexit = nil) then
    begin
    bugreport('do_open', 'cmd_move.inc', 'reverse exit (' + inttostr(ch.room.vnum) + ') is null',
              'The reserve exit back to this room does not exist. Please check this area.');
    exit;
    end;

  REMOVE_BIT(pexit.flags, EX_CLOSED);
end;

procedure do_close(ch:GCharacter;param:string);
var room_pos : GRoom;
    pexit : GExit;
    dir:integer;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Close what?'#13#10);
    exit;
    end;

  room_pos := ch.room;
  dir := findHeading(param);
  pexit := room_pos.findExit(dir);

  if (pexit<>nil) and (IS_SET(pexit.flags, EX_SECRET)) then
    pexit := nil;

  if (pexit = nil) then
    pexit := room_pos.findExitKeyword(param);

  if (pexit = nil) then
    begin
    ch.sendBuffer('That door cannot be found.'#13#10);
    exit;
    end;

  dir:=pexit.direction;
  if not IS_SET(pexit.flags, EX_ISDOOR) then
    begin
    ch.sendBuffer('That is not a door.'#13#10);
    exit;
    end;

  if IS_SET(pexit.flags, EX_CLOSED) then
    begin
    ch.sendBuffer('That door is already closed.'#13#10);
    exit;
    end;

  SET_BIT(pexit.flags, EX_CLOSED);

  act(AT_REPORT,'You close the $d.', false, ch, nil, pexit, TO_CHAR);
  act(AT_REPORT,'$n closes the $d.', false, ch, nil, pexit, TO_ROOM);

  { get reverse exit }
  room_pos := findRoom(pexit.vnum);

  if (room_pos = nil) then
    begin
    bugreport('do_close', 'cmd_move.inc', 'room_to (' + inttostr(ch.room.vnum) + ' -> ' + inttostr(pexit.vnum) + ') is null',
              'The room this exit links to does not exist. Please check this area.');
    exit;
    end;

  pexit := room_pos.findExit(dir_inv[dir]);

  if (pexit = nil) then
    begin
    bugreport('do_close', 'cmd_move.inc', 'reverse exit (' + inttostr(ch.room.vnum) + ') is null',
              'The reserve exit back to this room does not exist. Please check this area.');
    exit;
    end;

  SET_BIT(pexit.flags, EX_CLOSED);
end;
