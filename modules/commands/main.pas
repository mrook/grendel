unit main;

interface

implementation

uses
  SysUtils,
  Strip,
  Math,
{$IFDEF LINUX}
  Libc,
{$ENDIF}
{$IFDEF WIN32}
  Winsock,
{$ENDIF}
  ansiio,
  NameGen,
  progs,
  gvm,
  channels,
  race,
  clan,
  mudspell,
  magic,
  area,
  update,
  skills,
  mudsystem,
  mudhelp,
  conns,
  dtypes,
  chars,
  constants,
  timers,
  util,
  md5,
  fight,
  bulletinboard,
  modules,
  mudthread;

{ The complete quit procedure, which even logs off NPCs! - Grimlord }
procedure do_quit(ch : GCharacter; param : string);
var
   timer : GTimer;
begin
  if (ch.IS_NPC) then
    exit;

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

  GPlayer(ch).quit;
end;

procedure do_save(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC) then
    exit;

  GPlayer(ch).save(ch.name^);
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

{ Xenon 22/Apr/2001: helper function for do_help() and do_apropos() }
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


{ Revised help - Nemesis }
{ Xenon 16/Apr/2001: - help without arguments now gives sorted keywordlist
                     - help with an arg that matches multiple keywords will show matching keywords}
procedure do_help(ch : GCharacter; param : string);
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
begin
  ch.sendBuffer('Disfunctional. Sorry.'#13#10);
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

  if (not MD5Match(GPlayer(ch).md5_password, MD5String(param))) then
    begin
    ch.sendBuffer('Type DELETE <password> to delete. WARNING: This is irreversible!'#13#10);
    exit;
    end;

  GConnection(ch.conn).send('You feel yourself dissolving, atom by atom...'#13#10);

  write_console(ch.name^ + ' has deleted');
  GPlayer(ch).quit;

  assignfile(f, 'players\' + ch.name^ + '.usr');
  rename(f, 'backup\' + ch.name^ + '.usr');
end;

procedure do_wimpy(ch : GCharacter; param : string);
var wimpy:integer;
begin
  if (length(param) = 0) or (ch.IS_NPC) then
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

  if (wimpy > ch.max_hp div 3) then
    ch.sendBuffer('Your wimpy cannot be higher than 1/3 of your total hps!'#13#10)
  else
    begin
    GPlayer(ch).wimpy := wimpy;
    ch.sendBuffer('Wimpy set to '+inttostr(wimpy)+'.'+#13#10);
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

    ch.sendBuffer('You start writing a note on the ' + board_names[GPlayer(ch).active_board] + ' board.'#13#10);
    GPlayer(ch).startEditing('');
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

      if (note.board = GPlayer(ch).active_board) then
        begin
        inc(counter);
        buf := buf + ch.ansiColor(15) + ' ' + pad_integer_front(note.number,3) + ch.ansiColor(7) + '>   ' + pad_string(note.author,20) + ' ' + note.subject + #13#10;
        end;

      node := node.next;
      end;

    if (counter = 0) then
      buf := ch.ansiColor(7) + 'There are no notes on this board.' + #13#10;

    buf := ch.ansiColor(8) + '[' + ch.ansiColor(9) + 'Num ' + ch.ansiColor(8) + '] ' +
           ch.ansiColor(8) + '[' + ch.ansiColor(9) + 'Author            ' + ch.ansiColor(8) + '] ' +
           ch.ansiColor(8) + '[' + ch.ansiColor(9) + 'Subject               ' + ch.ansiColor(8) + ']' + #13#10 + #13#10 + buf;

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

    note := findNote(GPlayer(ch).active_board, number);

    if (note = nil) then
      begin
      ch.sendBuffer('That is not a valid number.'#13#10);
      exit;
      end;

    buf := ch.ansiColor(3) + add_chars(76, '---- Note by ' + note.author, '-') + #13#10 +
           ch.ansiColor(7) + 'Date:    ' + ch.ansiColor(7) + note.date + #13#10 +
           ch.ansiColor(7) + 'Subject: ' + ch.ansiColor(7) + note.subject + #13#10 +
           ch.ansiColor(3) + add_chars(76, '', '-') + #13#10#13#10 +
           ch.ansiColor(7) + note.text +
           ch.ansiColor(3) + add_chars(76, '', '-') + #13#10;

    ch.sendPager(buf);

    GPlayer(ch).boards[GPlayer(ch).active_board] := number;
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

      if (note.board = GPlayer(ch).active_board) and (note.number = number) then
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

      GPlayer(ch).active_board := boardnumber;
      ch.sendBuffer('Current board changed to ' + board_names[GPlayer(ch).active_board] + '.'#13#10);
      exit;
    except
      arg1 := '';
    end;
    end;

  if (length(arg1) = 0) then
    begin
    act(AT_REPORT, '$8[$B$1Num$A$8] [$B$1Name      $A$8] [$B$1New$A$8] [$B$1Description$A$8]'#13#10,false,ch,nil,nil,TO_CHAR);

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

      counter := counter - GPlayer(ch).boards[i];

      if (i = BOARD_IMM) then
        begin
        if (ch.IS_IMMORT) then
          act(AT_REPORT, '$B$7 ' + pad_integer_front(i, 2) + '$A$7>   ' + pad_string(board_names[i],10) + '   ' + pad_integer(counter,3) + '   ' + board_descr[i],false,ch,nil,nil,TO_CHAR);
        end
      else
        act(AT_REPORT, '$B$7 ' + pad_integer_front(i, 2) + '$A$7>   ' + pad_string(board_names[i],10) + '   ' + pad_integer(counter,3) + '   ' + board_descr[i],false,ch,nil,nil,TO_CHAR);
      end;

    ch.sendBuffer(#13#10 + ch.ansiColor(7) + 'Your current board is ' + board_names[GPlayer(ch).active_board] + '.'#13#10);

    if (GPlayer(ch).active_board = BOARD_NEWS) and (not ch.IS_IMMORT) then
      ch.sendBuffer(ch.ansiColor(7) + 'You can only read from this board.'#13#10)
    else
      ch.sendBuffer(ch.ansiColor(7) + 'You can both read and write on this board.'#13#10);
    end;
end;

{ Xenon 23/Apr/2001: apropos searches through all helpfiles for a match on user input }
procedure do_apropos(ch : GCharacter; param : string);
var
  node : GListNode;
  help : GHelp;
  matchlist : GDLinkedList;
  hk : THelpKeyword;
  s : string;
begin
  if (ch.IS_NPC) then
    exit;

  if (length(param) = 0) then
  begin
    ch.sendBuffer('Usage: APROPOS <text>'#13#10#13#10);
    ch.sendBuffer('Apropos searches for ''text'' in the online helpfiles.'#13#10);
    exit;
  end;

  matchlist := GDLinkedList.Create();
  
  node := help_files.head;
  while (node <> nil) do
  begin
    help := node.element;

    s := help.keywords;
    
    if ((s[length(s)] <> '_') and (pos(param, help.text) > 0) and (help.level <= ch.level)) then
    begin
      hk := THelpKeyword.Create(lowercase(s), help);
      insertAlphabetical(matchlist, hk);
    end;

    node := node.next;
  end;

  if (matchlist.getSize() = 0) then
  begin
    ch.sendBuffer(Format('No matches found for your query ''%s''.'#13#10, [param]));
    exit;
  end
  else
  begin
    ch.sendPager(act_string(Format('Found $B$7%d$A$7 helpfiles that match your query ''$B$7%s$A$7'':'#13#10#13#10, [matchlist.getSize(), param]), ch, nil, nil, nil));
    
    node := matchlist.head;
    while (node <> nil) do
    begin
      hk := node.element;

      ch.sendPager(act_string(Format('  $B$7%s$A$7'#13#10, [hk.keyword]), ch, nil, nil, nil));

      node := node.next;
    end;
  end;

  matchlist.Clean();
  matchlist.Free();
end;

{$INCLUDE cmd_imm.inc}
{$INCLUDE cmd_move.inc}
{$INCLUDE cmd_obj.inc}
{$INCLUDE cmd_shops.inc}
{$INCLUDE cmd_fight.inc}
{$INCLUDE cmd_info.inc}
{$INCLUDE cmd_comm.inc}
{$INCLUDE cmd_build.inc}
{$INCLUDE cmd_magic.inc}
{$INCLUDE cmd_skill.inc}

// registering with the caller
begin
  registerCommand('do_quit', do_quit);
  registerCommand('do_save', do_save);
  registerCommand('do_afk', do_afk);
  registerCommand('do_help', do_help);
  registerCommand('do_remort', do_remort);
  registerCommand('do_delete', do_delete);
  registerCommand('do_wimpy', do_wimpy);
  registerCommand('do_time', do_time);
  registerCommand('do_weather', do_weather);
  registerCommand('do_look', do_look);
  registerCommand('do_inventory', do_inventory);
  registerCommand('do_equipment', do_equipment);
  registerCommand('do_score', do_score);
  registerCommand('do_stats', do_stats);
  registerCommand('do_who', do_who);
  registerCommand('do_title', do_title);
  registerCommand('do_group', do_group);
  registerCommand('do_follow', do_follow);
  registerCommand('do_armor', do_armor);
  registerCommand('do_config', do_config);
  registerCommand('do_visible', do_visible);
  registerCommand('do_trophy', do_trophy);
  registerCommand('do_ditch', do_ditch);
  registerCommand('do_world', do_world);
  registerCommand('do_where', do_where);
  registerCommand('do_kill', do_kill);
  registerCommand('do_north', do_north);
  registerCommand('do_south', do_south);
  registerCommand('do_east', do_east);
  registerCommand('do_west', do_west);
  registerCommand('do_up', do_up);
  registerCommand('do_down', do_down);
  registerCommand('do_sleep', do_sleep);
  registerCommand('do_wake', do_wake);
  registerCommand('do_meditate', do_meditate);
  registerCommand('do_rest', do_rest);
  registerCommand('do_sit', do_sit);
  registerCommand('do_stand', do_stand);
  registerCommand('do_flee', do_flee);
  registerCommand('do_flurry', do_flurry);
  registerCommand('do_assist', do_assist);
  registerCommand('do_disengage', do_disengage);
  registerCommand('do_cast', do_cast);
  registerCommand('do_bash', do_bash);
  registerCommand('do_kick', do_kick);
  registerCommand('do_fly', do_fly);
  registerCommand('do_sneak', do_sneak);
  registerCommand('do_spells', do_spells);
  registerCommand('do_skills', do_skills);
  registerCommand('do_learn', do_learn);
  registerCommand('do_practice', do_practice);
  registerCommand('do_enter', do_enter);
  registerCommand('do_search', do_search);
  registerCommand('do_backstab', do_backstab);
  registerCommand('do_circle', do_circle);
  registerCommand('do_tell', do_tell);
  registerCommand('do_reply', do_reply);
  registerCommand('do_suggest', do_suggest);
  registerCommand('do_pray', do_pray);
  registerCommand('do_emote', do_emote);
  registerCommand('do_shutdown', do_shutdown);
  registerCommand('do_echo', do_echo);
  registerCommand('do_wizinvis', do_wizinvis);
  registerCommand('do_sla', do_sla);
  registerCommand('do_slay', do_slay);
  registerCommand('do_affects', do_affects);
  registerCommand('do_socials', do_socials);
  registerCommand('do_advance', do_advance);
  registerCommand('do_get', do_get);
  registerCommand('do_wear', do_wear);
  registerCommand('do_remove', do_remove);
  registerCommand('do_drop', do_drop);
  registerCommand('do_swap', do_swap);
  registerCommand('do_drink', do_drink);
  registerCommand('do_eat', do_eat);
  registerCommand('do_scalp', do_scalp);
  registerCommand('do_give', do_give);
  registerCommand('do_throw', do_throw);
  registerCommand('do_alias', do_alias);
  registerCommand('do_clanadd', do_clanadd);
  registerCommand('do_clanremove', do_clanremove);
  registerCommand('do_clan', do_clan);
  registerCommand('do_brag', do_brag);
  registerCommand('do_force', do_force);
  registerCommand('do_restore', do_restore);
  registerCommand('do_goto', do_goto);
  registerCommand('do_transfer', do_transfer);
  registerCommand('do_peace', do_peace);
  registerCommand('do_areas', do_areas);
  registerCommand('do_connections', do_connections);
  registerCommand('do_uptime', do_uptime);
  registerCommand('do_grace', do_grace);
  registerCommand('do_open', do_open);
  registerCommand('do_close', do_close);
  registerCommand('do_consider', do_consider);
  registerCommand('do_scan',  do_scan);
  registerCommand('do_sacrifice', do_sacrifice);
  registerCommand('do_bgset', do_bgset);
  registerCommand('do_battle', do_battle);
  registerCommand('do_auction', do_auction);
  registerCommand('do_bid', do_bid);
  registerCommand('do_balance', do_balance);
  registerCommand('do_withdraw', do_withdraw);
  registerCommand('do_deposit', do_deposit);
  registerCommand('do_list', do_list);
  registerCommand('do_buy', do_buy);
  registerCommand('do_sell', do_sell);
  registerCommand('do_rescue', do_rescue);
  registerCommand('do_disconnect', do_disconnect);
  registerCommand('do_wizhelp', do_wizhelp);
  registerCommand('do_rstat', do_rstat);
  registerCommand('do_pstat', do_pstat);
  registerCommand('do_ostat', do_ostat);
  registerCommand('do_report', do_report);
  registerCommand('do_destroy', do_destroy);
  registerCommand('do_loadup', do_loadup);
  registerCommand('do_freeze', do_freeze);
  registerCommand('do_silence', do_silence);
  registerCommand('do_log', do_log);
  registerCommand('do_snoop', do_snoop);
  registerCommand('do_switch', do_switch);
  registerCommand('do_return', do_return);
  registerCommand('do_sconfig', do_sconfig);
  registerCommand('do_track', do_track);
  registerCommand('do_bamfin', do_bamfin);
  registerCommand('do_bamfout', do_bamfout);
  registerCommand('do_mload', do_mload);
  registerCommand('do_oload', do_oload);
  registerCommand('do_mfind', do_mfind);
  registerCommand('do_ofind', do_ofind);
  registerCommand('do_put', do_put);
  registerCommand('do_sset', do_sset);
  registerCommand('do_taunt', do_taunt);
  registerCommand('do_nourish', do_nourish);
  registerCommand('do_mana', do_mana);
  registerCommand('do_fill', do_fill);
  registerCommand('do_unlock', do_unlock);
  registerCommand('do_lock', do_lock);
  registerCommand('do_pset', do_pset);
  registerCommand('do_revive', do_revive);
  registerCommand('do_setpager', do_setpager);
  registerCommand('do_autoloot', do_autoloot);
  registerCommand('do_autosac', do_autosac);
  registerCommand('do_password', do_password);
  registerCommand('do_ban', do_ban);
  registerCommand('do_allow', do_allow);
  registerCommand('do_last', do_last);
  registerCommand('do_unlearn', do_unlearn);
  registerCommand('do_hashstats', do_hashstats);
  registerCommand('do_keylock', do_keylock);
  registerCommand('do_take', do_take);
  registerCommand('do_holywalk', do_holywalk);
  registerCommand('do_prename', do_prename);
  registerCommand('do_peek', do_peek);
  registerCommand('do_ocreate', do_ocreate);
  registerCommand('do_oedit', do_oedit);
  registerCommand('do_olist', do_olist);
  registerCommand('do_redit', do_redit);
  registerCommand('do_rlink', do_rlink);
  registerCommand('do_rmake', do_rmake);
  registerCommand('do_rclone', do_rclone);
  registerCommand('do_aassign', do_aassign);
  registerCommand('do_ranges', do_ranges);
  registerCommand('do_acreate', do_acreate);
  registerCommand('do_aset', do_aset);
  registerCommand('do_astat', do_astat);
  registerCommand('do_raceinfo', do_raceinfo);
  registerCommand('do_checkarea', do_checkarea);
  registerCommand('do_savearea', do_savearea);
  registerCommand('do_loadarea', do_loadarea);
  registerCommand('do_reset', do_reset);
  registerCommand('do_map', do_map);
  registerCommand('do_holylight', do_holylight);
  registerCommand('do_prompt', do_prompt);
  registerCommand('do_at', do_at);
  registerCommand('do_namegen', do_namegen);
  registerCommand('do_note', do_note);
  registerCommand('do_board', do_board);
  registerCommand('do_apropos', do_apropos);
  registerCommand('do_say', do_say);
  registerCommand('do_channel', do_channel);
  registerCommand('do_vnums', do_vnums);
  registerCommand('do_aranges', do_aranges);
  registerCommand('do_rlist', do_rlist);
  registerCommand('do_rdelete', do_rdelete);
  registerCommand('do_coordgen', do_coordgen);
  registerCommand('do_findpath', do_findpath);
  registerCommand('do_reload', do_reload);
  registerCommand('do_modules', do_modules);
end.