unit debug;

interface

uses
  SysUtils;
  
//procedure outputError(addr : pointer);
procedure outputError(E : EExternal);
procedure readMapFile(module, fname : string);

implementation

uses
{$IFDEF WIN32}
    Windows,
    memcheck,
{$ENDIF}
    Math,
    Classes,
    strip,
    fsys,
    console,
    mudsystem;

type
    TSymbol = class
      section : cardinal;
      startAddress : cardinal;
      name : string;
      module : string;
    end;

    TLine = class
      section, address : cardinal;
      linenr : cardinal;
      filename : string;
      module : string;
    end;

var
   lines, symbols : TList;

{$IFDEF WIN32}
function IMAGE_FIRST_SECTION(ntheader : PImageNtHeaders) : PImageSectionHeader;
begin
  Result := pointer(integer(ntheader) + (sizeof(ntheader^.Signature) + sizeof(ntheader^.FileHeader)) + ntheader^.FileHeader.SizeofOptionalHeader);
end;

function GetLogicalAddress(addr : pointer;  szModule : pchar; len : cardinal; var section, offset : cardinal) : boolean;
var
   hMod : HMODULE;
   mbi : MEMORY_BASIC_INFORMATION;
   pDosHdr : PImageDosHeader;
   pNtHdr : PImageNtHeaders;
   pSection : PImageSectionHeader;
   i, rva : cardinal;
   sectionStart, sectionEnd : cardinal;
begin
  if (VirtualQuery(addr, mbi, sizeof(mbi)) = 0) then
    begin
    Result := false;
    exit;
    end;

  hMod := HMODULE(mbi.AllocationBase);

  if (GetModuleFileName(hMod, szModule, len) = 0) then
    begin
    Result := false;
    exit;
    end;

  // Point to the DOS header in memory
  pDosHdr := PImageDosHeader(hMod);

  // From the DOS header, find the NT (PE) header
  pNtHdr := PImageNtHeaders(hMod + pDosHdr^._lfanew);

  pSection := IMAGE_FIRST_SECTION(pNtHdr);

  rva := cardinal(addr) - cardinal(hMod); // RVA is offset from module load address

  // Iterate through the section table, looking for the one that encompasses
  // the linear address.
  for i := 0 to pNtHdr^.FileHeader.NumberOfSections - 1 do
    begin
    sectionStart := pSection^.VirtualAddress;
    sectionEnd := sectionStart + Max(pSection^.SizeOfRawData, pSection^.Misc.VirtualSize);

    if (rva >= sectionStart) or (rva <= sectionEnd) then
      begin
      section := i + 1;
      offset := rva - sectionStart;
      Result := true;
      exit;
      end;

    inc(pSection);
    end;

  Result := false;
end;
{$ENDIF}

function findSymbol(module : string; section, addr : cardinal) : TSymbol;
var
   a : integer;
   res, symbol : TSymbol;
begin
  res := nil;

  for a := 0 to symbols.count - 1 do
    begin
    symbol := symbols[a];

    if (symbol.module = module) and (symbol.section = section) and (addr >= symbol.startAddress) then
      begin
      if (res <> nil) and (res.startAddress > symbol.startAddress) then
        continue;

      res := symbol;
      end;
    end;

  Result := res;
end;

function findLine(module : string; section, offset : cardinal) : TLine;
var
   a : integer;
   res, line : TLine;
begin
  res := nil;

  for a := 0 to lines.count - 1 do
    begin
    line := lines[a];

    if (line.module = module) and (offset >= line.address) and (line.section = section) then
      begin
      if (res <> nil) and (res.address > line.address) then
        continue;

      res := line;
      end;
    end;

  Result := res;
end;

function hexRead(s : string) : cardinal;
var
   d : integer;
   x : cardinal;
begin
  d := 1;
  x := 0;

  while (d <= length(s)) do
    begin
    inc(x, strtoint('$' + s[d] + s[d+1]) shl ((7 - d) * 4));
    inc(d, 2);
    end;

  Result := x;
