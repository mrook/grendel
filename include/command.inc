// $Id: command.inc,v 1.14 2001/04/20 18:50:55 xenon Exp $

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

type 
  THelpKeyword = class
                   keyword : string;
                   phelp : GHelp;
                   constructor Create(str : string; p : GHelp);
                 end;

constructor THelpKeyword.Create(str : string; p : GHelp);
begin
  inherited Create();

  keyword := str;
  phelp := p;
end;

{ Revised help - Nemesis }
{ Xenon 16/Apr/2001: - help without arguments now gives sorted keywordlist
                     - help with an arg that matches multiple keywords will show matching keywords}
procedure do_help(ch : GCharacter; param : string);
  procedure insertAlphabetical(var ll : GDLinkedList; hk : THelpKeyword);
  var
    node, ins : GListNode;
    s : THelpKeyword;
  begin
    ins := nil;
    node := ll.head;

    if (ll.head = nil) then
    begin
      ll.insertLast(hk);
      exit;
    end;

    while (node <> nil) do
    begin
      s := node.element;

      if (AnsiCompareStr(hk.keyword, s.keyword) > 0) then
      begin
        ins := node;
      end
      else
      begin
        ll.insertBefore(node, hk);
        exit;
      end;
    
      node := node.next;
    end;

    ll.insertAfter(ins, hk)
  end;

var buf, s, keyword : string;
    help : GHelp;
    counter : integer;
    node : GListNode;
    keywordlist : GDLinkedList;
    hk : THelpKeyword;
    done : boolean;
