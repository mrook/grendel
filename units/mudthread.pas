// $Id: mudthread.pas,v 1.68 2001/09/02 21:53:02 ***REMOVED*** Exp $

unit mudthread;

interface

uses
    Classes,
{$IFDEF WIN32}
    Windows,
    Winsock2,
{$ENDIF}
{$IFDEF LINUX}
    Libc,
{$ENDIF}
    SysUtils,
    Math,
    ansiio,
    constants,
    console,
    conns,
    chars,
    race,
    clan,
    area,
    dtypes,
    skills,
    strip,
    util,
    bulletinboard,
    mudhelp,
    socket,
    mudsystem,
    fsys,
    gvm;

type
    GGameThread = class(TThread)
    private
      conn : GConnection;
      copyover : boolean;
      copyover_name : string;

    protected
      procedure Execute; override;

    public
      last_update : TDateTime;
      
      constructor Create(s : GSocket; copy : boolean; name : string);
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
      addArg0 : boolean;           { send arg[0] (the command itself) to func? }
    end;

var
   func_list, commands : GHashTable;

procedure load_commands;
procedure interpret(ch : GCharacter; line : string);

procedure registerCommand(name : string; func : COMMAND_FUNC);
procedure unregisterCommand(name : string);

procedure initCommands();
procedure cleanupCommands();

implementation

uses
    magic,
    md5,
    update,
    timers,
    debug,
    fight,
    NameGen,
    Channels;

constructor GGameThread.Create(s : GSocket; copy : boolean; name : string);
begin
  conn := GConnection.Create(s, Self);

  copyover := copy;
  copyover_name := name;
  last_update := Now();

  inherited Create(False);
end;

