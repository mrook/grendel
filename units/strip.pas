unit strip;

interface
uses SysUtils;

// return the part on the left of the first occurance of 'delim'
// or the whole string if there is no 'delim'
function left(s : string; delim : char) : string;

// return the part on the right of the first occurance 'delim'
// or the whole string if there is no 'delim'
function right(s : string; delim : char) : string;

// return the part on the left of the last occurance of 'delim'
// or the whole string if there is no 'delim'
function leftr(s : string; delim : char) : string;

// return the part on the right of the last occurance 'delim'
// or the whole string if there is no 'delim'
function rightr(s : string; delim : char) : string;

function CharsInStr(s:string;what:char):integer;

implementation

function left(s : string; delim : char) : string;
var
   i : integer;
begin
  i := pos(delim, s);

  if (i > 0) then
    Result := Copy(s, 1, i - 1)
  else
    Result := s;
end;

function right(s : string; delim : char) : string;
var
   i : integer;
begin
  i := pos(delim, s);

  if (i > 0) then
    Result := Copy(s, i + 1, length(s))
  else
    Result := s;
end;

function leftr(s : string; delim : char) : string;
var
   i : integer;
begin
  i := LastDelimiter(delim, s);

  if (i > 0) then
    Result := Copy(s, 1, i - 1)
  else
    Result := s;
end;

function rightr(s : string; delim : char) : string;
var
   i : integer;
begin
  i := LastDelimiter(delim, s);

  if (i > 0) then
    Result := Copy(s, i + 1, length(s))
  else
    Result := s;
end;

function CharsInStr;
var a,b:integer;
begin
  b:=0;
  for a:=1 to length(s) do
   if s[a]=what then inc(b,1);
  CharsInStr:=b;
end;

end.
