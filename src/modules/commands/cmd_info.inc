// $Id: cmd_info.inc,v 1.10 2004/05/18 12:08:12 ***REMOVED*** Exp $

function info_object(obj : GObject) : string;
var 
	r : string;
begin
	r := '$B$7';

	if (IS_SET(obj.flags, OBJ_GLOW)) then
		r := r + '(Glowing) ';
		
	if (IS_SET(obj.flags, OBJ_HUM)) then
		r := r + '(Humming) ';

	if (obj.item_type = ITEM_BOW) and (obj.value[2] > 0) then
		r := r + '(Loaded) ';

	Result := r;
end;

procedure do_time(ch:GCharacter;param:string);
begin
  act(AT_REPORT,'It is the ' + trail_number(time_info.hour) +
                ' hour of the ' + trail_number(time_info.day) +
                ' day of the ' + trail_number(time_info.month) +
                ' month, in the year ' + inttostr(time_info.year) + '.', false, ch, nil, nil ,TO_CHAR);
end;

procedure do_weather(ch:GCharacter;param:string);
var sun:string;
begin
  case time_info.sunlight of
    SUN_MOON:sun:='You can see the moon';
    SUN_DARK:sun:='It''s dark';
    SUN_DAWN:sun:='It''s dawn';
    SUN_RISE:sun:='The sun is rising';
    SUN_LIGHT:sun:='The sun is shining';
    SUN_SET:sun:='The sun is setting';
    else
      sun := 'You can''t see the sun';
  end;

  act(AT_REPORT,sun+', it is '+sky_types[ch.room.area.weather.sky]+
      ' and it''s around '+inttostr(ch.room.area.weather.temp)+' C.',false,ch,nil,nil,TO_CHAR);
end;

procedure do_peek(ch : GCharacter; param : string);
var
  cnt : integer;
  iterator : GIterator;
  vict : GCharacter;
  obj : GObject;
