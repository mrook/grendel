unit mudthread;

interface

uses
    Classes,
    Windows,
    Winsock2,
    SysUtils,
    ansiio,
    constants,
    conns,
    chars,
    race,
    clan,
    area,
    dtypes,
    skills,
    strip,
    util,
    mudhelp,
    mudsystem;

type
    GGameThread = class(TThread)
    private
      socket : TSocket;
      client_addr : TSockAddr_Storage;
      copyover : boolean;
      copyover_name : string;

    protected
      procedure Execute; override;

    public
      last_update : TDateTime;
      
      constructor Create(s : TSocket; a : TSockAddr_Storage; copy : boolean; name : string);
    end;

    COMMAND_FUNC = procedure(ch : GCharacter; param : string);

    GCommandFunc = class
      name : string;
      func : COMMAND_FUNC;
    end;

    GCommand = class
      name : string;
      func_name : string;
      ptr : COMMAND_FUNC;
      level : integer;             { minimum level }
      position : integer;          { minimum position }
    end;

var
   commands : GHashObject;
   func_list : GDLinkedList;

procedure load_commands;
procedure interpret(ch : GCharacter; line : string);

procedure registerCommand(name : string; func : COMMAND_FUNC);
procedure registerCommands;

implementation

uses
    magic,
    md5,
    update,
    progs,
    timers,
    debug,
    mudspell,
    fight,
    NameGen;

constructor GGameThread.Create(s : TSocket; a : TSockAddr_Storage; copy : boolean; name : string);
begin
  inherited Create(False);

  socket := s;
  client_addr := a;
  copyover := copy;
  copyover_name := name;
  last_update := Now();
end;

{$I include\command.inc}

