{
	Summary:
		Copyover / service reboot helper application
		
	## $Id: helper.dpr,v 1.2 2004/05/06 20:49:07 ***REMOVED*** Exp $
}
program helper;
{$APPTYPE CONSOLE}
uses
	{$IFDEF WIN32}
	WinSock2,
	Windows,
	{$ENDIF}
	{$IFDEF LINUX}
	Libc,
	{$ENDIF}
	JclSvcCtrl,
	SysUtils,
	DateUtils,
	Classes,
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
		procedure write(timestamp : integer; const text : string; debugLevel : integer = 0); override;
  	end;
  	

var
	cons : GConsole;
	

procedure GConsoleCopyover.write(timestamp : integer; const text : string; debugLevel : integer = 0);
begin
	writeln('[' + FormatDateTime('hh:nn:ss', UnixToDateTime(timestamp)) + '] ', text);
end;	


procedure copyoverServer();
var
	{$IFDEF WIN32}
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
	calling_pid : cardinal;
	hProcess : THandle;
	exitCode : cardinal;
	{$ENDIF}
begin
	cons.write('Starting copyover...');

	connectionList := TList.Create();

	{$IFDEF WIN32}
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
	
	suc := ReadFile(pipe, calling_pid, 4, w, nil);
	
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

	// wait for calling Grendel process to die
	cons.write('Waiting for calling process #' + IntToStr(calling_pid) + ' to die...');
	
	hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, false, calling_pid);
	
	GetExitCodeProcess(hProcess, exitCode);
	
	while (exitCode = STILL_ACTIVE) do
		begin
		Sleep(25);
		GetExitCodeProcess(hProcess, exitCode);
		end;
	
	CloseHandle(hProcess);

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

	if (not CreateProcess('grendel.exe', 'grendel copyover', Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI)) then
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
	{$ENDIF}
	
	connectionList.clear();
	connectionList.Free();
end;

procedure rebootService();
var
	manager : TJclSCManager;
	service : TJclNtService;
begin
	manager := TJclSCManager.Create();
	manager.Refresh(true);
	
	if (not manager.FindService('ServiceGrendel', service)) then
		begin
		writeConsole('Could not locate service');
		exit;
		end;
		
	if (service.serviceState <> ssStopped) then
		begin
		writeConsole('Service is probably stopping, waiting 5 seconds');
		
		service.WaitFor(ssStopped, 5000);	
		service.Refresh();

		if (service.serviceState <> ssStopped) then
			begin
			writeConsole('Service did not stop in time, aborting');
			exit;
			end;
		end;
		
	writeConsole('Starting service');
	service.Start(false);
	manager.Free();
end;


begin
	writeConsole('Reboot/copyover helper application');
	writeConsole(version_copyright + '.');

	cons := GConsole.Create();
	cons.attachWriter(GConsoleLogWriter.Create('helper'));
	cons.attachWriter(GConsoleCopyover.Create());

	if (ParamStr(1) = 'copyoverservice') then
		begin
		end
	else
	if (ParamStr(1) = 'rebootservice') then
		begin
		rebootService();
		end
	else
	if (ParamStr(1) = 'copyover') then
		begin
		copyoverServer();
		end
	else
		begin
		writeConsole('Unknown command line option ' + ParamStr(1));
		end;
				
	initDebug();
	
	cons.write('Cleaned up.');
	
	cons.Free();
end.