begin
  if (ch.LEARNED(gsn_peek) = 0) then
  begin
    ch.sendBuffer('You don''t know how to peek!'#13#10);
    exit;
  end;

  if IS_SET(ch.aff_flags,AFF_BLIND) then
  begin
    ch.sendBuffer('You can''t see a thing!'#13#10);
    exit;
  end;
  
  vict := ch.room.findChar(ch, param);

  if (vict = nil) then
    begin
    act(AT_REPORT,'You do not see that here.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;
  
  if (number_percent <= ch.LEARNED(gsn_peek)) then
    begin
    act(AT_REPORT, 'You peek at the inventory and see:'#13#10, false, ch, nil, nil, TO_CHAR);

    cnt := 0;
    iterator := vict.inventory.iterator();
    while (iterator.hasNext()) do
      begin
      obj := GObject(iterator.next());

      if (obj.count > 1) then
        act(AT_REPORT, '  $p [' + inttostr(obj.count) + '] ' + info_object(obj), false, ch, obj, nil, TO_CHAR)
      else
        act(AT_REPORT, '  $p ' + info_object(obj), false, ch, obj, nil, TO_CHAR);
      inc(cnt);
      end;
    iterator.Free();

    if (cnt = 0) then
      ch.sendBuffer('  nothing.'#13#10);
    end
  else
    act(AT_REPORT, 'You failed to see anything.', false, ch, nil, nil, TO_CHAR);
end;

{ Xenon 22/Feb/2001: seperated peek from look (it's a command on its own now) }
procedure do_look(ch : GCharacter; param:string);
var 
  vict:GCharacter;
  obj,obj_in: GObject;
  s_extra : GExtraDescription;
  pexit:GExit;
  w1,w2:byte;
  inside:string[20];
  buf1 : string;
  cnt:integer;
  brief:boolean;
  act_str:string;
  where_str : string;
  bodypart : GBodyPart;
  iterator, inner_iterator : GIterator;
begin
  if (IS_SET(ch.aff_flags,AFF_BLIND)) then
    begin
    ch.sendBuffer('You can''t see a thing!'#13#10);
    exit;
    end;

  if (not ch.CAN_SEE(ch.room)) then
    begin
    ch.sendBuffer('It''s pitch black, you can''t see a thing!'#13#10);
    exit;
    end;

  brief:=false;

  if (comparestr('_AUTO',param) = 0) then
   if (not ch.IS_NPC) and IS_SET(GPlayer(ch).cfg_flags, CFG_BRIEF) then
    brief:=true;

  if (length(param) > 0) and (comparestr('_AUTO',param)<>0) then
    begin
    { Check if it is a user }
    vict := ch.room.findChar(ch, param);
    s_extra := ch.room.findDescription(param);
    obj := ch.room.findObject(param);
    if (obj <> nil) then
      where_str := 'on the ground'
    else
    begin
      obj := ch.findInventory(param);
      if (obj <> nil) then
        where_str := 'in your inventory'
      else
      begin
        obj := ch.findEquipment(param);
        if (obj <> nil) then
          where_str := 'that you''re wearing';
      end
    end;

    if (vict <> nil) then
      begin
      if (not vict.IS_NPC) then
        act(AT_REPORT,vict.name+'$7 is known as $B$6' + GPlayer(vict).rank+'$A$7 amongst'+
        ' $S $B$4'+vict.race.name+'$A$7 ancestors.'#13#10,false,ch,nil,vict,TO_CHAR)
      else 
        if vict.short <> '' then
         act(AT_REPORT, vict.short + #13#10, false, ch, nil, vict, TO_CHAR);

      w1 := UMax(round((vict.hp / vict.max_hp)*5),0);
      w2 := UMax(round((vict.mv / vict.max_mv)*5),0);

      act(AT_REPORT,vict.name+' looks '+hp_perc[w1]+' and '+mv_perc[w2]+'.',false,ch,nil,vict,TO_CHAR);

      ch.sendBuffer(#13#10 + vict.name + ' is using: '#13#10#13#10);

      cnt := 0;
      iterator := vict.equipment.iterator();

      while (iterator.hasNext()) do
        begin
        obj := GObject(iterator.next());

        bodypart := GBodyPart(vict.race.bodyparts[obj.worn]);

        if (bodypart <> nil) then
          begin
          act(AT_REPORT, pad_string('(' + bodypart.description + ')', 20) + '$p ' + info_object(obj), false, ch, obj, nil, TO_CHAR);
          inc(cnt);

		  if (obj.contents.size() > 0) then
			begin
			inner_iterator := obj.contents.iterator();

			while (inner_iterator.hasNext()) do
				begin
				obj_in := GObject(inner_iterator.next());

				if (obj.item_type = ITEM_BELT) then    		
					act(AT_REPORT, pad_string('  [thrust through]', 20) + '$p ' + info_object(obj_in), false, ch, obj_in, nil, TO_CHAR)
				else
					act(AT_REPORT, pad_string('  [stored in]', 20) + '$p ' + info_object(obj_in), false, ch, obj_in, nil, TO_CHAR)
				end;

			inner_iterator.Free();
			end;
          end;
        end;
      
      iterator.Free();

      if (cnt = 0) then
        ch.sendBuffer('  nothing.'#13#10);

      if (not ch.IS_NPC) and (IS_SET(GPlayer(ch).cfg_flags, CFG_AUTOPEEK)) then
      begin
        ch.sendBuffer(#13#10);
        interpret(ch, 'peek ' + vict.name);
      end;
      end
    else
    if obj<>nil then
      begin
      act(AT_REPORT,'You look at $p ' + where_str + '.'#13#10,false,ch,obj,nil,TO_CHAR);

      if (obj.item_type=ITEM_CONTAINER) or (obj.item_type=ITEM_CORPSE) then
        begin
        if (obj.contents.size() > 0) then
          begin
          act(AT_REPORT,'$p contains:'#13#10,false,ch,obj,nil,TO_CHAR);

          iterator := obj.contents.iterator();
          
          while (iterator.hasNext()) do
            begin
            obj_in := GObject(iterator.next());

            if (obj_in.count > 1) then
              act(AT_REPORT,'   $p [$4'+inttostr(obj_in.count)+'$7x]',false,ch,obj_in,nil,TO_CHAR)
            else
              act(AT_REPORT,'   $p',false,ch,obj_in,nil,TO_CHAR);
            end;
            
          iterator.Free();
          end
        else
          act(AT_REPORT,'$p is empty.',false,ch,obj,nil,TO_CHAR);
        end
      else
        act(AT_REPORT,'There is nothing special about $p.',false,ch,obj,nil,TO_CHAR);
      end
    else
    if (s_extra <> nil) then
      ch.sendBuffer(s_extra.description)
    else
      act(AT_REPORT,'You look around, but find nothing.',false,ch,nil,nil,TO_CHAR);
    end
  else
  with ch.room do
    begin
    if (ch.IS_OUTSIDE) then
      inside := cap(sky_types[ch.room.area.weather.sky])
    else
      inside := 'Indoors';

    act(AT_DGREEN,name + ' [$B$5'+inside+'$A$2]$7',false,ch,nil,nil,TO_CHAR);

    if (not brief) then
      ch.sendBuffer(description);

    buf1 := '';
    iterator := exits.iterator();

    while (iterator.hasNext()) do
      begin
      pexit := GExit(iterator.next());

      if (IS_SET(pexit.flags, EX_SECRET) and IS_SET(pexit.flags, EX_CLOSED)) then
        continue;

      if (length(buf1) > 0) then
        buf1 := buf1 + ', ';

      if (IS_SET(pexit.flags, EX_CLOSED)) then
        buf1 := buf1 + '[' + headings[pexit.direction] + ']'
      else
      if (IS_SET(pexit.flags, EX_SWIM)) then
        buf1 := buf1 + '/' + headings[pexit.direction] + '\'
      else
      if (IS_SET(pexit.flags, EX_FLY)) then
        buf1 := buf1 + '<' + headings[pexit.direction] + '>'
      else
      if (IS_SET(pexit.flags, EX_UNDERWATER)) then
        buf1 := buf1 + '{' + headings[pexit.direction] + '}'
      else
        buf1 := buf1 + headings[pexit.direction];
      end;
      
    iterator.Free();

    if (length(buf1) = 0) then
      buf1 := 'none';

    act(AT_YELLOW, '[Exits: ' + buf1 + ']',false,ch,nil,nil,TO_CHAR);

    iterator := objects.iterator();

    while (iterator.hasNext()) do
      begin
      obj := GObject(iterator.next());

      if not IS_SET(obj.flags,OBJ_HIDDEN) then
        begin
        act_str := obj.long + '.';
        
        if (obj.count>1) then
          act_str:=act_str+' [$4'+inttostr(obj.count)+'$7x]';

        act(AT_OBJ,act_str,false,ch,nil,nil,TO_CHAR);
        end;
      end;
      
    iterator.Free();

    iterator := chars.iterator();
    
    while (iterator.hasNext()) do
      begin
      vict := GCharacter(iterator.next());

      if (vict <> ch) and (ch.CAN_SEE(vict)) then
        begin
        if (IS_SET(vict.aff_flags, AFF_BASHED)) then
          act_str := '$N is bashed to the ground.'
        else
        if (hasTimer(vict, 'cast') <> nil) then
          act_str := '$N is here, casting a spell.'
        else
        if (hasTimer(vict, 'searching') <> nil) then
          act_str := '$N is here, searching the room.'
        else
        if (vict.state = STATE_FIGHTING) then
          act_str := '$N is here, fighting ' + playername(vict.fighting, ch) + '!'
        else
        if (vict.state = STATE_SLEEPING) then
          act_str := '$N is sleeping here.'
        else
        if (vict.state = STATE_MEDITATING) then
          act_str := '$N is meditating here.'
        else
        if (vict.state = STATE_RESTING) then
          act_str := '$N is resting here.'
        else
        if (vict.state = STATE_IDLE) then
          begin
          if (vict.IS_NPC) then
            act_str := vict.long + '.'
          else
            act_str := '$N is here.';
          end;
          
        if (vict.IS_FLYING) then
          act_str := act_str + ' (Flying)';

        if (vict.IS_INVIS) then
          act_str := act_str + ' (Invis)';

        if (not vict.IS_NPC) and (IS_SET(GPlayer(vict).flags, PLR_LINKLESS)) then
          act_str := act_str + ' (Linkless)';

        if (ch.IS_IMMORT) and (not vict.IS_NPC) and (IS_SET(GPlayer(vict).flags, PLR_LOADED)) then
          act_str := act_str + ' (Loaded)';

        if (not vict.IS_NPC) and (vict.IS_WIZINVIS) then
          act_str := act_str + ' (WizInvis: ' + inttostr(GPlayer(vict).wiz_level) + ')';

        if (vict.IS_NPC) then
          act(AT_NPC,act_str,true,ch,nil,vict,TO_CHAR)
        else
          act(AT_PC,act_str,true,ch,nil,vict,TO_CHAR);
        end;
      end;
      
    iterator.Free();    
    end;

  ch.sendBuffer(ch.ansiColor(7));
end;

// 10/aug/2001 - scan exits and give roomnames - Nemesis
procedure do_exits(ch : GCharacter; param : string);
var h, counter : integer;
    pexit : GExit;
    room : GRoom;
    buf, rmname : string;
begin
  counter := 0;
  buf := ch.ansiColor(14) + 'Noticeable exits:' + #13#10;

  for h := DIR_NORTH to DIR_UP do
    begin
    pexit := ch.room.findExit(h);

    if (pexit <> nil) and (not IS_SET(pexit.flags, EX_SECRET)) then
      begin
      room := findRoom(pexit.vnum);
 
      if (room <> nil) then
        begin
        inc(counter);

        if IS_SET(pexit.flags, EX_CLOSED) then
          rmname := 'Closed'
        else
          rmname := room.name;

        buf := buf + ch.ansiColor(14) + pad_string(cap(headings[h]), 5) + ' - ' + rmname + #13#10;
        end;
      end;
    end;

  if (counter = 0) then
    buf := buf + ch.ansiColor(14) + 'None' + #13#10;

  ch.sendBuffer(buf);
end;

procedure do_inventory(ch:GCharacter;param:string);
var
  obj : GObject;
  iterator : GIterator;
  counter : integer;
begin
  counter := 0;

  act(AT_REPORT,'You are carrying: ',false,ch,nil,nil,TO_CHAR);
  
  if (ch.gold > 0) then
    act(AT_REPORT, '  $3' + inttostr(ch.gold) + '$7 coin(s).', false, ch, nil, nil, TO_CHAR);

  iterator := ch.inventory.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (obj.count > 1) then
      act(AT_REPORT, '  $p [' + inttostr(obj.count) + '] ' + info_object(obj), false, ch, obj, nil, TO_CHAR)
    else
      act(AT_REPORT, '  $p ' + info_object(obj), false, ch, obj, nil, TO_CHAR);

    inc(counter);
    end;
    
  iterator.Free();

  if (counter = 0) and (ch.gold = 0) then
    begin
    ch.sendBuffer('      nothing.'#13#10);
    exit;
    end;
end;

procedure do_equipment(ch:GCharacter;param:string);
var
  iterator, inner_iterator : GIterator;
  bodypart : GBodyPart;
  obj, obj_in : GObject;
  cnt : integer;
begin
  cnt := 0;
  ch.sendBuffer('You are using:'#13#10#13#10);

  iterator := ch.equipment.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    bodypart := GBodyPart(ch.race.bodyparts[obj.worn]);

    if (bodypart <> nil) then
      begin
      act(AT_REPORT, pad_string('(' + bodypart.description + ')', 20) + '$p ' + info_object(obj), false, ch, obj, nil, TO_CHAR);
      
      if (obj.contents.size() > 0) then
      	begin
      	inner_iterator := obj.contents.iterator();
      	
      	while (inner_iterator.hasNext()) do
      		begin
      		obj_in := GObject(inner_iterator.next());
      		
      		if (obj.item_type = ITEM_BELT) then    		
      			act(AT_REPORT, pad_string('  [thrust through]', 20) + '$p ' + info_object(obj_in), false, ch, obj_in, nil, TO_CHAR)
      		else
      			act(AT_REPORT, pad_string('  [stored in]', 20) + '$p ' + info_object(obj_in), false, ch, obj_in, nil, TO_CHAR)
      		end;
      	
      	inner_iterator.Free();
      	end;
      	
      inc(cnt);
      end;
    end;

  if (cnt = 0) then
    ch.sendBuffer('  nothing.'#13#10);

  ch.sendBuffer(ch.ansiColor(7));
end;

procedure do_score(ch : GCharacter; param : string);
var 
	buf1 : string;
	i, j, minh, maxh : integer;
begin
	buf1 := ' $8[$4*$8]$3 ' + add_chars(70, '---- Your score ', '-') + ' $8[$4*$8]';
	act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);

	if (not ch.IS_NPC) and (not ch.IS_IMMORT) then
		begin
		act(AT_REPORT,#13#10'   $B$4'+ch.name+'$A$7, thou art known as $B$6' + GPlayer(ch).rank+'$A$7 amongst'+
		' thy $B$4'+ch.race.name+'$A$7 ancestors.'#13#10,false,ch,nil,nil,TO_CHAR);
		act(AT_REPORT,'   Thou hast gained $B$3'+inttostr(GPlayer(ch).xptot)+'$A$7 experience points'+
		' and need $B$3'+inttostr(GPlayer(ch).xptogo)+'$A$7 to level.',false,ch,nil,nil,TO_CHAR);
		end
	else
	if (ch.IS_IMMORT) then
		act(AT_REPORT,#13#10'   $B$4'+ch.name+'$A$7, thou art ranked as a $B$6'+IMM_Types[ch.level]+'$A$7 amongst thy fellow immortals.'#13#10,false,ch,nil,nil,TO_CHAR);

	if (ch.sex = 1) then
		begin
		minh := (ch.race.avgheight_female * (100 - ch.race.avgheight_adjust)) div 100;
		maxh := (ch.race.avgheight_female * (100 + ch.race.avgheight_adjust)) div 100;
		end
	else
		begin
		minh := (ch.race.avgheight_male * (100 - ch.race.avgheight_adjust)) div 100;
		maxh := (ch.race.avgheight_male * (100 + ch.race.avgheight_adjust)) div 100;
		end;

	j := Max(1, maxh - minh);
	i := Max(0, ((ch.height - minh) * 100) div j);
	
	if (i >= 0) and (i < 20) then
		act(AT_REPORT, '   You are considered small by your people.', false, ch, nil, nil, TO_CHAR)
	else
	if (i >= 20) and (i < 40) then
		act(AT_REPORT, '   You are considered relatively small by your people.', false, ch, nil, nil, TO_CHAR)
	else
	if (i >= 40) and (i < 60) then
		act(AT_REPORT, '   You are considered of average length by your people.', false, ch, nil, nil, TO_CHAR)
	else
	if (i >= 60) and (i < 80) then
		act(AT_REPORT, '   You are considered relatively tall by your people.', false, ch, nil, nil, TO_CHAR)
	else
	if (i >= 80) then
		act(AT_REPORT, '   You are considered tall by your people.', false, ch, nil, nil, TO_CHAR);

	if (not ch.IS_NPC) then
		act(AT_REPORT,'   Thou art $B$3'+inttostr(GPlayer(ch).getAge)+'$A$7 years of age ('+inttostr(GPlayer(ch).getPlayed div 60)+' hours).'#13#10,false,ch,nil,nil,TO_CHAR);

	act(AT_REPORT,'   Health:   $B$3'+pad_integer(ch.hp,5)+'$A$7/$B$3'+pad_integer(ch.max_hp,5)+
		'$A$7     Attack Power Bonus: $B$3'+pad_integer(ch.apb,4)+
		'$A$7     Total kills: $B$3'+inttostr(ch.kills),false,ch,nil,nil,TO_CHAR);
	act(AT_REPORT,'   Stamina:  $B$3'+pad_integer(ch.mv,5)+'$A$7/$B$3'+pad_integer(ch.max_mv,5)+
		'$A$7     Hitroll:            $B$3'+pad_integer(ch.hitroll,4)+
		'$A$7     Alignment:   $B$3'+inttostr(ch.alignment),false,ch,nil,nil,TO_CHAR);

	if (ch.IS_NPC) then
		act(AT_REPORT,'   Mana:     $B$3'+pad_integer(ch.mana,5)+'$A$7/$B$3'+pad_integer(ch.max_mana,5)+
			'$A$7     Level:              $B$3'+pad_integer(ch.level,4)+#13#10,false,ch,nil,nil,TO_CHAR)
	else
		act(AT_REPORT,'   Mana:     $B$3'+pad_integer(ch.mana,5)+'$A$7/$B$3'+pad_integer(ch.max_mana,5)+
			'$A$7     Level:              $B$3'+pad_integer(ch.level,4)+
			'$A$7     Wimpy:       $B$3'+inttostr(GPlayer(ch).wimpy)+#13#10,false,ch,nil,nil,TO_CHAR);

	if (ch.IS_IMMORT) and (ch.IS_WIZINVIS) then
		act(AT_REPORT,'   WizLevel: $B$3'+pad_integer(GPlayer(ch).wiz_level,3)+#13#10,false,ch,nil,nil,TO_CHAR);

	if (not ch.IS_NPC) then
		act(AT_REPORT,'   You have $B$3'+IntToStr(GPlayer(ch).pracs)+'$A$7 practice sessions left.',false,ch,nil,nil,TO_CHAR);

	if (not ch.IS_NPC) then
		act(AT_REPORT,'   Thou hast gained $B$3'+inttostr(GPlayer(ch).bg_points)+'$A$7 battleground points.',false,ch,nil,nil,TO_CHAR);

	if (ch.getTrust > ch.level) then
		act(AT_REPORT,'   Thou art trusted by the gods at level '+inttostr(ch.getTrust)+'.',false,ch,nil,nil,TO_CHAR);

	{ thx to Haus for the following lines - Grimlord }
	if (not ch.IS_NPC) then
		begin
		if (ch.IS_DRUNK) then
			ch.sendBuffer('   Thou art drunk.'#13#10);

		if (GPlayer(ch).condition[COND_THIRST]=0) then
			ch.sendBuffer('   Thou art dehydrating.'#13#10);

		if (GPlayer(ch).condition[COND_FULL]=0) then
			ch.sendBuffer('   Thou art starving to death.'#13#10);
		end;

	if (ch.state <> STATE_SLEEPING) then
		case ch.mental_state div 10 of
			-10:ch.sendBuffer('   You are barely conscious.'#13#10);
			-9:ch.sendBuffer('   You can barely keep your eyes open.'#13#10);
			-8:ch.sendBuffer('   You are extremely drowsy.'#13#10);
			-7:ch.sendBuffer('   You feel very unmotivated.'#13#10);
			-6:ch.sendBuffer('   You feel sedated.'#13#10);
			-5:ch.sendBuffer('   You feel sleepy.'#13#10);
			-4:ch.sendBuffer('   You feel tired.'#13#10);
			-3:ch.sendBuffer('   You could use a rest.'#13#10);
			-2:ch.sendBuffer('   You feel okay.'#13#10);
			-1:ch.sendBuffer('   You feel fine.'#13#10);
			0:ch.sendBuffer('   You feel great.'#13#10);
			1:ch.sendBuffer('   You feel energetic.'#13#10);
			2:ch.sendBuffer('   Your mind is racing.'#13#10);
			3:ch.sendBuffer('   You cannot think normally.'#13#10);
			4:ch.sendBuffer('   You are very much off balance.'#13#10);
			5:ch.sendBuffer('   Your mind seems to be exploding.'#13#10);
			6:ch.sendBuffer('   Your mind and body are losing their connection.'#13#10);
			7:ch.sendBuffer('   Reality is slipping away.'#13#10);
			8:ch.sendBuffer('   You have no idea of what is real and what not.'#13#10);
			9:ch.sendBuffer('   You feel like a god.'#13#10);
			10:ch.sendBuffer('   You feel a rival of Grimlord.'#13#10);
		else
			ch.sendBuffer('   Help! You are completely messed up!'#13#10);
		end
	else
	if (ch.mental_state>45) then
		ch.sendBuffer('   Your sleep is filled with strange dreams.'#13#10)
	else
	if (ch.mental_state>25) then
		ch.sendBuffer('   Your sleep is uneasy.'#13#10)
	else
	if (ch.mental_state<-35) then
		ch.sendBuffer('   Your body relaxes as you are deep in a much needed sleep.'#13#10)
	else
	if (ch.mental_state<-25) then
		ch.sendBuffer('   You are in deep slumber.'#13#10);

	if (not ch.IS_NPC) then
		begin
		act(AT_REPORT,'   Thou art carrying $B$2'+inttostr(ch.gold)+'$A$7 coins and hast $B$2'+
		inttostr(GPlayer(ch).bankgold)+'$A$7 coins stored at a bank.',false,ch,nil,nil,TO_CHAR);

		i := (ch.carried_weight*10) div ((ch.str div 2) + 10);

		if i<25 then
			buf1 := 'You are unburdened'
		else
		if i<50 then
			buf1 := 'You have no trouble carrying your load'
		else
		if i<75 then
			buf1 := 'You are sweating under your load'
		else
		if i<100 then
			buf1 := 'Your load is heavy, but not unbearable'
		else
		if i<125 then
			buf1 := 'Your load is quite heavy'
		else
		if i<150 then
			buf1 := 'You are slowed by your load'
		else
		if i<175 then
			buf1 := 'Your load is VERY heavy'
		else
		if i<200 then
			buf1 := 'Your load is almost unbearable'
		else
			buf1 := 'Unbearable';

		act(AT_REPORT,'   Thou art carrying a weight of $B$2'+inttostr(ch.carried_weight)+'$A$7 kg(s). ($B$7'+buf1+'$A$7)',false,ch,nil,nil,TO_CHAR);
		end;

	if (not ch.IS_NPC) and (GPlayer(ch).clanleader) then
		act(AT_REPORT,'   Thou art the great leader of $B$3'+ch.clan.name+'$A$7.',false,ch,nil,nil,TO_CHAR)
	else
	if (ch.clan <> nil) then
		act(AT_REPORT,'   Thou art a proud member of $B$3'+ch.clan.name+'$A$7.',false,ch,nil,nil,TO_CHAR);

	if (not ch.IS_NPC) and (GPlayer(ch).area_fname <> '') then
		act(AT_REPORT,'   Thou hast been assigned $B$7'+GPlayer(ch).area_fname+'$A$7. '#13#10+
			'   Thee construction ranges art: '+inttostr(GPlayer(ch).r_lo)+' '+inttostr(GPlayer(ch).r_hi)+' '+
			inttostr(GPlayer(ch).m_lo)+' '+inttostr(GPlayer(ch).m_hi)+' '+
			inttostr(GPlayer(ch).o_lo)+' '+inttostr(GPlayer(ch).o_hi)+'.',false,ch,nil,nil,TO_CHAR);

	buf1 := #13#10' $8[$4*$8]$3 ' + add_chars(70, '', '-') + ' $8[$4*$8]';
	act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);
end;

procedure do_stats(ch:GCharacter;param:string);
var buf : string;
begin
  buf := 'Stats:'#13#10#13#10 +
         'Strength:       ' + inttostr(ch.str) + #13#10 +
         'Constitution:   ' + inttostr(ch.con) + #13#10 +
         'Dexterity:      ' + inttostr(ch.dex) + #13#10 +
         'Intelligence:   ' + inttostr(ch.int) + #13#10 +
         'Wisdom:         ' + inttostr(ch.wis);

  act(AT_REPORT,buf,false,ch,nil,nil,TO_CHAR);
end;

{ Jago 6/Jan/20001 : changed the format of WHO somewhat }
{ Xenon 22/Feb/2001: changed the format of WHO some more, still needs some more features (later) }
{ Xenon 23/Feb/2001: added 'who good' 'who evil' 'who imm' 'who clan' 'who <race>' 'who <name>' (code could be a bit cleaner still)}
procedure do_who(ch:GCharacter;param:string);
var 
  num, num_good, num_evil, numImms :integer;
  buf1 : string;
  buf_imm, buf_good, buf_evil, buf_result : string;
  conn : GPlayerConnection;
  iterator : GIterator;
  arg : string;
  normarg, specarg : boolean;
begin
  param := one_argument(param, arg);
  arg := trim(uppercase(arg));
  
  { normarg is only true if there's a paramater to who and it is one of GOOD, EVIL or IMM }
  normarg := (arg = 'GOOD') or (arg = 'EVIL') or (pos('IMM', arg) = 1);
  { specarg is only true if there's a parameter to who and it isnt one of GOOD, EVIL or IMM }
  specarg := (length(arg) > 0) and not(normarg);

  num := 0;
  num_good := 0;
  num_evil := 0;
  numImms := 0;

  buf_imm := add_chars(80, '$3---- Visible Immortals ', '-')  + #13#10 + #13#10;
  buf_good := add_chars(80, '$3---- Visible Mortals of the Creatures of Light ', '-')  + #13#10 + #13#10;
  buf_evil := add_chars(80, '$3---- Visible Mortals of the Creatures of Darkness ', '-')  + #13#10 + #13#10;

  iterator := connection_list.iterator();

  while (iterator.hasNext()) do
    begin
    conn := GPlayerConnection(iterator.next());
    
    if (conn.isPlaying() or conn.isEditing()) and (ch.CAN_SEE(conn.ch)) and (ch.IS_SAME_ALIGN(conn.ch)) and (not conn.ch.IS_NPC) then
      begin
      if not(specarg) or
        isName(conn.ch.race.name, arg) or
        isName(conn.ch.name, arg) or
        ((arg = 'CLAN') and (ch.clan <> nil) and (ch.clan = conn.ch.clan)) then
        begin
        inc(num);
        if (conn.ch.IS_GOOD) then
          inc(num_good)
        else
        if (conn.ch.IS_EVIL) then
          inc(num_evil);
        
        if (conn.ch.IS_IMMORT) then
          begin
          inc(numImms);

          if (conn.ch.IS_WIZINVIS) then
            buf_imm := buf_imm + '$B$7W$A$7'
          else
            buf_imm := buf_imm + ' ';
          
          if (conn.ch.IS_INVIS) then
            buf_imm := buf_imm + '$B$7I$A$7'
          else
            buf_imm := buf_imm + ' ';
          
          if (conn.ch.IS_HIDDEN) then
            buf_imm := buf_imm + '$B$7H$A$7'
          else
            buf_imm := buf_imm + ' ';
          
          if (conn.ch.clan <> nil) then
            begin
            if (conn.ch.clan = ch.clan) then
              buf_imm := buf_imm + '$B$7C $A$7<$B$6'
            else
              buf_imm := buf_imm + '$B$7[' + conn.ch.clan.abbrev + '] $A$7<$B$6';
            end
          else
            buf_imm := buf_imm + '  $A$7<$B$6';

          buf_imm := buf_imm +  pad_string(imm_types[conn.ch.level],12) + '$A$7> ';

          if (conn.ch.afk) then
            buf_imm := buf_imm + '$B$7<AFK> $A$7';

          buf_imm := buf_imm + conn.ch.name + ' ' + GPlayer(conn.ch).title;

          buf_imm := buf_imm + #13#10;

          end
        else
          begin
          delete(buf1, 1, length(buf1));
        
          if (conn.ch.clan <> nil) and (conn.ch.clan = ch.clan) then
            buf1 := buf1 + '   $B$7C$A$7 <'
          else
            buf1 := buf1 + '    $A$7 <';

          //change colour according to align .. dont *really* need to say "Good" or "Evil"
          if (conn.ch.alignment >= 0) then
            buf1 := buf1 + '$B$2'
          else
          if (conn.ch.alignment < 0) then
            buf1 := buf1 + '$B$4';

          buf1 := buf1 + Format('%3d', [conn.ch.level]) + ' ' + pad_string_front(conn.ch.race.name, 12);

          buf1 := buf1 + '$A$7> ';

          if (conn.ch.afk) then
            buf1 := buf1 + '$B$7<AFK> $A$7';

          buf1 := buf1 + conn.ch.name + ' ' + GPlayer(conn.ch).title;

          buf1 := buf1 + #13#10;

          if (conn.ch.IS_GOOD) then
            buf_good := buf_good + buf1
          else
          if (conn.ch.IS_EVIL) then
            buf_evil := buf_evil + buf1
          else
            bugreport('do_who', 'cmd_info.inc', 'unknown align on character ' + conn.ch.name);
          end;
        end;
      end;
    end;
  
  iterator.Free();

  if normarg or (arg = 'CLAN') then
    begin
    if (arg = 'GOOD') and (ch.IS_GOOD or ch.IS_IMMORT) then
      begin
      buf_result := buf_good;
      num := num_good;
      end
    else
    if (arg = 'EVIL') and (ch.IS_EVIL or ch.IS_IMMORT) then
      begin
      buf_result := buf_evil;
      num := num_evil;
      end
    else
    if (arg = 'CLAN') then
      begin
      if (numImms > 0) then
        buf_result := buf_imm + #13#10;
        
      if (ch.IS_IMMORT) then          // in case imm is in a mortal clan
        begin
        if (num_good > 0) then
          buf_result := buf_result + buf_good;
        if (num_evil > 0) then
          buf_result := buf_result + buf_evil;
        end
      else
      if (ch.IS_GOOD) then
        begin
        buf_result := buf_result + buf_good
        end
      else
      if (ch.IS_EVIL) then
        begin
        buf_result := buf_result + buf_evil
        end;
      end
    else
    if (pos('IMM', arg) = 1) and (numImms > 0) then
      begin
      buf_result := buf_imm;
      num := numImms;
      end
    else
      begin
      num := 0;
      end;
    end
  else
    begin
    if (numImms > 0) then
      begin
      buf_result := buf_imm;
      if ((num_good > 0) or (num_evil > 0)) then
        buf_result := buf_result + #13#10;
      end;
      
    if (ch.IS_IMMORT) then
      begin
      if (num_good > 0) then
        buf_result := buf_result + buf_good;
      if (num_good > 0) and (num_evil > 0) then
        buf_result := buf_result + #13#10;
      if (num_evil > 0) then
        buf_result := buf_result + buf_evil;
      end
    else
      begin
      if (ch.IS_GOOD) then
        buf_result := buf_result + buf_good
      else
      if (ch.IS_EVIL) then
        buf_result := buf_result + buf_evil
      else
        bugreport('do_who', 'cmd_info.inc', 'unknown align on character ' + ch.name);
      end;
    end;
        
  act(AT_REPORT,buf_result,false,ch,nil,nil,TO_CHAR);

  act(AT_REPORT,'Currently '+inttostr(num)+' player(s) visible to you.',false,ch,nil,nil,TO_CHAR);
end;

procedure do_title(ch:GCharacter;param:string);
begin
  if (ch.IS_NPC) then
    exit;

  if (length(param)=0) then
    begin
    ch.sendBuffer('Set title to what?'#13#10);
    exit;
    end;

  GPlayer(ch).title := param;
  ch.sendBuffer('Title set to "' + param + '"'#13#10);
end;

procedure do_group(ch:GCharacter;param:string);
var 
  buf1 : string;
  vict : GCharacter;
  iterator : GIterator;
begin
  if (length(param)=0) then
    begin
    act(AT_REPORT,'Group leader: [$B$7' + ch.leader.name+'$A$7]',false,ch,nil,nil,TO_CHAR);
    ch.sendBuffer(#13#10'[Power of Char]  [Name]      [Health]  [Stamina]   [Xp2Lvl]'#13#10);

    iterator := char_list.iterator();
    while (iterator.hasNext()) do
      begin
      vict := GCharacter(iterator.next());

      if (vict.leader = ch.leader) then
        begin
        if (vict.level < 50) then
          buf1 := '[$8Inexperienced'
        else
        if (vict.level < 100) then
          buf1 := '[$8Knowledgeable'
        else
        if (vict.level < 150) then
          buf1 := '[$8 Experienced '
        else
        if (vict.level < 200) then
          buf1 := '[$8 Well-Known  '
        else
        if (vict.level < 300) then
          buf1 := '[$8---Famous----'
        else
        if (vict.level < 400) then
          buf1 := '[$8--Legendary--'
        else
          buf1 := '[$8----Deity----';

        buf1 := buf1 + '$7]$B$7  ' + pad_string(vict.name,12);

        buf1 := buf1 + '$B$4' + pad_string(hp_perc[UMax(round((vict.hp / vict.max_hp) * 5), 0)], 10);

        buf1 := buf1 + '$B$1' + pad_string(mv_perc[UMax(round((vict.mv / vict.max_mv) * 5), 0)], 12);

        if (not vict.IS_NPC) then
          buf1 := buf1 + inttostr(GPlayer(vict).xptogo);

        act(AT_REPORT,buf1,false,ch,nil,nil,TO_CHAR);
        end;
      end;
    iterator.Free();
    end
  else
  if (comparestr('all',param) = 0) then
    begin
    iterator := char_list.iterator();

    while (iterator.hasNext()) do
      begin
      vict := GCharacter(iterator.next());

      if (vict.master = ch) and (vict.leader <> ch) then
        begin
        vict.leader := ch;
        act(AT_REPORT,'$N joins $n''s group.', false, ch, nil, vict, TO_NOTVICT);
        to_channel(ch, '$B$7[Group]: '+vict.name+' has joined the group!', CHANNEL_GROUP, AT_WHITE);
        end;
      end;

    iterator.Free();
    act(AT_REPORT, 'Ok.', false, ch, nil, nil, TO_CHAR);
    end
  else
    begin
    vict := findCharWorld(ch, param);

    if (vict = nil) then
      ch.sendBuffer('They aren''t here.'#13#10)
    else
    if (vict = ch) then
      begin
      act(AT_REPORT,'You have disbanded the group.',false,ch,nil,nil,TO_CHAR);

      iterator := char_list.iterator();
      while (iterator.hasNext()) do
        begin
        vict := GCharacter(iterator.next());
        
        if (vict.master = ch) and (vict.leader = ch) then
          begin
          act(AT_REPORT,'$n has disbanded the group and you follow no-one.',false,ch,nil,vict,TO_VICT);
          vict.master := nil;
          vict.leader := vict;
          end;
        end;
      iterator.Free();
      end
    else
    if (vict.master <> ch) then
      ch.sendBuffer('One must first follow to get in a group.'#13#10)
    else
    if (vict.leader = ch) then
      begin
      to_channel(ch, '$B$7[Group]: ' + vict.name + ' has left the group.', CHANNEL_GROUP, AT_WHITE);
      vict.leader := vict;
      end
    else
      begin
      vict.leader := ch;
      to_channel(ch, '$B$7[Group]: '+vict.name+' has joined the group!', CHANNEL_GROUP, AT_WHITE);
      end;
    end;
end;

procedure do_grouphand(ch : GCharacter; param : string);
var
	iterator : GIterator;
	vict, leader : GCharacter;
begin
	if (length(param) = 0) then
		begin
		ch.sendBuffer('Hand the group to whom?'#13#10);
		exit;
		end;

    if (ch.leader <> ch) then
    	begin
    	ch.sendBuffer('You''re not the groupleader!'#13#10);
    	exit;
    	end;
    	
    leader := findCharWorld(ch, param);
    
    if (leader = nil) then
    	begin
    	ch.sendBuffer('Can''t find that player.'#13#10);
    	exit;
    	end;
    
    if (leader = ch) then
    	begin
    	ch.sendBuffer('You already are the groupleader!'#13#10);
    	exit;
    	end;

    if (leader.leader <> ch) then
    	begin
    	ch.sendBuffer('That player is not part of the group!'#13#10);
    	exit;
    	end;
    		
	iterator := char_list.iterator();
	
	while (iterator.hasNext()) do
		begin
		vict := GCharacter(iterator.next());

		if (vict.master = ch) and (vict.leader = ch) then
			begin
			vict.master := leader;
			vict.leader := leader;
			end;
		end;
		
	ch.master := leader;
	ch.leader := leader;
		
	iterator.Free();
	
	act(AT_REPORT, 'You hand your group to $N.', false, ch, nil, leader, TO_CHAR);
	act(AT_REPORT, '$n hands $s group to $N.', false, ch, nil, leader, TO_ROOM);
	to_channel(ch, '$B$7[Group]: '+leader.name+' is now the groupleader!', CHANNEL_GROUP, AT_WHITE);
end;

procedure do_follow(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  vict := ch.room.findChar(ch, param);

  if (vict = nil) then
    ch.sendBuffer('They are not here.'#13#10)
  else
  if (vict = ch) then
    begin
    if (ch.master = nil) then
      ch.sendBuffer('You stop anyone you were following.'#13#10)
    else
      begin
      ch.sendBuffer('You stop following ' + ch.master.name + '.'#13#10);

      if not(ch.IS_WIZINVIS() and ch.IS_IMMORT()) then
        act(AT_REPORT,'$n no longer follows you.',false,ch,nil,ch.master,TO_VICT);
      ch.master := nil;

      if (ch.leader <> ch) then
        begin
        to_channel(ch.leader, '$B$7[Group]: ' + ch.name+ ' has left the group.', CHANNEL_GROUP, AT_WHITE);
        ch.leader := ch;
        end;
      end;
    end
  else
    begin
    ch.sendBuffer('You now follow ' + vict.name + '.'#13#10);

    if not(ch.IS_WIZINVIS() and ch.IS_IMMORT()) then
      act(AT_REPORT,'$n now follows you.',false,ch,nil,vict,TO_VICT);

    ch.master := vict;

    if (ch.leader <> ch) then
      begin
      to_channel(ch.leader, '$B$7[Group]: ' + ch.name + ' has left the group.', CHANNEL_GROUP, AT_WHITE);
      ch.leader := ch;
      end;
    end;
end;

procedure do_ditch(ch:GCharacter;param:string);
var
  vict : GCharacter;
  iterator : GIterator;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Ditch whom?'#13#10);
    exit;
    end;

  if (comparestr(param, 'all') = 0) then
    begin
    iterator := ch.room.chars.iterator();
    while (iterator.hasNext()) do
      begin
      vict := GCharacter(iterator.next());

      if (vict.master = ch) then
        interpret(vict, 'follow self');
      end;
    iterator.Free();
    
    ch.sendBuffer('Ok.'#13#10);
    end
  else
    begin
    vict := ch.room.findChar(ch, param);

    if (vict = nil) then
      begin
      ch.sendBuffer('You can''t seem to find the one you''re looking for.'#13#10);
      exit;
      end;

    interpret(vict, 'follow self');

    ch.sendBuffer('Ok.'#13#10);
    end;
end;

procedure do_where(ch:GCharacter;param:string);
var
  buf : string;
  vict : GCharacter;
  iterator : GIterator;
  d : integer;
begin
  buf := 'You are in ' + ch.room.area.name + ', built by ' + ch.room.area.author + '.'#13#10#13#10'Players near:'#13#10;

  ch.sendBuffer(buf);

  d := -1;

  iterator := char_list.iterator();
  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict <> ch) and (not vict.IS_NPC) and (vict.room.area = ch.room.area) and (ch.IS_SAME_ALIGN(vict)) then
      begin
      buf := pad_string(vict.name,20) + '   ' + vict.room.name + #13#10;
      ch.sendBuffer(buf);
      inc(d);
      end;
    end;
  iterator.Free();

  if (d = -1) then
   ch.sendBuffer('Nobody.'#13#10);
end;

procedure do_world(ch:GCharacter;param:string);
var
   buf : string;
begin
  buf := '$B$4Some world statistics:$A$7'#13#10#13#10 +
         'Open areas:        [$B$1' + pad_integer_front(area_list.size(), 5) + '$A$7]'#13#10 +
         'Rooms explorable:  [$B$1' + pad_integer_front(room_list.size(), 5) + '$A$7]'#13#10 +
         'World user max:    [$B$1' + pad_integer_front(system_info.user_high, 5) + '$A$7]'#13#10;

  act(AT_REPORT, buf, false, ch, nil, nil, TO_CHAR);
end;

{Jago 7/Jan/2001 : repaired for v 0.3}
procedure do_consider(ch:GCharacter;param:string);
var vict:GCharacter;
    dam1,dam2:integer;
    end1,end2:integer;
    proc1,proc2:integer;
    //obj:OBJECT_DATA;
    obj: GObject;
begin
  if (length(param)=0) then
  begin
    ch.sendBuffer('Consider who?'#13#10);
    exit;
  end;

  vict := ch.room.findChar(ch, param);

  if vict=nil then
    act(AT_REPORT,'They are not here.',false,ch,nil,nil,TO_CHAR)
  else
    begin
    obj := ch.getWield(ITEM_WEAPON);

    if (obj = nil) then
      dam1 := 3
    else
      dam1 := obj.value[2]*obj.value[3];

    inc(dam1, ch.apb);

    dam1:=(dam1 * ch.str) div 50;

    obj := vict.getWield(ITEM_WEAPON);

    if (obj = nil) then
      dam2 := 3
    else
      dam2 := obj.value[2]*obj.value[3];

    inc(dam2,vict.apb);

    dam2:=(dam2 * ch.str) div 50;

    end1:=ch.hp;
    end2:=vict.hp;

    repeat
      dec(end1,dam2);
      dec(end2,dam1);
    until (end1<=0) or (end2<=0);

    proc1:=URange(0,(100*end1) div ch.hp,100);
    proc2:=URange(0,(100*end2) div vict.hp,100);

    if dam1>dam2 then
      act(AT_REPORT,'You look stronger than $N.',false,ch,nil,vict,TO_CHAR)
    else
    if dam1=dam2 then
      act(AT_REPORT,'You look about as strong as $N.',false,ch,nil,vict,TO_CHAR)
    else
      act(AT_REPORT,'$N looks stronger than you.',false,ch,nil,vict,TO_CHAR);
    if end1>end2 then
      act(AT_REPORT,cons_perc_you[round(proc1/20)],false,ch,nil,vict,TO_CHAR)
    else
    if end1=end2 then
      act(AT_REPORT,'A battle with $N would end even.',false,ch,nil,vict,TO_CHAR)
    else
      act(AT_REPORT,cons_perc_oppnt[round(proc2/20)],false,ch,nil,vict,TO_CHAR);
    end;
end;

{Jago 7/Jan/2001 re-implemented for v 0.3}
procedure do_scan(ch:GCharacter;param:string);

const
  distance:array[1..3] of string=('pretty close by','fairly far off','a long way off');

var
     h,a,i:integer;
    buf1, sModifier : string;
    room_pos:GRoom;
    e:GExit;
    count, scanCount : integer;
    vict:GCharacter;
    list_first : GDLinkedList;
    list_count:integer;
    vict_node : GListNode;

begin
  list_first := GDLinkedList.Create;
  try

    scanCount := 0;
    act(AT_REPORT,'You scan in all directions:'#13#10,false,ch,nil,nil,TO_CHAR);

    for h :=DIR_NORTH to DIR_UP do
    begin
      room_pos:=ch.room;

      for i := 1 to 3 do
      begin
        e := room_pos.findExit(h);

        if (e<>nil) then
        begin
          if (IS_SET(e.flags, EX_SECRET) and IS_SET(e.flags, EX_CLOSED)) then
           break;

          room_pos := findRoom(e.vnum);
          count:=0;
          buf1 := '';
          list_count:=0;

          vict_node :=room_pos.chars.head;
          while  vict_node <> nil do
          begin
           vict := GCharacter(vict_node.element);

           if (ch.CAN_SEE(vict)) then
           begin
             list_first.insertLast(vict);
             inc(list_count);
           end;

           vict_node := vict_node.next;
          end;

          a := 0;
          vict_node := list_first.head;

          while vict_node <> nil do
          begin
           vict := GCharacter(vict_node.element);
           inc(count);

           buf1 := buf1 + playername(vict, ch);

           if a < list_count-2 then
             buf1 := buf1 + ', '
           else if count = list_count - 1 then
             buf1 := buf1 + ' and ';

           inc(a);

           vict_node := vict_node.next;
          end;

          if buf1 <> '' then // was someone found in that direction?
          begin
            if count = 1 then
             sModifier := ' is '
            else
             sModifier := ' are ';

            buf1 := buf1 + sModifier;
            buf1 := buf1 + distance[i] + ' ';
            buf1 := buf1 + headings[h] + ' from here.';

            inc(scanCount);

            act(AT_REPORT,buf1,false,ch,nil,nil,TO_CHAR);
            { person in this room blocks scan of other rooms in this direction - Grimlord }

            // clear list_first for next iteration
            vict_node := list_first.head;

            while vict_node <> nil do
            begin
              list_first.remove(vict_node);
              vict_node := list_first.head;;
            end;

            break;
          end;
        end;
      end;
    end; {for}

    if scanCount = 0 then
        act(AT_REPORT,'No-one to be seen in any direction.',false,ch,nil,nil,TO_CHAR);
  finally
    list_first.Free;
  end;
end;

procedure do_affects(ch:GCharacter;param:string);
var 
  h:integer;
  buf:string;
  iterator : GIterator;
  aff : GAffect;
begin
  act(AT_REPORT, '$B$1[$B$7Current status:$B$1]$A$7'#13#10, false, ch, nil, nil, TO_CHAR);

  if (ch.IS_FLYING) then
    ch.sendBuffer('You are flying.'#13#10);

  if (IS_SET(ch.aff_flags, AFF_SNEAK)) then
    ch.sendBuffer('You attempt to sneak.'#13#10);

  if (IS_SET(ch.aff_flags, AFF_HIDE)) then
    ch.sendBuffer('You attempt to hide.'#13#10);

  if (not ch.IS_NPC) and (IS_SET(GPlayer(ch).flags, PLR_HOLYWALK)) then
    ch.sendBuffer('Holy walk is on.'#13#10);

  if (not ch.IS_NPC) and (IS_SET(GPlayer(ch).flags, PLR_HOLYLIGHT)) then
    ch.sendBuffer('Holy light is on.'#13#10);

  if (not ch.IS_NPC) and (IS_SET(GPlayer(ch).flags, PLR_CLOAK)) then
    ch.sendBuffer('You are cloaked.'#13#10);

  h:=0;
  act(AT_REPORT, #13#10'$B$1[$B$7Current affects:$B$1]$A$7'#13#10, false, ch, nil, nil, TO_CHAR);

  iterator := ch.affects.iterator();
  while (iterator.hasNext()) do
    begin
    aff := GAffect(iterator.next());

    if (aff.name <> '') then
      with aff do
        begin
        buf := name + ', which will wear off';

        if duration=1 then
          buf := buf + ' any moment'
        else
        if duration<4 then
          buf := buf + ' in a few hours'
        else
        if duration<7 then
          buf := buf + ' in about a quarter of a day'
        else
        if duration<13 then
          buf := buf + ' in half a day'
        else
        if duration<25 then
          buf := buf + ' in about a day'
        else
        if duration<49 then
          buf := buf + ' in a day or two'
        else
          buf := buf + ' after several days';

        buf := buf + '.'#13#10;

        ch.sendBuffer(buf);
        inc(h);
        end;
    end;
  iterator.Free();

  if (h = 0) then
    ch.sendBuffer('No affects.'#13#10);
end;

procedure do_armor(ch:GCharacter;param:string);

procedure checkac(ac:integer);
begin
  if ac>7 then
    ch.sendBuffer('Poorly protected'#13#10)
  else
  if ac>4 then
    ch.sendBuffer('Barely protected'#13#10)
  else
  if ac>1 then
    ch.sendBuffer('Fairly protected'#13#10)
  else
  if ac>-3 then
    ch.sendBuffer('Moderately protected'#13#10)
  else
  if ac>-7 then
    ch.sendBuffer('Well protected'#13#10)
  else
  if ac>-11 then
    ch.sendBuffer('Very protected'#13#10)
  else
  if ac>-15 then
    ch.sendBuffer('Extremely protected'#13#10)
  else
  if ac>-19 then
    ch.sendBuffer('Incredibly protected'#13#10)
  else
  if ac>-23 then
    ch.sendBuffer('Virtually impenetrable'#13#10)
  else
  if ac>-27 then
    ch.sendBuffer('A solid wall'#13#10)
  else
    ch.sendBuffer('Godly protection'#13#10);
end;

begin
  with ch do
    begin
    ch.sendBuffer('Your armor: '#13#10#13#10);
    ch.sendBuffer('Head:    ');
    checkac(hac);
    ch.sendBuffer('Body:    ');
    checkac(bac);
    ch.sendBuffer('Arms:    ');
    checkac(aac);
    ch.sendBuffer('Legs:    ');
    checkac(lac);
    ch.sendBuffer(#13#10'Overall: ');
    checkac(ac);
    end;
end;

{ Xenon 21/Feb/2001 : modified do_config() to also work with commands like 'config +blank' etc. }
procedure do_config(ch:GCharacter;param:string);
var s:string;
    d:integer;
    not_switch : boolean;
    turn_on : boolean;
    
procedure hi_type(s,a:string);
var g:integer;
begin
  g:=15-length('['+s+']');

  act(AT_BLUE,'[$B$7'+uppercase(s)+'$A$9]$7'+pad_string(' ',g)+a,false,ch,nil,nil,TO_CHAR);
end;

procedure lo_type(s,a:string);
var g:integer;
begin
  g:=15-length('['+s+']');

  act(AT_BLUE,'[$1'+s+'$9]$7'+pad_string(' ',g)+a,false,ch,nil,nil,TO_CHAR);
end;

begin
  turn_on := false;
  if (ch.IS_NPC) then
    exit;

  if (length(param) = 0) then
    begin
    ch.sendBuffer('Current configuration:'#13#10#13#10);

    with GPlayer(ch) do
      begin
      if IS_SET(cfg_flags,CFG_ASSIST) then
        hi_type('assist','You automatically assist people in your group.')
      else
        lo_type('assist','You do not assist people in your group.');
      if IS_SET(cfg_flags,CFG_AUTOLOOT) then
        hi_type('autoloot','You automatically loot corpses at a kill.')
      else
        lo_type('autoloot','You do not loot corpses at a kill.');
      if IS_SET(cfg_flags,CFG_AUTOSAC) then
        hi_type('autosac','You automatically sacrifice corpses.')
      else
        lo_type('autosac','You do not sacrifice corpses.');
      if IS_SET(cfg_flags,CFG_AUTOSCALP) then
        hi_type('autoscalp','You automatically scalp dead opponents.')
      else
        lo_type('autoscalp','You don''t scalp dead opponents.');
      if IS_SET(cfg_flags,CFG_BLANK) then
        hi_type('blank','You receive a blank line before each prompt.')
      else
        lo_type('blank','You don''t receive a blank line before each prompt.');
      if IS_SET(cfg_flags,CFG_BRIEF) then
        hi_type('brief','All descriptions are brief.')
      else
        lo_type('brief','You receive full descriptions.');
      if IS_SET(cfg_flags,CFG_ANSI) then
        hi_type('ansi','You receive ANSI colors.')
      else
        lo_type('ansi','You don''t receive ANSI colors.');
      if IS_SET(cfg_flags,CFG_PAGER) then
        hi_type('pager','You view paged output when necessary.')
      else
        lo_type('pager','You don''t view paged output.');
      if IS_SET(cfg_flags,CFG_AUTOPEEK) then
        hi_type('autopeek','You automatically peek someone when looking at him.')
      else
        lo_type('autopeek','You don''t automatically peek someone when looking at him.');

      ch.sendBuffer(#13#10 + 'Immortal options:' + #13#10#13#10);
      if IS_SET(cfg_flags,CFG_AUTOCREATE) then
        hi_type('autocreate','You automatically create new rooms upon walking.')
      else
        lo_type('autocreate','You don''t automatically create new rooms upon walking.');
      end;
    end
  else
    begin
    if (param[1] in ['+','-']) then
    begin
      not_switch := true;
      if (param[1] = '+') then
        turn_on := true
      else
        turn_on := false;
      delete(param,1,1);
    end
    else
      not_switch := false;
      
    s:=uppercase(param);
    if s='ASSIST' then
      d:=CFG_ASSIST
    else
    if s='AUTOLOOT' then
      d:=CFG_AUTOLOOT
    else
    if s='AUTOSAC' then
      d:=CFG_AUTOSAC
    else
    if s='BLANK' then
      d:=CFG_BLANK
    else
    if s='BRIEF' then
      d:=CFG_BRIEF
    else
    if s='ANSI' then
      d:=CFG_ANSI
    else
    if s='AUTOSCALP' then
      d:=CFG_AUTOSCALP
    else
    if s='PAGER' then
      d:=CFG_PAGER
    else
    if s='AUTOPEEK' then
      d:=CFG_AUTOPEEK
    else
    if s='AUTOCREATE' then
      d:=CFG_AUTOCREATE
    else
      begin
      ch.sendBuffer('Unknown option.'#13#10);
      exit;
      end;

    with GPlayer(ch) do
    begin
      if not_switch then
      begin
        if turn_on then
        begin
          SET_BIT(cfg_flags,d);
          act(AT_REPORT,'Option toggled $B$7ON$A$7.',false,ch,nil,nil,TO_CHAR);
        end
        else
        begin
          REMOVE_BIT(cfg_flags,d);
          act(AT_REPORT,'Option toggled $B$7OFF$A$7.',false,ch,nil,nil,TO_CHAR);
        end;
      end
      else
      begin
        if IS_SET(cfg_flags,d) then
          REMOVE_BIT(cfg_flags,d)
        else
          SET_BIT(cfg_flags,d);
        ch.sendBuffer('Option toggled.'#13#10);
      end;
    end;
    end;
end;

procedure do_visible(ch:GCharacter;param:string);
begin
  if (ch.IS_WIZINVIS) then
    do_wizinvis(ch,param)
  else
  if (ch.IS_INVIS) then
    begin
    removeAffectFlag(ch,AFF_INVISIBLE);
    ch.sendBuffer('Ok.'#13#10);
    end
  else
    ch.sendBuffer('But you already are visible!'#13#10);
end;

procedure do_trophy(ch:GCharacter;param:string);
var f:integer;
begin
  if (ch.IS_NPC) then
    exit;

  act(AT_REPORT,'Your trophy bandolier carries the following heads:'#13#10,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'$3[Lvl] [Name]                  [Times]',false,ch,nil,nil,TO_CHAR);

  for f:=1 to GPlayer(ch).trophysize do
    act(AT_REPORT,'['+pad_integer(GPlayer(ch).trophy[f].level,3)+
        '] '+pad_string(GPlayer(ch).trophy[f].name,23)+' '+inttostr(GPlayer(ch).trophy[f].times),false,ch,nil,nil,TO_CHAR);
end;

// All available socials - Nemesis
procedure do_socials(ch : GCharacter; param : string);
var
  iterator : GIterator;
  social : GSocial;
  socialList : TStringList;
  i : integer;
  buf : string;
begin
  socialList := TStringList.Create();
  iterator := socials.iterator();
  
  while (iterator.hasNext()) do
    begin
    social := GSocial(iterator.next());
    
    socialList.Add(lowercase(social.name));
    end;
    
  iterator.Free();
    
  // Sort the list
  socialList.Sort();  
  
  buf := #13#10 + ch.ansiColor(3) + ' ' + add_chars(78, '---- Available socials ', '-') + ch.ansiColor(7) + #13#10;
  
  for i := 0 to pred(socialList.Count) do
    begin
    if (i mod 5 = 0) then
      buf := buf + #13#10 + pad_string(socialList[i], 15)
    else
      buf := buf + pad_string(socialList[i], 15);
    end;
  
  buf := buf + #13#10;
  
  socialList.Free();
 
  ch.sendPager(buf);
end;

{ Xenon 23/Feb/2001: fixed a small bug; made alias'ing an already existing alias replace it }
procedure do_alias(ch : GCharacter; param : string);
var
  iterator : GIterator;
  al, tmp : GAlias;
  count : integer;
  alname, alfill : string;
  replaced : boolean;
begin
  replaced := false;

  if (ch.IS_NPC) then
    begin
    ch.sendBuffer('You cannot do this.'#13#10);
    exit;
    end;

  alfill := one_argument(param, alname);

  if (length(alname) > 0) then
    begin
    al := nil;
    iterator := GPlayer(ch).aliases.iterator();

    while (iterator.hasNext()) do
      begin
      tmp := GAlias(iterator.next());
      
      if (tmp.alias = alname) then
        begin
        al := tmp;
        break;
        end;
      end;
    iterator.Free();

    if (length(alfill) > 0) then
      begin
      if (al <> nil) then
        begin        
        GPlayer(ch).aliases.remove(al.node);
        al.Free;
        replaced := true;
        end;

      al := GAlias.Create;

      al.expand := one_argument(param, al.alias);
      al.node := GPlayer(ch).aliases.insertLast(al);

      if replaced then
        ch.sendBuffer('Alias replaced.'#13#10)
      else
        ch.sendBuffer('Alias added.'#13#10);
      end
    else
      begin
      if (al = nil) then
        ch.sendBuffer('No such alias.'#13#10)
      else
        begin
        GPlayer(ch).aliases.remove(al.node);
        al.Free;

        ch.sendBuffer('Alias removed.'#13#10);
        end;
      end;

    exit;
    end;

  if (GPlayer(ch).aliases.size() = 0) then
    begin
    ch.sendBuffer('No aliases.'#13#10);
    exit;
    end;

  iterator := GPlayer(ch).aliases.iterator();
  count := 0;

  while (iterator.hasNext()) do
    begin
    al := GAlias(iterator.next());

    ch.sendBuffer('[' + ch.ansiColor(3) + pad_integer(count, 2) + ch.ansiColor(7) + '] ' + pad_string(al.alias, 10) + ' -> ' + al.expand + #13#10);

    inc(count);
    end;
    
  iterator.Free();
end;

procedure do_brag(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC) then
    exit;

  act(AT_REPORT, 'You are level $B$6' + inttostr(ch.level) + '$A$7, $B$6' + GPlayer(ch).rank + '$A$7 of the $B$6' + ch.race.name + '$A$7 race.', false, ch, nil, nil, TO_CHAR);
  act(AT_REPORT, '$n is level $B$6' + inttostr(ch.level) + '$A$7, $B$6' + GPlayer(ch).rank + '$A$7 of the $B$6' + ch.race.name + '$A$7 race.', false, ch, nil, nil, TO_ROOM);

  act(AT_REPORT, 'You have $B$6' + inttostr(GPlayer(ch).war_points) + '$A$7 warpoints, $B$6' + inttostr(GPlayer(ch).quest_points) + '$A$7 questpoints and $B$6' + inttostr(GPlayer(ch).bg_points) + '$A$7 battlepoints.', false, ch, nil, nil, TO_CHAR);
  act(AT_REPORT, '$n has $B$6' + inttostr(GPlayer(ch).war_points) + '$A$7 warpoints, $B$6' + inttostr(GPlayer(ch).quest_points) + '$A$7 questpoints and $B$6' + inttostr(GPlayer(ch).bg_points) + '$A$7 battlepoints.', false, ch, nil, nil, TO_ROOM);

  act(AT_REPORT, 'You have $B$6' + inttostr(ch.max_hp) + '$A$7 max hitponts, $B$6' + inttostr(ch.max_mv) + '$A$7 max moves and $B$6' + inttostr(ch.max_mana) + '$A$7 max mana.', false, ch, nil, nil, TO_CHAR);
  act(AT_REPORT, '$n has $B$6' + inttostr(ch.max_hp) + '$A$7 max hitponts, $B$6' + inttostr(ch.max_mv) + '$A$7 max moves and $B$6' + inttostr(ch.max_mana) + '$A$7 max mana.', false, ch, nil, nil, TO_ROOM);
end;

{ Jago 7/Jan/2001}
procedure do_report(ch : GCharacter; param : string);
var
  hp, mana, mv : string;
  max_hp, max_mana, max_mv : string;
  sReport : string;
begin
  hp := IntToStr(ch.hp);
  max_hp := IntToStr(ch.max_hp);
  mana := IntToStr(ch.mana);
  max_mana := IntToStr(ch.max_mana);
  mv := IntToStr(ch.mv);
  max_mv := IntToStr(ch.max_mv);

  sReport := '"' + hp + '/' + max_hp + ' hp, ' +
             mana + '/' + max_mana + ' mana, ' +
             mv + '/' + max_mv + ' mv." ';

  act(AT_REPORT, 'You report: ' + sReport , false, ch, nil, nil,TO_CHAR);
  act(AT_REPORT, '$n reports: ' + sReport, false, ch, nil, nil, TO_ROOM);
end;

procedure do_taunt(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC) then
    exit;

  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  TAUNT <line or NULL to reset>'#13#10);

    if (GPlayer(ch).taunt <> '') then
      ch.sendBuffer('Currently: ' + GPlayer(ch).taunt + #13#10);

    exit;
    end;

  if (uppercase(param) = 'NULL') then
    GPlayer(ch).taunt := ''
  else
    GPlayer(ch).taunt := param;

  ch.sendBuffer('Ok.'#13#10);
end;

{ Sets pagerlength - Nemesis }
procedure do_setpager(ch:GCharacter;param:string);
var value : integer;
begin
  if (ch.IS_NPC) then
    exit;

  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: SETPAGER <nr. of lines>'#13#10);
    exit;
    end;

  try
    value := strtoint(param);
  except
    begin
    ch.sendBuffer('Value must be a number.'#13#10);
    exit;
    end;
  end;

  if (value < 15) then
    begin
    ch.sendBuffer('The minimum amount of lines is 15.'#13#10);
    exit;
    end;

  if (value > 50) then
    begin
    ch.sendBuffer('The maximum amount of lines is 50.'#13#10);
    exit;
    end;

  GPlayer(ch).pagerlen := value;
  act(AT_REPORT,'Pager set to ' + inttostr(value) + ' lines.',false,ch,nil,nil,TO_CHAR);
end;

{ shortcut command - Nemesis }
procedure do_autoloot(ch:GCharacter;param:string);
begin
  with GPlayer(ch) do
    begin
    if IS_SET(cfg_flags,CFG_AUTOLOOT) then
      begin
      REMOVE_BIT(cfg_flags,CFG_AUTOLOOT);
      ch.sendBuffer('You now won''t loot corpses at a kill.'#13#10);
      exit;
      end
    else
      begin
      SET_BIT(cfg_flags,CFG_AUTOLOOT);
      ch.sendBuffer('You now automatically loot corpses at a kill.'#13#10);
      exit;
      end;
    end;
end;

{ shortcut command - Nemesis }
procedure do_autosac(ch:GCharacter;param:string);
begin
  with GPlayer(ch) do
    begin
    if IS_SET(cfg_flags,CFG_AUTOSAC) then
      begin
      REMOVE_BIT(cfg_flags,CFG_AUTOSAC);
      ch.sendBuffer('You now won''t automatically sacrifice corpses at a kill.'#13#10);
      exit;
      end
    else
      begin
      SET_BIT(cfg_flags,CFG_AUTOSAC);
      ch.sendBuffer('You now automatically sacrifice corpses at a kill.'#13#10);
      exit;
      end;
    end;
end;

{ Allow players to change their password - Nemesis }
procedure do_password(ch : GCharacter; param: string);
var arg1, arg2 : string;
begin
  if (ch.IS_NPC) then
    exit;

  param := one_argument(param,arg1);
  one_argument(param,arg2);

  if (length(param) = 0) or ((length(arg1) > 0) and (length(arg2) = 0)) then
    ch.sendBuffer('Usage:  PASSWORD <old password> <new password>'#13#10)
  else
  if (not MD5Match(GPlayer(ch).md5_password, MD5String(arg1))) then
    begin
    ch.sendBuffer('Your password did not match!'#13#10);
    exit;
    end
  else
    begin
    GPlayer(ch).md5_password := MD5String(arg2);
    GPlayer(ch).save(ch.name);
    ch.sendBuffer('Ok, password changed.'#13#10);
    end;
end;

{ Last-login of player - Nemesis }
procedure do_last(ch : GCharacter; param : string);

function calcTimeDiff(last : TDateTime) : string;
var
	days, hours, minutes, seconds : integer;
begin

  days := DiffDays(last, Now);
  hours := DiffHours(last, Now);
  minutes := DiffMinutes(last, Now);
  seconds := DiffSeconds(last, Now);

  dec(seconds, 60 * minutes);
  dec(minutes, 60 * hours);
  dec(hours, 24 * days);

  result := IntToStr(days) + ' day(s), ' +
            IntToStr(hours) + ' hour(s), ' +
            IntToStr(minutes) + ' minute(s) and ' +
            IntToStr(seconds) + ' second(s)';
end;

var vict : GCharacter;
    s, g, arg, arg2, race : string;
    f : textfile;
    level : integer;
    last : TDateTime;
begin
  level := 0;
  param := one_argument(param, arg);
  one_argument(param, arg2);

  if (length(arg) = 0) then
    begin
    ch.sendBuffer('Usage: LAST <playername> [info]'#13#10);
    exit;
    end;

  vict := FindCharWorld(ch, arg);

  if (vict <> nil) and (not vict.IS_NPC) then
    begin
    if (not vict.IS_SAME_ALIGN(ch)) then
      ch.sendBuffer('That player is not found on your side.'#13#10)
    else
      act(AT_REPORT,vict.name + ' is currently online.',false,ch,nil,nil,TO_CHAR);

    exit;
    end
  else
    begin
    if (not FileExists('players\' + arg + '.usr')) then
      begin
      ch.sendBuffer('That player is not found on your side.'#13#10);
      exit;
      end
    else
      begin
      assignfile(f,'players\' + arg + '.usr');
      reset(f);

      repeat
        readln(f, s);

        g := uppercase(left(s, ':'));

        if (g = 'LEVEL') then
          level := strtoint(right(s, ' '))
        else
        if (g = 'RACE') then
          race := right(s, ' ')
        else
        if (g = 'LAST-LOGIN') then
          last := StrToDateTime(right(s, ' '));

      until eof(f);

      closefile(f);

      if (uppercase(arg2) = 'INFO') then
        act(AT_REPORT,arg + ' is a level ' + inttostr(level) + ' ' + race + '.', false, ch, nil, nil, TO_CHAR);
        
      if (last = 0) then
        act(AT_REPORT, arg + ' has been away too long to remember.', false, ch, nil, nil, TO_CHAR)
      else
        begin
        act(AT_REPORT, arg + ' was last on at: ' + FormatDateTime('ddd mmm dd hh:nn:ss yyyy', last) + '.', false, ch, nil, nil, TO_CHAR);
        act(AT_REPORT,'This is ' + calcTimeDiff(last) + ' ago.', false, ch, nil, nil, TO_CHAR);
        end;
      end;
    end;
end;

procedure do_raceinfo(ch : GCharacter; param : string);
procedure get_longest_racename(var len : integer);
var
  iterator : GIterator;
  race : GRace;
begin
  len := 0;
  iterator := raceList.iterator();

  while (iterator.hasNext()) do
    begin
    race := GRace(iterator.next());

    if (length(race.name) > len) then
      len := length(race.name);
    end;
end;

function get_nearest_racematch(name : string) : GRace;
var
  iterator : GIterator;
  race : GRace;
begin
  name := uppercase(name);
  
  iterator := raceList.iterator();

  while (iterator.hasNext()) do
    begin
    race := GRace(iterator.next());

    if (isName(race.name, name)) then
      begin
      get_nearest_racematch := race;
      exit;
      end;
    end;

  get_nearest_racematch := nil;
end;

var
  arg : string;
  iterator : GIterator;
  race : GRace;
  buf, str, header, buf_good, buf_evil, legenda : string;
  conv_str : string;
  maxlen : integer;
begin
  one_argument(param, arg);

  if (length(arg) = 0) then
    begin
    header := '$B$1Racename        A   B   C   D   E  |  S1  S2  S3  S4  S5  |  M1 M2  |  Convertable?$A$7'#13#10#13#10;
    buf_good := '$B$7----[Races of the Creatures of $B$6Light$B$7]----$A$7'#13#10#13#10 + header;
    buf_evil := '$B$7----[Races of the Creatures of $A$8Darkness$B$7]----$A$7'#13#10#13#10 + header;

    legenda := #13#10#13#10 +
               '$B$1Bonusses:     A: Str, B: Con, C: Dex, D: Int, E: Wis'#13#10 +
               'Saves versus: S1: Poison, S2: Cold, S3: Para, S4: Breath, S5: Spell'#13#10 +
               'Max slots:    M1: Skills, M2: Spells$A$7';

    get_longest_racename(maxlen);
    
    iterator := raceList.iterator();

    while (iterator.hasNext()) do
      begin
      race := GRace(iterator.next());

      with race do
      begin
        if (race.convert) then
          conv_str := 'X'
        else
          conv_str := '';
          
        if (race.def_alignment >= 0) then    // align good
        begin
          buf_good := buf_good + Format('$B$2%s$A$7: %3d %3d %3d %3d %3d  | %3d %3d %3d %3d %3d  |  %2d %2d  |  %s'#13#10, [pad_string(name, maxlen + 1), str_bonus, con_bonus, dex_bonus, int_bonus, wis_bonus, save_poison, save_cold, save_para, save_breath, save_spell, max_skills, max_spells, conv_str]);
        end
        else
        begin
          buf_evil := buf_evil + Format('$B$4%s$A$7: %3d %3d %3d %3d %3d  | %3d %3d %3d %3d %3d  |  %2d %2d  |  %s'#13#10, [pad_string(name, maxlen + 1), str_bonus, con_bonus, dex_bonus, int_bonus, wis_bonus, save_poison, save_cold, save_para, save_breath, save_spell, max_skills, max_spells, conv_str]);
        end;
        
      end;
    end;

    buf := buf_good + #13#10 + buf_evil + legenda + #13#10;
    act(AT_REPORT, buf, false, ch, nil, nil, TO_CHAR);
  end
  else
  begin
    race := get_nearest_racematch(arg);
    if (race <> nil) then
    begin
      buf := '';
      with race do
      begin
        if (race.def_alignment >= 0) then
        begin
          buf := buf + Format('$B$7[$2%s$7]$A$7', [race.name]) + #13#10#13#10;
          str := '$B$2Good$A$7';
        end
        else
        begin
          buf := buf + Format('$B$7[$4%s$7]$A$7', [race.name]) + #13#10#13#10;
          str := '$B$4Evil$A$7';
        end;
        buf := buf + Format('Alignment:             %s', [str]) + #13#10;
        buf := buf + Format('Strength bonus:        $B$7%d$A$7', [str_bonus]) + #13#10;
        buf := buf + Format('Constitution bonus:    $B$7%d$A$7', [con_bonus]) + #13#10;
        buf := buf + Format('Dexterity bonus:       $B$7%d$A$7', [dex_bonus]) + #13#10;
        buf := buf + Format('Intelligence bonus:    $B$7%d$A$7', [int_bonus]) + #13#10;
        buf := buf + Format('Wisdom bonus:          $B$7%d$A$7', [wis_bonus]) + #13#10#13#10;
        buf := buf + Format('Save vs. poison:       $B$7%d$A$7', [save_poison]) + #13#10;
        buf := buf + Format('Save vs. cold:         $B$7%d$A$7', [save_cold]) + #13#10;
        buf := buf + Format('Save vs. para:         $B$7%d$A$7', [save_para]) + #13#10;
        buf := buf + Format('Save vs. breath:       $B$7%d$A$7', [save_breath]) + #13#10;
        buf := buf + Format('Save vs. spell:        $B$7%d$A$7', [save_spell]) + #13#10#13#10;
        buf := buf + Format('Max skillslots:        $B$7%d$A$7', [max_skills]) + #13#10;
        buf := buf + Format('Max spellslots:        $B$7%d$A$7', [max_spells]) + #13#10#13#10;
        buf := buf + Format('Description:', []) + #13#10#13#10;
        buf := buf + Format('$B$7%s$A$7', [description]);
      end;
      
      act(AT_REPORT, buf, false, ch, nil, nil, TO_CHAR);
    end
    else
    begin
      act(AT_REPORT, 'No race like that found.', false, ch, nil, nil, TO_CHAR);
    end;
  end;
end;

// Command which shows your prompt so it can easily be copied to a different
// character - Nemesis
procedure do_showprompt(ch : GCharacter; param : string);
var buf : string;
begin
  if (ch.IS_NPC) then
    exit;

  buf := 'Your current prompt:' + #13#10 + GPlayer(ch).prompt;

  act(AT_REPORT, buf, false, ch, nil, nil, TO_CHAR);
end;

procedure do_prompt(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC()) then
    begin
    ch.sendBuffer('This command is not available for NPCs.'#13#10);
    exit;
    end;
  
  if (length(param) = 0) then
    begin
    ch.sendBuffer('%h - no. of hitpoints'#13#10);
    ch.sendBuffer('%H - max no. of hitpoints'#13#10);
    ch.sendBuffer('%m - no. of movement points'#13#10);
    ch.sendBuffer('%M - max no. of movement points'#13#10);
    ch.sendBuffer('%a - mana level'#13#10);
    ch.sendBuffer('%A - max mana level'#13#10);
    ch.sendBuffer('%l - level'#13#10);
    ch.sendBuffer('%x - xp to level'#13#10);
    ch.sendBuffer('%X - total xp'#13#10);
    ch.sendBuffer('%f - status of opponent (when fighting)'#13#10);
    ch.sendBuffer('%t - status of tank (when fighting)'#13#10);
    ch.sendBuffer(#13#10'Default prompt is %hhp %mmv %ama (%l)%t%f'#13#10#13#10);
    ch.sendBuffer('Your prompt is: ' + GPlayer(ch).prompt + #13#10);
    exit;
    end;

  GPlayer(ch).prompt := param;
  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_areas(ch:GCharacter; param:string);
var
  //area:AREA_DATA;
  area: GArea;
 area_node : GListNode;
begin
  act(AT_DCYAN, 'Area name                                                    Author'#13#10, false, ch, nil, nil, TO_CHAR);

  area_node := area_list.head;
  while area_node <> nil do
  begin
   area := GArea(area_node.element);
    act(AT_REPORT, pad_string(area.name, 60) + ' ' + pad_string(area.author, 19), false, ch, nil, nil, TO_CHAR);
    area_node := area_node.next;
  end;
end;

// All available commands - Nemesis
procedure do_commands(ch : GCharacter; param : string);
var
  iterator : GIterator;
  cmd : GCommand;
  cmdList : TStringList;
  i : integer;
  buf : string;
begin
  cmdList := TStringList.Create();
  iterator := commandList.iterator();
  
  while (iterator.hasNext()) do
    begin
    cmd := GCommand(iterator.next());
  
    // Show only commands available at your level
    if (cmd.level <= ch.level) then
      cmdList.Add(lowercase(cmd.name));
    end;
    
  iterator.Free();
  
  // Sort the list
  cmdList.Sort();  
  
  buf := #13#10 + ch.ansiColor(3) + ' ' + add_chars(78, '---- Available commands ', '-') + ch.ansiColor(7) + #13#10;
  
  for i := 0 to pred(cmdList.Count) do
    begin
    if (i mod 5 = 0) then
      buf := buf + #13#10 + pad_string(cmdList[i], 15)
    else
      buf := buf + pad_string(cmdList[i], 15);
    end;
  
  buf := buf + #13#10;
  
  cmdList.Free();
 
  ch.sendPager(buf);
end;