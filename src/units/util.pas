{
	Summary:
		Various utility functions
		
	## $Id: util.pas,v 1.6 2004/03/04 19:11:24 ***REMOVED*** Exp $
}

unit util;

interface

uses
    strip,
    SysUtils,
    ansiio;

function URange(min, value, max : longint) : longint;
function UMax(op1, op2 : longint) : longint;
function UMin(op1, op2 : longint) : longint;

function IS_SET(value, bit : cardinal) : boolean;
procedure SET_BIT(var value : cardinal; bit : cardinal);
procedure REMOVE_BIT(var value : cardinal; bit : cardinal);

function pad_integer(s, num : integer) : string;
function pad_integer_front(s, num : integer) : string;
function pad_string(const s : string; num : integer) : string;
function pad_string_front(const s : string; num : integer) : string;
function trail_number(s : integer) : string;
function findNumber(var s : string) : integer;
function add_chars(num : integer; const s : string; c : char) : string;
function cap(s : string) : string;

function one_argument(argument : string; var arg_first : string) : string;

function number_range(val_from, val_to : integer) : integer;
function number_percent : integer;
function rolldice(num, size : integer):integer;

function mudAnsi(color : integer) : string;

function isName(const name, substr : string) : boolean;
function isNameAny(const name, substr : string) : boolean;
function isNameStart(const name, substr : string) : boolean;

function isObjectName(const name, substr : string) : boolean;
function isNumber(const param : string) : boolean;

function DiffSeconds (const D1, D2 : TDateTime) : Integer;
function DiffMinutes (const D1, D2 : TDateTime) : Integer;
function DiffHours (const D1, D2 : TDateTime) : Integer;
function DiffDays (const D1, D2 : TDateTime) : Integer;

function makedrunk(param : string) : string;

function prep(const str : string) : string;
function removeQuotes(const str : string) : string;
function escape(const str : string) : string;

implementation

uses
  FastStrings,
  constants;

// returns value if min <= value <= max, or min when value < min
// or max when value > max
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

// returns the maximum of the two operands
function UMax(op1, op2 : longint) : longint;
begin
  if (op1 > op2) then
    UMax := op1
  else
    UMax := op2;
end;

// returns the minimum of the two operands
function UMin(op1, op2 : longint) : longint;
begin
  if (op1 < op2) then
    UMin := op1
  else
    UMin := op2;
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
var
	g : string;
begin
  g := inttostr(s);

  Result := g + StringOfChar(' ', num-length(g));
end;

function pad_integer_front(s, num : integer) : string;
var
	g : string;
begin
  g := inttostr(s);

  Result := StringOfChar(' ', num - length(g)) + g;
end;

function pad_string(const s : string; num : integer) : string;
begin
  Result := s + StringOfChar(' ', num - length(s));
end;

function pad_string_front(const s : string; num : integer) : string;
begin
  Result := StringOfChar(' ', num - length(s)) + s;
end;

function trail_number(s : integer):string;
var 
  g : string;
begin
  g := IntToStr(s);
  
  case (s mod 100) of
	  11 : g := g + 'th';
	  12 : g := g + 'th';
		13 : g := g + 'th';
  else
  case (s mod 10) of
    1 : g := g + 'st';
    2 : g := g + 'nd';
    3 : g := g + 'rd';
  else
    g := g + 'th';
  end;
  end;
  
  Result := g;
end;

// Find number in <num>.* format
function findNumber(var s : string) : integer;
var
	g : string;
begin
  if (pos('.',s) = 0) then
    Result := 1
  else
    begin
    g := left(s, '.');
    s := right(s, '.');

    try
      Result := strtoint(g);
    except
      Result := 1;
    end;
    end;
end;

function add_chars(num:integer; const s : string; c : char) : string;
begin
  if (length(s)>num) then
    begin
    Result := s;
    exit;
    end;

  Result := s + StringOfChar(c, num - length(s));
end;

function cap(s : string) : string;
var
	g : integer;
begin
  if (length(s) = 0) then
    begin
    Result := '';
    exit;
    end;

  g := 0;

  repeat
    inc(g);
    if (s[g] = '$') then
      inc(g, 2);
  until (byte(s[g]) in [33..126]) or (length(s) <= g);

  s[g] := upcase(s[g]);
  Result := s;