procedure do_dummy(ch : GCharacter; param : string);
begin
  ch.sendBuffer('This is a DUMMY command, and doesn''t perform any action.'#13#10);
  ch.sendBuffer('Either this command has not been implemented yet,'#13#10);
  ch.sendBuffer('or the server is reconfiguring itself with new code.'#13#10);
  ch.sendBuffer('Please contact the administration if this persists for more than an hour.'#13#10);
end;

function findCommand(s : string) : COMMAND_FUNC;
var
   f : GCommandFunc;
begin
  f := GCommandFunc(func_list.get(s));
  
  if (f = nil) then
    begin
    writeConsole('Could not find function for command "' + s + '"');
    f := @do_dummy;
    end;
    
  Result := f.func;
end;

procedure load_commands;
var 
  af : GFileReader;
  s,g:string;
  cmd : GCommand;
  alias : GCommand;
begin
  try
    af := GFileReader.Create(SystemDir + 'commands.dat');
  except
    bugreport('load_commands', 'mudthread.pas', 'could not open system\commands.dat');
    exit;
  end;

  repeat
    repeat
      s := af.readLine();
    until (uppercase(s) = '#COMMAND') or (af.eof());

    if (af.eof()) then
      break;

    alias := nil;
    cmd := GCommand.Create;
    cmd.position := POS_MEDITATE;

    with cmd do
      repeat
      s := af.readLine();
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
        end
      else
      if g='ADDARG0' then
        begin
          addarg0 := (trim(uppercase(right(s,' '))) = 'TRUE');
        end;
      until (uppercase(s)='#END') or (af.eof());

    if (assigned(cmd.ptr)) then
      begin
      commands.put(cmd.name, cmd);

      if (alias <> nil) then
        begin
        // update settings
        alias.level := cmd.level;
        alias.ptr := cmd.ptr;
        alias.func_name := cmd.func_name;
        alias.position := cmd.position;
        alias.addarg0 := cmd.addarg0;

        commands.put(alias.name, alias);
        end;
      end
    else
      begin
      cmd.Free;

      if (alias <> nil) then
        alias.Free;
      end;
  until (af.eof());

  af.Free();
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
    a : longint;
    gc : GCommand;
    cmd : GCommand;
    node : GListNode;
    cmdline, param : string;
    hash, time : cardinal;
    al : GAlias;
begin
  with ch do
    begin
    { Check if keyboard is locked - Nemesis }
    if (conn <> nil) and (not IS_NPC) and (IS_KEYLOCKED) then
      begin
      if (length(line) = 0) then
        begin
        sendBuffer('Enter your password to unlock keyboard.'#13#10);
        exit;
        end;

      if (not MD5Match(GPlayer(ch).md5_password, MD5String(line))) then
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
      node := GPlayer(ch).aliases.head;

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
      gc := GCommand(GHashValue(node.element).value);
      if (cmdline = gc.name) or
         ((pos(cmdline, gc.name) = 1) and (length(cmdline) <= length(gc.name)) and (length(cmdline) > 1)) or
         ((copy(cmdline, 1, length(gc.name)) = gc.name) and (length(cmdline) = 1))
         then
        begin
        cmd := gc;
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
          if (system_info.log_all) or (ch.logging) then
            writeLog(ch.name^ + ': ' + line);

          if (cmd.level >= LEVEL_IMMORTAL) and (not IS_SET(GPlayer(ch).flags, PLR_CLOAK)) then
            writeConsole('[LOG] ' + ch.name^ + ': ' + cmd.name + ' (' + inttostr(cmd.level) + ')');

          try
//            time := GetTickCount;

            if cmd.addarg0 then
              cmd.ptr(ch, cmdline + ' ' + param)
            else
              cmd.ptr(ch, param);

            ch.last_cmd := @cmd.ptr;

            { Disabled this, this is too computer specific, e.g. on a 486
              some commands could lag while on a Pentium they would not.
              Uncomment if CPU leaks are to be traced. - Grimlord }

{            time := GetTickCount - time;

            if (time > 1500) and (not ch.CHAR_DIED) then
              bugreport('interpret','mudthread.pas', cmd.func_name + ', ch ' + ch.name^ + ' lagged', 'The command took over 1.5 sec to complete.'); }
          except
            on E : EExternal do
              begin
              bugreport('interpret', 'mudthread.pas', ch.name^ + ':' + cmd.func_name + ' - External exception');
              outputError(E);
              end;
              
            on E : Exception do
              bugreport('interpret', 'mudthread.pas', ch.name^ + ':' + cmd.func_name + ' - ' + E.Message);
              
            else
              bugreport('interpret', 'mudthread.pas', ch.name^ + ':' + cmd.func_name + ' - Unknown exception');
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
var ch, vict : GPlayer;
    tmp : GCharacter;
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
                    conn.sock.send('Please enter your name: ');
                    exit;
                    end;

                  if (uppercase(argument) = 'CREATE') then
                    begin
                    conn.sock.send(#13#10'By what name do you wish to be known? ');
                    conn.state := CON_NEW_NAME;
                    exit;
                    end;

                  vict := findPlayerWorld(nil, argument);

                  if (vict <> nil) and (not vict.IS_NPC) and (vict.conn <> nil) and (cap(vict.name^) = cap(argument)) then
                    begin
                    if (not MD5Match(MD5String(pwd), GPlayer(vict).md5_password)) then
                      begin
                      conn.sock.send(#13#10'You are already logged in under that name! Type your name and password on one line to break in.'#13#10);
                      conn.thread.Terminate;
                      end
                    else
                      begin
                      GConnection(vict.conn).thread.Terminate;

                      while (not IS_SET(vict.flags, PLR_LINKLESS)) do;

                      vict.conn := conn;
                      conn.ch := vict;
                      ch := vict;
                      REMOVE_BIT(conn.ch.flags,PLR_LINKLESS);
                      conn.state := CON_PLAYING;
                      conn.ch.sendPrompt;
                      end;

                    exit;
                    end;

                  if (not ch.load(argument)) then
                    begin
                    conn.sock.send(#13#10'Are you sure about that name?'#13#10'Name: ');
                    exit;
                    end;

                  conn.state:=CON_PASSWORD;
                  conn.sock.send('Password: ');
                  end;
    CON_PASSWORD: begin
                  if (length(argument) = 0) then
                    begin
                    conn.sock.send('Password: ');
                    exit;
                    end;

                  if (not MD5Match(MD5String(argument), ch.md5_password)) then
                    begin
                    writeConsole('(' + inttostr(conn.sock.getDescriptor) + ') Failed password');
                    conn.sock.send('Wrong password.'#13#10);
                    conn.sock.send('Password: ');
                    exit;
                    end;

                  vict := findPlayerWorld(nil, ch.name^);

                  if (vict <> nil) and (vict.conn = nil) then
                    begin
                    ch.Free;

                    conn.ch := vict;
                    ch := vict;
                    vict.conn := conn;

                    ch.ld_timer := 0;

                    conn.sock.send('You have reconnected.'#13#10);
                    act(AT_REPORT, '$n has reconnected.', false, ch, nil, nil, TO_ROOM);
                    REMOVE_BIT(ch.flags, PLR_LINKLESS);
                    writeConsole('(' + inttostr(conn.sock.getDescriptor) + ') ' + ch.name^ + ' has reconnected');

                    ch.sendPrompt;
                    conn.state := CON_PLAYING;
                    exit;
                    end;

                  if (ch.IS_IMMORT) then
                    conn.sock.send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                  else
                    conn.sock.send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                  conn.sock.send('Press Enter.'#13#10);
                  conn.state := CON_MOTD;
                  end;
        CON_MOTD: begin
                  conn.sock.send(ch.ansiColor(6) + #13#10#13#10'Welcome, ' + ch.name^ + ', to this MUD. May your stay be pleasant.'#13#10);

                  with system_info do
                    begin
                    user_cur := connection_list.getSize;
                    if (user_cur > user_high) then
                      user_high := user_cur;
                    end;

                  ch.toRoom(ch.room);

                  act(AT_WHITE, '$n enters through a magic portal.', true, ch, nil, nil, TO_ROOM);
                  writeConsole('(' + inttostr(conn.sock.getDescriptor) + ') '+ ch.name^ +' has logged in');

                  ch.node_world := char_list.insertLast(ch);
                  ch.logon_now := Now;

                  if (ch.level = LEVEL_RULER) then
                    interpret(ch, 'uptime')
                  else
                    ch.sendPrompt;

                  conn.state := CON_PLAYING;
                  conn.fcommand := true;
                  end;
    CON_NEW_NAME: begin
                  if (length(argument) = 0) then
                    begin
                    conn.sock.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  if (FileExists('players\' + argument + '.usr')) then
                    begin
                    conn.sock.send('That name is already used.'#13#10);
                    conn.sock.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  tmp := findCharWorld(nil, argument);
                  if (* ((banned_names.indexof(uppercase(argument)) <> -1) or *) (tmp <> nil) and (uppercase(tmp.name^) = uppercase(argument)) then
                    begin
                    conn.send('That name cannot be used.'#13#10);
                    conn.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  if (length(argument) < 3) or (length(argument) > 15) then
                    begin
                    conn.sock.send('Your name must be between 3 and 15 characters long.'#13#10);
                    conn.sock.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  ch.name := hash_string(cap(argument));
                  conn.state := CON_NEW_PASSWORD;
                  conn.sock.send(#13#10'Allright, '+ch.name^+', choose a password: ');
                  end;
CON_NEW_PASSWORD: begin
                  if (length(argument)=0) then
                    begin
                    conn.sock.send('Choose a password: ');
                    exit;
                    end;

                  ch.md5_password := MD5String(argument);
                  conn.state := CON_CHECK_PASSWORD;
                  conn.sock.send(#13#10'Please retype your password: ');
                  end;
CON_CHECK_PASSWORD: begin
                    if (length(argument) = 0) then
                      begin
                      conn.sock.send('Please retype your password: ');
                      exit;
                      end;

                    if (not MD5Match(MD5String(argument), ch.md5_password)) then
                      begin
                      conn.sock.send(#13#10'Password did not match!'#13#10'Choose a password: ');
                      conn.state := CON_NEW_PASSWORD;
                      exit;
                      end
                    else
                      begin
                      conn.state := CON_NEW_SEX;
                      conn.sock.send(#13#10'What sex do you wish to be (M/F/N): ');
                      exit;
                      end;
                    end;
     CON_NEW_SEX: begin
                  if (length(argument) = 0) then
                    begin
                    conn.sock.send('Choose a sex (M/F/N): ');
                    exit;
                    end;

                  case upcase(argument[1]) of
                    'M':ch.sex:=0;
                    'F':ch.sex:=1;
                    'N':ch.sex:=2;
                  else
                    begin
                    conn.sock.send('That is not a valid sex.'#13#10);
                    conn.sock.send('Choose a sex (M/F/N): ');
                    exit;
                    end;
                  end;

                  conn.state:=CON_NEW_RACE;
                  conn.sock.send(#13#10'Available races: '#13#10#13#10);

                  h:=1;
                  node := race_list.head;
                  while (node <> nil) do
                    begin
                    race := node.element;

                    buf := '  ['+inttostr(h)+']  '+pad_string(race.name,15);

                    if (race.def_alignment < 0) then
                      buf := buf + ANSIColor(12,0) + '<- EVIL'+ANSIColor(7,0);

                    buf := buf + #13#10;

                    conn.sock.send(buf);

                    inc(h);
                    node := node.next;
                    end;

                  conn.sock.send(#13#10'Choose a race: ');
                  end;
    CON_NEW_RACE: begin
                  if (length(argument)=0) then
                    begin
                    conn.sock.send(#13#10'Choose a race: ');
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
                    conn.sock.send('Not a valid race.'#13#10);

                    h:=1;
                    node := race_list.head;
                    while (node <> nil) do
                      begin
                      race := node.element;

                      buf := '  ['+inttostr(h)+']  '+pad_string(race.name,15);

                      if (race.def_alignment < 0) then
                        buf := buf + ANSIColor(12,0) + '<- EVIL'+ANSIColor(7,0);

                      buf := buf + #13#10;

                      conn.sock.send(buf);

                      inc(h);
                      node := node.next;
                      end;

                    conn.sock.send(#13#10'Choose a race: ');
                    exit;
                    end;

                  ch.race:=race;
                  conn.sock.send(race.description);
                  conn.sock.send('250 stat points will be randomly distributed over your five attributes.'#13#10);
                  conn.sock.send('It is impossible to get a lower or a higher total of stat points.'#13#10);

                  with ch do
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
                            str := str + temp;
                            end;
                          end;
                        1:begin
                          temp:=UMax(75-con,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            con := con + temp;
                            end;
                          end;
                        2:begin
                          temp:=UMax(75-dex,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            dex := dex + temp;
                            end;
                          end;
                        3:begin
                          temp:=UMax(75-int,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            int := int + temp;
                            end;
                          end;
                        4:begin
                          temp:=UMax(75-wis,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            wis := wis + temp;
                            end;
                          end;
                      end;
                      end;

                    top:=str+con+dex+int+wis;
                    end;

                  conn.sock.send(#13#10'Your character statistics are: '#13#10#13#10);

                  buf := 'Strength:     '+ANSIColor(10,0)+inttostr(ch.str)+ANSIColor(7,0)+#13#10 +
                         'Constitution: '+ANSIColor(10,0)+inttostr(ch.con)+ANSIColor(7,0)+#13#10 +
                         'Dexterity:    '+ANSIColor(10,0)+inttostr(ch.dex)+ANSIColor(7,0)+#13#10 +
                         'Intelligence: '+ANSIColor(10,0)+inttostr(ch.int)+ANSIColor(7,0)+#13#10 +
                         'Wisdom:       '+ANSIColor(10,0)+inttostr(ch.wis)+ANSIColor(7,0)+#13#10;
                  conn.sock.send(buf);

                  conn.sock.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                  conn.state:=CON_NEW_STATS;
                  end;
   CON_NEW_STATS: begin
                  if (length(argument) =0) then
                    begin
                    conn.sock.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                    exit;
                    end;

                  case (upcase(argument[1])) of
                    'C':begin
                        digest := ch.md5_password;

                        ch.load(ch.name^);
                        ch.md5_password := digest;
                        ch.save(ch.name^);

                        conn.sock.send(#13#10'Thank you. You have completed your entry.'#13#10);

                        conn.sock.send(ch.ansiColor(2) + #13#10);

                        if (ch.IS_IMMORT) then
                          conn.sock.send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                        else
                          conn.sock.send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                        conn.sock.send('Press Enter.'#13#10);
                        conn.state:=CON_MOTD;
                        end;
                    'R':begin
                        with ch do
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
                                  str := str + temp;
                                  end;
                                end;
                              1:begin
                                temp:=UMax(75-con,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  con := con + temp;
                                  end;
                                end;
                              2:begin
                                temp:=UMax(75-dex,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  dex := dex + temp;
                                  end;
                                end;
                              3:begin
                                temp:=UMax(75-int,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  int := int + temp;
                                  end;
                                end;
                              4:begin
                                temp:=UMax(75-wis,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  wis := wis + temp;
                                  end;
                                end;
                            end;
                            end;

                          top:=str+con+dex+int+wis;
                          end;

                        conn.sock.send(#13#10'Your character statistics are: '#13#10#13#10);

                        buf := 'Strength:     '+ANSIColor(10,0)+inttostr(ch.str)+ANSIColor(7,0)+#13#10 +
                               'Constitution: '+ANSIColor(10,0)+inttostr(ch.con)+ANSIColor(7,0)+#13#10 +
                               'Dexterity:    '+ANSIColor(10,0)+inttostr(ch.dex)+ANSIColor(7,0)+#13#10 +
                               'Intelligence: '+ANSIColor(10,0)+inttostr(ch.int)+ANSIColor(7,0)+#13#10 +
                               'Wisdom:       '+ANSIColor(10,0)+inttostr(ch.wis)+ANSIColor(7,0)+#13#10;
                        conn.sock.send(buf);

                        conn.sock.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                        end;
                    'S':begin
                        conn.sock.send(#13#10'Very well, restarting.'#13#10);
                        conn.sock.send('By what name do you wish to be known?');
                        conn.state:=CON_NEW_NAME;
                        end;
                  else
                    conn.sock.send('Do you wish to (C)ontinue, (R)eroll or (S)art over? ');
                    exit;
                 end;
                 end;
    else
      bugreport('nanny', 'mudthread.pas', 'illegal state ' + inttostr(conn.state));
  end;
end;

procedure GGameThread.Execute;
var 
  cmdline : string;
  temp_buf : string;
  ch : GPlayer;
  i : integer;

label nameinput,stopthread;
begin
  freeonterminate := true;

  writeConsole('(' + inttostr(conn.sock.getDescriptor) + ') New connection (' + conn.sock.host_string + ')');

  if (isMaskBanned(conn.sock.host_string)) then
    begin
    writeConsole('('+inttostr(conn.sock.getDescriptor)+') Closed banned IP (' + conn.sock.host_string + ')');

    conn.sock.send(system_info.mud_name+#13#10#13#10);
    conn.sock.send('Your site has been banned from this server.'#13#10);
    conn.sock.send('For more information, please mail the administration, '+system_info.admin_email+'.'#13#10);
    
    conn.Free();
    exit;
    end;

  ch := GPlayer.Create;
  conn.ch := ch;
  ch.conn := conn;

  if (not copyover) then
    begin
    conn.state := CON_NAME;

    conn.sock.send(AnsiColor(2,0) + findHelp('M_DESCRIPTION_').text);

    temp_buf := AnsiColor(6,0) + #13#10;

    temp_buf := temp_buf + version_info + ', ' + version_number + '.'#13#10;
    temp_buf := temp_buf + version_copyright + '.';
    temp_buf := temp_buf + #13#10'This is free software, with ABSOLUTELY NO WARRANTY; view LICENSE.TXT.';
    temp_buf := temp_buf + AnsiColor(7,0) + #13#10;

    conn.sock.send(temp_buf);

    conn.sock.send(#13#10#13#10'Enter your name or CREATE to create a new character.'#13#10'Please enter your name: ');
    end
  else
    begin
    conn.state := CON_MOTD;

    conn.ch.name := hash_string(copyover_name);
    conn.ch.load(copyover_name);
    conn.sock.send(#13#10#13#10'Gradually, the clouds form real images again, recreating the world...'#13#10);
    conn.sock.send('Copyover complete!'#13#10);

    nanny(conn, '');
    end;

  repeat
    try
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
                         if (not conn.ch.IS_NPC) and (IS_SET(conn.ch.flags,PLR_FROZEN)) and (cmdline <> 'quit') then
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
            CON_EDIT_HANDLE: conn.ch.editBuffer(cmdline);
            CON_EDITING: conn.ch.editBuffer(cmdline);
            else
              nanny(conn, cmdline);
          end;
        end;
    except
      on E : EExternal do
        begin
        bugreport('GGameThread.Execute()', 'mudthread.pas', conn.ch.name^ + ' - External exception');
        outputError(E);
        end;
        
      on E : Exception do
        bugreport('GGameThread.Execute()', 'mudthread.pas', conn.ch.name^ + ' - ' + E.Message);
        
      else
        bugreport('GGameThread.Execute()', 'mudthread.pas', conn.ch.name^ + ' - Unknown exception');
    end;
  until Terminated;

  try
    if (not conn.ch.CHAR_DIED) and ((conn.state=CON_PLAYING) or (conn.state=CON_EDITING)) then
      begin
      writeConsole('(' + inttostr(conn.sock.getDescriptor) + ') '+conn.ch.name^+' has lost the link');

      if (conn.ch.level >= LEVEL_IMMORTAL) then
        interpret(conn.ch, 'return');

      conn.ch.conn := nil;

      act(AT_REPORT,'$n has lost $s link.',false,conn.ch,nil,nil,TO_ROOM);
      SET_BIT(conn.ch.flags,PLR_LINKLESS);
      end
    else
    if (conn.state = CON_LOGGED_OUT) then
      dec(system_info.user_cur)
    else
      begin
      writeConsole('('+inttostr(conn.sock.getDescriptor)+') Connection reset by peer');
      conn.ch.Free;
      end;

    conn.Free();
  except
    on E : EExternal do
      begin
      bugreport('GGameThread.Execute()', 'mudthread.pas', 'Error while shutting down thread');
      outputError(E);
      end;
    
    on E : Exception do
      bugreport('GGameThread.Execute()', 'mudthread.pas', 'Error while shutting down thread: ' + E.Message);
      
    else
      bugreport('GGameThread.Execute()', 'mudthread.pas', 'Unknown error while shutting down thread');
  end;
end;

// command stuff
procedure registerCommand(name : string; func : COMMAND_FUNC);
var
   g : GCommandFunc;
   c : GCommand;
   iterator : GIterator;
begin
  g := GCommandFunc(func_list.get(name));
  
  if (g <> nil) then
    begin
    bugreport('registerCommand', 'mudthread.pas', 'Command ' + name + ' registered twice.');
    exit;
    end;

  g := GCommandFunc.Create;

  g.name := name;
  g.func := func;

  func_list.put(name, g);
  
  iterator := commands.iterator();
  
  while (iterator.hasNext()) do
    begin
    c := GCommand(iterator.next());
    
    if (c.func_name = name) then
      begin
//      writeConsole('Found empty command with my name: ' + c.name);
      c.ptr := func;
      end;
    end;  
   
  iterator.Free();
end;

procedure unregisterCommand(name : string);
var
  g : GCommandFunc;
  c : GCommand;
  iterator : GIterator;
begin
  g := GCommandFunc(func_list.get(name));
  
  if (g = nil) then
    begin
    bugreport('unregisterCommand', 'mudthread.pas', 'Command ' + name + ' not registered');
    exit;
    end
  else
    begin
    iterator := commands.iterator();
    
    while (iterator.hasNext()) do
      begin
      c := GCommand(iterator.next());
      
      if (@c.ptr = @g.func) then
        begin
//        writeConsole('Resetting command with my name: ' + c.name);
        c.ptr := do_dummy;
        end;
      end;
    
    func_list.remove(name);
    
    g.Free();
    end;
    
  iterator.Free();
end;

procedure initCommands();
begin
  func_list := GHashTable.Create(128);
  commands := GHashTable.Create(128);
  commands.setHashFunc(firstHash);
end;

procedure cleanupCommands();
begin
  func_list.clear();
  func_list.Free();

  commands.Free();
end;

end.
