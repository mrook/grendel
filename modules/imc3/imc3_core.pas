{
	Delphi IMC3 Client - Core code and types
	
	Based on client code by Samson of Alsherok.
	
	$Id: imc3_core.pas,v 1.1 2003/10/01 14:55:19 ***REMOVED*** Exp $
}

unit imc3_core;

interface


uses
	Classes,
  dtypes,
	socket,
	imc3_chan,
	imc3_mud,
	imc3_packet;


const
	MAX_IPS = 8192 * 16;
	MAX_READ = 4096;


type
	GInterMud = class(TThread)
	private
		mud : GMud_I3;
		packet : GPacket_I3;
		sock : GSocket;
		connected : boolean;
		
		showDebug : boolean;

		outputBuffer : string;
	 	inputBuffer : array[0..MAX_IPS - 1] of char;
 		inputPointer : integer;
		
		procedure handleStartupReply(packet : GPacket_I3);
		procedure handleMudList(packet : GPacket_I3);
		procedure handleChanList(packet : GPacket_I3);
		procedure handlePacket(packet : GPacket_I3);

		procedure startup();
		
		procedure debug(msg : string);

		procedure writePacket(msg : string);
		
	published
		procedure sendPacket();
		procedure writeBuffer(msg : string);
		procedure writeHeader(identifier, originator_mudname, originator_username, target_mudname, target_username : string);
		
		procedure shutdown();
		
		constructor Create(showDebug : boolean = false);
		
		procedure Execute(); override;
	end;


implementation

uses
	WinSock2,
	SysUtils,
	console,
	util;


constructor GInterMud.Create(showDebug : boolean = false);
begin
	inherited Create(false);
	
	connected := false;
	
	Self.showDebug := showDebug;
	
	mud := GMud_I3.Create();
	mud.readConfig();
	
	sock := GSocket4.Create();
end;

// bool I3_write_packet( char *msg )
procedure GInterMud.writePacket(msg : string);
var
	oldsize, size,  x : integer;
	s : array of char;
