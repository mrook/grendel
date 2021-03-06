{
	Delphi IMC3 Client - Core code and types
	
	Based on client code by Samson of Alsherok.
	
	$Id: imc3_core.pas,v 1.4 2004/03/14 11:54:22 ***REMOVED*** Exp $
}

unit imc3_core;

interface


uses
	Classes,
	dtypes,
	socket,
	imc3_chan,
	imc3_mud,
	imc3_packet,
	imc3_const;


type
	GInterMud = class(TThread)
	private
		this_mud : GMud_I3;
		router : GRouter_I3;
		packet : GPacket_I3;
		socket : GSocket;
		connected : boolean;
		
		debugLevel : integer;
		
		reconattempts : integer;
		_wait : integer;

		outputBuffer : string;
	 	inputBuffer : array[0..MAX_IPS - 1] of char;
 		inputPointer : integer;
		
		procedure handleError(packet : GPacket_I3);
		procedure handleStartupReply(packet : GPacket_I3);
		procedure handleMudList(packet : GPacket_I3);
		procedure handleChanList(packet : GPacket_I3);
		procedure handleChannelMessage(packet : GPacket_I3);
		procedure handleChannelEmote(packet : GPacket_I3);
		procedure handleLocateReply(packet : GPacket_I3);
		procedure handleLocateRequest(packet : GPacket_I3);
		procedure handleTell(packet : GPacket_I3);
		procedure handleBeep(packet : GPacket_I3);
		procedure handleWhoReq(packet : GPacket_I3);
		procedure handleWhoReply(packet : GPacket_I3);
		procedure handleFingerReq(packet : GPacket_I3);
		procedure handleFingerReply(packet : GPacket_I3);
		procedure handlePacket(packet : GPacket_I3);

		procedure startup();
		
		procedure debug(msg : string; level : integer = 1);

		procedure writePacket(msg : string);
		
	published
		procedure connect();
		procedure disconnect();
		
		procedure sendPacket();
		
		procedure writeBuffer(msg : string);
		procedure writeHeader(identifier, originator_mudname, originator_username, target_mudname, target_username : string);
		
		procedure sendError(mud, user, code, msg : string);
		procedure sendChannelListen(user : string; channel : GChannel_I3; lconnect : boolean);
		procedure sendChannelMessage(channel : GChannel_I3; name, msg : string);
		procedure sendChannelEmote(channel : GChannel_I3; name, msg : string);
		procedure sendChannelTarget(channel : GChannel_I3; name, tmud, tuser, msg_o, msg_t, tvis : string);
		procedure sendLocateRequest(originator, user : string);
		procedure sendTell(from_user, to_user : string; mud : GMud_I3; msg : string);
		procedure sendBeep(from_user, to_user : string; mud : GMud_I3);
		procedure sendWhoReq(from_user : string; mud : GMud_I3);
		procedure sendFingerReq(from_user, to_user : string; mud : GMud_I3);
		
		procedure shutdown();
		
		constructor Create(debugLevel : integer = 0);
		destructor Destroy; override;
		
		procedure setDebugLevel(debugLevel : integer = 0);
		
		procedure Execute(); override;
		
		property connectedRouter : GRouter_I3 read router;
		property isConnected : boolean read connected;
	end;


implementation

uses
{$IFDEF WIN32}
	WinSock2,
{$ENDIF}
{$IFDEF LINUX}
	Libc,
{$ENDIF}
	SysUtils,
	FastStrings,
	Channels,
	imc3_util,
	constants,
	console,
	chars,
	player,
	conns,
	mudsystem,
	util;


constructor GInterMud.Create(debugLevel : integer = 0);
begin
	inherited Create(false);
	
	connected := false;
	
	Self.debugLevel := debugLevel;
	
	this_mud := GMud_I3.Create();
	this_mud.readConfig();
	
	socket := GSocket4.Create();
	
	reconattempts := 0;
	_wait := 0;
end;

destructor GInterMud.Destroy();
begin
	socket.Free();
	this_mud.Free();
	
	inherited Destroy();
end;

procedure GInterMud.connect();
begin
	if (isConnected) then
		exit;
		
	_wait := 2;
end;