begin
  keywordlist := nil; hk := nil;
  done := false;
  counter := 0;
  
  if (length(param) = 0) then
  begin
    buf := ch.ansiColor(3) + ' ' + add_chars(78, '---- Available help keywords ', '-') + ch.ansiColor(7) + #13#10#13#10;

    keywordlist := GDLinkedList.Create();
    
    node := help_files.head;
    while (node <> nil) do
    begin
      help := node.element;

      keyword := help.keywords;

      while (length(keyword) > 0) do
      begin
        keyword := one_argument(keyword, s);

        if ((s[length(s)] <> '_') and (help.level <= ch.level)) then
        begin
          hk := THelpKeyword.Create(lowercase(s), help);

          insertAlphabetical(keywordlist, hk);
        end;
          
      end;

      node := node.next;
    end;

    node := keywordlist.head;
    while (node <> nil) do
    begin
      buf := buf + pad_string(THelpKeyword(node.element).keyword, 19);
      inc(counter);

      if (counter = 4) then
      begin
        buf := buf + #13#10;
        counter := 0;
      end;      
      node := node.next;
    end;

    keywordlist.Clean();
    keywordlist.Free();
    ch.sendPager(buf + #13#10);
    exit;
  end;

  keywordlist := GDLinkedList.Create();
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
        if ((pos(uppercase(param), s) = 1) and (help.level <= ch.level)) then
        begin
          hk := THelpKeyword.Create(lowercase(s), help);
          insertAlphabetical(keywordlist, hk);
        end;
        if ((uppercase(param) = s) and (help.level <= ch.level)) then // if it's a 1-on-1 match, stop right away
        begin
          keywordlist.Clean();
          keywordlist.Free();
          keywordlist := GDLinkedList.Create();
          keywordlist.insertLast(THelpKeyword.Create(lowercase(s), help));
          done := true;
          break;
        end;
      end;
    end;

    if (done) then
      break;
      
    node := node.next;
  end;
  
  if (keywordlist.getSize() = 0) then
  begin
    ch.sendBuffer('No help on that word.'#13#10)
  end
  else
  if (keywordlist.getSize() = 1) then
  begin
    help := THelpKeyword(keywordlist.head.element).phelp;
    buf := '$A$3 ' + add_chars(78, '---- Help topic ', '-') + '$A$7'#13#10#13#10 +
           'Name:    $A$3' + help.keywords + #13#10 + '$A$7' +
           'Type:    $A$3' + help.helptype + #13#10 + '$A$7' +
           'Syntax:  $A$3' + help.syntax + #13#10 + '$A$7' +
           'Related: $A$3' + help.related + #13#10 + '$A$7' +
           #13#10 + help.text;

    ch.sendPager(act_string(buf, ch, nil, nil, nil));
  end
  else
  if (keywordlist.getSize() > 1) then
  begin
    buf := Format('Your help query ''$B$7%s$A$7'' matched $B$7%d$A$7 keywords:'#13#10#13#10, [param, keywordlist.getSize()]);
    node := keywordlist.head;
    while (node <> nil) do
    begin
      buf := buf + Format('  $B$7%s$A$7'#13#10, [THelpKeyword(node.element).keyword]);
      node := node.next;
    end;

    ch.sendPager(act_string(buf, ch, nil, nil, nil));
  end;

  keywordlist.Clean();
  keywordlist.Free();
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
  begin
    ch.sendBuffer('REMORT <stat> <stat> <stat> <stat> <stat> <extra>' + #13#10 +
                  '' + #13#10 +
                  '   where <stat> is one of str, con, dex, int or wis and <extra> one of dam or pracs.'#13#10);
  end
  else
    begin
    str:=0; con:=0; dex:=0; int:=0; wis:=0;
    dam:=0; pracs:=10;
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
        ch.sendBuffer('Unknown <stat> in parameter list.'#13#10);
        exit;
        end;
      end;

    param := one_argument(param,sub);

    if (comparestr('dam',sub)=0) then
      inc(dam,2)
    else
    if (comparestr('pracs',sub)=0) then
//      inc(pracs,25)
      pracs := 25
    else
      begin
      ch.sendBuffer('Illegal <extra> in parameter list.'#13#10);
      exit;
      end;

    if (length(param) <> 0) then
    begin
      ch.sendBuffer('Unrecognized option ''' + param + ''' in remort command.'#13#10);
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
      inc(player^.max_skills, 1);
      inc(player^.max_spells, 2);
      player^.pracs := pracs;
      
      level := 1;

      point.max_hp:=50;
      point.max_mv:=40;
      point.max_mana:=25;
      point.hitroll:=50;

      skills_learned.clean;
      end;

    act(AT_WHITE,'Congratulations! This is remort '+inttostr(ch.player^.remorts)+
                 ' for your character!',false,ch,nil,nil,TO_CHAR);
    interpret(ch, 'save');
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

// Handle Notes - Nemesis
procedure do_note(ch : GCharacter; param : string);
var arg1, arg2, buf : string;
    number, counter : integer;
    note : GNote;
    node : GListNode;
begin
  if (ch.IS_NPC) then
    exit;

  param := one_argument(param, arg1);
  one_argument(param, arg2);

  if (length(arg1) = 0) then
    begin
    ch.sendBuffer('Usage: NOTE READ <number>'#13#10);
    ch.sendBuffer('       NOTE WRITE'#13#10);
    ch.sendBuffer('       NOTE LIST'#13#10);

    if (ch.IS_IMMORT) then
      ch.sendBuffer('       NOTE DELETE <number>'#13#10);

    exit;
    end
  else
  if (uppercase(arg1) = 'WRITE') then
    begin
    ch.substate := SUB_SUBJECT;

    ch.sendBuffer('You are now away from keyboard.'#13#10#13#10);
    act(AT_REPORT,'$n has left $s keyboard and starts writing a note.',false,ch,nil,nil,to_room);

    ch.sendBuffer('You start writing a note on the ' + board_names[ch.player^.active_board] + ' board.'#13#10);
    ch.startEditing('');
    exit;
    end
  else
  if (uppercase(arg1) = 'LIST') then
    begin
    counter := 0;
    node := notes.head;

    if (node = nil) then
      begin
      ch.sendBuffer('There are no notes on this board.'#13#10);
      exit;
      end;

    while (node <> nil) do
      begin
      note := node.element;

      if (note.board = ch.player^.active_board) then
        begin
        inc(counter);
        buf := buf + ansiColor(2,0) + pad_integer_front(note.number,3) + '>  ' + pad_string(note.author,20) + note.subject + #13#10;
        end;

      node := node.next;
      end;

    if (counter = 0) then
      buf := ansiColor(2,0) + 'There are no notes on this board.' + #13#10;

    buf := ansiColor(2,0) + 'Num   Author              Subject' + #13#10 +
           ansiColor(2,0) + '===   ==================  ======================' + #13#10 + buf;

    ch.sendPager(buf);
    exit;
    end
  else
  if (uppercase(arg1) = 'READ') then
    begin
    if (length(arg2) = 0) then
      begin
      ch.sendBuffer('Usage: NOTE READ <number>'#13#10);
      exit;
      end;

    try
      number := strtoint(arg2);
    except
      ch.sendBuffer('Usage: NOTE READ <number>'#13#10);
      exit;
    end;

    note := findNote(ch.player^.active_board, number);

    if (note = nil) then
      begin
      ch.sendBuffer('That is not a valid number.'#13#10);
      exit;
      end;

    buf := ansiColor(2,0) + add_chars(77, '=== NOTE ', '=') + #13#10 +
           ansiColor(2,0) + 'Number:  ' + ansiColor(7,0) + inttostr(note.number) + #13#10 +
           ansiColor(2,0) + 'Date:    ' + ansiColor(7,0) + note.date + #13#10 +
           ansiColor(2,0) + 'Author:  ' + ansiColor(7,0) + note.author + #13#10 +
           ansiColor(2,0) + 'Subject: ' + ansiColor(7,0) + note.subject + #13#10 +
           ansiColor(2,0) + add_chars(77, '-', '-') + #13#10 +
           ansiColor(7,0) + note.text +
           ansiColor(2,0) + add_chars(77, '=', '=') + #13#10;

    ch.sendPager(buf);

    ch.player^.boards[ch.player^.active_board] := number;
    exit;
    end
  else
  if (uppercase(arg1) = 'DELETE') then
    begin
    if (length(arg2) = 0) then
      begin
      ch.sendBuffer('Usage: NOTE DELETE <number>'#13#10);
      exit;
      end;

    try
      number := strtoint(arg2);
    except
      ch.sendBuffer('Usage: NOTE DELETE <number>'#13#10);
      exit;
    end;

    node := notes.head;

    if (node = nil) then
      begin
      ch.sendBuffer('There are no notes to delete.'#13#10);
      exit;
      end;

    while (node <> nil) do
      begin
      note := node.element;

      if (note.board = ch.player^.active_board) and (note.number = number) then
        begin
        notes.remove(node);
        save_notes;
        ch.sendBuffer('Note succesfully deleted.'#13#10);
        exit;
        end;

      node := node.next;
      end;

    ch.sendBuffer('Not a valid number.'#13#10);
    exit;
    end
  else
    begin
    ch.sendBuffer('Usage: NOTE READ <number>'#13#10);
    ch.sendBuffer('       NOTE WRITE'#13#10);
    ch.sendBuffer('       NOTE LIST'#13#10);

    if (ch.IS_IMMORT) then
      ch.sendBuffer('       NOTE DELETE <number>'#13#10);

    exit;
    end
end;

// Bulletinboard - Nemesis
procedure do_board(ch : GCharacter; param : string);
var node : GListNode;
    i, counter, boardnumber : integer;
    note : GNote;
    arg1 : string;
begin
  if (ch.IS_NPC) then
    exit;

  param := one_argument(param, arg1);

  if (length(arg1) > 0) then
    begin
    try
      boardnumber := strtoint(arg1);

      if (boardnumber < BOARD1) or (boardnumber >= BOARD_MAX) or ((boardnumber = BOARD_IMM) and (not ch.IS_IMMORT)) then
        begin
        ch.sendBuffer('That board is not available.'#13#10);
        exit;
        end;

      ch.player^.active_board := boardnumber;
      ch.sendBuffer('Current board changed to ' + board_names[ch.player^.active_board] + '.'#13#10);
      exit;
    except
      arg1 := '';
    end;
    end;

  if (length(arg1) = 0) then
    begin
    ch.sendBuffer(ansiColor(2,0) + 'Num       Name New Description'#13#10);
    ch.sendBuffer(ansiColor(2,0) + '=== ========== === ================'#13#10);

    for i:=1 to BOARD_MAX-1 do
      begin
      counter := 0;
      node := notes.head;

      while (node <> nil) do
        begin
        note := node.element;

        if (note.board = i) then
          begin
          if (note.number > counter) then
            counter := note.number;
          end;

        node := node.next;
        end;

      counter := counter - ch.player^.boards[i];

      if (i = BOARD_IMM) then
        begin
        if (ch.IS_IMMORT) then
          ch.sendBuffer(ansiColor(2,0) + ' ' + inttostr(i) + '> ' + pad_string_front(board_names[i],10) + ' ' + pad_integer_front(counter,3) + ' ' + board_descr[i] + #13#10);
        end
      else
        ch.sendBuffer(ansiColor(2,0) + ' ' + inttostr(i) + '> ' + pad_string_front(board_names[i],10) + ' ' + pad_integer_front(counter,3) + ' ' + board_descr[i] + #13#10);
      end;

    ch.sendBuffer(#13#10 + ansiColor(2,0) + 'Your current board is ' + board_names[ch.player^.active_board] + '.'#13#10);

    if (ch.player^.active_board = BOARD_NEWS) and (not ch.IS_IMMORT) then
      ch.sendBuffer(ansiColor(2,0) + 'You can only read from this board.'#13#10)
    else
      ch.sendBuffer(ansiColor(2,0) + 'You can both read and write on this board.'#13#10);
    end;
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
