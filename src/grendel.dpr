{
  The Grendel Project - A Windows/Linux MUD Server
  Copyright (c) 2000-2004 by Michiel Rook (Grimlord)

  Contact information:
  Webpage:            http://www.grendelproject.nl/
  E-Mail:             michiel@grendelproject.nl

  Please observe the file "text\License.txt" before using this software.

  Redistribution and use in source and binary forms, with or without modification, 
  are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer. 

  * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation and/or 
    other materials provided with the distribution. 
  
  Neither the name of The Grendel Project nor the names of its contributors may be used 
  to endorse or promote products derived from this software without specific prior 
  written permission. 

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
  SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  $Id: grendel.dpr,v 1.13 2004/03/13 15:50:37 ***REMOVED*** Exp $
}

program grendel;

{$DESCRIPTION 'The Grendel Project - A Windows/Linux MUD Server. Copyright (c) 2000-2004 by Michiel Rook.'}

{$R grendel_icon.res}

{$DEFINE Grendel}

{$IFDEF CONSOLEBUILD}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils,
{$IFDEF WIN32}
  Windows,
  Winsock2,
	Forms,
  {$IFNDEF CONSOLEBUILD}
  systray,
  {$ENDIF}
{$ENDIF}
  Classes,
{$IFDEF LINUX}
  Libc,
{$ENDIF}
  constants,
  clan,
  debug,
  mudsystem,
  timers,
  update,
  fight,
  fsys,
  modules,
  commands,
  NameGen,
  mudhelp,
  conns,
  dtypes,
  socket,
  console,
  skills,
  clean,
  chars,
  player,
  Channels,
  Bulletinboard,
  progs,
  events,
  area,
  race;

const pipeName : pchar = '\\.\pipe\grendel';

var
  old_exitproc : pointer;
  listenSockets : GDLinkedList;

procedure openListenSockets();
var
	socket : GSocket;
begin
	listenSockets := GDLinkedList.Create();
	
  if (isSupported(AF_INET)) then
    begin
    socket := GSocket4.Create(); 
    socket.openPort(system_info.port);
    
    listenSockets.add(socket);
    end;

  if (isSupported(AF_INET6)) then
    begin
    socket := GSocket6.Create();
    socket.openPort(system_info.port6);

    listenSockets.add(socket);
    end;
end;

procedure flushConnections();
var
   conn : GPlayerConnection;
   iterator : GIterator;
begin
  iterator := connection_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    conn := GPlayerConnection(iterator.next());
    
    if (conn.isPlaying()) and (not conn.ch.IS_NPC) then
      GPlayer(conn.ch).quit
    else
      conn.Terminate();
    end;
    
  iterator.Free();
end;

// Server cleanup
procedure cleanupServer();
var
	node : GListNode;
begin
	writeConsole('Terminating threads...');
	
	mud_booted := false;

	timer_thread.Terminate();
	clean_thread.Terminate();

	Sleep(100);

	writeConsole('Saving mudstate...');

	saveMudState();
	
	writeConsole('Unloading modules...');

	unloadModules();

	writeConsole('Releasing allocated memory...');

	node := char_list.tail;
	while (node <> nil) do
		begin
		GCharacter(node.element).extract(true);
		node := char_list.tail;
		end;

	writeConsole('Cleaning channels...');
	cleanupChannels();

	writeConsole('Cleaning players...');
	cleanupPlayers();
		
	writeConsole('Cleaning chars...');
	cleanupChars();
	
	writeConsole('Cleaning clans...');
	cleanupClans();

	writeConsole('Cleaning commands...');
	cleanupCommands();

	writeConsole('Cleaning connections...');
	cleanupConns();

	writeConsole('Cleaning help...');
	cleanupHelp();

	writeConsole('Cleaning skills...');
	cleanupSkills();

	writeConsole('Cleaning areas...');
	cleanupAreas();

	writeConsole('Cleaning timers...');
	cleanupTimers();

	writeConsole('Cleaning races...');
	cleanupRaces();

	writeConsole('Cleaning system...');
	cleanupSystem();

	writeConsole('Cleaning notes...');
	cleanupNotes();

	writeConsole('Cleaning events...');
	cleanupEvents();

	listenSockets.clear();
	listenSockets.Free();

	writeConsole('Cleanup complete.');

	{$IFDEF WIN32}      
		{$IFNDEF CONSOLEBUILD}
		unregisterSysTray();
		cleanupSysTray();
		{$ENDIF}
	{$ENDIF}
