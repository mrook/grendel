{
	Delphi IMC3 Client - Interface with core

	Based on client code by Samson of Alsherok.

	$Id: imc3_main.pas,v 1.1 2003/12/12 13:19:55 ***REMOVED*** Exp $
}

unit imc3_main;

interface

implementation


uses
	SysUtils,
	chars,
	player,
	commands,
	dtypes,
	util,
	modules,
	conns,
	constants,
	strip,
	imc3_const,
	imc3_chan,
	imc3_mud,
	imc3_util,
	imc3_core;


type
  GInterMudModule = class(TInterfacedObject, IModuleInterface)
  published
  	procedure registerModule();
  	procedure unregisterModule();
  end;
  

var
 	i3: GInterMud;


procedure do_i3(ch : GCharacter; param : string);
var
	iterator : GIterator;
	mud : GMud_I3;
	channel : GChannel_I3;
	cmd, arg, s, t : string;
	i : integer;
begin
	param := one_argument(param, cmd);
	
	if (length(cmd) = 0) then
		begin
		ch.sendBuffer('Usage: I3 <connect/status/mudlist/chanlist/chat/listen/tell/locate/beep/who/finger/help>'#13#10);
		exit;
		end;
	
	if (prep(cmd) = 'DEBUG') then
		begin
		if (prep(param) = 'OFF') then
			begin
			i3.setDebugLevel(0);
			ch.sendBuffer('I3 debugging turned off.'#13#10);
			end
		else
			begin
			i3.setDebugLevel(2);
			ch.sendBuffer('I3 debugging turned off.'#13#10);
			end;
		end
	else
	if (prep(cmd) = 'CONNECT') then
		begin
		if (i3.isConnected) then
			begin
			ch.sendBuffer('Already connected.'#13#10);
			exit;
			end;
			
		i3.wait := 2;
		ch.sendBuffer('Ok.'#13#10);
		end
	else
	if (prep(cmd) = 'STATUS') then
		begin
		if (not i3.isConnected) then
			ch.sendBuffer('Not connected.'#13#10)
		else
			begin
			ch.sendBuffer('Connected to ' + i3.connectedRouter.name + ' (' + i3.connectedRouter.ipaddress + ' ' + IntToStr(i3.connectedRouter.port) + ')'#13#10);
			ch.sendBuffer('Known muds: ' + IntToStr(mudList.size()) + #13#10);
			ch.sendBuffer('Known channels: ' + IntToStr(chanList.size()) + #13#10);
			end;
		end
	else
	if (prep(cmd) = 'MUDLIST') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		param := one_argument(param, arg);
		ch.sendPager(pad_string('Name', 30) + pad_string('Type', 10) + pad_string('Mudlib', 20) + pad_string('Address', 15) + #13#10#13#10);
		
		iterator := mudList.iterator();
		
		while (iterator.hasNext()) do
			begin
			mud := GMud_I3(iterator.next());

			if (prep(arg) = 'UP') and (mud.status >= 0) then 
				continue;
			
			case mud.status of
				-1:	ch.sendPager(pad_string(mud.name, 30) + pad_string(mud.mud_type, 10) + pad_string(mud.mudlib, 20) + pad_string(mud.ipaddress + ':' + IntToStr(mud.player_port), 15) + #13#10);
				0:	ch.sendPager(pad_string(mud.name, 30) + '(down)' + #13#10);
			else  ch.sendPager(pad_string(mud.name, 30) + '(rebooting)' + #13#10);
			end;
			end;
			
		iterator.Free();
		end
	else
	if (prep(cmd) = 'CHANLIST') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		ch.sendPager(pad_string('Name', 20) + pad_string('Hosted by', 30) + #13#10#13#10);
		
		iterator := chanList.iterator();
		
		while (iterator.hasNext()) do
			begin
			channel := GChannel_I3(iterator.next());
			
			ch.sendPager(pad_string(channel.I3_name, 20) + pad_string(channel.host_mud, 30) + #13#10);
			end;
			
		iterator.Free();
		end
	else
	if (prep(cmd) = 'CHAT') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		param := one_argument(param, arg);
		
		if (length(arg) = 0) then
			begin
			ch.sendBuffer('Usage: I3 <channel> <message>'#13#10);
			exit;
			end;
			
		channel := GChannel_I3(chanList.get(arg));
		
		if (channel <> nil) then
			begin
			if (length(param) = 0) then
				begin
				if (channel.history.Count = 0) then
					ch.sendBuffer('No history for this channel.'#13#10)
				else
					begin
					ch.sendBuffer('The last ' + IntToStr(channel.history.Count) + ' message(s):'#13#10);
				
					for i := 0 to channel.history.Count - 1 do
						act(AT_REPORT, channel.history[i], false, ch, nil, nil, TO_CHAR);				
					end;
				exit;
				end;
				
			i3.sendChannelMessage(channel, ch.name, param);
			end
		else
			ch.sendBuffer('Unknown channel, use I3 CHANLIST to view a list of all available channels.'#13#10);
		end
	else
	if (prep(cmd) = 'LISTEN') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		if (length(param) = 0) then
			begin
			ch.sendBuffer('Usage: I3 listen [all]/<channel>'#13#10);
			exit;
			end;

		if (prep(param) = 'ALL') then
			begin
			iterator := chanList.iterator();

			while (iterator.hasNext()) do
				begin
				channel := GChannel_I3(iterator.next());

				ch.sendBuffer('Listening to ' + channel.I3_name + '.'#13#10);
				i3.sendChannelListen(ch.name, channel, true);
				end;

			iterator.Free();
			end
		else
			begin
			channel := GChannel_I3(chanList.get(param));

			if (channel <> nil) then
				begin
				ch.sendBuffer('Listening to ' + channel.I3_name + '.'#13#10);
				i3.sendChannelListen(ch.name, channel, true);
				end
			else
				ch.sendBuffer('Unknown channel, use I3 CHANLIST to view a list of all available channels.'#13#10);
			end;
		end
	else
	if (prep(cmd) = 'LOCATE') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		if (length(param) = 0) then
			begin
			ch.sendBuffer('Usage: I3 locate <username>'#13#10);
			exit;
			end;

		ch.sendBuffer('Trying to locate "' + param + '". If you do not got any results within'#13#10);
		ch.sendBuffer('the next minute, you can safely assume this player is not online.'#13#10);

		i3.sendLocateRequest(ch.name, param);
		end
	else
	if (prep(cmd) = 'TELL') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		param := one_argument(param, arg);

		if (length(arg) = 0) then
			begin
			ch.sendBuffer('Usage: I3 tell <user@mud> <message>'#13#10);
			ch.sendBuffer('Usage: I3 tell [on]/[off]'#13#10);
			exit;
			end;
			
		if (prep(arg) = 'ON') then
			begin
			(GPlayer(ch).fields['i3flag'] as GBitVector).removeBit(I3_TELL);
			ch.sendBuffer('You now send and receive i3tells.'#13#10);
			exit;
			end;

		if (prep(arg) = 'OFF') then
			begin
			(GPlayer(ch).fields['i3flag'] as GBitVector).setBit(I3_TELL);
			ch.sendBuffer('You no longer send and receive i3tells.'#13#10);
			exit;
			end;
			
		if ((GPlayer(ch).fields['i3flag'] as GBitVector).isBitSet(I3_TELL)) then
			begin
			ch.sendBuffer('Your i3tells are turned off.'#13#10);
			exit;
			end;

		if (pos('@', arg) = 0) then
			begin
			ch.sendBuffer('You should specify a person and a mud. Use "I3 mudlist" to get an overview of the muds available.'#13#10);
			exit;
			end;
			
		s := right(arg, '@');
		t := lowercase(left(arg, '@'));
		mud := findMud(s);
		
		if (mud = nil) then
			begin
			ch.sendBuffer('No such mud known. Use "I3 mudlist" to get an overview of the muds available.'#13#10);
			exit;
			end;
			
		if (mud.status >= 0) then
			begin
			ch.sendBuffer('Mud is down.'#13#10);
			exit;
			end;
			
		if (not mud.tell) then
			begin
			ch.sendBuffer('Mud does not support the ''tell'' command.'#13#10);
			exit
			end;
		
		i3.sendTell(ch.name, t, mud, param);
		ch.sendBuffer(Format('You tell %s@%s: %s', [cap(t), mud.name, param]) + #13#10);
		end
	else
	if (prep(cmd) = 'BEEP') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		if (length(param) = 0) then
			begin
			ch.sendBuffer('Usage: I3 beep <user@mud>'#13#10);
			exit;
			end;

		if (pos('@', param) = 0) then
			begin
			ch.sendBuffer('You should specify a person and a mud. Use "I3 mudlist" to get an overview of the muds available.'#13#10);
			exit;
			end;
			
		s := right(param, '@');
		t := lowercase(left(param, '@'));
		mud := findMud(s);
		
		if (mud = nil) then
			begin
			ch.sendBuffer('No such mud known. Use "I3 mudlist" to get an overview of the muds available.'#13#10);
			exit;
			end;
			
		if (mud.status >= 0) then
			begin
			ch.sendBuffer('Mud is down.'#13#10);
			exit;
			end;
			
		if (not mud.beep) then
			begin
			ch.sendBuffer('Mud does not support the ''beep'' command.'#13#10);
			exit
			end;
		
		i3.sendBeep(ch.name, t, mud);
		ch.sendBuffer(Format('You beep %s@%s.', [cap(t), mud.name]) + #13#10);
		end
	else
	if (prep(cmd) = 'WHO') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		if (length(param) = 0) then
			begin
			ch.sendBuffer('Usage: I3 who <mud>'#13#10);
			exit;
			end;

		mud := findMud(param);
		
		if (mud = nil) then
			begin
			ch.sendBuffer('No such mud known. Use "I3 mudlist" to get an overview of the muds available.'#13#10);
			exit;
			end;
			
		if (mud.status >= 0) then
			begin
			ch.sendBuffer('Mud is down.'#13#10);
			exit;
			end;
			
		if (not mud.who) then
			begin
			ch.sendBuffer('Mud does not support the ''who'' command.'#13#10);
			exit
			end;
		
		i3.sendWhoReq(ch.name, mud);
		ch.sendBuffer('Ok.'#13#10);
		end
	else
	if (prep(cmd) = 'FINGER') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		if (length(param) = 0) then
			begin
			ch.sendBuffer('Usage: I3 finger <user@mud>'#13#10);
			exit;
			end;

		if (pos('@', param) = 0) then
			begin
			ch.sendBuffer('You should specify a person and a mud. Use "I3 mudlist" to get an overview of the muds available.'#13#10);
			exit;
			end;
			
		s := right(param, '@');
		t := lowercase(left(param, '@'));
		mud := findMud(s);
		
		if (mud = nil) then
			begin
			ch.sendBuffer('No such mud known. Use "I3 mudlist" to get an overview of the muds available.'#13#10);
			exit;
			end;
			
		if (mud.status >= 0) then
			begin
			ch.sendBuffer('Mud is down.'#13#10);
			exit;
			end;
			
		if (not mud.finger) then
			begin
			ch.sendBuffer('Mud does not support the ''finger'' command.'#13#10);
			exit
			end;
		
		i3.sendFingerReq(ch.name, t, mud);
		ch.sendBuffer('Ok.'#13#10);
		end
	else
	if (prep(cmd) = 'MUDINFO') then
		begin
		if (not i3.isConnected) then
			begin
			ch.sendBuffer('Not connected.'#13#10);
			exit;
			end;

		if (length(param) = 0) then
			begin
			ch.sendBuffer('Usage: I3 mudinfo <mud>'#13#10);
			exit;
			end;

		mud := findMud(param);
		
		if (mud = nil) then
			begin
			ch.sendBuffer('No such mud known. Use "I3 mudlist" to get an overview of the muds available.'#13#10);
			exit;
			end;
			
		ch.sendBuffer('Information about ' + mud.name + #13#10#13#10);

		if (mud.status = -1) then
			ch.sendBuffer('Status     : Up'#13#10)
		else
		if (mud.status = 0) then
			ch.sendBuffer('Status     : Currently down'#13#10)
		else
			ch.sendBuffer('Status     : Currently rebooting, back in ' + IntToStr(mud.status) + ' second(s)'#13#10);
			
		ch.sendBuffer('MUD port   : ' + mud.ipaddress + ' ' + IntToStr(mud.player_port) + #13#10);
		ch.sendBuffer('Base mudlib: ' + mud.base_mudlib + #13#10);
		ch.sendBuffer('Mudlib     : ' + mud.mudlib + #13#10);
		ch.sendBuffer('Driver     : ' + mud.driver + #13#10);
		ch.sendBuffer('Type       : ' + mud.mud_type + #13#10);
		ch.sendBuffer('Open status: ' + mud.open_status + #13#10);
		ch.sendBuffer('Admin      : ' + mud.admin_email + #13#10);
		
		if (mud.web <> '') then
		  ch.sendBuffer('URL        : ' + mud.web + #13#10);
		if (mud.daemon <> '') then
			ch.sendBuffer('Daemon     : ' + mud.daemon + #13#10);
		if (mud.time <> '') then
			ch.sendBuffer('Time     : ' + mud.time + #13#10);
		if (mud.jeamland > 0) then
			ch.sendBuffer('Jeamland     : ' + IntToStr(mud.jeamland) + #13#10);
		if (mud.banner <> '') then
			ch.sendBuffer('Banner     : ' + mud.banner + #13#10);
		
		ch.sendBuffer('Supports   : ');
		if (mud.tell) then
			ch.sendBuffer('tell, ');
		if (mud.beep) then
			ch.sendBuffer('beep, ');
		if (mud.emoteto) then
			ch.sendBuffer('emoteto, ');
		if (mud.who) then
			ch.sendBuffer('who, ');
		if (mud.finger) then
			ch.sendBuffer('finger, ');
		if (mud.locate) then
			ch.sendBuffer('locate, ');
		if (mud.channel) then
			ch.sendBuffer('channel, ');
		if (mud.news) then
			ch.sendBuffer('news, ');
		if (mud.mail) then
			ch.sendBuffer('mail, ');
		if (mud.mfile) then
			ch.sendBuffer('file, ');
		if (mud.auth) then
			ch.sendBuffer('auth, ');
		if (mud.ucache) then
			ch.sendBuffer('ucache, ');
		ch.sendBuffer(#13#10);
		
		ch.sendBuffer('Supports   : ');
		if (mud.smtp > 0) then
			ch.sendBuffer('smtp (port ' + IntToStr(mud.smtp) + '), ');
		if (mud.http > 0) then
			ch.sendBuffer('http (port ' + IntToStr(mud.http) + '), ');
		if (mud.ftp > 0) then
			ch.sendBuffer('ftp (port ' + IntToStr(mud.ftp) + '), ');
		if (mud.pop3 > 0) then
			ch.sendBuffer('pop3 (port ' + IntToStr(mud.pop3) + '), ');
		if (mud.nntp > 0) then
			ch.sendBuffer('nntp (port ' + IntToStr(mud.nntp) + '), ');
		if (mud.rcp > 0) then
			ch.sendBuffer('rcp (port ' + IntToStr(mud.rcp) + '), ');
		if (mud.amrcp > 0) then
			ch.sendBuffer('amrcp (port ' + IntToStr(mud.amrcp) + '), ');
		ch.sendBuffer(#13#10);
		end
	else
	if (prep(cmd) = 'HELP') then
		begin
		ch.sendBuffer('General Usage:'#13#10);
		ch.sendBuffer('------------------------------------------------'#13#10#13#10);
		ch.sendBuffer('Chat on a channel                      : i3 chat <channel> <message>'#13#10);
		ch.sendBuffer('Direct tell                            : i3 tell <user@mud> <message>'#13#10);
		ch.sendBuffer('Beep somebody                          : i3 beep <user@mud>'#13#10);
		ch.sendBuffer('List channels available                : i3 chanlist [all] [filter]'#13#10);
		ch.sendBuffer('To tune into a channel                 : i3 listen <channel>'#13#10);
		ch.sendBuffer('See who is logged into a mud           : i3 who <mud>'#13#10);
		ch.sendBuffer('Finger somebody                        : i3 finger <user@mud>'#13#10);
		ch.sendBuffer('Locate somebody on the I3 network      : i3 locate <username>'#13#10);
		ch.sendBuffer('! To see who is listening on another mud : i3 chanwho <channel> <mud>'#13#10);
		ch.sendBuffer('List muds connected to I3              : i3 mudlist [filter]'#13#10);
		ch.sendBuffer('Information on another mud             : i3 mudinfo <mud>'#13#10);
		ch.sendBuffer('! Ignore someone who annoys you          : i3 ignore <string>'#13#10);
		ch.sendBuffer('! Make yourself invisible to I3          : i3 invis'#13#10);
		ch.sendBuffer('! Toggle I3 color                        : i3 color'#13#10);

		if (I3PERM(ch) >= I3PERM_IMM) then
			begin
			ch.sendBuffer(#13#10'Immortal functions'#13#10);
			ch.sendBuffer('------------------------------------------------'#13#10#13#10);
			ch.sendBuffer('General statistics:'#13#10);
			ch.sendBuffer('! i3 ucache'#13#10);
			ch.sendBuffer('! i3 user <person@mud>'#13#10);
			ch.sendBuffer('Channel control:'#13#10);
			ch.sendBuffer('! i3 deny <person> <channel>'#13#10);
			end;

		if (I3PERM(ch) >= I3PERM_ADMIN) then
			begin
			ch.sendBuffer(#13#10'Administrative functions'#13#10);
			ch.sendBuffer('------------------------------------------------'#13#10#13#10);
			ch.sendBuffer('New channel creation and administration:'#13#10);
			ch.sendBuffer('! i3 addchan <channelname> <type>'#13#10);
			ch.sendBuffer('! i3 removechan <channel>'#13#10);
			ch.sendBuffer('! i3 adminchan <channel> <add|remove> <mudname>'#13#10#13#10);
			ch.sendBuffer('Traffic control and permissions:'#13#10);
			ch.sendBuffer('! i3 ban <string>'#13#10);
			end;
			
		ch.sendBuffer(#13#10'(! = not implemented)'#13#10);
		end
	else
		ch.sendBuffer('Not implemented.'#13#10);
end;


function returnModuleInterface() : IModuleInterface;
begin
	Result := GInterMudModule.Create();
end;

procedure GInterMudModule.registerModule();
begin
  i3 := GInterMud.Create(1);
	i3.FreeOnTerminate := true;
	
	registerCommand('do_i3', do_i3);
	
	registerField(GPlayerFieldFlag.Create('i3flag'));
	registerField(GPlayerFieldString.Create('i3replyname'));
end;

procedure GInterMudModule.unregisterModule();
begin
	unregisterField('i3flag');
	unregisterField('i3replyname');
	
  unregisterCommand('do_i3');
  
	i3.Terminate();

	{ Give thread a chance to terminate and free }
	Sleep(250);
end;


exports
	returnModuleInterface;


end.