///////////////////////////////////////////////////////////////////////////////
// This unit must be included in first string in "uses" clause of your project
//  main module (*.dpr). You can reach it through   View/Project Source.
//  You Must run application under any Debugger, that can recieve Debug Messages.
//  For example MS WinDbg available for free download from Microsoft.
//
unit MemDebug;

interface

procedure enableMemoryDebug();

function GetUsedSize: Integer;

function sGetMem(Size: Integer): Pointer;
function sFreeMem(P: Pointer): Integer;
function sReallocMem(P: Pointer; Size: Integer): Pointer;

procedure dumpMemory();

implementation

uses
  dtypes,
  MemCheck,
  debug,
  SysUtils,
  Windows;

// from \SOURCE\RTL\SYS\getmem.inc
type
  PUsed = ^TUsed;
  TUsed = record
    sizeFlags: Integer;
  end;

  GMemoryBlock = class
    block : pointer;
    classType : boolean;
    size : integer;
    stack : TCallStack;
//    alloc1, alloc2 : integer;

    function isEqual(other : GMemoryBlock) : boolean;
  end;

const
  cAlign        = 4;
  cThisUsedFlag = 2;
  cPrevFreeFlag = 1;
  cFillerFlag   = $80000000;
  cFlags        = cThisUsedFlag or cPrevFreeFlag or cFillerFlag;
  cSmallSize    = 4*1024;
  cDecommitMin  = 15*1024;
  peOffset = $3c;

  codename = 'CODE';
  datename = 'DATA';


var
  memoryBlocks : GHashTable;
  AddressOfNewInstance, AddressOfNewAnsiString : pointer;
// Base Address of 'Code' sectiom
  codeSub : Integer = 0;
//IMapLookup helper

  OldMMngr : TMemoryManager;
  MMngr : TMemoryManager =
  (GetMem: sGetMem;FreeMem:sFreeMem;ReallocMem:sReallocMem);

  Used : Integer = 0;
  ShowMemDebug : Boolean = False;

function GetUsedSize: Integer;
begin
  Result := memoryBlocks.size();
end;

type
  PSectArray = ^TSectArray;
  TSectArray = array[0..200] of TImageSectionHeader;

procedure SetMDebugState(aState : Boolean);
begin
  ShowMemDebug := aState;
end;

procedure OutputFormatTheStr(formatStr : PChar; const args : array of DWORD);
var
  Buff : array[0..255] of char;
begin
  wvsprintf(Buff, formatStr,  PChar(@args[0]));
  OutputDebugString(Buff);
end;

function GetBlockSize(p: Pointer):Integer;
begin
  Result := (PUsed(PChar(p) - sizeof(TUsed)).sizeFlags and not cFlags) - sizeof(TUsed);
end;

function CallerIsNewAnsiString: boolean;	//NewAnsiString has no stack frame
asm
	cmp ebp, 0	//this can happen when there are no stack frames
	je @@no
	mov eax, [ebp + 8]
	sub eax, 13
	cmp eax, AddressOfNewAnsiString
	je @@yes
	@@no:
	mov eax, 0
	ret
	@@yes:
	mov eax, 1
end;

function CallerIsNewInstance: boolean;	//TObject.NewInstance has no stack frame
asm
	cmp ebp, 0	//this can happen when there are no stack frames
	je @@no
	{$IFNDEF VER140}
	mov eax, [ebp + 8]
	sub eax, 9
	{$ELSE}
	mov eax, [EBP + 12]
	sub eax, 15
	{$ENDIF}
	cmp eax, AddressOfNewInstance;
	je @@yes
	@@no:
	mov eax, 0
	ret
	@@yes:
	mov eax, 1
end;

function sGetMem(Size: Integer): Pointer;
var
  allocFrom1, allocFrom2 : Integer;
  buf : array[0..128] of Char;
  block : GMemoryBlock;
begin
	if CallerIsNewAnsiString then
		//We do not log memory allocations for reference counted strings. This would take time and some leaks would be reported	uselessly. However, if you want to know about this, you can just uncomment this part
		begin
  	Result := SysGetMem(Size);
  	exit;
		end
	else	
  if CallerIsNewInstance then
    begin
    Result := SysGetMem(Size);

    SetMemoryManager(OldMMngr);

    asm
      cmp ebp, 0	//this can happen when there are no stack frames
      je @@EndOfStack
      mov eax, [ebp + 4]
      sub eax, 4
      mov allocFrom1, eax

      mov eax, [ebp]
      cmp eax, ebp
      jb @@EndOfStack
      mov eax, [eax + 4]
      sub eax, 4
      jmp @@End
      @@EndOfStack:
      mov eax, $FFFF

      @@End:
      mov allocFrom2, eax
    end;

    block := GMemoryBlock.Create();
    block.size := Size;
    block.classType := true;
    block.block := Result;
    FillCallStack(block.stack, 1);
    //block.alloc1 := allocFrom1;
    //block.alloc2 := allocFrom2;
    memoryBlocks.put(DWORD(Result), block);

    GetMemoryManager(OldMMngr);
    SetMemoryManager(MMngr);
    end
  else
    begin
    Result := SysGetMem(Size);

    SetMemoryManager(OldMMngr);

    asm
      cmp ebp, 0	//this can happen when there are no stack frames
      je @@EndOfStack
      mov eax, [ebp + 4]
      sub eax, 4
      mov allocFrom1, eax

      mov eax, [ebp]
      cmp eax, ebp
      jb @@EndOfStack
      mov eax, [eax + 4]
      sub eax, 4
      jmp @@End
      @@EndOfStack:
      mov eax, $FFFF

      mov allocFrom2, eax
      @@End:
    end;

    block := GMemoryBlock.Create();
    block.size := Size;
    block.classType := false;
    block.block := Result;
    FillCallStack(block.stack, 1);
    memoryBlocks.put(DWORD(Result), block);

    GetMemoryManager(OldMMngr);
    SetMemoryManager(MMngr);
    end;

