unit gvm;
interface

uses SysUtils, dtypes;

const
	stackSize = 512;

type
	GTrap = procedure(msg : string);
	GExternalVar = function(obj : variant; member : string) : variant;

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

    procedure Load(blck : GCodeBlock);
		procedure Execute;
	end;

	GVirtualMachine = class
		constructor Create;	
	end;

var
  cmdline : string;
  input : file;
	trap : GTrap;
  callback : GExternalVar;
	codeCache : GHashTable;

function loadCode(fname : string) : GCodeBlock;

implementation

uses gasmdef;

procedure vmError(msg : string);
begin
  writeln('fatal vm error: ', msg);
  exit;
end;

procedure dummyTrap(msg : string);
begin
  writeln('Trap: ', msg);
end;

function dummyCallback(obj : variant; member : string) : variant;
begin
  Result := 50;
end;

function loadCode(fname : string) : GCodeBlock;
var
	cd : GCodeBlock;
  input : file;
begin
  cd := GCodeBlock(codeCache.get(fname));

  if (cd = nil) then
    begin
	  assign(input, fname);
	  {$I-}
	  reset(input, 1);
	  {$I+}
  
	  if (IOResult <> 0) then
			vmError('Could not open ' + fname);

    cd := GCodeBlock.Create;

	  blockread(input, cd.codeSize, 4);
	  blockread(input, cd.dataSize, 4);

	  setLength(cd.code, cd.codeSize);
  
	  blockread(input, cd.code[0], cd.codeSize);

	  closefile(input);
	  codeCache.put(fname, cd);
    end;

	Result := cd;
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

procedure GContext.Execute;
var
	i : integer;
  r : byte;
  p : pchar;
	v1, v2 : variant;
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
        _ITOS		: begin
                  push(IntToStr(pop()));
                  inc(pc);
                  end;
        _BTOS		: begin
                  push(IntToStr(pop()));
                  inc(pc);
                  end;
        _PUSHI 	: begin
                  move(block.code[pc + 1], i, 4);
                  inc(pc, 5);
                  push(i);
                  end;
        _PUSHR  : begin
                  move(block.code[pc + 1], r, 1);
                  inc(pc, 2);
                  push(data[r]);
                  end;
        _PUSHS  : begin
                  p := @block.code[pc + 1];
                  inc(pc, strlen(p) + 2);

                  push(string(p));
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
                  v1 := pop() - pop();
                  push(v1);
                  inc(pc);
                  end;
        _MUL		: begin
                  v1 := pop() * pop();
                  push(v1);
                  inc(pc);
                  end;
        _DIV		: begin
                  v1 := pop() / pop();
                  push(v1);
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
                  push(pop() < pop());
                  inc(pc);
                  end;
        _GT     : begin
                  push(pop() > pop());
                  inc(pc);
                  end;
        _LTE    : begin
                  push(pop() <= pop());
                  inc(pc);
                  end;
        _GTE    : begin
                  push(pop() >= pop());
                  inc(pc);
                  end;
        _EQ     : begin
                  v1 := pop();
                  v2 := pop();
                  push(v1 = v2);
                  inc(pc);
                  end;
        _GET		: begin
                  push(callback(pop(), pop()));
                  inc(pc);
                  end;
        _GETR		: begin
                  move(block.code[pc + 1], r, 1);
                  inc(pc, 2);
                  pop();
                  end;
        _TRAP		: begin
                  trap(pop());
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
      vmError('stack conversion error');
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


// GVirtualMachine
constructor GVirtualMachine.Create;
begin
  inherited Create;

  trap := dummyTrap;
  callback := dummyCallback;  
end;


begin
  trap := dummyTrap;
  callback := dummyCallback;

  codeCache := GHashTable.Create(1024);
end.
