{
	Summary:
		Character update & regeneration routines
		
	## $Id: update.pas,v 1.5 2004/03/08 23:30:07 hemko Exp $
}

unit update;

interface

uses
	chars,
	dtypes,
	area,
	constants,
	util,
	timers,
	skills;


procedure regenerate_chars();

procedure update_chars();
procedure update_tracks();
procedure update_teleports();
procedure update_time();

procedure gain_condition(ch : GCharacter; iCond, value : integer);

procedure battlegroundMessage();
procedure startBattleground();
procedure update_battleground();

procedure update_objects();

implementation

uses
	SysUtils,
	mudsystem,
	commands,
	fight,
	conns,
	player,
	Channels;


// Regenerate characters
procedure regenerate_chars();
var 
	hp_gain, mv_gain, mana_gain : integer;
	ch : GCharacter;
	iterator : GIterator;
begin
  iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    ch := GCharacter(iterator.next());

    hp_gain:=0; mv_gain:=0; mana_gain:=0;

    if (not ch.IS_NPC) then
    with ch do
      begin
      case state of
            STATE_SLEEPING: begin
                            hp_gain:=9;
                            mv_gain:=7;
                            mana_gain:=3;
                            end;
             STATE_RESTING: begin
                            hp_gain:=7;
                            mv_gain:=9;
                            mana_gain:=4;
                            end;
          STATE_MEDITATING: begin
                            hp_gain:=6;
                            mv_gain:=6;
                            mana_gain:=10;
                            end;
                STATE_IDLE: begin
                            hp_gain:=2;
                            mv_gain:=2;
                            mana_gain:=1;
                            end;
        	STATE_FIGHTING: begin
                            hp_gain:=0;
                            mv_gain:=1;
                            mana_gain:=0;
                            end;
      end;

      if IS_SET(ch.aff_flags,AFF_POISON) then
        begin
        hp_gain := hp_gain div 4;
        mv_gain := mv_gain div 3;
        mana_gain := mana_gain div 2;
        end;

      if (ch.room.flags.isBitSet(ROOM_MANAROOM)) then
        mana_gain := mana_gain*2;

      hp := UMin(hp + hp_gain, max_hp);
      mv := UMin(mv + mv_gain, max_mv);
      mana := UMin(mana + mana_gain, max_mana);
      end;
    end;
    
  iterator.Free();
end;

// Update the time
procedure update_time();
var 
	buf : string;
	iterator : GIterator;
	ch : GCharacter;
