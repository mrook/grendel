program copyover;
{$APPTYPE CONSOLE}
{$IFDEF WIN32}
uses
	SysUtils,
	Classes,
	Windows,
	WinSock2,
	debug,
	console,
	socket;


const 
	pipeName : pchar = '\\.\pipe\grendel';
	

type
   	Connection = class
		socket : TSocket;
		name : string;
	end;
	
  	GConsoleCopyover = class(GConsoleWriter)
  	public
		procedure write(timestamp : TDateTime; const text : string); override;
  	end;
	

var
	prot : TWSAProtocol_Info;
	pipe : THandle;
	connectionList : TList;
	a, w, len : cardinal;
	g : array[0..1023] of char;
	suc : boolean;
	sock : TSocket;
	c : Connection;
	SI: TStartupInfo;
	PI: TProcessInformation;
	f : file;
	ret : integer;
	cons : GConsole;
	

procedure GConsoleCopyover.write(timestamp : TDateTime; const text : string);
begin
	writeln('[' + FormatDateTime('hh:nn', Now) + '] ', text);
end;	

begin
	cons := GConsole.Create();
	cons.attachWriter(GConsoleLogWriter.Create('copyover'));
	cons.attachWriter(GConsoleCopyover.Create());
	
	initDebug();
	connectionList := TList.Create();

	cons.write('Starting copyover...');

	pipe := INVALID_HANDLE_VALUE;

	while (true) do
		begin
		pipe := CreateFile(pipeName, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);

		if (pipe <> INVALID_HANDLE_VALUE) then
			break;

		ret := GetLastError();

		if (ret <> ERROR_PIPE_BUSY) and (ret <> ERROR_FILE_NOT_FOUND) then
			exit;

		// All pipe instances are busy, so wait a second
		if (ret = ERROR_PIPE_BUSY) then
			if (not WaitNamedPipe(pipeName, 500)) then
				exit;
		end;

	sock := -1;

	repeat
		suc := ReadFile(pipe, prot, sizeof(prot), w, nil);

		if (not suc) or (w < sizeof(prot)) then
			break;

		if (suc) then
			sock := WSASocket(prot.iAddressFamily, SOCK_STREAM, IPPROTO_IP, @prot, 0, 0);

		suc := ReadFile(pipe, len, 4, w, nil);

		if (not suc) or (w < 4) then
			break;

		suc := ReadFile(pipe, g, len, w, nil);

		if (not suc) or (w < len) then
			break;

		if (suc) and (sock <> -1) then
			begin
			g[len] := #0;

			c := Connection.Create;			
			c.socket := sock;
			c.name := g;

			connectionList.add(c);
			end;
	until (not suc);

	CloseHandle(pipe);

	// give Grendel time to die
	sleep(1000);

	// check for any new grendel.exe in dir "bin\"
	if (FileExists('bin\grendel.exe')) then
		begin
		if (CopyFile('bin\grendel.exe', 'grendel.exe', false)) then
			begin
			assign(f, 'bin\grendel.exe');
			erase(f);
			end;
		end;

	// check for a new core.bpl in dir "bin\"
	if (FileExists('bin\core.bpl')) then
		begin
			if (CopyFile('bin\core.bpl', 'core.bpl', false)) then
			begin
			assign(f, 'bin\core.bpl');
			erase(f);
			end;
		end;

	strpcopy(g, #13#10'In the void of space, you look around... fragments of memory flash by...'#13#10);

	if (connectionList.Count > 0) then
		begin
		for w := 0 to connectionList.Count - 1 do
			begin
			c := connectionList.items[w];

			send(c.socket, g, strlen(g), 0);
			end;
		end;

	sleep(1000);

	cons.write('Spawning new process...');

	FillChar(SI, SizeOf(SI), 0);
	SI.cb := SizeOf(SI);
	SI.wShowWindow := sw_show;

	if (not CreateProcess('grendel.exe', 'copyover', Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI)) then
		exit;

	pipe := CreateNamedPipe(pipeName, PIPE_ACCESS_DUPLEX, PIPE_TYPE_BYTE or PIPE_READMODE_BYTE, 1, 0, 0, 10000, nil);

	if (not ConnectNamedPipe(pipe, nil)) then
		exit;

	cons.write('Duplicating connections...');

	if (connectionList.Count > 0) then
		begin
		for a := 0 to connectionList.Count - 1 do
			begin
			c := connectionList.items[a];

			if (WSADuplicateSocket(c.socket, PI.dwProcessId, @prot) = -1) then
			exit;

			if (not WriteFile(pipe, prot, sizeof(prot), w, nil)) then
			exit;

			strpcopy(g, c.name);
			len := strlen(g);

			if (not WriteFile(pipe, len, 4, w, nil)) then
			exit;

			if (not WriteFile(pipe, g, len, w, nil)) then
			exit;

			closesocket(c.socket);
			end;
		end;

	CloseHandle(pipe);

	cons.write('Cleaned up.');
end.
{$ENDIF}
{$IFDEF LINUX}
begin
	writeln('Not implemented for this platform.');
end.
{$ENDIF}