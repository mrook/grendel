{$F+}

{ The complete quit procedure, which even logs off NPCs! - Grimlord }
procedure do_quit(ch : GCharacter; param : string);
var
   timer : GTimer;
begin
  if (ch.position = POS_FIGHTING) then
    begin
    ch.sendBuffer('You are fighting! You can''t quit!'#13#10);
    exit;
    end;

  timer := hasTimer(ch, TIMER_COMBAT);

  if (timer <> nil) then
    begin
    ch.sendBuffer('You have recently fled out of combat or have encountered a member'#13#10);
    ch.sendBuffer('of the opposite alignment. Therefor you are not allowed to quit.'#13#10);
    ch.sendBuffer('Please wait another '+inttostr(round(timer.counter / CPULSE_TICK))+' gameticks to quit.'#13#10);
    exit;
    end;

  if (auction_good.seller = ch) or (auction_good.buyer = ch)
   or (auction_evil.seller = ch) or (auction_evil.buyer = ch) then
    begin
    ch.sendBuffer('Please wait till the current auction has been concluded.'#13#10);
    exit;
    end;

  if (ch.snooped_by <> nil) then
    interpret(ch.snooped_by, 'snoop self');

  act(AT_REPORT, '$n has logged off.', false, ch, nil, nil, TO_ROOM);


  if (ch.conn <> nil) then
    GConnection(ch.conn).send('Thanks for playing! Please visit this MUD again!'#13#10);

  ch.quit;
end;

procedure do_save(ch : GCharacter; param : string);
begin
  ch.save(ch.name^);
  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_afk(ch : GCharacter; param : string);
begin
  GConnection(ch.conn).afk := true;
  ch.sendBuffer('You are now listed as AFK. Hitting ENTER will cease this.'#13#10);
end;

{ Revised help - Nemesis }
procedure do_help(ch : GCharacter; param : string);
var buf, s, keyword : string;
    help : GHelp;
    counter : integer;
    node : GListNode;
begin
  if (length(param) = 0) then
    begin
    buf := ch.ansiColor(3) + ' ' + add_chars(78, '---- Available help keywords ', '-') + ch.ansiColor(7) + #13#10#13#10;

    counter := 0;
    node := help_files.head;

    while (node <> nil) do
      begin
      help := node.element;

      keyword := help.keywords;

      while (length(keyword) > 0) do
        begin
        keyword := one_argument(keyword, s);

        if (s[length(s)] <> '_') then
          begin
          buf := buf + pad_string(lowercase(s), 19);

          inc(counter);

          if (counter = 4) then
            begin
            buf := buf + #13#10;
            counter := 0;
            end;
          end;
        end;

      node := node.next;
      end;

    ch.sendPager(buf + #13#10);
    exit;
    end;

  help := findHelp(param);

  if (help = nil) or (help = help_files.head.element) then
    ch.sendBuffer('No help on that word.'#13#10)
  else
    begin
    buf := ch.ansiColor(3) + ' ' + add_chars(78, '---- Help topic ', '-') + ch.ansiColor(7) + #13#10#13#10 +
           'Name:    ' + ansiColor(3,0) + help.keywords + #13#10 + ansiColor(7,0) +
           'Type:    ' + ansiColor(3,0) + help.helptype + #13#10 + ansiColor(7,0) +
           'Syntax:  ' + ansiColor(3,0) + help.syntax + #13#10 + ansiColor(7,0) +
           'Related: ' + ansiColor(3,0) + help.related + #13#10 + ansiColor(7,0) +
           #13#10 + help.text;

    ch.sendPager(buf);
    end;
end;

procedure do_remort(ch : GCharacter; param : string);
var a:integer;
    str,con,dex,int,wis,dam,pracs:integer;
    sub : string;
begin
  if (ch.IS_IMMORT) then
    ch.sendBuffer('You don''t want to remort!'#13#10)
  else
  if (ch.player^.remorts >= 6) then
    ch.sendBuffer('You have had enough remorts.'#13#10)
  else
  if (length(param) = 0) then
    ch.sendBuffer('REMORT <stat> <stat> <stat> <stat> <stat> <extra>'#13#10)
  else
    begin
    str:=0; con:=0; dex:=0; int:=0; wis:=0;
    dam:=0; pracs:=0;
    for a:=0 to 4 do
      begin
      param:=one_argument(param,sub);
      if (comparestr('str', sub) = 0) then
        inc(str)
      else
      if (comparestr('con',sub)=0) then
        inc(con)
      else
      if (comparestr('dex',sub)=0) then
        inc(dex)
      else
      if (comparestr('int',sub)=0) then
        inc(int)
      else
      if (comparestr('wis',sub)=0) then
        inc(wis)
      else
        begin
        ch.sendBuffer('Unknown stat in parameter list.'#13#10);
        exit;
        end;
      end;

    param := one_argument(param,sub);

    if (comparestr('dam',sub)=0) then
      inc(dam,2)
    else
    if (comparestr('pracs',sub)=0) then
      inc(pracs,25)
    else
      begin
      ch.sendBuffer('Illegal extra in parameter list.'#13#10);
      exit;
      end;

    with ch do
      begin
      inc(player^.remorts);
      inc(ability.str,str);
      inc(ability.con,con);
      inc(ability.dex,dex);
      inc(ability.int,int);
      inc(ability.wis,wis);
      inc(point.apb,dam);
      
      level:=1;

      point.max_hp:=50;
      point.max_mv:=40;
      point.max_mana:=25;
      point.hitroll:=50;

      skills_learned.clean;
      end;

    act(AT_WHITE,'Congratulations! This is remort '+inttostr(ch.player^.remorts)+
                 ' for your character!',false,ch,nil,nil,TO_CHAR);
    end;
end;

{ Revised - Nemesis }
procedure do_delete(ch: GCharacter; param : string);
var f:file;
begin
  if (ch.IS_NPC) then
    begin
    ch.sendBuffer('NPCs cannot delete.'#13#10);
    exit;
    end;

  if (not MD5Match(ch.player^.md5_password, MD5String(param))) then
    begin
    ch.sendBuffer('Type DELETE <password> to delete. WARNING: This is irreversible!'#13#10);
    exit;
    end;

  GConnection(ch.conn).send('You feel yourself dissolving, atom by atom...'#13#10);

  write_console(ch.name^ + ' has deleted');
  ch.quit;

  assignfile(f, 'players\' + ch.name^ + '.usr');
  rename(f, 'backup\' + ch.name^ + '.usr');
end;

procedure do_wimpy(ch : GCharacter; param : string);
var wimpy:integer;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Set wimpy to what?'#13#10);
    exit;
    end;

  try
    wimpy := strtoint(param);
  except
    ch.sendBuffer('That is not a valid number.'#13#10);
    exit;
  end;

  if (wimpy > ch.point.max_hp div 3) then
    ch.sendBuffer('Your wimpy cannot be higher than 1/3 of your total hps!'#13#10)
  else
    begin
    ch.player^.wimpy := wimpy;
    ch.sendBuffer(pchar('Wimpy set to '+inttostr(wimpy)+'.'+#13#10));
    end;
end;

{ Allow players to lock their keyboard - Nemesis }
procedure do_keylock(ch : GCharacter; param: string);
begin
  GConnection(ch.conn).afk := true;
  GConnection(ch.conn).keylock := true;

  ch.sendBuffer('You are now away from keyboard.'#13#10);
  ch.sendBuffer('Enter your password to unlock.'#13#10);
end;

{$I include\cmd_imm.inc}
{$I include\cmd_info.inc}
{$I include\cmd_move.inc}
{$I include\cmd_fight.inc}
{$I include\cmd_magic.inc}
{$I include\cmd_skill.inc}
{$I include\cmd_comm.inc}
{$I include\cmd_obj.inc}
{$I include\cmd_shops.inc}
{$I include\cmd_build.inc}
