procedure do_cast(ch:GCharacter;param:string);
var sn : GSkill;
    victim:GCharacter;
    sub : string;
    obj : GObject;
    spell_lvl : integer;
begin
  if (ch.position = POS_BASHED) then
    begin
    ch.sendBuffer('You are bashed to the ground!'#13#10);
    exit;
    end;

  if (length(param)=0) then
    begin
    ch.sendBuffer('Cast which what where?'#13#10);
    exit;
    end;

  if (IS_SET(ch.room.flags, ROOM_NOCAST)) then
    begin
    ch.sendBuffer('A powerful force prevents you from using magic here.'#13#10);
    exit;
    end;

  if (ch.cast_timer > 0) then
    begin
    ch.sendBuffer('You cannot cast this soon after your last spell!'#13#10);
    exit;
    end;

  param := one_argument(param,sub);

  if (ch.IS_NPC) then
    sn := findSkill(sub)
  else
    sn := findSkillPlayer(ch, sub);

  one_argument(param,sub);

  if (sn <> nil) then
    begin
    if (sn.skill_type = SKILL_SPELL) then
      begin
      victim := nil;

      case (sn.target) of
        TARGET_OFF_ATTACK:begin
                          victim := ch.room.findChar(ch, sub);

                          if victim=nil then
                           if (ch.position=POS_FIGHTING) and (ch.fighting<>nil) then
                            victim:=ch.fighting;

                          if victim=nil then
                            begin
                            act(AT_REPORT,'They are not here.',false,ch,nil,nil,TO_CHAR);
                            exit;
                            end;
                          end;
          TARGET_OFF_AREA:begin
                          victim := ch.room.findChar(ch, sub);

                          if (victim = ch) then
                            begin
                            act(AT_REPORT, 'You can''t cast this on yourself!',false,ch,nil,nil,TO_CHAR);
                            exit;
                            end;

                          if victim=nil then
                           if (ch.position=POS_FIGHTING) and (ch.fighting<>nil) then
                            victim:=ch.fighting;

                          if victim=nil then
                            begin
                            act(AT_REPORT,'They are not here.',false,ch,nil,nil,TO_CHAR);
                            exit;
                            end;
                          end;
          TARGET_DEF_SELF:begin
                          if (length(sub)>0) then
                            begin
                            act(AT_REPORT,'You can only cast this on yourself.',false,ch,nil,nil,TO_CHAR);
                            exit;
                            end;

                          if ch.position=POS_FIGHTING then
                            begin
                            act(AT_REPORT,'You cannot concentrate enough.',false,ch,nil,nil,TO_CHAR);
                            exit;
                            end;

                          victim:=ch;
                          end;
        TARGET_DEF_SINGLE:begin
                          if (length(sub)=0) then
                            victim := ch
                          else
                            victim := ch.room.findChar(ch, sub);

                          if victim=nil then
                            begin
                            act(AT_REPORT,'They are not here.',false,ch,nil,nil,TO_CHAR);
                            exit;
                            end;
                          end;
          TARGET_DEF_AREA:begin
                          victim := ch;
                          end;
         TARGET_DEF_WORLD:begin
                          victim := findCharWorld(ch, sub);

                          if victim=nil then
                            begin
                            act(AT_REPORT,'They are not here.',false,ch,nil,nil,TO_CHAR);
                            exit;
                            end;
                          end;
            TARGET_OBJECT:begin
                          victim := GCharacter(ch.findInventory(sub));

                          if victim=nil then
                            begin
                            act(AT_REPORT,'You are not carrying that.',false,ch,nil,nil,TO_CHAR);
                            exit;
                            end;
                          end;
         end;

    if (sn.target <= TARGET_OFF_AREA) and (not ch.IS_NPC) then
      ch.player^.fightxp := 0;

    obj := ch.getWield(ITEM_GEM);

    if (obj <> nil) and (obj.item_type = ITEM_GEM) then
      spell_lvl := obj.value[2]
    else
      spell_lvl := (ch.ability.int + ch.ability.wis) div 2;

    if (victim = nil) then
      act(AT_REPORT,'They are not here.',false,ch,nil,nil,TO_CHAR)
    else
    if (victim = ch) and (sn.target = TARGET_OFF_ATTACK) then
      act(AT_REPORT,'You don''t want to cast that on yourself!',false,ch,nil,nil,TO_CHAR)
    else
    if (spell_lvl < sn.min_lvl) and (not ch.IS_NPC) then
      act(AT_REPORT,'That spell is too powerful!',false,ch,nil,nil,TO_CHAR)
    else
    if (ch.point.mana >= sn.min_mana) or (ch.IS_NPC) then
      begin
      if (sn.target = TARGET_OFF_ATTACK) and (ch.fighting<>nil) then
        ch.fighting := victim;

      if (ch.IS_NPC) then
        magic_timer(ch, victim, sn)
      else
        begin
        ch.position := POS_CASTING;

        act(AT_REPORT,'You begin to utter some strange incantations...',false,ch,nil,nil,TO_CHAR);
        act(AT_REPORT,'$n begins to utter some strange incantations...',false,ch,nil,nil,TO_ROOM);

        registerTimer(TIMER_CAST, magic_timer, sn.beats, ch, victim, sn);
        end;
      end
    else
      act(AT_REPORT,'You don''t have enough mana.',false,ch,nil,nil,TO_CHAR);
    end
   else
    act(AT_REPORT,'That is not a spell.',false,ch,nil,nil,TO_CHAR);
   end
 else
    act(AT_REPORT,'You haven''t learned that spell.',false,ch,nil,nil,TO_CHAR);
end;

procedure do_mana(ch : GCharacter; param : string);
var
   obj : GObject;
   spell_lvl : integer;
begin
  obj := ch.getWield(ITEM_GEM);

  if (obj <> nil) and (obj.item_type = ITEM_GEM) then
    spell_lvl := obj.value[2]
  else
    spell_lvl := (ch.ability.int + ch.ability.wis) div 2;

  act(AT_REPORT,'Your current spell-level: $B$1[$B$7' + inttostr(spell_lvl) + '$B$1]',false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'Your current mana:        $B$1[$B$7' + inttostr(ch.point.mana) + '$B$1]',false,ch,nil,nil,TO_CHAR);
end;