procedure GInterMud.disconnect();
begin
	if (not isConnected) then
		exit;
	
	debug('Disconnecting from server');
		
	connected := false;
	shutdown();
	socket.disconnect();
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
	
	x := socket.send(s[0], oldsize + 4);
	
	if (x <= 0) then
		raise Exception.Create('Write error on socket');
	
	debug('Sent packet: ' + msg, 2);
	
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

  writeHeader('startup-req-3', this_mud.name, '', router.name, '');

  writeBuffer(IntToStr(this_mud.password));
  writeBuffer(',');
  writeBuffer(IntToStr(this_mud.mudlist_id));
  writeBuffer(',');
  writeBuffer(IntToStr(this_mud.chanlist_id));
  writeBuffer(',');
  writeBuffer(IntToStr(this_mud.player_port));
  writeBuffer(',0,0,"');

	writeBuffer(this_mud.mudlib);
  writeBuffer('","');
	writeBuffer(this_mud.base_mudlib);
  writeBuffer('","');
  writeBuffer(this_mud.driver);
  writeBuffer('","');
  writeBuffer(this_mud.mud_type);
  writeBuffer('","');
  writeBuffer(this_mud.open_status);
  writeBuffer('","');
  writeBuffer(this_mud.admin_email);
  writeBuffer('",');

  { Begin first mapping set }
  writeBuffer('([');

  if (this_mud.emoteto) then
		writeBuffer('"emoteto":1,');
  if (this_mud.news) then
		writeBuffer('"news":1,');
  if (this_mud.ucache) then
		writeBuffer('"ucache":1,');
  if (this_mud.auth) then
		writeBuffer('"auth":1,');
  if (this_mud.locate) then
		writeBuffer('"locate":1,');
  if (this_mud.finger) then
		writeBuffer('"finger":1,');
  if (this_mud.channel) then
		writeBuffer('"channel":1,');
  if (this_mud.who) then
		writeBuffer('"who":1,');
  if (this_mud.tell) then
		writeBuffer('"tell":1,');
  if (this_mud.beep) then
		writeBuffer('"beep":1,');
  if (this_mud.mail) then
		writeBuffer('"mail":1,');
  if (this_mud.mfile) then
		writeBuffer('"file":1,');
  if (this_mud.http > 0) then
  	writeBuffer('"http":' + IntToStr(this_mud.http) + ',');
  if (this_mud.smtp > 0) then
  	writeBuffer('"smtp":' + IntToStr(this_mud.smtp) + ',');
  if (this_mud.pop3 > 0) then
  	writeBuffer('"pop3":' + IntToStr(this_mud.pop3) + ',');
  if (this_mud.ftp > 0) then
  	writeBuffer('"ftp":' + IntToStr(this_mud.ftp) + ',');
  if (this_mud.nntp > 0) then
  	writeBuffer('"nntp":' + IntToStr(this_mud.nntp) + ',');
  if (this_mud.rcp > 0) then
  	writeBuffer('"rcp":' + IntToStr(this_mud.rcp) + ',');
  if (this_mud.amrcp > 0) then
  	writeBuffer('"amrcp":' + IntToStr(this_mud.amrcp) + ',');

  writeBuffer(']),([');

  { END first set of "mappings", start of second set }
  if (this_mud.web <> '') then
  	writeBuffer('"url":"' + this_mud.web + '",');

  writeBuffer('"time":"' + DateTimeToStr(Now) + '",');
  writeBuffer(']),})' + #13);

	sendPacket();
end;

procedure GInterMud.handleError(packet : GPacket_I3);
var
	code, msg, error : string;
	pl : GPlayer;
begin
	code := GString(packet.fields[6]).value;
	msg := GString(packet.fields[7]).value;
	
	pl := GPlayer(findPlayerWorldEx(nil, packet.target_username));
	
	error := Format('Error: from %s to %s@%s: %s (%s)', [packet.originator_mudname, packet.target_username, packet.target_mudname, msg, code]);
	
 	debug(error);

	if (pl <> nil) then
		pl.sendBuffer(error + #13#10);
end;

procedure GInterMud.handleStartupReply(packet : GPacket_I3);
begin
	debug('Accepted by router', 1);
end;

procedure GInterMud.handleMudList(packet : GPacket_I3);
var
	mud : GMud_I3;
  i, j : integer;
  child, list : TList;
  name : string;
begin
  list := TList(packet.fields[7]);
	debug(IntToStr(list.count div 2) + ' muds in packet', 2);

  i := 0;

  while (i < list.count) do
  	begin
    name := GString(list[i]).value;

    mud := GMud_I3(mudList.get(name));

    if (mud = nil) then
    	begin
      debug('New mud: ' + name, 2);

      mud := GMud_I3.Create();
      mud.name := name;
	    mudList.put(mud.name, mud);
      end
    else
      debug('Updating mud: ' + name, 2);

    if (GString(list[i + 1]).value = '0') then
    	begin
      debug(name + ' is down', 2);
      mud.status := 0;
      end
    else
    	begin
	    child := TList(list[i + 1]);
	    
	    if (child.count < 13) then
	    	debug('Illegal mud: ' + name, 1)
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

      debug('New channel: ' + name, 2);
      end
    else
    	debug('Updating channel: ' + name, 2);

    child := TList(list[i + 1]);

    chan.host_mud := GString(child[0]).value;
    chan.status := StrToIntDef(GString(child[1]).value, 0);

    inc(i, 2);
    end;
end;

procedure GInterMud.handleChannelMessage(packet : GPacket_I3);
var
	channel_name, visname, message, text : string;
	channel : GChannel_I3;
begin
	channel_name := GString(packet.fields[6]).value;
	visname := GString(packet.fields[7]).value;
	message := GString(packet.fields[8]).value;
	text := Format('[%s] %s@%s: %s$7', [channel_name, visname, packet.originator_mudname, message]);
	
	channel := GChannel_I3(chanList[channel_name]);
	
	if (channel <> nil) then
		channel.updateHistory(text);
	
	to_channel(nil, text, CHANNEL_ALL, AT_ECHO);
end;

procedure GInterMud.handleChannelEmote(packet : GPacket_I3);
var
	channel_name, visname, message, text : string;
	channel : GChannel_I3;
begin
	channel_name := GString(packet.fields[6]).value;
	visname := GString(packet.fields[7]).value;
	message := GString(packet.fields[8]).value;
	
	visname := Format('%s@%s', [visname, packet.originator_mudname]);
	
	message := FastReplace(message, '$N', visname);
	
	text := Format('[%s] %s$7', [channel_name, message]);
	
	channel := GChannel_I3(chanList[channel_name]);
	
	if (channel <> nil) then
		channel.updateHistory(text);
	
	to_channel(nil, text, CHANNEL_ALL, AT_ECHO);
end;

procedure GInterMud.handleLocateRequest(packet : GPacket_I3);
var
	username : string;
	pl : GCharacter;
begin
	username := GString(packet.fields[6]).value;
	
	if (existsPlayer(username)) then
		begin
		pl := findPlayerWorldEx(nil, username);
	
		writeHeader('locate-reply', this_mud.name, '', packet.originator_mudname, packet.originator_username);
		writeBuffer('"');
		writeBuffer(this_mud.name);
		writeBuffer('","');
		writeBuffer(pl.name);
		writeBuffer('",0,"');
		
		if (pl <> nil) then
			writeBuffer('Online')
		else
			writeBuffer('Offline');
		
		writeBuffer('",})'#13);
		
		sendPacket();
		end;
end;

procedure GInterMud.handleLocateReply(packet : GPacket_I3);
var
	mudname, visname, status : string;
	pl : GPlayer;
begin
	pl := GPlayer(findPlayerWorldEx(nil, packet.target_username));
	
	mudname := GString(packet.fields[6]).value;
	visname := GString(packet.fields[7]).value;
	status := GString(packet.fields[9]).value;
	
	if (pl = nil) then
		begin
		if (not existsPlayer(packet.target_username)) then
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'No such player.')
		else
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'That player is offline.');
			
		exit;
		end;
		
	pl.sendBuffer('Player "' + visname + '" was located on "' + mudname + '" (' + status + ').'#13#10);
end;

procedure GInterMud.handleTell(packet : GPacket_I3);
var
	visname, msg : string;
	pl : GPlayer;
begin
	pl := GPlayer(findPlayerWorldEx(nil, packet.target_username));
	
	visname := GString(packet.fields[6]).value;
	msg := GString(packet.fields[7]).value;

	if (pl = nil) then
		begin
		if (not existsPlayer(packet.target_username)) then
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'No such player.')
		else
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'That player is offline.');
			
		exit;
		end;
		
	if ((pl.fields['i3flag'] as GBitVector).isBitSet(I3_TELL)) then
		begin
		sendError(packet.originator_mudname, packet.originator_username, 'unk-user', pl.name + ' is not accepting tells.');
		exit;
		end;

	pl.sendBuffer(Format('%s@%s tells you: %s' + #13#10, [visname, packet.originator_mudname, msg]))
end;

procedure GInterMud.handleBeep(packet : GPacket_I3);
var
	visname : string;
	pl : GPlayer;
begin
	pl := GPlayer(findPlayerWorldEx(nil, packet.target_username));
	
	visname := GString(packet.fields[6]).value;

	if (pl = nil) then
		begin
		if (not existsPlayer(packet.target_username)) then
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'No such player.')
		else
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'That player is offline.');
			
		exit;
		end;
	
	if ((pl.fields['i3flag'] as GBitVector).isBitSet(I3_BEEP)) then
		begin
		sendError(packet.originator_mudname, packet.originator_username, 'unk-user', pl.name + ' is not accepting beeps.');
		exit;
		end;
	
	pl.sendBuffer(Format('%s@%s beeps you.'#7 + #13#10, [visname, packet.originator_mudname]))
end;

procedure GInterMud.handleWhoReq(packet : GPacket_I3);
var
	conn : GPlayerConnection;
	iterator : GIterator;
begin
	writeHeader('who-reply', this_mud.name, '', packet.originator_mudname, packet.originator_username);
	writeBuffer('({');
	
	iterator := connection_list.iterator();
	
	while (iterator.hasNext()) do
		begin
		conn := GPlayerConnection(iterator.next());
		
		if (conn.isPlaying()) and (not conn.ch.IS_INVIS) then
			writeBuffer('({"' + escape(conn.ch.name) + '",0,"",}),');
		end;
	
	iterator.Free();

	writeBuffer('}),})'#13);
	sendPacket();	
end;

procedure GInterMud.handleWhoReply(packet : GPacket_I3);
var
	pl : GPlayer;
	list, child : TList;
	i : integer;
	name, title : string;
begin
	pl := GPlayer(findPlayerWorldEx(nil, packet.target_username));
	
	if (pl = nil) then
		begin
		if (not existsPlayer(packet.target_username)) then
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'No such player.')
		else
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'That player is offline.');
			
		exit;
		end;
	
	list := TList(packet.fields[6]);
	i := 0;

	pl.sendBuffer('Who list from "' + packet.originator_mudname + '":'#13#10#13#10);

	while (i < list.count) do
		begin
		child := TList(list[i]);

		name := GString(child[0]).value;
		title := GString(child[2]).value;

		sendToPlayer(pl, Format('%s %s' + #13#10, [name, title]));

		inc(i);
		end;
end;

procedure GInterMud.handleFingerReq(packet : GPacket_I3);
var
	username : string;
	pl : GPlayer;
begin
	username := GString(packet.fields[6]).value;
	pl := GPlayer(findPlayerWorldEx(nil, username));
	
	if (pl = nil) then
		begin
		if (not existsPlayer(username)) then
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'No such player.')
		else
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'That player is offline.');
			
		exit;
		end;
		
	if (pl.IS_INVIS) then
		begin
		sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'That player is offline.');
		exit;
		end;

	if ((pl.fields['i3flag'] as GBitVector).isBitSet(I3_DENYFINGER)) or ((pl.fields['i3flag'] as GBitVector).isBitSet(I3_PRIVACY)) then
		begin
		sendError(packet.originator_mudname, packet.originator_username, 'unk-user', pl.name + ' is not accepting fingers.');
		exit;
		end;
		
	pl.sendBuffer(Format('%s@%s just requested your i3 finger information.'#13#10, [packet.originator_mudname, packet.originator_username]));

	writeHeader('finger-reply', this_mud.name, '', packet.originator_mudname, packet.originator_username);
	writeBuffer('"');
	writeBuffer(escape(pl.name));
	writeBuffer('","');
	writeBuffer(escape(pl.name + ' ' + pl.title));
	writeBuffer('","","');	

	// No email info in Grendel (yet)
	writeBuffer('Not supported');

	writeBuffer('","');
	writeBuffer('-1');
	writeBuffer('",');
	writeBuffer('-1');
	writeBuffer(',"');
	writeBuffer('[PRIVATE]');
	writeBuffer('","');

	if (pl.IS_IMMORT) then
		writeBuffer(imm_types[pl.level])
	else
		writeBuffer(pl.rank);

	writeBuffer('","Not supported",})'#13);

	sendPacket();
end;

procedure GInterMud.handleFingerReply(packet : GPacket_I3);
var
	pl : GPlayer;
	visname, title, realname, email, last, level, extra : string;
begin
	visname := GString(packet.fields[6]).value;
	title := GString(packet.fields[7]).value;
	realname := GString(packet.fields[8]).value;
	email := GString(packet.fields[9]).value;
	last := GString(packet.fields[10]).value;
	level := GString(packet.fields[13]).value;
	extra := GString(packet.fields[14]).value;
	
	pl := GPlayer(findPlayerWorldEx(nil, packet.target_username));

	
	if (pl = nil) then
		begin
		if (not existsPlayer(packet.target_username)) then
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'No such player.')
		else
			sendError(packet.originator_mudname, packet.originator_username, 'unk-user', 'That player is offline.');
			
		exit;
		end;
		
	sendToPlayer(pl, Format('I3 finger information for %s@%s:'#13#10#13#10, [visname, packet.originator_mudname]));
	sendToPlayer(pl, 'Title: ' + title + #13#10);
	sendToPlayer(pl, 'Real name: ' + realname + #13#10);
	sendToPlayer(pl, 'Level: ' + level + #13#10);
	sendToPlayer(pl, 'E-mail: ' + email + #13#10);
	sendToPlayer(pl, 'Extra info: ' + extra + #13#10);
	sendToPlayer(pl, 'Last on: ' + last + #13#10);
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
	else
	if (packet.packet_type = 'channel-m') then
  		handleChannelMessage(packet)
	else
	if (packet.packet_type = 'channel-e') then
  		handleChannelEmote(packet)
	else
	if (packet.packet_type = 'locate-req') then
  		handleLocateRequest(packet)
	else
	if (packet.packet_type = 'locate-reply') then
  		handleLocateReply(packet)
	else
	if (packet.packet_type = 'tell') then
  		handleTell(packet)
	else
	if (packet.packet_type = 'beep') then
  		handleBeep(packet)
	else
	if (packet.packet_type = 'who-req') then
  		handleWhoReq(packet)
	else
	if (packet.packet_type = 'who-reply') then
  		handleWhoReply(packet)
	else
	if (packet.packet_type = 'finger-req') then
  		handleFingerReq(packet)
	else
	if (packet.packet_type = 'finger-reply') then
  		handleFingerReply(packet)
	else
	if (packet.packet_type = 'error') then
  		handleError(packet)
	else
  		begin
	  	debug('unknown packet "' + packet.packet_type + '"', 0);
		debug(packet.toString(), 0);
	  	end;
end;

procedure GInterMud.shutdown();
begin
	saveMudList();
	saveChanList();
	
	writeHeader('shutdown', this_mud.name, '', router.name, '');
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
	Sleep(2500);
	inputPointer := 0;
	
	if (this_mud.name = 'Your Mud Name Here') then
		begin
		writeConsole('I3: Refusing to connect with default values. Please change ' + I3_CONFIG_FILE);
		Terminate();
		end;

	if (this_mud.preferredRouter = nil) then	
		begin
		writeConsole('I3: Impossible to connect to non-existing router');
		exit;
		end;

	router := this_mud.preferredRouter;
	
	if (this_mud.autoconnect) then
		connect();
	
	while (not Terminated) do
		begin
		if (_wait > 0) then
			dec(_wait);

		Sleep(100);

		try
			if (not connected) and (_wait = 1) then
				begin
				debug('Trying to connect to ' + router.name);
				if (socket.connect(router.ipaddress, router.port)) then
					begin
					writeConsole('I3: Connected to ' + router.ipaddress + ' port ' + IntToStr(router.port));

					connected := true;

					startup();
					end
				else
					begin
					writeConsole('I3: Could not connect to ' + router.ipaddress + ' port ' + IntToStr(router.port));
			        	inc(reconattempts);

					if (reconattempts <= 5) then
						_wait := 10
					else
					if (reconattempts <= 20) then
						_wait := 500
					else
						begin
						_wait := -2;	{ Abandon attempts - probably an ISP failure anyway if this happens :) }
						writeConsole('Abandoning attempts to reconnect to Intermud-3 router. Too many failures.');
	   					end;
					end;
				end
			else
			if (connected) then
				begin
				if (socket.canRead()) then
					begin
					ret := socket.read(buf, MAX_READ);

					if (ret > 0) then
						begin
						if (inputPointer + ret > MAX_IPS) then
							debug('Buffer is growing beyond ' + IntToStr(MAX_IPS), 0);
							
						//debug('Read ' + IntToStr(ret) + ' bytes');

						StrMove(@inputBuffer[inputPointer], @buf[0], ret);
						inc(inputPointer, ret);
						end;
					end;

				if (inputPointer > 0) then
					begin
					StrMove(@size, @inputBuffer[0], 4);

					size := ntohl(size);

					//debug('Need ' + IntToStr(size + 4) + ' bytes, currently ' + IntToStr(inputPointer) + ' in buffer');
				
					{ SetLength(msg, inputPointer);
					StrMove(@msg[1], @inputBuffer[4], inputPointer);
					
					for ret := 1 to inputPointer do
						if (msg[ret] = #0) then
							msg[ret] := ' ';
					
					//debug('Packet received so far: ' + msg); }
						
					if (inputPointer >= size + 4) then
						begin
						SetLength(msg, size);

						for ret := 4 to size + 4 do
							if (inputBuffer[ret] = #10) then
								inputBuffer[ret] := ' ';

						StrMove(@msg[1], @inputBuffer[4], size);

						packet := parsePacket(msg);

						debug(msg, 2);
						debug(packet.toString(), 2);

						debug('Got packet: ' + packet.packet_type, 1); 

						debug('Removing head ' + IntToStr(size + 4) + ' bytes from buffer', 2); 
					
						StrMove(@inputBuffer[0], @inputBuffer[size+4], inputPointer - (size + 4));
						dec(inputPointer, size + 4);
						debug('Pointer at ' + IntToStr(inputPointer), 2);

						handlePacket(packet);
						
						packet.Free();
						end;
					end;
				end;
			except
				on E : Exception do 
					begin
					debug(E.Message);
					connected := socket.isValid();
					
					if (not connected) then
						begin
						debug('Connection lost, waiting for reconnect');
						_wait := 500;
						end;
					end;
			end;
		end;
		
	if (connected) then
		disconnect();
end;

// void I3_send_error( char *mud, char *user, char *code, char *message ) 
procedure GInterMud.sendError(mud, user, code, msg : string);
begin
	writeHeader('error', this_mud.name, '', mud, user);
	writeBuffer('"');
	writeBuffer(code);
	writeBuffer('","');
	writeBuffer(msg);
	writeBuffer('",0,})'#13);
	sendPacket();
end;

// void I3_send_channel_message( I3_CHANNEL *channel, char *name, char *message ) 
procedure GInterMud.sendChannelMessage(channel : GChannel_I3; name, msg : string);
begin
	writeHeader('channel-m', this_mud.name, name, '', '');
	writeBuffer('"');
	writeBuffer(channel.I3_name);
	writeBuffer('","');
	writeBuffer(name);
	writeBuffer('","');
	writeBuffer(escape(msg));
	writeBuffer('",})'#13);
	sendPacket();
end;

// void I3_send_channel_emote( I3_CHANNEL *channel, char *name, char *message ) 
procedure GInterMud.sendChannelEmote(channel : GChannel_I3; name, msg : string);
begin
	if (Pos('$N', msg) = 0) then
		msg := '$N ' + msg;
		
	writeHeader('channel-e', this_mud.name, name, '', '');
	writeBuffer('"');
	writeBuffer(channel.I3_name);
	writeBuffer('","');
	writeBuffer(name);
	writeBuffer('","');
	writeBuffer(escape(msg));
	writeBuffer('",})'#13);
	sendPacket();
end;

// void I3_send_channel_t( I3_CHANNEL *channel, char *name, char *tmud, char *tuser, char *msg_o, char *msg_t, char *tvis )
procedure GInterMud.sendChannelTarget(channel : GChannel_I3; name, tmud, tuser, msg_o, msg_t, tvis : string);
begin
	writeHeader('channel-t', this_mud.name, name, '', '');
	writeBuffer('"');
	writeBuffer(channel.I3_name);
	writeBuffer('","');
	writeBuffer(tmud);
	writeBuffer('","');
	writeBuffer(tuser);
	writeBuffer('","');
	writeBuffer(escape(msg_o));
	writeBuffer('","');
	writeBuffer(escape(msg_t));
	writeBuffer('","');
	writeBuffer(name);
	writeBuffer('","');
	writeBuffer(tvis);
	writeBuffer('",})'#13);
	sendPacket();
end;

// void I3_send_channel_listen( I3_CHANNEL *channel, bool lconnect ) 
procedure GInterMud.sendChannelListen(user : string; channel : GChannel_I3; lconnect : boolean);
begin
	writeHeader('channel-listen', this_mud.name, user, router.name, '');
	writeBuffer('"');
	writeBuffer(channel.I3_name);
	writeBuffer('",');
	
	if (lconnect) then
		writeBuffer('1,})'#13)
	else
		writeBuffer('0,})'#13);
		
	sendPacket();
end;

// void I3_send_locate( CHAR_DATA *ch, char *user )
procedure GInterMud.sendLocateRequest(originator, user : string);
begin
	writeHeader('locate-req', this_mud.name, originator, '', '');
	writeBuffer('"');
	writeBuffer(user);
	writeBuffer('",})'#13);
	sendPacket();
end;

// void I3_send_tell( CHAR_DATA *ch, char *to, I3_MUD *mud, char *message )
procedure GInterMud.sendTell(from_user, to_user : string; mud : GMud_I3; msg : string);
begin
	writeHeader('tell', this_mud.name, from_user, mud.name, escape(to_user));
	writeBuffer('"');
	writeBuffer(from_user);
	writeBuffer('","');
	writeBuffer(escape(msg));
	writeBuffer('",})'#13);
	sendPacket();
end;

// void I3_send_beep( CHAR_DATA *ch, char *to, I3_MUD *mud )
procedure GInterMud.sendBeep(from_user, to_user : string; mud : GMud_I3);
begin
	writeHeader('beep', this_mud.name, from_user, mud.name, to_user);
	writeBuffer('"');
	writeBuffer(from_user);
	writeBuffer('",})'#13);
	sendPacket();
end;

// void I3_send_who( CHAR_DATA *ch, char *mud ) 
procedure GInterMud.sendWhoReq(from_user : string; mud : GMud_I3);
begin
	writeHeader('who-req', this_mud.name, from_user, mud.name, '');
	writeBuffer('})'#13);
	sendPacket();	
end;

// void I3_send_finger( CHAR_DATA *ch, char *user, char *mud ) 
procedure GInterMud.sendFingerReq(from_user, to_user : string; mud : GMud_I3);
begin
	writeHeader('finger-req', this_mud.name, from_user, mud.name, '');
	writeBuffer('"');
	writeBuffer(escape(to_user));
	writeBuffer('",');
	writeBuffer('})'#13);
	sendPacket();	
end;

procedure GInterMud.debug(msg : string; level : integer = 1);
begin
	if (level <= debugLevel) then
		writeConsole('I3: ' + msg);
end;

procedure GInterMud.setDebugLevel(debugLevel : integer = 0);
begin
	Self.debugLevel := debugLevel;
end;

end.