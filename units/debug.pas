unit debug;

interface

procedure outputError(addr : pointer);

implementation

uses
    Windows,
    Math,
    SysUtils,
    Classes,
    strip,
    memcheck,
    mudsystem;

type
    TSymbol = class
      section : cardinal;
      startAddress : cardinal;
      name : string;
    end;

    TLine = class
      section, address : cardinal;
      linenr : cardinal;
      filename : string;
    end;

var
   lines, symbols : TList;


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

function findSymbol(section, addr : cardinal) : TSymbol;
var
   a : integer;
   res, symbol : TSymbol;
begin
  res := nil;

  for a := 0 to symbols.count - 1 do
    begin
    symbol := symbols[a];

    if (symbol.section = section) and (addr >= symbol.startAddress) then
      begin
      if (res <> nil) and (res.startAddress > symbol.startAddress) then
        continue;

      res := symbol;
      end;
    end;

  Result := res;
end;

function findLine(section, offset : cardinal) : TLine;
var
   a : integer;
   res, line : TLine;
begin
  res := nil;

  for a := 0 to lines.count - 1 do
    begin
    line := lines[a];

    if (offset >= line.address) and (line.section = section) then
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

procedure readMapfile;
var
   f : textfile;
   s, g : string;
   symbol : TSymbol;
   line : TLine;
   changed : boolean;
   a : integer;
   temp : string;
begin
  assignfile(f, 'grendel.map');

  {$I-}
  reset(f);
  {$I+}

  if (IOResult <> 0) then
    begin
    write_console('Could not load mapfile, symbol info disabled.');
    exit;
    end;

  repeat
    readln(f, s);
  until (pos('Address', s) > 0) and (pos('Publics by Name', s) > 0);

  repeat
    readln(f, s);
  until (trim(s) <> '');

  repeat
    g := trim(s);

    if (g <> '') then
      begin
      symbol := TSymbol.Create;

      symbol.section := strtointdef('$' + stripl(g, ':'), 0);

      g := striprbeg(g, ':');
      symbol.startAddress := hexRead(stripl(g, ' '));

      symbol.name := trim(striprbeg(g, ' '));

      symbols.add(symbol);
      end;

    readln(f, s);
  until (s = '');

  while (true) do
    begin
    repeat
      readln(f, s);
    until (pos('Line numbers for', s) > 0) or (eof(f));

    if (eof(f)) then
      break;

    temp := stripl(striprbeg(s, '('), ')');

    repeat
      readln(f, s);
    until (trim(s) <> '');

    repeat
      g := trim(s);

      while (g <> '') do
        begin
        line := TLine.Create;

        line.filename := temp;
        line.linenr := strtointdef(stripl(g, ' '), 0);

        g := striprbeg(g, ' ');
        line.section := strtointdef('$' + stripl(g, ':'), 0);

        g := striprbeg(g, ':');
        line.address := strtointdef('$' + stripl(g, ' '), 0);

        lines.add(line);

        if (pos(' ', g) = 0) then
          break;

        g := trim(striprbeg(g, ' '));
        end;

      readln(f, s);
    until (s = '');
    end;

  closefile(f);
end;

procedure showAddress(addr : pointer);
var
   section, offset : cardinal;
   modu : array[0..1023] of char;
   symbol : TSymbol;
   line : TLine;
   symboln, linen : string;
begin
  GetLogicalAddress(addr, modu, 1024, section, offset);

  symbol := findSymbol(section, offset);
  line := findLine(section, offset);

  if (symbol <> nil) then
    symboln := symbol.name
  else
    symboln := 'no symbol';

  if (line <> nil) then
    linen := IntToStr(line.linenr) + ' (' + line.filename + ')'
  else
    linen := 'no line';

  write_console(symboln + ':' + linen + ' (' + ExtractFileName(modu) + '@' + IntToHex(offset, 8) + ')');
end;

procedure outputError(addr : pointer);
var
   st : TCallStack;
   a : integer;
begin
  write_console('Win32 exception detected, call stack follows:');
  showAddress(addr);

  FillCallStack(st, false);

  for a := 0 to 1 do
    begin
    if (st[a] = nil) then
      continue;

    showAddress(st[a]);
    end;
end;

begin
  symbols := TList.Create;
  lines := TList.Create;

  readMapfile;
end.
