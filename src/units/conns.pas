{
	Summary:
  		Connection manager
  	
	## $Id: conns.pas,v 1.24 2004/05/18 12:07:08 ***REMOVED*** Exp $
}

unit conns;

interface


uses
	ZLib,
{$IFDEF WIN32}
	Winsock2,
	Windows,
	JclDebug,
{$ENDIF}
{$IFDEF LINUX}
	Libc,
{$ENDIF}
	Classes,
	SysUtils,
	dtypes,
	socket;
	

type
	GConnectionEvent = procedure() of object;

	{$IFDEF WIN32}
	GConnection = class(TJclDebugThread)
	{$ELSE}
	GConnection = class(TThread)
	{$ENDIF}
	protected
		_socket : GSocket;
		_idle : integer;
		input_buf : string;
		comm_buf : string;
		last_line : string;
		sendbuffer : string;

		empty_busy : boolean;
		compress : boolean; { are we using MCCP v2? }
  
		strm: TZStreamRec;

		_lastupdate : TDateTime;
      
		{ Called when GConnection.Execute() starts }
		FOnOpen : GConnectionEvent;
		{ Called when GConnection.Execute() terminates }
		FOnClose : GConnectionEvent;
		{ Called for every iteration in GConnection.Execute() }
		FOnTick : GConnectionEvent;
		{ Called when GConnection has one or more lines of input waiting }
		FOnInput : GConnectionEvent;
		{ Called when GConnection has sent one or more lines of output }
		FOnOutput : GConnectionEvent;
      
	protected
		procedure Execute(); override;

		procedure sendIAC(option : byte; const params : array of byte);
		
		procedure processIAC();

		procedure send(s : PChar; len : integer); overload;

	public
		procedure send(const s : string); overload;
		procedure read();
		procedure readBuffer();

		procedure emptyBuffer();
		procedure writeBuffer(const txt : string; in_command : boolean = false);

		constructor Create(socket : GSocket);
		destructor Destroy; override;
      
		procedure disableCompression();
		procedure enableCompression();
		procedure negotiateCompression();
      
	published
		property socket : GSocket read _socket;

		property idle : integer read _idle;
		property last_update : TDateTime read _lastupdate;

		property OnOpen : GConnectionEvent read FOnOpen write FOnOpen;
		property OnClose : GConnectionEvent read FOnClose write FOnClose;
		property OnTick : GConnectionEvent read FOnTick write FOnTick;
		property OnInput : GConnectionEvent read FOnInput write FOnInput;
		property OnOutput : GConnectionEvent read FOnOutput write FOnOutput;

		property useCompress : boolean read compress;
	end;


var
	connection_list : GDLinkedList;


procedure flushConnections();
procedure terminateAndWaitConnections();


implementation


uses
	chars,
	constants,
	console,
	player,
	debug;


const
	IAC_COMPRESS = 85;		// MCCP v1
	IAC_COMPRESS2 = 86;		// MCCP v2
	IAC_SE = 240;
	IAC_SB = 250;
	IAC_WILL = 251;
	IAC_WONT = 252;
	IAC_DO = 253;
	IAC_DONT = 254;
	IAC_IAC = 255;


{ GConnection constructor }
constructor GConnection.Create(socket : GSocket);
begin
	inherited Create(true);
	
	FreeOnTerminate := true;

	connection_list.add(Self);

	_socket := socket;

	_idle := 0;

	comm_buf := '';
	input_buf := '';
	last_line := '';
	sendbuffer := '';
  
	compress := false;
end;

{ GConnection destructor }
destructor GConnection.Destroy();
begin
	connection_list.remove(Self);
	_socket.Free();

	inherited Destroy();
end;

