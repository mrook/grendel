{
  Summary:
  	Substring manipulation routines
  	
  ## $Id: strip.pas,v 1.2 2004/02/27 22:24:21 ***REMOVED*** Exp $
}

unit strip;


interface


uses 
	SysUtils;
	

// return the part on the left of the first occurance of 'delim'
// or the whole string if there is no 'delim'
function left(const s : string; delim : char) : string;

// return the part on the right of the first occurance 'delim'
// or the whole string if there is no 'delim'
function right(const s : string; delim : char) : string;

// return the part on the left of the last occurance of 'delim'
// or the whole string if there is no 'delim'
function leftr(const s : string; delim : char) : string;

// return the part on the right of the last occurance 'delim'
// or the whole string if there is no 'delim'
function rightr(const s : string; delim : char) : string;

function charsInStr(const s : string; what : char) : integer;


implementation


function left(const s : string; delim : char) : string;
var
   i : integer;
begin
  i := pos(delim, s);

  if (i > 0) then
    Result := Copy(s, 1, i - 1)
  else
    Result := s;
end;

function right(const s : string; delim : char) : string;
var
   i : integer;
begin
  i := pos(delim, s);

  if (i > 0) then
    Result := Copy(s, i + 1, length(s))
  else
    Result := s;
end;

function leftr(const s : string; delim : char) : string;
var
   i : integer;
begin
  i := LastDelimiter(delim, s);

  if (i > 0) then
    Result := Copy(s, 1, i - 1)
  else
    Result := s;
end;

function rightr(const s : string; delim : char) : string;
var
   i : integer;
begin
  i := LastDelimiter(delim, s);

  if (i > 0) then
    Result := Copy(s, i + 1, length(s))
  else
    Result := s;
end;

function charsInStr(const s : string; what : char) : integer;
var 
	a , b : integer;
begin
  b := 0;
  
  for a := 1 to length(s) do
   	if (s[a] = what) then 
   		inc(b,1);
   		
  Result := b;
end;

end.
