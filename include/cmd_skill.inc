procedure do_bash(ch:GCharacter;param:string);
var chance:integer;
    vict:GCharacter;
begin
  if (ch.learned[gsn_bash] = 0) then
    begin
    ch.sendBuffer('You don''t know how to bash!'#13#10);
    exit;
    end;

  if (length(param) = 0) and (ch.position <> POS_FIGHTING) then
    begin
    act(AT_REPORT,'Bash whom?',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  if (ch.position = POS_BASHED) then
    begin
    ch.sendBuffer('You are bashed and cannot move!'#13#10);
    exit;
    end;

  if (ch.bash_timer > -2) then
    begin
    act(AT_REPORT,'You are still too off-balance from that last bash.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  if (ch.bashing > -2) then
    begin
    act(AT_REPORT,'You cannot bash this soon after a bash!',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  vict := ch.room.findChar(ch, param);

  if (vict = nil) then
   if (ch.position = POS_FIGHTING) and (ch.fighting <> nil) then
    vict := ch.fighting;

  if (vict = nil) then
    ch.sendBuffer('They aren''t here.'#13#10)
  else
  if not in_melee(ch,vict) then
    begin
    act(AT_REPORT,'You aren''t on the front lines of that battle!',false,ch,nil,nil,TO_CHAR);
    exit;
    end
  else
  if (vict = ch) then
    begin
    ch.sendBuffer('You try to bash yourself and fall to the ground!'#13#10);
    act(AT_REPORT,'$n looks silly as $e tries to bash $mself.',false,ch,nil,nil,TO_ROOM);
    end
  else
  if (vict.IS_NPC) and (IS_SET(vict.act_flags, ACT_SPIRIT) or IS_SET(vict.act_flags,ACT_NOBASH)) then
    ch.sendBuffer('You can''t bash that kind of creature!'#13#10)
  else
   with ch do
    begin
    if fighting=nil then
      begin
      if IS_SET(ch.room.flags,ROOM_SAFE) then
        begin
        ch.sendBuffer('A strange force prevents you from attacking.'#13#10);
        exit;
        end
      else
        begin
        fighting:=vict;

        if (not ch.IS_NPC) then
          player^.fightxp:=0;
        end;
      end;
    chance:=ch.learned[gsn_bash];
    if (vict.bash_timer>0) then
      act(AT_REPORT,'$N is already bashed to the ground!',false,ch,nil,vict,TO_CHAR)
    else
    if (vict.bash_timer>-2) then
      act(AT_REPORT,'$N is still alert from the last bash.',false,ch,nil,vict,TO_CHAR)
    else
    if number_percent<=chance then
      begin
      improve_skill(ch,gsn_bash);
      vict.position:=POS_BASHED;
      position:=POS_FIGHTING;
      vict.bash_timer:=6;
      bashing:=6;
      if vict.fighting=nil then
        vict.fighting:=ch;
      act(AT_GREEN,'Your powerful bash sends $N sprawling to the ground!',false,ch,nil,vict,TO_CHAR);
      act(AT_GREEN,'$n sends $N sprawling to the ground with a powerful bash!',false,ch,nil,vict,TO_ROOM);
      end
    else
      begin
      ch.setWait(8);

      act(AT_REPORT,'You miss the bash and almost fall over!',false,ch,nil,nil,TO_CHAR);
      act(AT_REPORT,'$n misses a bash at $N and almost falls over!',false,ch,nil,vict,TO_ROOM);
      position:=POS_FIGHTING;
      vict.position:=POS_FIGHTING;
      if vict.fighting=nil then
        vict.fighting:=ch;
      end;
    end;
end;

procedure do_kick(ch:GCharacter;param:string);
var dam,chance:integer;
    vict:GCharacter;
begin
  if (ch.learned[gsn_kick] = 0) then
    begin
    ch.sendBuffer('You don''t know how to kick!'#13#10);
    exit;
    end;

  if (length(param)=0) and (ch.position<>POS_FIGHTING) then
    begin
    act(AT_REPORT,'Kick whom?',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  if (ch.position = POS_BASHED) then
    begin
    ch.sendBuffer('You are bashed and cannot move!'#13#10);
    exit;
    end;

  if (ch.bash_timer > -2) then
    begin
    act(AT_REPORT,'You are still too off-balance from that last bash.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  if (ch.bashing > -2) then
    begin
    act(AT_REPORT,'You cannot kick this soon after a bash!',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  vict := ch.room.findChar(ch, param);

  if (vict = nil) then
   if (ch.position=POS_FIGHTING) and (ch.fighting<>nil) then
    vict:=ch.fighting;

  if (vict = nil) then
    act(AT_REPORT,'They aren''t here.',false,ch,nil,nil,TO_CHAR)
  else
  if not in_melee(ch,vict) then
    begin
    act(AT_REPORT,'You cannot reach $N!',false,ch,nil,vict,TO_CHAR);
    exit;
    end
  else
  if (vict = ch) then
    ch.sendBuffer('Painfully, you force your knee to bend in a way it isn''t supposed to.'#13#10)
  else
   with ch do
    begin
    if point.mv<12 then
      begin
      ch.sendBuffer('You don''t have enough energy to kick.'#13#10);
      exit;
      end;

    if (vict.CHAR_DIED) then
      exit;

    if fighting=nil then
      begin
      if IS_SET(ch.room.flags,ROOM_SAFE) then
        begin
        ch.sendBuffer('A strange force prevents you from attacking.'#13#10);
        exit;
        end
      else
        begin
        fighting:=vict;

        if (not ch.IS_NPC) then
          player^.fightxp:=0;
        end;
      end;

    ch.setWait(8);

    chance:=ch.learned[gsn_kick];
    if (vict.IS_NPC) and (IS_SET(vict.act_flags,ACT_SPIRIT)) then
      begin
      ch.sendBuffer('You swing your leg and kick high, but it goes right through your victim!'#13#10);

      if vict.fighting=nil then
        vict.fighting:=ch;

      position:=POS_FIGHTING;
      vict.position:=POS_FIGHTING;
      end
    else
    if number_percent<=chance then
      begin
      improve_skill(ch,gsn_kick);
      dam:=urange(1,rolldice(4,18),level div 6)*3;
      inc(dam,ch.point.apb);
      dam:=(dam*ch.ability.str) div 50;
      damage(ch,ch.fighting,dam,gsn_kick);
      end
    else
      damage(ch,ch.fighting,0,gsn_kick);
    end;
end;

procedure do_fly(ch:GCharacter;param:string);
begin
  if (ch.IS_FLYING) then
    ch.stopFlying
  else
    ch.startFlying;
end;

procedure do_sneak(ch:GCharacter;param:string);
begin
  if IS_SET(ch.aff_flags,AFF_SNEAK) then
    begin
    ch.sendBuffer('You no longer sneak.'#13#10);
    REMOVE_BIT(ch.aff_flags,AFF_SNEAK);
    end
  else
    begin
    ch.sendBuffer('You attempt to move silently.'#13#10);
    SET_BIT(ch.aff_flags,AFF_SNEAK);
    end;
end;

procedure do_spells(ch:GCharacter;param:string);
var a:integer;
begin
  with ch do
    begin
    act(AT_REPORT,'Spells learned:'#13#10,false,ch,nil,nil,TO_CHAR);
    for a:=0 to MAX_SKILLS-1 do
     if learned[a]>0 then
      with skill_table[a] do
       if skill_type=SKILL_SPELL then
        act(AT_REPORT,pad_integer(min_mana,2)+'Ma    '+name+' ('+inttostr(learned[a])+'%)',false,ch,nil,nil,TO_CHAR);
    end;
end;

procedure do_skills(ch:GCharacter;param:string);
var a:integer;
begin
  with ch do
    begin
    act(AT_REPORT,'Skills learned:'#13#10,false,ch,nil,nil,TO_CHAR);
    for a:=0 to MAX_SKILLS-1 do
     if learned[a]>0 then
      with skill_table[a] do
       if skill_type<>SKILL_SPELL then
        act(AT_REPORT,'        '+name+' ('+inttostr(learned[a])+'%)',false,ch,nil,nil,TO_CHAR);
    end;
end;

procedure do_learn(ch:GCharacter;param:string);
var sn:integer;
    node : GListNode;
    vict,learn:GCharacter;
begin
  learn := nil;
  node := ch.room.chars.head;

  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.IS_NPC) and (vict.IS_LEARNER) then
      begin
      learn := vict;
      break;
      end;

    node := node.next;
    end;

  if (learn=nil) then
    begin
    ch.sendBuffer('You cannot learn anything here!'#13#10);
    exit;
    end
  else
  if (length(param)=0) then
    begin
    ch.sendBuffer('Skills you can learn here:'#13#10#13#10);

    for sn := 0 to MAX_SKILLS - 1 do
      begin
      if (vict.learned[sn] > 0) then
        ch.sendBuffer(skill_table[sn].name + #13#10);
      end;
    end
  else
    begin
    sn := findSkill(param);

    if (sn = -1) or (vict.learned[sn] = 0) then
      act(AT_REPORT, '$N doesn''t teach this skill.',false,ch,nil,vict,TO_CHAR)
    else
      begin
      if (ch.learned[sn] = 0) then
        begin
        if skill_table[sn].min_lvl<=ch.level then
          begin
          act(AT_REPORT,'You learn '+cap(skill_table[sn].name)+'.',false,ch,nil,nil,TO_CHAR);
          ch.learned[sn]:=20;
          end
        else
          ch.sendBuffer('You have not yet reached the appropiate level.'#13#10);
        end
      else
        act(AT_REPORT,'You have already learned that skill.',false,ch,nil,nil,TO_CHAR);
      end;
    end;
end;

procedure do_practice(ch:GCharacter;param:string);
var sn:integer;
    vict,learn:GCharacter;
    node : GListNode;
begin
  learn := nil;
  node := ch.room.chars.head;

  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.IS_NPC) and (vict.IS_LEARNER) then
      begin
      learn := vict;
      break;
      end;

    node := node.next;
    end;

  if (learn=nil) then
    begin
    ch.sendBuffer('You cannot practice anything here!'#13#10);
    exit;
    end
  else
  if (length(param)=0) then
    begin
    ch.sendBuffer('Skills you can learn here:'#13#10#13#10);

    for sn := 0 to MAX_SKILLS - 1 do
      begin
      if (vict.learned[sn] > 0) then
        ch.sendBuffer(skill_table[sn].name + #13#10);
      end;
    end
  else
    begin
    sn := findSkillPlayer(ch,param);

    if (sn <> -1) then
      begin
      if (vict.learned[sn] = 0) then
        act(AT_REPORT, '$N doesn''t teach this skill.', false, ch, nil, vict, TO_CHAR)
      else
      if ch.learned[sn]<50 then
        begin
        inc(ch.learned[sn],8);
        if (ch.learned[sn]>50) then
          begin
          ch.learned[sn]:=50;
          act(AT_REPORT,'You now know enough about '+cap(skill_table[sn].name)+'.',false,ch,nil,nil,TO_CHAR);
          end
        else
          act(AT_REPORT,'You practice '+cap(skill_table[sn].name)+'.',false,ch,nil,nil,TO_CHAR);
        end
      else
        act(AT_REPORT,'You have practiced this skill enough.',false,ch,nil,nil,TO_CHAR);
      end
    else
      act(AT_REPORT,'You have not learned this skill!',false,ch,nil,nil,TO_CHAR);
    end;
end;

procedure search_timer(ch,victim:GCharacter;sn:integer);
var pexit : GExit;
    node : GListNode;
begin
  ch.position := POS_STANDING;
  
  if skill_success(ch,sn) then
    begin
    { check for hidden exits first }
    node := ch.room.exits.head;

    while (node <> nil) do
      begin
      pexit := node.element;

      if (IS_SET(pexit.flags, EX_SECRET)) and (IS_SET(pexit.flags, EX_ISDOOR)) then
        begin
        if (length(pexit.keyword) > 0) then
          act(AT_REPORT,'You uncover a $d!',false,ch,nil,pexit,TO_CHAR)
        else
          act(AT_REPORT,'You uncover a secret passage '+headings[pexit.direction]+'!',false,ch,nil,nil,TO_CHAR);

        REMOVE_BIT(pexit.flags, EX_SECRET);
        exit;
        end;

      node := node.next;
      end;

    ch.sendBuffer('You look around, but find nothing.'#13#10);
    end
  else
    ch.sendBuffer('You look around, but find nothing.'#13#10);
end;

procedure do_search(ch:GCharacter;param:string);
begin
  ch.sendBuffer('You start searching...'#13#10);

  act(AT_REPORT,'$n looks around, searching for something...',false,ch,nil,nil,TO_ROOM);

  ch.position := POS_SEARCHING;

  addTimer(ch,nil,TIMER_SEARCH,search_timer,gsn_searching,6);
end;

procedure backstab_timer(ch,victim:GCharacter;sn:integer);
var roll,to_hit:integer;
    dam:integer;
    wield : GObject;
begin
  if (victim.CHAR_DIED) or (victim.room <> ch.room) or (not ch.CAN_SEE(victim)) then
    begin
    ch.sendBuffer('They are not here.'#13#10);
    ch.position:=POS_STANDING;
    exit;
    end;

  wield := ch.getWield(ITEM_WEAPON);

  to_hit:=ch.point.hitroll + 10;             { +10 bonus because of backstab }

  dec(to_hit,victim.point.ac);
  inc(to_hit,(ch.learned[sn]-50) div 5);
  roll:=rolldice(1,100);
  
  if (roll<=to_hit) and (wield<>nil) then
    begin
    dam:=URange(1,rolldice(wield.value[2],wield.value[3])*(2+ch.level div 15),350);
    act(AT_REPORT,'Your weapon finds its point in $N''s back, causing $S body to spasm.',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'Before you know what happens, $n places $s weapon in your back!',false,ch,nil,victim,TO_VICT);
    act(AT_REPORT,'$n sneaks up behind $N''s back and places $s weapon into $S''s back.',false,ch,nil,victim,TO_NOTVICT);
    if (dam<=25) then
      begin
      act(AT_REPORT,'$N grimaces in pain as your blade pierces $S flesh.',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'You grimace in pain as $n''s blade pierces your flesh.',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'$N grimaces in pain as $n''s blade pierces $S flesh.',false,ch,nil,victim,TO_NOTVICT);
      end
    else
    if (dam<=50) then
      begin
      act(AT_REPORT,'$N winces in agony as you stab $M in the back.',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'You wince in agony as $n stabs you in the back.',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'$N winces in agony as $n stabs $M in the back.',false,ch,nil,victim,TO_NOTVICT);
      end
    else
    if (dam<=75) then
      begin
      act(AT_REPORT,'As you find a lung and pierce hard, $N cries out in pain!',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'You cry out in pain as $n pierces your lung!',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'$N cries out in pain as $n pierces $S lung!',false,ch,nil,victim,TO_NOTVICT);
      end
    else
    if (dam<=100) then
      begin
      act(AT_REPORT,'$N spasms in terrible pain as you plunge your blade into $M.',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'You feel a terrible pain as $n plunges $s blade into you!',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'$N spasms in terrible pain as $n plunges $s blade into $M.',false,ch,nil,victim,TO_NOTVICT);
      end
    else
    if (dam<=150) then
      begin
      act(AT_REPORT,'Blood runs over your hands as you forcefully stab $N!',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'You bleed hard as you are forcefully stabbed by $n!',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'Blood runs over $n''s hands as $e forcefully stabs $N!',false,ch,nil,victim,TO_NOTVICT);
      end
    else
    if (dam<=200) then
      begin
      act(AT_REPORT,'As you pierce $N''s back, you twist your weapon multiple times!',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'$n pierces your back and twists $s blade multiple times!',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'$n pierces $N''s back and twists $s blade multiple times!',false,ch,nil,victim,TO_NOTVICT);
      end
    else
    if (dam<=350) then
      begin
      act(AT_REPORT,'You find a mark in $N''s spine and thrust your blade through!',false,ch,nil,victim,TO_CHAR);
      act(AT_REPORT,'$n targets your spine and thrusts $s blade through!',false,ch,nil,victim,TO_VICT);
      act(AT_REPORT,'$n finds a mark in $N''s spine and thrusts $s blade through!',false,ch,nil,victim,TO_NOTVICT);
      end;
    damage(ch,victim,dam,sn);
    victim.fighting:=ch;
    end
  else
    begin
    act(AT_REPORT,'As you attempt to sneak behind $N''s back, you are uncovered!',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'$n failed to backstab $N!', false,ch,nil,victim,TO_ROOM);
    damage(ch,victim,0,sn);
    victim.fighting:=ch;
    end;
end;

procedure do_backstab(ch:GCharacter;param:string);
var victim:GCharacter;
    wield:GObject;
begin
  if (ch.learned[gsn_backstab] = 0) then
    begin
    ch.sendBuffer('You don''t know how to backstab!'#13#10);
    exit;
    end;

  if (length(param)=0) then
    begin
    ch.sendBuffer('Backstab whom?'#13#10);
    exit;
    end;

  if (ch.position=POS_FIGHTING) then
    begin
    ch.sendBuffer('You cannot backstab while fighting!'#13#10);
    exit;
    end;

  victim := ch.room.findChar(ch, param);

  if (victim=nil) then
    begin
    ch.sendBuffer('They are not here.'#13#10);
    exit;
    end
  else
  if (victim=ch) then
    begin
    ch.sendBuffer('How would you sneak upon yourself?'#13#10);
    exit;
    end;

  wield := ch.getWield(ITEM_WEAPON);

  if (wield=nil) or not (wield.value[4] in [FG_PIERCE,FG_STAB]) then
    begin
    ch.sendBuffer('You must wield a piercing or stabbing weapon.'#13#10);
    exit;
    end;

  ch.sendBuffer('You move stealthily, attempting to get behind your target...'#13#10);
  addTimer(ch,victim,TIMER_BACKSTAB,backstab_timer,gsn_backstab,8);
  ch.position:=POS_BACKSTAB;
end;

procedure circle_timer(ch,victim:GCharacter;sn:integer);
begin
  if (victim.CHAR_DIED) or (victim.room<>ch.room) then
    begin
    ch.sendBuffer('They are not here.'#13#10);
    ch.position:=POS_STANDING;
    exit;
    end;
  ch.position:=POS_FIGHTING;
  if (number_percent<=ch.learned[sn]) then
    begin
    act(AT_REPORT,'You succeed in circling your opponent and find yourself behind $M.',false,ch,nil,victim,TO_CHAR);
    backstab_timer(ch,victim,gsn_backstab);
    end
  else
    act(AT_REPORT,'You failed to circle.',false,ch,nil,nil,TO_CHAR);
end;

procedure do_circle(ch:GCharacter;param:string);
begin
  if (ch.learned[gsn_circle] = 0) then
    begin
    ch.sendBuffer('You don''t know how to circle!'#13#10);
    exit;
    end;

  if (ch.position<>POS_FIGHTING) then
    begin
    ch.sendBuffer('You are not fighting!'#13#10);
    exit;
    end;

  if (ch.fighting.fighting=ch) then
    begin
    ch.sendBuffer('You are on the frontline and can not circle!'#13#10);
    exit;
    end;

  act(AT_REPORT,'You attempt to circle behind your target...',false,ch,nil,nil,TO_CHAR);
  addTimer(ch,ch.fighting,TIMER_CIRCLE,circle_timer,gsn_circle,10);
  ch.position:=POS_CIRCLE;
end;

procedure do_rescue(ch:GCharacter;param:string);
var victim:GCharacter;
begin
  if (ch.learned[gsn_rescue] = 0) then
    begin
    ch.sendBuffer('You don''t know how to rescue!'#13#10);
    exit;
    end;

  if (length(param) = 0) then
    begin
    ch.sendBuffer('Rescue whom?'#13#10);
    exit;
    end;

  if (ch.position=POS_FIGHTING) and (ch.fighting.fighting=ch) then
    begin
    ch.sendBuffer('You are on the frontline and can not rescue!'#13#10);
    exit;
    end;

  victim := ch.room.findChar(ch, param);

  if (victim = nil) then
    begin
    ch.sendBuffer('That is not here!'#13#10);
    exit;
    end;

  if (number_percent <= ch.learned[gsn_rescue]) then
    begin
    act(AT_REPORT,'You rescue $N!',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'$N rescues $n!',false,victim,nil,ch,TO_NOTVICT);

    if (ch.position <> POS_FIGHTING) then
      begin
      ch.fighting := victim.fighting;
      ch.position := POS_FIGHTING;
      end;

    ch.fighting.fighting := ch;
    victim.fighting := nil;
    victim.position := POS_STANDING;
    end
  else
    begin
    act(AT_REPORT,'Your rescue attempt failed.',false,ch,nil,nil,TO_CHAR);

    ch.setWait(3);
    end;
end;

procedure track_timer(ch,victim:GCharacter;sn:integer);
var
   node : GListNode;
   track : GTrack;
begin
  if (not skill_success(ch, gsn_track)) then
    begin
    ch.sendBuffer('You can''t seem to find any tracks.'#13#10);
    exit;
    end;

  node := ch.room.tracks.head;
  track := nil;

  while (node <> nil) do
    begin
    if (GTrack(node.element).who = ch.tracking) and ((track = nil) or (track.life < GTrack(node.element).life)) then
      track := node.element;

    node := node.next;
    end;

  if (track = nil) then
    begin
    if (victim = nil) then
      begin
      ch.sendBuffer('The tracks seem to end here.'#13#10);
      ch.tracking := '';
      end
    else
      ch.sendBuffer('You can''t seem to find any tracks.'#13#10)
    end
  else
    begin
    ch.sendBuffer('You see some tracks heading ' + headings[track.direction] + '!'#13#10);
    end;
end;

procedure do_track(ch : GCharacter; param : string);
var
   vict : GCharacter;
begin
  vict := nil;
  
  if (ch.learned[gsn_track] = 0) then
    begin
    ch.sendBuffer('You don''t know how to track!'#13#10);
    exit;
    end;

  if (length(param) = 0) then
    begin
    if (ch.tracking = '') then
      begin
      ch.sendBuffer('Track whom?'#13#10);
      exit;
      end;
    end
  else
    begin
    vict := findCharWorld(ch, param);

    if (vict = ch) then
      begin
      ch.sendBuffer('You stop looking for tracks.'#13#10);
      ch.tracking := '';
      exit;
      end;
    end;

  act(AT_REPORT,'You begin to look for tracks...',false,ch,nil,nil,TO_CHAR);

  if (vict <> nil) then
    ch.tracking := vict.name;

  addTimer(ch, vict, TIMER_TRACK, track_timer, gsn_track, 4);
end;
