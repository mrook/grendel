unit fsys;

interface

uses
    Classes,
    SysUtils;

const
    BUFSIZE = 65536;

type
    GFileReader = class
      fp : TFileStream;
      buffer : array[0..BUFSIZE] of char;
      fpos, fsize : integer;
      feol : boolean;
      line : integer;

      function readChar : char;
      function eof : boolean;
      procedure seek(pos : integer);

      function readLine : string;
      function readInteger : integer;
      function readCardinal : cardinal;
      function readWord : string;
      function readQuoted : string;

      procedure flush;

      constructor Create(fn : string);
      destructor Destroy; override;
    end;

implementation

constructor GFileReader.Create(fn : string);
begin
  inherited Create;

  fp := TFileStream.Create(fn, fmOpenRead);

  fsize := fp.Read(buffer, BUFSIZE);

  fpos := 0;
  line := 1;
  feol := false;
end;

destructor GFileReader.Destroy;
begin
  fp.Free;

  inherited Destroy;
end;

function GFileReader.readChar : char;
var c : char;
begin
  c := buffer[fpos];

  inc(fpos);

  if (fpos >= BUFSIZE) then
    begin
    fsize := fp.Read(buffer, BUFSIZE);
    fpos := 0;
    end;

  if (c = #13) then
    begin
    readChar;
    inc(line);
    feol := true;
    end
  else
    feol := false;

  readChar := c;
end;

function GFileReader.eof : boolean;
begin
  eof := (fpos >= fsize) or (buffer[fpos] = #0);
end;

procedure GFileReader.seek(pos : integer);
begin
  { avoid pos+pos<0, don't want to get tangled in a bug
    *lazy coders grin* - Grimlord }

  if (fpos + pos >= 0) then
    inc(fpos,pos);
end;

function GFileReader.readLine : string;
var buf : string;
    c : char;
begin
  c := ' ';
  buf := '';

  while (c <> #13) do
    begin
    c := readChar;

    if (c <> #13) then
      buf := buf + c;
    end;

  readLine := buf;
end;

function GFileReader.readInteger : integer;
var c : char;
    number : integer;
    sign : boolean;
begin
  c := ' ';

  while (c in [' ', #13]) do
    begin
    if (eof) then
      begin
      Result := 0;
      exit;
      end;

    c := readChar;
    end;

  number := 0;
  sign := false;

  if (c = '+') then
    c := readChar
  else
  if (c = '-') then
    begin
    sign := true;
    c := readChar;
    end;

  if not (c in ['0'..'9']) then
    begin
    Result := 0;
    exit;
    end;

  while (c in ['0'..'9']) do
    begin
    if (eof) then
      begin
      Result := number;
      exit;
      end;

    number := number * 10 + byte(c) - byte('0');
    c := readChar;
    end;

  if (sign) then
    number := 0 - number;

  if (c = '|') then
    inc(number, readInteger);

  Result := number;
end;

function GFileReader.readCardinal : cardinal;
var c : char;
    number : cardinal;
    sign : boolean;
begin
  c := ' ';

  while (c in [' ', #13]) do
    begin
    if (eof) then
      begin
      Result := 0;
      exit;
      end;

    c := readChar;
    end;

  number := 0;
  sign := false;

  if (c = '+') then
    c := readChar
  else
  if (c = '-') then
    begin
    sign := true;
    c := readChar;
    end;

  if not (c in ['0'..'9']) then
    begin
    Result := 0;
    exit;
    end;

  while (c in ['0'..'9']) do
    begin
    if (eof) then
      begin
      Result := number;
      exit;
      end;

    number := number * 10 + byte(c) - byte('0');
    c := readChar;
    end;

  if (sign) then
    number := 0 - number;

  if (c = '|') then
    inc(number, readCardinal);

  Result := number;
end;

function GFileReader.readWord : string;
var word : array[0..255] of char;
    pword : pchar;
    c : char;
begin
  c := ' ';

  while (c in [' ', #13]) do
    begin
    if (eof) then
      begin
      readWord := '';
      exit;
      end;

    c := readChar;
    end;

  if (c = '''') or (c = '"') then
    pword := @word[0]
  else
    begin
    word[0] := c;
    pword := @word[1];
    end;

  repeat
    if (eof) then
      begin
      pword^ := #0;
      readWord := word;
      exit;
      end;

    pword^ := readChar;

    if (pword^ in [' ', '''', #13]) then
      begin
      pword^ := #0;
      readWord := word;
      exit;
      end;

    inc(pword);
  until (pword > word + 255);

  readWord := '';
end;

function GFileReader.readQuoted : string;
var word : array[0..255] of char;
    pword : pchar;
    c : char;
begin
  c := ' ';

  while (c in [' ', #13]) do
    begin
    if (eof) then
      begin
      readQuoted := '';
      exit;
      end;

    if (feol) then
      exit;

    c := readChar;
    end;

  if (c = '''') or (c = '"') then
    pword := @word[0]
  else
    begin
    word[0] := c;
    pword := @word[1];
    end;

  repeat
    if (eof) then
      begin
      pword^ := #0;
      readQuoted := word;
      exit;
      end;

    pword^ := readChar;

    if (pword^ in ['''', #13]) then
      begin
      pword^ := #0;
      readQuoted := word;
      exit;
      end;

    inc(pword);
  until (pword > word + 255);

  readQuoted := '';
end;

procedure GFileReader.flush;
begin
  if (buffer = nil) then
    exit;

  fillchar(buffer, BUFSIZE, 0);
end;

end.
