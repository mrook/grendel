// $Id: cmd_skill.inc,v 1.2 2002/08/14 18:15:03 ***REMOVED*** Exp $

procedure do_bash(ch:GCharacter;param:string);
var chance:integer;
    vict:GCharacter;
begin
  if (ch.LEARNED(gsn_bash) = 0) then
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
  if (vict.IS_NPC) and (IS_SET(GNPC(vict).act_flags, ACT_SPIRIT) or IS_SET(GNPC(vict).act_flags, ACT_NOBASH)) then
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
          GPlayer(ch).fightxp:=0;
        end;
      end;

    chance := ch.LEARNED(gsn_bash);

    if (vict.bash_timer>0) then
      act(AT_REPORT,'$N is already bashed to the ground!',false,ch,nil,vict,TO_CHAR)
    else
    if (vict.bash_timer>-2) then
      act(AT_REPORT,'$N is still alert from the last bash.',false,ch,nil,vict,TO_CHAR)
    else
    if (number_percent <= chance) then
      begin
      // improve_skill(ch,gsn_bash);

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
  if (ch.LEARNED(gsn_kick) = 0) then
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
    if mv<12 then
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
          GPlayer(ch).fightxp:=0;
        end;
      end;

    ch.setWait(8);

    chance := ch.LEARNED(gsn_kick);

    if (vict.IS_NPC) and (IS_SET(GNPC(vict).act_flags, ACT_SPIRIT)) then
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
      //improve_skill(ch,gsn_kick);

      dam:=urange(1,rolldice(4,18),level div 6)*3;
      inc(dam,ch.apb);
      dam:=(dam*ch.str) div 50;

      damage(ch,ch.fighting,dam, integer(gsn_kick));
      end
    else
      damage(ch,ch.fighting,0, integer(gsn_kick));
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

procedure do_spells(ch : GCharacter; param : string);
var
  a, targ : integer;
  buf : string;
  node : GListNode;
  g : GLearned;
  arr : array[TARGET_OFF_ATTACK..TARGET_OBJECT] of
    record
      num : integer;
      str : string;
    end;