end;

// Reboot procedure
procedure reboot_mud;
{$IFDEF WIN32}
var
  SI: TStartupInfo;
  PI: TProcessInformation;
{$ENDIF}
begin
  writeConsole('Server rebooting...');

  try
    if MUD_Booted then
      flushConnections();

    { wait for users to logout }
    Sleep(1000);
  except
    writeConsole('Exception caught while cleaning up connections');
  end;

  cleanupServer();

{$IFDEF WIN32}
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.wShowWindow := sw_show;

  if not CreateProcess('grendel.exe',Nil, Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI) then
    bugreport('reboot_mud', 'grendel.dpr', 'Could not execute grendel.exe, reboot failed!');
{$ENDIF}
{$IFDEF LINUX}
  if (execv('grendel', nil) = -1) then
    bugreport('reboot_mud', 'grendel.dpr', 'Could not execute grendel, reboot failed!');
{$ENDIF}
end;

// Copyover procedure
procedure copyover_mud;
{$IFDEF WIN32}
var
   SI: TStartupInfo;
   PI: TProcessInformation;
   pipe : THandle;
   node, node_next : GListNode;
   conn : GPlayerConnection;
   w, len : cardinal;
   prot : TWSAProtocol_Info;
   name : array[0..1023] of char;
begin
  writeConsole('Server starting copyover...');

  node := connection_list.head;

  while (node <> nil) do
    begin
    conn := GPlayerConnection(node.element);
    node_next := node.next;
    
    // disable MCCP compression 
    conn.disableCompression();

    if (conn.isPlaying()) then
      begin
      stopfighting(conn.ch);
  		conn.ch.emptyBuffer;
      conn.send(#13#10'Slowly, you feel the world as you know it fading away in wisps of steam...'#13#10#13#10);
      end
    else
      begin
      conn.send(#13#10'This server is rebooting, please continue in a few minutes.'#13#10#13#10);
      conn.Terminate();
      end;

    node := node_next;
    end;

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.wShowWindow := sw_show;

  if (not CreateProcess('copyover.exe', nil, Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI)) then
    begin
    bugreport('copyover_mud', 'grendel.dpr', 'Could not execute copyover.exe, copyover failed!');
    reboot_mud;
    end;

  pipe := CreateNamedPipe(pipeName, PIPE_ACCESS_DUPLEX, PIPE_WAIT or PIPE_TYPE_BYTE or PIPE_READMODE_BYTE, 10, 0, 0, 1000, nil);

  if (pipe = INVALID_HANDLE_VALUE) then
    begin
    writeConsole('Could not create pipe: ' + IntToStr(GetLastError()));
    exit;
    end;

  if (not ConnectNamedPipe(pipe, nil)) then
    begin
    bugreport('copyover_mud', 'grendel.dpr', 'Pipe did not initialize correctly!');
    reboot_mud;
    end;

  node := connection_list.head;

  while (node <> nil) do
    begin
    conn := GPlayerConnection(node.element);
    node_next := node.next;

    conn.ch.save(conn.ch.name);

    if (WSADuplicateSocket(conn.socket.getDescriptor, PI.dwProcessId, @prot) = -1) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'WSADuplicateSocket failed');
      reboot_mud;
      end;

    if (not WriteFile(pipe, prot, sizeof(prot), w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
      reboot_mud;
      end;

    strpcopy(name, conn.ch.name);
    len := strlen(name);

    if (not WriteFile(pipe, len, 4, w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
      reboot_mud;
      end;

    if (not WriteFile(pipe, name, len, w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
      reboot_mud;
      end;
      
    conn.Terminate();

    node := node_next;
    end;

  Sleep(500);

  CloseHandle(pipe);

  cleanupServer();
end;
{$ELSE}
begin
  writeConsole('Copyover not supported on this platform.');
end;
{$ENDIF}

// Shutdown procedure
procedure shutdown_mud;
begin
	writeConsole('Server shutting down...');

	if (mud_booted) then
		flushConnections();

	Sleep(1000);

  cleanupServer();
end;

procedure sendtoall(const s : string);
var
	iterator : GIterator;
	conn : GPlayerConnection;
begin
  iterator := connection_list.iterator();

  while (iterator.hasNext()) do
    begin
    conn := GPlayerConnection(iterator.next());

    conn.send(s);
		end;

	iterator.Free();
end;

{ our exit procedure, catches the server when unstable }
{ This is one of the most important pieces of code: the exit handler.
  These lines make sure that if the server crashes (due to illegal memory
  access, file operations, overload, etc.) the players are logged out
  and their data is saved properly. Also, this routine makes sure the
  server reboots automatically, no script needed! - Grimlord }
procedure reboot_exitproc;far;
var
	f : TextFile;
begin
	AssignFile(f, 'grendel.run');
	Erase(f);

  { okay, so we crashed :) }
  if (not grace_exit) then
    begin
    sendtoall('------ GAME CRASH DETECTED! ---- Saving all players.'#13#10#13#10);
    sendtoall('The server should be back online in less than a minute.'#13#10);
    sendtoall('If the server doesn''t auto-reboot, please notify'#13#10);
    sendtoall(pchar('the administration, '+system_info.admin_email+'.'#13#10));

    // save all characters and try to unlog before quitting
    flushConnections();

    Sleep(1000);

    // give operator/logfile a message
    writeConsole('CRASH WARNING -- SERVER IS UNSTABLE, WILL TRY TO REBOOT');

    boot_type := BOOTTYPE_REBOOT;
    end;

  exitproc := old_exitproc;

  { reboot }
  if (boot_type = BOOTTYPE_REBOOT) then
    reboot_mud
  else
  { copyover }
  if (boot_type = BOOTTYPE_COPYOVER) then
    begin
    if (connection_list.size() > 0) then
      copyover_mud
    else
      reboot_mud;
    end
  else
    shutdown_mud;
end;

// Boot the server
procedure bootServer();
var
  s : string;
begin
	writeConsole(version_info + ', ' + version_number + '.');
	writeConsole(version_copyright + '.');

	writeConsole('Initializing memory pool...');
	init_progs();
	initClans();
	initCommands();
	initConns();
	initHelp();
	initChannels();
	initChars();
	initPlayers();
	initSkills();
	initAreas();
	initTimers();
	initRaces();
	initNotes();
	initSystem();
	initEvents();

	{$IFDEF WIN32}
		{$IFNDEF CONSOLEBUILD}
		initSysTray();
		{$ENDIF}
	{$ENDIF}

	{ writeConsole('Reading debug info...');
	readMapFile('grendel.exe', 'grendel.map');
	readMapfile('core.bpl', 'core.map'); }
 
	writeConsole('Booting server...');
	loadSystem();

	s := FormatDateTime('ddddd', Now);
	writeConsole('Booting "' + system_info.mud_name + '" database, ' + s + '.');

	writeConsole('Loading skills...');
	load_skills();
	
	writeConsole('Loading races...');
	loadRaces();
	
	writeConsole('Loading clans...');
	load_clans;
	
	writeConsole('Loading channels...');
	load_channels();
	
	writeConsole('Loading areas...');
	loadAreas();
	
	writeConsole('Loading help...');
	loadHelp('help.dat');
	
	writeConsole('Loading namegenerator data...');
	loadNameTables(NameTablesDataFile);
	
	writeConsole('Loading noteboards...');
	load_notes('boards.dat');
	
	writeConsole('Loading modules...');
	loadModules();
	
	writeConsole('Loading texts...');
	loadCommands();
	loadSocials();
	loadDamage();
	
	writeConsole('Loading mud state...');
	BootTime := Now;

	boot_type := 0;
	bg_info.count := -1;
	boot_info.timer := -1;
	mud_booted := true;

	update_time;

	time_info.day := 1;
	time_info.month := 1;
	time_info.year := 1;

	loadMudState();

	randomize();

	openListenSockets();

	ExitProc := @reboot_exitproc;

	registerTimer('teleports', update_teleports, 1, true);
	registerTimer('fighting', update_fighting, CPULSE_VIOLENCE, true);
	registerTimer('battleground', update_battleground, CPULSE_VIOLENCE, true);
	registerTimer('objects', update_objects, CPULSE_TICK, true);
	registerTimer('characters', update_chars, CPULSE_TICK, true);
	registerTimer('gametime', update_time, CPULSE_GAMETIME, true);

	timer_thread := GTimerThread.Create();
	clean_thread := GCleanThread.Create();

	calculateonline();

	{$IFDEF WIN32}
		{$IFNDEF CONSOLEBUILD}
		registerSysTray();
		{$ENDIF}  
	{$ENDIF}
end;

// Recover from copyover
procedure from_copyover;
{$IFDEF WIN32}
var
   pipe : THandle;
   w, len : cardinal;
   prot : TWSAProtocol_Info;
   g : array[0..1023] of char;
   suc : boolean;
   sock : TSocket;
   sk : GSocket;
   client_addr : TSockAddr_Storage;
   cl : PSockAddr;
   l : integer;
begin
  pipe := INVALID_HANDLE_VALUE;
  
  while (true) do
    begin
    pipe := CreateFile(pipeName, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);

    if (pipe <> INVALID_HANDLE_VALUE) then
      break;

    if (GetLastError() <> ERROR_PIPE_BUSY) then
      begin
      bugreport('from_copyover', 'grendel.dpr', 'Could not restart from copyover');
			exit;
      end;

    // All pipe instances are busy, so wait a second
    if (not WaitNamedPipe(pipeName, 1000)) then
      begin
      bugreport('from_copyover', 'grendel.dpr', 'Could not restart from copyover');
			exit;
      end;
  end;
  
  sock := -1;

  repeat
    suc := ReadFile(pipe, prot, sizeof(prot), w, nil);

    if (suc) then
      sock := WSASocket(prot.iAddressFamily, SOCK_STREAM, IPPROTO_IP, @prot, 0, 0);

    suc := ReadFile(pipe, len, 4, w, nil);
    
    if (not suc) then
    	break;
    	
    suc := ReadFile(pipe, g, len, w, nil);

    if (suc) and (sock <> -1) then
      begin
      g[len] := #0;
      
      cl := @client_addr;
      l := 128;
      getpeername(sock, cl^, l);
      
      sk := createSocket(prot.iAddressFamily, sock);
      sk.setNonBlocking();     
      sk.socketAddress := client_addr;
      sk.resolve(system_info.lookup_hosts);

      GPlayerConnection.Create(sk, true, g);
      end;
  until (not suc);

  CloseHandle(pipe);
end;
{$ELSE}
begin
  writeConsole('Copyover not supported on this platform.');
end;
{$ENDIF}

{$IFDEF WIN32}
{$IFDEF CONSOLEBUILD}
function controlHandler(event : DWORD) : boolean;
begin
  Result := true;
  grace_exit := true;
  SetConsoleCtrlHandler(@controlHandler, false);
  halt;
end;
{$ENDIF}
{$ENDIF}

procedure gameLoop();
var
	iterator : GIterator;
	socket : GSocket;
begin
  while (not system_info.terminated) do
    begin
    iterator := listenSockets.iterator();
    
    while (iterator.hasNext()) do
    	begin
    	socket := GSocket(iterator.next());
    	
    	if (socket.canRead()) then
    		acceptConnection(socket);
    	end;
    	
    iterator.Free();

    {$IFDEF WIN32}
    Application.ProcessMessages();
    {$ENDIF}

		pollConsole();
    
    sleep(25);
    end;    
end;

var
	tm : TDateTime;
	f : file;

begin
	if (FileExists('grendel.run')) then
		begin
		{$IFDEF CONSOLEBUILD}
		writeln('Server is already running? (delete grendel.run if this is not the case)');
		{$ELSE}
			{$IFDEF WIN32}
			MessageBox(0, 'Server is already running? (delete grendel.run if this is not the case)', 'Server is already running', 0);
			{$ENDIF}
		{$ENDIF}
		exit;
		end;
		
	AssignFile(f, 'grendel.run');
	Rewrite(f);
	CloseFile(f);
	
	old_exitproc := ExitProc;
	tm := Now();
	
	initDebug();

	bootServer();  
  
{$IFDEF WIN32}
	if (GetCommandLine() = 'copyover') or (paramstr(1) = 'copyover') then
		from_copyover();
{$ENDIF}

	tm := Now() - tm;

	writeConsole('Server boot took ' + FormatDateTime('s "second(s)," z "millisecond(s)"', tm));
	writeConsole('Grendel ' + version_number + ' ready...');

{$IFDEF WIN32}
{$IFDEF CONSOLEBUILD}
	SetConsoleCtrlHandler(@controlHandler, true);
{$ENDIF}
{$ENDIF}

	gameLoop();
end.