(*  if ShowMemDebug then
    begin
    asm
    	cmp ebp, 0	//this can happen when there are no stack frames
    	je @@EndOfStack
    	mov eax, [ebp + 4]
        sub eax, 4
    	jmp @@End
    	@@EndOfStack:
    	mov eax, $FFFF
    	@@End:

	    mov allocFrom, eax
    end;

    strpcopy(buf, returnAddress(pointer(allocFrom)));
    OutputFormatTheStr('Alloc %d byte(s) at %s', [Size, integer(@buf[0])]);
    end; *)

end;

function sFreeMem(P: Pointer): Integer;
var
  OldSize : Integer;
begin
  OldSize := GetBlockSize(p);
  Used := Used - OldSize;

  SetMemoryManager(OldMMngr);

  memoryBlocks.remove(cardinal(p));

  GetMemoryManager(OldMMngr);
  SetMemoryManager(MMngr);

(*  if ShowMemDebug then
    OutputFormatTheStr(#13#10'total = 0x%08X; --Free--- = 0x%08X, Addr = 0x%08X',[Used, OldSize, DWORD(P)]); *)
    
  Result := SysFreeMem(P);

(*  if(theMapLookup <> nil) then
  begin
    theMapLookup.RemoveAllocUnit(DWORD(P));
  end; *)
end;

function sReallocMem(P: Pointer; Size: Integer): Pointer;
var
  OldSize : Integer;
  AllocSize : Integer;
begin
  OldSize := GetBlockSize(p);
  Result := SysReallocMem(P, Size);
  AllocSize := GetBlockSize(Result);
  Used := Used + AllocSize - OldSize;

(*  if ShowMemDebug then
    OutputFormatTheStr(#13#10'total = 0x%08X; ReAllocat = 0x%08X, Addr = 0x%08X to 0x%08X, Addr = 0x%08X',
      [Used, OldSize, DWORD(P), AllocSize, DWORD(Result)]); *)

(*  if(theMapLookup <> nil) then
  begin
    theMapLookup.ReallocUnit(DWORD(P), DWORD(Result), AllocSize);
  end; *)
end;

procedure dumpMemory();
var
  f : TextFile;
  block : GMemoryBlock;
  iterator : GIterator;
  lastBlock : GMemoryBlock;
  i, count, total : integer;
begin
  SetMemoryManager(OldMMngr);
  
  AssignFile(f, 'memdebug.txt');
  Rewrite(f);

  lastBlock := nil;
  block := nil;
  total := 0;
  count := 0;
  iterator := memoryBlocks.iterator();

  while (iterator.hasNext()) do
    begin
    block := GMemoryBlock(iterator.next());

    if (lastBlock = nil) or (not lastBlock.isEqual(block)) then
      begin
      writeln(f, 'Block of size ', block.size, ', total ', count * block.size);

      if (block.classType) then
        try
          writeln(f, 'Block is class: ', TObject(block.block).ClassName);
        except
        end;

      i := 0;
      
      try
        while (i < StoredCallStackDepth) and (block.stack[i] <> nil) do
          begin
          writeln(f, returnAddress(block.stack[i]));
          inc(i);
          end;
      except
      end;

      lastBlock := block;
      count := 0;
      end;

    inc(count);
    inc(total, block.size);
    end;
    
  iterator.Free();

  if (block <> nil) then
    begin
    writeln(f, 'Block of size ', block.size, ', total ', count * block.size);

    if (block.classType) then
      try
        writeln(f, 'Block is class: ', TObject(block.block).ClassName);
      except
      end;

    i := 0;

    try
      while (i < StoredCallStackDepth) and (block.stack[i] <> nil) do
        begin
        writeln(f, returnAddress(block.stack[i]));
        inc(i);
        end;
    except
    end;
    end;

  writeln(f, #13#10'Total leaked: ', total);
  CloseFile(f);

  memoryBlocks.clear();
  memoryBLocks.Free();
end;

function GMemoryBlock.isEqual(other : GMemoryBlock) : boolean;
begin
  Result := true;

  if (other.classType <> classType) then
    Result := false;

  if (other.size <> size) then
    Result := false;
end;

procedure enableMemoryDebug();
begin
  memoryBlocks := GHashTable.Create(32768);

  GetMemoryManager(OldMMngr);
  SetMemoryManager(MMngr);

  AddressOfNewInstance := pointer($40003A3C);
  AddressOfNewAnsiString:= pointer($40004BA8);
//  AddressOfNewAnsiString := @System._NewAnsiString;
end;

end.
