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
	_SLEEP = $74;
	_WAIT = $75;
	_SIGNAL = $76;

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
  _CALLE = $A4;
  _RET = $A5;

	_PUSHI = $B0;
  _PUSHF = $B1;
	_PUSHS = $B2;
	_PUSHR = $B3;

	_POPR = $C0;
  _GET = $C1;
  _GETR = $C2;

  _ITOF = $D0;
  _FTOI = $D1;
	_ITOS = $D2;
	_BTOS = $D3;
	_FTOS = $D4;

  opcodeNum = 36;
	
	opcodes : array[1..opcodeNum] of opcode_trans = (
                                                (keyword:'NOP'; opcode:_NOP),
                                                (keyword:'HALT'; opcode:_HALT),
                                                (keyword:'TRAP'; opcode:_TRAP),
                                                (keyword:'GETC'; opcode:_GETC),
                                                (keyword:'SLEEP'; opcode:_SLEEP),
                                                (keyword:'WAIT'; opcode:_WAIT),
                                                (keyword:'SIGNAL'; opcode:_SIGNAL),

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
                                                (keyword:'CALLE'; opcode:_CALLE),
                                                (keyword:'RET'; opcode:_RET),

																								(keyword:'PUSHI'; opcode:_PUSHI),
																								(keyword:'PUSHF'; opcode:_PUSHF),
																								(keyword:'PUSHS'; opcode:_PUSHS),
																								(keyword:'PUSHR'; opcode:_PUSHR),

																								(keyword:'POPR'; opcode:_POPR),
                                                (keyword:'GET'; opcode:_GET),
                                                (keyword:'GETR'; opcode:_GETR),

																								(keyword:'ITOF'; opcode:_ITOF),
																								(keyword:'FTOI'; opcode:_FTOI),
																								(keyword:'ITOS'; opcode:_ITOS),
																								(keyword:'BTOS'; opcode:_BTOS),
																								(keyword:'FTOS'; opcode:_FTOS)
                                                );



implementation

end.
