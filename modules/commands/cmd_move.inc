// $Id

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
    name := 'a trail of blood';
    short := 'a trail of $B$4blood$A$7';
    long := 'a trail of $B$4blood$A$3 goes ' + headings[pexit.direction];

    item_type:=ITEM_BLOOD;
    SET_BIT(flags,OBJ_NOPICKUP);
    SET_BIT(flags,OBJ_NOSAC);

    value[2]:=pexit.direction;
    weight:=0;
    timer := 60;
    end;

  obj.node_world := objectList.insertLast(obj);

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

    if (track.who = ch.name) and (track.direction = pexit.direction) then
      begin
      track.life := 150;
      exit;
      end;

    node := node.next;
    end;

  track := GTrack.Create;

  track.who := ch.name;
  track.direction := pexit.direction;
  track.life := 150;

  ch.room.tracks.insertLast(track);
end;

function do_move(ch : GCharacter; pexit : GExit) : boolean; overload;
var 
  vict : GCharacter;
  sneaking : boolean;
  txt_ch, txt_room : string;
  room_pos, room_to : GRoom;
  mv_cost : integer;
  drunk : boolean;
  node, node_next : GListNode;
  p : integer;
begin
  do_move := false;
  room_pos := ch.room;

  if (not ch.IS_NPC) and (ch.IS_DRUNK) then
    drunk := true
  else
    drunk := false;

  if (drunk) then
    begin
    ch.sendBuffer('You sway a bit and have trouble maintaining your balance.'#13#10);
    pexit := room_pos.findExit(random(6)+1);
    end;

  { if exit is hidden or it is secret and closed then no exit - Grimlord }
  if (pexit = nil) or (IS_SET(pexit.flags, EX_SECRET) and IS_SET(pexit.flags, EX_CLOSED)) and (not ch.IS_HOLYWALK) then
    begin
    if (drunk) then
      case random(3) of
        0 : begin
            act(AT_REPORT, 'You stumble into some obstacle.', false, ch, nil, nil, TO_CHAR);
            act(AT_REPORT, '$n stumbles into an obstacle.', false, ch, nil, nil, TO_ROOM);
            end;
        1 : begin
            act(AT_REPORT, 'Your arms flailing wildly, you trip and tumble to the ground.', false, ch, nil, nil, TO_CHAR);
            act(AT_REPORT, 'Arms flailing wildly, $n trips and tumbles to the ground.', false, ch, nil, nil, TO_ROOM);
            end;
        2 : begin
            act(AT_REPORT, 'Staggering along, you are suddenly intercepted by something solid.', false, ch, nil, nil, TO_CHAR);
            act(AT_REPORT, 'Everything goes dark and blurry as you fall to the ground.', false, ch, nil, nil, TO_CHAR);

            act(AT_REPORT, '$n staggers along, muttering under $s breath, and bumps into something.', false, ch, nil, nil, TO_ROOM);
            act(AT_REPORT, 'A loud thud sounds as $n topples to the ground.', false, ch, nil, nil, TO_ROOM);
            end;
      end
    else
      ch.sendBuffer('You can''t go in that direction.'#13#10);

    exit;
    end
  else
    begin
    room_to := findRoom(pexit.vnum);

    if (room_to = nil) then
      begin
      ch.sendBuffer('You can''t go in that direction.'#13#10);

      bugreport('do_move', 'cmd_move.inc', 'room_to (' + inttostr(room_pos.vnum) + ' -> ' + inttostr(pexit.vnum) + ') is null');
      exit;
      end;
    end;

  if (ch.state = STATE_FIGHTING) then
    begin
    ch.sendBuffer('You are fighting and cannot move.'#13#10);
    exit;
    end;

  if (IS_SET(ch.aff_flags, AFF_BASHED) or IS_SET(ch.aff_flags, AFF_STUNNED)) then
    begin
    ch.sendBuffer('You are immobilized and cannot move.'#13#10);
    exit;
    end;

  if (not (ch.position in [POS_STANDING,POS_FLYING])) then
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

  if (not ch.IS_IMMORT) and (pexit.to_room.flags.isBitSet(ROOM_PRIVATE)) then
    begin
    ch.sendBuffer('That room is private.'#13#10);
    exit;
    end;

  if (ch.IS_EVIL) and (pexit.to_room.flags.isBitSet(ROOM_GOOD)) then
    begin
    ch.sendBuffer('An irritating holy force prevents you from entering.'#13#10);
    exit;
    end;

  if (ch.IS_GOOD) and (pexit.to_room.flags.isBitSet(ROOM_EVIL)) then
    begin
    ch.sendBuffer('A distinct evil force prevents you from entering.'#13#10);
    exit;
    end;

  if (pexit.to_room.flags.isBitSet(ROOM_SOLITARY)) and (pexit.to_room.chars.getSize > 0) and (not ch.IS_HOLYWALK) then
    begin
    ch.sendBuffer('Only one person can enter that room at a time.'#13#10);
    exit;
    end;

  if (IS_SET(pexit.flags, EX_CLOSED)) and (not ch.IS_HOLYWALK) then
    begin
    act(AT_REPORT, 'The $d is closed.', false, ch, nil, pexit, TO_CHAR);
    exit;
    end;

  if (room_pos.sector=SECT_AIR) or (room_to.sector=SECT_AIR) or
   IS_SET(pexit.flags, EX_FLY) then
    if (not ch.IS_FLYING) and (not ch.IS_HOLYWALK) then
     begin
     ch.sendBuffer('You''d need to fly to get there.'#13#10);
     exit;
     end;

  if (room_pos.sector = SECT_NOPASSAGE) and (not ch.IS_HOLYWALK) then
    begin
    ch.sendBuffer('You cannot fly, walk or swim there... it''s too dangerous.'#13#10);
    exit;
    end;

  if ((room_pos.sector = SECT_WATER_NOSWIM) or (room_to.sector = SECT_WATER_NOSWIM)) and (not ch.IS_HOLYWALK) then
    begin
    ch.sendBuffer('That water is too deep to swim in, you need a boat!'#13#10);
    exit;
    end;

  if ((ch.level < room_to.minlevel) or (ch.level > room_to.maxlevel)) and
   (not ch.IS_IMMORT) and (not ch.IS_NPC) then
    begin
    ch.sendBuffer('A strange force prevents you from travelling there.'#13#10);
    exit;
    end;

  { when a mob blocks ch, we don't want to continue - Grimlord }

  node := ch.room.chars.head;
  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.IS_NPC) then
      begin
      p := GNPC(vict).context.findSymbol('onBlock');

      if (p <> -1) then
        begin
        GNPC(vict).context.push(integer(ch));
        GNPC(vict).context.push(integer(vict));
        GNPC(vict).context.setEntryPoint(p);
        GNPC(vict).context.Execute;
        
        if (GNPC(vict).context.pop()) and (not ch.IS_HOLYWALK) then
          begin
          ch.sendBuffer('A strange force prevents you from travelling there.'#13#10);
          exit;
          end; 
        end;
      end;

    node := node.next;
    end;

  if (not ch.IS_FLYING) then
    mv_cost := movement_loss[room_pos.sector]
  else
    mv_cost := 1;

  if (ch.mv < mv_cost) then
    begin
    ch.sendBuffer('You are too exhausted.'#13#10);
    exit;
    end;

  if (not ch.IS_NPC) then
    begin
    if (ch.hp < ch.max_hp div 2) then
      makeblood(ch, pexit);

    maketrack(ch, pexit);
    end;

  sneaking := (IS_SET(ch.aff_flags,AFF_SNEAK) and skill_success(ch, gsn_sneak));

  if sneaking then
    improve_skill(ch, gsn_sneak);

  if (ch.IS_FLYING) then
    begin
    txt_ch := 'fly';
    txt_room := 'flies';
    end
  else
  if (IS_SET(pexit.flags, EX_SWIM)) then
    begin
    txt_ch := 'swim';
    txt_room := 'swims';
    end
  else
  if IS_SET(pexit.flags, EX_CLIMB) then
    begin
    txt_ch := 'climb';
    txt_room := 'climbs';
    end
  else
  if IS_SET(ch.aff_flags, AFF_SNEAK) then
    begin
    txt_ch := 'sneak';
    txt_room := 'sneaks';
    end
  else
  if (drunk) then
    begin
    txt_ch := 'stumble';
    txt_room := 'stumbles';
    end
  else
  if (ch.room.flags.isBitSet(ROOM_NOFLOOR)) then
    begin
    txt_ch := 'fall';
    txt_room := 'falls';
    end
  else
    begin
    txt_ch := 'walk';
    txt_room := 'walks';
    end;

  if (not sneaking) then
    begin
    if IS_SET(pexit.flags, EX_PORTAL) or IS_SET(pexit.flags, EX_ENTER) then
      act(AT_REPORT, '$n leaves through the $d.',true,ch,nil, pexit,TO_ROOM)
    else
      act(AT_REPORT, '$n ' + txt_room + ' ' + headings[pexit.direction] + '.',true,ch,nil,nil,TO_ROOM);
    end;

  ch.fromRoom;
  ch.toRoom(room_to);

  ch.mv := ch.mv - mv_cost;

  if (ch.mv < 15) then
    act(AT_REPORT,'You start breathing heavily... you are very tired.',false,ch,nil,nil,TO_CHAR);

  if IS_SET(pexit.flags, EX_PORTAL) or IS_SET(pexit.flags, EX_ENTER) then
    begin
    if (not sneaking) then
      act(AT_REPORT,'$n enters from somewhere.',true,ch,nil,nil,TO_ROOM);

    act(AT_REPORT,'You enter the $d.',false,ch,nil,pexit,TO_CHAR);
    end
  else
    begin
    if (not sneaking) then
      act(AT_REPORT,'$n ' + txt_room + ' in from ' + headingsi[pexit.direction] + '.',true,ch,nil,nil,TO_ROOM);

    act(AT_REPORT,'You ' + txt_ch + ' ' + headings[pexit.direction] + '.',false,ch,nil,nil,TO_CHAR);
    end;

  if (not ch.IS_OUTSIDE) then
   if (ch.IS_FLYING) then
    begin
    ch.sendBuffer('You cannot fly while indoors!'#13#10);
    ch.stopFlying;
    end;

  interpret(ch, 'look _AUTO');

  if (ch.tracking <> '') then
    interpret(ch, 'track');

  node := room_pos.chars.head;

  while (node <> nil) do
    begin
    node_next := node.next;
    vict := node.element;

    if (Assigned(vict)) and (vict.master = ch) then
      begin
      vict.in_command := true;

      act(AT_REPORT,'You follow $N '+headings[pexit.direction]+'.',false,vict,nil,ch,TO_CHAR);
      interpret(vict, headings[pexit.direction]);
      vict.emptyBuffer;

      vict.in_command := false;
      end;

    node := node_next;
    end;

  node := ch.room.chars.head;
  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.IS_NPC) then
      begin
      p := GNPC(vict).context.findSymbol('onGreet');

      if (p <> -1) then
        begin
        GNPC(vict).context.push(integer(ch));
        GNPC(vict).context.push(integer(vict));
        GNPC(vict).context.setEntryPoint(p);
        GNPC(vict).context.Execute;
        end;
      end;

    node := node.next;
    end;
    
  if (ch.room.flags.isBitSet(ROOM_NOFLOOR)) and (not ch.IS_FLYING) then
    begin
    pexit := ch.room.findExit(DIR_DOWN);
    
    if (pexit <> nil) then
      begin   
      ch.sendBuffer(#13#10'Suddenly you discover that the floor underneath you is missing!'#13#10);  
      act(AT_GREY, 'Unable to fly, $n plummets into the depths below.', false, ch, nil, nil, TO_ROOM);
      
      do_move(ch, pexit);
      end;
    end;

  do_move := true;
end;

function do_move(ch : GCharacter; direction : integer) : boolean; overload;
var
  pexit : GExit;
begin
  pexit := ch.room.findExit(direction);

  if (pexit = nil) and ((ch.room.vnum >= GPlayer(ch).r_lo) and (ch.room.vnum <= GPlayer(ch).r_hi)
        and (ch.getTrust() > LEVEL_GOD) and (GPlayer(ch).area_fname <> '') and (GPlayer(ch).area <> nil))
        and (IS_SET(GPlayer(ch).cfg_flags, CFG_AUTOCREATE)) then
    begin
    interpret(ch, 'rclone ' + headings[direction]);
    
    Result := true;
    end
  else
    Result := do_move(ch, pexit);
end;

procedure do_north(ch:GCharacter;param:string);
begin
  do_move(ch, DIR_NORTH);
end;

procedure do_east(ch:GCharacter;param:string);
begin
  do_move(ch, DIR_EAST);
end;

procedure do_south(ch:GCharacter;param:string);
begin
  do_move(ch, DIR_SOUTH);
end;

procedure do_west(ch:GCharacter;param:string);
begin
  do_move(ch, DIR_WEST);
end;

procedure do_down(ch:GCharacter;param:string);
begin
  do_move(ch, DIR_DOWN);
end;

procedure do_up(ch:GCharacter;param:string);
begin
  do_move(ch, DIR_UP);
end;

procedure do_sleep(ch:GCharacter;param:string);
begin
  if (IS_SET(ch.aff_flags, AFF_BASHED)) or (IS_SET(ch.aff_flags, AFF_STUNNED)) then
    act(AT_REPORT, 'You are immobilized and cannot move.',false,ch,nil,nil,TO_CHAR);
    
  if (ch.state in [STATE_IDLE,STATE_RESTING,STATE_MEDITATING]) then
    begin
    ch.stopFlying();
    
    act(AT_REPORT,'You lie down and fall sleep.',false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n lies down and falls asleep.',true,ch,nil,nil,TO_ROOM);
    
    ch.position := POS_LYING;
    ch.state := STATE_SLEEPING;
    end;
end;

procedure do_stand(ch:GCharacter;param:string);
begin
  if (ch.position in [POS_STANDING,POS_FLYING]) then
    begin
    act(AT_REPORT,'You are already standing.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;
  
  if (IS_SET(ch.aff_flags, AFF_BASHED)) or (IS_SET(ch.aff_flags, AFF_STUNNED)) then
    begin
    act(AT_REPORT, 'You are immobilized and cannot move.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;
    
  case ch.state of
       STATE_SLEEPING : begin
					  						ch.state := STATE_IDLE;
										  	ch.position := POS_STANDING;
					  						act(AT_REPORT,'You wake and stand up.',false,ch,nil,nil,TO_CHAR);
										  	act(AT_REPORT,'$n wakes and stands up.',true,ch,nil,nil,TO_ROOM);
                        end;
     STATE_MEDITATING : begin
												ch.state := STATE_IDLE;
												ch.position := POS_STANDING;

												act(AT_REPORT,'You stop meditating and stand up.',false,ch,nil,nil,TO_CHAR);
												act(AT_REPORT,'$n stops meditating and stands up.',true,ch,nil,nil,TO_ROOM);
                        end;
        STATE_RESTING : begin
												ch.state := STATE_IDLE;
												ch.position := POS_STANDING;

												act(AT_REPORT,'You stand up.',false,ch,nil,nil,TO_CHAR);
												act(AT_REPORT,'$n stands up.',true,ch,nil,nil,TO_ROOM);
                        end;
   end;
end;

procedure do_meditate(ch:GCharacter;param:string);
begin
  if (IS_SET(ch.aff_flags, AFF_BASHED)) or (IS_SET(ch.aff_flags, AFF_STUNNED)) then
    begin
    act(AT_REPORT, 'You are immobilized and cannot move.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  case ch.state of
       STATE_SLEEPING : act(AT_REPORT, 'You are asleep.',false,ch,nil,nil,TO_CHAR);
     STATE_MEDITATING : act(AT_REPORT, 'You are already meditating.', false, ch, nil, nil, TO_CHAR);
        STATE_RESTING : begin 
                        ch.state := STATE_MEDITATING;
						  					act(AT_REPORT,'You start meditating.',false,ch,nil,nil,TO_CHAR);
											  act(AT_REPORT,'$n starts meditating.',true,ch,nil,nil,TO_ROOM);
  					  					end;
		   		 STATE_IDLE : begin
		   									ch.state := STATE_MEDITATING;
			                  act(AT_REPORT,'You sit down cross-legged and begin meditating.',false,ch,nil,nil,TO_CHAR);
			                  act(AT_REPORT,'$n sits down cross-legged and begins meditating.',true,ch,nil,nil,TO_ROOM);
		   				  				end;
   end;
end;

procedure do_rest(ch:GCharacter;param:string);
begin
  if (IS_SET(ch.aff_flags, AFF_BASHED)) or (IS_SET(ch.aff_flags, AFF_STUNNED)) then
    begin
    act(AT_REPORT, 'You are immobilized and cannot move.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  case ch.state of
       STATE_SLEEPING : act(AT_REPORT, 'You are asleep.',false,ch,nil,nil,TO_CHAR);
        STATE_RESTING : act(AT_REPORT, 'You are already resting.', false, ch, nil, nil, TO_CHAR);
		 STATE_MEDITATING : begin
												ch.state := STATE_RESTING;
												act(AT_REPORT,'You stop meditating and go to rest.',false,ch,nil,nil,TO_CHAR);
												act(AT_REPORT,'$n stops meditating and rests.',true,ch,nil,nil,TO_ROOM);
			                  end;
			     STATE_IDLE : begin
												ch.position := POS_SITTING;
												ch.state := STATE_RESTING;
												
												act(AT_REPORT,'You sit down comfortably and rest.',false,ch,nil,nil,TO_CHAR);
												act(AT_REPORT,'$n sits down comfortably and rests.',true,ch,nil,nil,TO_ROOM);
			                  end;
   end;
end;

procedure do_wake(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Wake who?'#13#10);
    exit;
    end;

  vict := ch.room.findChar(ch, param);

  if (vict = nil) then
    ch.sendBuffer('They aren''t here.'#13#10)
  else
  if (vict = ch) then
    do_stand(ch, '')
  else
  if (vict.state <> STATE_SLEEPING) then
    act(AT_REPORT,'$N is not sleeping.',false,ch,nil,vict,TO_CHAR)
  else
    begin
    act(AT_REPORT,'You wake $N.',false,ch,nil,vict,TO_CHAR);
    act(AT_REPORT,'$n wakes $N.',false,ch,nil,vict,TO_ROOM);
    vict.position := POS_STANDING;
    vict.state := STATE_IDLE;
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

  do_move(ch, pexit);
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
    bugreport('do_open', 'cmd_move.inc', 'room_to (' + inttostr(ch.room.vnum) + ' -> ' + inttostr(pexit.vnum) + ') is null');
    exit;
    end;

  pexit := room_pos.findExit(dir_inv[dir]);

  if (pexit = nil) then
    begin
    bugreport('do_open', 'cmd_move.inc', 'reverse exit (' + inttostr(ch.room.vnum) + ') is null');
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
    bugreport('do_close', 'cmd_move.inc', 'room_to (' + inttostr(ch.room.vnum) + ' -> ' + inttostr(pexit.vnum) + ') is null');
    exit;
    end;

  pexit := room_pos.findExit(dir_inv[dir]);

  if (pexit = nil) then
    begin
    bugreport('do_close', 'cmd_move.inc', 'reverse exit (' + inttostr(ch.room.vnum) + ') is null');
    exit;
    end;

  SET_BIT(pexit.flags, EX_CLOSED);
end;
