{
  @abstract(Game thread and command interpreter)
  @lastmod($Id: commands.pas,v 1.4 2003/10/18 11:09:33 ***REMOVED*** Exp $)
}

unit commands;

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
		allowed_states : set of STATE_IDLE .. STATE_SLEEPING;      { allowed states }
		addArg0 : boolean;           { send arg[0] (the command itself) to func? }
	end;

var
   funcList, commandList : GHashTable;

procedure interpret(ch : GCharacter; line : string);

procedure registerCommand(name : string; func : COMMAND_FUNC);
procedure unregisterCommand(name : string);

procedure initCommands();
procedure loadCommands();
procedure cleanupCommands();

implementation

uses
    magic,
    md5,
    update,
    timers,
    fight,
    player,
    NameGen,
    Channels;


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
  f := GCommandFunc(funcList.get(s));
  
  if (f = nil) then
    begin
    writeConsole('Could not find function for command "' + s + '"');
    Result := @do_dummy;
    end
  else   
  	Result := f.func;
end;

procedure loadCommands();
var 
  af : GFileReader;
  s,g:string;
  cmd : GCommand;
  alias : GCommand;
begin
  try
    af := GFileReader.Create(SystemDir + 'commands.dat');
  except
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
    cmd.allowed_states := [STATE_MEDITATING, STATE_IDLE, STATE_RESTING, STATE_FIGHTING];

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
        begin
        //position:=strtoint(right(s,' '));
        end
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
      commandList.put(cmd.name, cmd);

      if (alias <> nil) then
        begin
        // update settings
        alias.level := cmd.level;
        alias.ptr := cmd.ptr;
        alias.func_name := cmd.func_name;
        alias.allowed_states := cmd.allowed_states;
        alias.addarg0 := cmd.addarg0;

        commandList.put(alias.name, alias);
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
    cmdline, param, ale : string;
    hash, time : cardinal;
    al : GAlias;
    timer : GTimer;
