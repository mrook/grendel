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

procedure do_look(ch : GCharacter; param:string);
var a:integer;
    vict:GCharacter;
    node : GListNode;
    obj,obj_in: GObject;
    pexit:GExit;
    w1,w2:byte;
    inside:string[20];
    buf1,buf2 : string;
    cnt:integer;
    brief:boolean;
    r,act_str:string;
begin
  if IS_SET(ch.aff_flags,AFF_BLIND) then
    begin
    ch.sendBuffer('You can''t see a thing!'#13#10);
    exit;
    end;

  brief:=false;

  if (comparestr('_AUTO',param) = 0) then
   if (not ch.IS_NPC) and IS_SET(ch.player^.cfg_flags, CFG_BRIEF) then
    brief:=true;

  if (length(param) > 0) and (comparestr('_AUTO',param)<>0) then
    begin
    { Check if it is a user }
    vict := ch.room.findChar(ch, param);
    obj := ch.room.findObject(param);

    if (vict <> nil) then
      begin
      if (not vict.IS_NPC) then
        act(AT_REPORT,vict.name+'$7 is known as $B$6'+vict.player^.rank+'$A$7 amongst'+
        ' $S $B$4'+vict.race.name+'$A$7 ancestors.'#13#10,false,ch,nil,vict,TO_CHAR);

      w1 := UMin(round((vict.point.hp/vict.point.max_hp)*5),0);
      w2 := UMin(round((vict.point.mv/vict.point.max_mv)*5),0);

      act(AT_REPORT,vict.name+' looks '+hp_perc[w1]+' and '+mv_perc[w2]+'.',false,ch,nil,vict,TO_CHAR);

      cnt:=0;
      for a:=1 to MAX_WEAR do
       if (vict.wear[a] <> nil) then
        inc(cnt);

      if cnt<>0 then
        begin
        act(AT_REPORT,#13#10+vict.name+' is using:',false,ch,nil,vict,TO_CHAR);

        for a:=1 to MAX_WEAR do
         if (vict.wear[a] <> nil) then
          begin
          case a of
              16:r:='(floating ';
           17,18:r:='(held ';
            else r:='(worn ';
          end;

          r := add_chars(30, r + eq_string[a] + ')', ' ');

          act(AT_REPORT, r + ' $p',false,ch,vict.wear[a],nil,TO_CHAR);
          end;
        end;
      end
    else
    if obj<>nil then
      begin
      act(AT_REPORT,'You look at $p.'#13#10,false,ch,obj,nil,TO_CHAR);

      if (obj.item_type=ITEM_CONTAINER) or (obj.item_type=ITEM_CORPSE) then
        begin
        if (obj.contents.getSize > 0) then
          begin
          node := obj.contents.head;

          act(AT_REPORT,'$p contains:'#13#10,false,ch,obj,nil,TO_CHAR);

          while (node <> nil) do
            begin
            obj_in := node.element;

            if (obj_in.count > 1) then
              act(AT_REPORT,'   $p [$4'+inttostr(obj_in.count)+'$7x]',false,ch,obj_in,nil,TO_CHAR)
            else
              act(AT_REPORT,'   $p',false,ch,obj_in,nil,TO_CHAR);

            node := node.next;
            end;
          end
        else
          act(AT_REPORT,'$p is empty.',false,ch,obj,nil,TO_CHAR);
        end
      else
        act(AT_REPORT,'There is nothing special about $p.',false,ch,obj,nil,TO_CHAR);
      end
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

    act(AT_DGREEN,name+' [$B$5'+inside+'$A$2]$7',false,ch,nil,nil,TO_CHAR);

    if (not brief) then
      ch.sendBuffer(description);

    buf1 := '';
    node := exits.head;

    while (node <> nil) do
      begin
      pexit := node.element;

      if (IS_SET(pexit.flags, EX_SECRET) and IS_SET(pexit.flags, EX_CLOSED)) then
        begin
        node := node.next;

        continue;
        end;

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

      node := node.next;
      end;

    if (length(buf1) = 0) then
      buf1 := 'none';

    buf2 := '[Exits: ' + buf1 + ']';

    act(AT_YELLOW,buf2,false,ch,nil,nil,TO_CHAR);

    node := objects.head;

    while (node <> nil) do
      begin
      obj := node.element;

      if not IS_SET(obj.flags,OBJ_HIDDEN) then
        begin
        act_str:=obj.long+'.';
        if (obj.count>1) then
          act_str:=act_str+' [$4'+inttostr(obj.count)+'$7x]';
        act(AT_OBJ,act_str,false,ch,nil,nil,TO_CHAR);
        end;

      node := node.next;
      end;

    node := chars.head;
    while (node <> nil) do
      begin
      vict := node.element;

      if (vict <> ch) and (ch.CAN_SEE(vict)) then
        begin
        case (vict.position) of
          POS_SLEEPING: act_str := '$N is asleep here.';
          POS_MEDITATE: act_str := '$N is meditating here.';
           POS_RESTING: act_str := '$N is resting here.';
           POS_SITTING: act_str := '$N is sitting here.';
          POS_STANDING,
          POS_BACKSTAB: if (vict.IS_NPC) then
                          act_str := vict.long + '.'
                        else
                          act_str := '$N is here.';
           POS_CASTING: act_str := '$N is here, casting a spell.';
          POS_FIGHTING: act_str := '$N is here, fighting ' + playername(vict.fighting, ch) + '!';
            POS_BASHED: act_str := '$N is bashed to the ground.';
         POS_SEARCHING: act_str := '$N is here, searching for something.';
        end;

        if (IS_SET(vict.act_flags, ACT_FLYING)) then
          act_str := act_str + ' (Flying)';

        if (vict.IS_INVIS) then
          act_str := act_str + ' (Invis)';

        if (not vict.IS_NPC) and (IS_SET(vict.player^.flags, PLR_LINKLESS)) then
          act_str := act_str + ' (Linkless)';

        if (ch.IS_IMMORT) and (not vict.IS_NPC) and (IS_SET(vict.player^.flags, PLR_LOADED)) then
          act_str := act_str + ' (Loaded)';

        if (ch.IS_IMMORT) and (not vict.IS_NPC) and (vict.player^.switched <> nil) then
          act_str := act_str + ' (Switched: '+ vict.player^.switched.name + ')';

        if (not vict.IS_NPC) and (vict.IS_WIZINVIS) then
          act_str := act_str + ' (WizInvis: ' + inttostr(vict.player^.wiz_level) + ')';

        if (vict.IS_NPC) then
          act(AT_NPC,act_str,true,ch,nil,vict,TO_CHAR)
        else
          act(AT_PC,act_str,true,ch,nil,vict,TO_CHAR);
        end;

      node := node.next;
      end;
    end;

  ch.sendBuffer(ch.ansiColor(7));
end;

procedure do_inventory(ch:GCharacter;param:string);
var
   obj : GObject;
   node : GListNode;
begin
  act(AT_REPORT,'You are carrying: ',false,ch,nil,nil,TO_CHAR);

  if (ch.gold > 0) then
    act(AT_REPORT, '  $3' + inttostr(ch.gold) + '$7 coin(s).', false, ch, nil, nil, TO_CHAR);

  if (ch.objects.getSize = 0) and (ch.gold = 0) then
    act(AT_REPORT,'  nothing',false,ch,nil,nil,TO_CHAR)
  else
    begin
    node := ch.objects.head;

    while (node <> nil) do
      begin
      obj := node.element;

      if (obj.count > 1) then
        act(AT_REPORT, '  $p [' + inttostr(obj.count) + ']', false, ch, obj, nil, TO_CHAR)
      else
        act(AT_REPORT, '  $p', false, ch, obj, nil, TO_CHAR);

      node := node.next;
      end;
    end;
end;

function info_object(obj : GObject) : string;
var r : string;
begin
  r := '$B$7';
  
  if (IS_SET(obj.flags, OBJ_GLOW)) then
    r := r + '(Glowing) ';
  if (IS_SET(obj.flags, OBJ_HUM)) then
    r := r + '(Humming) ';

  info_object := r;
end;

procedure do_equipment(ch:GCharacter;param:string);
var a,cnt:word;
    r:string;
begin
  with ch do
    begin
    cnt:=0;
    act(AT_REPORT,'You are using:',false,ch,nil,nil,TO_CHAR);
    for a:=1 to MAX_WEAR do
      if Wear[a]<>nil then
        begin
          case a of
             16:r:='(floating ';
         17,18:r:='(held ';
          else r:='(worn ';
          end;
        r:=add_chars(30,r+eq_string[a]+')', ' ');
        act(AT_REPORT,r+' $p '+info_object(wear[a]),false,ch,wear[a],nil,TO_CHAR);
        inc(cnt);
        end;
    if cnt=0 then
      act(AT_REPORT,'nothing',false,ch,nil,nil,TO_CHAR);
    end;

  ch.sendBuffer(ch.ansiColor(7));
end;

procedure do_score(ch : GCharacter; param : string);
var buf1 : string;
    i:integer;
begin
  buf1 := ' $8[$4*$8]$3 ' + add_chars(70, '---- Your score ', '-') + ' $8[$4*$8]';
  act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);

  if (not ch.IS_NPC) and (not ch.IS_IMMORT) then
    begin
    act(AT_REPORT,#13#10'   $B$4'+ch.name+'$A$7, thou art known as $B$6'+ch.player^.rank+'$A$7 amongst'+
        ' thy $B$4'+ch.race.name+'$A$7 ancestors.'#13#10,false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'   Thou hast gained $B$3'+inttostr(ch.player^.xptot)+'$A$7 experience points'+
        ' and need $B$3'+inttostr(ch.player^.xptogo)+'$A$7 to level.',false,ch,nil,nil,TO_CHAR);
    end
  else
  if (ch.IS_IMMORT) then
    act(AT_REPORT,#13#10'   $B$4'+ch.name+'$A$7, thou art ranked as a $B$6'+IMM_Types[ch.level]+'$A$7 amongst thy fellow immortals.'#13#10,false,ch,nil,nil,TO_CHAR);

  if (not ch.IS_NPC) then
    act(AT_REPORT,'   Thou art $B$3'+inttostr(ch.getAge)+'$A$7 years of age ('+inttostr(ch.getPlayed div 60)+' hours).'#13#10,false,ch,nil,nil,TO_CHAR);

  act(AT_REPORT,'   Health:   $B$3'+pad_integer(ch.point.hp,5)+'$A$7/$B$3'+pad_integer(ch.point.max_hp,5)+
                '$A$7     Attack Power Bonus: $B$3'+pad_integer(ch.point.apb,4)+
                '$A$7     Total kills: $B$3'+inttostr(ch.kills),false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'   Stamina:  $B$3'+pad_integer(ch.point.mv,5)+'$A$7/$B$3'+pad_integer(ch.point.max_mv,5)+
                '$A$7     Hitroll:            $B$3'+pad_integer(ch.point.hitroll,4)+
                '$A$7     Alignment:   $B$3'+inttostr(ch.alignment),false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'   Mana:     $B$3'+pad_integer(ch.point.mana,5)+'$A$7/$B$3'+pad_integer(ch.point.max_mana,5)+
                '$A$7     Level:              $B$3'+pad_integer(ch.level,4)+
                '$A$7     Wimpy:       $B$3'+inttostr(ch.player^.wimpy)+#13#10,false,ch,nil,nil,TO_CHAR);

  if (ch.IS_IMMORT) and (ch.IS_WIZINVIS) then
    act(AT_REPORT,'   WizLevel: $B$3'+pad_integer(ch.player^.wiz_level,3)+#13#10,false,ch,nil,nil,TO_CHAR);

  if (not ch.IS_NPC) then
    act(AT_REPORT,'   Thou hast gained $B$3'+inttostr(ch.player^.bg_points)+'$A$7 battleground points.',false,ch,nil,nil,TO_CHAR);

  if (ch.getTrust > ch.level) then
    act(AT_REPORT,'   Thou art trusted by the gods at level '+inttostr(ch.getTrust)+'.',false,ch,nil,nil,TO_CHAR);

  { thx to Haus for the following lines - Grimlord }
  if (not ch.IS_NPC) then
    begin
    if (ch.player^.condition[COND_DRUNK]>10) then
      ch.sendBuffer('   Thou art drunk.'#13#10);

    if (ch.player^.condition[COND_THIRST]=0) then
      ch.sendBuffer('   Thou art dehydrating.'#13#10);

    if (ch.player^.condition[COND_FULL]=0) then
      ch.sendBuffer('   Thou art starving to death.'#13#10);
    end;

  if ch.position<>POS_SLEEPING then
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
                  inttostr(ch.player^.bankgold)+'$A$7 coins stored at a bank.',false,ch,nil,nil,TO_CHAR);

    i := (ch.carried_weight*10) div ((ch.ability.str div 2) + 10);

    if i<25 then
      buf1 := 'You are unburdened'
    else
    if i<50 then
      buf1 := 'No trouble carrying this'
    else
    if i<75 then
      buf1 := 'No problem yet'
    else
    if i<100 then
      buf1 := 'Heavy, but not unbearable'
    else
    if i<125 then
      buf1 := 'Quite heavy'
    else
    if i<150 then
      buf1 := 'You are slowed by this'
    else
    if i<175 then
      buf1 := 'VERY heavy'
    else
    if i<200 then
      buf1 := 'Almost unbearable'
    else
      buf1 := 'Unbearable';

    act(AT_REPORT,'   Thou art carrying a weight of $B$2'+inttostr(ch.carried_weight)+'$A$7 kg(s). ($B$7'+buf1+'$A$7)',false,ch,nil,nil,TO_CHAR);
    end;

  if (not ch.IS_NPC) and (ch.player^.clanleader) then
    act(AT_REPORT,'   Thou art the great leader of $B$3'+ch.clan.name+'$A$7.',false,ch,nil,nil,TO_CHAR)
  else
  if (ch.clan <> nil) then
    act(AT_REPORT,'   Thou art a proud member of $B$3'+ch.clan.name+'$A$7.',false,ch,nil,nil,TO_CHAR);

  (* if (not ch.IS_NPC) then
   if ch.player^.area_fname<>'' then
    act(AT_REPORT,'   Thou hast been assigned $B$7'+ch.player^.area_fname+'$A$7. '#13#10+
        '   Thee construction ranges art: '+inttostr(ch.player^.r_lo)+' '+inttostr(ch.player^.r_hi)+' '+
        inttostr(ch.player^.m_lo)+' '+inttostr(ch.player^.m_hi)+' '+
        inttostr(ch.player^.o_lo)+' '+inttostr(ch.player^.o_hi)+'.',false,ch,nil,nil,TO_CHAR); *)

  buf1 := #13#10' $8[$4*$8]$3 ' + add_chars(70, '', '-') + ' $8[$4*$8]';
  act(AT_REPORT, buf1, false, ch, nil, nil, TO_CHAR);
end;

procedure do_stats(ch:GCharacter;param:string);
var buf : string;
begin
  buf := 'Stats:'#13#10#13#10 +
         'Strength:       ' + inttostr(ch.ability.str) + #13#10 +
         'Constitution:   ' + inttostr(ch.ability.con) + #13#10 +
         'Dexterity:      ' + inttostr(ch.ability.dex) + #13#10 +
         'Intelligence:   ' + inttostr(ch.ability.int) + #13#10 +
         'Wisdom:         ' + inttostr(ch.ability.wis);

  act(AT_REPORT,buf,false,ch,nil,nil,TO_CHAR);
end;

{Jago 6/Jan/20001 : changed the format of WHO somewhat }
procedure do_who(ch:GCharacter;param:string);
var a:word;
    num, numImms :integer;
    buf1, buf2 : string;
    conn : GConnection;
    node : GListNode;
begin

  num := 0;
  numImms := 0;

  buf1 := add_chars(80, '$3--- Visible Mortals ', '-')  + #13#10 + #13#10;
  buf2 := add_chars(80, '$3--- Visible Immortals ', '-')  + #13#10 + #13#10;

  node := connection_list.head;

  while (node <> nil) do
    begin
    conn := node.element;

    if (conn.state = CON_PLAYING) and (ch.CAN_SEE(conn.ch)) and (ch.IS_SAME_ALIGN(conn.ch)) and (not conn.ch.IS_NPC) then
      begin
      inc(num);

      if (conn.ch.IS_IMMORT) then
      begin

        inc(numImms);

        if (conn.ch.clan <> nil) and (conn.ch.clan = ch.clan) then
          buf2 := buf2 + ' $B$7C $A$7<$B$6'
        else
          buf2 := buf2 +  '   <$B$6';

        buf2 := buf2 +  pad_string(imm_types[conn.ch.level],12) + '$A$7> ';

        if (conn.afk) then
          buf2 := buf2 + '$B$7<AFK> $A$7';

        buf2 := buf2 + conn.ch.name + ' ' + conn.ch.player^.title;

        buf2 := buf2 + #13#10;

      end
      else
        begin
        if (conn.ch.clan <> nil) and (conn.ch.clan = ch.clan) then
          buf1 := buf1 + ' $B$7C$A$7 <'
        else
          buf1 := buf1 + '   <';

        //change colour according to align .. dont *really* need to say "Good" or "Evil"
        if (conn.ch.alignment >= 0) then
          buf1 := buf1 + '$B$2'
        else
        if (conn.ch.alignment < 0) then
          buf1 := buf1 + '$B$4';

        buf1 := buf1 + IntToStr(conn.ch.level) + ' ' + pad_string_front(conn.ch.race.name, 12);

        buf1 := buf1 + '$A$7> ';

        if (conn.afk) then
          buf1 := buf1 + '$B$7<AFK> $A$7';

        buf1 := buf1 + conn.ch.name + ' ' + conn.ch.player^.title;

        buf1 := buf1 + #13#10;
        end;
      end;

    node := node.next;
    end;

  if (numImms > 0) then // any imms online?
  begin
    if (num - 1) = 0 then // no players online? only show imm list then
     buf1 := buf2
    else
  		buf1 := buf2 + #13#10 + buf1; // put IMMs FIRST! :)
  end;


  act(AT_REPORT,buf1,false,ch,nil,nil,TO_CHAR);

  act(AT_REPORT,#13#10'Currently '+inttostr(num)+' player(s) visible to you.',false,ch,nil,nil,TO_CHAR);
end;

procedure do_title(ch:GCharacter;param:string);
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Set title to what?'#13#10);
    exit;
    end;
  if (ch.IS_NPC) then
    begin
    ch.sendBuffer('NPCs cannot set title.'#13#10);
    exit;
    end;
  ch.player^.title := param;
end;

procedure do_group(ch:GCharacter;param:string);
var buf1 : string;
    vict : GCharacter;
    node : GListNode;
begin
  if (length(param)=0) then
    begin
    act(AT_REPORT,'Group leader: [$B$7' + ch.leader.name+'$A$7]',false,ch,nil,nil,TO_CHAR);
    ch.sendBuffer(#13#10'[Power of Char]  [Name]      [Health]  [Stamina]   [Xp2Lvl]'#13#10);

    node := char_list.head;

    while (node <> nil) do
      begin
      vict := node.element;

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

        buf1 := buf1 + '$B$4' + pad_string(hp_perc[UMin(round((vict.point.hp / vict.point.max_hp) * 5), 0)], 10);

        buf1 := buf1 + '$B$1' + pad_string(mv_perc[UMin(round((vict.point.mv / vict.point.max_mv) * 5), 0)], 12);

        if (not vict.IS_NPC) then
          buf1 := buf1 + inttostr(vict.player^.xptogo);

        act(AT_REPORT,buf1,false,ch,nil,nil,TO_CHAR);
        end;

      node := node.next;
      end;
    end
  else
  if (comparestr('all',param) = 0) then
    begin
    node := char_list.head;
    while (node <> nil) do
      begin
      vict := node.element;

      if (vict.master = ch) and (vict.leader <> ch) then
        begin
        vict.leader := ch;
        act(AT_REPORT,'$N joins $n''s group.',false,ch,nil,vict,TO_ROOM);
        to_group(ch, '$B$7[Group]: '+vict.name+' has joined the group!');
        end;

      node := node.next;
      end;
    ch.sendBuffer('Ok.'#13#10);
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

      node := char_list.head;

      while (node <> nil) do
        begin
        vict := node.element;

        if (vict.master = ch) and (vict.leader = ch) then
          begin
          act(AT_REPORT,'$n has disbanded the group and you follow no-one.',false,ch,nil,vict,TO_VICT);
          vict.master := nil;
          vict.leader := vict;
          end;

        node := node.next;
        end;
      end
    else
    if (vict.master <> ch) then
      ch.sendBuffer('One must first follow to get in a group.'#13#10)
    else
    if (vict.leader = ch) then
      begin
      to_group(ch, '$B$7[Group]: ' + vict.name + ' has left the group.');
      vict.leader := vict;
      end
    else
      begin
      vict.leader := ch;
      to_group(ch, '$B$7[Group]: '+vict.name+' has joined the group!');
      end;
    end;
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

      act(AT_REPORT,'$n no longer follows you.',false,ch,nil,ch.master,TO_VICT);
      ch.master := nil;

      if (ch.leader <> ch) then
        begin
        to_group(ch.leader, '$B$7[Group]: ' + ch.name + ' has left the group.');
        ch.leader := ch;
        end;
      end;
    end
  else
    begin
    ch.sendBuffer('You now follow ' + vict.name + '.'#13#10);

    act(AT_REPORT,'$n now follows you.',false,ch,nil,vict,TO_VICT);

    ch.master := vict;

    if (ch.leader <> ch) then
      begin
      to_group(ch.leader, '$B$7[Group]: ' + ch.name + ' has left the group.');
      ch.leader := ch;
      end;
    end;
end;

procedure do_ditch(ch:GCharacter;param:string);
var
   vict : GCharacter;
   node : GListNode;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Ditch whom?'#13#10);
    exit;
    end;

  if (comparestr(param, 'all') = 0) then
    begin
    node := ch.room.chars.head;

    while (node <> nil) do
      begin
      vict := node.element;

      if (vict.master = ch) then
        interpret(vict, 'follow self');

      node := node.next;
      end;

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
   node : GListNode;
   d : integer;
begin
  buf := 'You are in ' + ch.room.area.name + ', built by ' + ch.room.area.author + '.'#13#10#13#10'Players near:'#13#10;

  ch.sendBuffer(buf);

  d := -1;

  node := char_list.head;

  while (node <> nil) do
    begin
    vict := node.element;

    if (vict <> ch) and (not vict.IS_NPC) and (vict.room.area = ch.room.area) then
      begin
      buf := pad_string(vict.name,20) + '   ' + vict.room.name + #13#10;
      ch.sendBuffer(buf);
      inc(d);
      end;

    node := node.next;
    end;

  if (d = -1) then
   ch.sendBuffer('Nobody.'#13#10);
end;

procedure do_world(ch:GCharacter;param:string);
var
   buf : string;
begin
  buf := '$B$4Some world statistics:$A$7'#13#10#13#10 +
         'Open areas:        [$B$1' + pad_integer_front(area_list.getSize, 5) + '$A$7]'#13#10 +
         'Rooms explorable:  [$B$1' + pad_integer_front(room_list.getSize, 5) + '$A$7]'#13#10 +
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

    inc(dam1, ch.point.apb);

    dam1:=(dam1 * ch.ability.str) div 50;

    obj := vict.getWield(ITEM_WEAPON);

    if (obj = nil) then
      dam2 := 3
    else
      dam2 := obj.value[2]*obj.value[3];

    inc(dam2,vict.point.apb);

    dam2:=(dam2 * ch.ability.str) div 50;

    end1:=ch.point.hp;
    end2:=vict.point.hp;

    repeat
      dec(end1,dam2);
      dec(end2,dam1);
    until (end1<=0) or (end2<=0);

    proc1:=URange(0,(100*end1) div ch.point.hp,100);
    proc2:=URange(0,(100*end2) div vict.point.hp,100);

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
    list_first,list_last: GDLinkedList;
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
var g,h:integer;
    buf:string;
    node : GListNode;
    aff : GAffect;
begin
  h:=0;
  ch.sendBuffer('Current affects:'#13#10#13#10);

  node := ch.affects.head;

  while (node <> nil) do
    begin
    aff := node.element;

    with aff do
      begin
      buf := skill_table[sn].name + ', which will wear off';

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

    node := node.next;
    end;

  if h=0 then
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
  with ch.point do
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

procedure do_config(ch:GCharacter;param:string);
var s:string;
    d:integer;
    
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
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Current configuration:'#13#10#13#10);
    with ch.player^ do
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
      end;
    end
  else
    begin
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
      begin
      ch.sendBuffer('Unknown option.'#13#10);
      exit;
      end;
    with ch.player^ do
      begin
      if IS_SET(cfg_flags,d) then
        REMOVE_BIT(cfg_flags,d)
      else
        SET_BIT(cfg_flags,d);
      end;
    ch.sendBuffer('Option toggled.'#13#10);
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
  act(AT_REPORT,'Your trophy bandolier carries the following heads:'#13#10,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'$3[Lvl] [Name]                  [Times]',false,ch,nil,nil,TO_CHAR);

  for f:=1 to ch.player^.trophysize do
    act(AT_REPORT,'['+pad_integer(ch.player^.trophy[f].level,3)+
        '] '+pad_string(ch.player^.trophy[f].name,23)+' '+inttostr(ch.player^.trophy[f].times),false,ch,nil,nil,TO_CHAR);
end;

procedure do_socials(ch:GCharacter; param:string);
var social : GSocial;
    node : GListNode;
    line : string;
    i, count : integer;
begin
  count := 0;
  line := '';
  for i := 0 to socials.hashsize - 1 do
    begin
    node := socials.bucketList[i].head;

    while (node <> nil) do
      begin
      social := node.element;

      line := line + pad_string(lowercase(social.name), 13);

      inc(count);
      if (count = 6) then
        begin
        ch.sendBuffer(line + #13#10);
        count := 0;
        line := '';
        end;

      node := node.next;
      end;
    end;

  if (length(line) > 0) then
    ch.sendBuffer(line + #13#10);
end;

procedure do_alias(ch : GCharacter; param : string);
var
   node : GListNode;
   al : GAlias;
   count : integer;
   alname, alfill : string;
begin
  if (ch.IS_NPC) then
    begin
    ch.sendBuffer('You cannot do this.'#13#10);
    exit;
    end;

  alfill := one_argument(param, alname);

  if (length(alname) > 0) then
    begin
    al := nil;
    node := ch.player^.aliases.head;

    while (node <> nil) do
      begin
      if (GAlias(node.element).alias = param) then
        begin
        al := node.element;
        break;
        end;

      node := node.next;
      end;

    if (length(alfill) > 0) then
      begin
      if (al = nil) then
        begin
        al := GAlias.Create;

        al.expand := one_argument(param, al.alias);
        al.node := ch.player^.aliases.insertLast(al);

        ch.sendBuffer('Alias added.'#13#10);
        end
      else
        ch.sendBuffer('There is already an alias under that name.'#13#10);
      end
    else
      begin
      if (al = nil) then
        ch.sendBuffer('No such alias.'#13#10)
      else
        begin
        ch.player^.aliases.remove(al.node);
        al.Free;

        ch.sendBuffer('Alias removed.'#13#10);
        end;
      end;

    exit;
    end;

  if (ch.player^.aliases.getSize = 0) then
    begin
    ch.sendBuffer('No aliases.'#13#10);
    exit;
    end;

  node := ch.player^.aliases.head;
  count := 0;

  while (node <> nil) do
    begin
    al := node.element;

    ch.sendBuffer('[' + ch.ansiColor(3) + pad_integer(count, 2) + ch.ansiColor(7) + '] ' + pad_string(al.alias, 10) + ' -> ' + al.expand + #13#10);

    inc(count);

    node := node.next;
    end;
end;

procedure do_brag(ch : GCharacter; param : string);
begin
  act(AT_REPORT, 'You are level $B$6' + inttostr(ch.level) + '$A$7, $B$6' + ch.player^.rank + '$A$7 of the $B$6' + ch.race.name + '$A$7 race.', false, ch, nil, nil, TO_CHAR);
  act(AT_REPORT, '$n is level $B$6' + inttostr(ch.level) + '$A$7, $B$6' + ch.player^.rank + '$A$7 of the $B$6' + ch.race.name + '$A$7 race.', false, ch, nil, nil, TO_ROOM);

  act(AT_REPORT, 'You have $B$6' + inttostr(ch.player^.war_points) + '$A$7 warpoints, $B$6' + inttostr(ch.player^.quest_points) + '$A$7 questpoints and $B$6' + inttostr(ch.player^.bg_points) + '$A$7 battlepoints.', false, ch, nil, nil, TO_CHAR);
  act(AT_REPORT, '$n has $B$6' + inttostr(ch.player^.war_points) + '$A$7 warpoints, $B$6' + inttostr(ch.player^.quest_points) + '$A$7 questpoints and $B$6' + inttostr(ch.player^.bg_points) + '$A$7 battlepoints.', false, ch, nil, nil, TO_ROOM);

  act(AT_REPORT, 'You have $B$6' + inttostr(ch.point.max_hp) + '$A$7 max hitponts, $B$6' + inttostr(ch.point.max_mv) + '$A$7 max moves and $B$6' + inttostr(ch.point.max_mana) + '$A$7 max mana.', false, ch, nil, nil, TO_CHAR);
  act(AT_REPORT, '$n has $B$6' + inttostr(ch.point.max_hp) + '$A$7 max hitponts, $B$6' + inttostr(ch.point.max_mv) + '$A$7 max moves and $B$6' + inttostr(ch.point.max_mana) + '$A$7 max mana.', false, ch, nil, nil, TO_ROOM);
end;

{ Jago 7/Jan/2001}
procedure do_report(ch : GCharacter; param : string);
var
  hp, mana, mv : string;
  max_hp, max_mana, max_mv : string;
  sReport : string;
begin
  hp := IntToStr(ch.point.hp);
  max_hp := IntToStr(ch.point.max_hp);
  mana := IntToStr(ch.point.mana);
  max_mana := IntToStr(ch.point.max_mana);
  mv := IntToStr(ch.point.mv);
  max_mv := IntToStr(ch.point.max_mv);

  sReport := '"' + hp + '/' + max_hp + ' hp, ' +
             mana + '/' + max_mana + ' mana, ' +
             mv + '/' + max_mv + ' mv." ' + #13#10;

  act(AT_REPORT, 'You report: ' + sReport , false, ch, nil, nil,TO_CHAR);
  act(AT_REPORT, '$n reports: ' + sReport, false, ch, nil, nil, TO_ROOM);
end;

procedure do_taunt(ch : GCharacter; param : string);
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  TAUNT <line or NULL to reset>'#13#10);
    if (ch.player^.taunt <> '') then
      ch.sendBuffer('Currently: ' + ch.player^.taunt + #13#10);
    exit;
    end;

  if (uppercase(param) = 'NULL') then
    ch.player^.taunt := ''
  else
    ch.player^.taunt := param;

  ch.sendBuffer('Ok.'#13#10);
end;

{ Sets pagerlength - Nemesis }
procedure do_setpager(ch:GCharacter;param:string);
var value : integer;
begin
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

  ch.player^.pagerlen := value;
  act(AT_REPORT,'Pager set to ' + inttostr(value) + ' lines.',false,ch,nil,nil,TO_CHAR);
end;

{ shortcut command - Nemesis }
procedure do_autoloot(ch:GCharacter;param:string);
begin
  with ch.player^ do
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
  with ch.player^ do
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
  param := one_argument(param,arg1);
  one_argument(param,arg2);

  if (length(param) = 0) or ((length(arg1) > 0) and (length(arg2) = 0)) then
    ch.sendBuffer('Usage:  PASSWORD <old password> <new password>'#13#10)
  else
  if (not MD5Match(ch.player^.md5_password, MD5String(arg1))) then
    begin
    ch.sendBuffer('Your password did not match!'#13#10);
    exit;
    end
  else
    begin
    ch.player^.md5_password := MD5String(arg2);
    ch.save(ch.name);
    ch.sendBuffer('Ok, password changed.'#13#10);
    end;
end;

{ Last-login of player - Nemesis }
procedure do_last(ch:GCharacter;param:string);
var vict : GCharacter;
    s, g, arg, arg2, race, last_login : string;
    f : textfile;
    level : integer;
begin
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
    last_login := '';

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

        g := uppercase(stripl(s, ':'));

        if (g = 'LEVEL') then
          level := strtoint(striprbeg(s, ' '))
        else
        if (g = 'RACE') then
          race := striprbeg(s, ' ')
        else
        if (g = 'LAST-LOGIN') then
          last_login := striprbeg(s, ' ');

      until eof(f);

      closefile(f);

      if (uppercase(arg2) = 'INFO') then
        act(AT_REPORT,arg + ' is a level ' + inttostr(level) + ' ' + race + '.',false,ch,nil,nil,TO_CHAR);

      if (length(last_login) = 0) then
        act(AT_REPORT, arg + ' has been away too long to remember.', false, ch, nil, nil, TO_CHAR)
      else
        act(AT_REPORT,arg + ' was last on at: ' + last_login + '.',false,ch,nil,nil,TO_CHAR);
      end;
    end;
end;
