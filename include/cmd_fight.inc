procedure do_kill(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Kill who?'#13#10);
    exit;
    end;

  vict := ch.room.findChar(ch, param);
  
  if (vict=nil) then
    ch.sendBuffer('They aren''t here.'#13#10)
  else
  if (vict=ch) then
    ch.sendBuffer('You try to attack yourself, but somehow it just doesn''t work!'#13#10)
  else
  if IS_SET(ch.room.flags,ROOM_SAFE) then
    ch.sendBuffer('A strange force prevents you from attacking.'#13#10)
  else
  if (vict.position<>POS_FIGHTING) then
    begin
    if (not ch.IS_NPC) then
      ch.player^.fightxp:=0;

    ch.position:=POS_FIGHTING;
    ch.fighting:=vict;
    // ch.fought_by.add(vict);

    vict.position:=POS_FIGHTING;
    vict.fighting:=ch;
    // vict.fought_by.add(ch);

    act(AT_FIGHT_YOU,'You attack $N!',false,ch,nil,vict,TO_CHAR);
//          act(AT_FIGHT_HIT,'You are being attacked by $N!',false,t,nil,ch,TO_CHAR);
//          act(AT_FIGHT,'$N attackes $n!',false,t,nil,ch,TO_NOTVICT);
    end
  else
  if (vict.position=POS_FIGHTING) and (ch.position<>POS_FIGHTING) then
    begin
    if (not ch.IS_NPC) then
      ch.player^.fightxp:=0;

    ch.position:=POS_FIGHTING;
    ch.fighting:=vict;
    // vict.fought_by.add(ch);

    act(AT_FIGHT_YOU,'You assist $N!',false,ch,nil,vict.fighting,TO_CHAR);
    act(AT_FIGHT_HIT,'$N CHARGES into battle!',false,vict,nil,ch,TO_CHAR);
    act(AT_FIGHT,'$N CHARGES into the battle against $n!',false,vict,nil,ch,TO_NOTVICT);
    end
  else
  if (vict<>ch.fighting) then
    begin
    //ch.fighting.fought_by.delete(ch.fighting.fought_by.indexof(ch));

    if (not ch.IS_NPC) then
      ch.player^.fightxp:=0;

    ch.fighting:=vict;
    //vict.fought_by.add(ch);

    act(AT_FIGHT_YOU,'You turn and target $N!',false,ch,nil,vict,TO_CHAR);
    act(AT_FIGHT_HIT,'$N turns and targets YOU!',false,vict,nil,ch,TO_CHAR);
    act(AT_FIGHT,'$N turns and targets $n!',false,vict,nil,ch,TO_NOTVICT);
    end
  else
    act(AT_REPORT,'You are already fighting $N!',false,ch,nil,vict,TO_CHAR);
end;

procedure do_flee(ch:GCharacter;param:string);
var a : integer;
    pexit : GExit;
    timer : GTimer;
    room : GRoom;
    vict : GCharacter;
    node : GListNode;
begin
  if (ch.position = POS_BASHED) then
    begin
    act(AT_REPORT,'You are bashed and cannot flee.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  if (ch.bashing > -2) then
    begin
    act(AT_REPORT,'You are still too off-balance to flee.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  if (ch.position <> POS_FIGHTING) then
    begin
    ch.sendBuffer('You can''t flee when you''re not fighting!'#13#10);
    exit;
    end;

  a := random(6)+1;
  pexit := ch.room.findExit(a);

  ch.position := POS_STANDING;
  room := ch.room;

  if (pexit <> nil) and (do_move(ch, pexit)) then
    begin
    // ch.fought_by.clear;
    ch.sendBuffer('You flee as fast as you can!'#13#10);

    node := room.chars.head;

    while (node <> nil) do
      begin
      vict := node.element;

      act(AT_REPORT,'$N flees away in panic!',false,vict,nil,ch,TO_CHAR);

      node := node.next;
      end;

    timer := timerSet(ch, TIMER_COMBAT);

    if (timer <> nil) then
      timer.rounds := combat_timer[COMBAT_MOBILE]
    else
      addTimer(ch,nil,TIMER_COMBAT,nil,-1,combat_timer[COMBAT_MOBILE]);

    if (ch.fighting.IS_NPC) then
      begin
      ch.fighting.hunting:=ch;
      SET_BIT(ch.fighting.act_flags,ACT_HUNTING);
      end;

    if (ch.fighting.fighting = ch) then
      ch.fighting.fighting := nil;
      
    ch.fighting.position := POS_STANDING;
    stopfighting(ch);
    ch.fighting := nil;
    end
  else
    begin
    ch.position := POS_FIGHTING;
    ch.sendBuffer('You cannot get away!'#13#10);
    end;
end;

procedure do_flurry(ch:GCharacter;param:string);
var a,num:integer;
begin
  if (ch.position = POS_BASHED) then
    begin
    ch.sendBuffer('You are bashed! You cannot flurry!'#13#10);
    exit;
    end
  else
  if (ch.position<>POS_FIGHTING) or (ch.fighting.CHAR_DIED) then
    begin
    ch.sendBuffer('You can only flurry when you are fighting.'#13#10);
    exit;
    end
  else
  if (ch.bashing > -2) then
    begin
    ch.sendBuffer('You cannot flurry this soon after a bash.'#13#10);
    exit;
    end
  else
  if (ch.point.mv < 15 + (ch.level div 10)+1) then
    begin
    ch.sendBuffer('You don''t have enough energy to flurry.'#13#10);
    exit;
    end;

  with ch do
    begin
    act(AT_REPORT,'You go crazy and open up in a flurry of attacks!',false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n screams out a warcry and opens up in a flurry of attacks!',false,ch,nil,nil,TO_ROOM);

    dec(point.mv, 15 + (ch.level div 10));

    ch.setWait(8);

    num := URange(1,level div 10, rolldice(1,5));

    { first a predetermined number of attacks (the flurry) - Grimlord }
    for a := 1 to num do
      begin
      if (ch.fighting.CHAR_DIED) then
        exit;

      if (one_hit(ch, ch.fighting) <> RESULT_NONE) then
        exit;
      end;

    { then the other attacks (second/third/etc) - Grimlord }
    if (not ch.fighting.CHAR_DIED) then
      multi_hit(ch, ch.fighting);
    end;
end;

procedure do_assist(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  case ch.position of
    POS_BASHED:begin
               ch.sendBuffer('You are bashed to the ground!'#13#10);
               exit;
               end;
  POS_FIGHTING:begin
               ch.sendBuffer('You are already fighting!'#13#10);
               exit;
               end;
  end;

  if (length(param) = 0) then
    ch.sendBuffer('Assist who?'#13#10)
  else
    begin
    vict := ch.room.findChar(ch, param);

    if (vict = nil) then
      ch.sendBuffer('They aren''t here.'#13#10)
    else
    if (vict.IS_NPC) then
      act(AT_REPORT,'$N doesn''t want your help.',false,ch,nil,vict,TO_CHAR)
    else
    if vict.fighting=nil then
      act(AT_REPORT,'$N isn''t fighting.',false,ch,nil,vict,TO_CHAR)
    else
      begin
      act(AT_REPORT,'You assist $N!',false,ch,nil,vict,TO_CHAR);
      act(AT_REPORT,'$n assists $N!',false,ch,nil,vict,TO_ROOM);
      ch.fighting := vict.fighting;
      ch.position := POS_FIGHTING;
      end;
    end;
end;

procedure do_disengage(ch:GCharacter;param:string);
begin
  if (ch.position<>POS_FIGHTING) then
    begin
    ch.sendBuffer('You are not fighting!'#13#10);
    exit;
    end;

  { cannot disengage when tanking }
  if (ch.fighting.fighting=ch) then
    begin
    ch.sendBuffer('You are in the frontline and can not disengage!'#13#10);
    exit;
    end;
    
  act(AT_REPORT,'You withdraw from the fight.',false,ch,nil,nil,TO_CHAR);

  ch.fighting:=nil;
  ch.position:=POS_STANDING;
end;
