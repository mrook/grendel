{
	Summary:
		Grendel Virtual (Stack) Machine
	
	## $Id: gvm.pas,v 1.3 2004/03/04 19:11:03 ***REMOVED*** Exp $
}

unit gvm;


interface


uses 
{$IFDEF WIN32}
	Windows,
{$ENDIF}
	SysUtils, 
	Variants,
	fsys,
	dtypes;


const
  stackSize = 512;


type
  GVMError = procedure(owner : TObject; const errorMsg : string);
	GSystemTrap = procedure(owner : TObject; const msg : string);
	GExternalTrap = function(obj : variant; const member : string) : variant;
	GSignalTrap = procedure(owner : TObject; const signal : string);
	GWaitTrap = function(owner : TObject; const signal : string) : boolean;

  GSignature = record
    resultType : integer;
    paramTypes : array of integer;
  end;

  GExternalMethod = class
    name : string;
    classAddr, methodAddr : pointer;
    signature : GSignature;
  end;

  GSymbol = class
    id : string;
    addr : integer;
  end;

  GCodeBlock = class
		code : array of char;
		codeSize, dataSize : integer;
		symbols : GHashTable;
  end;

	GContext = class
  	stack : array[0..stackSize] of variant;
	  data : array of variant;
	  pc, sp, bp : integer;

    clockTick : integer;

	  owner : TObject;
    block : GCodeBlock;

		function findSymbol(const id : string) : integer;
    procedure setEntryPoint(addr : integer);

		procedure push(v : variant);
		function pop : variant;

		procedure callMethod(classAddr, methodAddr : pointer; signature : GSignature);

    procedure load(cb : GCodeBlock);
		procedure execute;
		
		constructor Create();
		destructor Destroy(); override;
	end;


var
	cmdline : string;
	input : file;
	vmError : GVMError;
	systemTrap : GSystemTrap;
	externalTrap : GExternalTrap;
	signalTrap : GSignalTrap;
	waitTrap : GWaitTrap;
	externalMethods : GHashTable;
	codeCache : GHashTable;


function loadCode(const fname : string) : GCodeBlock;

procedure setVMError(method : GVMError);
procedure setSystemTrap(method : GSystemTrap);
procedure setExternalTrap(method : GExternalTrap);
procedure setSignalTrap(method : GSignalTrap);
procedure setWaitTrap(method : GWaitTrap);

procedure registerExternalMethod(const name : string; classAddr, methodAddr : pointer; const signature : GSignature);


implementation


uses 
	gasmdef;


procedure dummyError(owner : TObject; const msg : string);
begin
  writeln('fatal vm error: ', msg);
end;

procedure dummySystemTrap(owner : TObject; const msg : string);
begin
  writeln('Trap: ', msg);
end;

function dummyExternalTrap(obj : variant; const member : string) : variant;
begin
  Result := Null;
end;

procedure dummySignalTrap(owner : TObject; const signal : string);
begin
end;

function dummyWaitTrap(owner : TObject; const signal : string) : boolean;
begin
  Result := True;
end;

function loadCode(const fname : string) : GCodeBlock;
var
  cb : GCodeBlock;
  input : file;
  sym : GSymbol;
  t : byte;
begin
  Result := nil;
  cb := GCodeBlock(codeCache.get(fname));

  if (cb = nil) then
    begin
    cb := GCodeBlock.Create;
    cb.symbols := GHashTable.Create(128);
    
    codeCache.put(fname, cb);

    assign(input, translateFileName(fname));
    {$I-}
    reset(input, 1);
    {$I+}

    if (IOResult <> 0) then
      begin
      vmError(nil, 'could not open ' + fname);
      exit;
      end;

    blockread(input, cb.codeSize, 4);
    blockread(input, cb.dataSize, 4);

    setLength(cb.code, cb.codeSize);

    blockread(input, cb.code[0], cb.codeSize);

    while (not eof(input)) do
      begin
      sym := GSymbol.Create;

      blockread(input, t, 1);
      setLength(sym.id, t);
      blockread(input, sym.id[1], t);
      blockread(input, sym.addr, 4);

      cb.symbols.put(sym.id, sym);
      end;

    closefile(input);
    end;

  Result := cb;
end;

// GContext
constructor GContext.Create();
begin
	inherited Create();
end;

destructor GContext.Destroy();
begin
	SetLength(data, 0);
	
	inherited Destroy();
end;

function GContext.findSymbol(const id : string) : integer;
var
  sym : GSymbol;
begin
  Result := -1;

  if (block = nil) then
    exit;

  sym := GSymbol(block.symbols.get(id));

  if (sym <> nil) then
    Result := sym.addr;
end;

procedure GContext.setEntryPoint(addr : integer);
begin
  if (addr >= 0) then
    push(pc);

  pc := addr;
end;

procedure GContext.push(v : variant);
begin
  if (sp > stackSize) then
    vmError(owner, 'data stack overflow');

  inc(sp);
  stack[sp] := v;
end;

function GContext.pop : variant;
begin
  if (sp < 0) then
    vmError(owner, 'data stack underflow');

  Result := stack[sp];
  dec(sp);
