
(* lexical analyzer template (TP Lex V3.0), V1.0 3-2-91 AG *)

(* global definitions: *)

  (* Lexical analyzer for the sample Yacc program in Expr.y. *)


type 
			Keyword = record
				kw : string;
				state : Integer;
			end;

const 
			KWSize = 30;
			KWTable : array[1..KWSize] of Keyword = (
																							(kw:'true'; state:_TRUE), 
																							(kw:'false'; state:_FALSE),
																							(kw:'if'; state:_IF),
																							(kw:'else'; state:_ELSE),
																							(kw:'&&'; state:_AND),
																							(kw:'||'; state:_OR),
																							(kw:'!'; state:_NOT),
																							(kw:'>'; state:_RELGT),
																							(kw:'<'; state:_RELLT),
																							(kw:'>='; state:_RELGTE),
																							(kw:'=<'; state:_RELLTE),
																							(kw:'=='; state:_RELEQ),
																							(kw:'break'; state:_BREAK),
																							(kw:'continue'; state:_CONTINUE),
																							(kw:'return'; state:_RETURN),
																							(kw:'do'; state:_DO),
																							(kw:'sleep'; state:_SLEEP),
																							(kw:'wait'; state:_WAIT),
																							(kw:'signal'; state:_SIGNAL),
																							(kw:'while'; state:_WHILE),
																							(kw:'for'; state:_FOR),
																							(kw:'void'; state:_VOID),
																							(kw:'bool'; state:_INT),
																							(kw:'int'; state:_INT),
																							(kw:'float'; state:_FLOAT),
																							(kw:'string'; state:_STRING),
																							(kw:'external'; state:_EXTERNAL),
																							(kw:'asm'; state:_ASM),
																							(kw:'require'; state:_REQUIRE),
																							(kw:'export'; state:_EXPORT)
																					 	  );







const INITIAL = 2;
const LINEMODE = 4;
const COMMENT = 6;


function yylex : Integer;

procedure yyaction ( yyruleno : Integer );
  (* local definitions: *)

  var result : integer;

begin
  (* actions: *)
  case yyruleno of
  1:
                 														begin
																					  val(yytext, yylval.yyInteger, result);

																						if (result = 0) then
				  															      return(INT)
																						else
																							return(ILLEGAL);
																						end;

  2:
                            								begin
																					  val(yytext, yylval.yySingle, result);

																						if (result = 0) then
				  															      return(FLOAT)
																						else
																							return(ILLEGAL);
																						end;

  3:
                                              		begin
	          for result := 1 to KWSize do 
	            begin
	            if (uppercase(yytext) = uppercase(KWtable[result].kw)) then 
	              begin	
	              return(KWtable[result].state);
								exit;
								end;
	            end;
	            
						varName := yytext;
						return(IDENTIFIER);
  	        end;

  4:
                          		;

  5:
                              begin
                              start(COMMENT);
                              end;
                              
  6:
                              begin
                              start(INITIAL);
                              end;
                              
  7:
                              ;

  8:
             		 	 	  				begin
															start(LINEMODE);
											        returnc(yytext[1]);
															end;

  9:
                  						begin
															varName := yytext;
															return(LINE);
															end;
															
  10:
              								begin
															start(INITIAL);
											        returnc(yytext[1]);
															end;

  11:
                   				begin
        returnc(yytext[1]);
        end;

  end;
end(*yyaction*);

(* DFA table: *)

type YYTRec = record
                cc : set of Char;
                s  : Integer;
              end;

const

yynmarks   = 35;
yynmatches = 35;
yyntrans   = 74;
yynstates  = 36;

yyk : array [1..yynmarks] of Integer = (
  { 0: }
  { 1: }
  { 2: }
  { 3: }
  { 4: }
  9,
  { 5: }
  9,
  { 6: }
  { 7: }
  { 8: }
  1,
  11,
  { 9: }
  3,
  11,
  { 10: }
  3,
  11,
  { 11: }
  11,
  { 12: }
  11,
  { 13: }
  3,
  11,
  { 14: }
  11,
  { 15: }
  4,
  11,
  { 16: }
  4,
  { 17: }
  11,
  { 18: }
  8,
  11,
  { 19: }
  11,
  { 20: }
  9,
  11,
  { 21: }
  11,
  { 22: }
  10,
  11,
  { 23: }
  7,
  { 24: }
  7,
  { 25: }
  1,
  { 26: }
  { 27: }
  3,
  { 28: }
  3,
  { 29: }
  5,
  { 30: }
  9,
  { 31: }
  { 32: }
  { 33: }
  6,
  { 34: }
  2,
  { 35: }
  11
);

