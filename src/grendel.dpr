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

  $Id: grendel.dpr,v 1.18 2004/03/20 19:44:23 ***REMOVED*** Exp $
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
	dtypes,
	player,
	mudsystem,
	debug,
	socket,
	server,
	console,
	conns,
	fight,
	constants;


const 
	pipeName : pchar = '\\.\pipe\grendel';


var
	oldExitProc : pointer;
	


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

// Reboot procedure
procedure rebootServer();
{$IFDEF WIN32}
var
	SI: TStartupInfo;
	PI: TProcessInformation;
{$ENDIF}
begin
	{$IFDEF WIN32}
	FillChar(SI, SizeOf(SI), 0);
	SI.cb := SizeOf(SI);
	SI.wShowWindow := sw_show;

	if (not CreateProcess('grendel.exe',Nil, Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI)) then
		bugreport('reboot_mud', 'grendel.dpr', 'Could not execute grendel.exe, reboot failed!');
	{$ENDIF}
	{$IFDEF LINUX}
	if (execv('grendel', nil) = -1) then
		bugreport('reboot_mud', 'grendel.dpr', 'Could not execute grendel, reboot failed!');
	{$ENDIF}
end;

// Copyover procedure
procedure copyoverServer();
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
		rebootServer();
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
		rebootServer();
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
			rebootServer();
			end;

		if (not WriteFile(pipe, prot, sizeof(prot), w, nil)) then
			begin
			bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
			rebootServer();
			end;

		strpcopy(name, conn.ch.name);
		len := strlen(name);

		if (not WriteFile(pipe, len, 4, w, nil)) then
			begin
			bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
			rebootServer();
			end;

		if (not WriteFile(pipe, name, len, w, nil)) then
			begin
			bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
			rebootServer();
			end;

		conn.Terminate();

		node := node_next;
		end;

	Sleep(500);

	CloseHandle(pipe);
end;
{$ELSE}
begin
	writeConsole('Copyover not supported on this platform.');
end;
{$ENDIF}

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
	SetConsoleCtrlHandler(@controlHandler, false);
	halt;
end;
{$ENDIF}
{$ENDIF}

{ Our last hope, the ExitProc handler }
procedure serverExitProc; far;
var
	f : TextFile;
begin
	ExitProc := oldExitProc;
	
	{$I-}
	AssignFile(f, 'grendel.run');	
	Erase(f);
	{$I+}
	
	if (serverBooted) then
		begin
		sendtoall('------ GAME CRASH DETECTED! ---- Saving all players.'#13#10#13#10);
		sendtoall('The server should be back online in less than a minute.'#13#10);
		sendtoall('If the server doesn''t auto-reboot, please notify'#13#10);
		sendtoall(pchar('the administration, '+system_info.admin_email+'.'#13#10));

		// save all characters and try to unlog before quitting
		flushConnections();

		Sleep(1000);

		// give operator/logfile a message
		{$IFDEF CONSOLEBUILD}
		writeln('CRASH WARNING -- SERVER IS UNSTABLE, WILL TRY TO REBOOT');
		{$ENDIF}

		rebootServer();
		end;
end;


type
  	GConsoleGrendel = class(GConsoleWriter)
  	public
		procedure write(timestamp : TDateTime; const text : string; debugLevel : integer = 0); override;
  	end;
  	
procedure GConsoleGrendel.write(timestamp : TDateTime; const text : string; debugLevel : integer = 0);
begin
	writeln('[' + FormatDateTime('hh:nn', Now) + '] ', text);
end;	


var
	serverInstance : GServer;
	f : file;
	shutdownType : GServerShutdownTypes;
	tm : TDateTime;
	cons : GConsole;
	
	{$IFDEF LINUX}
	sSet : TSigSet;
	aOld, aTerm, aHup : PSigAction;  
	{$ENDIF}
	

{$IFDEF LINUX}
procedure handleSignal(signal : longint); cdecl;
begin
	case signal of
		SIGTERM: 	begin
				writeConsole('Received SIGTERM, halting');
				serverInstance.shutdown(SHUTDOWNTYPE_HALT, 0);
				end;
	end;
end;
{$ENDIF}


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

	oldExitProc := ExitProc;
	ExitProc := @serverExitProc;
		
	AssignFile(f, 'grendel.run');
	Rewrite(f);
	CloseFile(f);

	cons := GConsole.Create();
	cons.attachWriter(GConsoleLogWriter.Create('grendel'));
	
	{$IFDEF CONSOLEBUILD}
	cons.attachWriter(GConsoleGrendel.Create());
	{$ENDIF}
	
	cons.Free();
	
	{$IFDEF LINUX}
	{ block all signals except for SIGTERM/SIGHUP }
	sigfillset(sSet);
	sigdelset(sSet, SIGTERM);
	sigdelset(sSet, SIGHUP);
	sigprocmask(SIG_BLOCK, @sSet, nil);
	
	{ setup the signal handlers }
	new(aOld);
        new(aHup);
        new(aTerm);
        
        aTerm^.__sigaction_handler := @handleSignal;
        aTerm^.sa_flags := 0;
        aTerm^.sa_restorer := nil;
        
        aHup^.__sigaction_handler:= @handleSignal;
        aHup^.sa_flags := 0;
        aHup^.sa_restorer := nil;
        
        SigAction(SIGTERM,aTerm,aOld);
        SigAction(SIGHUP,aHup,aOld);
        
        case fork() of
		0:	begin
			Close(input);  { close standard in }
                        AssignFile(output,'/dev/null');
                        ReWrite(output);
                        AssignFile(ErrOutPut,'/dev/null');
                        ReWrite(ErrOutPut);
                        end;
		-1: 	begin
			writeln('fork() failed, continuing on foreground');
			end;
	else
		begin
		Halt(0);
		end;
	end;
	{$ENDIF}
	
	initDebug();

	{$IFDEF WIN32}
	{$IFDEF CONSOLEBUILD}
	SetConsoleCtrlHandler(@controlHandler, true);
	{$ENDIF}
	{$ENDIF}

	serverInstance := GServer.Create();

	tm := Now();

	serverInstance.init();

	{$IFDEF WIN32}
	if (GetCommandLine() = 'copyover') or (paramstr(1) = 'copyover') then
		from_copyover();
	{$ENDIF}

	tm := Now() - tm;

	writeConsole('Server boot took ' + FormatDateTime('s "second(s)," z "millisecond(s)"', tm));
	writeConsole('Grendel ' + version_number + ' ready...');
	
	shutdownType := serverInstance.gameLoop();
	
	if (shutdownType = SHUTDOWNTYPE_COPYOVER) then
		begin
		copyoverServer();
		end
	else
		flushConnections();	
	
	serverInstance.cleanup();
	
	serverInstance.Free();
	
	if (shutdownType = SHUTDOWNTYPE_REBOOT) then
		rebootServer();
end.
