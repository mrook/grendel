unit util;

interface

uses
    SysUtils,
    ansiio;

function URange(min, value, max : longint) : longint;
function UMax(value, max : longint) : longint;
function UMin(value, min : longint) : longint;

function IS_SET(value, bit : cardinal) : boolean;
procedure SET_BIT(var value : cardinal; bit : cardinal);
procedure REMOVE_BIT(var value : cardinal; bit : cardinal);

function pad_integer(s, num : integer) : string;
function pad_integer_front(s, num : integer) : string;
function pad_string(s : string; num : integer) : string;
function pad_string_front(s : string; num : integer) : string;
function trail_number(s:integer):string;
function findNumber(var s:string):integer;
function add_chars(num:integer; s : string; c : char) : string;
function cap(s : string) : string;

function one_argument(argument : string; var arg_first : string) : string;

function number_range(val_from, val_to : integer) : integer;
function number_percent:integer;
function rolldice(num,size:integer):integer;

function mudAnsi(color : integer) : string;

function isName(name , param : string) : boolean;

function DiffMinutes (const D1, D2 : TDateTime) : Integer;
function DiffHours (const D1, D2 : TDateTime) : Integer;
function DiffDays (const D1, D2 : TDateTime) : Integer;

function StringMatches(Value, Pattern : String) : Boolean;

function makedrunk(param : string) : string;

implementation

uses
    constants,
    strip;

function URange(min, value, max : longint) : longint;
begin
  if (value < min) then
    URange := min
  else
  if (value > max) then
    URange := max
  else
    URange := value;
end;

function UMax(value, max : longint) : longint;
begin
  if (value > max) then
    UMax := max
  else
    UMax := value;
end;

function UMin(value, min : longint) : longint;
begin
  if (value < min) then
    UMin := min
  else
    UMin := value;
end;

function IS_SET(value, bit : cardinal) : boolean;
begin
  IS_SET := ((value and bit) = bit);
end;

procedure SET_BIT(var value : cardinal; bit : cardinal);
begin
  value := value or bit;
end;

procedure REMOVE_BIT(var value : cardinal; bit : cardinal);
begin
  if (IS_SET(value, bit)) then
    dec(value, bit);
end;

function pad_integer(s, num : integer) : string;
var g : string;
begin
  g := inttostr(s);

  pad_integer := g + StringOfChar(' ', num-length(g));
end;

function pad_integer_front(s, num : integer) : string;
var g : string;
begin
  g := inttostr(s);

  pad_integer_front := StringOfChar(' ', num - length(g)) + g;
end;

function pad_string(s : string; num : integer) : string;
begin
  pad_string := s + StringOfChar(' ', num - length(s));
end;

function pad_string_front(s : string; num : integer) : string;
begin
  pad_string_front := StringOfChar(' ', num - length(s)) + s;
end;

function trail_number(s:integer):string;
var g:string;
begin
  g:=inttostr(s);
  case s of
    1:g:=g+'st';
    2:g:=g+'nd';
    3:g:=g+'rd';
  else
    g:=g+'th';
  end;
  trail_number:=g;
end;

function findNumber(var s:string):integer;
var g:string;
begin
  if (pos('.',s) = 0) then
    Result := 1
  else
    begin
    g := stripl(s,'.');
    s := striprbeg(s,'.');

    try
      Result := strtoint(g);
    except
      Result := 1;
    end;
    end;
end;

function add_chars(num:integer; s : string; c : char) : string;
begin
  if (length(s)>num) then
    begin
    add_chars := s;
    exit;
    end;

  add_chars := s + StringOfChar(c, num - length(s));
end;

function cap(s : string) : string;
var g : integer;
begin
  if (length(s) = 0) then
    begin
    cap := '';
    exit;
    end;

  g := 0;

  repeat
    inc(g);
    if (s[g] = '$') then
      inc(g, 2);
  until (byte(s[g]) in [33..126]) or (length(s) <= g);

  s[g] := upcase(s[g]);
  cap := s;
end;

function one_argument(argument : string; var arg_first : string) : string;
var cEnd : char;
    count : integer;
    p : integer;
