{
	Delphi IMC3 Client - Interface with core

	Based on client code by Samson of Alsherok.

	$Id: imc3_main.pas,v 1.17 2003/11/02 20:22:05 ***REMOVED*** Exp $
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
	strip,
	imc3_const,
	imc3_chan,
	imc3_mud,
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
begin
	param := one_argument(param, cmd);
	
	if (length(cmd) = 0) then
		begin
		ch.sendBuffer('Usage: I3 <status/mudlist/chanlist/chat/listen/tell/locate/beep/who/finger>'#13#10);
		exit;
		end;
		
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
		param := one_argument(param, arg);
		
		if (length(arg) = 0) and (length(param) = 0) then
			begin
			ch.sendBuffer('Usage: I3 chat <channel> <message>'#13#10);
			exit;
			end;
			
		channel := GChannel_I3(chanList.get(arg));
		
		if (channel <> nil) then
			begin
			i3.sendChannelMessage(channel, ch.name, param);
			end
		else
			ch.sendBuffer('Unknown channel, use I3 CHANLIST to view a list of all available channels.'#13#10);
		end
	else
	if (prep(cmd) = 'LISTEN') then
		begin
		if (length(param) = 0) then
			begin
			ch.sendBuffer('Usage: I3 listen [all]/<channel>'#13#10);
			exit;
			end;

		if (prep(arg) = 'ALL') then
			begin
			iterator := chanList.iterator();

			while (iterator.hasNext()) do
				begin
				channel := GChannel_I3(iterator.next());

				ch.sendBuffer('Listening to ' + channel.I3_name + #13#10);
				i3.sendChannelListen(ch.name, channel, true);
				end;

			iterator.Free();
			end
		else
			begin
			channel := GChannel_I3(chanList.get(arg));

			if (channel <> nil) then
				begin
				ch.sendBuffer('Listening to ' + channel.I3_name + #13#10);
				i3.sendChannelListen(ch.name, channel, true);
				end
			else
				ch.sendBuffer('Unknown channel, use I3 CHANLIST to view a list of all available channels.'#13#10);
			end;
		end
	else
	if (prep(cmd) = 'LOCATE') then
		begin
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
		ch.sendBuffer('Unimplemented.'#13#10);
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