begin
	size := length(msg);
	oldsize := size;
	
	SetLength(s, size + 8);
	
	s[3] := chr(size mod 256);
	size := size shr 8;
	s[2] := chr(size mod 256);
	size := size shr 8;
	s[1] := chr(size mod 256);
	size := size shr 8;
	s[0] := chr(size mod 256);
	
	StrPCopy(@s[4], msg);

  { Scan for \r used in Diku client packets and change to NULL }
  for x := 4 to oldsize + 4 do
    begin
  	if (s[x] = #13) then
  		begin
  		s[x] := #0;
  		end;
    end;
	
	x := sock.send(s[0], oldsize + 4);
	
	if (x <= 0) then
		raise Exception.Create('Write error on socket');
	
	debug('Sent packet: ' + msg);
	
	outputBuffer := '';
end;

// void I3_send_packet( void )
procedure GInterMud.sendPacket();
begin
	writePacket(outputBuffer);
end;

// void I3_write_buffer( const char *msg )
procedure GInterMud.writeBuffer(msg : string);
begin
	outputBuffer := outputBuffer + msg;
end;

// void I3_write_header( char *identifier, char *originator_mudname, char *originator_username, char *target_mudname, char *target_username ) 
procedure GInterMud.writeHeader(identifier, originator_mudname, originator_username, target_mudname, target_username : string);
begin
	writeBuffer('({"');
	writeBuffer(identifier);
	writeBuffer('",5,');

	if (originator_mudname <> '') then
		begin
		writeBuffer('"');
		writeBuffer(originator_mudname);
		writeBuffer('",');
		end
	else
		begin
		writeBuffer('0,');
		end;
	
	if (originator_username <> '') then
		begin
		writeBuffer('"');
		writeBuffer(originator_username);
		writeBuffer('",');
		end
	else
		begin
		writeBuffer('0,');
		end;

	if (target_mudname <> '') then
		begin
		writeBuffer('"');
		writeBuffer(target_mudname);
		writeBuffer('",');
		end
	else
		begin
		writeBuffer('0,');
		end;

	if (target_username <> '') then
		begin
		writeBuffer('"');
		writeBuffer(target_username);
		writeBuffer('",');
		end
	else
		begin
		writeBuffer('0,');
		end;
end;

// void I3_startup_packet( void )
procedure GInterMud.startup();
begin
(*   char s[SMST];

   if( !I3_is_connected() )
	return;

   I3_output_pointer = 4;
   I3_output_buffer[0] = '\0';

   i3log( "Sending startup_packet to %s", this_mud->routerName ); *)

  writeHeader('startup-req-3', mud.name, '', mud.preferredRouter.routerName, '');

  writeBuffer(IntToStr(mud.password));
  writeBuffer(',');
  writeBuffer(IntToStr(mud.mudlist_id));
  writeBuffer(',');
  writeBuffer(IntToStr(mud.chanlist_id));
  writeBuffer(',');
  writeBuffer(IntToStr(mud.player_port));
  writeBuffer(',0,0,"');

	writeBuffer(mud.mudlib);
  writeBuffer('","');
	writeBuffer(mud.base_mudlib);
  writeBuffer('","');
  writeBuffer(mud.driver);
  writeBuffer('","');
  writeBuffer(mud.mud_type);
  writeBuffer('","');
  writeBuffer(mud.open_status);
  writeBuffer('","');
  writeBuffer(mud.admin_email);
  writeBuffer('",');

  { Begin first mapping set }
  writeBuffer('([');

  if (mud.emoteto) then
		writeBuffer('"emoteto":1,');
  if (mud.news) then
		writeBuffer('"news":1,');
  if (mud.ucache) then
		writeBuffer('"ucache":1,');
  if (mud.auth) then
		writeBuffer('"auth":1,');
  if (mud.locate) then
		writeBuffer('"locate":1,');
  if (mud.finger) then
		writeBuffer('"finger":1,');
  if (mud.channel) then
		writeBuffer('"channel":1,');
  if (mud.who) then
		writeBuffer('"who":1,');
  if (mud.tell) then
		writeBuffer('"tell":1,');
  if (mud.beep) then
		writeBuffer('"beep":1,');
  if (mud.mail) then
		writeBuffer('"mail":1,');
  if (mud.mfile) then
		writeBuffer('"file":1,');
  if (mud.http > 0) then
  	writeBuffer('"http":' + IntToStr(mud.http) + ',');
  if (mud.smtp > 0) then
  	writeBuffer('"smtp":' + IntToStr(mud.smtp) + ',');
  if (mud.pop3 > 0) then
  	writeBuffer('"pop3":' + IntToStr(mud.pop3) + ',');
  if (mud.ftp > 0) then
  	writeBuffer('"ftp":' + IntToStr(mud.ftp) + ',');
  if (mud.nntp > 0) then
  	writeBuffer('"nntp":' + IntToStr(mud.nntp) + ',');
  if (mud.rcp > 0) then
  	writeBuffer('"rcp":' + IntToStr(mud.rcp) + ',');
  if (mud.amrcp > 0) then
  	writeBuffer('"amrcp":' + IntToStr(mud.amrcp) + ',');

  writeBuffer(']),([');

  { END first set of "mappings", start of second set }
  if (mud.web <> '') then
  	writeBuffer('"url":"' + mud.web + '",');

  writeBuffer('"time":"' + DateTimeToStr(Now) + '",');
  writeBuffer(']),})' + #13);

	sendPacket();
end;

procedure GInterMud.handleStartupReply(packet : GPacket_I3);
begin
	debug('Accepted by router, new password is ' + GString(packet.fields[7]).value);
end;

procedure GInterMud.handleMudList(packet : GPacket_I3);
var
	mud : GMud_I3;
  i, j : integer;
  child, list : TList;
  name : string;
begin
  list := TList(packet.fields[7]);
	debug(IntToStr(list.count div 2) + ' muds in packet');

  i := 0;

  while (i < list.count) do
  	begin
    name := GString(list[i]).value;

    mud := GMud_I3(mudList.get(name));

    if (mud = nil) then
    	begin
      debug('New mud: ' + name);

      mud := GMud_I3.Create();
      mud.name := name;
	    mudList.put(mud.name, mud);
      end
    else
      debug('Updating mud: ' + name);

    if (GString(list[i + 1]).value = '0') then
    	begin
      debug(name + ' is down');
      mud.status := 0;
      end
    else
    	begin
	    child := TList(list[i + 1]);
	    
	    if (child.count < 13) then
	    	debug('Illegal mud: ' + name)
	    else
	    	begin
				mud.status := StrToIntDef(GString(child[0]).value, 0);
				mud.ipaddress := GString(child[1]).value;
				mud.player_port := StrToIntDef(GString(child[2]).value, 0);
				mud.imud_tcp_port := StrToIntDef(GString(child[3]).value, 0);
				mud.imud_udp_port := StrToIntDef(GString(child[4]).value, 0);
				mud.mudlib := GString(child[5]).value;
				mud.base_mudlib := GString(child[6]).value;
				mud.driver := GString(child[7]).value;
				mud.mud_type := GString(child[8]).value;
				mud.open_status := GString(child[9]).value;
				mud.admin_email := GString(child[10]).value;

				child := TList(child[11]);
				j := 0;

				while (j < child.count) do
					begin
					if (GString(child[j]).value = 'tell') then
						mud.tell := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'beep') then
						mud.beep := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'emoteto') then
						mud.emoteto := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'who') then
						mud.who := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'finger') then
						mud.finger := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'locate') then
						mud.locate := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'channel') then
						mud.channel := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'news') then
						mud.news := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'mail') then
						mud.mail := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'file') then
						mud.mfile := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'auth') then
						mud.auth := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'ucache') then
						mud.ucache := (StrToIntDef(GString(child[j + 1]).value, 0) = 1)
					else
					if (GString(child[j]).value = 'http') then
						mud.http := StrToIntDef(GString(child[j + 1]).value, 0)
					else
					if (GString(child[j]).value = 'ftp') then
						mud.ftp := StrToIntDef(GString(child[j + 1]).value, 0)
					else
					if (GString(child[j]).value = 'nntp') then
						mud.nntp := StrToIntDef(GString(child[j + 1]).value, 0)
					else
					if (GString(child[j]).value = 'smtp') then
						mud.smtp := StrToIntDef(GString(child[j + 1]).value, 0)
					else
					if (GString(child[j]).value = 'rcp') then
						mud.rcp := StrToIntDef(GString(child[j + 1]).value, 0)
					else
					if (GString(child[j]).value = 'amrcp') then
						mud.amrcp := StrToIntDef(GString(child[j + 1]).value, 0);

					inc(j, 2);
					end;
				end;
      end;

    inc(i, 2);
	  end;
