unit util;

interface

uses
    SysUtils,
    ansiio;

function URange(min, value, max : longint) : longint;
function UMax(value, max : longint) : longint;
function UMin(value, min : longint) : longint;

function IS_SET(value, bit : integer) : boolean;
procedure SET_BIT(var value : integer; bit : integer);
procedure REMOVE_BIT(var value : integer; bit : integer);

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

implementation

uses
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

function IS_SET(value, bit : integer) : boolean;
begin
  IS_SET := ((value and bit) = bit);
end;

procedure SET_BIT(var value : integer; bit : integer);
begin
  value := value or bit;
end;

procedure REMOVE_BIT(var value : integer; bit : integer);
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
  until (byte(s[g]) in [33..126]);

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
    if (argument[p] = cEnd) then
      begin
      inc(p);
      break;
      end;

    arg_first := concat(arg_first, argument[p]);

    inc(p);
    inc(count);
    end;

  while (p <= length(argument)) and (argument[p] = ' ') do
    inc(p);

  one_argument := copy(argument, p, length(argument) - p + 1);
end;

function number_range(val_from, val_to : integer) : integer;
begin
  number_range := ((random(val_to - val_from) + val_from) + (random(val_to) - val_from)) div 2;
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

end.