begin
  inc(time_info.hour);
  buf := '';

  case time_info.hour of
    1:begin
      time_info.sunlight := SUN_DARK;
      buf := 'The moon sets.';
      end;
    5:begin
      time_info.sunlight:=SUN_DAWN;
      buf := 'The day has begun.';
      end;
    6:begin
      time_info.sunlight:=SUN_RISE;
      buf := 'The sun rises in the east.';
      end;
   12:begin
      time_info.sunlight:=SUN_LIGHT;
      buf := 'It''s noon.';
      end;
   19:begin
      time_info.sunlight:=SUN_SET;
      buf := 'The sun slowly disappears in the west.';
      end;
   20:begin
      time_info.sunlight:=SUN_MOON;
      buf := 'The night has begun, the moon slowly rises.';
      end;
   24:begin
      time_info.hour:=0;
      inc(time_info.day);
      end;
  end;

  if (time_info.day>=30) then
    begin
    time_info.day:=1;
    inc(time_info.month);
    end;

  if (time_info.month>=17) then
    begin
    time_info.month:=1;

    { it wouldn't be Grendel without this :) - Grimlord }
    to_channel(nil, 'The sky lights up with colorful flashes, created by the firework masters.'#13#10, CHANNEL_ALL, AT_GREY);

    inc(time_info.year);
    end;

  if (length(buf) > 0) then
    begin
    iterator := char_list.iterator();
    
    while (iterator.hasNext()) do
    	begin
    	ch := GCharacter(iterator.next());
    	
    	if (ch.IS_NPC) then
    		continue;
    		
    	if (ch.IS_OUTSIDE) and (ch.IS_AWAKE) then
        act(AT_REPORT,buf,false,ch,nil,nil,TO_CHAR);    		
    	end;
    
    iterator.Free();
    end;
end;

// Improve mental state
procedure better_mental_state(ch : GCharacter; modifier : integer);
var
	c : integer;
begin
  c := URANGE(0, abs(modifier), 20);
  
  if (number_percent < ch.con) then
    inc(c);
  if (ch.mental_state < 0) then
    ch.mental_state := URANGE(-MAX_COND, ch.mental_state + c, 0)
  else
  if (ch.mental_state > 0) then
    ch.mental_state := URANGE(0, ch.mental_state-c, MAX_COND);
end;

// Worsen mental state
procedure worsen_mental_state(ch : GCharacter; modifier : integer);
var
	c : integer;
begin
  c := URANGE(0, abs(modifier), 20);
  
  if (number_percent < ch.con) then
    dec(c);
  if (c<1) then exit;
  if (ch.mental_state < 0) then
    ch.mental_state := URANGE(-MAX_COND, ch.mental_state-c, MAX_COND)
  else
  if (ch.mental_state > 0) then
    ch.mental_state := URANGE(-MAX_COND, ch.mental_state+c, MAX_COND)
  else
    dec(ch.mental_state,c);
end;

procedure gain_condition(ch : GCharacter; iCond, value : integer);
var
	condition, retcode : integer;
begin
  if (value = 0) or (ch.IS_NPC) or (ch.IS_IMMORT) then
    exit;

  condition := GPlayer(ch).condition[iCond];
  GPlayer(ch).condition[iCond]:=URANGE(0, condition+value, MAX_COND);

  retcode := RESULT_NONE;

  if (GPlayer(ch).condition[iCond]=0) then
    case iCond of
       COND_FULL:begin
                 act(AT_REPORT,'You are STARVING!',false,ch,nil,nil,TO_CHAR);
                 act(AT_REPORT,'$n is starving and looks awfully weak!',false,ch,nil,nil,TO_ROOM);
                 worsen_mental_state(ch,1);

                 retcode:=damage(ch,ch,1,TYPE_SILENT);
                 end;
     COND_THIRST:begin
                 act(AT_REPORT,'You are DYING of THIRST!',false,ch,nil,nil,TO_CHAR);
                 act(AT_REPORT,'$n is dying of thirst!',false,ch,nil,nil,TO_ROOM);
                 worsen_mental_state(ch,2);
                 retcode:=damage(ch,ch,2,TYPE_SILENT);
                 end;
      COND_DRUNK:begin
                 if condition<>0 then
                   act(AT_REPORT,'You are sober again.',false,ch,nil,nil,TO_CHAR);
                 retcode:=RESULT_NONE;
                 end;
       COND_HIGH:begin
                 if condition<>0 then
                   act(AT_REPORT,'Your mind stops floating and resumes its normal course.',false,ch,nil,nil,TO_CHAR);
                 retcode:=RESULT_NONE;
                 end;
   COND_CAFFEINE:begin
                 if condition<>0 then
                   act(AT_REPORT,'Your vains are clear of caffeine... you are less tense.',false,ch,nil,nil,TO_CHAR);
                 retcode:=RESULT_NONE;
                 end;
      else begin
           bugreport('gain_condition', 'update.pas', 'invalid condition: '+inttostr(icond));
           retcode:=RESULT_NONE;
           end;
    end;

  if (retcode<>RESULT_NONE) then               { don't want to continue when ch is dead }
    exit;

  if (GPlayer(ch).condition[iCond]=3) then
    case iCond of
       COND_FULL:begin
                 act(AT_REPORT,'You are getting really hungry.',false,ch,nil,nil,TO_CHAR);
                 act(AT_REPORT,'You can hear $n''s stomach growling, $e must be hungry.',false,ch,nil,nil,TO_ROOM);
                 if random(2)=0 then
                   worsen_mental_state(ch,1);
                 end;
     COND_THIRST:begin
                 act(AT_REPORT,'You are getting really thirsty.',false,ch,nil,nil,TO_CHAR);
                 act(AT_REPORT,'$n gasps and looks thirsty.',false,ch,nil,nil,TO_ROOM);
                 worsen_mental_state(ch,1);
                 end;
      COND_DRUNK:if condition<>0 then
                   act(AT_REPORT,'The world is coming back into perspective.',false,ch,nil,nil,TO_CHAR);
       COND_HIGH:if condition<>0 then
                   act(AT_REPORT,'You are slowly returning from outer space...',false,ch,nil,nil,TO_CHAR);
    end;

  if (GPlayer(ch).condition[iCond]=8) then
    case iCond of
       COND_FULL:act(AT_REPORT,'You are hungry.',false,ch,nil,nil,TO_CHAR);
     COND_THIRST:act(AT_REPORT,'You are thirsty.',false,ch,nil,nil,TO_CHAR);
      COND_DRUNK:if condition<>0 then
                   act(AT_REPORT,'You feel a bit less light headed.',false,ch,nil,nil,TO_CHAR);
       COND_HIGH:if condition<>0 then
                   act(AT_REPORT,'Slowly but surely, your high is starting to wear off.',false,ch,nil,nil,TO_CHAR);
    end;

  if (GPlayer(ch).condition[iCond]=16) then
    case iCond of
       COND_FULL:act(AT_REPORT,'You could use a bite of something.',false,ch,nil,nil,TO_CHAR);
     COND_THIRST:act(AT_REPORT,'A drink would be nice.',false,ch,nil,nil,TO_CHAR);
      COND_DRUNK:act(AT_REPORT,'You feel as if little pixies feast inside your skull.',false,ch,nil,nil,TO_CHAR);
    end;
end;

// Update characters
procedure update_chars();
var 
	p : integer;
	ch : GCharacter;
	e : GExit;
	r : GRoom;
	iterator : GIterator;
begin
  iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    ch := GCharacter(iterator.next());

    
    if (ch.IS_NPC) then
      begin
      { switched mobs don't wander }
      if (ch.snooped_by <> nil) and (GPlayer(ch.snooped_by).switching = ch) then
      	continue;
      
      if (not IS_SET(GNPC(ch).act_flags, ACT_SENTINEL)) and (ch.state = STATE_IDLE) then
        begin
        p := random(6)+1;

        e := ch.room.findExit(p);

        if (e <> nil) then
          begin
          r := findRoom(e.vnum);

          if (r <> nil) and not (IS_SET(GNPC(ch).act_flags, ACT_STAY_AREA) and (r.area <> ch.room.area)) then
            interpret(ch, headings[p]);
          end;
        end;

      GNPC(ch).context.runSymbol('onTick', [integer(ch)]);
      end
    else
    if (not ch.IS_NPC) then
      begin
      if (GPlayer(ch).condition[COND_DRUNK] > 8) then
        worsen_mental_state(ch,GPlayer(ch).condition[COND_DRUNK] div 8);

      if (GPlayer(ch).condition[COND_FULL] > 1) then
        case ch.position of
              STATE_SLEEPING: better_mental_state(ch, 4);
               STATE_RESTING: better_mental_state(ch, 3);
                  STATE_IDLE: better_mental_state(ch, 2);
          	  STATE_FIGHTING: if (random(4) = 0) then
                                better_mental_state(ch, 1);
        end;

      if (GPlayer(ch).condition[COND_THIRST] > 1) then
        case ch.position of
              STATE_SLEEPING: better_mental_state(ch, 5);
               STATE_RESTING: better_mental_state(ch, 3);
                  STATE_IDLE: better_mental_state(ch, 2);
              STATE_FIGHTING: if (random(4) = 0) then
                                better_mental_state(ch, 1);
        end;
        
      gain_condition(ch,COND_DRUNK, -1);
      gain_condition(ch,COND_HIGH, -1);
      gain_condition(ch,COND_FULL, -1);

      case ch.room.sector of
            SECT_DESERT:gain_condition(ch,COND_THIRST,-2);
        SECT_UNDERWATER,
        SECT_OCEANFLOOR:if random(2)=0 then
                          gain_condition(ch,COND_THIRST,-1);
        else gain_condition(ch,COND_THIRST,-1);
      end;
      if (ch.mental_state>=30) then
        case (ch.mental_state+5) div 10 of
           3:begin
             act(AT_REPORT,'You feel chilly and not well.',false,ch,nil,nil,TO_CHAR);
             act(AT_REPORT,'$n doesn''t look $s normal self.',false,ch,nil,nil,TO_ROOM);
             end;
           4:begin
             act(AT_REPORT,'You don''t feel good at all.',false,ch,nil,nil,TO_CHAR);
             act(AT_REPORT,'$n doesn''t look too good.',false,ch,nil,nil,TO_ROOM);
             end;
           5:begin
             act(AT_REPORT,'You need help immediately!',false,ch,nil,nil,TO_CHAR);
             act(AT_REPORT,'$n looks like $e could use your help.',false,ch,nil,nil,TO_ROOM);
             end;
           6:begin
             act(AT_REPORT,'You are in BAD shape, get a healer!',false,ch,nil,nil,TO_CHAR);
             act(AT_REPORT,'$n looks awful and could use assistance.',false,ch,nil,nil,TO_ROOM);
             end;
           7:begin
             act(AT_REPORT,'You lose your grip on reality... what is happening?',false,ch,nil,nil,TO_CHAR);
             act(AT_REPORT,'$n seems unaware of the world and $s surroundings.',false,ch,nil,nil,TO_ROOM);
             end;
           8:begin
             act(AT_REPORT,'Understanding and knowledge flow through your mind.',false,ch,nil,nil,TO_CHAR);
             act(AT_REPORT,'$n runs about, babbling like an escaped madman!',false,ch,nil,nil,TO_ROOM);
             end;
           9:begin
             act(AT_REPORT,'You feel like... Thor.',false,ch,nil,nil,TO_CHAR);
             act(AT_REPORT,'$n stands ranting about $s immortality.',false,ch,nil,nil,TO_ROOM);
             end;
          10:begin
             act(AT_REPORT,'Your brain is a cloud of fog... you are dying.',false,ch,nil,nil,TO_CHAR);
             act(AT_REPORT,'$n kneels down, muttering and chanting in tongues...',false,ch,nil,nil,TO_ROOM);
             end;
        end;
      end;
    end; 
    
  iterator.Free();
end;

procedure teleportChar(ch : GCharacter;room:GRoom);
begin
  if (room.flags.isBitSet(ROOM_PRIVATE)) then
    exit;

  act(AT_REPORT,'$n disappears suddenly!',false,ch,nil,nil,TO_ROOM);
  act(AT_REPORT,'You feel dizzy as you are transferred to another place...',false,ch,nil,nil,TO_CHAR);

  ch.fromRoom;
  ch.toRoom(room);

  act(AT_REPORT,'$n appears in a puff of smoke.',false,ch,nil,nil,TO_ROOM);
  interpret(ch,'look _AUTO');
end;

// Update tracks
procedure update_tracks();
var
	iterator_room : GIterator;
	node_track, node_tracknext : GListNode;
	room : GRoom;
	track : GTrack;
begin
	iterator_room := room_list.iterator();
	
	while (iterator_room.hasNext()) do
		begin
		room := GRoom(iterator_room.next());
		node_track := room.tracks.head;

		while (node_track <> nil) do
			begin
			node_tracknext := node_track.next;

			track := GTrack(node_track.element);

			dec(track.life);

			if (track.life = 0) then
				begin
				room.tracks.remove(node_track);
				track.Free;
				end;

			node_track := node_tracknext;
			end;
		end;
		
	iterator_room.Free();
end;

// Update teleports
procedure update_teleports();
var 
	tele : GTeleport;
	room, dest : GRoom;
	iterator : GIterator;
begin
  iterator := teleport_list.iterator();

  while (iterator.hasNext()) do
    begin
    tele := GTeleport(iterator.next());

    dec(tele.timer);

    if (tele.timer = 0) then
      begin
      room := tele.t_room;
      dest := findRoom(room.televnum);

      while (room.chars.size() > 0) do
        teleportChar(GCharacter(room.chars.head.element), dest);

      teleport_list.remove(tele.node);
      end;
    end;
    
  iterator.Free();
end;

{ procedure update_timers;
var
   timer : GTimer;
   node, node_next : GListNode;
begin
  node := timer_list.head;
  while (node <> nil) do
    begin
    timer := node.element;
    node_next := node.next;

    dec(timer.rounds);

    if (timer.rounds = 0) then
      begin
      timers.remove(node);

      if assigned(timer.spec_func) then
        timer.spec_func(timer.ch,timer.victim,timer.sn);

      timer.Free;
      end;

    node := node_next;
    end;
end; }

procedure battlegroundMessage();
begin
  if (bg_info.prize<>nil) then
    to_channel(nil,pchar('[$B$7Battleground starting in '+inttostr(bg_info.count)+' seconds$A$7]'#13#10+
               'Allowed levels: '+inttostr(bg_info.lo_range)+
               '-'+inttostr(bg_info.hi_range)+'  Prize: '+ GObject(bg_info.prize).short),CHANNEL_ALL,AT_REPORT)
  else
    to_channel(nil,pchar('[$B$7Battleground starting in '+inttostr(bg_info.count)+' seconds$A$7]'#13#10+
               'Allowed levels: '+inttostr(bg_info.lo_range)+
               '-'+inttostr(bg_info.hi_range)),CHANNEL_ALL,AT_REPORT)
end;

procedure startBattleground();
var 
	iterator : GIterator;
	ch : GCharacter;
	s,vnum:integer;
begin
  to_channel(nil,pchar('[$B$7Battleground starting NOW!$A$7]'),CHANNEL_ALL,AT_REPORT);

	iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    ch := GCharacter(iterator.next());
    
    if (ch.IS_NPC) then
    	continue;

    if (ch.state = CON_PLAYING) and (GPlayer(ch).bg_status = BG_JOIN)
     and (ch.level >= bg_info.lo_range) and (ch.level <= bg_info.hi_range) then
      begin
      act(AT_REPORT,'You are transfered into the arena.',false,ch,nil,nil,TO_CHAR);
      act(AT_GREEN,'Niet mokken, lekker knokken!',false,ch,nil,nil,TO_CHAR);

      s := random(system_info.arena_end - system_info.arena_start + 1) + system_info.arena_start;
      vnum := URange(system_info.arena_start, s, system_info.arena_end);

      GPlayer(ch).bg_room := ch.room;

      ch.fromRoom();
      ch.toRoom(findRoom(vnum));

      GPlayer(ch).bg_status := BG_PARTICIPATE;
      interpret(ch,'look');
      end;
    end;
    
  iterator.Free();
end;

procedure update_battleground();
var 
	s : integer;
	ch, last : GCharacter;
	iterator : GIterator;
begin
  { battleground is running, check to see if we have a winner }
  if (bg_info.count = 0) then
    begin
    last := nil;
    s := 0;

		iterator := char_list.iterator();
		
		while (iterator.hasNext()) do
      begin
      ch := GCharacter(iterator.next());
      
      if (ch.IS_NPC) then
      	continue;

      if (ch.state = CON_PLAYING) and (GPlayer(ch).bg_status = BG_PARTICIPATE) then
        begin
        inc(s);
        last := ch;
        end;
      end;

    if (s = 0) then
      begin
      to_channel(nil,'[$B$7Battleground stopped without a winner.$A$7]',CHANNEL_ALL,AT_REPORT);
      bg_info.count := -1;
      end
    else
    if (s = 1) then
      begin
      to_channel(nil,'[$B$3'+last.name+'$B$7 has won the battleground!$A$7]',CHANNEL_ALL,AT_REPORT);
      act(AT_REPORT,'Congratulations! You have won the battleground!',false,last,nil,nil,TO_CHAR);

      inc(GPlayer(last).bg_points,3);

      last.fromRoom();
      last.toRoom(GPlayer(last).bg_room);

      if (bg_info.prize <> nil) then
        begin
        act(AT_REPORT,'You have won $p.', false, last, bg_info.prize, nil, TO_CHAR);

        GObject(bg_info.prize).toChar(last);
        end;

      interpret(last, 'look');
      GPlayer(last).bg_status := BG_NOJOIN;
      last.hp := last.max_hp;

      bg_info.winner := last;
      bg_info.count := -1;
      bg_info.prize := nil;
      end;
    end;
end;

// Update objects
procedure update_objects();
var 
  obj : GObject;
  rch : GCharacter;
  msg : string;
  at_temp : integer;
  iterator : GIterator;
begin
  iterator := objectList.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (IS_SET(obj.flags, OBJ_NODECAY)) then
      continue;

    if (obj.timer <= 0) then
      continue;

    dec(obj.timer);
    if (obj.timer > 0) then
      continue;

    case obj.item_type of
      ITEM_CORPSE : begin
                    msg := '$p decays into dust and blows away.';
                    at_temp := AT_CORPSE;
                    end;
       ITEM_BLOOD : begin
                    msg := '$p dries up.';
                    at_temp := AT_RED;
                    end;
        ITEM_FOOD : begin
                    msg := '$p slowly rots away, leaving a foul stench.';
                    at_temp := AT_REPORT;
                    end;
      else
         begin
         msg := '$p vanishes in the wink of an eye.';
         at_temp := AT_REPORT;
         end;
    end;

    if (obj.carried_by <> nil) then
      act(at_temp, msg, false, obj.carried_by, obj, nil, TO_CHAR)
    else
    if (obj.room <> nil) then
      begin
      if (obj.room.chars.head <> nil) then
        rch := GCharacter(obj.room.chars.head.element)
      else
        rch := nil;

      if (rch <> nil) and (not IS_SET(obj.flags, OBJ_HIDDEN)) then
        begin
        act(at_temp, msg, false, rch, obj, nil, TO_ROOM);
        act(at_temp, msg, false, rch, obj, nil, TO_CHAR);
        end;
      end;

    obj.Free();
  end;
end;

end.