begin
  for a := TARGET_OFF_ATTACK to TARGET_OBJECT do
  begin
    arr[a].num := 0;
    arr[a].str := '';
  end;

  arr[TARGET_OFF_ATTACK].str :=  add_chars(88, '$A$3--- $B$7[Offensive spells]$A$3 -', '-') + '$A$7'#13#10;
  arr[TARGET_OFF_AREA].str := add_chars(88, '$A$3--- $B$7[Offensive area spells]$A$3 -', '-') + '$A$7'#13#10;
  arr[TARGET_DEF_SELF].str := add_chars(88, '$A$3--- $B$7[Self-only spells]$A$3 -', '-') + '$A$7'#13#10;
  arr[TARGET_DEF_SINGLE].str := add_chars(88, '$A$3--- $B$7[Defensive spells]$A$3 -', '-') + '$A$7'#13#10;
  arr[TARGET_DEF_AREA].str := add_chars(88, '$A$3--- $B$7[Defensive area spells]$A$3 -', '-') + '$A$7'#13#10;
  arr[TARGET_DEF_WORLD].str := add_chars(88, '$A$3--- $B$7[World spells]$A$3 -', '-') + '$A$7'#13#10;
  arr[TARGET_OBJECT].str := add_chars(88, '$A$3--- $B$7[Object spells]$A$3 -', '-') + '$A$7'#13#10;

  with ch do
    begin
    node := skills_learned.head;

    while (node <> nil) do
      begin
      g := node.element;

      if (GSkill(g.skill).skill_type = SKILL_SPELL) then
        for targ := TARGET_OFF_ATTACK to TARGET_OBJECT do
          begin
          if (GSkill(g.skill).target = targ) then
            with arr[targ] do
              begin
              inc(num);

              if (odd(num)) then
                str := str + Format('%25s %3dMa %3d%%', [GSkill(g.skill).name^, GSkill(g.skill).min_mana, g.perc]) + '    '
              else
                str := str + Format('%-25s %3dMa %3d%%', [GSkill(g.skill).name^, GSkill(g.skill).min_mana, g.perc]) + #13#10;
              end;
          end;

      node := node.next;
      end;
    end;

  buf := act_string(add_chars(80, '$A$3---- Known spells -', '-') + #13#10 + #13#10, ch, nil, nil, nil);

  for a := TARGET_OFF_ATTACK to TARGET_OBJECT do
    begin
    if (arr[a].num <> 0) then
      begin
      if odd(arr[a].num) then
        buf := buf + act_string(arr[a].str + #13#10#13#10, ch, nil, nil, nil)
      else
        buf := buf + act_string(arr[a].str + #13#10, ch, nil, nil, nil);
      end;
    end;

  if (not ch.IS_NPC()) then
    buf := buf + act_string('$A$7    Spellslots available: $B$7' + inttostr(GPlayer(ch).max_spells - GPlayer(ch).getUsedSpellslots()) + '$A$7'#13#10#13#10, ch, nil, nil, nil);
    
  delete(buf, length(buf) - 2, 2);
  ch.sendPager(buf);
end;

procedure do_skills(ch : GCharacter; param : string);
var
  a : integer;
  buf : string;
  g : GLearned;
  node : GListNode;
begin
  buf := '';

  with ch do
  begin
    ch.sendPager(act_string(add_chars(80, '$A$3---- Known skills -', '-') + '$A$7'#13#10#13#10, ch, nil, nil, nil));

    a := 0;
    node := ch.skills_learned.head;

    while (node <> nil) do
      begin
      g := node.element;

      if (GSkill(g.skill).skill_type <> SKILL_SPELL) then
        begin
        inc(a);
      
        if (odd(a)) then
          buf := buf + Format('%25s  %3d%%', [GSkill(g.skill).name^, g.perc]) + '    '
        else
          buf := buf + Format('%-25s  %3d%%', [GSkill(g.skill).name^, g.perc]) + #13#10;
        end;

      node := node.next;
      end;

    if (odd(a)) then
      buf := buf + #13#10;

    if (not ch.IS_NPC()) then
      buf := buf + act_string(#13#10'$A$7    Skillslots available: $B$7' + inttostr(GPlayer(ch).max_skills - GPlayer(ch).getUsedSkillslots()) + '$A$7'#13#10, ch, nil, nil, nil);

    ch.sendPager(act_string(buf, ch, nil, nil, nil));
  end;

end;

procedure do_learn(ch:GCharacter;param:string);
var sn : GSkill;
    node : GListNode;
    g : GLearned;
    vict,learn:GCharacter;
begin
  vict := nil;
  learn := nil;

  if (ch.IS_NPC()) then
  begin
    ch.sendBuffer('This command doesn''t work for mobs.'#13#10);
    exit;
  end;

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

    node := vict.skills_learned.head;

    while (node <> nil) do
      begin
      g := node.element;

//      if (ch.LEARNED(g.skill) = 0) then
      if ((ch.level >= GSkill(g.skill).min_lvl) and (ch.LEARNED(g.skill) = 0)) then
        act(AT_REPORT, '  (Level $B$4' + pad_integer_front(GSkill(g.skill).min_lvl, 3) + '$A$7) ' + GSkill(g.skill).name^, false, ch, nil, nil, TO_CHAR);

      node := node.next;
      end;
    end
  else
    begin
    sn := findSkill(param);

    if (sn = nil) or (vict.LEARNED(sn) = 0) then
      act(AT_REPORT, '$N doesn''t teach this skill.',false,ch,nil,vict,TO_CHAR)
    else
      if ((sn.skill_type <> SKILL_SPELL) and (GPlayer(ch).max_skills - GPlayer(ch).getUsedSkillslots() <= 0)) then
        act(AT_REPORT, 'You have no more free skillslots!', false, ch, nil, nil, TO_CHAR)
      else
      if ((sn.skill_type = SKILL_SPELL) and (GPlayer(ch).max_spells - GPlayer(ch).getUsedSpellslots() <= 0)) then
        act(AT_REPORT, 'You have no more free spellslots!', false, ch, nil, nil, TO_CHAR)
      else
{    if (sn.skill_type = SKILL_SPELL) and (ch.skills_learned.getSize() = ch.race.max_spells) then
      act(AT_REPORT, 'You have reached the maximum number of spells for your race.', false, ch, nil, nil, TO_CHAR)
    else
    if (sn.skill_type = SKILL_SKILL) and (ch.skills_learned.getSize() = ch.race.max_skills) then
      act(AT_REPORT, 'You have reached the maximum number of spells for your race.', false, ch, nil, nil, TO_CHAR)
    else }
      begin
      if (ch.LEARNED(sn) = 0) then
        begin
        if (sn.min_lvl > ch.level) then
          ch.sendBuffer('You have not yet reached the appropiate level.'#13#10)
        else
          begin
          node := sn.prereqs.head;

          while (node <> nil) do
            begin
            if (ch.LEARNED(node.element) < 50) then
              begin
              ch.sendBuffer('You need to have sufficient knowledge of ' + GSkill(node.element).name^ + ' first.'#13#10);
              exit;
              end;

            node := node.next;
            end;

          act(AT_REPORT,'You learn ' + cap(sn.name^) + '.',false,ch,nil,nil,TO_CHAR);

          ch.SET_LEARNED(20, sn);
          end;
        end
      else
        act(AT_REPORT,'You have already learned that skill.',false,ch,nil,nil,TO_CHAR);
      end;
    end;
end;

procedure do_unlearn(ch:GCharacter;param:string);
var
   sn : GSkill;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('UNLEARN <skill or spell to unlearn>'#13#10#13#10);
    ch.sendBuffer('This is irreversible, and you won''t get any practice sessions back.'#13#10);
    exit;
    end;

  sn := findSkill(param);

  if (sn = nil) or (ch.LEARNED(sn) = 0) then
    act(AT_REPORT, 'You haven''t learned this skill.',false,ch,nil,nil,TO_CHAR)
  else
    begin
    ch.SET_LEARNED(0, sn);
    act(AT_REPORT, 'You have unlearned ' + sn.name^ + '.', false, ch, nil, nil, TO_CHAR);
    end;
end;

procedure do_practice(ch:GCharacter;param:string);
var sn : GSkill;
    vict,learn:GCharacter;
    node : GListNode;
    g : GLearned;
begin
  vict := nil;
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
    ch.sendBuffer('Skills you can practice here:'#13#10#13#10);

    { for sn := 0 to MAX_SKILLS - 1 do
      begin
      if (vict.learsn] > 0) then
        act(AT_REPORT, '  (Level $B$4' + pad_integer_front(skill_table[sn].min_lvl, 3) + '$A$7) ' + skill_table[sn].name, false, ch, nil, nil, TO_CHAR);
      end; }
    node := vict.skills_learned.head;

    while (node <> nil) do
      begin
      g := node.element;

      if (ch.level >= GSkill(g.skill).min_lvl) then
        act(AT_REPORT, Format('  (Level $B$4%s$A$7) %-25s $B$7%s$A$7%%', [pad_integer_front(GSkill(g.skill).min_lvl, 3), GSkill(g.skill).name, pad_integer_front(ch.LEARNED(g.skill), 3)]), false, ch, nil, nil, TO_CHAR);

      node := node.next;
      end;
    end
  else
    begin
    sn := findSkillPlayer(ch,param);

    if (sn <> nil) then
      begin
      if (vict.LEARNED(sn) = 0) then
        act(AT_REPORT, '$N doesn''t teach this skill.', false, ch, nil, vict, TO_CHAR)
      else
      if (ch.LEARNED(sn) < 50) then
        begin
        if (GPlayer(ch).pracs < 1) then
        begin
          ch.sendBuffer('You don''t have enough practice sessions left!'#13#10);
          exit;
        end
        else
          dec(GPlayer(ch).pracs);
        
//        ch.SET_LEARNED(ch.LEARNED(sn) + 8, sn);
        // base skill gain on int
        ch.SET_LEARNED(ch.LEARNED(sn) + round(ch.int / 10) + random(4) - 2, sn);

        if (ch.LEARNED(sn) > 50) then
          begin
          ch.SET_LEARNED(50, sn);

          act(AT_REPORT,'You now know enough about ' + cap(sn.name^) + '.',false,ch,nil,nil,TO_CHAR);
          end
        else
          act(AT_REPORT,'You practice ' + cap(sn.name^) + '.',false,ch,nil,nil,TO_CHAR);
        end
      else
        act(AT_REPORT,'You have practiced this skill enough.',false,ch,nil,nil,TO_CHAR);
      end
    else
      act(AT_REPORT,'You have not learned this skill!',false,ch,nil,nil,TO_CHAR);
    end;
end;

procedure search_timer(ch, victim : GCharacter; sn : GSkill);
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
        if (length(pexit.keywords^) > 0) then
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

  registerTimer(TIMER_SEARCH, search_timer, 6, ch, nil, gsn_searching);
end;

procedure backstab_timer(ch,victim:GCharacter;sn:GSkill);
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

  to_hit:=ch.hitroll + 10;             { +10 bonus because of backstab }

  inc(to_hit,victim.ac);
  inc(to_hit,(ch.LEARNED(sn) - 50) div 5);
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
    damage(ch,victim,dam,cardinal(sn));
    victim.fighting:=ch;
    end
  else
    begin
    act(AT_REPORT,'As you attempt to sneak behind $N''s back, you are uncovered!',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'$n failed to backstab $N!', false,ch,nil,victim,TO_ROOM);
    damage(ch,victim,0,cardinal(sn));
    victim.fighting:=ch;
    end;
end;

procedure do_backstab(ch:GCharacter;param:string);
var victim:GCharacter;
    wield:GObject;
begin
  if (ch.LEARNED(gsn_backstab) = 0) then
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
  registerTimer(TIMER_BACKSTAB, backstab_timer, 8, ch, victim, gsn_backstab);
  ch.position:=POS_BACKSTAB;
end;

procedure circle_timer(ch,victim:GCharacter; sn : GSkill);
begin
  if (victim.CHAR_DIED) or (victim.room<>ch.room) then
    begin
    ch.sendBuffer('They are not here.'#13#10);
    ch.position:=POS_STANDING;
    exit;
    end;

  ch.position := POS_FIGHTING;

  if (number_percent <= ch.LEARNED(sn)) then
    begin
    act(AT_REPORT,'You succeed in circling your opponent and find yourself behind $M.',false,ch,nil,victim,TO_CHAR);
    backstab_timer(ch,victim,gsn_backstab);
    end
  else
    act(AT_REPORT,'You failed to circle.',false,ch,nil,nil,TO_CHAR);
end;

procedure do_circle(ch:GCharacter;param:string);
var
   wield : GObject;
begin
  if (ch.LEARNED(gsn_circle) = 0) then
    begin
    ch.sendBuffer('You don''t know how to circle!'#13#10);
    exit;
    end;

  if (ch.position <> POS_FIGHTING) then
    begin
    ch.sendBuffer('You are not fighting!'#13#10);
    exit;
    end;

  if (ch.fighting.fighting = ch) then
    begin
    ch.sendBuffer('You are on the frontline and can not circle!'#13#10);
    exit;
    end;

  wield := ch.getWield(ITEM_WEAPON);

  if (wield=nil) or not (wield.value[4] in [FG_PIERCE,FG_STAB]) then
    begin
    ch.sendBuffer('You must wield a piercing or stabbing weapon.'#13#10);
    exit;
    end;

  act(AT_REPORT,'You attempt to circle behind your target...',false,ch,nil,nil,TO_CHAR);
  registerTimer(TIMER_CIRCLE, circle_timer, 10, ch, ch.fighting, gsn_circle);
  ch.position:=POS_CIRCLE;
end;

procedure do_rescue(ch:GCharacter;param:string);
var victim:GCharacter;
begin
  if (ch.LEARNED(gsn_rescue) = 0) then
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

  if (number_percent <= ch.LEARNED(gsn_rescue)) then
    begin
    act(AT_REPORT,'You rescue $N!',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'$N rescues you!',false,victim,nil,ch,TO_VICT);
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

procedure track_timer(ch,victim:GCharacter; sn : GSkill);
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
  
  if (ch.LEARNED(gsn_track) = 0) then
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
    ch.tracking := vict.name^;

  registerTimer(TIMER_TRACK, track_timer, 4, ch, vict, gsn_track);
end;

// Lock Pick - Nemesis
procedure do_lockpick(ch : GCharacter; param : string);
var pexit : GExit;
    dir : integer;
    room_pos : GRoom;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Lockpick what?'#13#10);
    exit;
    end;

  dir := findHeading(param);
  pexit := ch.room.findExit(dir);

  if (pexit = nil) then
    begin
    ch.sendBuffer('That door cannot be found.'#13#10);
    exit;
    end;

  if not IS_SET(pexit.flags, EX_ISDOOR) then
    begin
    ch.sendBuffer('That is not a door.'#13#10);
    exit;
    end;

  if not IS_SET(pexit.flags, EX_LOCKED) then
    begin
    ch.sendBuffer('That door isn''t locked.'#13#10);
    exit;
    end;

  if not IS_SET(pexit.flags, EX_PICKPROOF) and (number_percent < ch.LEARNED(gsn_lockpick)) then
    begin
    REMOVE_BIT(pexit.flags, EX_LOCKED);

    // Get reverse exit
    room_pos := findRoom(pexit.vnum);

    if (room_pos <> nil) then
      begin
      pexit := room_pos.findExit(dir_inv[dir]);

      if (pexit <> nil) then
        REMOVE_BIT(pexit.flags, EX_LOCKED);
      end;

    act(AT_BROWN, 'You have succesfully picked the lock.', false, ch, nil, nil, TO_CHAR);
    act(AT_BROWN, '$n has picked the lock.', false, ch, nil, nil, TO_ROOM);
    end
  else
    ch.sendBuffer('You failed to pick the lock.'#13#10);
end;