yym : array [1..yynmatches] of Integer = (
{ 0: }
{ 1: }
{ 2: }
{ 3: }
{ 4: }
  9,
{ 5: }
  9,
{ 6: }
{ 7: }
{ 8: }
  1,
  11,
{ 9: }
  3,
  11,
{ 10: }
  3,
  11,
{ 11: }
  11,
{ 12: }
  11,
{ 13: }
  3,
  11,
{ 14: }
  11,
{ 15: }
  4,
  11,
{ 16: }
  4,
{ 17: }
  11,
{ 18: }
  8,
  11,
{ 19: }
  11,
{ 20: }
  9,
  11,
{ 21: }
  11,
{ 22: }
  10,
  11,
{ 23: }
  7,
{ 24: }
  7,
{ 25: }
  1,
{ 26: }
{ 27: }
  3,
{ 28: }
  3,
{ 29: }
  5,
{ 30: }
  9,
{ 31: }
{ 32: }
{ 33: }
  6,
{ 34: }
  2,
{ 35: }
  11
);

yyt : array [1..yyntrans] of YYTrec = (
{ 0: }
{ 1: }
{ 2: }
  ( cc: [ #1..#8,#11,#12,#14..#31,'#'..'%',''''..'.',
            ':',';','?','@','['..'`','{','}'..#255 ]; s: 19),
  ( cc: [ #9,#13,' ' ]; s: 15),
  ( cc: [ #10 ]; s: 16),
  ( cc: [ '!','<' ]; s: 10),
  ( cc: [ '"' ]; s: 18),
  ( cc: [ '&' ]; s: 11),
  ( cc: [ '/' ]; s: 17),
  ( cc: [ '0'..'9' ]; s: 8),
  ( cc: [ '=' ]; s: 14),
  ( cc: [ '>' ]; s: 13),
  ( cc: [ 'A'..'Z','a'..'z' ]; s: 9),
  ( cc: [ '|' ]; s: 12),
{ 3: }
  ( cc: [ #1..#8,#11,#12,#14..#31,'#'..'%',''''..'.',
            ':',';','?','@','['..'`','{','}'..#255 ]; s: 19),
  ( cc: [ #9,#13,' ' ]; s: 15),
  ( cc: [ #10 ]; s: 16),
  ( cc: [ '!','<' ]; s: 10),
  ( cc: [ '"' ]; s: 18),
  ( cc: [ '&' ]; s: 11),
  ( cc: [ '/' ]; s: 17),
  ( cc: [ '0'..'9' ]; s: 8),
  ( cc: [ '=' ]; s: 14),
  ( cc: [ '>' ]; s: 13),
  ( cc: [ 'A'..'Z','a'..'z' ]; s: 9),
  ( cc: [ '|' ]; s: 12),
{ 4: }
  ( cc: [ #1..#9,#11..#31,'#'..'%','@','^','{','}',
            #127..#255 ]; s: 19),
  ( cc: [ ' ','!',''''..'<','?','A'..'[',']','_'..'z',
            '~' ]; s: 20),
  ( cc: [ '"' ]; s: 22),
  ( cc: [ '&' ]; s: 35),
  ( cc: [ '=' ]; s: 20),
  ( cc: [ '>' ]; s: 20),
  ( cc: [ '\' ]; s: 21),
  ( cc: [ '|' ]; s: 20),
{ 5: }
  ( cc: [ #1..#9,#11..#31,'#'..'%','@','^','{','}',
            #127..#255 ]; s: 19),
  ( cc: [ ' ','!',''''..'<','?','A'..'[',']','_'..'z',
            '~' ]; s: 20),
  ( cc: [ '"' ]; s: 22),
  ( cc: [ '&' ]; s: 35),
  ( cc: [ '=' ]; s: 20),
  ( cc: [ '>' ]; s: 20),
  ( cc: [ '\' ]; s: 21),
  ( cc: [ '|' ]; s: 20),
{ 6: }
  ( cc: [ #1..#9,#11..')','+'..#255 ]; s: 24),
  ( cc: [ '*' ]; s: 23),
{ 7: }
  ( cc: [ #1..#9,#11..')','+'..#255 ]; s: 24),
  ( cc: [ '*' ]; s: 23),
{ 8: }
  ( cc: [ '.' ]; s: 26),
  ( cc: [ '0'..'9' ]; s: 25),
{ 9: }
  ( cc: [ '0'..'9','A'..'Z','_','a'..'z' ]; s: 27),
{ 10: }
{ 11: }
  ( cc: [ '&' ]; s: 28),
{ 12: }
  ( cc: [ '|' ]; s: 28),
{ 13: }
  ( cc: [ '=' ]; s: 28),
{ 14: }
  ( cc: [ '<','=' ]; s: 28),
{ 15: }
{ 16: }
{ 17: }
  ( cc: [ '*' ]; s: 29),
{ 18: }
{ 19: }
{ 20: }
  ( cc: [ ' ','!',''''..'<','?','A'..'[',']','_'..'z',
            '~' ]; s: 30),
  ( cc: [ '&' ]; s: 31),
  ( cc: [ '=' ]; s: 30),
  ( cc: [ '>' ]; s: 30),
  ( cc: [ '\' ]; s: 32),
  ( cc: [ '|' ]; s: 30),
{ 21: }
  ( cc: [ '"' ]; s: 30),
{ 22: }
{ 23: }
  ( cc: [ '/' ]; s: 33),
{ 24: }
{ 25: }
  ( cc: [ '.' ]; s: 26),
  ( cc: [ '0'..'9' ]; s: 25),
{ 26: }
  ( cc: [ '0'..'9' ]; s: 34),
{ 27: }
  ( cc: [ '0'..'9','A'..'Z','_','a'..'z' ]; s: 27),
{ 28: }
{ 29: }
{ 30: }
  ( cc: [ ' ','!',''''..'<','?','A'..'[',']','_'..'z',
            '~' ]; s: 30),
  ( cc: [ '&' ]; s: 31),
  ( cc: [ '=' ]; s: 30),
  ( cc: [ '>' ]; s: 30),
  ( cc: [ '\' ]; s: 32),
  ( cc: [ '|' ]; s: 30),
{ 31: }
  ( cc: [ '&' ]; s: 30),
{ 32: }
  ( cc: [ '"' ]; s: 30),
{ 33: }
{ 34: }
  ( cc: [ '0'..'9' ]; s: 34),
{ 35: }
  ( cc: [ '&' ]; s: 30)
);

yykl : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 1,
{ 2: } 1,
{ 3: } 1,
{ 4: } 1,
{ 5: } 2,
{ 6: } 3,
{ 7: } 3,
{ 8: } 3,
{ 9: } 5,
{ 10: } 7,
{ 11: } 9,
{ 12: } 10,
{ 13: } 11,
{ 14: } 13,
{ 15: } 14,
{ 16: } 16,
{ 17: } 17,
{ 18: } 18,
{ 19: } 20,
{ 20: } 21,
{ 21: } 23,
{ 22: } 24,
{ 23: } 26,
{ 24: } 27,
{ 25: } 28,
{ 26: } 29,
{ 27: } 29,
{ 28: } 30,
{ 29: } 31,
{ 30: } 32,
{ 31: } 33,
{ 32: } 33,
{ 33: } 33,
{ 34: } 34,
{ 35: } 35
);

yykh : array [0..yynstates-1] of Integer = (
{ 0: } 0,
{ 1: } 0,
{ 2: } 0,
{ 3: } 0,
{ 4: } 1,
{ 5: } 2,
{ 6: } 2,
{ 7: } 2,
{ 8: } 4,
{ 9: } 6,
{ 10: } 8,
{ 11: } 9,
{ 12: } 10,
{ 13: } 12,
{ 14: } 13,
{ 15: } 15,
{ 16: } 16,
{ 17: } 17,
{ 18: } 19,
{ 19: } 20,
{ 20: } 22,
{ 21: } 23,
{ 22: } 25,
{ 23: } 26,
{ 24: } 27,
{ 25: } 28,
{ 26: } 28,
{ 27: } 29,
{ 28: } 30,
{ 29: } 31,
{ 30: } 32,
{ 31: } 32,
{ 32: } 32,
{ 33: } 33,
{ 34: } 34,
{ 35: } 35
);

yyml : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 1,
{ 2: } 1,
{ 3: } 1,
{ 4: } 1,
{ 5: } 2,
{ 6: } 3,
{ 7: } 3,
{ 8: } 3,
{ 9: } 5,
{ 10: } 7,
{ 11: } 9,
{ 12: } 10,
{ 13: } 11,
{ 14: } 13,
{ 15: } 14,
{ 16: } 16,
{ 17: } 17,
{ 18: } 18,
{ 19: } 20,
{ 20: } 21,
{ 21: } 23,
{ 22: } 24,
{ 23: } 26,
{ 24: } 27,
{ 25: } 28,
{ 26: } 29,
{ 27: } 29,
{ 28: } 30,
{ 29: } 31,
{ 30: } 32,
{ 31: } 33,
{ 32: } 33,
{ 33: } 33,
{ 34: } 34,
{ 35: } 35
);

yymh : array [0..yynstates-1] of Integer = (
{ 0: } 0,
{ 1: } 0,
{ 2: } 0,
{ 3: } 0,
{ 4: } 1,
{ 5: } 2,
{ 6: } 2,
{ 7: } 2,
{ 8: } 4,
{ 9: } 6,
{ 10: } 8,
{ 11: } 9,
{ 12: } 10,
{ 13: } 12,
{ 14: } 13,
{ 15: } 15,
{ 16: } 16,
{ 17: } 17,
{ 18: } 19,
{ 19: } 20,
{ 20: } 22,
{ 21: } 23,
{ 22: } 25,
{ 23: } 26,
{ 24: } 27,
{ 25: } 28,
{ 26: } 28,
{ 27: } 29,
{ 28: } 30,
{ 29: } 31,
{ 30: } 32,
{ 31: } 32,
{ 32: } 32,
{ 33: } 33,
{ 34: } 34,
{ 35: } 35
);

yytl : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 1,
{ 2: } 1,
{ 3: } 13,
{ 4: } 25,
{ 5: } 33,
{ 6: } 41,
{ 7: } 43,
{ 8: } 45,
{ 9: } 47,
{ 10: } 48,
{ 11: } 48,
{ 12: } 49,
{ 13: } 50,
{ 14: } 51,
{ 15: } 52,
{ 16: } 52,
{ 17: } 52,
{ 18: } 53,
{ 19: } 53,
{ 20: } 53,
{ 21: } 59,
{ 22: } 60,
{ 23: } 60,
{ 24: } 61,
{ 25: } 61,
{ 26: } 63,
{ 27: } 64,
{ 28: } 65,
{ 29: } 65,
{ 30: } 65,
{ 31: } 71,
{ 32: } 72,
{ 33: } 73,
{ 34: } 73,
{ 35: } 74
);

yyth : array [0..yynstates-1] of Integer = (
{ 0: } 0,
{ 1: } 0,
{ 2: } 12,
{ 3: } 24,
{ 4: } 32,
{ 5: } 40,
{ 6: } 42,
{ 7: } 44,
{ 8: } 46,
{ 9: } 47,
{ 10: } 47,
{ 11: } 48,
{ 12: } 49,
{ 13: } 50,
{ 14: } 51,
{ 15: } 51,
{ 16: } 51,
{ 17: } 52,
{ 18: } 52,
{ 19: } 52,
{ 20: } 58,
{ 21: } 59,
{ 22: } 59,
{ 23: } 60,
{ 24: } 60,
{ 25: } 62,
{ 26: } 63,
{ 27: } 64,
{ 28: } 64,
{ 29: } 64,
{ 30: } 70,
{ 31: } 71,
{ 32: } 72,
{ 33: } 72,
{ 34: } 73,
{ 35: } 74
);


var yyn : Integer;

label start, scan, action;

begin

start:

  (* initialize: *)

  yynew;

scan:

  (* mark positions and matches: *)

  for yyn := yykl[yystate] to     yykh[yystate] do yymark(yyk[yyn]);
  for yyn := yymh[yystate] downto yyml[yystate] do yymatch(yym[yyn]);

  if yytl[yystate]>yyth[yystate] then goto action; (* dead state *)

  (* get next character: *)

  yyscan;

  (* determine action: *)

  yyn := yytl[yystate];
  while (yyn<=yyth[yystate]) and not (yyactchar in yyt[yyn].cc) do inc(yyn);
  if yyn>yyth[yystate] then goto action;
    (* no transition on yyactchar in this state *)

  (* switch to new state: *)

  yystate := yyt[yyn].s;

  goto scan;

action:

  (* execute action: *)

  if yyfind(yyrule) then
    begin
      yyaction(yyrule);
      if yyreject then goto action;
    end
  else if not yydefault and yywrap then
    begin
      yyclear;
      return(0);
    end;

  if not yydone then goto start;

  yylex := yyretval;

end(*yylex*);