{ GConnection main loop }
procedure GConnection.Execute();
begin 
	writeConsole('(' + IntToStr(_socket.getDescriptor) + ') New connection (' + _socket.hostString + ')');
   
	try
		negotiateCompression();
		read();
		
		if (Assigned(FOnOpen)) then
  			FOnOpen();
  			
		while (not Terminated) do
			begin
			_lastupdate := Now();
			
			sleep(50);

			if (Assigned(FOnTick)) then
  				FOnTick();

			if (not Terminated) then
				read();

			if (not Terminated) then
				readBuffer();

			if (Assigned(FOnInput)) and (length(comm_buf) > 0) then
				FOnInput(); 
		end;
  	except
		on E : Exception do
			begin
          	send('Your previous command possibly triggered an illegal instruction.'#13#10);
          	send('To prevent data loss you have been disconnected.'#13#10);

			Terminate();
		
			{$IFDEF WIN32}
			HandleException();
			{$ELSE}
			reportException(E, 'conns.pas:GConnection.Execute()');
			{$ENDIF}
			end;
	end;
	
	if (Assigned(FOnClose)) then
		FOnClose();
	
	writeConsole('(' + IntToStr(_socket.getDescriptor) + ') Connection closed');
end;

procedure GConnection.enableCompression();
begin
	FillChar(strm, sizeof(strm), 0);
	strm.zalloc := zlibAllocMem;
	strm.zfree := zlibFreeMem;

	deflateInit_(strm, Z_DEFAULT_COMPRESSION, zlib_version, sizeof(strm));

	sendIAC(IAC_SB, [IAC_COMPRESS2]);
	sendIAC(IAC_SE, []);
	
	compress := true;
end;

procedure GConnection.disableCompression();
var
	compress_size : integer;
	compress_buf : array[0..4095] of char;
begin
	if (compress) then
  	begin
		compress := false;
		strm.next_in := nil;
		strm.avail_in := 0;
		strm.next_out := compress_buf;
		strm.avail_out := 4096;

		deflate(strm, Z_FINISH);

		compress_size := 4096 - strm.avail_out;

		_socket.send(compress_buf, compress_size);

		deflateEnd(strm);
	  end;
end;

procedure GConnection.negotiateCompression();
begin
	sendIAC(IAC_WILL, [IAC_COMPRESS2]);
end;

procedure GConnection.send(s : PChar; len : integer);
var
	compress_size : integer;
	compress_buf : array[0..4095] of char;
begin
	if (Terminated) then
		exit;
		
	try
		while (not Terminated) and (not _socket.canWrite()) do;
		
		if (compress) then
			begin
			strm.next_in := s;
			strm.avail_in := len;
			strm.next_out := compress_buf;
			strm.avail_out := 4096;

			deflate(strm, Z_SYNC_FLUSH);

			compress_size := 4096 - strm.avail_out;

			_socket.send(compress_buf, compress_size);
  		end
  	else
			_socket.send(s^, len);
	except
		Terminate();
	end;
end;

procedure GConnection.send(const s : string);
begin
	send(@s[1], length(s));
end;

procedure GConnection.read();
var
	read : integer;
	buf : array[0..MAX_RECEIVE-1] of char;
begin
	if (length(comm_buf) > 0) then
		exit;

	try
		if (not _socket.canRead()) then
			exit;
	except
		on E : Exception do
			begin
			Terminate();
			exit;
			end;
	end;
  
	_idle := 0;

	while (not Terminated) do
		begin
		if (not _socket.canRead()) then
			break;

		read := recv(_socket.getDescriptor, buf, MAX_RECEIVE - 10, 0);

		if (read > 0) then
			begin
			buf[read] := #0;
			input_buf := input_buf + buf;

			processIAC();
			end
		else
		if (read = 0) then
			begin
			Terminate();
			break;
			end
		else
		if (read = SOCKET_ERROR) then
			begin
			{$IFDEF WIN32}
			if (WSAGetLastError() = WSAEWOULDBLOCK) then
				break
			else
				begin
				Terminate();
				break;
				end;
			{$ELSE}
			break;
			{$ENDIF}      
			end;
		end;
end;

procedure GConnection.sendIAC(option : byte; const params : array of byte);
var
	buf : array[0..255] of char;
	i : integer;
begin
	buf[0] := chr(IAC_IAC);
	buf[1] := chr(option);
	
	for i := 0 to length(params) - 1 do
		buf[2 + i] := chr(params[i]);
  	
	send(buf, 2 + length(params));
end;

procedure GConnection.processIAC();
var 
	i : integer;
	iac : boolean;
	new_buf : string;
begin
	iac := false;
	new_buf := '';
	i := 1;
	
	while (i <= length(input_buf)) do
		begin
    if (iac) then
    	begin
    	case byte(input_buf[i]) of
    		IAC_WILL: 	begin
										inc(i);
    								//writeConsole('(' + IntToStr(socket.getDescriptor) + ') IAC WILL ' + IntToStr(byte(input_buf[i])));
			    					end;
    		IAC_WONT: 	begin
										inc(i);
    								//writeConsole('(' + IntToStr(socket.getDescriptor) + ') IAC WON''T ' + IntToStr(byte(input_buf[i])));
										end;
    		IAC_DO: 		begin
										inc(i);
    								case byte(input_buf[i]) of
    									IAC_COMPRESS2:	begin
    																	writeConsole('(' + IntToStr(_socket.getDescriptor) + ') Client has MCCPv2');
    																	enableCompression();
    																	end;
    								end;
    								
    								//writeConsole('(' + IntToStr(socket.getDescriptor) + ') IAC DO ' + IntToStr(byte(input_buf[i])));
										end;
    		IAC_DONT: 	begin
										inc(i);
										case byte(input_buf[i]) of
											IAC_COMPRESS2:	begin
    																	writeConsole('(' + IntToStr(_socket.getDescriptor) + ') Client has disabled MCCPv2');
    																	disableCompression();
    																	end;
    								end;
    								//writeConsole('(' + IntToStr(socket.getDescriptor) + ') IAC DON''T ' + IntToStr(byte(input_buf[i])));
										end;
			else
	    	//writeConsole('(' + IntToStr(socket.getDescriptor) + ') IAC ' + IntToStr(byte(input_buf[i])));
    	end;     	
    	
    	iac := false;
    	end    	
    else
    if (byte(input_buf[i]) = IAC_IAC) then		// IAC
    	begin
    	iac := true;
    	end
    else
    	new_buf := new_buf + input_buf[i];
    	
   	inc(i);
    end;
    
  input_buf := new_buf;
end;

procedure GConnection.readBuffer();
var 
	i : integer;
begin
  if (length(comm_buf) <> 0) or ((pos(#10, input_buf) = 0) and (pos(#13, input_buf) = 0))  then
    exit;

  i := 1;

  while (i <= length(input_buf)) and (input_buf[i] <> #13) and (input_buf[i] <> #10) do
    begin
    if ((input_buf[i] = #8) or (input_buf[i] = #127)) then
      delete(comm_buf, length(comm_buf), 1)
    else
    //if (byte(input_buf[i]) > 31) and (byte(input_buf[i]) < 127) then
      begin
      comm_buf := comm_buf + input_buf[i];
      end;

    inc(i);
    end;

  while (i <= length(input_buf)) and ((input_buf[i] = #13) or (input_buf[i] = #10)) do
    begin
    comm_buf := comm_buf + input_buf[i];

    inc(i);
    end;

  if (comm_buf = '!'#13#10) then
    comm_buf := last_line
  else
    last_line := comm_buf;

  delete(input_buf, 1, i - 1);
end;

procedure GConnection.emptyBuffer();
begin
  if (empty_busy) then
    exit;

  empty_busy := true;

  if (length(sendbuffer) > 0) then
    begin
    send(sendbuffer);
    
    if (Assigned(FOnOutput)) then
    	FOnOutput();

    sendbuffer := '';
    end;

  empty_busy := false;
end;

procedure GConnection.writeBuffer(const txt : string; in_command : boolean = false);
begin
  if ((length(sendbuffer) + length(txt)) > 2048) then
    begin
    send(sendbuffer);
    sendbuffer := '';
    end;

  if (not in_command) and (length(sendbuffer) = 0) then
    sendbuffer := sendbuffer + #13#10;

  sendbuffer := sendbuffer + txt;
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

procedure terminateAndWaitConnections();
var
	conn : GPlayerConnection;
	iterator : GIterator;
begin
	iterator := connection_list.iterator();

	while (iterator.hasNext()) do
		begin
		conn := GPlayerConnection(iterator.next());

		conn.Terminate();
		end;

	iterator.Free();

	// Wait for connection_list to clean itself
	while (connection_list.size() > 0) do
		begin
		Sleep(25);
		end;
end;

initialization
	connection_list := GDLinkedList.Create();
	connection_list.ownsObjects := false;

finalization
	connection_list.clear();
	connection_list.Free();

end.
