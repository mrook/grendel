unit gasmdef;

interface

type
  opcode_trans = record
                   keyword : string;
                   opcode : byte;
                 end;

const
  _NOP = $70;
  _HALT = $71;
  _TRAP = $72;
	_GETC = $73;

	_ADD = $80;
	_SUB = $81;
	_MUL = $82;
	_DIV = $83;

	_AND = $90;
	_OR = $91;
	_LT = $92;
	_GT = $93;
	_LTE = $94;
	_GTE = $95;
	_EQ = $96;

	_JMP = $A0;
	_JNZ = $A1;
	_JZ = $A2;
	_CALL = $A3;
  _RET = $A4;

	_PUSHI = $B0;
	_PUSHR = $B1;
	_PUSHS = $B2;

	_POPR = $C0;
  _GET = $C1;
  _GETR = $C2;

	_ITOS = $D0;
	_BTOS = $D1;

  opcodeNum = 28;
	
	opcodes : array[1..opcodeNum] of opcode_trans = (
                                                (keyword:'NOP'; opcode:_NOP),
                                                (keyword:'HALT'; opcode:_HALT),
                                                (keyword:'TRAP'; opcode:_TRAP),
                                                (keyword:'GETC'; opcode:_GETC),

                                                (keyword:'ADD'; opcode:_ADD),
                                                (keyword:'SUB'; opcode:_SUB),
                                                (keyword:'MUL'; opcode:_MUL),
                                                (keyword:'DIV'; opcode:_DIV),

                                                (keyword:'AND'; opcode:_AND),
                                                (keyword:'OR'; opcode:_OR),
                                                (keyword:'LT'; opcode:_LT),
                                                (keyword:'GT'; opcode:_GT),
                                                (keyword:'LTE'; opcode:_LTE),
                                                (keyword:'GTE'; opcode:_GTE),
                                                (keyword:'EQ'; opcode:_EQ),

																								(keyword:'JMP'; opcode:_JMP),
																								(keyword:'JNZ'; opcode:_JNZ),
																								(keyword:'JZ'; opcode:_JZ),
                                                (keyword:'CALL'; opcode:_CALL),
                                                (keyword:'RET'; opcode:_RET),

																								(keyword:'PUSHI'; opcode:_PUSHI),
																								(keyword:'PUSHR'; opcode:_PUSHR),
																								(keyword:'PUSHS'; opcode:_PUSHS),

																								(keyword:'POPR'; opcode:_POPR),
                                                (keyword:'GET'; opcode:_GET),
                                                (keyword:'GETR'; opcode:_GETR),

																								(keyword:'ITOS'; opcode:_ITOS),
																								(keyword:'BTOS'; opcode:_BTOS)
                                                );



implementation

end.
