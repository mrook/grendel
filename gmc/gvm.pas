unit gvm;
interface

uses SysUtils, dtypes, Windows;

const
	stackSize = 512;

type
  GVMError = procedure(owner : TObject; errorMsg : string);
	GSystemTrap = procedure(owner : TObject; msg : string);
	GExternalTrap = function(obj : variant; member : string) : variant;
	GSignalTrap = procedure(owner : TObject; signal : string);
	GWaitTrap = function(owner : TObject; signal : string) : boolean;

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
  	stack, returns : array[0..stackSize] of variant;
	  data : array of variant;
	  pc, rp, sp : integer;

    clockTick : integer;

	  owner : TObject;
    block : GCodeBlock;

		function findSymbol(id : string) : integer;
    function setEntryPoint(id : string) : boolean;

		procedure push(v : variant);
		function pop : variant;
		procedure pushr(v : variant);
		function popr : variant;

		procedure callMethod(classAddr, methodAddr : pointer; signature : GSignature);

    procedure load(cb : GCodeBlock);
		procedure execute;
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

function loadCode(fname : string) : GCodeBlock;

procedure setVMError(method : GVMError);
procedure setSystemTrap(method : GSystemTrap);
procedure setExternalTrap(method : GExternalTrap);
procedure setSignalTrap(method : GSignalTrap);
procedure setWaitTrap(method : GWaitTrap);

procedure registerExternalMethod(name : string; classAddr, methodAddr : pointer; signature : GSignature);

implementation

uses gasmdef;

procedure dummyError(owner : TObject; msg : string);
begin
  writeln('fatal vm error: ', msg);
end;

procedure dummySystemTrap(owner : TObject; msg : string);
begin
  writeln('Trap: ', msg);
end;

function dummyExternalTrap(obj : variant; member : string) : variant;
begin
  Result := Null;
end;

procedure dummySignalTrap(owner : TObject; signal : string);
begin
end;

function dummyWaitTrap(owner : TObject; signal : string) : boolean;
begin
  Result := True;
end;

function loadCode(fname : string) : GCodeBlock;
var
  cb : GCodeBlock;
	i : integer;
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

    assign(input, fname);
    {$I-}
    reset(input, 1);
    {$I+}

    if (IOResult <> 0) then
      exit;

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
function GContext.findSymbol(id : string) : integer;
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

function GContext.setEntryPoint(id : string) : boolean;
var
	i : integer;
begin
  Result := false;

  if (block = nil) then
    exit;

  i := findSymbol(id);

  if (i >= 0) then
    begin
    Result := true;
    pushr(block.codeSize);
    end;

  pc := i;
end;

procedure GContext.push(v : variant);
begin
  if (sp > stackSize) then
    vmError(owner, 'data stack overflow');

  stack[sp] := v;
  inc(sp);
end;

function GContext.pop : variant;
begin
  if (sp < 0) then
    vmError(owner, 'data stack underflow');

  dec(sp);

  Result := stack[sp];
end;

procedure GContext.pushr(v : variant);
begin
  if (rp > stackSize) then
    vmError(owner, 'address stack overflow');

  returns[rp] := v;
  inc(rp);
end;

function GContext.popr : variant;
begin
  if (rp < 0) then
    vmError(owner, 'address stack underflow');

  dec(rp);

  Result := returns[rp];
end;

procedure GContext.load(cb : GCodeBlock);
var
	i : integer;
begin
  sp := 0;
  rp := 0;
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
begin
  if (methodAddr = nil) then
    exit;

  for i := length(signature.ParamTypes) downto 1 do
    begin
    v := pop();

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

  asm
    mov eax, classAddr
    test eax, eax
    jz @call

    @methodcall:
    push eax

    @call:
    call methodAddr

    mov edx, signature.ResultType

    cmp edx, varSingle
    je @varSingle

    cmp edx, varInteger
    je @varInteger

    jmp @end

@varSingle:
    fstp dword ptr vd.TVarData.VSingle
    mov vd.TVarData.VType, varSingle
    jmp @end

@varInteger:
    mov vd.TVarData.VType, varInteger
    mov vd.TVarData.VInteger, eax
    jmp @end

@end:
  end;

  if (signature.ResultType <> varEmpty) then
    push(vd);
end;


procedure GContext.Execute;
var
	i : integer;
  f : single;
  r : byte;
  p : pchar;
	v1, v2 : variant;
  meth : GExternalMethod;
begin
  if (block = nil) or (pc < 0) or (pc >= block.codeSize) then
    exit;

  writeln('GMC DEBUG: executing ', integer(owner), ' at ', pc);

  try
    while (pc < block.codeSize) do
    case ord(block.code[pc]) of
      _GETC		: begin
                push(cmdline);
                inc(pc);
                end;
      _ITOF   : begin
                VarCast(v1, pop(), varSingle);
                push(v1);
                inc(pc);
                end;
      _FTOI   : begin
                VarCast(v1, pop(), varInteger);
                push(v1);
                inc(pc);
                end;
      _ITOS		: begin
                push(IntToStr(pop()));
                inc(pc);
                end;
      _BTOS		: begin
                push(IntToStr(pop()));
                inc(pc);
                end;
      _FTOS   : begin
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
      _PUSHR  : begin
                move(block.code[pc + 1], r, 1);
                inc(pc, 2);
                push(data[r]);
                end;
      _POPR   : begin
                move(block.code[pc + 1], r, 1);
                inc(pc, 2);
                data[r] := pop();
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
      _GETR		: begin
                move(block.code[pc + 1], r, 1);
                inc(pc, 2);
                pop();
                end;
      _TRAP		: begin
                systemTrap(owner, pop());
                inc(pc);
                end;
      _SLEEP  : begin
                v1 := pop();

                if (clockTick >= v1) then
                  begin
                  clockTick := 0;
                  inc(pc);
                  end
                else
                  begin
                  inc(clockTick);
                  push(v1);
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
                i := popr();
                pc := i;
                end;
      _CALL 	: begin
                move(block.code[pc + 1], i, 4);

                if (i < 0) or (i > block.codeSize) then
                  vmError(owner, 'procedure call outside of boundary');

                pushr(pc + 5);					// save return address
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
      _HALT : pc := block.codeSize;
    else
      inc(pc);
    end;
  except
    on E : EVariantError do
      vmError(owner, 'stack error: ' + E.Message);
  end;

{  writeln('Execution halted.');

  if (sp > 0) then
    begin
    writeln(#13#10'Stack layout on termination:'#13#10);

    for i := 0 to sp - 1 do
      begin
      writeln('[', i, '] ', stack[i]);
      end;
    end;

  writeln(#13#10'Data segment:'#13#10);

  for i := 0 to dataSize - 1 do
    begin
    writeln('[R', i, '] ', data[i]);
    end; }
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

procedure registerExternalMethod(name : string; classAddr, methodAddr : pointer; signature : GSignature);
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
