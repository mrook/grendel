
  (* Lexical analyzer for the sample Yacc program in Expr.y. *)

%{

type 
			Keyword = record
				kw : string;
				state : Integer;
			end;

const 
			KWSize = 25;
			KWTable : array[1..KWSize] of Keyword = (
																							(kw:'true'; state:_TRUE), 
																							(kw:'false'; state:_FALSE),
																							(kw:'if'; state:_IF),
																							(kw:'else'; state:_ELSE),
																							(kw:'&&'; state:_AND),
																							(kw:'||'; state:_OR),
																							(kw:'>'; state:_RELGT),
																							(kw:'<'; state:_RELLT),
																							(kw:'>='; state:_RELGTE),
																							(kw:'=<'; state:_RELLTE),
																							(kw:'=='; state:_RELEQ),
																							(kw:'break'; state:_BREAK),
																							(kw:'continue'; state:_CONTINUE),
																							(kw:'return'; state:_RETURN),
																							(kw:'do'; state:_DO),
																							(kw:'while'; state:_WHILE),
																							(kw:'for'; state:_FOR),
																							(kw:'void'; state:_VOID),
																							(kw:'bool'; state:_BOOL),
																							(kw:'char'; state:_CHAR),
																							(kw:'int'; state:_INT),
																							(kw:'float'; state:_FLOAT),
																							(kw:'string'; state:_STRING),
																							(kw:'external'; state:_EXTERNAL),
																							(kw:'asm'; state:_ASM)
																					 	  );

%}

ALPHA				[A-Za-z]
DIGIT				[0-9]
DIGITS			{DIGIT}+

ALPHANUM    {ALPHA}|{DIGIT}

SEP					" "
SEPS				{SEPS}*

BOOLOP			"&&"|"||"|"<"|">"|"=<"|">="|"=="
RESERV			"!"|"*"|"("|")"|","|"\~"|"|"|"["|"]"
EXTRA				"_"|"-"

ALL					{ALPHANUM}|{DIGIT}|{BOOLOP}|{RESERV}|{EXTRA}|{SEP}

%start INITIAL LINEMODE

%%

  var result : integer;

<INITIAL>{DIGITS}(\.{DIGITS})?([Ee][+-]?{DIGITS})?	begin
																					  val(yytext, yylval.yyInteger, result);

																						if (result = 0) then
				  															      return(NUM)
																						else
																							return(ILLEGAL);
																						end;

<INITIAL>{ALPHA}({ALPHANUM}|{EXTRA})*|{BOOLOP}		begin
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

<INITIAL>" "|\t|\r             		;

<INITIAL>"\""		 	 	  				begin
															start(LINEMODE);
											        returnc(yytext[1]);
															end;

<LINEMODE>({ALL})*						begin
															varName := yytext;
															return(LINE);
															end;

<LINEMODE>"\""								begin
															start(INITIAL);
											        returnc(yytext[1]);
															end;

<INITIAL,LINEMODE>\n					inc(yylinenum);

<INITIAL,LINEMODE>.				begin
        returnc(yytext[1]);
        end;