end;

procedure readMapfile(module, fname : string);
var
   af : GFileReader;
   s, g : string;
   symbol : TSymbol;
   line : TLine;
   temp : string;
begin
  try
    af := GFileReader.Create(fname);
  except
    writeConsole('Could not load mapfile, symbol info disabled.');
    exit;
  end;

  repeat
    s := af.readLine();
  until (pos('Address', s) > 0) and (pos('Publics by Value', s) > 0);

  repeat
    s := af.readLine();
  until (trim(s) <> '');

  while (pos('Line numbers for',s) = 0) do
    begin
    g := trim(s);

    if (g <> '') then
      begin
      symbol := TSymbol.Create;

      symbol.module := module;
      symbol.section := strtointdef('$' + left(g, ':'), 0);

      g := right(g, ':');
      symbol.startAddress := hexRead(left(g, ' '));

      symbol.name := trim(right(g, ' '));

      symbols.add(symbol);
      end;

    s := af.readLine();
    end;

  while (true) do
    begin
    if (af.eof()) then
      break;

    temp := left(right(s, '('), ')');
    
    repeat
      s := af.readLine();
    until (length(trim(s)) > 0);

    repeat
      g := trim(s);

      while (length(g) > 0) do
        begin
        line := TLine.Create;

        line.module := module;
        line.filename := temp;
        line.linenr := strtointdef(left(g, ' '), 0);

        g := right(g, ' ');
        line.section := strtointdef('$' + left(g, ':'), 0);

        g := right(g, ':');
        line.address := strtointdef('$' + left(g, ' '), 0);

        lines.add(line);

        if (pos(' ', g) = 0) then
          break;

        g := trim(right(g, ' '));
        end;

      s := af.readLine();
    until (pos('Line numbers for', s) > 0) or (pos('Bound resource files', s) > 0) or (pos('Program entryp point', s) > 0);
    
    if (pos('Bound resource files', s) > 0) or (pos('Program entryp point', s) > 0) then
      break;
    end;

  af.Free();
end;

procedure showAddress(addr : pointer);
var
   section, offset : cardinal;
   modu : array[0..1023] of char;
   symbol : TSymbol;
   line : TLine;
   symboln, linen : string;
begin
{$IFDEF WIN32}
  GetLogicalAddress(addr, modu, 1024, section, offset);
  
  symbol := findSymbol(ExtractFileName(modu), section, offset);
  line := findLine(ExtractFileName(modu), section, offset);

  if (symbol <> nil) then
    symboln := symbol.name
  else
    symboln := 'no symbol';

  if (line <> nil) then
    linen := line.filename + ':' + IntToStr(line.linenr)
  else
    linen := 'no line';

  writeConsole(linen + ' (' + symboln + ') (' + ExtractFileName(modu) + '@' + IntToHex(offset, 8) + ') (loaded at ' + IntToHex(cardinal(addr), 8) + ')');
{$ELSE}
  writeConsole(IntToHex(integer(addr), 8));
{$ENDIF}
end;

procedure outputError(E : EExternal);
var
{$IFDEF WIN32}
   st : TCallStack;
{$ENDIF}
   a : integer;
   addr : pointer;
begin
{$IFDEF WIN32}
  addr := E.ExceptionRecord.ExceptionAddress;
  writeConsole('Win32 exception detected.');
  writeConsole('Exception message: "' + E.Message + '".');
  
  try
    writeConsole('Call stack follows:');
    showAddress(addr);

    FillCallStack(st, false);

    for a := 0 to 1 do
      begin
      if (st[a] = nil) then
        continue;

      showAddress(st[a]);
      end;
  except
    writeConsole('Unable to read call stack.');
  end;
{$ELSE}
  writeConsole('Exception detected, debugging disabled on this platform.');
{$ENDIF}
end;

begin
  symbols := TList.Create;
  lines := TList.Create;

  readMapFile('grendel.exe', 'grendel.map');
  readMapfile('core.bpl', 'core.map');
end.

