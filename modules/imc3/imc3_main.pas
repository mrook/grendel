{
	Delphi IMC3 Client - Interface with core

	Based on client code by Samson of Alsherok.

	$Id: imc3_main.pas,v 1.8 2003/10/20 16:01:08 ***REMOVED*** Exp $
}

unit imc3_main;

interface

implementation


uses
	SysUtils,
	chars,
	commands,
	dtypes,
	util,
	modules,
	imc3_chan,
	imc3_mud,
	imc3_core;


type
  GInterMudModule = class(TInterfacedObject, IModuleInterface)
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
	cmd, arg : string;
begin
	param := one_argument(param, cmd);
	param := one_argument(param, arg);
	
	if (length(cmd) = 0) then
		begin
		ch.sendBuffer('I3 what?'#13#10);
		exit;
		end;
		
	if (prep(cmd) = 'MUDLIST') then
		begin
		ch.sendPager(pad_string('Name', 30) + pad_string('Type', 10) + pad_string('Mudlib', 20) + pad_string('Address', 15) + #13#10#13#10);
		
		iterator := mudList.iterator();
		
		while (iterator.hasNext()) do
			begin
			mud := GMud_I3(iterator.next());
			
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
		if (prep(arg) = 'ALL') then
			begin
			iterator := chanList.iterator();

			while (iterator.hasNext()) do
				begin
				channel := GChannel_I3(iterator.next());

				ch.sendBuffer('Listening to ' + channel.I3_name + #13#10);
				i3.sendChannelListen(channel, true);
				end;

			iterator.Free();
			end
		else
			begin
			channel := GChannel_I3(chanList.get(arg));

			if (channel <> nil) then
				begin
				ch.sendBuffer('Listening to ' + channel.I3_name + #13#10);
				i3.sendChannelListen(channel, true);
				end
			else
				ch.sendBuffer('Unknown channel, use I3 CHANLIST to view a list of all available channels.'#13#10);
			end;
		end
	else
	if (prep(cmd) = 'LOCATE') then
		begin
		if (length(arg) = 0) then
			ch.sendBuffer('Locate whom?'#13#10)
		else
			begin
			ch.sendBuffer('Trying to locate "' + arg + '". If you do not got any results within the next minute,'#13#10);
			ch.sendBuffer('you can safely assume this player is not online.'#13#10);
			
			i3.sendLocateRequest(ch.name, arg);
			end;
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
end;

procedure GInterMudModule.unregisterModule();
begin
  unregisterCommand('do_i3');
	i3.Terminate();

	{ Give thread a chance to terminate and free }
	Sleep(250);
end;


exports
	returnModuleInterface;


end.