end;

procedure GContext.load(cb : GCodeBlock);
var
	i : integer;
begin
  sp := -1;
  pc := -1;

  block := cb;
  clockTick := 0;

  if (cb <> nil) then
    begin
    setLength(data, cb.dataSize);

    for i := 0 to cb.dataSize-1 do
      data[i] := 0;
    end
  else
    setLength(data, 0);
end;

procedure GContext.callMethod(classAddr, methodAddr : pointer; signature : GSignature);
var
	i : integer;
  v, vd : variant;
  resstr : string;
begin
  if (methodAddr = nil) then
    exit;
    
  for i := length(signature.ParamTypes) - 1 downto 0 do
    begin
    v := stack[sp - i];

    VarCast(vd, v, signature.ParamTypes[i]);

    case varType(vd) of
      varBoolean: asm
                  xor eax, eax
                  mov ax, vd.TVarData.VBoolean
                  push eax
                  end;
      varInteger: asm
                  mov eax, vd.TVarData.VInteger
                  push eax
                  end;
       varSingle: asm
                  mov eax, vd.TVarData.VSingle
                  push eax
                  end;
       varString: asm
                  mov eax, vd.TVarData.VString
                  push eax
                  end;
    end;
    end;
    
  dec(sp, length(signature.paramTypes));

  asm
    mov eax, classAddr
    test eax, eax
    jz @strresult

    @methodcall:
    push eax

    @strresult:
    mov eax, signature.ResultType
    cmp eax, varString
    jne @call
    lea eax, resstr
    push eax

    @call:
    call methodAddr

    mov edx, signature.ResultType

    cmp edx, varSingle
    je @varSingle

    cmp edx, varInteger
    je @varInteger

    cmp edx, varBoolean
    je @varBoolean

    jmp @end

@varSingle:
    fstp dword ptr vd.TVarData.VSingle
    mov vd.TVarData.VType, varSingle
    jmp @end

@varInteger:
    mov vd.TVarData.VType, varInteger
    mov vd.TVarData.VInteger, eax
    jmp @end

@varBoolean:
    mov vd.TVarData.VType, varBoolean   
    xor ah,ah   
    mov vd.TVarData.VBoolean, ax
    jmp @end

@end:
  end;
  
  if (signature.ResultType = varString) then
    push(resstr)
  else
  if (signature.ResultType <> varEmpty) then
    push(vd);
end;


procedure GContext.Execute;
var
	i : integer;
  f : single;
  p : pchar;
	v1, v2 : variant;
  meth : GExternalMethod;