begin
  if (not ch.IS_NPC) and (GPlayer(ch).switching <> nil) then
    begin
    interpret(GPlayer(ch).switching, line);
    exit;
    end;

	{ Check if keyboard is locked - Nemesis }
	if (not ch.IS_NPC) then
		begin
		if (GPlayer(ch).conn <> nil) and (ch.IS_KEYLOCKED) then
			begin
			if (length(line) = 0) then
				begin
				ch.sendBuffer('Enter your password to unlock keyboard.'#13#10);
				exit;
				end;

			if (not MD5Match(GPlayer(ch).md5_password, MD5String(line))) then
				begin
				ch.sendBuffer('Wrong password!'#13#10);
				exit;
				end
			else
				begin
				GPlayer(ch).afk := false;
				GPlayer(ch).keylock := false;

				act(AT_REPORT,'You are now back at your keyboard.',false,ch,nil,nil,to_char);
				act(AT_REPORT,'$n has returned to $s keyboard.',false,ch,nil,nil,to_room);
				exit;
				end;
			end;

		{ AFK revised with keylock - Nemesis }
		if (GPlayer(ch).conn <> nil) and (ch.IS_AFK) and (not ch.IS_KEYLOCKED) then
			begin
			GPlayer(ch).afk := false;

			act(AT_REPORT,'You are now back at your keyboard.',false,ch,nil,nil,to_char);
			act(AT_REPORT,'$n has returned to $s keyboard.',false,ch,nil,nil,to_room);
			end;
		end;

	timer := hasTimer(ch, TIMER_ACTION);
	if (timer <> nil) then
		begin
		act(AT_REPORT, 'You stop your ' + timer.name + '.', false, ch, nil, nil, TO_CHAR);
		unregisterTimer(ch, TIMER_ACTION);
		end;

	if (length(line) = 0) then
		begin
		ch.sendBuffer(' ');
		exit;
		end;

	if (ch.snooped_by <> nil) then
		GPlayer(ch.snooped_by).conn.send(line + #13#10);

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
				ale := stringreplace(al.expand, '%', param, [rfReplaceAll]);

				while (pos(':', ale) > 0) do
					begin
					line := left(ale, ':');
					ale := right(ale, ':');

					interpret(ch, line);
					end;

				line := ale + ' ' + param;
				param := one_argument(line, cmdline);
				cmdline := uppercase(cmdline);

				break;
				end;

			node := node.next;
			end;
		end;

	cmd := nil;

	hash := commandList.getHash(cmdline);
	node := commandList.bucketList[hash].head;

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
		a := ch.getTrust();
		
		if (a >= cmd.level) then
			begin
			if (not (ch.state in cmd.allowed_states)) then
				case ch.state of
						STATE_SLEEPING: ch.sendBuffer('You are off to dreamland.'#13#10);
					STATE_MEDITATING: ch.sendBuffer('You must break out of your trance first.'#13#10);
						 STATE_RESTING: ch.sendBuffer('You feel too relaxed to do this.'#13#10);
						STATE_FIGHTING: ch.sendBuffer('You are fighting!'#13#10);
					else
						writeConsole('Illegal state ' + IntToStr(ch.state) + '!');
				end
			else
				begin
				try
					if (system_info.log_all) or (ch.logging) then
						writeConsole(ch.name + ': ' + line);
					if (cmd.level >= LEVEL_IMMORTAL) and (not IS_SET(GPlayer(ch).flags, PLR_CLOAK)) then
						writeConsole(ch.name + ': ' + cmd.name + ' (' + inttostr(cmd.level) + ')');

//            time := GetTickCount;

					if (cmd.addarg0) then
						cmd.ptr(ch, cmdline + ' ' + param)
					else
						cmd.ptr(ch, param);

					ch.last_cmd := @cmd.ptr;

				except
{            on E : EExternal do
						begin
						bugreport('interpret', 'mudthread.pas', ch.name + ':' + cmd.func_name + ' - External exception');
						outputError(E);
						end;

					on E : Exception do
						bugreport('interpret', 'mudthread.pas', ch.name + ':' + cmd.func_name + ' - ' + E.Message);

					else
						bugreport('interpret', 'mudthread.pas', ch.name + ':' + cmd.func_name + ' - Unknown exception'); }
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

(* procedure GGameThread.Execute;
var 
  cmdline : string;
  temp_buf : string;
  ch : GPlayer;
  i : integer;

label nameinput,stopthread;
begin

  ch := GPlayer.Create;
  conn.ch := ch;
  ch.conn := conn;

  if (not copyover) then
    begin
    conn.state := CON_NAME;

    conn.send(AnsiColor(2,0) + findHelp('M_DESCRIPTION_').text);

    temp_buf := AnsiColor(6,0) + #13#10;

    temp_buf := temp_buf + version_info + ', ' + version_number + '.'#13#10;
    temp_buf := temp_buf + version_copyright + '.';
    temp_buf := temp_buf + AnsiColor(7,0) + #13#10;

    conn.send(temp_buf);

    conn.send(#13#10#13#10'Enter your name or CREATE to create a new character.'#13#10'Please enter your name: ');
    end
  else
    begin
    conn.state := CON_MOTD;

    conn.ch.setName(copyover_name);
    conn.ch.load(copyover_name);
    conn.send(#13#10#13#10'Gradually, the clouds form real images again, recreating the world...'#13#10);
    conn.send('Copyover complete!'#13#10);

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
{      on E : EExternal do
        begin
        bugreport('GGameThread.Execute()', 'mudthread.pas', conn.ch.name + ' - External exception');
        outputError(E);
        end;
        
      on E : Exception do
        bugreport('GGameThread.Execute()', 'mudthread.pas', conn.ch.name + ' - ' + E.Message);
        
      else
        bugreport('GGameThread.Execute()', 'mudthread.pas', conn.ch.name + ' - Unknown exception'); }
    end;
  until Terminated;

  try
    if (not conn.ch.CHAR_DIED) and ((conn.state=CON_PLAYING) or (conn.state=CON_EDITING)) then
      begin
      writeConsole('(' + inttostr(conn.socket.getDescriptor) + ') '+conn.ch.name+' has lost the link');

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
      writeConsole('('+inttostr(conn.socket.getDescriptor)+') Connection reset by peer');
      conn.ch.Free;
      end;

    conn.Free();
  except
{    on E : EExternal do
      begin
      bugreport('GGameThread.Execute()', 'mudthread.pas', 'Error while shutting down thread');
      outputError(E);
      end;
    
    on E : Exception do
      bugreport('GGameThread.Execute()', 'mudthread.pas', 'Error while shutting down thread: ' + E.Message);
      
    else
      bugreport('GGameThread.Execute()', 'mudthread.pas', 'Unknown error while shutting down thread'); }
  end;
end; *)

// command stuff
procedure registerCommand(name : string; func : COMMAND_FUNC);
var
   g : GCommandFunc;
   c : GCommand;
   iterator : GIterator;
begin
  g := GCommandFunc(funcList.get(name));
  
  if (g <> nil) then
    begin
    bugreport('registerCommand', 'mudthread.pas', 'Command ' + name + ' registered twice.');
    exit;
    end;

  g := GCommandFunc.Create;

  g.name := name;
  g.func := func;

  funcList.put(name, g);
  
  iterator := commandList.iterator();
  
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
  g := GCommandFunc(funcList.get(name));
  
  if (g = nil) then
    begin
    bugreport('unregisterCommand', 'mudthread.pas', 'Command ' + name + ' not registered');
    exit;
    end
  else
    begin
    iterator := commandList.iterator();
    
    while (iterator.hasNext()) do
      begin
      c := GCommand(iterator.next());
      
      if (@c.ptr = @g.func) then
        begin
//        writeConsole('Resetting command with my name: ' + c.name);
        c.ptr := do_dummy;
        end;
      end;
    
    funcList.remove(name);
    
    g.Free();
    end;
    
  iterator.Free();
end;

procedure initCommands();
begin
  funcList := GHashTable.Create(128);
  commandList := GHashTable.Create(128);
  commandList.setHashFunc(firstHash);
end;

procedure cleanupCommands();
begin
  funcList.clear();
  funcList.Free();

  commandList.Free();
end;

end.
