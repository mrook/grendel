{
	Delphi IMC3 Client - Packet type and support routines

	Based on client code by Samson of Alsherok.

	$Id: imc3_packet.pas,v 1.3 2003/10/03 21:00:12 ***REMOVED*** Exp $
}
unit imc3_packet;

interface


uses
	Classes;


type
	GPacket_I3 = class
	public
  	original_msg : string;

		packet_type : string;
		ttl : integer;
		originator_mudname : string;
		originator_username : string;
		target_mudname : string;
		target_username : string;

		fields : TList;
		
	private
		function listToString(list : TList; indent : integer = 0) : string;	
		
	published
		function toString() : string;
	end;


function parsePacket(msg : string) : GPacket_I3;


implementation


uses
	SysUtils,
	Contnrs,
	StrUtils,
	util,
	dtypes;


function GPacket_I3.listToString(list : TList; indent : integer = 0) : string;
var
	i : integer;
	s : string;
begin
  s := '';
  
	for i := 0 to list.Count - 1 do
  	begin
    if (TObject(list[i]) is GString) then
	  	s := s + (DupeString(' ', indent) + '- ' + GString(list[i]).value) + #13#10
		else
    if (TObject(list[i]) is TList) then
    	s := s + listToString(list[i], indent + 4);
    end;
    
  Result := s;
end;

function GPacket_I3.toString() : string;
begin
	Result := listToString(fields);
end;


function parsePacket(msg : string) : GPacket_I3;
var
	packet : GPacket_I3;
	backslash, quote : boolean;
	count : array[1..256] of integer;
	len, left, right : integer;
  s : string;
  stack : TObjectStack;
  list : TList;
begin
	backslash := false;
	quote := false;

  for left := 1 to 256 do count[left] := 0;

	packet := GPacket_I3.Create();
  stack := TObjectStack.Create();
  list := TList.Create();

	left := 1;
	right := 1;
	len := length(msg);

	while (right <= len) do
	  begin
		while (right <= len) do
			begin
			case msg[right] of
				'(':	if (not quote) then
								begin
								inc(count[ord('(')]);
								inc(left);
								end;
				')':	if (not quote) then
								begin
								inc(count[ord(')')]);
								inc(left);
								end;
				'{':	if (not quote) then
                begin
        				inc(count[ord('{')]);
                inc(left);

                stack.Push(list);
                list.Add(TList.Create());
                list := list[list.Count - 1];
                end;
				'}':	if (not quote) then
        				begin
                inc(count[ord('}')]);
                inc(left);

                if (stack.Peek() <> nil) then
	                list := TList(stack.Pop());
                end;
				'[':	if (not quote) then
								begin
								inc(count[ord('[')]);
								inc(left);

                stack.Push(list);
                list.Add(TList.Create());
                list := list[list.Count - 1];
								end;
				']':	if (not quote) then
								begin
								inc(count[ord(']')]);
								inc(left);

                if (stack.Peek() <> nil) then
	                list := TList(stack.Pop());
								end;
				'\':	backslash := not backslash;
				'"':	if (backslash) then backslash := false else quote := not quote;
				',',
				':':	begin
							if (quote or backslash) then
								begin
								inc(right);
								continue;
								end;
								
							if (count[ord('(')] <> count[ord(')')]) then
								break;
							if (count[ord('{')] <> count[ord('}')]) then
								break;
							if (count[ord('[')] <> count[ord(']')]) then
								break;

							end;
			end;

			inc(right);
			end;

  	s := removeQuotes(MidBStr(msg, left, right - left));

  	if (length(s) > 0) then
			list.Add(GString.Create(s));

  	inc(right);
	 	left := right;
	end;

  packet.fields := TList.Create();
  packet.fields.Assign(list[0]);

  if (packet.fields.count < 6) then
  	begin
    packet.packet_type := 'error';
    packet.fields.Clear;
  	//('Invalid packet ' + msg);
    end
  else
		begin
		packet.packet_type := GString(packet.fields[0]).value;
	  packet.ttl := StrToIntDef(GString(packet.fields[1]).value, 0);
	  packet.originator_mudname := GString(packet.fields[2]).value;
	  packet.originator_username := GString(packet.fields[3]).value;
	  packet.target_mudname := GString(packet.fields[4]).value;
	  packet.target_username := GString(packet.fields[5]).value;
    end;

  packet.original_msg := msg;
	Result := packet;
end;

end.