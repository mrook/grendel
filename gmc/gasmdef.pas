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
	_SLEEP = $73;
	_WAIT = $74;
	_SIGNAL = $75;

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
	_PUSHDISP = $B3;
	_POPDISP = $B4;
  _PUSHR = $B5;
	_POPR = $B6;
  _GET = $B7;

  _ITOF = $D0;
  _FTOI = $D1;
	_ITOS = $D2;
	_BTOS = $D3;
	_FTOS = $D4;
	
	_PUSHBP = $E0;
	_POPBP = $E1;
	_MBPSP = $E2;
	_MSPBP = $E3;
	_ADDSP = $E4;
	_SUBSP = $E5;
	_MTSD = $E6;

  opcodeNum = 43;
	
	opcodes : array[1..opcodeNum] of opcode_trans = (
                                                (keyword:'NOP'; opcode:_NOP),
                                                (keyword:'HALT'; opcode:_HALT),
                                                (keyword:'TRAP'; opcode:_TRAP),
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
																								(keyword:'PUSHDISP'; opcode:_PUSHDISP),
																								(keyword:'POPDISP'; opcode:_POPDISP),
																								(keyword:'PUSHR'; opcode:_PUSHR),
																								(keyword:'POPR'; opcode:_POPR),
                                                (keyword:'GET'; opcode:_GET),

																								(keyword:'ITOF'; opcode:_ITOF),
																								(keyword:'FTOI'; opcode:_FTOI),
																								(keyword:'ITOS'; opcode:_ITOS),
																								(keyword:'BTOS'; opcode:_BTOS),
																								(keyword:'FTOS'; opcode:_FTOS),

																								(keyword:'PUSHBP'; opcode:_PUSHBP),
																								(keyword:'POPBP'; opcode:_POPBP),
																								(keyword:'MBPSP'; opcode:_MBPSP),
																								(keyword:'MSPBP'; opcode:_MSPBP),
																								(keyword:'ADDSP'; opcode:_ADDSP),
																								(keyword:'SUBSP'; opcode:_SUBSP),
																								(keyword:'MTSD'; opcode:_MTSD)
                                                );


implementation

end.