end;

procedure GInterMud.handleChanList(packet : GPacket_I3);
var
	chan : GChannel_I3;
  name : string;
  i : integer;
  child, list : TList;
begin
  list := TList(packet.fields[7]);
  i := 0;

	while (i < list.count) do
  	begin
    name := GString(list[i]).value;

    chan := GChannel_I3(chanList.get(name));

    if (chan = nil) then
    	begin
      chan := GChannel_I3.Create();
      chan.I3_name := name;
      chanList.put(chan.I3_name, chan);

      debug('New channel: ' + name);
      end
    else
    	debug('Updating channel: ' + name);

    child := TList(list[i + 1]);

    chan.host_mud := GString(child[0]).value;
    chan.status := StrToIntDef(GString(child[1]).value, 0);

    inc(i, 2);
    end;
end;

procedure GInterMud.handlePacket(packet : GPacket_I3);
begin
	if (packet.packet_type = 'startup-reply') then
    handleStartupReply(packet)
  else
	if (packet.packet_type = 'mudlist') then
    handleMudList(packet)
  else
  if (packet.packet_type = 'chanlist-reply') then
  	handleChanList(packet)
end;

procedure GInterMud.shutdown();
begin
	saveMudList();
	saveChanList();
	
  writeHeader('shutdown', mud.name, '', mud.preferredRouter.routerName, '');
  writeBuffer('0');
	writeBuffer(',})' + #13);  

	sendPacket();
end;

procedure GInterMud.Execute();
var
 	ret : integer;
	size : integer;
	msg : string;
 	buf : array[0..MAX_READ - 1] of char;
begin
	inputPointer := 0;
	
	while (not Terminated) do
		begin
		try
			if (not connected) then
				begin
				if (sock.connect(mud.preferredRouter.routerIP, mud.preferredRouter.routerPort)) then
					begin
					debug('Connected to ' + mud.preferredRouter.routerIP);

					connected := true;

					startup();
					end
				else
					begin
					debug('Could not connect to ' + mud.preferredRouter.routerIP);
					
					// Wait 5 minutes
					Sleep(5 * 60 * 1000);
					end;
				end
			else
				begin
				if (sock.canRead()) then
					begin
					ret := sock.read(buf, MAX_READ);

					if (ret > 0) then
						begin
						if (inputPointer + ret > MAX_IPS) then
							debug('Buffer is growing beyond ' + IntToStr(MAX_IPS));
							
						//debug('Read ' + IntToStr(ret) + ' bytes');

						StrMove(@inputBuffer[inputPointer], @buf[0], ret);
						inc(inputPointer, ret);
						end;
					end;

				Sleep(10);

				if (inputPointer > 0) then
					begin
					StrMove(@size, @inputBuffer[0], 4);

					size := ntohl(size);

					debug('Need ' + IntToStr(size + 4) + ' bytes, currently ' + IntToStr(inputPointer) + ' in buffer');
				
					SetLength(msg, inputPointer);
					StrMove(@msg[1], @inputBuffer[4], inputPointer);
					
					for ret := 1 to inputPointer do
						if (msg[ret] = #0) then
							msg[ret] := ' ';
					
					//debug('Packet received so far: ' + msg);
						
					if (inputPointer >= size + 4) then
						begin
						SetLength(msg, size);

						for ret := 4 to size + 4 do
							if (inputBuffer[ret] = #10) then
								inputBuffer[ret] := ' ';

						StrMove(@msg[1], @inputBuffer[4], size);

						packet := parsePacket(msg);

						debug('-------- (size: ' + IntToStr(size + 4) + ')');
						debug(msg);
						debug(#13#10);
						debug(packet.toString());
						debug(#13#10);

						debug('Got packet: ' + packet.packet_type); 

						handlePacket(packet);

						debug('Removing head ' + IntToStr(size + 4) + ' bytes from buffer'); 
					
						StrMove(@inputBuffer[0], @inputBuffer[size+4], inputPointer - (size + 4));
						dec(inputPointer, size + 4);
						debug('Pointer at ' + IntToStr(inputPointer));
						end;
					end;
				end;
			except
				on E : Exception do debug(E.Message);
			end;
		end;

	sock.disconnect();
	sock.Free();
end;

procedure GInterMud.debug(msg : string);
begin
	if (showDebug) then
		writeConsole(msg);
end;


end.