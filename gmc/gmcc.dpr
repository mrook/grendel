
(* Yacc parser template (TP Yacc V3.0), V1.2 6-17-91 AG *)

(* global definitions: *)


uses 
  SysUtils,
  Classes,
{$IFDEF WIN32}
  Windows,
{$ENDIF}  
  YaccLib, 
  LexLib,
  strip;


const
  CONV_TO_INT = 1;
  CONV_TO_FLOAT = 2;
	CONV_TO_STRING = 3;
	
	SPECIAL_TRAP = 1;
	SPECIAL_SLEEP = 2;
	SPECIAL_WAIT = 3;
	SPECIAL_SIGNAL = 4;
	
	VARTYPE_FUNCTION = 1;
	VARTYPE_GLOBAL = 2;
	VARTYPE_LOCAL = 3;
	VARTYPE_PARAM = 4;


type 	Root = class
        lineNum : integer;
				typ : integer;
     	end;
	
			Expr = class(Root)
     	end;
	

			Expr_ConstInt = class(Expr)
				value : Integer;
			end;

			Expr_ConstFloat = class(Expr)
				value : Single;
			end;

      Expr_String = class(Expr)
        value : string;
      end;

			Expr_Neg = class(Expr)
        ex : Expr;
      end;

			Expr_Op = class(Expr)
				op : char;
        le, re : Expr;
			end;

			Expr_Seq = class(Expr)
				ex, seq : Expr;
			end;

			Expr_If = class(Expr)
        ce : Expr;
        le, re : Expr;

				lThen, lElse, lAfter : Integer;
      end;

			Expr_Id = class(Expr)
        id : string;
      end;
		
      Expr_Assign = class(Expr)
        id, ex : Expr;
      end;

			Expr_Asm = class(Expr)
        line : string; 
      end;

			Expr_Func = class(Expr)
				id : string;
				displ : integer;
				body : Expr;
				lStart : integer;
      end;
      
      Expr_Return = class(Expr)
				id : string;
        ret : Expr;
      end;

			Expr_Call = class(Expr)
			  id : string;
				params : Expr;
			end;

			Expr_External = class(Expr)
				id : string;
				assoc : string;
      end;

			Expr_Conv = class(expr)
				ex : Expr;

				cnv : integer;
				originaltyp : integer;	
			end;
			
			Expr_Cast = class(expr)
			  ex : Expr;
			  desttype : integer;
			end;
			
			Expr_Special = class(Expr)
				spec : integer;
				ex : Expr;
			end;
			
			Expr_Loop = class(Expr)
			  lStart : integer;
			  init : Expr;
			  ce : Expr;
			  step : Expr;
			  body : Expr;
			end;

			Expr_Rel = class(Expr)
        op : string;
        le, re : Expr;
			end;

			Expr_And = class(Expr)
        le, re : Expr;
			end;

			Expr_Or = class(Expr)
        le, re : Expr;
			end;

			Expr_Not = class(Expr)
        ex : Expr;
			end;

	
			Env_Entry = class
        id : string;
        typ : integer;
				lbl : integer;
		 		displ : integer;
		 		varTyp : integer;
      end;

var
    labelNum : integer;
    globalCount : integer;
    tmp, varName, varGlob : string;
		curFunction : string;
    varType : integer;
    environment : TList;
    f : textfile;


procedure startCompiler(root : Expr); forward;
procedure updateLabel(id : string; lbl : integer); forward;
procedure addEnvironment(lineNum : integer; id : string; typ, lbl, varTyp : integer); forward;
function lookupEnv(id : string) : Env_Entry; forward;
procedure compilerError(lineNum : integer; msg : string); forward;


const IDENTIFIER = 257;
const LINE = 258;
const INT = 259;
const FLOAT = 260;
const UMINUS = 261;
const ILLEGAL = 262;
const _IF = 263;
const _ELSE = 264;
const _ASM = 265;
const _TRUE = 266;
const _FALSE = 267;
const _AND = 268;
const _OR = 269;
const _NOT = 270;
const _RELGT = 271;
const _RELLT = 272;
const _RELGTE = 273;
const _RELLTE = 274;
const _RELEQ = 275;
const _RETURN = 276;
const _BREAK = 277;
const _CONTINUE = 278;
const _DO = 279;
const _SLEEP = 280;
const _WAIT = 281;
const _SIGNAL = 282;
const _WHILE = 283;
const _FOR = 284;
const _REQUIRE = 285;
const _VOID = 286;
const _INT = 287;
const _FLOAT = 288;
const _STRING = 289;
const _EXTERNAL = 290;

type YYSType = record case Integer of
                 1 : ( yyExpr : Expr );
                 2 : ( yyInteger : Integer );
                 3 : ( yyShortString : ShortString );
                 4 : ( yySingle : Single );
               end(*YYSType*);

var yylval : YYSType;

function yylex : Integer; forward;

function yyparse : Integer;

var yystate, yysp, yyn : Integer;
    yys : array [1..yymaxdepth] of Integer;
    yyv : array [1..yymaxdepth] of YYSType;
    yyval : YYSType;

procedure yyaction ( yyruleno : Integer );
  (* local definitions: *)