end;

function one_argument(argument : string; var arg_first : string) : string;
var
	cEnd : char;
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
    Result := '';
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

  Result := copy(argument, p, length(argument) - p + 1);
end;

function number_range(val_from, val_to : integer) : integer;
begin
  Result := random(val_to - val_from) + val_from;
end;

// Random number between 1 - 100
function number_percent() : integer;
begin
  Result := random(100) + 1;
end;

function rolldice(num, size : integer) : integer;
var
	s, a : integer;
begin
  s := 0;
  
  for a:=1 to num do
    inc(s, random(size) + 1);
  
  Result := s;
end;

function mudAnsi(color : integer) : string;
begin
  if (color > 8) then
    Result := '$B$' + inttostr(color - 8)
  else
    Result := '$A$' + inttostr(color);
end;

{ alias for isNameAny }
function isName(const name, substr : string) : boolean;
begin
	Result := isNameAny(name, substr);
end;

{ tests wether substr occurs anywhere in name }
function isNameAny(const name, substr : string) : boolean;
begin
  Result := (Pos(trim(uppercase(substr)), trim(uppercase(name)) ) > 0);
end;

{ tests wether substr occurs at the start of 'name' or at the start of the first noun in 'name' }
function isNameStart(const name, substr : string) : boolean;
{ list of articles, change this if you wish to recompile Grendel for a different language }
const
	articles : array[0..1] of string = ('A', 'THE');

var
	i : integer;
begin
	Result := (Pos(trim(uppercase(substr)), trim(uppercase(name))) = 1);
	
	if (Result = false) then
		begin
		for i := 0 to length(articles) - 1 do
			begin
			Result := (Pos(articles[i] + ' ' + trim(uppercase(substr)), trim(uppercase(name))) = 1);
			
			if (Result) then
				exit;
			end;
		end;
end;

{ tests wether substr occurs at the start of name }
function isNameStartNoun(const name, substr : string) : boolean;
begin
	Result := (Pos(trim(uppercase(substr)), trim(uppercase(name))) = 1);
end;

{Xenon 16/Apr/2001: same as isName() but less strict }
function isObjectName(const name, substr : string) : boolean;
begin
  Result := (Pos(trim(uppercase(substr)), trim(uppercase(name))) > 0);
end;

{Jago 17/Jan/2001 - utility function}
function isNumber(const param : string) : boolean;
begin
  Result := True;
  
  try
    StrToInt(param);
  except
    Result := False;
  end;
end;

// functions borrowed from the Delphi Fundamentals
const
  OneDay         = 1.0;
  OneHour        = OneDay / 24.0;
  OneMinute      = OneHour / 60.0;
  OneSecond      = OneMinute / 60.0;
  OneMillisecond = OneSecond / 1000.0;

function DiffSeconds (const D1, D2 : TDateTime) : Integer;
begin
  Result := Trunc ((D2 - D1) / OneSecond);
end;

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

// Drunken speech - Nemesis
function makedrunk(param : string) : string;
var
	temp : char;
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

function prep(const str : string) : string;
begin
  Result := trim(uppercase(str));
end;

// Strip quotes from string
function removeQuotes(const str : string) : string;
var
  s : string;
  x : integer;
begin
  if (length(str) = 0) then
    begin
    Result := '';
    exit;
    end;
      
  x := 1;
  s := '';
  
  while (x <= length(str)) do
    begin
    if (str[x] = '\') then
      inc(x);
    
    s := s + str[x];
    inc(x);
    end;

  if ((s[1] = '"') or (s[1] = '''')) then
    s[1] := ' ';
  
  if ((s[length(s)] = '"') or (s[length(s)] = '''')) then
    s[length(s)] := ' ';
    
  Result := Trim(s);
end;

function escape(const str : string) : string;
var
  i : integer;
begin
  Result := '';
  
  for i := 1 to length(str) do
    begin
    if (str[i] in ['"','\']) then
      Result := Result + '\';
      
    Result := Result + str[i];
    end;
end;

end.