begin
  if (block = nil) or (pc < 0) or (pc >= block.codeSize) then
    exit;

  try
    while (pc >= 0) and (pc < block.codeSize) do
    case ord(block.code[pc]) of
      _TOF    : begin
                VarCast(v1, pop(), varSingle);
                push(v1);
                inc(pc);
                end;
      _TOI    : begin
                VarCast(v1, pop(), varInteger);
                push(v1);
                inc(pc);
                end;
      _TOS    : begin
                VarCast(v1, pop(), varString);
                push(v1);
                inc(pc);
                end;
      _PUSHI 	: begin
                move(block.code[pc + 1], i, 4);
                inc(pc, 5);
                push(i);
                end;
      _PUSHF  : begin
                move(block.code[pc + 1], f, 4);
                inc(pc, 5);
                push(f);
                end;
      _PUSHS  : begin
                p := @block.code[pc + 1];
                inc(pc, strlen(p) + 2);

                push(string(p));
                end;
       _PUSHR : begin
                move(block.code[pc + 1], i, 4);
                inc(pc, 5);
                push(data[i]);
                end;
        _POPR : begin
                move(block.code[pc + 1], i, 4);
                inc(pc, 5);
                data[i] := pop();
                end;
    _PUSHDISP : begin
                move(block.code[pc + 1], i, 4);
                inc(pc, 5);
                push(stack[bp + i]);
                end;
     _POPDISP : begin
                move(block.code[pc + 1], i, 4);
                inc(pc, 5);
                stack[bp + i] := pop();
                end;
      _ADD		: begin
                v2 := pop();
                v1 := pop();
                push(v1 + v2);
                inc(pc);
                end;
      _SUB		: begin
                v2 := pop();
                v1 := pop();
                push(v1 - v2);
                inc(pc);
                end;
      _MUL		: begin
                v2 := pop();
                v1 := pop();
                push(v1 * v2);
                inc(pc);
                end;
      _DIV		: begin
                v2 := pop();
                v1 := pop();
                push(v1 / v2);
                inc(pc);
                end;
      _NOT    : begin
                push(not pop());
                inc(pc);
                end;
      _AND    : begin
                push(pop() and pop());
                inc(pc);
                end;
      _OR     : begin
                push(pop() or pop());
                inc(pc);
                end;
      _LT     : begin
                v2 := pop();
                v1 := pop();
                push(v1 < v2);
                inc(pc);
                end;
      _GT     : begin
                v2 := pop();
                v1 := pop();
                push(v1 > v2);
                inc(pc);
                end;
      _LTE    : begin
                v2 := pop();
                v1 := pop();
                push(v1 <= v2);
                inc(pc);
                end;
      _GTE    : begin
                v2 := pop();
                v1 := pop();
                push(v1 >= v2);
                inc(pc);
                end;
      _EQ     : begin
                v2 := pop();
                v1 := pop();
                push(v1 = v2);
                inc(pc);
                end;
      _GET		: begin
                v2 := pop();
                v1 := pop();
                push(externalTrap(v1, v2));
                inc(pc);
                end;
      _TRAP		: begin
                systemTrap(owner, pop());
                inc(pc);
                end;
      _SLEEP  : begin
                v1 := pop();

                if (v1 <= 0) then
                  inc(pc)
                else
                  begin
                  push(v1 - 1);
                  break;
                  end;
                end;
      _WAIT   : begin
                v1 := pop();

                if (not waitTrap(owner, v1)) then
                  begin
                  push(v1);
                  break;
                  end
                else
                  inc(pc);
                end;
      _SIGNAL : begin
                v1 := pop();
                inc(pc);
                signalTrap(owner, v1);
                end;
      _RET		: begin
                i := pop();
                pc := i;
                end;
      _CALL 	: begin
                move(block.code[pc + 1], i, 4);

                if (i < 0) or (i > block.codeSize) then
                  vmError(owner, 'procedure call outside of boundary');

                push(pc + 5);					// save return address
                pc := i;
                end;
      _CALLE  : begin
                p := @block.code[pc + 1];
                inc(pc, strlen(p) + 2);

                meth := GExternalMethod(externalMethods.get(string(p)));

                if (meth <> nil) then
                  callMethod(meth.classAddr, meth.methodAddr, meth.signature)
                else
                  vmError(owner, 'unregistered external method "' + p + '"');
                end;
      _JMP    : begin
                move(block.code[pc + 1], i, 4);

                if (i < 0) or (i > block.codeSize) then
                  vmError(owner, 'jump outside of boundary');

                pc := i;
                end;
      _JZ     : begin
                move(block.code[pc + 1], i, 4);
                v1 := pop();

                if (i < 0) or (i > block.codeSize) then
                  vmError(owner, 'jump outside of boundary');

                if (integer(v1) = 0) then
                  pc := i
                else
                  inc(pc, 5);
                end;
      _JNZ    : begin
                move(block.code[pc + 1], i, 4);
                v1 := pop();

                if (i < 0) or (i > block.codeSize) then
                  vmError(owner, 'jump outside of boundary');

                if (integer(v1) <> 0) then
                  pc := i
                else
                  inc(pc, 5);
                end;
      _PUSHBP : begin 
                push(bp);
                inc(pc);
                end;
       _POPBP : begin 
                bp := pop();
                inc(pc);
                end;
       _MBPSP : begin
                sp := bp;
                inc(pc);
                end;
       _MSPBP : begin
                bp := sp;
                inc(pc);
                end;
       _ADDSP : begin
                move(block.code[pc + 1], i, 4);
                inc(sp, i);
                inc(pc, 5);
                end;
       _SUBSP : begin
                move(block.code[pc + 1], i, 4);
                dec(sp, i);
                inc(pc, 5);
                end;
        _MTSD : begin
                move(block.code[pc + 1], i, 4);
                stack[sp - i] := stack[sp];
                inc(pc, 5);
                end;
      	_HALT : pc := block.codeSize;
    else
      inc(pc);
    end;
  except
    on E : Exception do
      begin
      vmError(owner, 'stack error: ' + E.Message);

      // reset state, stop program
      sp := -1;
      bp := 0;
      pc := -1;
      end;
  end;
end;

procedure setVMError(method : GVMError);
begin
  if (Assigned(method)) then
    vmError := method;
end;

procedure setSystemTrap(method : GSystemTrap);
begin
  if (Assigned(method)) then
    systemTrap := method;
end;

procedure setExternalTrap(method : GExternalTrap);
begin
  if (Assigned(method)) then
    externalTrap := method;
end;

procedure setSignalTrap(method : GSignalTrap);
begin
  if (Assigned(method)) then
    signalTrap := method;
end;

procedure setWaitTrap(method : GWaitTrap);
begin
  if (Assigned(method)) then
    waitTrap := method;
end;

procedure registerExternalMethod(const name : string; classAddr, methodAddr : pointer; const signature : GSignature);
var
	meth : GExternalMethod;
begin
  meth := GExternalMethod.Create;

  meth.name := name;
  meth.classAddr := classAddr;
  meth.methodAddr := methodAddr;
  meth.signature := signature;

  externalMethods.put(name, meth);
end;

begin
  DecimalSeparator := '.';

  setVMError(dummyError);
  setSystemTrap(dummySystemTrap);
  setExternalTrap(dummyExternalTrap);
  setSignalTrap(dummySignalTrap);
  setWaitTrap(dummyWaitTrap);

  codeCache := GHashTable.Create(128);
  externalMethods := GHashTable.Create(256);
end.