procedure do_dummy(ch : GCharacter; param : string);
begin
  ch.sendBuffer('This is a DUMMY command. Please contact the ADMINISTRATION.'#13#10);
end;

function findCommand(s : string) : COMMAND_FUNC;
var
   g : COMMAND_FUNC;
   node : GListNode;
   f : GCommandFunc;
begin
  Result := nil;

  node := func_list.head;

  while (node <> nil) do
    begin
    f := node.element;

    if (f.name = s) then
      begin
      Result := f.func;
      exit;
      end;

    node := node.next;
    end;

  write_console('Could not find command "' + s + '"');
end;

procedure load_commands;
var f:textfile;
    s,g:string;
    cmd, alias : GCommand;
begin
  assignfile(f, 'system\commands.dat');
  {$I-}
  reset(f);
  {$I+}
  if IOResult<>0 then
    begin
    bugreport('load_commands', 'mudthread.pas', 'could not open system\commands.dat',
              'The system file commands.dat could not be opened.');
    exit;
    end;

  commands := GHashObject.Create(32);
  commands.setHashFunc(firstHash);

  repeat
    repeat
      readln(f,s);
    until (uppercase(s) = '#COMMAND') or eof(f);

    if (eof(f)) then
      break;

    alias := nil;
    cmd := GCommand.Create;
    cmd.position := POS_MEDITATE;

    with cmd do
      repeat
      readln(f,s);
      g:=uppercase(left(s,':'));

      if g='NAME' then
        name := uppercase(right(s,' '))
      else
      if g='ALIAS' then
        begin
        // create an alias
        alias := GCommand.Create;
        alias.name := uppercase(right(s,' '));
        end
      else
      if g='LEVEL' then
        level:=strtoint(right(s,' '))
      else
      if g='POSITION' then
        position:=strtoint(right(s,' '))
      else
      if g='FUNCTION' then
        begin
        func_name := right(s,' ');
        ptr := findCommand(func_name);
        end;
      until (uppercase(s)='#END') or eof(f);

    if (assigned(cmd.ptr)) then
      begin
      commands.hashObject(cmd, cmd.name);

      if (alias <> nil) then
        begin
        // update settings
        alias.level := cmd.level;
        alias.ptr := cmd.ptr;
        alias.func_name := cmd.func_name;
        alias.position := cmd.position;

        commands.hashObject(alias, alias.name);
        end;
      end
    else
      begin
      cmd.Free;

      if (alias <> nil) then
        alias.Free;
      end;
  until eof(f);

  closefile(f);
end;

procedure clean_cmdline(var line : string);
var
   d : integer;
begin
  d := pos('$', line);

  while (d > 0) do
    begin
    delete(line, d, 1);

    d := pos('$', line);
    end;
end;

procedure interpret(ch : GCharacter; line : string);
var
    a, g : longint;
    cmd : GCommand;
    node : GListNode;
    cmdline, param : string;
    hash, time : cardinal;
    al : GAlias;
begin
  with ch do
    begin
    { Check if keyboard is locked - Nemesis }
    if (conn <> nil) and (IS_KEYLOCKED) and (not IS_NPC) then
      begin
      if (length(line) = 0) then
        begin
        sendBuffer('Enter your password to unlock keyboard.'#13#10);
        exit;
        end;

      if (not MD5Match(player^.md5_password, MD5String(line))) then
        begin
        sendBuffer('Wrong password!'#13#10);
        exit;
        end
      else
        begin
        GConnection(conn).afk := false;
        GConnection(conn).keylock := false;

        act(AT_REPORT,'You are now back at your keyboard.',false,ch,nil,nil,to_char);
        act(AT_REPORT,'$n has returned to $s keyboard.',false,ch,nil,nil,to_room);
        exit;
        end;
      end;

    { AFK revised with keylock - Nemesis }
    if (conn <> nil) and (IS_AFK) and (not IS_NPC) and (not IS_KEYLOCKED) then
      begin
      GConnection(conn).afk := false;

      act(AT_REPORT,'You are now back at your keyboard.',false,ch,nil,nil,to_char);
      act(AT_REPORT,'$n has returned to $s keyboard.',false,ch,nil,nil,to_room);
      end;

    if (ch.position = POS_CASTING) then
      begin
      act(AT_REPORT, 'You stop casting.', false, ch, nil, nil, TO_CHAR);
      unregisterTimer(ch, TIMER_CAST);
      ch.position := POS_STANDING;
      end;

    if (length(line) = 0) then
      begin
      ch.sendBuffer(' ');
      exit;
      end;

    if (snooped_by <> nil) then
        GConnection(snooped_by.conn).send(line + #13#10);

    clean_cmdline(line);

    param := one_argument(line, cmdline);
    cmdline := uppercase(cmdline);

    // check for aliases first
    if (not ch.IS_NPC) then
      begin
      node := ch.player^.aliases.head;

      while (node <> nil) do
        begin
        al := node.element;

        if (uppercase(al.alias) = cmdline) then
          begin
          line := al.expand + ' ' + param;
          param := one_argument(line, cmdline);
          cmdline := uppercase(cmdline);

          break;
          end;

        node := node.next;
        end;
      end;

    cmd := nil;

    hash := commands.getHash(cmdline);
    node := commands.bucketList[hash].head;

    while (node <> nil) do
      begin
      if (pos(cmdline, GCommand(node.element).name) = 1) then
        begin
        cmd := GCommand(node.element);
        break;
        end;

      node := node.next;
      end;

    if (cmd <> nil) then
      begin
      a := ch.getTrust;

      if (a >= cmd.level) then
        begin
        if (cmd.position > position) then
          case position of
            POS_SLEEPING: ch.sendBuffer('You are off to dreamland.'#13#10);
            POS_MEDITATE: ch.sendBuffer('You must break out of your trance first.'#13#10);
             POS_RESTING: ch.sendBuffer('You feel too relaxed to do this.'#13#10);
             POS_SITTING: ch.sendBuffer('You must get on your feet first.'#13#10);
            POS_FIGHTING: ch.sendBuffer('You are fighting!'#13#10);
          end
        else
          begin
          if (system_info.log_all) or (IS_SET(ch.act_flags, ACT_LOG)) then
            write_log(ch.name^ + ': ' + line);

          if (cmd.level >= LEVEL_IMMORTAL) then
            write_console('[LOG] ' + ch.name^ + ': ' + cmd.name + ' (' + inttostr(cmd.level) + ')');

          try
            time := GetTickCount;

            cmd.ptr(ch, param);

            ch.last_cmd := @cmd.ptr;

            { Disabled this, this is too computer specific, e.g. on a 486
              some commands could lag while on a Pentium they would not.
              Uncomment if CPU leaks are to be traced. - Grimlord }

            time := GetTickCount - time;

            if (time > 1500) and (not ch.CHAR_DIED) then
              bugreport('interpret','mudthread.pas', cmd.func_name + ', ch ' + ch.name^ + ' lagged', 'The command took over 1.5 sec to complete.');
          except
            on E : EExternal do
              outputError(E.ExceptionRecord.ExceptionAddress);

              //bugreport('interpret', 'mudthread.pas', cmd.func_name + ', ch ' + ch.name^ + ' bugged',
              //          'The specified command caused an error and has been terminated.');
          end;
          end;
        end
      else
        cmd := nil;
      end;

    if (cmd = nil) and (not checkSocial(ch, cmdline, param)) then
      begin
      a := random(9);
      if a<1 then
        cmdline := 'Sorry, that command doesn''t exist in my vocabulaire!'
      else
      if a<2 then
        cmdline := 'I don''t understand you.'
      else
      if a<3 then
        cmdline := 'What are you saying?'
      else
      if a<4 then
        cmdline := 'Learn some english!'
      else
      if a<5 then
        cmdline := 'Hey, I don''t know that command. Try again.'
      else
      if a<6 then
        cmdline := 'What??'
      else
      if a<7 then
        cmdline := 'Huh?'
      else
      if a<8 then
        cmdline := 'Yeah, right!'
      else
      if a<9 then
        cmdline := 'What you say??';

      act(AT_DGREEN, cmdline, false, ch, nil, nil, TO_CHAR);
      end;
  end;
end;

procedure nanny(conn : GConnection; argument : string);
var ch, vict : GCharacter;
    node : GListNode;
    race : GRace;
    digest : MD5Digest;
    h,top,x,temp:integer;
    buf, pwd : string;
begin
  ch := conn.ch;

  case conn.state of
        CON_NAME: begin
                  pwd := one_argument(argument, argument);
                  
                  if (length(argument) = 0) then
                    begin
                    conn.send('Please enter your name: ');
                    exit;
                    end;

                  if (uppercase(argument) = 'CREATE') then
                    begin
                    conn.send(#13#10'By what name do you wish to be known? ');
                    conn.state := CON_NEW_NAME;
                    exit;
                    end;

                  vict := findCharWorld(nil, argument);

                  if (vict <> nil) and (not vict.IS_NPC) and (vict.conn <> nil) then
                    begin
                    if (not MD5Match(MD5String(pwd), vict.player^.md5_password)) then
                      begin
                      conn.send(#13#10'You are already logged in under that name! Type your name and password on one line to break in.'#13#10);
                      closesocket(conn.socket);
                      conn.thread.Terminate;
                      end
                    else
                      begin
                      GConnection(vict.conn).thread.Terminate;

                      while (not IS_SET(vict.player^.flags, PLR_LINKLESS)) do;

                      vict.conn := conn;
                      conn.ch := vict;
                      ch := vict;
                      REMOVE_BIT(conn.ch.player^.flags,PLR_LINKLESS);
                      conn.state := CON_PLAYING;
                      conn.ch.sendPrompt;
                      end;

                    exit;
                    end;

                  if (not ch.load(argument)) then
                    begin
                    conn.send(#13#10'Are you sure about that name?'#13#10'Name: ');
                    exit;
                    end;

                  conn.state:=CON_PASSWORD;
                  conn.send('Password: ');
                  end;
    CON_PASSWORD: begin
                  if (length(argument) = 0) then
                    begin
                    conn.send('Password: ');
                    exit;
                    end;

                  if (not MD5Match(MD5String(argument), ch.player^.md5_password)) then
                    begin
                    write_console('(' + inttostr(conn.socket) + ') Failed password');
                    conn.send('Wrong password.'#13#10);
                    closesocket(conn.socket);
                    exit;
                    end;

                  vict := findCharWorld(nil, ch.name^);

                  if (vict <> nil) and (vict.conn = nil) then
                    begin
                    ch.Free;

                    conn.ch := vict;
                    ch := vict;
                    vict.conn := conn;

                    ch.player^.ld_timer := 0;

                    conn.send('You have reconnected.'#13#10);
                    act(AT_REPORT, '$n has reconnected.', false, ch, nil, nil, TO_ROOM);
                    REMOVE_BIT(ch.player^.flags, PLR_LINKLESS);
                    write_console('(' + inttostr(conn.socket) + ') ' + ch.name^ + ' has reconnected');

                    ch.sendPrompt;
                    conn.state := CON_PLAYING;
                    exit;
                    end;

                  if (ch.IS_IMMORT) then
                    conn.send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                  else
                    conn.send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                  conn.send('Press Enter.'#13#10);
                  conn.state := CON_MOTD;
                  end;
        CON_MOTD: begin
                  conn.send(ch.ansiColor(6) + #13#10#13#10'Welcome, ' + ch.name^ + ', to this MUD. May your stay be pleasant.'#13#10);

                  with system_info do
                    begin
                    user_cur := connection_list.getSize;
                    if (user_cur > user_high) then
                      user_high := user_cur;
                    end;

                  ch.toRoom(ch.room);

                  act(AT_WHITE, '$n enters through a magic portal.', true, ch, nil, nil, TO_ROOM);
                  write_console('(' + inttostr(conn.socket) + ') '+ ch.name^ +' has logged in');

                  ch.node_world := char_list.insertLast(ch);
                  ch.player^.logon_now := Now;

                  if (ch.level = LEVEL_RULER) then
                    do_uptime(ch, '')
                  else
                    ch.sendPrompt;

                  conn.state := CON_PLAYING;
                  conn.fcommand := true;
                  end;
    CON_NEW_NAME: begin
                  if (length(argument) = 0) then
                    begin
                    conn.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  if (FileExists('players\' + argument + '.usr')) then
                    begin
                    conn.send('That name is already used.'#13#10);
                    conn.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  vict := findCharWorld(nil, argument);
                  (* if ((banned_names.indexof(uppercase(argument)) <> -1) or ((vict <> nil) and (uppercase(vict.name) = uppercase(argument)))) then
                    begin
                    send_to_conn(conn,'That name cannot be used.'#13#10);
                     send_to_conn(conn,'By what name do you wish to be known? ');
                    exit;
                    end; *)

                  if (length(argument) < 3) or (length(argument) > 15) then
                    begin
                    conn.send('Your name must be between 3 and 15 characters long.'#13#10);
                    conn.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  ch.name := hash_string(cap(argument));
                  conn.state := CON_NEW_PASSWORD;
                  conn.send(#13#10'Allright, '+ch.name^+', choose a password: ');
                  end;
CON_NEW_PASSWORD: begin
                  if (length(argument)=0) then
                    begin
                    conn.send('Choose a password: ');
                    exit;
                    end;

                  new(ch.player);
                  ch.player^.md5_password := MD5String(argument);
                  conn.state := CON_CHECK_PASSWORD;
                  conn.send(#13#10'Please retype your password: ');
                  end;
CON_CHECK_PASSWORD: begin
                    if (length(argument) = 0) then
                      begin
                      conn.send('Please retype your password: ');
                      exit;
                      end;

                    if (not MD5Match(MD5String(argument), ch.player^.md5_password)) then
                      begin
                      conn.send(#13#10'Password did not match!'#13#10'Choose a password: ');
                      conn.state := CON_NEW_PASSWORD;
                      exit;
                      end
                    else
                      begin
                      conn.state := CON_NEW_SEX;
                      conn.send(#13#10'What sex do you wish to be (M/F/N): ');
                      exit;
                      end;
                    end;
     CON_NEW_SEX: begin
                  if (length(argument) = 0) then
                    begin
                    conn.send('Choose a sex (M/F/N): ');
                    exit;
                    end;

                  case upcase(argument[1]) of
                    'M':ch.sex:=0;
                    'F':ch.sex:=1;
                    'N':ch.sex:=2;
                  else
                    begin
                    conn.send('That is not a valid sex.'#13#10);
                    conn.send('Choose a sex (M/F/N): ');
                    exit;
                    end;
                  end;

                  conn.state:=CON_NEW_RACE;
                  conn.send(#13#10'Available races: '#13#10#13#10);

                  h:=1;
                  node := race_list.head;
                  while (node <> nil) do
                    begin
                    race := node.element;

                    buf := '  ['+inttostr(h)+']  '+pad_string(race.name,15);

                    if (race.def_alignment < 0) then
                      buf := buf + ANSIColor(12,0) + '<- EVIL'+ANSIColor(7,0);

                    buf := buf + #13#10;

                    conn.send(buf);

                    inc(h);
                    node := node.next;
                    end;

                  conn.send(#13#10'Choose a race: ');
                  end;
    CON_NEW_RACE: begin
                  if (length(argument)=0) then
                    begin
                    conn.send(#13#10'Choose a race: ');
                    exit;
                    end;

                  try
                    x:=strtoint(argument);
                  except
                    x:=-1;
                  end;

                  race := nil;
                  node := race_list.head;
                  h := 1;

                  while (node <> nil) do
                    begin
                    if (h = x) then
                      begin
                      race := node.element;
                      break;
                      end;

                    inc(h);
                    node := node.next;
                    end;

                  if (race = nil) then
                    begin
                    conn.send('Not a valid race.'#13#10);

                    h:=1;
                    node := race_list.head;
                    while (node <> nil) do
                      begin
                      race := node.element;

                      buf := '  ['+inttostr(h)+']  '+pad_string(race.name,15);

                      if (race.def_alignment < 0) then
                        buf := buf + ANSIColor(12,0) + '<- EVIL'+ANSIColor(7,0);

                      buf := buf + #13#10;

                      conn.send(buf);

                      inc(h);
                      node := node.next;
                      end;

                    conn.send(#13#10'Choose a race: ');
                    exit;
                    end;

                  ch.race:=race;
                  conn.send(race.description);
                  conn.send('250 stat points will be randomly distributed over your five attributes.'#13#10);
                  conn.send('It is impossible to get a lower or a higher total of stat points.'#13#10);

                  with ch.ability do
                    begin
                    top:=250;

                    str:=URange(25,random(UMax(top,75))+ch.race.str_bonus,75);
                    dec(top,str);

                    con:=URange(25,random(UMax(top,75))+ch.race.con_bonus,75);
                    dec(top,con);

                    dex:=URange(25,random(UMax(top,75))+ch.race.dex_bonus,75);
                    dec(top,dex);

                    int:=URange(25,random(UMax(top,75))+ch.race.int_bonus,75);
                    dec(top,int);

                    wis:=URange(25,random(UMax(top,75))+ch.race.wis_bonus,75);
                    dec(top,wis);

                    while (top>0) do
                      begin
                      x:=random(5);

                      case x of
                        0:begin
                          temp:=UMax(75-str,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            inc(str,temp);
                            end;
                          end;
                        1:begin
                          temp:=UMax(75-con,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            inc(con,temp);
                            end;
                          end;
                        2:begin
                          temp:=UMax(75-dex,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            inc(dex,temp);
                            end;
                          end;
                        3:begin
                          temp:=UMax(75-int,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            inc(int,temp);
                            end;
                          end;
                        4:begin
                          temp:=UMax(75-wis,top);
                          if (temp>0) then
                           begin
                            dec(top,temp);
                            inc(wis,temp);
                            end;
                          end;
                      end;
                    end;

                    top:=str+con+dex+int+wis;

                    // temporarily disabled this one - Grimlord [31/01/2000]
                    { if (top<250) then
                      bugreport('roll_char','total stats lower than 250')
                    else
                    if (top>250) then
                      bugreport('roll_char','total stats more than 250'); }

                    conn.send(#13#10'Your character statistics are: '#13#10#13#10);

                    buf := 'Strength:     '+ANSIColor(10,0)+inttostr(str)+ANSIColor(7,0)+#13#10 +
                           'Constitution: '+ANSIColor(10,0)+inttostr(con)+ANSIColor(7,0)+#13#10 +
                           'Dexterity:    '+ANSIColor(10,0)+inttostr(dex)+ANSIColor(7,0)+#13#10 +
                           'Intelligence: '+ANSIColor(10,0)+inttostr(int)+ANSIColor(7,0)+#13#10 +
                           'Wisdom:       '+ANSIColor(10,0)+inttostr(wis)+ANSIColor(7,0)+#13#10;
                    conn.send(buf);
                    end;

                  conn.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                  conn.state:=CON_NEW_STATS;
                  end;
   CON_NEW_STATS: begin
                  if (length(argument) =0) then
                    begin
                    conn.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                    exit;
                    end;

                  case (upcase(argument[1])) of
                    'C':begin
                        digest := ch.player^.md5_password;

                        ch.load(ch.name^);
                        ch.player^.md5_password := digest;
                        ch.save(ch.name^);

                        conn.send(#13#10'Thank you. You have completed your entry.'#13#10);

                        conn.send(ch.ansiColor(2) + #13#10);

                        if (ch.IS_IMMORT) then
                          conn.send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                        else
                          conn.send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                        conn.send('Press Enter.'#13#10);
                        conn.state:=CON_MOTD;
                        end;
                    'R':begin
                        with ch.ability do
                          begin
                          top:=250;

                          str:=URange(25,random(UMax(top,75))+ch.race.str_bonus,75);
                          dec(top,str);

                          con:=URange(25,random(UMax(top,75))+ch.race.con_bonus,75);
                          dec(top,con);

                          dex:=URange(25,random(UMax(top,75))+ch.race.dex_bonus,75);
                          dec(top,dex);

                          int:=URange(25,random(UMax(top,75))+ch.race.int_bonus,75);
                          dec(top,int);

                          wis:=URange(25,random(UMax(top,75))+ch.race.wis_bonus,75);
                          dec(top,wis);

                          while (top>0) do
                            begin
                            x:=random(5);

                            case x of
                              0:begin
                                temp:=UMax(75-str,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  inc(str,temp);
                                  end;
                                end;
                              1:begin
                                temp:=UMax(75-con,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  inc(con,temp);
                                  end;
                                end;
                              2:begin
                                temp:=UMax(75-dex,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  inc(dex,temp);
                                  end;
                                end;
                              3:begin
                                temp:=UMax(75-int,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  inc(int,temp);
                                  end;
                                end;
                              4:begin
                                temp:=UMax(75-wis,top);
                                if (temp>0) then
                                 begin
                                  dec(top,temp);
                                  inc(wis,temp);
                                  end;
                                end;
                            end;
                          end;

                          top:=str+con+dex+int+wis;

                          // temporarily disabled this one - Grimlord [31/01/2000]
                          { if (top<250) then
                            bugreport('roll_char','total stats lower than 250')
                          else
                          if (top>250) then
                            bugreport('roll_char','total stats more than 250'); }

                          conn.send(#13#10'Your character statistics are: '#13#10#13#10);

                          buf := 'Strength:     '+ANSIColor(10,0)+inttostr(str)+ANSIColor(7,0)+#13#10 +
                                 'Constitution: '+ANSIColor(10,0)+inttostr(con)+ANSIColor(7,0)+#13#10 +
                                 'Dexterity:    '+ANSIColor(10,0)+inttostr(dex)+ANSIColor(7,0)+#13#10 +
                                 'Intelligence: '+ANSIColor(10,0)+inttostr(int)+ANSIColor(7,0)+#13#10 +
                                 'Wisdom:       '+ANSIColor(10,0)+inttostr(wis)+ANSIColor(7,0)+#13#10;
                          conn.send(buf);
                          end;

                        conn.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                        end;
                    'S':begin
                        conn.send(#13#10'Very well, restarting.'#13#10);
                        conn.send('By what name do you wish to be known?');
                        conn.state:=CON_NEW_NAME;
                        end;
                  else
                    conn.send('Do you wish to (C)ontinue, (R)eroll or (S)art over? ');
                    exit;
                 end;
                 end;
    else
      bugreport('nanny', 'mudthread.pas', 'illegal state ' + inttostr(conn.state),
                'The specified connection state is unknown. Someone may be hacking.');
  end;
end;

procedure GGameThread.Execute;
var conn : GConnection;
    cmdline : string;
    temp_buf : string;
    ch : GCharacter;
    i : integer;

label nameinput,stopthread;
begin
  freeonterminate := true;

  conn := GConnection.Create(socket, client_addr, Self);

  write_console('(' + inttostr(socket) + ') New connection (' + conn.host_string + ')');

  if (isMaskBanned(conn.host_string)) then
    begin
    write_console('('+inttostr(socket)+') Closed banned IP (' + conn.host_string + ')');

    conn.send(system_info.mud_name+#13#10#13#10);
    conn.send('Your site has been banned from this server.'#13#10);
    conn.send('For more information, please mail the administration, '+system_info.admin_email+'.'#13#10);
    closesocket(socket);
    conn.Free;
    exit;
    end;

  ch := GCharacter.Create;
  conn.ch := ch;
  ch.conn := conn;

  if (not copyover) then
    begin
    conn.state := CON_NAME;

    conn.send(AnsiColor(2,0) + findHelp('M_DESCRIPTION_').text);

    temp_buf := AnsiColor(6,0) + #13#10;

    temp_buf := temp_buf + version_info + ', ' + version_number + '.'#13#10;
    temp_buf := temp_buf + version_copyright + '.';
    temp_buf := temp_buf + #13#10'This is free software, with ABSOLUTELY NO WARRANTY; view LICENSE.TXT.';
    temp_buf := temp_buf + AnsiColor(7,0) + #13#10;

    conn.send(temp_buf);

    conn.send(#13#10#13#10'Enter your name or CREATE to create a new character.'#13#10'Please enter your name: ');
    end
  else
    begin
    conn.state := CON_MOTD;

    conn.ch.name := hash_string(copyover_name);
    conn.ch.load(copyover_name);
    conn.send(#13#10#13#10'Gradually, the clouds form real images again, recreating the world...'#13#10);
    conn.send('Copyover complete!'#13#10);

    nanny(conn, '');
    end;

  repeat
    if (conn.fcommand) then
      begin
      if (conn.pagepoint <> 0) then
        conn.outputPager
      else
        conn.ch.emptyBuffer;
      end;

    conn.fcommand:=false;
    sleep(100);

    last_update := Now();

    conn.checkReceive;

    if (not Terminated) then
      conn.read;

    if (not Terminated) and (conn.ch.wait > 0) then
      continue;

    if (not Terminated) then
      conn.readBuffer;

    if (length(conn.comm_buf) > 0) then
      begin
      cmdline := trim(conn.comm_buf);

      i := pos(#13, cmdline);
      if (i <> 0) then
        delete(cmdline, i, 1);

      i := pos(#10, cmdline);
      if (i <> 0) then
        delete(cmdline, i, 1);

      conn.comm_buf := '';
      conn.fcommand := true;

      if (conn.pagepoint <> 0) then
        conn.setPagerInput(cmdline)
      else
        case conn.state of
          CON_PLAYING: begin
                       if (not conn.ch.IS_NPC) and (IS_SET(conn.ch.player^.flags,PLR_FROZEN)) and (cmdline <> 'quit') then
                         begin
                         conn.ch.sendBuffer('You have been frozen by the gods and cannot do anything.'#13#10);
                         conn.ch.sendBuffer('To be unfrozen, send an e-mail to the administration, '+system_info.admin_email+'.'#13#10);
                         continue;
                         end;

                       conn.ch.in_command:=true;
                       interpret(conn.ch, cmdline);

                       if (not conn.ch.CHAR_DIED) then
                         conn.ch.in_command := false;
                       end;
          CON_EDITING: conn.ch.editBuffer(cmdline);
          else
            nanny(conn, cmdline);
        end;
      end;
  until Terminated;

  if (not conn.ch.CHAR_DIED) and ((conn.state=CON_PLAYING) or (conn.state=CON_EDITING)) then
    begin
    write_console('(' + inttostr(conn.socket) + ') '+conn.ch.name^+' has lost the link');

    interpret(conn.ch, 'return');

    conn.ch.conn := nil;

    act(AT_REPORT,'$n has lost $s link.',false,conn.ch,nil,nil,TO_ROOM);
    SET_BIT(conn.ch.player^.flags,PLR_LINKLESS);
    end
  else
  if (conn.state = CON_LOGGED_OUT) then
    dec(system_info.user_cur)
  else
    begin
    write_console('('+inttostr(conn.socket)+') Connection reset by peer');
    conn.ch.Free;
    end;

  closesocket(socket);

  conn.Free;
end;

// command stuff
procedure registerCommand(name : string; func : COMMAND_FUNC);
var
   g : GCommandFunc;
   node : GListNode;
begin
  node := func_list.head;

  while (node <> nil) do
    begin
    g := node.element;

    if (g.name = name) or (pointer(@g.func) = pointer(@func)) then
      begin
      bugreport('registerCommand', 'mudthread.pas', 'Command ' + name + ' registered twice.', 'Command ' + name + ' registered twice.');
      exit;
      end;

    node := node.next;
    end;

  g := GCommandFunc.Create;

  g.name := name;
  g.func := func;

  func_list.insertLast(g);
end;

procedure registerCommands;
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
  registerCommand('do_chat', do_chat);
  registerCommand('do_raid', do_raid);
  registerCommand('do_immtalk', do_immtalk);
  registerCommand('do_say', do_say);
  registerCommand('do_tell', do_tell);
  registerCommand('do_reply', do_reply);
  registerCommand('do_yell', do_yell);
  registerCommand('do_suggest', do_suggest);
  registerCommand('do_pray', do_pray);
  registerCommand('do_emote', do_emote);
  registerCommand('do_auctalk', do_auctalk);
  registerCommand('do_babbel', do_babbel);
  registerCommand('do_shutdown', do_shutdown);
  registerCommand('do_echo', do_echo);
  registerCommand('do_thunder', do_thunder);
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
  registerCommand('do_clantalk', do_clantalk);
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
end;

begin
  func_list := GDLinkedList.Create;
end.

