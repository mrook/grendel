{
  Summary:
    Command interpreter and supporting code
  
  ##  $Id: commands.pas,v 1.11 2004/03/04 19:35:00 ***REMOVED*** Exp $
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
  private
		_name : string;
		_func : COMMAND_FUNC;
		
	public
		property name : string read _name write _name;
		property func : COMMAND_FUNC read _func write _func;
  end;

  GCommand = class
  private
    _name : string;
    _level : integer;             { minimum level }
  
  public
    func_name : string;
    ptr : COMMAND_FUNC;
    allowed_states : set of STATE_IDLE .. STATE_SLEEPING;      { allowed states }
    addArg0 : boolean;           { send arg[0] (the command itself) to func? }

    property name : string read _name write _name;
    property level : integer read _level write _level;
  end;

var
   funcList, commandList : GHashTable;

procedure interpret(ch : GCharacter; line : string);

procedure registerCommand(const name : string; func : COMMAND_FUNC);
procedure unregisterCommand(const name : string);

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

function findCommand(const s : string) : COMMAND_FUNC;
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

// Load the commands
procedure loadCommands();
var 
  af : GFileReader;
  param, s, g : string;
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
    cmd := GCommand.Create();
    cmd.allowed_states := [];

    with cmd do
      repeat
      s := af.readLine();
      g := uppercase(left(s,':'));
      
      param := trim(right(s, ':'));

      if (g = 'NAME') then
        name := uppercase(param)
      else
      if (g = 'ALIAS') then
        begin
        // create an alias
        alias := GCommand.Create();
        alias.name := uppercase(param);
        end
      else
      if (g = 'LEVEL') then
        level := strtoint(param)
      else
      if (g = 'POSITION') then
      	begin
      	writeConsole('deprecated element position at line ' + IntToStr(af.line));
      	end
      else
      if (g = 'ALLOWED_STATES') then
        begin
        while (pos(',', param) > 0) do
        	begin
        	s := uppercase(left(param, ','));
        	
        	if (s = 'IDLE') then
        		cmd.allowed_states := cmd.allowed_states + [STATE_IDLE]
        	else
        	if (s = 'FIGHTING') then
        		cmd.allowed_states := cmd.allowed_states + [STATE_FIGHTING]
        	else
        	if (s = 'RESTING') then
        		cmd.allowed_states := cmd.allowed_states + [STATE_RESTING]
        	else
        	if (s = 'MEDITATING') then
        		cmd.allowed_states := cmd.allowed_states + [STATE_MEDITATING]
        	else
        	if (s = 'SLEEPING') then
        		cmd.allowed_states := cmd.allowed_states + [STATE_SLEEPING];
        	
        	param := right(param, ',');
        	end;
        
				s := uppercase(left(param, ','));

				if (s = 'IDLE') then
					cmd.allowed_states := cmd.allowed_states + [STATE_IDLE]
				else
				if (s = 'FIGHTING') then
					cmd.allowed_states := cmd.allowed_states + [STATE_FIGHTING]
				else
				if (s = 'RESTING') then
					cmd.allowed_states := cmd.allowed_states + [STATE_RESTING]
				else
				if (s = 'MEDITATING') then
					cmd.allowed_states := cmd.allowed_states + [STATE_MEDITATING]
				else
				if (s = 'SLEEPING') then
					cmd.allowed_states := cmd.allowed_states + [STATE_SLEEPING];
        end
      else
      if (g = 'FUNCTION') then
        begin
        func_name := right(s,' ');
        ptr := findCommand(func_name);
        end
      else
      if (g = 'ADDARG0') then
        begin
          addarg0 := (trim(uppercase(right(s,' '))) = 'TRUE');
        end;
      until (uppercase(s)='#END') or (af.eof());
      
		if (cmd.allowed_states = []) then
		 	cmd.allowed_states := [STATE_MEDITATING, STATE_IDLE, STATE_RESTING, STATE_FIGHTING];
		 	
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
      cmd.Free();

      if (alias <> nil) then
        alias.Free();
      end;
  until (af.eof());

  af.Free();
end;

// Strip '$' from commandline
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

// Interpret the command
procedure interpret(ch : GCharacter; line : string);
var
  a : longint;
  gc : GCommand;
  cmd : GCommand;
  node : GListNode;
  cmdline, param, ale : string;
  hash : cardinal;
  al : GAlias;
  iterator : GIterator;
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

  // Char is being snooped
  if (ch.snooped_by <> nil) then
    GPlayer(ch.snooped_by).conn.send(line + #13#10);

  clean_cmdline(line);

  param := one_argument(line, cmdline);
  cmdline := uppercase(cmdline);

  // check for aliases first
  if (not ch.IS_NPC) then
    begin
    iterator := GPlayer(ch).aliases.iterator();

    while (iterator.hasNext()) do
      begin
      al := GAlias(iterator.next());

      if (uppercase(al.alias) = cmdline) then
        begin
        ale := stringreplace(al.expand, '%', param, [rfReplaceAll]);

        while (pos(':', ale) > 0) do
          begin
          line := left(ale, ':');
          ale := right(ale, ':');

          interpret(ch, line);
          end;
        
        interpret(ch, ale);
        
        exit;
        end;
      end;
      
    iterator.Free();
    end;

  cmd := nil;

  hash := commandList.getHash(cmdline);
  node := commandList.buckets[hash].head;

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
      if not (ch.state in cmd.allowed_states) then
        case ch.state of
            STATE_SLEEPING: ch.sendBuffer('You are off to dreamland.'#13#10);
          STATE_MEDITATING: ch.sendBuffer('You must break out of your trance first.'#13#10);
             STATE_RESTING: ch.sendBuffer('You are resting.'#13#10);
            STATE_FIGHTING: ch.sendBuffer('You are fighting!'#13#10);
            		STATE_IDLE: ch.sendBuffer('You can not do that now.'#13#10);
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

          if (cmd.addarg0) then
            cmd.ptr(ch, cmdline + ' ' + param)
          else
            cmd.ptr(ch, param);

          ch.last_cmd := @cmd.ptr;
        except
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

// command stuff
procedure registerCommand(const name : string; func : COMMAND_FUNC);
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

  g := GCommandFunc.Create();

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

procedure unregisterCommand(const name : string);
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
