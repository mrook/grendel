{
  Summary:
  	Wrappers for IPv4 and IPv6 socket operations
  	
  ## $Id: socket.pas,v 1.9 2004/03/30 12:22:42 ***REMOVED*** Exp $
}

unit socket;

interface


uses
{$IFDEF WIN32}
	Winsock2;
{$ENDIF}
{$IFDEF LINUX}
	KernelIoctl,
	Libc;
{$ENDIF}


type
{$IFDEF LINUX}
	TSockAddr = sockaddr;
	TSockAddr6 = sockaddr_in6;
	TSockAddr_Storage = sockaddr_storage;
{$ENDIF}

	GSocketTypes = (SOCKTYPE_IPV4, SOCKTYPE_IPV6);
	
	GSocket = class
	private
		af : integer;
		fd : TSocket;
		addr : TSockAddr_Storage;
		rw_set, ex_set : TFDSet;
		time : TTimeVal;
		ip_string : string;
		host_string : string;

	public
		procedure resolve(lookup_hosts : boolean); 
		procedure disconnect();
  
		procedure openPort(port : integer); virtual;
    
		procedure setNonBlocking();

		function isValid() : boolean;

		function canRead() : boolean;
		function canWrite() : boolean;
		function read(var Buf; len : integer) : integer;
		function send(s : string) : integer; overload;
		function send(var s; len : integer) : integer; overload;
    
		function acceptConnection(lookup_hosts : boolean) : GSocket;
    
		function connect(const remoteName : string; port : integer) : boolean;
    
		constructor Create(_af : integer; _fd : TSocket = -1);
		destructor Destroy; override;
    
		property getDescriptor : TSocket read fd;
		property getAddressFamily : integer read af;
		property socketAddress : TSockAddr_Storage read addr write addr;
		property hostString : string read host_string;
		property ipString : string read ip_string;
	end;
  
	GSocket4 = class(GSocket)
	private
		addrv4 : TSockAddrIn;
    
	public
		constructor Create(); overload;
		constructor Create(fd : TSocket); overload;

		procedure openPort(port : integer); override;
	end;
  
	GSocket6 = class(GSocket)
	private
		addrv6 : TSockAddr6;
		ssv6 : TSockAddr_Storage;
		addrv6p : PSockAddr;
    
	public
		constructor Create(); overload;
		constructor Create(fd : TSocket); overload;

		procedure openPort(port : integer); override;
	end;


function isSupported(socketType : GSocketTypes) : boolean; overload;
function isSupported(af : integer) : boolean; overload;

function createSocket(socketType : GSocketTypes; fd : TSocket = -1) : GSocket; overload;
function createSocket(af : integer; fd : TSocket = -1) : GSocket; overload;


implementation


uses
	SysUtils;


{$IFDEF WIN32}
var
	hWSAData : TWSAData;
	ver : integer;
{$ENDIF}


{ Convert a symbolic socketType to address family }
function socketTypeToFamily(socketType : GSocketTypes) : integer;
begin
	case socketType of
		SOCKTYPE_IPV4: Result := AF_INET;
		SOCKTYPE_IPV6: Result := AF_INET6;
	end;
end;

{ Check wether socketType is a supported address family }
function isSupported(socketType : GSocketTypes) : boolean;
begin
	Result := isSupported(socketTypeToFamily(socketType));
end;

{ Check wether af is a supported address family }
function isSupported(af : integer) : boolean;
{$IFDEF WIN32}
var
	x, ret, size : integer;
	lpprot : array[0..1] of integer;
	lpinfo, pinfo : LPWSAProtocol_Info;
begin
	Result := false;

	size := SizeOf(TWSAProtocol_Info) * 10;
	
	GetMem(lpinfo, size);

	lpprot[0] := IPPROTO_TCP;
	lpprot[1] := 0;

	x := size;
	ret := WSAEnumProtocols(@lpprot, lpinfo, x);
	
	if (ret = SOCKET_ERROR) then
		begin
		raise Exception.Create('WSAEnumProtocols failed: ' + IntToStr(WSAGetLastError()));
		end
	else
		begin
		for x := 0 to ret - 1 do
			begin
			pinfo := pointer(integer(lpinfo) + (x * sizeof(TWSAProtocol_Info)));

			if (pinfo^.iAddressFamily = af) then
				Result := true;
			end;
		end;
		
	FreeMem(lpinfo, size);
end;
{$ELSE}
var
	fd : TSocket;
begin
	fd := Libc.socket(af, SOCK_STREAM, IPPROTO_TCP);

	if (fd = INVALID_SOCKET) then
		Result := false
	else
		Result := true;
end;
{$ENDIF}

{ Create a socket of type socketType }
function createSocket(socketType : GSocketTypes; fd : TSocket = -1) : GSocket;
begin
	Result := createSocket(socketTypeToFamily(socketType), fd);
end;

{ Create a socket of type af }
function createSocket(af : integer; fd : TSocket = -1) : GSocket;
begin
	if (af = AF_INET) then
		Result := GSocket4.Create(fd)
	else
	if (af = AF_INET6) then
		Result := GSocket6.Create(fd)
	else
		raise Exception.Create('Unsupported address family');
