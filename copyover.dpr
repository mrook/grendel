program copyover;
{$APPTYPE CONSOLE}
uses
  SysUtils,
	Classes,
  Windows,
	Winsock2;


const pipeName : pchar = '\\.\pipe\grendel';

type
   	Connection = class
			socket : TSocket;
			name : string;
		end;

var
   pipe : THandle;
   a, w, len : cardinal;
   prot : TWSAProtocol_Info;
	 g : array[0..1023] of char;
	 suc : boolean;
   sock : TSocket;
   hWSAData : TWSAData;
   ver : integer;
   c : Connection;
	 conns : TList;
   SI: TStartupInfo;
   PI: TProcessInformation;
	 f : file;
   ret : integer;


begin
  conns := TList.Create;

  ver := WINSOCK_VERSION;

  if (WSAStartup(ver, hWSAData) <> 0) then
    exit;
    
  writeln('Starting copyover...');

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

			conns.Add(c);
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

	strpcopy(g, #13#10'In the void of space, you look around... fragments of memory flash by...'#13#10);

  for w := 0 to conns.count - 1 do
    begin
		c := conns.items[w];

		send(c.socket, g, strlen(g), 0);
		end;

  sleep(1000);

  writeln('Spawning new process...');

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.wShowWindow := sw_show;

  if (not CreateProcess('grendel.exe', 'copyover', Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI)) then
    exit;

  pipe := CreateNamedPipe(pipeName, PIPE_ACCESS_DUPLEX, PIPE_TYPE_BYTE or PIPE_READMODE_BYTE, 1, 0, 0, 10000, nil);
  
  if (not ConnectNamedPipe(pipe, nil)) then
    exit;

  writeln('Duplicating connections...');

  for a := 0 to conns.count - 1 do
    begin
		c := conns.items[a];

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

  CloseHandle(pipe);

  WSACleanup;
  
  writeln('Cleaned up.');
end.

