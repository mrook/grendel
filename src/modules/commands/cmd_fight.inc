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
    ch.sendBuffer('Attack yourself? Get a clue!'#13#10)
  else
  if (ch.room.flags.isBitSet(ROOM_SAFE)) then
    ch.sendBuffer('A strange force prevents you from attacking.'#13#10)
  else
  if (vict.state <> STATE_FIGHTING) then
    begin
    if (not ch.IS_NPC) then
      GPlayer(ch).fightxp:=0;

    ch.state := STATE_FIGHTING;
    ch.fighting := vict;

    act(AT_FIGHT_YOU, 'You attack $N!',false,ch,nil,vict,TO_CHAR);
    end
  else
  if (vict.state = STATE_FIGHTING) and (ch.state <> STATE_FIGHTING) then
    begin
    if (not ch.IS_NPC) then
      GPlayer(ch).fightxp:=0;

    ch.state := STATE_FIGHTING;
    ch.fighting := vict;

    act(AT_FIGHT_YOU,'You assist $N!',false,ch,nil,vict.fighting,TO_CHAR);
    act(AT_FIGHT_HIT,'$N CHARGES into battle!',false,vict,nil,ch,TO_CHAR);
    act(AT_FIGHT,'$N CHARGES into the battle against $n!',false,vict,nil,ch,TO_NOTVICT);
    end
  else
  if (vict <> ch.fighting) then
    begin
    if (not ch.IS_NPC) then
      GPlayer(ch).fightxp:=0;

    ch.fighting := vict;

    act(AT_FIGHT_YOU,'You turn and target $N!',false,ch,nil,vict,TO_CHAR);
    act(AT_FIGHT_HIT,'$N turns and targets YOU!',false,vict,nil,ch,TO_CHAR);
    act(AT_FIGHT,'$N turns and targets $n!',false,vict,nil,ch,TO_NOTVICT);
    end
  else
    act(AT_REPORT,'You are already fighting $N!',false,ch,nil,vict,TO_CHAR);
end;

procedure do_flee(ch:GCharacter;param:string);
var 
	a : integer;
	timer : GTimer;
	room : GRoom;
	vict : GCharacter;
	iterator : GIterator;
begin
  if (IS_SET(ch.aff_flags, AFF_BASHED) or IS_SET(ch.aff_flags, AFF_STUNNED)) then
    begin
    act(AT_REPORT,'You are immobile and cannot flee!',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  if (ch.bashing > -2) then
    begin
    act(AT_REPORT,'You are still too off-balance to flee.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  if (ch.state <> STATE_FIGHTING) then
    begin
    ch.sendBuffer('You can''t flee when you''re not fighting!'#13#10);
    exit;
    end;

  a := random(6)+1;

  ch.state := STATE_IDLE;
  room := ch.room;

  if (do_move(ch, a)) then
    begin
    // ch.fought_by.clear;
    ch.sendBuffer('You flee as fast as you can!'#13#10);

    iterator := room.chars.iterator();
    while (iterator.hasNext()) do
      begin
      vict := GCharacter(iterator.next());

      act(AT_REPORT,'$N flees away in panic!',false,vict,nil,ch,TO_CHAR);
			end;
		iterator.Free();

    timer := hasTimer(ch, TIMER_COMBAT);

    if (timer <> nil) then
      timer.counter := combat_timer[COMBAT_MOBILE]
    else
      registerTimer('combat', TIMER_COMBAT, nil, combat_timer[COMBAT_MOBILE], ch, nil, nil);

    if (ch.fighting.IS_NPC) then
      begin
      ch.fighting.hunting := ch;
      SET_BIT(GNPC(ch.fighting).act_flags, ACT_HUNTING);
      end;

    if (ch.fighting.fighting = ch) then
      ch.fighting.fighting := nil;
      
    ch.fighting.state := STATE_IDLE;
    stopfighting(ch);
    ch.fighting := nil;
    end
  else
    begin
    ch.state := STATE_FIGHTING;
    ch.sendBuffer('You cannot get away!'#13#10);
    end;
end;

procedure do_flurry(ch:GCharacter;param:string);
var a,num:integer;
begin
  if (IS_SET(ch.aff_flags, AFF_BASHED) or IS_SET(ch.aff_flags, AFF_STUNNED)) then
    begin
    ch.sendBuffer('You are immobilized and cannot move!'#13#10);
    exit;
    end;

  if (ch.state <> STATE_FIGHTING) or (ch.fighting.CHAR_DIED) then
    begin
    ch.sendBuffer('You can only flurry when you are fighting.'#13#10);
    exit;
    end;
    
  if (ch.bashing > -2) then
    begin
    ch.sendBuffer('You cannot flurry this soon after a bash.'#13#10);
    exit;
    end;

  if (ch.mv < 15 + (ch.level div 10)+1) then
    begin
    ch.sendBuffer('You don''t have enough energy to flurry.'#13#10);
    exit;
    end;

  with ch do
    begin
    act(AT_REPORT,'You go crazy and open up in a flurry of attacks!',false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n screams out a warcry and opens up in a flurry of attacks!',false,ch,nil,nil,TO_ROOM);

    mv := mv - 15 + (ch.level div 10);

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
  if (IS_SET(ch.aff_flags, AFF_BASHED) or IS_SET(ch.aff_flags, AFF_STUNNED)) then
    begin
    ch.sendBuffer('You are immobilized and cannot move!'#13#10);
    exit;
    end;

  if (ch.state = STATE_FIGHTING) then
    begin
    ch.sendBuffer('You are already fighting!'#13#10);
    exit;
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
      ch.state := STATE_FIGHTING;
      end;
    end;
end;

procedure do_disengage(ch:GCharacter;param:string);
begin
  if (ch.state <> STATE_FIGHTING) then
    begin
    ch.sendBuffer('You are not fighting!'#13#10);
    exit;
    end;

  { cannot disengage when tanking }
  if (ch.fighting.fighting = ch) then
    begin
    ch.sendBuffer('You are in the frontline and can not disengage!'#13#10);
    exit;
    end;
    
  act(AT_REPORT,'You withdraw from the fight.',false,ch,nil,nil,TO_CHAR);

  ch.fighting := nil;
  ch.state := STATE_IDLE;
end;