begin
  count := 0;
  cEnd := ' ';
  p := 1;

  argument := trim(argument);

  arg_first := '';

  if (length(argument) = 0) then
    begin
    one_argument := '';
    exit;
    end;

  if (argument[p] = '''') or (argument[p] = '"') then
    begin
    cEnd := argument[p];
    inc(p);
    end;

  while (p <= length(argument)) and (count < 256) do
    begin
    if (argument[p] = cEnd) or (argument[p] = #13) or (argument[p] = #10) then
      begin
      inc(p);
      break;
      end;

    arg_first := concat(arg_first, argument[p]);

    inc(p);
    inc(count);
    end;

  while (p <= length(argument)) and ((argument[p] = ' ') or (argument[p] = #13) or (argument[p] = #10)) do
    inc(p);

  one_argument := copy(argument, p, length(argument) - p + 1);
end;

function number_range(val_from, val_to : integer) : integer;
begin
  number_range := random(val_to - val_from) + val_from;
end;

function number_percent:integer;
begin
  number_percent:=random(100)+1;
end;

function rolldice(num,size:integer):integer;
var s,a:integer;
begin
  s:=0;
  for a:=1 to num do
    inc(s,random(size)+1);
  rolldice:=s;
end;

function mudAnsi(color : integer) : string;
begin
  if (color > 8) then
    mudAnsi := '$B$' + inttostr(color - 8)
  else
    mudAnsi := '$A$' + inttostr(color);
end;

{Jago 10/Jan/2001 - utility function (- move it to util.pas)}
function isName(name , param : string) : boolean;
begin
	Result := (Pos(trim(uppercase(param)), trim(uppercase(name)) ) > 0);
end;

// functions borrowed from the Delphi Fundamentals
const
  OneDay         = 1.0;
  OneHour        = OneDay / 24.0;
  OneMinute      = OneHour / 60.0;
  OneSecond      = OneMinute / 60.0;
  OneMillisecond = OneSecond / 1000.0;

function DiffMinutes (const D1, D2 : TDateTime) : Integer;
begin
  Result := Trunc ((D2 - D1) / OneMinute);
end;

function DiffHours (const D1, D2 : TDateTime) : Integer;
begin
  Result := Trunc ((D2 - D1) / OneHour);
end;

function DiffDays (const D1, D2 : TDateTime) : Integer;
begin
  Result := Trunc (D2 - D1);
end;


// functions borrowed from the Peter Morris' FastString lib
function FastCharPos(const aSource : String; const C: Char; StartPos : Integer) : Integer;
var
  L                           : Integer;
begin
  //If this assert failed, it is because you passed 0 for StartPos, lowest value is 1 !!
  Assert(StartPos > 0);

  Result := 0;
  L := Length(aSource);
  if L = 0 then exit;
  if StartPos > L then exit;
  Dec(StartPos);
  asm
      PUSH EDI                 //Preserve this register

      mov  EDI, aSource        //Point EDI at aSource
      add  EDI, StartPos
      mov  ECX, L              //Make a note of how many chars to search through
      sub  ECX, StartPos
      mov  AL,  C              //and which char we want
    @Loop:
      cmp  Al, [EDI]           //compare it against the SourceString
      jz   @Found
      inc  EDI
      dec  ECX
      jnz  @Loop
      jmp  @NotFound
    @Found:
      sub  EDI, aSource        //EDI has been incremented, so EDI-OrigAdress = Char pos !
      inc  EDI
      mov  Result,   EDI
    @NotFound:

      POP  EDI
  end;
end;

function StringMatches(Value, Pattern : String) : Boolean;
var
  NextPos,
  Star1,
  Star2       : Integer;
  NextPattern   : String;
begin
  Star1 := FastCharPos(Pattern,'*',1);
  if Star1 = 0 then
    Result := (Value = Pattern)
  else begin
    Result := (Copy(Value,1,Star1-1) = Copy(Pattern,1,Star1-1));
    if Result then begin
      if Star1 > 1 then Value := Copy(Value,Star1,Length(Value));
      Pattern := Copy(Pattern,Star1+1,Length(Pattern));

      NextPattern := Pattern;
      Star2 := FastCharPos(NextPattern, '*',1);
      if Star2 > 0 then NextPattern := Copy(NextPattern,1,Star2-1);

      NextPos := pos(NextPattern,Value);
      if (NextPos = 0) and not (NextPattern = '') then
        Result := False
      else begin
        Value := Copy(Value,NextPos,Length(Value));
        if Pattern = '' then
          Result := True
        else
          Result := Result and StringMatches(Value,Pattern);
      end;
    end;
  end;
end;

// Drunken speech - Nemesis
function makedrunk(param : string) : string;
var temp : char;
    i, drunkpos : integer;
    buf, drunkstring : string;
begin
  for i:=1 to length(param) do
    begin
    drunkpos := 0;

    param := uppercase(param);
    temp := param[i];

    if (temp = ' ') then
      buf := ' '
    else
    if not (temp in ['A'..'Z']) then
      buf := temp
    else
      begin
      try
        while (cap(temp) < 'Z') do
          begin
          inc(temp);
          inc(drunkpos);
          end;
      except
        drunkpos := -1;
        end;

      if (drunkpos >= 0) and (drunkpos <= 25) then
        buf := drunkbuf[drunkpos]
      else
        buf := temp;
      end;

    drunkstring := drunkstring + buf;
    end;

  Result := drunkstring;
end;

end.
