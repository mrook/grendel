unit gvm;
interface

uses SysUtils, dtypes;

const
	stackSize = 512;

type
	GSystemTrap = procedure(msg : string);
	GExternalTrap = function(obj : variant; member : string) : variant;

  GSignature = record
    resultType : integer;
    paramTypes : array of integer;
  end;

  GExternalMethod = class
    name : string;
    classAddr, methodAddr : pointer;
    signature : GSignature;
  end;

	GCodeBlock = class
		code : array of char;
		codeSize, dataSize : integer;
	end;

	GContext = class	
  	stack, returns : array[0..stackSize] of variant;
	  data : array of variant;
	  pc, rp, sp : integer;

		block : GCodeBlock;

		procedure push(v : variant);
		function pop : variant;
		procedure pushr(v : variant);
		function popr : variant;

		procedure callMethod(classAddr, methodAddr : pointer; signature : GSignature);

    procedure Load(blck : GCodeBlock);
		procedure Execute;
	end;

var
  cmdline : string;
  input : file;
  systemTrap : GSystemTrap;
  externalTrap : GExternalTrap;
  externalMethods : GHashTable;
	codeCache : GHashTable;

function loadCode(fname : string) : GCodeBlock;

procedure setSystemTrap(method : GSystemTrap);
procedure setExternalTrap(method : GExternalTrap);

procedure registerExternalMethod(name : string; classAddr, methodAddr : pointer; signature : GSignature);

implementation

uses gasmdef;

procedure vmError(msg : string);
begin
  writeln('fatal vm error: ', msg);
  exit;
end;

procedure dummySystemTrap(msg : string);
begin
  writeln('Trap: ', msg);
end;

function dummyExternalTrap(obj : variant; member : string) : variant;
begin
  Result := Null;
end;

function loadCode(fname : string) : GCodeBlock;
var
	cb : GCodeBlock;
  input : file;
begin
  cb := GCodeBlock(codeCache.get(fname));

  if (cb = nil) then
    begin
	  assign(input, fname);
	  {$I-}
	  reset(input, 1);
	  {$I+}
  
	  if (IOResult <> 0) then
			vmError('Could not open ' + fname);

    cb := GCodeBlock.Create;

	  blockread(input, cb.codeSize, 4);
	  blockread(input, cb.dataSize, 4);

	  setLength(cb.code, cb.codeSize);
  
	  blockread(input, cb.code[0], cb.codeSize);

	  closefile(input);
	  codeCache.put(fname, cb);
    end;

	Result := cb;
end;

// GContext
procedure GContext.push(v : variant);
begin
  if (sp > stackSize) then
    vmError('data stack overflow');

  stack[sp] := v;
  inc(sp);
end;

function GContext.pop : variant;
begin
  if (sp < 0) then
    vmError('data stack underflow');

  dec(sp);

  Result := stack[sp];
end;

procedure GContext.pushr(v : variant);
begin
  if (rp > stackSize) then
    vmError('address stack overflow');

  returns[rp] := v;
  inc(rp);
end;

function GContext.popr : variant;
begin
  if (rp < 0) then
    vmError('address stack underflow');

  dec(rp);

  Result := returns[rp];
end;

procedure GContext.Load(blck : GCodeBlock);
var
	i : integer;
begin
  sp := 0;
  rp := 0;
  pc := 0;

  setLength(data, blck.dataSize);

  for i := 0 to blck.dataSize-1 do
    data[i] := 0;

  block := blck;
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
	writeln('Starting execution, codesize is ', block.codeSize, ' byte(s), datasize is ', block.dataSize, ' element(s).');

  try

    while (pc < block.codeSize) do
      begin
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
                  v1 := pop();
                  v2 := pop();
                  push(v1 + v2);
                  inc(pc);
                  end;
        _SUB		: begin
                  v1 := pop();
                  v2 := pop();
                  push(v1 - v2);
                  inc(pc);
                  end;
        _MUL		: begin
                  v1 := pop();
                  v2 := pop();
                  push(v1 * v2);
                  inc(pc);
                  end;
        _DIV		: begin
                  v1 := pop();
                  v2 := pop();
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
                  systemTrap(pop());
                  inc(pc);
                  end;
        _RET		: begin
                  i := popr();
                  pc := i;
                  end;
        _CALL 	: begin
                  move(block.code[pc + 1], i, 4);
	
                  if (i < 0) or (i > block.codeSize) then
                    vmError('procedure call outside of boundary');

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
                    vmError('unregistered external method "' + p + '"');
                  end;
        _JMP    : begin
                  move(block.code[pc + 1], i, 4);

                  if (i < 0) or (i > block.codeSize) then
                    vmError('jump outside of boundary');

                  pc := i;
                  end;
        _JZ     : begin
                  move(block.code[pc + 1], i, 4);
                  v1 := pop();

                  if (i < 0) or (i > block.codeSize) then
                    vmError('jump outside of boundary');

                  if (not v1) then
                    pc := i
                  else
                    inc(pc, 5);
                  end;
        _JNZ    : begin
                  move(block.code[pc + 1], i, 4);
                  v1 := pop();

                  if (i < 0) or (i > block.codeSize) then
                    vmError('jump outside of boundary');

                  if (v1) then
                    pc := i
                  else
                    inc(pc, 5);
                  end;
        _HALT : break;
      else
        inc(pc);
      end;
      end;

  except
    on E : EVariantError do
      vmError('stack error: ' + E.Message);
  end;

  writeln('Execution halted.');

  if (sp > 0) then
    begin
    writeln(#13#10'Stack layout on termination:'#13#10);

    for i := 0 to sp - 1 do
      begin
      writeln('[', i, '] ', stack[i]);
      end;
    end;

  writeln(#13#10'Data segment:'#13#10);

  for i := 0 to block.dataSize - 1 do
    begin
    writeln('[R', i, '] ', data[i]);
    end;
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

  setSystemTrap(dummySystemTrap);
  setExternalTrap(dummyExternalTrap);

  codeCache := GHashTable.Create(1024);
  externalMethods := GHashTable.Create(256);
end.
