{
	Delphi IMC3 Client - Interface with core

	Based on client code by Samson of Alsherok.

	$Id: imc3_main.pas,v 1.3 2003/10/02 15:52:40 ***REMOVED*** Exp $
}

unit imc3_main;

interface

implementation

uses
	SysUtils,
	chars,
	mudthread,
	dtypes,
	util,
	imc3_chan,
	imc3_mud,
	imc3_core;

var
 	i3: GInterMud;


procedure do_i3(ch : GCharacter; param : string);
var
	iterator : GIterator;
	mud : GMud_I3;
	channel : GChannel_I3;
begin
	if (prep(param) = 'MUDLIST') then
		begin
		ch.sendBuffer(pad_string('Name', 30) + pad_string('Type', 10) + pad_string('Mudlib', 20) + pad_string('Address', 15) + #13#10#13#10);
		
		iterator := mudList.iterator();
		
		while (iterator.hasNext()) do
			begin
			mud := GMud_I3(iterator.next());
			
			case mud.status of
				-1:	ch.sendBuffer(pad_string(mud.name, 30) + pad_string(mud.mud_type, 10) + pad_string(mud.mudlib, 20) + pad_string(mud.ipaddress + ':' + IntToStr(mud.player_port), 15) + #13#10);
				0:	ch.sendBuffer(pad_string(mud.name, 30) + '(down)' + #13#10);
			else  ch.sendBuffer(pad_string(mud.name, 30) + '(rebooting)' + #13#10);
			end;
			end;
			
		iterator.Free();
		end
	else
	if (prep(param) = 'CHANLIST') then
		begin
		ch.sendBuffer(pad_string('Name', 20) + pad_string('Hosted by', 30) + #13#10#13#10);
		
		iterator := chanList.iterator();
		
		while (iterator.hasNext()) do
			begin
			channel := GChannel_I3(iterator.next());
			
			ch.sendBuffer(pad_string(channel.I3_name, 20) + pad_string(channel.host_mud, 30) + #13#10);
			end;
			
		iterator.Free();
		end
	else
		ch.sendBuffer('Unimplemented.'#13#10);
end;

initialization
  i3 := GInterMud.Create(false);
  registerCommand('do_i3', do_i3);

finalization
  unregisterCommand('do_i3');
	i3.Terminate();

	{ Give thread a chance to stop }
	Sleep(10);

	i3.Free();

end.