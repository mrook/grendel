{
	Summary:
		NT Service main unit
	
	## $Id: servicemain.pas,v 1.5 2004/05/06 21:58:05 ***REMOVED*** Exp $
}

unit servicemain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs;

type
  TServiceGrendel = class(TService)
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceAfterInstall(Sender: TService);
  private
    { Private declarations }
    procedure serverTick();
    procedure copyoverService();
    procedure copyoverRecover();
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  ServiceGrendel: TServiceGrendel;

implementation

{$R *.DFM}

uses
	Registry,
	Winsock2,
	conns,
	dtypes,
	fight,
	socket,
	player,
	constants,
	mudsystem,
	console,
	server;


const 
	pipeName : pchar = '\\.\pipe\grendel';


var
	serverInstance : GServer;


procedure ServiceController(CtrlCode: cardinal); stdcall;
begin
	ServiceGrendel.Controller(CtrlCode);
end;

function TServiceGrendel.GetServiceController: TServiceController;
begin
	Result := ServiceController;
end;

procedure TServiceGrendel.serverTick();
begin
	ServiceThread.ProcessRequests(false);
end;

procedure waitConnections();
begin
	// Wait for connection_list to clean itself
	while (connection_list.size() > 0) do
		begin
		Sleep(25);
		end;
end;

// Copyover procedure
procedure TServiceGrendel.copyoverService();
var
	SI: TStartupInfo;
	PI: TProcessInformation;
	pipe : THandle;
	prot : TWSAProtocol_Info;
	w, len : cardinal;
	name : array[0..1023] of char;
	node, node_next : GListNode;
	conn : GPlayerConnection;
	pid : cardinal;
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

	if (not CreateProcess('helper.exe', 'helper copyoverservice', Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI)) then
		begin
		bugreport('copyover_mud', 'grendel.dpr', 'Could not execute helper.exe, copyover failed!');
		exit;
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
		exit;
		end;
		
	pid := GetCurrentProcessID();
	
	if (not WriteFile(pipe, pid, 4, w, nil)) then
		begin
		bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
		exit;
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
			exit;
			end;

		if (not WriteFile(pipe, prot, sizeof(prot), w, nil)) then
			begin
			bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
			exit;
			end;

		strpcopy(name, conn.ch.name);
		len := strlen(name);

		if (not WriteFile(pipe, len, 4, w, nil)) then
			begin
			bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
			exit;
			end;

		if (not WriteFile(pipe, name, len, w, nil)) then
			begin
			bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
			exit;
			end;

		conn.Terminate();
		
		node := node_next;
		end;

	waitConnections();
		
	CloseHandle(pipe);
end;

procedure TServiceGrendel.copyoverRecover();
var
	client_addr : TSockAddr_Storage;
	cl : PSockaddr;
	sk : GSocket;
	conn : GPlayerConnection;
	pipe : THandle;
	w, len : cardinal;
	prot : TWSAProtocol_Info;
	g : array[0..1023] of char;
	suc : boolean;
	sock : TSocket;
	l : integer;
	pid : cardinal;
begin
	writeConsole('Recovering from copyover...');
	
	pipe := INVALID_HANDLE_VALUE;

	while (true) do
		begin
		pipe := CreateFile(pipeName, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);

		if (pipe <> INVALID_HANDLE_VALUE) then
			break;

		if (GetLastError() <> ERROR_PIPE_BUSY) then
			begin
			bugreport('copyoverRecover', 'grendel.dpr', 'Could not restart from copyover');
			exit;
			end;

		// All pipe instances are busy, so wait a second
		if (not WaitNamedPipe(pipeName, 1000)) then
			begin
			bugreport('copyoverRecover', 'grendel.dpr', 'Could not restart from copyover');
			exit;
			end;
		end;

	pid := GetCurrentProcessID();
	
	if (not WriteFile(pipe, pid, 4, w, nil)) then
		begin
		bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
		exit;
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

			conn := GPlayerConnection.Create(sk, true, g);
			conn.Resume();
			end;
	until (not suc);

	CloseHandle(pipe);
end;

procedure TServiceGrendel.ServiceExecute(Sender: TService);
var
	shutdownType : GServerShutdownTypes;
	SI: TStartupInfo;
	PI: TProcessInformation;
	x : integer;
begin
	if (ParamCount > 1) and (Param[1] = 'copyover') then
		copyoverRecover();
		
	writeConsole('Grendel ' + version_number + ' ready...');

	serverInstance.OnTick := serverTick;

	shutdownType := serverInstance.gameLoop();

	if (shutdownType = SHUTDOWNTYPE_COPYOVER) then
		begin
		copyoverService();
		end
	else
		flushConnections();	

	serverInstance.cleanup();

	serverInstance.Free();
	
	Status := csStopped;
	ReportStatus();
	
	if (shutdownType = SHUTDOWNTYPE_REBOOT) then
		begin
		FillChar(SI, SizeOf(SI), 0);
		SI.cb := SizeOf(SI);
		SI.wShowWindow := sw_show;

		if (not CreateProcess('helper.exe', 'helper rebootservice', Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI)) then
			exit;
		end;
end;

procedure TServiceGrendel.ServiceStart(Sender: TService;
  var Started: Boolean);
var
	cons : GConsole;
	path : string;
begin
	Started := false;
	
	path := ExtractFilePath(ParamStr(0));

 	if (not DirectoryExists(path)) then
  		begin
    	ErrCode := 1;
		LogMessage('Directory "' + path + '" does not exist', EVENTLOG_ERROR_TYPE, 0, 1);
    	exit;
    	end;

	ChDir(path);

	cons := GConsole.Create();
	cons.attachWriter(GConsoleLogWriter.Create('grendelservice'));
	cons.Free();

	serverInstance := GServer.Create();
	serverInstance.init();

 	writeConsole('Running as NT service...');

	Started := true;
end;

procedure TServiceGrendel.ServiceStop(Sender : TService; var Stopped: Boolean);
begin
	writeConsole('NT service halting...');
	
	serverInstance.shutdown(SHUTDOWNTYPE_HALT, 0);
end;

procedure TServiceGrendel.ServiceAfterInstall(Sender: TService);
begin
	with TRegistry.Create(KEY_READ or KEY_WRITE) do
	try
		RootKey := HKEY_LOCAL_MACHINE;
		if OpenKey( 'SYSTEM\CurrentControlSet\Services\' + Name, True) then
			begin
			WriteString('Description', version_info + ' Version ' + version_number);
			end;
	finally
		Free();
	end;
end;

end.
