// $Id: fsys.pas,v 1.8 2001/07/14 13:26:20 ***REMOVED*** Exp $

unit fsys;

interface

uses
    Classes,
    SysUtils;

const
    BUFSIZE = 65536 * 16;
    MAX_LINESIZE = 1024;

type
    GFileReader = class
      fp : TFileStream;
      fname : string;
      buffer : array[0..BUFSIZE] of char;
      fpos, fsize : integer;
      feol : boolean;
      line : integer;

      function readChar : char;
      function eof() : boolean;
      function eol() : boolean;
      procedure seek(pos : integer);

      function readLine() : string;
      function readInteger() : integer;
      function readCardinal() : cardinal;
      function readToken() : string;

      procedure flush;

      constructor Create(fn : string);
      destructor Destroy; override;
    end;


function translateFileName(fn : string) : string;

implementation

uses
  dtypes;


function translateFileName(fn : string) : string;
begin
{$IFDEF LINUX}
  Result := StringReplace(fn, '\', '/', [rfReplaceAll]);
{$ELSE}
  Result := fn;
{$ENDIF}
end;

constructor GFileReader.Create(fn : string);
begin
  inherited Create;

  fn := translateFileName(fn);

  fp := TFileStream.Create(fn, fmOpenRead);
  fname := fn;

  fsize := fp.Read(buffer, BUFSIZE);
  if (fsize = 0) then
    raise GException.Create('fsys.pas:GFileReader.Create', '0 length file');

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

function GFileReader.eol : boolean;
begin
  Result := feol;
end;

procedure GFileReader.seek(pos : integer);
begin
  { avoid pos+pos<0, don't want to get tangled in a bug
    *lazy coders grin* - Grimlord }

  if (fpos + pos >= 0) then
    inc(fpos,pos);
end;

function GFileReader.readLine : string;
var
   chars : array[0..MAX_LINESIZE] of char;
   pos : integer;
   c : char;
begin
  c := ' ';
  pos := 0;

  while (not eof()) do
    begin
    c := readChar;

    if (c <> #13) and (c <> #10) then
      begin
      chars[pos] := c;
      inc(pos);

      if (pos >= MAX_LINESIZE) then 
        begin
	raise GException.Create('fsys.pas:GFileReader.Create', 'max linesize exceeded in ' + fname);

        pos := MAX_LINESIZE;
        break;
        end;
      end
    else
      break;
    end;

  chars[pos] := #0;

  readLine := chars;
end;

function GFileReader.readInteger : integer;
var c : char;
    number : integer;
    sign : boolean;
begin
  c := ' ';

  while (c in [' ', #13, #10]) do
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

  while (c in [' ', #13, #10]) do
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

function GFileReader.readToken() :  string;
var
  word : array[0..255] of char;
  quoted : boolean;
  pword : pchar;
  c : char;
begin
  c := ' ';

  while (c in [' ', #13, #10]) do
    begin
    if (eof) then
      begin
      Result := '';
      exit;
      end;

    c := readChar;
    end;

  if (c = '''') or (c = '"') then
    begin
    quoted := true;
    pword := @word[0];
    end
  else
    begin
    quoted := false;
    word[0] := c;
    pword := @word[1];
    end;

  repeat
    if (eof) then
      begin
      pword^ := #0;
      Result := word;
      exit;
      end;

    pword^ := readChar;

    if (quoted) and (pword^ in ['''', '"', #13, #10]) then
      begin
      pword^ := #0;
      Result := word;
      exit;
      end
    else
    if (not quoted) and (pword^ in [' ', #13, #10]) then
      begin
      pword^ := #0;
      Result := word;
      exit;
      end;

    inc(pword);
  until (pword > word + 255);

  Result := '';
end;

procedure GFileReader.flush;
begin
  if (buffer = nil) then
    exit;

  fillchar(buffer, BUFSIZE, 0);
end;

end.