end;


// GSocket
constructor GSocket.Create(_af : integer; _fd : TSocket = -1);
begin
  inherited Create();
  
  af := _af;

  if (_fd = -1) then
    begin
    {$IFDEF WIN32}
    fd := Winsock2.socket(af, SOCK_STREAM, IPPROTO_TCP);
    {$ENDIF}
    {$IFDEF LINUX}
    fd := Libc.socket(af, SOCK_STREAM, IPPROTO_TCP);
    {$ENDIF}

    if (fd = INVALID_SOCKET) then
      raise Exception.Create('Could not create socket.');
    end
  else
    fd := _fd;
end;

destructor GSocket.Destroy;
begin
  disconnect();

  inherited Destroy();
end;

procedure GSocket.disconnect();
begin
{$IFDEF LINUX}
  __close(fd);
{$ENDIF}
{$IFDEF WIN32}
  closesocket(fd);
{$ENDIF}
end;

procedure GSocket.resolve(lookup_hosts : boolean);
var
  h : PHostEnt;
  l, p : integer;
  v6 : TSockAddr6;
  v4 : TSockAddr;
begin
{$IFDEF LINUX}
  if (addr.__ss__family = AF_INET) then
{$ENDIF}
{$IFDEF WIN32}
  if (addr.ss_family = AF_INET) then
{$ENDIF}
    begin
    move(addr, v4, sizeof(v4));

    ip_string := inet_ntoa(v4.sin_addr);

    if (lookup_hosts) then
      begin
      h := gethostbyaddr(@v4.sin_addr.s_addr, 4, AF_INET);

      if (h <> nil) then
        host_string := h.h_name
      else
        host_string := ip_string;
      end
    else
      host_string := ip_string;
    end
  else
{$IFDEF LINUX}
  if (addr.__ss__family = AF_INET6) then
{$ENDIF}
{$IFDEF WIN32}
  if (addr.ss_family = AF_INET6) then
{$ENDIF}
    begin
    move(addr, v6, sizeof(v6));

    l := 0;

    while (l < 16) do
      begin
      p := (byte(v6.sin6_addr.s6_addr[l]) shl 8) + byte(v6.sin6_addr.s6_addr[l + 1]);

      if (p = 0) then
        begin
        ip_string := ip_string + ':';

        while (p = 0) do
          begin
          p := (byte(v6.sin6_addr.s6_addr[l]) shl 8) + byte(v6.sin6_addr.s6_addr[l + 1]);

          inc(l, 2);
          end;
        end
      else
        inc(l, 2);

      if (ip_string <> '') then
        ip_string := ip_string + ':';

      ip_string := ip_string + lowercase(inttohex(p, 1));
      end;

    host_string := ip_string;
    end;
end;

function GSocket.isValid() : boolean;
begin
	Result := (fd <> INVALID_SOCKET);
end;

function GSocket.canRead() : boolean;
begin
	Result := false;
	
	if (not isValid) then
		exit;
  
	FD_ZERO(rw_set);
	FD_SET(fd, rw_set);
	FD_ZERO(ex_set);
	FD_SET(fd, ex_set);

	time.tv_sec := 0;
	time.tv_usec := 0;

	if (select(fd + 1, @rw_set, nil, @ex_set, @time) = SOCKET_ERROR) or (FD_ISSET(fd, ex_set)) then
		begin
		fd := INVALID_SOCKET;
		raise Exception.Create('Connection reset by peer');
		end;

	if (FD_ISSET(fd, rw_set)) then
		Result := true;
end;

function GSocket.canWrite() : boolean;
begin
	Result := false;

	if (not isValid) then
		exit;
  
	FD_ZERO(rw_set);
	FD_SET(fd, rw_set);
	FD_ZERO(ex_set);
	FD_SET(fd, ex_set);

	time.tv_sec := 0;
	time.tv_usec := 0;

	if (select(fd + 1, nil, @rw_set, @ex_set, @time) = SOCKET_ERROR) or (FD_ISSET(fd, ex_set)) then
		begin
		fd := INVALID_SOCKET;
		raise Exception.Create('Connection reset by peer');
		end;

	if (FD_ISSET(fd, rw_set)) then
		Result := true;
end;

function GSocket.send(s : string) : integer;
begin
	if (not isValid) then
		begin
		Result := -1;
		exit;
		end;
		
	Result := send(s[1], length(s));
end;

function GSocket.send(var s; len : integer) : integer;
var
	res : integer;
begin
	if (not isValid) then
		begin
		Result := -1;
		exit;
		end;

	res := 0;
  
	if (len > 0) then	
{$IFDEF WIN32}
		res := Winsock2.send(fd, s, len, 0);
{$ENDIF}
{$IFDEF LINUX}
		res := Libc.send(fd, s, len, 0);
{$ENDIF}

	if (res = SOCKET_ERROR) then
		begin
		fd := INVALID_SOCKET;
		raise Exception.Create('Connection reset by peer');
		end;
    
	Result := res;
