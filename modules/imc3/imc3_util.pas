{
	Delphi IMC3 Client - Various utility functions

	Based on client code by Samson of Alsherok.

	$Id: imc3_util.pas,v 1.3 2003/11/11 19:34:33 ***REMOVED*** Exp $
}

unit imc3_util;

interface


uses
	imc3_const,
	chars,
	player;


procedure sendToPlayer(pl : GPlayer; buf : string);
function fishToAnsi(buf : string) : string;
function I3PERM(ch : GCharacter) : I3_PERMISSIONS;


implementation


uses
	SysUtils,
	StrUtils,
	constants;
	

procedure sendToPlayer(pl : GPlayer; buf : string);
var
	t : string;
begin
	t := fishToAnsi(buf);
	
	{ Reset color to stop bleeding }
	pl.sendBuffer(t + #27'[0m');
end;

function fishToAnsi(buf : string) : string;
var
	x, inbuf, cp, cp2, len : integer;
	t, col : string;
begin
	inbuf := 1;
	Result := '';
	col := '';
	
	{ catch the trivial case first (for speed) }
	cp := Pos('%^', buf);
	if (cp = 0) then
		begin
		Result := buf;
		exit;
		end;
		
	while (cp > 0) do
		begin
		cp2 := PosEx('%^', buf, cp + 2);
		
		if (cp2 = 0) then		{ unmatched single %^ }
			break;
		
		len := cp2 - cp + 2;
		
		if (len = 4) then
			begin
			col := '%^';
			end
		else
			begin
			t := Copy(buf, cp, len);
			
			for x := 1 to I3MAX_ANSI do
				if (t = I3_ANSI_CONVERSION[x][2]) then
					begin
					col := I3_ANSI_CONVERSION[x][3];
					break;
					end;
			end;
			
		t := Copy(buf, inbuf, cp - inbuf);
		
		Result := Result + t;
		Result := Result + col;
		
		inbuf := cp2 + 2;
      
		cp := PosEx('%^', buf, inbuf);
		end;
	
	Result := Result + Copy(buf, cp2 + 2, length(buf));
end;

function I3PERM(ch : GCharacter) : I3_PERMISSIONS;
begin
  Result := I3PERM_NOTSET;
  
	if (ch.level < LEVEL_START) then
		Result := I3PERM_NONE
	else
	if (ch.level <= LEVEL_MAX) then
		Result := I3PERM_MORT
	else
	if (ch.level <= LEVEL_BUILD) then
		Result := I3PERM_ADMIN
	else
	if (ch.level <= LEVEL_MAX_IMMORTAL) then
		Result := I3PERM_IMP;
end;


end.