begin
  (* actions: *)
  case yyruleno of
   1 : begin
       end;
   2 : begin
         yyaccept; 
       end;
   3 : begin
         startCompiler(yyv[yysp-0].yyExpr); 
       end;
   4 : begin
         yyerrok; 
       end;
   5 : begin
         yyval.yyExpr := nil; 
       end;
   6 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
   7 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-0].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
   8 : begin
         yyval.yyExpr := nil; 
       end;
   9 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  10 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-0].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  11 : begin
         yyval.yyExpr := nil; 
       end;
  12 : begin
         yyval.yyExpr := nil; 
       end;
  13 : begin
         yyval.yyExpr := nil; 
       end;
  14 : begin
         yyval.yyExpr := Expr_Return.Create; Expr_Return(yyval.yyExpr).ret := nil; Expr_Return(yyval.yyExpr).lineNum := yylineno; Expr_Return(yyval.yyExpr).id := curFunction; 
       end;
  15 : begin
         yyval.yyExpr := Expr_Return.Create; Expr_Return(yyval.yyExpr).ret := yyv[yysp-1].yyExpr; Expr_Return(yyval.yyExpr).lineNum := yylineno; Expr_Return(yyval.yyExpr).id := curFunction; 
       end;
  16 : begin
         yyval.yyExpr := Expr_Return.Create; Expr_Return(yyval.yyExpr).ret := yyv[yysp-2].yyExpr; Expr_Return(yyval.yyExpr).lineNum := yylineno; Expr_Return(yyval.yyExpr).id := curFunction; 
       end;
  17 : begin
         yyval.yyExpr := nil; 
       end;
  18 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  19 : begin
         yyval.yyExpr := nil;
         																											 		if (not FileExists(varName)) then
         																													  compilerError(yylineno, 'could not open include file ' + varName)
         																													else
         																													  begin																													
         																													  yyopen(varName);
         																														end;	
       end;
  20 : begin
         yyval.yyExpr := nil; 
       end;
  21 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; if (yyval.yyExpr <> nil) then yyval.yyExpr.lineNum := yylineno; 
       end;
  22 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr; if (yyval.yyExpr <> nil) then yyval.yyExpr.lineNum := yylineno; 
       end;
  23 : begin
         yyval.yyExpr := Expr_If.Create; Expr_If(yyval.yyExpr).ce := yyv[yysp-4].yyExpr;	yyval.yyExpr.lineNum := yylineno;
         																														Expr_If(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_If(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
         																														Expr_If(yyval.yyExpr).lThen := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lElse := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lAfter := labelNum; inc(labelNum); 
       end;
  24 : begin
         yyval.yyExpr := Expr_If.Create; Expr_If(yyval.yyExpr).ce := yyv[yysp-2].yyExpr; yyval.yyExpr.lineNum := yylineno;	
         																														Expr_If(yyval.yyExpr).le := yyv[yysp-0].yyExpr; Expr_If(yyval.yyExpr).re := nil; 
         																														Expr_If(yyval.yyExpr).lThen := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lAfter := labelNum; inc(labelNum); 
       end;
  25 : begin
         yyval.yyExpr := Expr_Loop.Create; Expr_Loop(yyval.yyExpr).init := yyv[yysp-6].yyExpr;
         				                                                    yyval.yyExpr.lineNum := yylineno; Expr_Loop(yyval.yyExpr).ce := yyv[yysp-4].yyExpr;
         				                                                    Expr_Loop(yyval.yyExpr).lStart := labelNum; inc(labelNum);
         				                                                    Expr_Loop(yyval.yyExpr).step := yyv[yysp-2].yyExpr; Expr_Loop(yyval.yyExpr).body := yyv[yysp-0].yyExpr; 
       end;
  26 : begin
         yyval.yyExpr := Expr_Special.Create; yyval.yyExpr.lineNum := yylineno; Expr_Special(yyval.yyExpr).spec := SPECIAL_TRAP; yyval.yyExpr.lineNum := yylineno; Expr_Special(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  27 : begin
         yyval.yyExpr := Expr_Special.Create; yyval.yyExpr.lineNum := yylineno; Expr_Special(yyval.yyExpr).spec := SPECIAL_SLEEP; yyval.yyExpr.lineNum := yylineno; Expr_Special(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  28 : begin
         yyval.yyExpr := Expr_Special.Create; yyval.yyExpr.lineNum := yylineno; Expr_Special(yyval.yyExpr).spec := SPECIAL_WAIT; yyval.yyExpr.lineNum := yylineno; Expr_Special(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  29 : begin
         yyval.yyExpr := Expr_Special.Create; yyval.yyExpr.lineNum := yylineno; Expr_Special(yyval.yyExpr).spec := SPECIAL_SIGNAL; yyval.yyExpr.lineNum := yylineno; Expr_Special(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  30 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr; 
       end;
  31 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  32 : begin
         yyval.yyExpr := nil; 
       end;
  33 : begin
         yyval.yyExpr := nil; 
       end;
  34 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  35 : begin
         yyval.yyExpr := nil; 
       end;
  36 : begin
         yyval.yyExpr := nil; addEnvironment(yylineno, curFunction + ':' + varName, varType, -1, VARTYPE_PARAM); 
       end;
  37 : begin
         yyval.yyExpr := nil; 
       end;
  38 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  39 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-2].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
       end;
  40 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  41 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-0].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  42 : begin
         yyval.yyExpr := Expr_Asm.Create; Expr_Asm(yyval.yyExpr).line := varName; 
       end;
  43 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := nil; Expr_Seq(yyval.yyExpr).ex := nil; 
       end;
  44 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr;  
       end;
  45 : begin
         yyval.yyExpr := nil; 
       end;
  46 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  47 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-0].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  48 : begin
         curFunction := varName;	 yyval.yyExpr := Expr_Func.Create; Expr_Func(yyval.yyExpr).id := curFunction;
         																				Expr_Func(yyval.yyExpr).lStart := labelNum; inc(labelNum);
         																				addEnvironment(yylineno, varName, varType, Expr_Func(yyval.yyExpr).lStart, VARTYPE_FUNCTION); 
       end;
  49 : begin
         yyval.yyExpr := nil; 
       end;
  50 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  51 : begin
         yyval.yyExpr := nil; 
       end;
  52 : begin
         yyval.yyExpr := yyv[yysp-4].yyExpr; Expr_Func(yyval.yyExpr).body := yyv[yysp-0].yyExpr; 
         if (yyv[yysp-0].yyExpr = nil) then updateLabel(curFunction, -1);  curFunction := ''; 
       end;
  53 : begin
         yyval := yyv[yysp-0];
       end;
  54 : begin
         yyval := yyv[yysp-2];
       end;
  55 : begin
         varName := curFunction + ':' + varName; 
         yyval.yyShortString := varName; 
         if (curFunction = '') then
         addEnvironment(yylineno, varName, varType, -1, VARTYPE_GLOBAL)
         else
         addEnvironment(yylineno, varName, varType, -1, VARTYPE_LOCAL); 
       end;
  56 : begin
         varType := _VOID; yyval.yyInteger := _VOID; 
       end;
  57 : begin
         varType := _INT; yyval.yyInteger := _INT; 
       end;
  58 : begin
         varType := _FLOAT; yyval.yyInteger := _FLOAT; 
       end;
  59 : begin
         varType := _STRING; yyval.yyInteger := _STRING; 
       end;
  60 : begin
         varType := _EXTERNAL; yyval.yyInteger := _EXTERNAL; 
       end;
  61 : begin
         yyval.yyExpr := nil; 
       end;
  62 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '+'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  63 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '-'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  64 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '*'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  65 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '/'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  66 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '%'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  67 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '&'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  68 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '|'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  69 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr; 
       end;
  70 : begin
         yyval.yyExpr := Expr_Neg.Create; yyval.yyExpr.lineNum := yylineno; Expr_Neg(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
       end;
  71 : begin
         yyval.yyExpr := Expr_ConstInt.Create; yyval.yyExpr.lineNum := yylineno; Expr_ConstInt(yyval.yyExpr).value := yyv[yysp-0].yyInteger; 
       end;
  72 : begin
         yyval.yyExpr := Expr_ConstFloat.Create; yyval.yyExpr.lineNum := yylineno; Expr_ConstFloat(yyval.yyExpr).value := yyv[yysp-0].yySingle; 
       end;
  73 : begin
         yyval.yyExpr := Expr_String.Create; yyval.yyExpr.lineNum := yylineno; Expr_String(yyval.yyExpr).value := ''; 
       end;
  74 : begin
         yyval.yyExpr := Expr_String.Create; yyval.yyExpr.lineNum := yylineno; Expr_String(yyval.yyExpr).value := varName; 
       end;
  75 : begin
         yyval.yyExpr := Expr_Cast.Create; yyval.yyExpr.lineNum := yylineno; Expr_Cast(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; Expr_Cast(yyval.yyExpr).desttype := yyv[yysp-2].yyInteger; 
       end;
  76 : begin
         if (yyv[yysp-2].yyExpr <> nil) then
         															begin
         															yyval.yyExpr := Expr_Assign.Create; 
         															Expr_Assign(yyval.yyExpr).id := yyv[yysp-2].yyExpr; 
         															Expr_Assign(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
         															yyval.yyExpr.lineNum := yylineno;
         															end
         														else
         															yyval.yyExpr := nil; 
       end;
  77 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  78 : begin
         	if (lookupEnv(yyv[yysp-3].yyShortString) = nil) then 
         																					  					begin
         																											compilerError(yylineno, 'undefined function "' + yyv[yysp-3].yyShortString + '"');
         																											yyval.yyExpr := nil;
         																											yyabort;
         																											end;
         																										yyval.yyExpr := Expr_Call.Create; Expr_Call(yyval.yyExpr).id := yyv[yysp-3].yyShortString; Expr_Call(yyval.yyExpr).params := yyv[yysp-1].yyExpr; yyval.yyExpr.lineNum := yyLineno; 
       end;
  79 : begin
         yyval.yyExpr := Expr_Rel.Create; yyval.yyExpr.lineNum := yylineno; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '>';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  80 : begin
         yyval.yyExpr := Expr_Rel.Create; yyval.yyExpr.lineNum := yylineno; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '<';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  81 : begin
         yyval.yyExpr := Expr_Rel.Create; yyval.yyExpr.lineNum := yylineno; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '>=';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  82 : begin
         yyval.yyExpr := Expr_Rel.Create; yyval.yyExpr.lineNum := yylineno; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '=<';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  83 : begin
         yyval.yyExpr := Expr_Rel.Create; yyval.yyExpr.lineNum := yylineno; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '==';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  84 : begin
         yyval.yyExpr := Expr_And.Create; yyval.yyExpr.lineNum := yylineno; Expr_And(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_And(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  85 : begin
         yyval.yyExpr := Expr_Or.Create; yyval.yyExpr.lineNum := yylineno; Expr_Or(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Or(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  86 : begin
         yyval.yyExpr := Expr_Not.Create; yyval.yyExpr.lineNum := yylineno; Expr_Not(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
       end;
  87 : begin
         yyval.yyExpr := Expr_ConstInt.Create; yyval.yyExpr.lineNum := yylineno; Expr_ConstInt(yyval.yyExpr).value := 1; yyval.yyExpr.lineNum := yylineno;
       end;
  88 : begin
         yyval.yyExpr := Expr_ConstInt.Create; yyval.yyExpr.lineNum := yylineno; Expr_ConstInt(yyval.yyExpr).value := 0; yyval.yyExpr.lineNum := yylineno;
       end;
  89 : begin
         yyval.yyShortString := varName; 
       end;
  90 : begin
         varGlob := ':' + yyv[yysp-0].yyShortString;
         tmp := curFunction + varGlob;
         varGlob := left(varGlob, '.');
         												varName := left(tmp, '.');
         																																		
         												if (varName <> tmp) then
         begin
         if (lookupEnv(varName) <> nil) then
         begin
         													yyval.yyExpr := Expr_External.Create;
         													yyval.yyExpr.lineNum := yylineno; 
         													Expr_External(yyval.yyExpr).id := varName;
         													Expr_External(yyval.yyExpr).assoc := right(tmp, '.');
         													end
         												else
         												  begin
         													compilerError(yylineno, 'undeclared identifier "' + right(varGlob, ':') + '"');
         													yyval.yyExpr := nil;
         	  												yyabort;
         	  												end;
         													end
         												else
         												if (lookupEnv(varName) <> nil) then 
         													begin
         													yyval.yyExpr := Expr_Id.Create;
         													yyval.yyExpr.lineNum := yylineno; 
         													Expr_Id(yyval.yyExpr).id := varName;
         													end
         												else
         												if (lookupEnv(varGlob) <> nil) then 
         													begin
         													yyval.yyExpr := Expr_Id.Create;
         													yyval.yyExpr.lineNum := yylineno; 
         													Expr_Id(yyval.yyExpr).id := varGlob;
         													end
         												else
         													begin
         													compilerError(yylineno, 'undeclared identifier "' + right(varGlob, ':') + '"');
         													yyval.yyExpr := nil;
         													yyabort;
         													end; 
       end;
  91 : begin
       end;
  92 : begin
         yyval.yyShortString := varName; 
       end;
  93 : begin
         yyval.yyShortString := yyv[yysp-2].yyShortString + '.' + varName; 
       end;
  end;
end(*yyaction*);

(* parse table: *)

type YYARec = record
                sym, act : Integer;
              end;
     YYRRec = record
                len, sym : Integer;
              end;

const

yynacts   = 1766;
yyngotos  = 198;
yynstates = 161;
yynrules  = 93;

yya : array [1..yynacts] of YYARec = (
{ 0: }
  ( sym: 256; act: 2 ),
  ( sym: 0; act: -1 ),
  ( sym: 10; act: -1 ),
  ( sym: 285; act: -1 ),
  ( sym: 286; act: -1 ),
  ( sym: 287; act: -1 ),
  ( sym: 288; act: -1 ),
  ( sym: 289; act: -1 ),
  ( sym: 290; act: -1 ),
{ 1: }
  ( sym: 0; act: 0 ),
  ( sym: 10; act: 9 ),
  ( sym: 285; act: 10 ),
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
{ 2: }
  ( sym: 10; act: 16 ),
{ 3: }
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 0; act: -18 ),
  ( sym: 10; act: -18 ),
  ( sym: 285; act: -18 ),
{ 4: }
{ 5: }
  ( sym: 285; act: 10 ),
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 0; act: -3 ),
  ( sym: 10; act: -3 ),
{ 6: }
{ 7: }
  ( sym: 40; act: 19 ),
{ 8: }
  ( sym: 257; act: 22 ),
{ 9: }
{ 10: }
  ( sym: 34; act: 23 ),
{ 11: }
{ 12: }
{ 13: }
{ 14: }
{ 15: }
{ 16: }
{ 17: }
{ 18: }
{ 19: }
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 41; act: -33 ),
  ( sym: 44; act: -33 ),
{ 20: }
  ( sym: 44; act: 27 ),
  ( sym: 59; act: 28 ),
{ 21: }
{ 22: }
  ( sym: 40; act: -48 ),
  ( sym: 44; act: -55 ),
  ( sym: 59; act: -55 ),
{ 23: }
  ( sym: 258; act: 29 ),
{ 24: }
{ 25: }
  ( sym: 41; act: 30 ),
  ( sym: 44; act: 31 ),
{ 26: }
  ( sym: 257; act: 32 ),
{ 27: }
  ( sym: 257; act: 34 ),
{ 28: }
{ 29: }
  ( sym: 34; act: 35 ),
{ 30: }
  ( sym: 59; act: 38 ),
  ( sym: 123; act: 39 ),
{ 31: }
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
{ 32: }
{ 33: }
{ 34: }
{ 35: }
{ 36: }
{ 37: }
{ 38: }
{ 39: }
  ( sym: 125; act: 42 ),
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 34; act: -45 ),
  ( sym: 37; act: -45 ),
  ( sym: 38; act: -45 ),
  ( sym: 40; act: -45 ),
  ( sym: 42; act: -45 ),
  ( sym: 43; act: -45 ),
  ( sym: 45; act: -45 ),
  ( sym: 46; act: -45 ),
  ( sym: 47; act: -45 ),
  ( sym: 59; act: -45 ),
  ( sym: 61; act: -45 ),
  ( sym: 123; act: -45 ),
  ( sym: 124; act: -45 ),
  ( sym: 257; act: -45 ),
  ( sym: 259; act: -45 ),
  ( sym: 260; act: -45 ),
  ( sym: 263; act: -45 ),
  ( sym: 265; act: -45 ),
  ( sym: 266; act: -45 ),
  ( sym: 267; act: -45 ),
  ( sym: 268; act: -45 ),
  ( sym: 269; act: -45 ),
  ( sym: 270; act: -45 ),
  ( sym: 271; act: -45 ),
  ( sym: 272; act: -45 ),
  ( sym: 273; act: -45 ),
  ( sym: 274; act: -45 ),
  ( sym: 275; act: -45 ),
  ( sym: 276; act: -45 ),
  ( sym: 277; act: -45 ),
  ( sym: 278; act: -45 ),
  ( sym: 279; act: -45 ),
  ( sym: 280; act: -45 ),
  ( sym: 281; act: -45 ),
  ( sym: 282; act: -45 ),
  ( sym: 284; act: -45 ),
{ 40: }
{ 41: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 59; act: 54 ),
  ( sym: 123; act: 39 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 263; act: 58 ),
  ( sym: 265; act: 59 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 276; act: 63 ),
  ( sym: 277; act: 64 ),
  ( sym: 278; act: 65 ),
  ( sym: 279; act: 66 ),
  ( sym: 280; act: 67 ),
  ( sym: 281; act: 68 ),
  ( sym: 282; act: 69 ),
  ( sym: 284; act: 70 ),
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 37; act: -8 ),
  ( sym: 38; act: -8 ),
  ( sym: 42; act: -8 ),
  ( sym: 43; act: -8 ),
  ( sym: 46; act: -8 ),
  ( sym: 47; act: -8 ),
  ( sym: 61; act: -8 ),
  ( sym: 124; act: -8 ),
  ( sym: 125; act: -8 ),
  ( sym: 268; act: -8 ),
  ( sym: 269; act: -8 ),
  ( sym: 271; act: -8 ),
  ( sym: 272; act: -8 ),
  ( sym: 273; act: -8 ),
  ( sym: 274; act: -8 ),
  ( sym: 275; act: -8 ),
{ 42: }
{ 43: }
  ( sym: 46; act: 71 ),
  ( sym: 37; act: -90 ),
  ( sym: 38; act: -90 ),
  ( sym: 41; act: -90 ),
  ( sym: 42; act: -90 ),
  ( sym: 43; act: -90 ),
  ( sym: 44; act: -90 ),
  ( sym: 45; act: -90 ),
  ( sym: 47; act: -90 ),
  ( sym: 59; act: -90 ),
  ( sym: 61; act: -90 ),
  ( sym: 124; act: -90 ),
  ( sym: 268; act: -90 ),
  ( sym: 269; act: -90 ),
  ( sym: 271; act: -90 ),
  ( sym: 272; act: -90 ),
  ( sym: 273; act: -90 ),
  ( sym: 274; act: -90 ),
  ( sym: 275; act: -90 ),
{ 44: }
  ( sym: 40; act: 72 ),
{ 45: }
  ( sym: 61; act: 73 ),
  ( sym: 37; act: -77 ),
  ( sym: 38; act: -77 ),
  ( sym: 41; act: -77 ),
  ( sym: 42; act: -77 ),
  ( sym: 43; act: -77 ),
  ( sym: 44; act: -77 ),
  ( sym: 45; act: -77 ),
  ( sym: 47; act: -77 ),
  ( sym: 59; act: -77 ),
  ( sym: 124; act: -77 ),
  ( sym: 268; act: -77 ),
  ( sym: 269; act: -77 ),
  ( sym: 271; act: -77 ),
  ( sym: 272; act: -77 ),
  ( sym: 273; act: -77 ),
  ( sym: 274; act: -77 ),
  ( sym: 275; act: -77 ),
{ 46: }
{ 47: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 59; act: 54 ),
  ( sym: 123; act: 39 ),
  ( sym: 125; act: 75 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 263; act: 58 ),
  ( sym: 265; act: 59 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 276; act: 63 ),
  ( sym: 277; act: 64 ),
  ( sym: 278; act: 65 ),
  ( sym: 279; act: 66 ),
  ( sym: 280; act: 67 ),
  ( sym: 281; act: 68 ),
  ( sym: 282; act: 69 ),
  ( sym: 284; act: 70 ),
  ( sym: 37; act: -11 ),
  ( sym: 38; act: -11 ),
  ( sym: 42; act: -11 ),
  ( sym: 43; act: -11 ),
  ( sym: 46; act: -11 ),
  ( sym: 47; act: -11 ),
  ( sym: 61; act: -11 ),
  ( sym: 124; act: -11 ),
  ( sym: 268; act: -11 ),
  ( sym: 269; act: -11 ),
  ( sym: 271; act: -11 ),
  ( sym: 272; act: -11 ),
  ( sym: 273; act: -11 ),
  ( sym: 274; act: -11 ),
  ( sym: 275; act: -11 ),
{ 48: }
{ 49: }
{ 50: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 59; act: 82 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 51: }
  ( sym: 34; act: 91 ),
  ( sym: 258; act: 92 ),
{ 52: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 53: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 54: }
{ 55: }
  ( sym: 40; act: -89 ),
  ( sym: 37; act: -92 ),
  ( sym: 38; act: -92 ),
  ( sym: 41; act: -92 ),
  ( sym: 42; act: -92 ),
  ( sym: 43; act: -92 ),
  ( sym: 44; act: -92 ),
  ( sym: 45; act: -92 ),
  ( sym: 46; act: -92 ),
  ( sym: 47; act: -92 ),
  ( sym: 59; act: -92 ),
  ( sym: 61; act: -92 ),
  ( sym: 124; act: -92 ),
  ( sym: 268; act: -92 ),
  ( sym: 269; act: -92 ),
  ( sym: 271; act: -92 ),
  ( sym: 272; act: -92 ),
  ( sym: 273; act: -92 ),
  ( sym: 274; act: -92 ),
  ( sym: 275; act: -92 ),
{ 56: }
{ 57: }
{ 58: }
  ( sym: 40; act: 96 ),
{ 59: }
  ( sym: 123; act: 97 ),
{ 60: }
{ 61: }
{ 62: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 63: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 100 ),
  ( sym: 45; act: 53 ),
  ( sym: 59; act: 101 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 64: }
  ( sym: 59; act: 102 ),
{ 65: }
  ( sym: 59; act: 103 ),
{ 66: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 67: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 68: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 69: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 70: }
  ( sym: 40; act: 108 ),
{ 71: }
  ( sym: 257; act: 109 ),
{ 72: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 41; act: -37 ),
  ( sym: 44; act: -37 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 73: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 74: }
{ 75: }
{ 76: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 77: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 78: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 79: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 80: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 81: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 82: }
{ 83: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 84: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 85: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 86: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 87: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 88: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 89: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 90: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 91: }
{ 92: }
  ( sym: 34; act: 127 ),
{ 93: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 41; act: 128 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 94: }
  ( sym: 41; act: 129 ),
{ 95: }
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 37; act: -70 ),
  ( sym: 38; act: -70 ),
  ( sym: 41; act: -70 ),
  ( sym: 42; act: -70 ),
  ( sym: 43; act: -70 ),
  ( sym: 44; act: -70 ),
  ( sym: 45; act: -70 ),
  ( sym: 47; act: -70 ),
  ( sym: 59; act: -70 ),
  ( sym: 124; act: -70 ),
{ 96: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 97: }
  ( sym: 34; act: 133 ),
{ 98: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -86 ),
  ( sym: 44; act: -86 ),
  ( sym: 59; act: -86 ),
{ 99: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 59; act: 134 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 100: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 101: }
{ 102: }
{ 103: }
{ 104: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 59; act: 136 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 105: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 59; act: 137 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 106: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 59; act: 138 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 107: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 59; act: 139 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 108: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 109: }
{ 110: }
  ( sym: 41; act: 141 ),
  ( sym: 44; act: 142 ),
{ 111: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -38 ),
  ( sym: 44; act: -38 ),
{ 112: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -76 ),
  ( sym: 44; act: -76 ),
  ( sym: 59; act: -76 ),
{ 113: }
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 37; act: -66 ),
  ( sym: 38; act: -66 ),
  ( sym: 41; act: -66 ),
  ( sym: 42; act: -66 ),
  ( sym: 43; act: -66 ),
  ( sym: 44; act: -66 ),
  ( sym: 45; act: -66 ),
  ( sym: 47; act: -66 ),
  ( sym: 59; act: -66 ),
  ( sym: 124; act: -66 ),
{ 114: }
  ( sym: 37; act: 76 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 38; act: -67 ),
  ( sym: 41; act: -67 ),
  ( sym: 44; act: -67 ),
  ( sym: 59; act: -67 ),
  ( sym: 124; act: -67 ),
{ 115: }
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 37; act: -64 ),
  ( sym: 38; act: -64 ),
  ( sym: 41; act: -64 ),
  ( sym: 42; act: -64 ),
  ( sym: 43; act: -64 ),
  ( sym: 44; act: -64 ),
  ( sym: 45; act: -64 ),
  ( sym: 47; act: -64 ),
  ( sym: 59; act: -64 ),
  ( sym: 124; act: -64 ),
{ 116: }
  ( sym: 37; act: 76 ),
  ( sym: 42; act: 78 ),
  ( sym: 47; act: 81 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 45; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
{ 117: }
  ( sym: 37; act: 76 ),
  ( sym: 42; act: 78 ),
  ( sym: 47; act: 81 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 38; act: -63 ),
  ( sym: 41; act: -63 ),
  ( sym: 43; act: -63 ),
  ( sym: 44; act: -63 ),
  ( sym: 45; act: -63 ),
  ( sym: 59; act: -63 ),
  ( sym: 124; act: -63 ),
{ 118: }
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 37; act: -65 ),
  ( sym: 38; act: -65 ),
  ( sym: 41; act: -65 ),
  ( sym: 42; act: -65 ),
  ( sym: 43; act: -65 ),
  ( sym: 44; act: -65 ),
  ( sym: 45; act: -65 ),
  ( sym: 47; act: -65 ),
  ( sym: 59; act: -65 ),
  ( sym: 124; act: -65 ),
{ 119: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -68 ),
  ( sym: 44; act: -68 ),
  ( sym: 59; act: -68 ),
  ( sym: 124; act: -68 ),
{ 120: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -84 ),
  ( sym: 44; act: -84 ),
  ( sym: 59; act: -84 ),
{ 121: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -85 ),
  ( sym: 44; act: -85 ),
  ( sym: 59; act: -85 ),
{ 122: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -79 ),
  ( sym: 44; act: -79 ),
  ( sym: 59; act: -79 ),
{ 123: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -80 ),
  ( sym: 44; act: -80 ),
  ( sym: 59; act: -80 ),
{ 124: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -81 ),
  ( sym: 44; act: -81 ),
  ( sym: 59; act: -81 ),
{ 125: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -82 ),
  ( sym: 44; act: -82 ),
  ( sym: 59; act: -82 ),
{ 126: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -83 ),
  ( sym: 44; act: -83 ),
  ( sym: 59; act: -83 ),
{ 127: }
{ 128: }
{ 129: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 130: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 41; act: 144 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 131: }
{ 132: }
  ( sym: 34; act: 133 ),
  ( sym: 125; act: 146 ),
{ 133: }
  ( sym: 258; act: 147 ),
{ 134: }
{ 135: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 41; act: 148 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 136: }
{ 137: }
{ 138: }
{ 139: }
{ 140: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 59; act: 149 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 141: }
{ 142: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 44; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 143: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -75 ),
  ( sym: 44; act: -75 ),
  ( sym: 59; act: -75 ),
{ 144: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 59; act: 54 ),
  ( sym: 123; act: 39 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 263; act: 58 ),
  ( sym: 265; act: 59 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 276; act: 63 ),
  ( sym: 277; act: 64 ),
  ( sym: 278; act: 65 ),
  ( sym: 279; act: 66 ),
  ( sym: 280; act: 67 ),
  ( sym: 281; act: 68 ),
  ( sym: 282; act: 69 ),
  ( sym: 284; act: 70 ),
  ( sym: 37; act: -11 ),
  ( sym: 38; act: -11 ),
  ( sym: 42; act: -11 ),
  ( sym: 43; act: -11 ),
  ( sym: 46; act: -11 ),
  ( sym: 47; act: -11 ),
  ( sym: 61; act: -11 ),
  ( sym: 124; act: -11 ),
  ( sym: 125; act: -11 ),
  ( sym: 264; act: -11 ),
  ( sym: 268; act: -11 ),
  ( sym: 269; act: -11 ),
  ( sym: 271; act: -11 ),
  ( sym: 272; act: -11 ),
  ( sym: 273; act: -11 ),
  ( sym: 274; act: -11 ),
  ( sym: 275; act: -11 ),
{ 145: }
{ 146: }
{ 147: }
  ( sym: 34; act: 152 ),
{ 148: }
  ( sym: 59; act: 153 ),
  ( sym: 37; act: -69 ),
  ( sym: 38; act: -69 ),
  ( sym: 42; act: -69 ),
  ( sym: 43; act: -69 ),
  ( sym: 45; act: -69 ),
  ( sym: 47; act: -69 ),
  ( sym: 124; act: -69 ),
  ( sym: 268; act: -69 ),
  ( sym: 269; act: -69 ),
  ( sym: 271; act: -69 ),
  ( sym: 272; act: -69 ),
  ( sym: 273; act: -69 ),
  ( sym: 274; act: -69 ),
  ( sym: 275; act: -69 ),
{ 149: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 59; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 150: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
  ( sym: 41; act: -39 ),
  ( sym: 44; act: -39 ),
{ 151: }
  ( sym: 264; act: 155 ),
  ( sym: 34; act: -24 ),
  ( sym: 37; act: -24 ),
  ( sym: 38; act: -24 ),
  ( sym: 40; act: -24 ),
  ( sym: 42; act: -24 ),
  ( sym: 43; act: -24 ),
  ( sym: 45; act: -24 ),
  ( sym: 46; act: -24 ),
  ( sym: 47; act: -24 ),
  ( sym: 59; act: -24 ),
  ( sym: 61; act: -24 ),
  ( sym: 123; act: -24 ),
  ( sym: 124; act: -24 ),
  ( sym: 125; act: -24 ),
  ( sym: 257; act: -24 ),
  ( sym: 259; act: -24 ),
  ( sym: 260; act: -24 ),
  ( sym: 263; act: -24 ),
  ( sym: 265; act: -24 ),
  ( sym: 266; act: -24 ),
  ( sym: 267; act: -24 ),
  ( sym: 268; act: -24 ),
  ( sym: 269; act: -24 ),
  ( sym: 270; act: -24 ),
  ( sym: 271; act: -24 ),
  ( sym: 272; act: -24 ),
  ( sym: 273; act: -24 ),
  ( sym: 274; act: -24 ),
  ( sym: 275; act: -24 ),
  ( sym: 276; act: -24 ),
  ( sym: 277; act: -24 ),
  ( sym: 278; act: -24 ),
  ( sym: 279; act: -24 ),
  ( sym: 280; act: -24 ),
  ( sym: 281; act: -24 ),
  ( sym: 282; act: -24 ),
  ( sym: 284; act: -24 ),
{ 152: }
{ 153: }
{ 154: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 59; act: 156 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 155: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 59; act: 54 ),
  ( sym: 123; act: 39 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 263; act: 58 ),
  ( sym: 265; act: 59 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 276; act: 63 ),
  ( sym: 277; act: 64 ),
  ( sym: 278; act: 65 ),
  ( sym: 279; act: 66 ),
  ( sym: 280; act: 67 ),
  ( sym: 281; act: 68 ),
  ( sym: 282; act: 69 ),
  ( sym: 284; act: 70 ),
  ( sym: 37; act: -11 ),
  ( sym: 38; act: -11 ),
  ( sym: 42; act: -11 ),
  ( sym: 43; act: -11 ),
  ( sym: 46; act: -11 ),
  ( sym: 47; act: -11 ),
  ( sym: 61; act: -11 ),
  ( sym: 124; act: -11 ),
  ( sym: 125; act: -11 ),
  ( sym: 264; act: -11 ),
  ( sym: 268; act: -11 ),
  ( sym: 269; act: -11 ),
  ( sym: 271; act: -11 ),
  ( sym: 272; act: -11 ),
  ( sym: 273; act: -11 ),
  ( sym: 274; act: -11 ),
  ( sym: 275; act: -11 ),
{ 156: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 37; act: -61 ),
  ( sym: 38; act: -61 ),
  ( sym: 41; act: -61 ),
  ( sym: 42; act: -61 ),
  ( sym: 43; act: -61 ),
  ( sym: 47; act: -61 ),
  ( sym: 124; act: -61 ),
  ( sym: 268; act: -61 ),
  ( sym: 269; act: -61 ),
  ( sym: 271; act: -61 ),
  ( sym: 272; act: -61 ),
  ( sym: 273; act: -61 ),
  ( sym: 274; act: -61 ),
  ( sym: 275; act: -61 ),
  ( sym: 46; act: -91 ),
  ( sym: 61; act: -91 ),
{ 157: }
{ 158: }
  ( sym: 37; act: 76 ),
  ( sym: 38; act: 77 ),
  ( sym: 41; act: 159 ),
  ( sym: 42; act: 78 ),
  ( sym: 43; act: 79 ),
  ( sym: 45; act: 80 ),
  ( sym: 47; act: 81 ),
  ( sym: 124; act: 83 ),
  ( sym: 268; act: 84 ),
  ( sym: 269; act: 85 ),
  ( sym: 271; act: 86 ),
  ( sym: 272; act: 87 ),
  ( sym: 273; act: 88 ),
  ( sym: 274; act: 89 ),
  ( sym: 275; act: 90 ),
{ 159: }
  ( sym: 34; act: 51 ),
  ( sym: 40; act: 52 ),
  ( sym: 45; act: 53 ),
  ( sym: 59; act: 54 ),
  ( sym: 123; act: 39 ),
  ( sym: 257; act: 55 ),
  ( sym: 259; act: 56 ),
  ( sym: 260; act: 57 ),
  ( sym: 263; act: 58 ),
  ( sym: 265; act: 59 ),
  ( sym: 266; act: 60 ),
  ( sym: 267; act: 61 ),
  ( sym: 270; act: 62 ),
  ( sym: 276; act: 63 ),
  ( sym: 277; act: 64 ),
  ( sym: 278; act: 65 ),
  ( sym: 279; act: 66 ),
  ( sym: 280; act: 67 ),
  ( sym: 281; act: 68 ),
  ( sym: 282; act: 69 ),
  ( sym: 284; act: 70 ),
  ( sym: 37; act: -11 ),
  ( sym: 38; act: -11 ),
  ( sym: 42; act: -11 ),
  ( sym: 43; act: -11 ),
  ( sym: 46; act: -11 ),
  ( sym: 47; act: -11 ),
  ( sym: 61; act: -11 ),
  ( sym: 124; act: -11 ),
  ( sym: 125; act: -11 ),
  ( sym: 264; act: -11 ),
  ( sym: 268; act: -11 ),
  ( sym: 269; act: -11 ),
  ( sym: 271; act: -11 ),
  ( sym: 272; act: -11 ),
  ( sym: 273; act: -11 ),
  ( sym: 274; act: -11 ),
  ( sym: 275; act: -11 )
{ 160: }
);

yyg : array [1..yyngotos] of YYARec = (
{ 0: }
  ( sym: -24; act: 1 ),
{ 1: }
  ( sym: -16; act: 3 ),
  ( sym: -15; act: 4 ),
  ( sym: -8; act: 5 ),
  ( sym: -7; act: 6 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 2: }
{ 3: }
  ( sym: -15; act: 17 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 4: }
{ 5: }
  ( sym: -16; act: 3 ),
  ( sym: -15; act: 4 ),
  ( sym: -7; act: 18 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 6: }
{ 7: }
{ 8: }
  ( sym: -25; act: 20 ),
  ( sym: -21; act: 21 ),
{ 9: }
{ 10: }
{ 11: }
{ 12: }
{ 13: }
{ 14: }
{ 15: }
{ 16: }
{ 17: }
{ 18: }
{ 19: }
  ( sym: -12; act: 24 ),
  ( sym: -11; act: 25 ),
  ( sym: -2; act: 26 ),
{ 20: }
{ 21: }
{ 22: }
{ 23: }
{ 24: }
{ 25: }
{ 26: }
{ 27: }
  ( sym: -21; act: 33 ),
{ 28: }
{ 29: }
{ 30: }
  ( sym: -14; act: 36 ),
  ( sym: -6; act: 37 ),
{ 31: }
  ( sym: -12; act: 40 ),
  ( sym: -2; act: 26 ),
{ 32: }
{ 33: }
{ 34: }
{ 35: }
{ 36: }
{ 37: }
{ 38: }
{ 39: }
  ( sym: -16; act: 41 ),
  ( sym: -15; act: 4 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 40: }
{ 41: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -15; act: 17 ),
  ( sym: -14; act: 46 ),
  ( sym: -10; act: 47 ),
  ( sym: -9; act: 48 ),
  ( sym: -5; act: 7 ),
  ( sym: -4; act: 49 ),
  ( sym: -3; act: 50 ),
  ( sym: -2; act: 8 ),
{ 42: }
{ 43: }
{ 44: }
{ 45: }
{ 46: }
{ 47: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -14; act: 46 ),
  ( sym: -9; act: 74 ),
  ( sym: -4; act: 49 ),
  ( sym: -3; act: 50 ),
{ 48: }
{ 49: }
{ 50: }
{ 51: }
{ 52: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 93 ),
  ( sym: -2; act: 94 ),
{ 53: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 95 ),
{ 54: }
{ 55: }
{ 56: }
{ 57: }
{ 58: }
{ 59: }
{ 60: }
{ 61: }
{ 62: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 98 ),
{ 63: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 99 ),
{ 64: }
{ 65: }
{ 66: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 104 ),
{ 67: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 105 ),
{ 68: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 106 ),
{ 69: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 107 ),
{ 70: }
{ 71: }
{ 72: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -13; act: 110 ),
  ( sym: -3; act: 111 ),
{ 73: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 112 ),
{ 74: }
{ 75: }
{ 76: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 113 ),
{ 77: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 114 ),
{ 78: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 115 ),
{ 79: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 116 ),
{ 80: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 117 ),
{ 81: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 118 ),
{ 82: }
{ 83: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 119 ),
{ 84: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 120 ),
{ 85: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 121 ),
{ 86: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 122 ),
{ 87: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 123 ),
{ 88: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 124 ),
{ 89: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 125 ),
{ 90: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 126 ),
{ 91: }
{ 92: }
{ 93: }
{ 94: }
{ 95: }
{ 96: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 130 ),
{ 97: }
  ( sym: -20; act: 131 ),
  ( sym: -19; act: 132 ),
{ 98: }
{ 99: }
{ 100: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 135 ),
  ( sym: -2; act: 94 ),
{ 101: }
{ 102: }
{ 103: }
{ 104: }
{ 105: }
{ 106: }
{ 107: }
{ 108: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 140 ),
{ 109: }
{ 110: }
{ 111: }
{ 112: }
{ 113: }
{ 114: }
{ 115: }
{ 116: }
{ 117: }
{ 118: }
{ 119: }
{ 120: }
{ 121: }
{ 122: }
{ 123: }
{ 124: }
{ 125: }
{ 126: }
{ 127: }
{ 128: }
{ 129: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 143 ),
{ 130: }
{ 131: }
{ 132: }
  ( sym: -20; act: 145 ),
{ 133: }
{ 134: }
{ 135: }
{ 136: }
{ 137: }
{ 138: }
{ 139: }
{ 140: }
{ 141: }
{ 142: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 150 ),
{ 143: }
{ 144: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -14; act: 46 ),
  ( sym: -9; act: 151 ),
  ( sym: -4; act: 49 ),
  ( sym: -3; act: 50 ),
{ 145: }
{ 146: }
{ 147: }
{ 148: }
{ 149: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 154 ),
{ 150: }
{ 151: }
{ 152: }
{ 153: }
{ 154: }
{ 155: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -14; act: 46 ),
  ( sym: -9; act: 157 ),
  ( sym: -4; act: 49 ),
  ( sym: -3; act: 50 ),
{ 156: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -3; act: 158 ),
{ 157: }
{ 158: }
{ 159: }
  ( sym: -23; act: 43 ),
  ( sym: -22; act: 44 ),
  ( sym: -18; act: 45 ),
  ( sym: -14; act: 46 ),
  ( sym: -9; act: 160 ),
  ( sym: -4; act: 49 ),
  ( sym: -3; act: 50 )
{ 160: }
);

yyd : array [0..yynstates-1] of Integer = (
{ 0: } 0,
{ 1: } 0,
{ 2: } 0,
{ 3: } 0,
{ 4: } -46,
{ 5: } 0,
{ 6: } -6,
{ 7: } 0,
{ 8: } 0,
{ 9: } -2,
{ 10: } 0,
{ 11: } -56,
{ 12: } -57,
{ 13: } -58,
{ 14: } -59,
{ 15: } -60,
{ 16: } -4,
{ 17: } -47,
{ 18: } -7,
{ 19: } 0,
{ 20: } 0,
{ 21: } -53,
{ 22: } 0,
{ 23: } 0,
{ 24: } -34,
{ 25: } 0,
{ 26: } 0,
{ 27: } 0,
{ 28: } -51,
{ 29: } 0,
{ 30: } 0,
{ 31: } 0,
{ 32: } -36,
{ 33: } -54,
{ 34: } -55,
{ 35: } -19,
{ 36: } -50,
{ 37: } -52,
{ 38: } -49,
{ 39: } 0,
{ 40: } -35,
{ 41: } 0,
{ 42: } -43,
{ 43: } 0,
{ 44: } 0,
{ 45: } 0,
{ 46: } -21,
{ 47: } 0,
{ 48: } -9,
{ 49: } -31,
{ 50: } 0,
{ 51: } 0,
{ 52: } 0,
{ 53: } 0,
{ 54: } -32,
{ 55: } 0,
{ 56: } -71,
{ 57: } -72,
{ 58: } 0,
{ 59: } 0,
{ 60: } -87,
{ 61: } -88,
{ 62: } 0,
{ 63: } 0,
{ 64: } 0,
{ 65: } 0,
{ 66: } 0,
{ 67: } 0,
{ 68: } 0,
{ 69: } 0,
{ 70: } 0,
{ 71: } 0,
{ 72: } 0,
{ 73: } 0,
{ 74: } -10,
{ 75: } -44,
{ 76: } 0,
{ 77: } 0,
{ 78: } 0,
{ 79: } 0,
{ 80: } 0,
{ 81: } 0,
{ 82: } -22,
{ 83: } 0,
{ 84: } 0,
{ 85: } 0,
{ 86: } 0,
{ 87: } 0,
{ 88: } 0,
{ 89: } 0,
{ 90: } 0,
{ 91: } -73,
{ 92: } 0,
{ 93: } 0,
{ 94: } 0,
{ 95: } 0,
{ 96: } 0,
{ 97: } 0,
{ 98: } 0,
{ 99: } 0,
{ 100: } 0,
{ 101: } -14,
{ 102: } -12,
{ 103: } -13,
{ 104: } 0,
{ 105: } 0,
{ 106: } 0,
{ 107: } 0,
{ 108: } 0,
{ 109: } -93,
{ 110: } 0,
{ 111: } 0,
{ 112: } 0,
{ 113: } 0,
{ 114: } 0,
{ 115: } 0,
{ 116: } 0,
{ 117: } 0,
{ 118: } 0,
{ 119: } 0,
{ 120: } 0,
{ 121: } 0,
{ 122: } 0,
{ 123: } 0,
{ 124: } 0,
{ 125: } 0,
{ 126: } 0,
{ 127: } -74,
{ 128: } -69,
{ 129: } 0,
{ 130: } 0,
{ 131: } -40,
{ 132: } 0,
{ 133: } 0,
{ 134: } -15,
{ 135: } 0,
{ 136: } -26,
{ 137: } -27,
{ 138: } -28,
{ 139: } -29,
{ 140: } 0,
{ 141: } -78,
{ 142: } 0,
{ 143: } 0,
{ 144: } 0,
{ 145: } -41,
{ 146: } -30,
{ 147: } 0,
{ 148: } 0,
{ 149: } 0,
{ 150: } 0,
{ 151: } 0,
{ 152: } -42,
{ 153: } -16,
{ 154: } 0,
{ 155: } 0,
{ 156: } 0,
{ 157: } -23,
{ 158: } 0,
{ 159: } 0,
{ 160: } -25
);

yyal : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 10,
{ 2: } 18,
{ 3: } 19,
{ 4: } 27,
{ 5: } 27,
{ 6: } 35,
{ 7: } 35,
{ 8: } 36,
{ 9: } 37,
{ 10: } 37,
{ 11: } 38,
{ 12: } 38,
{ 13: } 38,
{ 14: } 38,
{ 15: } 38,
{ 16: } 38,
{ 17: } 38,
{ 18: } 38,
{ 19: } 38,
{ 20: } 45,
{ 21: } 47,
{ 22: } 47,
{ 23: } 50,
{ 24: } 51,
{ 25: } 51,
{ 26: } 53,
{ 27: } 54,
{ 28: } 55,
{ 29: } 55,
{ 30: } 56,
{ 31: } 58,
{ 32: } 63,
{ 33: } 63,
{ 34: } 63,
{ 35: } 63,
{ 36: } 63,
{ 37: } 63,
{ 38: } 63,
{ 39: } 63,
{ 40: } 105,
{ 41: } 105,
{ 42: } 147,
{ 43: } 147,
{ 44: } 166,
{ 45: } 167,
{ 46: } 185,
{ 47: } 185,
{ 48: } 222,
{ 49: } 222,
{ 50: } 222,
{ 51: } 237,
{ 52: } 239,
{ 53: } 269,
{ 54: } 296,
{ 55: } 296,
{ 56: } 316,
{ 57: } 316,
{ 58: } 316,
{ 59: } 317,
{ 60: } 318,
{ 61: } 318,
{ 62: } 318,
{ 63: } 345,
{ 64: } 370,
{ 65: } 371,
{ 66: } 372,
{ 67: } 397,
{ 68: } 422,
{ 69: } 447,
{ 70: } 472,
{ 71: } 473,
{ 72: } 474,
{ 73: } 500,
{ 74: } 527,
{ 75: } 527,
{ 76: } 527,
{ 77: } 554,
{ 78: } 581,
{ 79: } 608,
{ 80: } 635,
{ 81: } 662,
{ 82: } 689,
{ 83: } 689,
{ 84: } 716,
{ 85: } 743,
{ 86: } 770,
{ 87: } 797,
{ 88: } 824,
{ 89: } 851,
{ 90: } 878,
{ 91: } 905,
{ 92: } 905,
{ 93: } 906,
{ 94: } 921,
{ 95: } 922,
{ 96: } 939,
{ 97: } 964,
{ 98: } 965,
{ 99: } 982,
{ 100: } 997,
{ 101: } 1027,
{ 102: } 1027,
{ 103: } 1027,
{ 104: } 1027,
{ 105: } 1042,
{ 106: } 1057,
{ 107: } 1072,
{ 108: } 1087,
{ 109: } 1112,
{ 110: } 1112,
{ 111: } 1114,
{ 112: } 1130,
{ 113: } 1147,
{ 114: } 1164,
{ 115: } 1181,
{ 116: } 1198,
{ 117: } 1215,
{ 118: } 1232,
{ 119: } 1249,
{ 120: } 1266,
{ 121: } 1283,
{ 122: } 1300,
{ 123: } 1317,
{ 124: } 1334,
{ 125: } 1351,
{ 126: } 1368,
{ 127: } 1385,
{ 128: } 1385,
{ 129: } 1385,
{ 130: } 1412,
{ 131: } 1427,
{ 132: } 1427,
{ 133: } 1429,
{ 134: } 1430,
{ 135: } 1430,
{ 136: } 1445,
{ 137: } 1445,
{ 138: } 1445,
{ 139: } 1445,
{ 140: } 1445,
{ 141: } 1460,
{ 142: } 1460,
{ 143: } 1486,
{ 144: } 1503,
{ 145: } 1541,
{ 146: } 1541,
{ 147: } 1541,
{ 148: } 1542,
{ 149: } 1557,
{ 150: } 1582,
{ 151: } 1598,
{ 152: } 1636,
{ 153: } 1636,
{ 154: } 1636,
{ 155: } 1651,
{ 156: } 1689,
{ 157: } 1714,
{ 158: } 1714,
{ 159: } 1729,
{ 160: } 1767
);

yyah : array [0..yynstates-1] of Integer = (
{ 0: } 9,
{ 1: } 17,
{ 2: } 18,
{ 3: } 26,
{ 4: } 26,
{ 5: } 34,
{ 6: } 34,
{ 7: } 35,
{ 8: } 36,
{ 9: } 36,
{ 10: } 37,
{ 11: } 37,
{ 12: } 37,
{ 13: } 37,
{ 14: } 37,
{ 15: } 37,
{ 16: } 37,
{ 17: } 37,
{ 18: } 37,
{ 19: } 44,
{ 20: } 46,
{ 21: } 46,
{ 22: } 49,
{ 23: } 50,
{ 24: } 50,
{ 25: } 52,
{ 26: } 53,
{ 27: } 54,
{ 28: } 54,
{ 29: } 55,
{ 30: } 57,
{ 31: } 62,
{ 32: } 62,
{ 33: } 62,
{ 34: } 62,
{ 35: } 62,
{ 36: } 62,
{ 37: } 62,
{ 38: } 62,
{ 39: } 104,
{ 40: } 104,
{ 41: } 146,
{ 42: } 146,
{ 43: } 165,
{ 44: } 166,
{ 45: } 184,
{ 46: } 184,
{ 47: } 221,
{ 48: } 221,
{ 49: } 221,
{ 50: } 236,
{ 51: } 238,
{ 52: } 268,
{ 53: } 295,
{ 54: } 295,
{ 55: } 315,
{ 56: } 315,
{ 57: } 315,
{ 58: } 316,
{ 59: } 317,
{ 60: } 317,
{ 61: } 317,
{ 62: } 344,
{ 63: } 369,
{ 64: } 370,
{ 65: } 371,
{ 66: } 396,
{ 67: } 421,
{ 68: } 446,
{ 69: } 471,
{ 70: } 472,
{ 71: } 473,
{ 72: } 499,
{ 73: } 526,
{ 74: } 526,
{ 75: } 526,
{ 76: } 553,
{ 77: } 580,
{ 78: } 607,
{ 79: } 634,
{ 80: } 661,
{ 81: } 688,
{ 82: } 688,
{ 83: } 715,
{ 84: } 742,
{ 85: } 769,
{ 86: } 796,
{ 87: } 823,
{ 88: } 850,
{ 89: } 877,
{ 90: } 904,
{ 91: } 904,
{ 92: } 905,
{ 93: } 920,
{ 94: } 921,
{ 95: } 938,
{ 96: } 963,
{ 97: } 964,
{ 98: } 981,
{ 99: } 996,
{ 100: } 1026,
{ 101: } 1026,
{ 102: } 1026,
{ 103: } 1026,
{ 104: } 1041,
{ 105: } 1056,
{ 106: } 1071,
{ 107: } 1086,
{ 108: } 1111,
{ 109: } 1111,
{ 110: } 1113,
{ 111: } 1129,
{ 112: } 1146,
{ 113: } 1163,
{ 114: } 1180,
{ 115: } 1197,
{ 116: } 1214,
{ 117: } 1231,
{ 118: } 1248,
{ 119: } 1265,
{ 120: } 1282,
{ 121: } 1299,
{ 122: } 1316,
{ 123: } 1333,
{ 124: } 1350,
{ 125: } 1367,
{ 126: } 1384,
{ 127: } 1384,
{ 128: } 1384,
{ 129: } 1411,
{ 130: } 1426,
{ 131: } 1426,
{ 132: } 1428,
{ 133: } 1429,
{ 134: } 1429,
{ 135: } 1444,
{ 136: } 1444,
{ 137: } 1444,
{ 138: } 1444,
{ 139: } 1444,
{ 140: } 1459,
{ 141: } 1459,
{ 142: } 1485,
{ 143: } 1502,
{ 144: } 1540,
{ 145: } 1540,
{ 146: } 1540,
{ 147: } 1541,
{ 148: } 1556,
{ 149: } 1581,
{ 150: } 1597,
{ 151: } 1635,
{ 152: } 1635,
{ 153: } 1635,
{ 154: } 1650,
{ 155: } 1688,
{ 156: } 1713,
{ 157: } 1713,
{ 158: } 1728,
{ 159: } 1766,
{ 160: } 1766
);

yygl : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 2,
{ 2: } 8,
{ 3: } 8,
{ 4: } 11,
{ 5: } 11,
{ 6: } 16,
{ 7: } 16,
{ 8: } 16,
{ 9: } 18,
{ 10: } 18,
{ 11: } 18,
{ 12: } 18,
{ 13: } 18,
{ 14: } 18,
{ 15: } 18,
{ 16: } 18,
{ 17: } 18,
{ 18: } 18,
{ 19: } 18,
{ 20: } 21,
{ 21: } 21,
{ 22: } 21,
{ 23: } 21,
{ 24: } 21,
{ 25: } 21,
{ 26: } 21,
{ 27: } 21,
{ 28: } 22,
{ 29: } 22,
{ 30: } 22,
{ 31: } 24,
{ 32: } 26,
{ 33: } 26,
{ 34: } 26,
{ 35: } 26,
{ 36: } 26,
{ 37: } 26,
{ 38: } 26,
{ 39: } 26,
{ 40: } 30,
{ 41: } 30,
{ 42: } 41,
{ 43: } 41,
{ 44: } 41,
{ 45: } 41,
{ 46: } 41,
{ 47: } 41,
{ 48: } 48,
{ 49: } 48,
{ 50: } 48,
{ 51: } 48,
{ 52: } 48,
{ 53: } 53,
{ 54: } 57,
{ 55: } 57,
{ 56: } 57,
{ 57: } 57,
{ 58: } 57,
{ 59: } 57,
{ 60: } 57,
{ 61: } 57,
{ 62: } 57,
{ 63: } 61,
{ 64: } 65,
{ 65: } 65,
{ 66: } 65,
{ 67: } 69,
{ 68: } 73,
{ 69: } 77,
{ 70: } 81,
{ 71: } 81,
{ 72: } 81,
{ 73: } 86,
{ 74: } 90,
{ 75: } 90,
{ 76: } 90,
{ 77: } 94,
{ 78: } 98,
{ 79: } 102,
{ 80: } 106,
{ 81: } 110,
{ 82: } 114,
{ 83: } 114,
{ 84: } 118,
{ 85: } 122,
{ 86: } 126,
{ 87: } 130,
{ 88: } 134,
{ 89: } 138,
{ 90: } 142,
{ 91: } 146,
{ 92: } 146,
{ 93: } 146,
{ 94: } 146,
{ 95: } 146,
{ 96: } 146,
{ 97: } 150,
{ 98: } 152,
{ 99: } 152,
{ 100: } 152,
{ 101: } 157,
{ 102: } 157,
{ 103: } 157,
{ 104: } 157,
{ 105: } 157,
{ 106: } 157,
{ 107: } 157,
{ 108: } 157,
{ 109: } 161,
{ 110: } 161,
{ 111: } 161,
{ 112: } 161,
{ 113: } 161,
{ 114: } 161,
{ 115: } 161,
{ 116: } 161,
{ 117: } 161,
{ 118: } 161,
{ 119: } 161,
{ 120: } 161,
{ 121: } 161,
{ 122: } 161,
{ 123: } 161,
{ 124: } 161,
{ 125: } 161,
{ 126: } 161,
{ 127: } 161,
{ 128: } 161,
{ 129: } 161,
{ 130: } 165,
{ 131: } 165,
{ 132: } 165,
{ 133: } 166,
{ 134: } 166,
{ 135: } 166,
{ 136: } 166,
{ 137: } 166,
{ 138: } 166,
{ 139: } 166,
{ 140: } 166,
{ 141: } 166,
{ 142: } 166,
{ 143: } 170,
{ 144: } 170,
{ 145: } 177,
{ 146: } 177,
{ 147: } 177,
{ 148: } 177,
{ 149: } 177,
{ 150: } 181,
{ 151: } 181,
{ 152: } 181,
{ 153: } 181,
{ 154: } 181,
{ 155: } 181,
{ 156: } 188,
{ 157: } 192,
{ 158: } 192,
{ 159: } 192,
{ 160: } 199
);

yygh : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 7,
{ 2: } 7,
{ 3: } 10,
{ 4: } 10,
{ 5: } 15,
{ 6: } 15,
{ 7: } 15,
{ 8: } 17,
{ 9: } 17,
{ 10: } 17,
{ 11: } 17,
{ 12: } 17,
{ 13: } 17,
{ 14: } 17,
{ 15: } 17,
{ 16: } 17,
{ 17: } 17,
{ 18: } 17,
{ 19: } 20,
{ 20: } 20,
{ 21: } 20,
{ 22: } 20,
{ 23: } 20,
{ 24: } 20,
{ 25: } 20,
{ 26: } 20,
{ 27: } 21,
{ 28: } 21,
{ 29: } 21,
{ 30: } 23,
{ 31: } 25,
{ 32: } 25,
{ 33: } 25,
{ 34: } 25,
{ 35: } 25,
{ 36: } 25,
{ 37: } 25,
{ 38: } 25,
{ 39: } 29,
{ 40: } 29,
{ 41: } 40,
{ 42: } 40,
{ 43: } 40,
{ 44: } 40,
{ 45: } 40,
{ 46: } 40,
{ 47: } 47,
{ 48: } 47,
{ 49: } 47,
{ 50: } 47,
{ 51: } 47,
{ 52: } 52,
{ 53: } 56,
{ 54: } 56,
{ 55: } 56,
{ 56: } 56,
{ 57: } 56,
{ 58: } 56,
{ 59: } 56,
{ 60: } 56,
{ 61: } 56,
{ 62: } 60,
{ 63: } 64,
{ 64: } 64,
{ 65: } 64,
{ 66: } 68,
{ 67: } 72,
{ 68: } 76,
{ 69: } 80,
{ 70: } 80,
{ 71: } 80,
{ 72: } 85,
{ 73: } 89,
{ 74: } 89,
{ 75: } 89,
{ 76: } 93,
{ 77: } 97,
{ 78: } 101,
{ 79: } 105,
{ 80: } 109,
{ 81: } 113,
{ 82: } 113,
{ 83: } 117,
{ 84: } 121,
{ 85: } 125,
{ 86: } 129,
{ 87: } 133,
{ 88: } 137,
{ 89: } 141,
{ 90: } 145,
{ 91: } 145,
{ 92: } 145,
{ 93: } 145,
{ 94: } 145,
{ 95: } 145,
{ 96: } 149,
{ 97: } 151,
{ 98: } 151,
{ 99: } 151,
{ 100: } 156,
{ 101: } 156,
{ 102: } 156,
{ 103: } 156,
{ 104: } 156,
{ 105: } 156,
{ 106: } 156,
{ 107: } 156,
{ 108: } 160,
{ 109: } 160,
{ 110: } 160,
{ 111: } 160,
{ 112: } 160,
{ 113: } 160,
{ 114: } 160,
{ 115: } 160,
{ 116: } 160,
{ 117: } 160,
{ 118: } 160,
{ 119: } 160,
{ 120: } 160,
{ 121: } 160,
{ 122: } 160,
{ 123: } 160,
{ 124: } 160,
{ 125: } 160,
{ 126: } 160,
{ 127: } 160,
{ 128: } 160,
{ 129: } 164,
{ 130: } 164,
{ 131: } 164,
{ 132: } 165,
{ 133: } 165,
{ 134: } 165,
{ 135: } 165,
{ 136: } 165,
{ 137: } 165,
{ 138: } 165,
{ 139: } 165,
{ 140: } 165,
{ 141: } 165,
{ 142: } 169,
{ 143: } 169,
{ 144: } 176,
{ 145: } 176,
{ 146: } 176,
{ 147: } 176,
{ 148: } 176,
{ 149: } 180,
{ 150: } 180,
{ 151: } 180,
{ 152: } 180,
{ 153: } 180,
{ 154: } 180,
{ 155: } 187,
{ 156: } 191,
{ 157: } 191,
{ 158: } 191,
{ 159: } 198,
{ 160: } 198
);

yyr : array [1..yynrules] of YYRRec = (
{ 1: } ( len: 0; sym: -24 ),
{ 2: } ( len: 2; sym: -24 ),
{ 3: } ( len: 2; sym: -24 ),
{ 4: } ( len: 2; sym: -24 ),
{ 5: } ( len: 0; sym: -8 ),
{ 6: } ( len: 1; sym: -8 ),
{ 7: } ( len: 2; sym: -8 ),
{ 8: } ( len: 0; sym: -10 ),
{ 9: } ( len: 1; sym: -10 ),
{ 10: } ( len: 2; sym: -10 ),
{ 11: } ( len: 0; sym: -4 ),
{ 12: } ( len: 2; sym: -4 ),
{ 13: } ( len: 2; sym: -4 ),
{ 14: } ( len: 2; sym: -4 ),
{ 15: } ( len: 3; sym: -4 ),
{ 16: } ( len: 5; sym: -4 ),
{ 17: } ( len: 0; sym: -7 ),
{ 18: } ( len: 1; sym: -7 ),
{ 19: } ( len: 4; sym: -7 ),
{ 20: } ( len: 0; sym: -9 ),
{ 21: } ( len: 1; sym: -9 ),
{ 22: } ( len: 2; sym: -9 ),
{ 23: } ( len: 7; sym: -9 ),
{ 24: } ( len: 5; sym: -9 ),
{ 25: } ( len: 9; sym: -9 ),
{ 26: } ( len: 3; sym: -9 ),
{ 27: } ( len: 3; sym: -9 ),
{ 28: } ( len: 3; sym: -9 ),
{ 29: } ( len: 3; sym: -9 ),
{ 30: } ( len: 4; sym: -9 ),
{ 31: } ( len: 1; sym: -9 ),
{ 32: } ( len: 1; sym: -9 ),
{ 33: } ( len: 0; sym: -11 ),
{ 34: } ( len: 1; sym: -11 ),
{ 35: } ( len: 3; sym: -11 ),
{ 36: } ( len: 2; sym: -12 ),
{ 37: } ( len: 0; sym: -13 ),
{ 38: } ( len: 1; sym: -13 ),
{ 39: } ( len: 3; sym: -13 ),
{ 40: } ( len: 1; sym: -19 ),
{ 41: } ( len: 2; sym: -19 ),
{ 42: } ( len: 3; sym: -20 ),
{ 43: } ( len: 2; sym: -14 ),
{ 44: } ( len: 4; sym: -14 ),
{ 45: } ( len: 0; sym: -16 ),
{ 46: } ( len: 1; sym: -16 ),
{ 47: } ( len: 2; sym: -16 ),
{ 48: } ( len: 2; sym: -5 ),
{ 49: } ( len: 1; sym: -6 ),
{ 50: } ( len: 1; sym: -6 ),
{ 51: } ( len: 3; sym: -15 ),
{ 52: } ( len: 5; sym: -15 ),
{ 53: } ( len: 1; sym: -25 ),
{ 54: } ( len: 3; sym: -25 ),
{ 55: } ( len: 1; sym: -21 ),
{ 56: } ( len: 1; sym: -2 ),
{ 57: } ( len: 1; sym: -2 ),
{ 58: } ( len: 1; sym: -2 ),
{ 59: } ( len: 1; sym: -2 ),
{ 60: } ( len: 1; sym: -2 ),
{ 61: } ( len: 0; sym: -3 ),
{ 62: } ( len: 3; sym: -3 ),
{ 63: } ( len: 3; sym: -3 ),
{ 64: } ( len: 3; sym: -3 ),
{ 65: } ( len: 3; sym: -3 ),
{ 66: } ( len: 3; sym: -3 ),
{ 67: } ( len: 3; sym: -3 ),
{ 68: } ( len: 3; sym: -3 ),
{ 69: } ( len: 3; sym: -3 ),
{ 70: } ( len: 2; sym: -3 ),
{ 71: } ( len: 1; sym: -3 ),
{ 72: } ( len: 1; sym: -3 ),
{ 73: } ( len: 2; sym: -3 ),
{ 74: } ( len: 3; sym: -3 ),
{ 75: } ( len: 4; sym: -3 ),
{ 76: } ( len: 3; sym: -3 ),
{ 77: } ( len: 1; sym: -3 ),
{ 78: } ( len: 4; sym: -3 ),
{ 79: } ( len: 3; sym: -3 ),
{ 80: } ( len: 3; sym: -3 ),
{ 81: } ( len: 3; sym: -3 ),
{ 82: } ( len: 3; sym: -3 ),
{ 83: } ( len: 3; sym: -3 ),
{ 84: } ( len: 3; sym: -3 ),
{ 85: } ( len: 3; sym: -3 ),
{ 86: } ( len: 2; sym: -3 ),
{ 87: } ( len: 1; sym: -3 ),
{ 88: } ( len: 1; sym: -3 ),
{ 89: } ( len: 1; sym: -22 ),
{ 90: } ( len: 1; sym: -18 ),
{ 91: } ( len: 0; sym: -23 ),
{ 92: } ( len: 1; sym: -23 ),
{ 93: } ( len: 3; sym: -23 )
);


const _error = 256; (* error token *)

function yyact(state, sym : Integer; var act : Integer) : Boolean;
  (* search action table *)
  var k : Integer;
  begin
    k := yyal[state];
    while (k<=yyah[state]) and (yya[k].sym<>sym) do inc(k);
    if k>yyah[state] then
      yyact := false
    else
      begin
        act := yya[k].act;
        yyact := true;
      end;
  end(*yyact*);

function yygoto(state, sym : Integer; var nstate : Integer) : Boolean;
  (* search goto table *)
  var k : Integer;
  begin
    k := yygl[state];
    while (k<=yygh[state]) and (yyg[k].sym<>sym) do inc(k);
    if k>yygh[state] then
      yygoto := false
    else
      begin
        nstate := yyg[k].act;
        yygoto := true;
      end;
  end(*yygoto*);

label parse, next, error, errlab, shift, reduce, accept, abort;

begin(*yyparse*)

  (* initialize: *)

  yystate := 0; yychar := -1; yynerrs := 0; yyerrflag := 0; yysp := 0;

{$ifdef yydebug}
  yydebug := true;
{$else}
  yydebug := false;
{$endif}

parse:

  (* push state and value: *)

  inc(yysp);
  if yysp>yymaxdepth then
    begin
      yyerror('yyparse stack overflow');
      goto abort;
    end;
  yys[yysp] := yystate; yyv[yysp] := yyval;

next:

  if (yyd[yystate]=0) and (yychar=-1) then
    (* get next symbol *)
    begin
      yychar := yylex; if yychar<0 then yychar := 0;
    end;

  if yydebug then writeln('state ', yystate, ', char ', yychar);

  (* determine parse action: *)

  yyn := yyd[yystate];
  if yyn<>0 then goto reduce; (* simple state *)

  (* no default action; search parse table *)

  if not yyact(yystate, yychar, yyn) then goto error
  else if yyn>0 then                      goto shift
  else if yyn<0 then                      goto reduce
  else                                    goto accept;

error:

  (* error; start error recovery: *)

  if yyerrflag=0 then yyerror('syntax error');

errlab:

  if yyerrflag=0 then inc(yynerrs);     (* new error *)

  if yyerrflag<=2 then                  (* incomplete recovery; try again *)
    begin
      yyerrflag := 3;
      (* uncover a state with shift action on error token *)
      while (yysp>0) and not ( yyact(yys[yysp], _error, yyn) and
                               (yyn>0) ) do
        begin
          if yydebug then
            if yysp>1 then
              writeln('error recovery pops state ', yys[yysp], ', uncovers ',
                      yys[yysp-1])
            else
              writeln('error recovery fails ... abort');
          dec(yysp);
        end;
      if yysp=0 then goto abort; (* parser has fallen from stack; abort *)
      yystate := yyn;            (* simulate shift on error *)
      goto parse;
    end
  else                                  (* no shift yet; discard symbol *)
    begin
      if yydebug then writeln('error recovery discards char ', yychar);
      if yychar=0 then goto abort; (* end of input; abort *)
      yychar := -1; goto next;     (* clear lookahead char and try again *)
    end;

shift:

  (* go to new state, clear lookahead character: *)

  yystate := yyn; yychar := -1; yyval := yylval;
  if yyerrflag>0 then dec(yyerrflag);

  goto parse;

reduce:

  (* execute action, pop rule from stack, and go to next state: *)

  if yydebug then writeln('reduce ', -yyn);

  yyflag := yyfnone; yyaction(-yyn);
  dec(yysp, yyr[-yyn].len);
  if yygoto(yys[yysp], yyr[-yyn].sym, yyn) then yystate := yyn;

  (* handle action calls to yyaccept, yyabort and yyerror: *)

  case yyflag of
    yyfaccept : goto accept;
    yyfabort  : goto abort;
    yyferror  : goto errlab;
  end;

  goto parse;

accept:

  yyparse := 0; exit;

abort:

  yyparse := 1; exit;

end(*yyparse*);


{$I gmclex.pas}

var
	output : textfile;

function typeExpr(expr : Expr) : Expr; forward;

function optimizeExpr(expr : Expr) : Expr; forward;

procedure showExpr(expr : Expr); forward;

function typeToString(typ : integer) : string; forward;


procedure emit(line : string);
begin
  writeln(output, line);
end;

procedure compilerError(lineNum : integer; msg : string);
begin
  writeln('error (line ', lineNum, ', file ', yyfname, '): ', msg);
 
  yyerrors := true;
end;

procedure updateLabel(id : string; lbl : integer);
var
		a : integer;
    e : Env_Entry;
begin
  for a := 0 to environment.count - 1 do
    begin
    e := environment[a];
   
    if (e.id = id) then
      begin
			e.lbl := lbl;
      break; 
      end;
    end;
end;

procedure addEnvironment(lineNum : integer; id : string; typ, lbl, varTyp : integer);
var
	  e : Env_Entry;
begin
  if (lookupEnv(id) <> nil) then
    begin
    compilerError(lineNum, 'identifier redeclared');
    exit;
    end;
       
  e := Env_Entry.Create;
  e.id := id;
  e.typ := typ;
	e.lbl := lbl;
	e.varTyp := varTyp;
	
	if (varTyp = VARTYPE_GLOBAL) then
	  begin
	  e.displ := globalCount;
	  inc(globalCount);
	  end
	else
	 	e.displ := 0;		

  environment.add(e);
end;

function lookupEnv(id : string) : Env_Entry;
var
		a : integer;
    e : Env_Entry;
begin
  Result := nil;
 
  for a := 0 to environment.count - 1 do
    begin
    e := environment[a];
   
    if (e.id = id) then
      begin
      Result := e;
      break; 
      end;
    end;
end;

function typeToString(typ : integer) : string;
begin
  case typ of 
    _INT 		: Result := 'int';
    _STRING : Result := 'string';
    _FLOAT  : Result := 'float';
    _VOID		: Result := 'void';
    _EXTERNAL : Result := 'external';
   
    else Result := 'unknown (' + IntToStr(typ) + ')';
  end;
end;

function coerce(expr : Expr; src, dest: integer) : Expr;
var
	cn : Expr_Conv;
begin
  if ((src = _INT) or (src = _EXTERNAL)) and (dest = _FLOAT) then
    begin
    cn := Expr_Conv.Create;
		cn.ex := expr;
		cn.cnv := CONV_TO_FLOAT;
		cn.originaltyp := src;
		cn.typ := _FLOAT;

		Result := cn;
    end
  else
  if ((src = _INT) or (src = _FLOAT) or (src = _EXTERNAL)) and (dest = _STRING) then
    begin
    cn := Expr_Conv.Create;
		cn.ex := expr;
		cn.cnv := CONV_TO_STRING;
		cn.originaltyp := src;
		cn.typ := _STRING;

		Result := cn;
    end
  else
    begin
    compilerError(expr.lineNum, 'no appropriate conversion from ''' + typeToString(src) + ''' to ''' + typeToString(dest) + '''');
		Result := expr;
    end;
end;

function typeExpr(expr : Expr) : Expr;
var
	  t1, t2 : integer;
begin
  Result := expr;
  
  if (expr = nil) then
    exit;

	Result.typ := _VOID;

  if (expr is Expr_Op) then
    begin   
    Expr_Op(expr).le := typeExpr(Expr_Op(expr).le);
    Expr_Op(expr).re := typeExpr(Expr_Op(expr).re);

		t1 := Expr_Op(expr).le.typ;
		t2 := Expr_Op(expr).re.typ;
		
    if (t1 <> t2) and (t1 <> _EXTERNAL) and (t2 <> _EXTERNAL) then
      Expr_Op(expr).re := coerce(Expr_Op(expr).re, t2, t1);

    expr.typ := t1;
    end
  else
  if (expr is Expr_Func) then
    begin
    Expr_Func(expr).body := typeExpr(Expr_Func(expr).body);

		expr.typ := lookupEnv(Expr_Func(expr).id).typ;
		end
  else
  if (expr is Expr_Return) then
    begin
		t1 := lookupEnv(Expr_Func(expr).id).typ;
		
		if (t1 = _VOID) then
		  begin
		  if (Expr_Return(expr).ret <> nil) then
		    compilerError(expr.lineNum, 'can not assign return value to void function');
		    
		  end
		else
		  begin
			Expr_Return(expr).ret := typeExpr(Expr_Return(expr).ret);
  		t2 := Expr_Return(expr).ret.typ;
		
  		if (t1 <> t2) and (t1 <> _EXTERNAL) and (t2 <> _EXTERNAL) then
  		  Expr_Return(expr).ret := coerce(Expr_Return(expr).ret, t2, t1);
      end;
    end
  else
  if (expr is Expr_Call) then
    begin
		Expr_Call(expr).params := typeExpr(Expr_Call(expr).params);

		t1 := lookupEnv(Expr_Call(expr).id).typ;
		 
    if (t1 <> -1) then
	    expr.typ := t1
    else
	    expr.typ := _VOID;
		end
  else
  if (expr is Expr_ConstInt) then
    expr.typ := _INT
  else
  if (expr is Expr_ConstFloat) then
    expr.typ := _FLOAT
  else
  if (expr is Expr_External) then
    expr.typ := _EXTERNAL
  else
  if (expr is Expr_String) then
    expr.typ := _STRING
  else
  if (expr is Expr_Id) then
    begin
		t1 := lookupEnv(Expr_Id(expr).id).typ;
   
    if (t1 <> -1) then
      expr.typ := t1
    else
      expr.typ := _VOID;
    end
  else
  if (expr is Expr_If) then
    begin
    Expr_If(expr).ce := typeExpr(Expr_If(expr).ce);
    Expr_If(expr).le := typeExpr(Expr_If(expr).le);
    Expr_If(expr).re := typeExpr(Expr_If(expr).re);

    expr.typ := _VOID;
		end
  else
  if (expr is Expr_Seq) then
    begin
    Expr_Seq(expr).ex := typeExpr(Expr_Seq(expr).ex);
    Expr_Seq(expr).seq := typeExpr(Expr_Seq(expr).seq);

		expr.typ := _VOID;
    end
  else
  if (expr is Expr_Assign) then
    begin
    Expr_Assign(expr).id := typeExpr(Expr_Assign(expr).id);
    Expr_Assign(expr).ex := typeExpr(Expr_Assign(expr).ex);

		t1 := Expr_Assign(expr).id.typ;
		t2 := Expr_Assign(expr).ex.typ;

    if (t1 <> t2) and (t1 <> _EXTERNAL) and (t2 <> _EXTERNAL) then
      Expr_Assign(expr).ex := coerce(Expr_Assign(expr).ex, t2, t1);

		expr.typ := _VOID;
    end
  else
  if (expr is Expr_Special) then
    begin
    Expr_Special(expr).ex := typeExpr(Expr_Special(expr).ex);

		expr.typ := Expr_Special(expr).ex.typ;
    end
  else
  if (expr is Expr_Loop) then
    begin
    Expr_Loop(expr).init := typeExpr(Expr_Loop(expr).init);
    Expr_Loop(expr).ce := typeExpr(Expr_Loop(expr).ce);
    Expr_Loop(expr).step := typeExpr(Expr_Loop(expr).step);
    Expr_Loop(expr).body := typeExpr(Expr_Loop(expr).body);
    end
  else
  if (expr is Expr_Cast) then
    begin
    Expr_Cast(expr).ex := typeExpr(Expr_Cast(expr).ex);
    
    t1 := Expr_Cast(expr).ex.typ;

    Result := coerce(Expr_Cast(expr).ex, t1, Expr_Cast(expr).desttype);
    
    Expr_Cast(expr).Free;
    end
  else
  if (expr is Expr_Rel) then 
    begin
    Expr_Rel(expr).le := typeExpr(Expr_Rel(expr).le);
    Expr_Rel(expr).re := typeExpr(Expr_Rel(expr).re);

		t1 := Expr_Rel(expr).le.typ;
		t2 := Expr_Rel(expr).re.typ;

    if (t1 <> t2) and (t1 <> _EXTERNAL) and (t2 <> _EXTERNAL) then
      compilerError(expr.lineNum, 'no appropriate conversion from ''' + typeToString(t1) + ''' to ''' + typeToString(t2) + '''');

    expr.typ := _INT;
    end
  else
  if (expr is Expr_Not) then 
    begin
	  Expr_Not(expr).ex := typeExpr(Expr_Not(expr).ex);

		t1 := Expr_Not(expr).ex.typ;

    if (t1 <> _INT) then
      compilerError(expr.lineNum, 'impossible to negate non-integer value');

    expr.typ := _INT;
    end
  else
  if (expr is Expr_And) then 
    begin
	  Expr_And(expr).le := typeExpr(Expr_And(expr).le);
    Expr_And(expr).re := typeExpr(Expr_And(expr).re);

		t1 := Expr_And(expr).le.typ;
		t2 := Expr_And(expr).re.typ;

    if (t1 <> _INT) or (t2 <> _INT) then
      compilerError(expr.lineNum, 'impossible to and non-integer value');

    expr.typ := _INT;
    end
  else
  if (expr is Expr_Or) then 
    begin
	  Expr_Or(expr).le := typeExpr(Expr_Or(expr).le);
    Expr_Or(expr).re := typeExpr(Expr_Or(expr).re);

		t1 := Expr_Or(expr).le.typ;
		t2 := Expr_Or(expr).re.typ;

    if (t1 <> _INT) or (t2 <> _INT) then
      compilerError(expr.lineNum, 'impossible to or non-integer value');

    expr.typ := _INT;
    end;
end;

function optimizeExpr(expr : Expr) : Expr;
var
	bval, lval, rval : integer;
begin
  Result := expr;
  
  if (expr = nil) then
    exit;

  if (expr is Expr_Op) then
    begin
    Expr_Op(expr).le := optimizeExpr(Expr_Op(expr).le);
    Expr_Op(expr).re := optimizeExpr(Expr_Op(expr).re);

    if (Expr_Op(expr).le is Expr_ConstInt) and (Expr_Op(expr).re is Expr_ConstInt) then
      begin
      lval := Expr_ConstInt(Expr_Op(expr).le).value;
      rval := Expr_ConstInt(Expr_Op(expr).re).value;

      case Expr_Op(expr).op of
        '+': begin
             Result := Expr_ConstInt.Create;
             Expr_ConstInt(Result).value := lval + rval;
             end;
        '-': begin
             Result := Expr_ConstInt.Create;
             Expr_ConstInt(Result).value := lval - rval;
             end;
        '*': begin
             Result := Expr_ConstInt.Create;
             Expr_ConstInt(Result).value := lval * rval;
             end;
        '/': begin
             Result := Expr_ConstInt.Create;
             Expr_ConstInt(Result).value := lval div rval;
             end;
        '%': begin
             Result := Expr_ConstInt.Create;
             Expr_ConstInt(Result).value := lval mod rval;
             end;
        '&': begin
             Result := Expr_ConstInt.Create;
             Expr_ConstInt(Result).value := lval and rval;
             end;
        '|': begin
             Result := Expr_ConstInt.Create;
             Expr_ConstInt(Result).value := lval or rval;
             end;
      end;
   
			Expr_Op(expr).le.Free;
			Expr_Op(expr).re.Free;
      expr.Free;
      end;
    end
  else
  if (expr is Expr_Seq) then
    begin
    Expr_Seq(expr).ex := optimizeExpr(Expr_Seq(expr).ex);
    Expr_Seq(expr).seq := optimizeExpr(Expr_Seq(expr).seq);
    end
  else
  if (expr is Expr_Func) then
    begin
    Expr_Func(expr).body := optimizeExpr(Expr_Func(expr).body);
    end
  else
  if (expr is Expr_Return) then
    begin
    Expr_Return(expr).ret := optimizeExpr(Expr_Return(expr).ret);
    end
  else
  if (expr is Expr_Assign) then
    begin
    Expr_Assign(expr).ex := optimizeExpr(Expr_Assign(expr).ex);
    end
  else
  if (expr is Expr_Call) then
    begin
    Expr_Call(expr).params := optimizeExpr(Expr_Call(expr).params);
    end
  else
  if (expr is Expr_Conv) then
    begin
    Expr_Conv(expr).ex := optimizeExpr(Expr_Conv(expr).ex);

		case Expr_Conv(expr).cnv of
 			 CONV_TO_FLOAT : if (Expr_Conv(expr).ex is Expr_ConstInt) then
                         begin
                         Result := Expr_ConstFloat.Create;
                         Expr_ConstFloat(Result).value := Expr_ConstInt(Expr_Conv(expr).ex).value;
        
        								 Expr_Conv(expr).ex.Free;
        								 expr.Free;
                         end;
  			 CONV_TO_INT : if (Expr_Conv(expr).ex is Expr_ConstFloat) then
                         begin
                         Result := Expr_ConstInt.Create;
                         Expr_ConstInt(Result).value := trunc(Expr_ConstFloat(Expr_Conv(expr).ex).value);
        
        								 Expr_Conv(expr).ex.Free;
        								 expr.Free;
                         end;
    end;
    end
  else
  if (expr is Expr_If) then
    begin
    Expr_If(expr).ce := optimizeExpr(Expr_If(expr).ce); 

    if (Expr_If(expr).ce is Expr_ConstInt) then
      begin
      bval := Expr_ConstInt(Expr_If(expr).ce).value;

      if (bval = 1) then
        Result := Expr_If(expr).le
      else
        Result := Expr_If(expr).re;
      end;
    end
  else
  if (expr is Expr_Loop) then
    begin
    Expr_Loop(expr).init := optimizeExpr(Expr_Loop(expr).init);
    Expr_Loop(expr).ce := optimizeExpr(Expr_Loop(expr).ce);
    Expr_Loop(expr).step := optimizeExpr(Expr_Loop(expr).step);
    Expr_Loop(expr).body := optimizeExpr(Expr_Loop(expr).body);
    end  
  else
  if (expr is Expr_Rel) then 
    begin
    Expr_Rel(expr).le := optimizeExpr(Expr_Rel(expr).le);
    Expr_Rel(expr).re := optimizeExpr(Expr_Rel(expr).re);
    end
  else
  if (expr is Expr_And) then 
    begin
    Expr_And(expr).le := optimizeExpr(Expr_And(expr).le);
    Expr_And(expr).re := optimizeExpr(Expr_And(expr).re);

    if (Expr_And(expr).le is Expr_ConstInt) and (Expr_And(expr).re is Expr_ConstInt) then
      begin
      lval := Expr_ConstInt(Expr_And(expr).le).value;
      rval := Expr_ConstInt(Expr_And(expr).re).value;

      Result := Expr_ConstInt.Create;
      Expr_ConstInt(Result).value := lval and rval;

      Expr_And(expr).le.Free;
      Expr_And(expr).re.Free;
      expr.Free;
      end
    else
		if (Expr_And(expr).le is Expr_ConstInt) then
		  begin
      lval := Expr_ConstInt(Expr_And(expr).le).value;
      
      if (lval = 1) then
        begin
        Result := Expr_And(expr).re;
        Expr_And(expr).le.Free;
        expr.Free;
        end
      else
        begin
        Result := Expr_And(expr).le;
        Expr_And(expr).re.Free;
        expr.Free;
        end;
      end
    else
		if (Expr_And(expr).re is Expr_ConstInt) then
		  begin
      lval := Expr_ConstInt(Expr_And(expr).re).value;
      
      if (lval = 1) then
        begin
        Result := Expr_And(expr).le;
        Expr_And(expr).re.Free;
        expr.Free;
        end
      else
        begin
        Result := Expr_And(expr).re;
        Expr_And(expr).le.Free;
        expr.Free;
        end;
      end; 
    end
  else
  if (expr is Expr_Or) then 
    begin
    Expr_Or(expr).le := optimizeExpr(Expr_Or(expr).le);
    Expr_Or(expr).re := optimizeExpr(Expr_Or(expr).re);

    if (Expr_Or(expr).le is Expr_ConstInt) and (Expr_Or(expr).re is Expr_ConstInt) then
      begin
      lval := Expr_ConstInt(Expr_Or(expr).le).value;
      rval := Expr_ConstInt(Expr_Or(expr).re).value;

      Result := Expr_ConstInt.Create;
      Expr_ConstInt(Result).value := lval and rval;

      Expr_Or(expr).le.Free;
      Expr_Or(expr).re.Free;
      expr.Free;
      end
    else
		if (Expr_Or(expr).le is Expr_ConstInt) then
		  begin
      lval := Expr_ConstInt(Expr_Or(expr).le).value;
      
      if (lval = 1) then
        begin
        Result := Expr_Or(expr).le;
        Expr_Or(expr).re.Free;
        expr.Free;
        end
      else
        begin
        Result := Expr_Or(expr).re;
        Expr_Or(expr).le.Free;
        expr.Free;
        end;
      end
    else
		if (Expr_Or(expr).re is Expr_ConstInt) then
		  begin
      lval := Expr_ConstInt(Expr_Or(expr).re).value;
      
      if (lval = 1) then
        begin
        Result := Expr_Or(expr).re;
        Expr_Or(expr).le.Free;
        expr.Free;
        end
      else
        begin
        Result := Expr_Or(expr).le;
        Expr_Or(expr).re.Free;
        expr.Free;
        end;
      end; 
    end
  else
  if (expr is Expr_Not) then 
    begin
    Expr_Not(expr).ex := optimizeExpr(Expr_Not(expr).ex);

		if (Expr_Not(expr).ex is Expr_ConstInt) then
		  begin
      lval := Expr_ConstInt(Expr_Not(expr).ex).value;
      
      Result := Expr_ConstInt.Create;
      Expr_ConstInt(Result).value := not lval;

      Expr_Not(expr).ex.Free;
      expr.Free;
      end;
    end;
end;

procedure showExpr(expr : Expr);
var
	t : integer;
	num, displ, pdispl : integer;
	e : Env_Entry;
begin
  if (expr = nil) then
    exit;

  if (expr is Expr_Op) then
    begin
    showExpr(Expr_Op(expr).le);
    showExpr(Expr_Op(expr).re);

    case Expr_Op(expr).op of
      '+': emit('ADD');
      '-': emit('SUB');
      '*': emit('MUL');
      '/': emit('DIV');
			'%': emit('MOD');
			'&': emit('AND');
			'|': emit('OR');
    end;
    end
  else
  if (expr is Expr_ConstInt) then
    emit('PUSHI ' + IntToStr(Expr_ConstInt(expr).value))
  else
  if (expr is Expr_ConstFloat) then
    emit('PUSHF ' + FloatToStr(Expr_ConstFloat(expr).value))
  else
  if (expr is Expr_String) then
    emit('PUSHS ' + Expr_String(expr).value)
  else
  if (expr is Expr_If) then
    begin
    showExpr(Expr_If(expr).ce); 

    if (Expr_If(expr).re = nil) and (Expr_If(expr).le = nil) then
      begin
      end
    else
    if (Expr_If(expr).re <> nil) then
      begin
      emit('JZ L' + IntToStr(Expr_If(expr).lElse));
      emit('L' + IntToStr(Expr_If(expr).lThen) + ':');

      showExpr(Expr_If(expr).le);

      emit('JMP L' + IntToStr(Expr_If(expr).lAfter));
	    emit('L' + IntToStr(Expr_If(expr).lElse) + ':');
	    showExpr(Expr_If(expr).re);
			end
    else 
      begin
      emit('JZ L' + IntToStr(Expr_If(expr).lAfter));
      emit('L' + IntToStr(Expr_If(expr).lThen) + ':');
      showExpr(Expr_If(expr).le);
      end;

    emit('L' + IntToStr(Expr_If(expr).lAfter) + ':');
    end
  else
  if (expr is Expr_Func) then
    begin
    if (Expr_Func(expr).body <> nil) then
      begin
      displ := 1;
      pdispl := -2;
      num := 0;
      
      for t := 0 to environment.count - 1 do
        begin
        e := environment[t];
        
        if (pos(Expr_Func(expr).id + ':', e.id) > 0) then
          begin
          if (e.varTyp = VARTYPE_PARAM) then
            begin
            inc(num);
            e.displ := pdispl;
            dec(pdispl);
            end
          else
          if (e.varTyp = VARTYPE_LOCAL) then
            begin
            e.displ := displ;
            inc(displ);
            end;
          end;
        end;
        
	    emit('L' + IntToStr(Expr_Func(expr).lStart) + ':');
	    emit('PUSHBP');
	    emit('MSPBP');
	    
	    if (displ > 1) then
  	    emit('ADDSP ' + IntToStr(displ - 1));

			showExpr(Expr_Func(expr).body);
			
			if (expr.typ <> _VOID) then
			  begin
			  emit('POPDISP ' + IntToStr(pdispl + 1));
			  dec(num);
			  end;
			 
      emit('MBPSP');
      emit('POPBP');

			if (num > 0) then
			  begin
			  emit('MTSD ' + IntToStr(num)); 
  			  
  			emit('SUBSP ' + IntToStr(num));
  			end;
  			
			emit('RET');
	    end;
    end
  else
  if (expr is Expr_Return) then
    begin
    showExpr(Expr_Return(expr).ret);
    end
  else
  if (expr is Expr_Call) then
    begin
		t := lookupEnv(Expr_Call(expr).id).lbl;

    if (t > 0) then
      begin
  		showExpr(Expr_Call(expr).params);		
  		emit('CALL L' + IntToStr(t));
			end
    else
    if (t = -1) then
      begin
  		showExpr(Expr_Call(expr).params);		
  		emit('CALLE ' + Expr_Call(expr).id);
			end;
    end
  else
  if (expr is Expr_Seq) then
    begin
    showExpr(Expr_Seq(expr).ex);
    showExpr(Expr_Seq(expr).seq);
    end
  else
  if (expr is Expr_Id) then
    begin
    e := lookupEnv(Expr_Id(expr).id);
    
    if (e.varTyp = VARTYPE_GLOBAL) then
      emit('PUSHR R' + IntToStr(e.displ))
    else
      emit('PUSHDISP ' + IntToStr(e.displ));
    end 
  else
  if (expr is Expr_External) then
    begin
    e := lookupEnv(Expr_External(expr).id);
    
    if (e.varTyp = VARTYPE_GLOBAL) then
      emit('PUSHR R' + IntToStr(e.displ))
    else
      emit('PUSHDISP ' + IntToStr(e.displ));
      
		emit('PUSHS ' + Expr_External(expr).assoc);
    emit('GET');
    end
  else
  if (expr is Expr_Assign) then
    begin
    showExpr(Expr_Assign(expr).ex);

    e := lookupEnv(Expr_Id(Expr_Assign(expr).id).id);

{		if (e.typ = _EXTERNAL) then
      emit('GET'); }
      
    if (e.varTyp = VARTYPE_GLOBAL) then
      emit('POPR R' + IntToStr(e.displ))
    else
      emit('POPDISP ' + IntToStr(e.displ));       
    end
  else
  if (expr is Expr_Asm) then
    begin
    emit(Expr_Asm(expr).line);
    end
  else
  if (expr is Expr_Special) then
    begin
    showExpr(Expr_Special(expr).ex);
    
    case Expr_Special(expr).spec of
      SPECIAL_TRAP:   emit('TRAP');
      SPECIAL_SLEEP:	emit('SLEEP');
      SPECIAL_WAIT:		emit('WAIT');
      SPECIAL_SIGNAL:	emit('SIGNAL');
    end;
    end
	else
  if (expr is Expr_Conv) then
    begin
    showExpr(Expr_Conv(expr).ex);

		case Expr_Conv(expr).cnv of
			CONV_TO_INT : emit('TOI');
			CONV_TO_FLOAT : emit('TOF');
			CONV_TO_STRING : emit('TOS');
    end;
    end
  else
  if (expr is Expr_Loop) then
    begin
    showExpr(Expr_Loop(Expr).init);

    emit('L' + IntToStr(Expr_Loop(expr).lStart) + ':');

    showExpr(Expr_Loop(Expr).body);
    showExpr(Expr_Loop(Expr).step);
    showExpr(Expr_Loop(Expr).ce);
    emit('JNZ L' + IntToStr(Expr_Loop(expr).lStart));
    end
  else
  if (expr is Expr_Rel) then 
    begin
    showExpr(Expr_Rel(expr).le);
    showExpr(Expr_Rel(expr).re);

    if (Expr_Rel(expr).op = '>') then
      emit('GT')
    else
    if (Expr_Rel(expr).op = '<') then
      emit('LT')
    else
    if (Expr_Rel(expr).op = '>=') then
      emit('GTE')
    else
    if (Expr_Rel(expr).op = '=<') then
      emit('LTE')
    else
    if (Expr_Rel(expr).op = '==') then
      emit('EQ');
    end
  else
  if (expr is Expr_Not) then 
    begin
    showExpr(Expr_Not(expr).ex);
    emit('NOT');
    end
  else
  if (expr is Expr_And) then 
    begin
    showExpr(Expr_And(expr).le);
    showExpr(Expr_And(expr).re);
    emit('AND');
    end
  else
  if (expr is Expr_Or) then 
    begin
    showExpr(Expr_Or(expr).le);
    showExpr(Expr_Or(expr).re);
    emit('OR');
    end;
end;

procedure startCompiler(root : Expr);
var
  a : integer;
  e : Env_Entry;
begin
  root := typeExpr(root);

  if (not yyerrors) then
    root := optimizeExpr(root);

  if (not yyerrors) then
    begin
    emit('$DATA ' + IntToStr(globalCount));
    
    for a := 0 to environment.count - 1 do
      begin
      e := environment[a];
   
      if (e.lbl > 0) then
        begin
        emit('$SYMBOL ' + e.id + ' L' + IntToStr(e.lbl));
        end;
      end;
      
    showExpr(root); 
    
	  writeln('Output file written, datasize is ', globalCount, ' element(s).');
		end;
end;

var
	ifname : string; 
  ofname : string;
  {$IFDEF WIN32}
  SI : TStartupInfo;
  PI : TProcessInformation;
  ex : DWORD;
  {$ENDIF}

begin
  DecimalSeparator := '.';
  writeln('GMCC - GMC ''Elise'' compiler v0.3'#13#10);

  if (paramcount < 1) then
    begin
    writeln('gmcc <input file>'#13#10);
    { writeln('     -o   turn optimizations on (not implemented at the moment)');
		writeln('     -c   just compile, do not call assembler'); }
    exit;
    end;

  ifname := paramstr(1);
  ofname := ChangeFileExt(ifname, '.asm');
  
  if (not FileExists(ifname)) then
    begin
    writeln('Could not open ', ifname);
    exit;
    end;

  yyopen(ifname);

  assignfile(output, ofname);
  {$I-}
  rewrite(output);
  {$I+}

  if (IOresult <> 0) then
    begin
    writeln('Could not open ', ofname);
    exit;
    end;

  environment := TList.Create;
  labelNum := 1;
  globalCount := 0;
  yylineno := 1;

  start(INITIAL);

  if yyparse=0 then { done; };

  closefile(output);

  if (not yyerrors) then
    begin
    {$IFDEF WIN32}
	  FillChar(SI, SizeOf(SI), 0);
	  SI.cb := SizeOf(SI);

	  CreateProcess(nil, PChar('gasm ' + ofname), nil, nil, false, NORMAL_PRIORITY_CLASS, nil, nil, SI, PI);

	  repeat
	    GetExitCodeProcess(PI.hProcess, ex);
	  until (ex <> STILL_ACTIVE);
    {$ENDIF}	  
    end;
end.