end;

function GSocket.read(var buf; len : integer) : integer;
var
	res : integer;
begin
	res := recv(fd, buf, len, 0);
  
	if (res = SOCKET_ERROR) then
		begin
		fd := INVALID_SOCKET;
		raise Exception.Create('Connection reset by peer');
		end;
    
	Result := res;
end;

procedure GSocket.setNonBlocking();
var
	x : integer;
begin
	if (not isValid) then
		exit;

{$IFDEF WIN32}
	x := 1;
	ioctlsocket(fd, FIONBIO, x);
{$ENDIF}
{$IFDEF LINUX}
 	x := fcntl(fd, F_GETFL);
	fcntl(fd, F_SETFL, x or O_NONBLOCK);
{$ENDIF}
end;

function GSocket.acceptConnection(lookup_hosts : boolean) : GSocket;
var
	ac_fd : TSocket;
	client_addr : TSockAddr_Storage;
	len : integer;
	sk : GSocket;
begin
	len := 128;

{$IFDEF LINUX}  
	ac_fd := accept(fd, PSockAddr(@client_addr), @len);
{$ELSE}
	ac_fd := accept(fd, PSockAddr(@client_addr)^, len);
{$ENDIF}

	sk := createSocket(af, ac_fd);
	sk.addr := client_addr;

	sk.resolve(lookup_hosts);

	Result := sk;
end;

function GSocket.connect(const remoteName : string; port : integer) : boolean;
var
	addrLength : integer;
	addrPointer : PChar;
	sockAddr : TSockAddr;
	hostent : PHostEnt;
begin
	hostent := gethostbyname(PChar(remoteName));
	
	if (hostent = nil) then
		raise Exception.Create('Could not resolve hostname ' + remoteName);

	addrLength := hostent^.h_length;
	addrPointer := hostent^.h_addr_list^;

	sockAddr.sin_family := af;
	sockAddr.sin_port := htons(port);
	StrMove (PChar(@sockAddr.sin_addr.s_addr), addrPointer, addrLength);
        
	{$IFDEF WIN32}
	Result := WinSock2.connect(fd, sockAddr, sizeof(sockAddr)) = 0;
	{$ENDIF}

	{$IFDEF LINUX}
	Result := Libc.connect(fd, sockAddr, sizeof(sockAddr)) = 0;
	{$ENDIF}
end;

procedure GSocket.openPort(port : integer);
begin
  raise Exception.Create('Operation not supported');
end;


// GSocket4
constructor GSocket4.Create;
begin 
	inherited Create(AF_INET);
end;

constructor GSocket4.Create(fd : TSocket);
begin 
	inherited Create(AF_INET, fd);
end;

procedure GSocket4.openPort(port : integer);
var
  rc : integer;
begin
  rc := 1;
    
  if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, @rc, sizeof(rc)) < 0) then
    raise Exception.Create('Could not set option on IPv4 socket.');

  addrv4.sin_family := AF_INET;
  addrv4.sin_port := htons(port);
//  addrv4.sin_addr.s_addr := system_info.bind_ip;
  addrv4.sin_addr.s_addr := INADDR_ANY;

  if (bind(fd, TSockaddr(addrv4), sizeof(addrv4)) = -1) then
    begin
{$IFDEF LINUX}
    __close(fd);
{$ELSE}
    closesocket(fd);
{$ENDIF}

    raise Exception.Create('Could not bind on IPv4 port ' + inttostr(port));
    end;

  rc := listen(fd, 15);

  if (rc > 0) then
    raise Exception.Create('Could not listen on IPv4 socket');
end;

// GSocket6
constructor GSocket6.Create;
begin 
  inherited Create(AF_INET6);
end;

constructor GSocket6.Create(fd : TSocket);
begin 
  inherited Create(AF_INET6, fd);
end;

procedure GSocket6.openPort(port : integer);
var
  rc : integer;
begin
  rc := 1;
    
  if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, @rc, sizeof(rc)) < 0) then
    raise Exception.Create('Could not set option on IPv6 socket.');

  addrv6.sin6_family := AF_INET6;
  addrv6.sin6_port := htons(port);

  move(addrv6, ssv6, sizeof(addrv6));

  addrv6p := @ssv6;

  if (bind(fd, addrv6p^, 128) = -1) then
    begin
{$IFDEF LINUX}
    __close(fd);
{$ELSE}
    closesocket(fd);
{$ENDIF}

    raise Exception.Create('Could not bind on IPv6 port ' + inttostr(port));
    end;

  rc := listen(fd, 15);

  if (rc > 0) then
    raise Exception.Create('Could not listen on IPv6 socket');
end;

initialization
{$IFDEF WIN32}
  ver := WINSOCK_VERSION;

  if (WSAStartup(ver, hWSAData) <> 0) then
    raise Exception.Create('Could not perform WSAStartup');
{$ENDIF}

finalization
{$IFDEF WIN32}
  WSACleanup();
{$ENDIF}

end.
