
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

			BoolExpr = class(Root)
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

			Expr_Bool = class(Expr)
        ex : BoolExpr;
			end;

			Expr_Seq = class(Expr)
				ex, seq : Expr;
			end;

			Expr_If = class(Expr)
        ce : BoolExpr;
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
			  ce : BoolExpr;
			  step : Expr;
			  body : Expr;
			end;

	
			BoolExpr_Const = class(BoolExpr)
        value : boolean;
			end;

			BoolExpr_Id = class(BoolExpr)
        id : string;
			end;

			BoolExpr_And = class(BoolExpr)
        le, re : BoolExpr;
			end;

			BoolExpr_Or = class(BoolExpr)
        le, re : BoolExpr;
			end;

			BoolExpr_Rel = class(BoolExpr)
        op : string;
        le, re : Expr;
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
const _RELGT = 270;
const _RELLT = 271;
const _RELGTE = 272;
const _RELLTE = 273;
const _RELEQ = 274;
const _RETURN = 275;
const _BREAK = 276;
const _CONTINUE = 277;
const _DO = 278;
const _SLEEP = 279;
const _WAIT = 280;
const _SIGNAL = 281;
const _WHILE = 282;
const _FOR = 283;
const _REQUIRE = 284;
const _VOID = 285;
const _BOOL = 286;
const _INT = 287;
const _FLOAT = 288;
const _STRING = 289;
const _EXTERNAL = 290;

type YYSType = record case Integer of
                 1 : ( yyBoolExpr : BoolExpr );
                 2 : ( yyExpr : Expr );
                 3 : ( yyInteger : Integer );
                 4 : ( yyShortString : ShortString );
                 5 : ( yySingle : Single );
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
         yyval.yyExpr := Expr_If.Create; Expr_If(yyval.yyExpr).ce := yyv[yysp-4].yyBoolExpr;	yyval.yyExpr.lineNum := yylineno;
         																														Expr_If(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_If(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
         																														Expr_If(yyval.yyExpr).lThen := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lElse := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lAfter := labelNum; inc(labelNum); 
       end;
  24 : begin
         yyval.yyExpr := Expr_If.Create; Expr_If(yyval.yyExpr).ce := yyv[yysp-2].yyBoolExpr; yyval.yyExpr.lineNum := yylineno;	
         																														Expr_If(yyval.yyExpr).le := yyv[yysp-0].yyExpr; Expr_If(yyval.yyExpr).re := nil; 
         																														Expr_If(yyval.yyExpr).lThen := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lAfter := labelNum; inc(labelNum); 
       end;
  25 : begin
         yyval.yyExpr := Expr_Loop.Create; Expr_Loop(yyval.yyExpr).init := yyv[yysp-6].yyExpr;
         				                                                    yyval.yyExpr.lineNum := yylineno; Expr_Loop(yyval.yyExpr).ce := yyv[yysp-4].yyBoolExpr;
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
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-0].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-2].yyExpr; 
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
         varType := _BOOL; yyval.yyInteger := _BOOL; 
       end;
  59 : begin
         varType := _FLOAT; yyval.yyInteger := _FLOAT; 
       end;
  60 : begin
         varType := _STRING; yyval.yyInteger := _STRING; 
       end;
  61 : begin
         varType := _EXTERNAL; yyval.yyInteger := _EXTERNAL; 
       end;
  62 : begin
         yyval.yyExpr := nil; 
       end;
  63 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '+'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  64 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '-'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  65 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '*'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  66 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '/'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  67 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '%'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  68 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '&'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  69 : begin
         yyval.yyExpr := Expr_Op.Create; yyval.yyExpr.lineNum := yylineno; Expr_Op(yyval.yyExpr).op := '|'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  70 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr; 
       end;
  71 : begin
         yyval.yyExpr := Expr_Neg.Create; yyval.yyExpr.lineNum := yylineno; Expr_Neg(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
       end;
  72 : begin
         yyval.yyExpr := Expr_ConstInt.Create; yyval.yyExpr.lineNum := yylineno; Expr_ConstInt(yyval.yyExpr).value := yyv[yysp-0].yyInteger; 
       end;
  73 : begin
         yyval.yyExpr := Expr_ConstFloat.Create; yyval.yyExpr.lineNum := yylineno; Expr_ConstFloat(yyval.yyExpr).value := yyv[yysp-0].yySingle; 
       end;
  74 : begin
         yyval.yyExpr := Expr_String.Create; yyval.yyExpr.lineNum := yylineno; Expr_String(yyval.yyExpr).value := ''; 
       end;
  75 : begin
         yyval.yyExpr := Expr_String.Create; yyval.yyExpr.lineNum := yylineno; Expr_String(yyval.yyExpr).value := varName; 
       end;
  76 : begin
         yyval.yyExpr := Expr_Cast.Create; yyval.yyExpr.lineNum := yylineno; Expr_Cast(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; Expr_Cast(yyval.yyExpr).desttype := yyv[yysp-2].yyInteger; 
       end;
  77 : begin
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
  78 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  79 : begin
         	if (lookupEnv(yyv[yysp-3].yyShortString) = nil) then 
         																					  					begin
         																											compilerError(yylineno, 'undefined function ' + yyv[yysp-3].yyShortString);
         																											yyval.yyExpr := nil;
         																											yyabort;
         																											end;
         																										yyval.yyExpr := Expr_Call.Create; Expr_Call(yyval.yyExpr).id := yyv[yysp-3].yyShortString; Expr_Call(yyval.yyExpr).params := yyv[yysp-1].yyExpr; yyval.yyExpr.lineNum := yyLineno; 
       end;
  80 : begin
         yyval.yyExpr := Expr_Bool.Create; yyval.yyExpr.lineNum := yyLineno; Expr_Bool(yyval.yyExpr).ex := yyv[yysp-0].yyBoolExpr; 
       end;
  81 : begin
         yyval.yyBoolExpr := BoolExpr_Const.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_Const(yyval.yyBoolExpr).value := True; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  82 : begin
         yyval.yyBoolExpr := BoolExpr_Const.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_Const(yyval.yyBoolExpr).value := False; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  83 : begin
         yyval.yyBoolExpr := BoolExpr_And.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_And(yyval.yyBoolExpr).le := yyv[yysp-2].yyBoolExpr; BoolExpr_And(yyval.yyBoolExpr).re := yyv[yysp-0].yyBoolExpr; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  84 : begin
         yyval.yyBoolExpr := BoolExpr_Or.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_Or(yyval.yyBoolExpr).le := yyv[yysp-2].yyBoolExpr; BoolExpr_Or(yyval.yyBoolExpr).re := yyv[yysp-0].yyBoolExpr; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  85 : begin
         yyval.yyBoolExpr := BoolExpr_Rel.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_Rel(yyval.yyBoolExpr).le := yyv[yysp-2].yyExpr; BoolExpr_Rel(yyval.yyBoolExpr).op := '>';  BoolExpr_Rel(yyval.yyBoolExpr).re := yyv[yysp-0].yyExpr; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  86 : begin
         yyval.yyBoolExpr := BoolExpr_Rel.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_Rel(yyval.yyBoolExpr).le := yyv[yysp-2].yyExpr; BoolExpr_Rel(yyval.yyBoolExpr).op := '<';  BoolExpr_Rel(yyval.yyBoolExpr).re := yyv[yysp-0].yyExpr; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  87 : begin
         yyval.yyBoolExpr := BoolExpr_Rel.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_Rel(yyval.yyBoolExpr).le := yyv[yysp-2].yyExpr; BoolExpr_Rel(yyval.yyBoolExpr).op := '>=';  BoolExpr_Rel(yyval.yyBoolExpr).re := yyv[yysp-0].yyExpr; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  88 : begin
         yyval.yyBoolExpr := BoolExpr_Rel.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_Rel(yyval.yyBoolExpr).le := yyv[yysp-2].yyExpr; BoolExpr_Rel(yyval.yyBoolExpr).op := '=<';  BoolExpr_Rel(yyval.yyBoolExpr).re := yyv[yysp-0].yyExpr; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  89 : begin
         yyval.yyBoolExpr := BoolExpr_Rel.Create; yyval.yyBoolExpr.lineNum := yylineno; BoolExpr_Rel(yyval.yyBoolExpr).le := yyv[yysp-2].yyExpr; BoolExpr_Rel(yyval.yyBoolExpr).op := '==';  BoolExpr_Rel(yyval.yyBoolExpr).re := yyv[yysp-0].yyExpr; yyval.yyBoolExpr.lineNum := yylineno;
       end;
  90 : begin
         yyval.yyBoolExpr := yyv[yysp-1].yyBoolExpr; 
       end;
  91 : begin
         yyval.yyShortString := varName; 
       end;
  92 : begin
         varGlob := ':' + yyv[yysp-0].yyShortString;
         tmp := curFunction + varGlob;
         												varName := left(tmp, '.');
         																							
         												if (varName <> tmp) then
         begin
         													yyval.yyExpr := Expr_External.Create;
         													yyval.yyExpr.lineNum := yylineno; 
         													Expr_External(yyval.yyExpr).id := varName;
         													Expr_External(yyval.yyExpr).assoc := right(tmp, '.');
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
  93 : begin
       end;
  94 : begin
         yyval.yyShortString := varName; 
       end;
  95 : begin
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

yynacts   = 1661;
yyngotos  = 229;
yynstates = 164;
yynrules  = 95;

yya : array [1..yynacts] of YYARec = (
{ 0: }
  ( sym: 256; act: 2 ),
  ( sym: 0; act: -1 ),
  ( sym: 10; act: -1 ),
  ( sym: 284; act: -1 ),
  ( sym: 285; act: -1 ),
  ( sym: 286; act: -1 ),
  ( sym: 287; act: -1 ),
  ( sym: 288; act: -1 ),
  ( sym: 289; act: -1 ),
  ( sym: 290; act: -1 ),
{ 1: }
  ( sym: 0; act: 0 ),
  ( sym: 10; act: 9 ),
  ( sym: 284; act: 10 ),
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
{ 2: }
  ( sym: 10; act: 17 ),
{ 3: }
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
  ( sym: 0; act: -18 ),
  ( sym: 10; act: -18 ),
  ( sym: 284; act: -18 ),
{ 4: }
{ 5: }
  ( sym: 284; act: 10 ),
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
  ( sym: 0; act: -3 ),
  ( sym: 10; act: -3 ),
{ 6: }
{ 7: }
  ( sym: 40; act: 20 ),
{ 8: }
  ( sym: 257; act: 23 ),
{ 9: }
{ 10: }
  ( sym: 34; act: 24 ),
{ 11: }
{ 12: }
{ 13: }
{ 14: }
{ 15: }
{ 16: }
{ 17: }
{ 18: }
{ 19: }
{ 20: }
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
  ( sym: 41; act: -33 ),
  ( sym: 44; act: -33 ),
{ 21: }
  ( sym: 44; act: 28 ),
  ( sym: 59; act: 29 ),
{ 22: }
{ 23: }
  ( sym: 40; act: -48 ),
  ( sym: 44; act: -55 ),
  ( sym: 59; act: -55 ),
{ 24: }
  ( sym: 258; act: 30 ),
{ 25: }
{ 26: }
  ( sym: 41; act: 31 ),
  ( sym: 44; act: 32 ),
{ 27: }
  ( sym: 257; act: 33 ),
{ 28: }
  ( sym: 257; act: 35 ),
{ 29: }
{ 30: }
  ( sym: 34; act: 36 ),
{ 31: }
  ( sym: 59; act: 39 ),
  ( sym: 123; act: 40 ),
{ 32: }
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
{ 33: }
{ 34: }
{ 35: }
{ 36: }
{ 37: }
{ 38: }
{ 39: }
{ 40: }
  ( sym: 125; act: 43 ),
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
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
  ( sym: 283; act: -45 ),
{ 41: }
{ 42: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 40 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 275; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 283; act: 71 ),
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
  ( sym: 37; act: -8 ),
  ( sym: 38; act: -8 ),
  ( sym: 42; act: -8 ),
  ( sym: 43; act: -8 ),
  ( sym: 46; act: -8 ),
  ( sym: 47; act: -8 ),
  ( sym: 61; act: -8 ),
  ( sym: 124; act: -8 ),
  ( sym: 125; act: -8 ),
  ( sym: 270; act: -8 ),
  ( sym: 271; act: -8 ),
  ( sym: 272; act: -8 ),
  ( sym: 273; act: -8 ),
  ( sym: 274; act: -8 ),
{ 43: }
{ 44: }
  ( sym: 268; act: 72 ),
  ( sym: 269; act: 73 ),
  ( sym: 37; act: -80 ),
  ( sym: 38; act: -80 ),
  ( sym: 41; act: -80 ),
  ( sym: 42; act: -80 ),
  ( sym: 43; act: -80 ),
  ( sym: 44; act: -80 ),
  ( sym: 45; act: -80 ),
  ( sym: 47; act: -80 ),
  ( sym: 59; act: -80 ),
  ( sym: 124; act: -80 ),
  ( sym: 270; act: -80 ),
  ( sym: 271; act: -80 ),
  ( sym: 272; act: -80 ),
  ( sym: 273; act: -80 ),
  ( sym: 274; act: -80 ),
{ 45: }
  ( sym: 46; act: 74 ),
  ( sym: 37; act: -92 ),
  ( sym: 38; act: -92 ),
  ( sym: 41; act: -92 ),
  ( sym: 42; act: -92 ),
  ( sym: 43; act: -92 ),
  ( sym: 44; act: -92 ),
  ( sym: 45; act: -92 ),
  ( sym: 47; act: -92 ),
  ( sym: 59; act: -92 ),
  ( sym: 61; act: -92 ),
  ( sym: 124; act: -92 ),
  ( sym: 268; act: -92 ),
  ( sym: 269; act: -92 ),
  ( sym: 270; act: -92 ),
  ( sym: 271; act: -92 ),
  ( sym: 272; act: -92 ),
  ( sym: 273; act: -92 ),
  ( sym: 274; act: -92 ),
{ 46: }
  ( sym: 40; act: 75 ),
{ 47: }
  ( sym: 61; act: 76 ),
  ( sym: 37; act: -78 ),
  ( sym: 38; act: -78 ),
  ( sym: 41; act: -78 ),
  ( sym: 42; act: -78 ),
  ( sym: 43; act: -78 ),
  ( sym: 44; act: -78 ),
  ( sym: 45; act: -78 ),
  ( sym: 47; act: -78 ),
  ( sym: 59; act: -78 ),
  ( sym: 124; act: -78 ),
  ( sym: 268; act: -78 ),
  ( sym: 269; act: -78 ),
  ( sym: 270; act: -78 ),
  ( sym: 271; act: -78 ),
  ( sym: 272; act: -78 ),
  ( sym: 273; act: -78 ),
  ( sym: 274; act: -78 ),
{ 48: }
{ 49: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 40 ),
  ( sym: 125; act: 78 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 275; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 283; act: 71 ),
  ( sym: 37; act: -11 ),
  ( sym: 38; act: -11 ),
  ( sym: 42; act: -11 ),
  ( sym: 43; act: -11 ),
  ( sym: 46; act: -11 ),
  ( sym: 47; act: -11 ),
  ( sym: 61; act: -11 ),
  ( sym: 124; act: -11 ),
  ( sym: 270; act: -11 ),
  ( sym: 271; act: -11 ),
  ( sym: 272; act: -11 ),
  ( sym: 273; act: -11 ),
  ( sym: 274; act: -11 ),
{ 50: }
{ 51: }
{ 52: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 59; act: 85 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 53: }
  ( sym: 34; act: 92 ),
  ( sym: 258; act: 93 ),
{ 54: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 55: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 56: }
{ 57: }
  ( sym: 40; act: -91 ),
  ( sym: 37; act: -94 ),
  ( sym: 38; act: -94 ),
  ( sym: 41; act: -94 ),
  ( sym: 42; act: -94 ),
  ( sym: 43; act: -94 ),
  ( sym: 44; act: -94 ),
  ( sym: 45; act: -94 ),
  ( sym: 46; act: -94 ),
  ( sym: 47; act: -94 ),
  ( sym: 59; act: -94 ),
  ( sym: 61; act: -94 ),
  ( sym: 124; act: -94 ),
  ( sym: 268; act: -94 ),
  ( sym: 269; act: -94 ),
  ( sym: 270; act: -94 ),
  ( sym: 271; act: -94 ),
  ( sym: 272; act: -94 ),
  ( sym: 273; act: -94 ),
  ( sym: 274; act: -94 ),
{ 58: }
{ 59: }
{ 60: }
  ( sym: 40; act: 98 ),
{ 61: }
  ( sym: 123; act: 99 ),
{ 62: }
{ 63: }
{ 64: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 101 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 102 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 65: }
  ( sym: 59; act: 103 ),
{ 66: }
  ( sym: 59; act: 104 ),
{ 67: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 68: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 69: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 70: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 71: }
  ( sym: 40; act: 109 ),
{ 72: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 73: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 74: }
  ( sym: 257; act: 113 ),
{ 75: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 41; act: -37 ),
  ( sym: 44; act: -37 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 76: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 77: }
{ 78: }
{ 79: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 80: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 81: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 82: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 83: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 84: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 85: }
{ 86: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 87: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 88: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 89: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 90: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 91: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 92: }
{ 93: }
  ( sym: 34; act: 129 ),
{ 94: }
  ( sym: 41; act: 130 ),
  ( sym: 268; act: 72 ),
  ( sym: 269; act: 73 ),
  ( sym: 37; act: -80 ),
  ( sym: 38; act: -80 ),
  ( sym: 42; act: -80 ),
  ( sym: 43; act: -80 ),
  ( sym: 45; act: -80 ),
  ( sym: 47; act: -80 ),
  ( sym: 124; act: -80 ),
  ( sym: 270; act: -80 ),
  ( sym: 271; act: -80 ),
  ( sym: 272; act: -80 ),
  ( sym: 273; act: -80 ),
  ( sym: 274; act: -80 ),
{ 95: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 41; act: 131 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 96: }
  ( sym: 41; act: 132 ),
{ 97: }
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 37; act: -71 ),
  ( sym: 38; act: -71 ),
  ( sym: 41; act: -71 ),
  ( sym: 42; act: -71 ),
  ( sym: 43; act: -71 ),
  ( sym: 44; act: -71 ),
  ( sym: 45; act: -71 ),
  ( sym: 47; act: -71 ),
  ( sym: 59; act: -71 ),
  ( sym: 124; act: -71 ),
  ( sym: 268; act: -71 ),
  ( sym: 269; act: -71 ),
{ 98: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 99: }
  ( sym: 34; act: 136 ),
{ 100: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 59; act: 137 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 101: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 285; act: 11 ),
  ( sym: 286; act: 12 ),
  ( sym: 287; act: 13 ),
  ( sym: 288; act: 14 ),
  ( sym: 289; act: 15 ),
  ( sym: 290; act: 16 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 102: }
{ 103: }
{ 104: }
{ 105: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 59; act: 139 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 106: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 59; act: 140 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 107: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 59; act: 141 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 108: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 59; act: 142 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 109: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 110: }
  ( sym: 268; act: 72 ),
  ( sym: 269; act: 73 ),
  ( sym: 37; act: -80 ),
  ( sym: 38; act: -80 ),
  ( sym: 42; act: -80 ),
  ( sym: 43; act: -80 ),
  ( sym: 45; act: -80 ),
  ( sym: 47; act: -80 ),
  ( sym: 124; act: -80 ),
  ( sym: 270; act: -80 ),
  ( sym: 271; act: -80 ),
  ( sym: 272; act: -80 ),
  ( sym: 273; act: -80 ),
  ( sym: 274; act: -80 ),
  ( sym: 41; act: -83 ),
  ( sym: 44; act: -83 ),
  ( sym: 59; act: -83 ),
{ 111: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 112: }
  ( sym: 268; act: 72 ),
  ( sym: 269; act: 73 ),
  ( sym: 37; act: -80 ),
  ( sym: 38; act: -80 ),
  ( sym: 42; act: -80 ),
  ( sym: 43; act: -80 ),
  ( sym: 45; act: -80 ),
  ( sym: 47; act: -80 ),
  ( sym: 124; act: -80 ),
  ( sym: 270; act: -80 ),
  ( sym: 271; act: -80 ),
  ( sym: 272; act: -80 ),
  ( sym: 273; act: -80 ),
  ( sym: 274; act: -80 ),
  ( sym: 41; act: -84 ),
  ( sym: 44; act: -84 ),
  ( sym: 59; act: -84 ),
{ 113: }
{ 114: }
  ( sym: 41; act: 144 ),
  ( sym: 44; act: 145 ),
{ 115: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -38 ),
  ( sym: 44; act: -38 ),
{ 116: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -77 ),
  ( sym: 44; act: -77 ),
  ( sym: 59; act: -77 ),
  ( sym: 268; act: -77 ),
  ( sym: 269; act: -77 ),
{ 117: }
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 37; act: -67 ),
  ( sym: 38; act: -67 ),
  ( sym: 41; act: -67 ),
  ( sym: 42; act: -67 ),
  ( sym: 43; act: -67 ),
  ( sym: 44; act: -67 ),
  ( sym: 45; act: -67 ),
  ( sym: 47; act: -67 ),
  ( sym: 59; act: -67 ),
  ( sym: 124; act: -67 ),
  ( sym: 268; act: -67 ),
  ( sym: 269; act: -67 ),
{ 118: }
  ( sym: 37; act: 79 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 38; act: -68 ),
  ( sym: 41; act: -68 ),
  ( sym: 44; act: -68 ),
  ( sym: 59; act: -68 ),
  ( sym: 124; act: -68 ),
  ( sym: 268; act: -68 ),
  ( sym: 269; act: -68 ),
{ 119: }
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
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
  ( sym: 268; act: -65 ),
  ( sym: 269; act: -65 ),
{ 120: }
  ( sym: 37; act: 79 ),
  ( sym: 42; act: 81 ),
  ( sym: 47; act: 84 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 38; act: -63 ),
  ( sym: 41; act: -63 ),
  ( sym: 43; act: -63 ),
  ( sym: 44; act: -63 ),
  ( sym: 45; act: -63 ),
  ( sym: 59; act: -63 ),
  ( sym: 124; act: -63 ),
  ( sym: 268; act: -63 ),
  ( sym: 269; act: -63 ),
{ 121: }
  ( sym: 37; act: 79 ),
  ( sym: 42; act: 81 ),
  ( sym: 47; act: 84 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 38; act: -64 ),
  ( sym: 41; act: -64 ),
  ( sym: 43; act: -64 ),
  ( sym: 44; act: -64 ),
  ( sym: 45; act: -64 ),
  ( sym: 59; act: -64 ),
  ( sym: 124; act: -64 ),
  ( sym: 268; act: -64 ),
  ( sym: 269; act: -64 ),
{ 122: }
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
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
  ( sym: 268; act: -66 ),
  ( sym: 269; act: -66 ),
{ 123: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -69 ),
  ( sym: 44; act: -69 ),
  ( sym: 59; act: -69 ),
  ( sym: 124; act: -69 ),
  ( sym: 268; act: -69 ),
  ( sym: 269; act: -69 ),
{ 124: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -85 ),
  ( sym: 44; act: -85 ),
  ( sym: 59; act: -85 ),
  ( sym: 268; act: -85 ),
  ( sym: 269; act: -85 ),
{ 125: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -86 ),
  ( sym: 44; act: -86 ),
  ( sym: 59; act: -86 ),
  ( sym: 268; act: -86 ),
  ( sym: 269; act: -86 ),
{ 126: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -87 ),
  ( sym: 44; act: -87 ),
  ( sym: 59; act: -87 ),
  ( sym: 268; act: -87 ),
  ( sym: 269; act: -87 ),
{ 127: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -88 ),
  ( sym: 44; act: -88 ),
  ( sym: 59; act: -88 ),
  ( sym: 268; act: -88 ),
  ( sym: 269; act: -88 ),
{ 128: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -89 ),
  ( sym: 44; act: -89 ),
  ( sym: 59; act: -89 ),
  ( sym: 268; act: -89 ),
  ( sym: 269; act: -89 ),
{ 129: }
{ 130: }
{ 131: }
{ 132: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 133: }
  ( sym: 41; act: 147 ),
  ( sym: 268; act: 72 ),
  ( sym: 269; act: 73 ),
  ( sym: 37; act: -80 ),
  ( sym: 38; act: -80 ),
  ( sym: 42; act: -80 ),
  ( sym: 43; act: -80 ),
  ( sym: 45; act: -80 ),
  ( sym: 47; act: -80 ),
  ( sym: 124; act: -80 ),
  ( sym: 270; act: -80 ),
  ( sym: 271; act: -80 ),
  ( sym: 272; act: -80 ),
  ( sym: 273; act: -80 ),
  ( sym: 274; act: -80 ),
{ 134: }
{ 135: }
  ( sym: 34; act: 136 ),
  ( sym: 125; act: 149 ),
{ 136: }
  ( sym: 258; act: 150 ),
{ 137: }
{ 138: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 41; act: 151 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 139: }
{ 140: }
{ 141: }
{ 142: }
{ 143: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 59; act: 152 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 144: }
{ 145: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 146: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -76 ),
  ( sym: 44; act: -76 ),
  ( sym: 59; act: -76 ),
  ( sym: 268; act: -76 ),
  ( sym: 269; act: -76 ),
{ 147: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 40 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 275; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 283; act: 71 ),
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
  ( sym: 270; act: -11 ),
  ( sym: 271; act: -11 ),
  ( sym: 272; act: -11 ),
  ( sym: 273; act: -11 ),
  ( sym: 274; act: -11 ),
{ 148: }
{ 149: }
{ 150: }
  ( sym: 34; act: 155 ),
{ 151: }
  ( sym: 59; act: 156 ),
  ( sym: 37; act: -70 ),
  ( sym: 38; act: -70 ),
  ( sym: 42; act: -70 ),
  ( sym: 43; act: -70 ),
  ( sym: 45; act: -70 ),
  ( sym: 47; act: -70 ),
  ( sym: 124; act: -70 ),
  ( sym: 270; act: -70 ),
  ( sym: 271; act: -70 ),
  ( sym: 272; act: -70 ),
  ( sym: 273; act: -70 ),
  ( sym: 274; act: -70 ),
{ 152: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 153: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 41; act: -39 ),
  ( sym: 44; act: -39 ),
{ 154: }
  ( sym: 264; act: 158 ),
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
  ( sym: 283; act: -24 ),
{ 155: }
{ 156: }
{ 157: }
  ( sym: 59; act: 159 ),
  ( sym: 268; act: 72 ),
  ( sym: 269; act: 73 ),
  ( sym: 37; act: -80 ),
  ( sym: 38; act: -80 ),
  ( sym: 42; act: -80 ),
  ( sym: 43; act: -80 ),
  ( sym: 45; act: -80 ),
  ( sym: 47; act: -80 ),
  ( sym: 124; act: -80 ),
  ( sym: 270; act: -80 ),
  ( sym: 271; act: -80 ),
  ( sym: 272; act: -80 ),
  ( sym: 273; act: -80 ),
  ( sym: 274; act: -80 ),
{ 158: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 40 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 275; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 283; act: 71 ),
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
  ( sym: 270; act: -11 ),
  ( sym: 271; act: -11 ),
  ( sym: 272; act: -11 ),
  ( sym: 273; act: -11 ),
  ( sym: 274; act: -11 ),
{ 159: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 270; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 46; act: -93 ),
  ( sym: 61; act: -93 ),
{ 160: }
{ 161: }
  ( sym: 37; act: 79 ),
  ( sym: 38; act: 80 ),
  ( sym: 41; act: 162 ),
  ( sym: 42; act: 81 ),
  ( sym: 43; act: 82 ),
  ( sym: 45; act: 83 ),
  ( sym: 47; act: 84 ),
  ( sym: 124; act: 86 ),
  ( sym: 270; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
{ 162: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 40 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 275; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 283; act: 71 ),
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
  ( sym: 270; act: -11 ),
  ( sym: 271; act: -11 ),
  ( sym: 272; act: -11 ),
  ( sym: 273; act: -11 ),
  ( sym: 274; act: -11 )
{ 163: }
);

yyg : array [1..yyngotos] of YYARec = (
{ 0: }
  ( sym: -25; act: 1 ),
{ 1: }
  ( sym: -16; act: 3 ),
  ( sym: -15; act: 4 ),
  ( sym: -8; act: 5 ),
  ( sym: -7; act: 6 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 2: }
{ 3: }
  ( sym: -15; act: 18 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 4: }
{ 5: }
  ( sym: -16; act: 3 ),
  ( sym: -15; act: 4 ),
  ( sym: -7; act: 19 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 6: }
{ 7: }
{ 8: }
  ( sym: -26; act: 21 ),
  ( sym: -21; act: 22 ),
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
{ 20: }
  ( sym: -12; act: 25 ),
  ( sym: -11; act: 26 ),
  ( sym: -2; act: 27 ),
{ 21: }
{ 22: }
{ 23: }
{ 24: }
{ 25: }
{ 26: }
{ 27: }
{ 28: }
  ( sym: -21; act: 34 ),
{ 29: }
{ 30: }
{ 31: }
  ( sym: -14; act: 37 ),
  ( sym: -6; act: 38 ),
{ 32: }
  ( sym: -12; act: 41 ),
  ( sym: -2; act: 27 ),
{ 33: }
{ 34: }
{ 35: }
{ 36: }
{ 37: }
{ 38: }
{ 39: }
{ 40: }
  ( sym: -16; act: 42 ),
  ( sym: -15; act: 4 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 41: }
{ 42: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -15; act: 18 ),
  ( sym: -14; act: 48 ),
  ( sym: -10; act: 49 ),
  ( sym: -9; act: 50 ),
  ( sym: -5; act: 7 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 ),
  ( sym: -2; act: 8 ),
{ 43: }
{ 44: }
{ 45: }
{ 46: }
{ 47: }
{ 48: }
{ 49: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -14; act: 48 ),
  ( sym: -9; act: 77 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 ),
{ 50: }
{ 51: }
{ 52: }
{ 53: }
{ 54: }
  ( sym: -24; act: 94 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 95 ),
  ( sym: -2; act: 96 ),
{ 55: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 97 ),
{ 56: }
{ 57: }
{ 58: }
{ 59: }
{ 60: }
{ 61: }
{ 62: }
{ 63: }
{ 64: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 100 ),
{ 65: }
{ 66: }
{ 67: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 105 ),
{ 68: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 106 ),
{ 69: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 107 ),
{ 70: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 108 ),
{ 71: }
{ 72: }
  ( sym: -24; act: 110 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 111 ),
{ 73: }
  ( sym: -24; act: 112 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 111 ),
{ 74: }
{ 75: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -13; act: 114 ),
  ( sym: -3; act: 115 ),
{ 76: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 116 ),
{ 77: }
{ 78: }
{ 79: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 117 ),
{ 80: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 118 ),
{ 81: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 119 ),
{ 82: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 120 ),
{ 83: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 121 ),
{ 84: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 122 ),
{ 85: }
{ 86: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 123 ),
{ 87: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 124 ),
{ 88: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 125 ),
{ 89: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 126 ),
{ 90: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 127 ),
{ 91: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 128 ),
{ 92: }
{ 93: }
{ 94: }
{ 95: }
{ 96: }
{ 97: }
{ 98: }
  ( sym: -24; act: 133 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 111 ),
{ 99: }
  ( sym: -20; act: 134 ),
  ( sym: -19; act: 135 ),
{ 100: }
{ 101: }
  ( sym: -24; act: 94 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 138 ),
  ( sym: -2; act: 96 ),
{ 102: }
{ 103: }
{ 104: }
{ 105: }
{ 106: }
{ 107: }
{ 108: }
{ 109: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 143 ),
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
{ 130: }
{ 131: }
{ 132: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 146 ),
{ 133: }
{ 134: }
{ 135: }
  ( sym: -20; act: 148 ),
{ 136: }
{ 137: }
{ 138: }
{ 139: }
{ 140: }
{ 141: }
{ 142: }
{ 143: }
{ 144: }
{ 145: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 153 ),
{ 146: }
{ 147: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -14; act: 48 ),
  ( sym: -9; act: 154 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 ),
{ 148: }
{ 149: }
{ 150: }
{ 151: }
{ 152: }
  ( sym: -24; act: 157 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 111 ),
{ 153: }
{ 154: }
{ 155: }
{ 156: }
{ 157: }
{ 158: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -14; act: 48 ),
  ( sym: -9; act: 160 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 ),
{ 159: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 161 ),
{ 160: }
{ 161: }
{ 162: }
  ( sym: -24; act: 44 ),
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -14; act: 48 ),
  ( sym: -9; act: 163 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 )
{ 163: }
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
{ 12: } -58,
{ 13: } -57,
{ 14: } -59,
{ 15: } -60,
{ 16: } -61,
{ 17: } -4,
{ 18: } -47,
{ 19: } -7,
{ 20: } 0,
{ 21: } 0,
{ 22: } -53,
{ 23: } 0,
{ 24: } 0,
{ 25: } -34,
{ 26: } 0,
{ 27: } 0,
{ 28: } 0,
{ 29: } -51,
{ 30: } 0,
{ 31: } 0,
{ 32: } 0,
{ 33: } -36,
{ 34: } -54,
{ 35: } -55,
{ 36: } -19,
{ 37: } -50,
{ 38: } -52,
{ 39: } -49,
{ 40: } 0,
{ 41: } -35,
{ 42: } 0,
{ 43: } -43,
{ 44: } 0,
{ 45: } 0,
{ 46: } 0,
{ 47: } 0,
{ 48: } -21,
{ 49: } 0,
{ 50: } -9,
{ 51: } -31,
{ 52: } 0,
{ 53: } 0,
{ 54: } 0,
{ 55: } 0,
{ 56: } -32,
{ 57: } 0,
{ 58: } -72,
{ 59: } -73,
{ 60: } 0,
{ 61: } 0,
{ 62: } -81,
{ 63: } -82,
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
{ 74: } 0,
{ 75: } 0,
{ 76: } 0,
{ 77: } -10,
{ 78: } -44,
{ 79: } 0,
{ 80: } 0,
{ 81: } 0,
{ 82: } 0,
{ 83: } 0,
{ 84: } 0,
{ 85: } -22,
{ 86: } 0,
{ 87: } 0,
{ 88: } 0,
{ 89: } 0,
{ 90: } 0,
{ 91: } 0,
{ 92: } -74,
{ 93: } 0,
{ 94: } 0,
{ 95: } 0,
{ 96: } 0,
{ 97: } 0,
{ 98: } 0,
{ 99: } 0,
{ 100: } 0,
{ 101: } 0,
{ 102: } -14,
{ 103: } -12,
{ 104: } -13,
{ 105: } 0,
{ 106: } 0,
{ 107: } 0,
{ 108: } 0,
{ 109: } 0,
{ 110: } 0,
{ 111: } 0,
{ 112: } 0,
{ 113: } -95,
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
{ 127: } 0,
{ 128: } 0,
{ 129: } -75,
{ 130: } -90,
{ 131: } -70,
{ 132: } 0,
{ 133: } 0,
{ 134: } -40,
{ 135: } 0,
{ 136: } 0,
{ 137: } -15,
{ 138: } 0,
{ 139: } -26,
{ 140: } -27,
{ 141: } -28,
{ 142: } -29,
{ 143: } 0,
{ 144: } -79,
{ 145: } 0,
{ 146: } 0,
{ 147: } 0,
{ 148: } -41,
{ 149: } -30,
{ 150: } 0,
{ 151: } 0,
{ 152: } 0,
{ 153: } 0,
{ 154: } 0,
{ 155: } -42,
{ 156: } -16,
{ 157: } 0,
{ 158: } 0,
{ 159: } 0,
{ 160: } -23,
{ 161: } 0,
{ 162: } 0,
{ 163: } -25
);

yyal : array [0..yynstates-1] of Integer = (
{ 0: } 1,
{ 1: } 11,
{ 2: } 20,
{ 3: } 21,
{ 4: } 30,
{ 5: } 30,
{ 6: } 39,
{ 7: } 39,
{ 8: } 40,
{ 9: } 41,
{ 10: } 41,
{ 11: } 42,
{ 12: } 42,
{ 13: } 42,
{ 14: } 42,
{ 15: } 42,
{ 16: } 42,
{ 17: } 42,
{ 18: } 42,
{ 19: } 42,
{ 20: } 42,
{ 21: } 50,
{ 22: } 52,
{ 23: } 52,
{ 24: } 55,
{ 25: } 56,
{ 26: } 56,
{ 27: } 58,
{ 28: } 59,
{ 29: } 60,
{ 30: } 60,
{ 31: } 61,
{ 32: } 63,
{ 33: } 69,
{ 34: } 69,
{ 35: } 69,
{ 36: } 69,
{ 37: } 69,
{ 38: } 69,
{ 39: } 69,
{ 40: } 69,
{ 41: } 109,
{ 42: } 109,
{ 43: } 149,
{ 44: } 149,
{ 45: } 166,
{ 46: } 185,
{ 47: } 186,
{ 48: } 204,
{ 49: } 204,
{ 50: } 238,
{ 51: } 238,
{ 52: } 238,
{ 53: } 251,
{ 54: } 253,
{ 55: } 281,
{ 56: } 307,
{ 57: } 307,
{ 58: } 327,
{ 59: } 327,
{ 60: } 327,
{ 61: } 328,
{ 62: } 329,
{ 63: } 329,
{ 64: } 329,
{ 65: } 351,
{ 66: } 352,
{ 67: } 353,
{ 68: } 375,
{ 69: } 397,
{ 70: } 419,
{ 71: } 441,
{ 72: } 442,
{ 73: } 463,
{ 74: } 484,
{ 75: } 485,
{ 76: } 508,
{ 77: } 534,
{ 78: } 534,
{ 79: } 534,
{ 80: } 560,
{ 81: } 586,
{ 82: } 612,
{ 83: } 638,
{ 84: } 664,
{ 85: } 690,
{ 86: } 690,
{ 87: } 716,
{ 88: } 742,
{ 89: } 768,
{ 90: } 794,
{ 91: } 820,
{ 92: } 846,
{ 93: } 846,
{ 94: } 847,
{ 95: } 862,
{ 96: } 875,
{ 97: } 876,
{ 98: } 893,
{ 99: } 914,
{ 100: } 915,
{ 101: } 928,
{ 102: } 956,
{ 103: } 956,
{ 104: } 956,
{ 105: } 956,
{ 106: } 969,
{ 107: } 982,
{ 108: } 995,
{ 109: } 1008,
{ 110: } 1030,
{ 111: } 1047,
{ 112: } 1059,
{ 113: } 1076,
{ 114: } 1076,
{ 115: } 1078,
{ 116: } 1092,
{ 117: } 1109,
{ 118: } 1126,
{ 119: } 1143,
{ 120: } 1160,
{ 121: } 1177,
{ 122: } 1194,
{ 123: } 1211,
{ 124: } 1228,
{ 125: } 1245,
{ 126: } 1262,
{ 127: } 1279,
{ 128: } 1296,
{ 129: } 1313,
{ 130: } 1313,
{ 131: } 1313,
{ 132: } 1313,
{ 133: } 1339,
{ 134: } 1354,
{ 135: } 1354,
{ 136: } 1356,
{ 137: } 1357,
{ 138: } 1357,
{ 139: } 1370,
{ 140: } 1370,
{ 141: } 1370,
{ 142: } 1370,
{ 143: } 1370,
{ 144: } 1383,
{ 145: } 1383,
{ 146: } 1406,
{ 147: } 1423,
{ 148: } 1458,
{ 149: } 1458,
{ 150: } 1458,
{ 151: } 1459,
{ 152: } 1472,
{ 153: } 1493,
{ 154: } 1507,
{ 155: } 1542,
{ 156: } 1542,
{ 157: } 1542,
{ 158: } 1557,
{ 159: } 1592,
{ 160: } 1614,
{ 161: } 1614,
{ 162: } 1627,
{ 163: } 1662
);

yyah : array [0..yynstates-1] of Integer = (
{ 0: } 10,
{ 1: } 19,
{ 2: } 20,
{ 3: } 29,
{ 4: } 29,
{ 5: } 38,
{ 6: } 38,
{ 7: } 39,
{ 8: } 40,
{ 9: } 40,
{ 10: } 41,
{ 11: } 41,
{ 12: } 41,
{ 13: } 41,
{ 14: } 41,
{ 15: } 41,
{ 16: } 41,
{ 17: } 41,
{ 18: } 41,
{ 19: } 41,
{ 20: } 49,
{ 21: } 51,
{ 22: } 51,
{ 23: } 54,
{ 24: } 55,
{ 25: } 55,
{ 26: } 57,
{ 27: } 58,
{ 28: } 59,
{ 29: } 59,
{ 30: } 60,
{ 31: } 62,
{ 32: } 68,
{ 33: } 68,
{ 34: } 68,
{ 35: } 68,
{ 36: } 68,
{ 37: } 68,
{ 38: } 68,
{ 39: } 68,
{ 40: } 108,
{ 41: } 108,
{ 42: } 148,
{ 43: } 148,
{ 44: } 165,
{ 45: } 184,
{ 46: } 185,
{ 47: } 203,
{ 48: } 203,
{ 49: } 237,
{ 50: } 237,
{ 51: } 237,
{ 52: } 250,
{ 53: } 252,
{ 54: } 280,
{ 55: } 306,
{ 56: } 306,
{ 57: } 326,
{ 58: } 326,
{ 59: } 326,
{ 60: } 327,
{ 61: } 328,
{ 62: } 328,
{ 63: } 328,
{ 64: } 350,
{ 65: } 351,
{ 66: } 352,
{ 67: } 374,
{ 68: } 396,
{ 69: } 418,
{ 70: } 440,
{ 71: } 441,
{ 72: } 462,
{ 73: } 483,
{ 74: } 484,
{ 75: } 507,
{ 76: } 533,
{ 77: } 533,
{ 78: } 533,
{ 79: } 559,
{ 80: } 585,
{ 81: } 611,
{ 82: } 637,
{ 83: } 663,
{ 84: } 689,
{ 85: } 689,
{ 86: } 715,
{ 87: } 741,
{ 88: } 767,
{ 89: } 793,
{ 90: } 819,
{ 91: } 845,
{ 92: } 845,
{ 93: } 846,
{ 94: } 861,
{ 95: } 874,
{ 96: } 875,
{ 97: } 892,
{ 98: } 913,
{ 99: } 914,
{ 100: } 927,
{ 101: } 955,
{ 102: } 955,
{ 103: } 955,
{ 104: } 955,
{ 105: } 968,
{ 106: } 981,
{ 107: } 994,
{ 108: } 1007,
{ 109: } 1029,
{ 110: } 1046,
{ 111: } 1058,
{ 112: } 1075,
{ 113: } 1075,
{ 114: } 1077,
{ 115: } 1091,
{ 116: } 1108,
{ 117: } 1125,
{ 118: } 1142,
{ 119: } 1159,
{ 120: } 1176,
{ 121: } 1193,
{ 122: } 1210,
{ 123: } 1227,
{ 124: } 1244,
{ 125: } 1261,
{ 126: } 1278,
{ 127: } 1295,
{ 128: } 1312,
{ 129: } 1312,
{ 130: } 1312,
{ 131: } 1312,
{ 132: } 1338,
{ 133: } 1353,
{ 134: } 1353,
{ 135: } 1355,
{ 136: } 1356,
{ 137: } 1356,
{ 138: } 1369,
{ 139: } 1369,
{ 140: } 1369,
{ 141: } 1369,
{ 142: } 1369,
{ 143: } 1382,
{ 144: } 1382,
{ 145: } 1405,
{ 146: } 1422,
{ 147: } 1457,
{ 148: } 1457,
{ 149: } 1457,
{ 150: } 1458,
{ 151: } 1471,
{ 152: } 1492,
{ 153: } 1506,
{ 154: } 1541,
{ 155: } 1541,
{ 156: } 1541,
{ 157: } 1556,
{ 158: } 1591,
{ 159: } 1613,
{ 160: } 1613,
{ 161: } 1626,
{ 162: } 1661,
{ 163: } 1661
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
{ 20: } 18,
{ 21: } 21,
{ 22: } 21,
{ 23: } 21,
{ 24: } 21,
{ 25: } 21,
{ 26: } 21,
{ 27: } 21,
{ 28: } 21,
{ 29: } 22,
{ 30: } 22,
{ 31: } 22,
{ 32: } 24,
{ 33: } 26,
{ 34: } 26,
{ 35: } 26,
{ 36: } 26,
{ 37: } 26,
{ 38: } 26,
{ 39: } 26,
{ 40: } 26,
{ 41: } 30,
{ 42: } 30,
{ 43: } 42,
{ 44: } 42,
{ 45: } 42,
{ 46: } 42,
{ 47: } 42,
{ 48: } 42,
{ 49: } 42,
{ 50: } 50,
{ 51: } 50,
{ 52: } 50,
{ 53: } 50,
{ 54: } 50,
{ 55: } 56,
{ 56: } 61,
{ 57: } 61,
{ 58: } 61,
{ 59: } 61,
{ 60: } 61,
{ 61: } 61,
{ 62: } 61,
{ 63: } 61,
{ 64: } 61,
{ 65: } 66,
{ 66: } 66,
{ 67: } 66,
{ 68: } 71,
{ 69: } 76,
{ 70: } 81,
{ 71: } 86,
{ 72: } 86,
{ 73: } 91,
{ 74: } 96,
{ 75: } 96,
{ 76: } 102,
{ 77: } 107,
{ 78: } 107,
{ 79: } 107,
{ 80: } 112,
{ 81: } 117,
{ 82: } 122,
{ 83: } 127,
{ 84: } 132,
{ 85: } 137,
{ 86: } 137,
{ 87: } 142,
{ 88: } 147,
{ 89: } 152,
{ 90: } 157,
{ 91: } 162,
{ 92: } 167,
{ 93: } 167,
{ 94: } 167,
{ 95: } 167,
{ 96: } 167,
{ 97: } 167,
{ 98: } 167,
{ 99: } 172,
{ 100: } 174,
{ 101: } 174,
{ 102: } 180,
{ 103: } 180,
{ 104: } 180,
{ 105: } 180,
{ 106: } 180,
{ 107: } 180,
{ 108: } 180,
{ 109: } 180,
{ 110: } 185,
{ 111: } 185,
{ 112: } 185,
{ 113: } 185,
{ 114: } 185,
{ 115: } 185,
{ 116: } 185,
{ 117: } 185,
{ 118: } 185,
{ 119: } 185,
{ 120: } 185,
{ 121: } 185,
{ 122: } 185,
{ 123: } 185,
{ 124: } 185,
{ 125: } 185,
{ 126: } 185,
{ 127: } 185,
{ 128: } 185,
{ 129: } 185,
{ 130: } 185,
{ 131: } 185,
{ 132: } 185,
{ 133: } 190,
{ 134: } 190,
{ 135: } 190,
{ 136: } 191,
{ 137: } 191,
{ 138: } 191,
{ 139: } 191,
{ 140: } 191,
{ 141: } 191,
{ 142: } 191,
{ 143: } 191,
{ 144: } 191,
{ 145: } 191,
{ 146: } 196,
{ 147: } 196,
{ 148: } 204,
{ 149: } 204,
{ 150: } 204,
{ 151: } 204,
{ 152: } 204,
{ 153: } 209,
{ 154: } 209,
{ 155: } 209,
{ 156: } 209,
{ 157: } 209,
{ 158: } 209,
{ 159: } 217,
{ 160: } 222,
{ 161: } 222,
{ 162: } 222,
{ 163: } 230
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
{ 19: } 17,
{ 20: } 20,
{ 21: } 20,
{ 22: } 20,
{ 23: } 20,
{ 24: } 20,
{ 25: } 20,
{ 26: } 20,
{ 27: } 20,
{ 28: } 21,
{ 29: } 21,
{ 30: } 21,
{ 31: } 23,
{ 32: } 25,
{ 33: } 25,
{ 34: } 25,
{ 35: } 25,
{ 36: } 25,
{ 37: } 25,
{ 38: } 25,
{ 39: } 25,
{ 40: } 29,
{ 41: } 29,
{ 42: } 41,
{ 43: } 41,
{ 44: } 41,
{ 45: } 41,
{ 46: } 41,
{ 47: } 41,
{ 48: } 41,
{ 49: } 49,
{ 50: } 49,
{ 51: } 49,
{ 52: } 49,
{ 53: } 49,
{ 54: } 55,
{ 55: } 60,
{ 56: } 60,
{ 57: } 60,
{ 58: } 60,
{ 59: } 60,
{ 60: } 60,
{ 61: } 60,
{ 62: } 60,
{ 63: } 60,
{ 64: } 65,
{ 65: } 65,
{ 66: } 65,
{ 67: } 70,
{ 68: } 75,
{ 69: } 80,
{ 70: } 85,
{ 71: } 85,
{ 72: } 90,
{ 73: } 95,
{ 74: } 95,
{ 75: } 101,
{ 76: } 106,
{ 77: } 106,
{ 78: } 106,
{ 79: } 111,
{ 80: } 116,
{ 81: } 121,
{ 82: } 126,
{ 83: } 131,
{ 84: } 136,
{ 85: } 136,
{ 86: } 141,
{ 87: } 146,
{ 88: } 151,
{ 89: } 156,
{ 90: } 161,
{ 91: } 166,
{ 92: } 166,
{ 93: } 166,
{ 94: } 166,
{ 95: } 166,
{ 96: } 166,
{ 97: } 166,
{ 98: } 171,
{ 99: } 173,
{ 100: } 173,
{ 101: } 179,
{ 102: } 179,
{ 103: } 179,
{ 104: } 179,
{ 105: } 179,
{ 106: } 179,
{ 107: } 179,
{ 108: } 179,
{ 109: } 184,
{ 110: } 184,
{ 111: } 184,
{ 112: } 184,
{ 113: } 184,
{ 114: } 184,
{ 115: } 184,
{ 116: } 184,
{ 117: } 184,
{ 118: } 184,
{ 119: } 184,
{ 120: } 184,
{ 121: } 184,
{ 122: } 184,
{ 123: } 184,
{ 124: } 184,
{ 125: } 184,
{ 126: } 184,
{ 127: } 184,
{ 128: } 184,
{ 129: } 184,
{ 130: } 184,
{ 131: } 184,
{ 132: } 189,
{ 133: } 189,
{ 134: } 189,
{ 135: } 190,
{ 136: } 190,
{ 137: } 190,
{ 138: } 190,
{ 139: } 190,
{ 140: } 190,
{ 141: } 190,
{ 142: } 190,
{ 143: } 190,
{ 144: } 190,
{ 145: } 195,
{ 146: } 195,
{ 147: } 203,
{ 148: } 203,
{ 149: } 203,
{ 150: } 203,
{ 151: } 203,
{ 152: } 208,
{ 153: } 208,
{ 154: } 208,
{ 155: } 208,
{ 156: } 208,
{ 157: } 208,
{ 158: } 216,
{ 159: } 221,
{ 160: } 221,
{ 161: } 221,
{ 162: } 229,
{ 163: } 229
);

yyr : array [1..yynrules] of YYRRec = (
{ 1: } ( len: 0; sym: -25 ),
{ 2: } ( len: 2; sym: -25 ),
{ 3: } ( len: 2; sym: -25 ),
{ 4: } ( len: 2; sym: -25 ),
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
{ 53: } ( len: 1; sym: -26 ),
{ 54: } ( len: 3; sym: -26 ),
{ 55: } ( len: 1; sym: -21 ),
{ 56: } ( len: 1; sym: -2 ),
{ 57: } ( len: 1; sym: -2 ),
{ 58: } ( len: 1; sym: -2 ),
{ 59: } ( len: 1; sym: -2 ),
{ 60: } ( len: 1; sym: -2 ),
{ 61: } ( len: 1; sym: -2 ),
{ 62: } ( len: 0; sym: -3 ),
{ 63: } ( len: 3; sym: -3 ),
{ 64: } ( len: 3; sym: -3 ),
{ 65: } ( len: 3; sym: -3 ),
{ 66: } ( len: 3; sym: -3 ),
{ 67: } ( len: 3; sym: -3 ),
{ 68: } ( len: 3; sym: -3 ),
{ 69: } ( len: 3; sym: -3 ),
{ 70: } ( len: 3; sym: -3 ),
{ 71: } ( len: 2; sym: -3 ),
{ 72: } ( len: 1; sym: -3 ),
{ 73: } ( len: 1; sym: -3 ),
{ 74: } ( len: 2; sym: -3 ),
{ 75: } ( len: 3; sym: -3 ),
{ 76: } ( len: 4; sym: -3 ),
{ 77: } ( len: 3; sym: -3 ),
{ 78: } ( len: 1; sym: -3 ),
{ 79: } ( len: 4; sym: -3 ),
{ 80: } ( len: 1; sym: -3 ),
{ 81: } ( len: 1; sym: -24 ),
{ 82: } ( len: 1; sym: -24 ),
{ 83: } ( len: 3; sym: -24 ),
{ 84: } ( len: 3; sym: -24 ),
{ 85: } ( len: 3; sym: -24 ),
{ 86: } ( len: 3; sym: -24 ),
{ 87: } ( len: 3; sym: -24 ),
{ 88: } ( len: 3; sym: -24 ),
{ 89: } ( len: 3; sym: -24 ),
{ 90: } ( len: 3; sym: -24 ),
{ 91: } ( len: 1; sym: -22 ),
{ 92: } ( len: 1; sym: -18 ),
{ 93: } ( len: 0; sym: -23 ),
{ 94: } ( len: 1; sym: -23 ),
{ 95: } ( len: 3; sym: -23 )
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
function typeBoolExpr(expr : BoolExpr) : BoolExpr; forward;

function optimizeBoolExpr(expr : BoolExpr) : BoolExpr; forward;
function optimizeExpr(expr : Expr) : Expr; forward;

procedure showExpr(expr : Expr); forward;
procedure showBoolExpr(expr : BoolExpr); forward;

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
    _BOOL 	: Result := 'bool';
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
  if ((src = _FLOAT) or (src = _EXTERNAL) or (src = _BOOL)) and (dest = _INT) then
    begin
    cn := Expr_Conv.Create;
		cn.ex := expr;
		cn.cnv := CONV_TO_INT;
		cn.originaltyp := src;
		cn.typ := _INT;

		Result := cn;
    end
  else
  if ((src = _INT) or (src = _FLOAT) or (src = _EXTERNAL) or (src = _BOOL)) and (dest = _STRING) then
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

function typeBoolExpr(expr : BoolExpr) : BoolExpr;
var
	  t1, t2 : integer;
begin
  Result := expr;
  
  if (expr = nil) then
    exit;

	Result.typ := _BOOL;

  if (expr is BoolExpr_Const) then 
		expr.typ := _BOOL
  else
  if (expr is BoolExpr_And) then 
    begin
	  BoolExpr_And(expr).le := typeBoolExpr(BoolExpr_And(expr).le);
    BoolExpr_And(expr).re := typeBoolExpr(BoolExpr_And(expr).re);

		t1 := BoolExpr_And(expr).le.typ;
		t2 := BoolExpr_And(expr).re.typ;

    if (t1 <> _BOOL) or (t2 <> _BOOL) then
      compilerError(expr.lineNum, 'expression should be boolean');

    expr.typ := _BOOL;
    end
  else
  if (expr is BoolExpr_Or) then 
    begin
	  BoolExpr_Or(expr).le := typeBoolExpr(BoolExpr_Or(expr).le);
    BoolExpr_Or(expr).re := typeBoolExpr(BoolExpr_Or(expr).re);

		t1 := BoolExpr_Or(expr).le.typ;
		t2 := BoolExpr_Or(expr).re.typ;

    if (t1 <> _BOOL) or (t2 <> _BOOL) then
      compilerError(expr.lineNum, 'expression should be boolean');

    expr.typ := _BOOL;
    end
  else
  if (expr is BoolExpr_Rel) then 
    begin
    BoolExpr_Rel(expr).le := typeExpr(BoolExpr_Rel(expr).le);
    BoolExpr_Rel(expr).re := typeExpr(BoolExpr_Rel(expr).re);

		t1 := BoolExpr_Rel(expr).le.typ;
		t2 := BoolExpr_Rel(expr).re.typ;

    if (t1 <> t2) and (t1 <> _EXTERNAL) and (t2 <> _EXTERNAL) then
      compilerError(expr.lineNum, 'no appropriate conversion from ''' + typeToString(t1) + ''' to ''' + typeToString(t2) + '''');

    expr.typ := _BOOL;
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
  if (expr is Expr_Bool) then
    begin
    Expr_Bool(expr).ex := typeBoolExpr(Expr_Bool(expr).ex);

    if (Expr_Bool(expr).ex.typ <> _BOOL) then
      compilerError(expr.lineNum, 'expected boolean expression');

    expr.typ := _BOOL;
    end
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
    Expr_If(expr).ce := typeBoolExpr(Expr_If(expr).ce);
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
    Expr_Loop(expr).ce := typeBoolExpr(Expr_Loop(expr).ce);
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
    end;
end;

function optimizeBoolExpr(expr : BoolExpr) : BoolExpr;
var
	lval, rval : boolean;
begin
  Result := expr;

  if (expr is BoolExpr_And) then 
    begin
    BoolExpr_And(expr).le := optimizeBoolExpr(BoolExpr_And(expr).le);
    BoolExpr_And(expr).re := optimizeBoolExpr(BoolExpr_And(expr).re);

    if (BoolExpr_And(expr).le is BoolExpr_Const) and (BoolExpr_And(expr).re is BoolExpr_Const) then
      begin
      lval := BoolExpr_Const(BoolExpr_And(expr).le).value;
      rval := BoolExpr_Const(BoolExpr_And(expr).re).value;

      Result := BoolExpr_Const.Create;
      BoolExpr_Const(Result).value := lval and rval;

      BoolExpr_And(expr).le.Free;
      BoolExpr_And(expr).re.Free;
      expr.Free;
      end
    else
		if (BoolExpr_And(expr).le is BoolExpr_Const) then
		  begin
      lval := BoolExpr_Const(BoolExpr_And(expr).le).value;
      
      if (lval) then
        begin
        Result := BoolExpr_And(expr).re;
        BoolExpr_And(expr).le.Free;
        expr.Free;
        end
      else
        begin
        Result := BoolExpr_And(expr).le;
        BoolExpr_And(expr).re.Free;
        expr.Free;
        end;
      end
    else
		if (BoolExpr_And(expr).re is BoolExpr_Const) then
		  begin
      lval := BoolExpr_Const(BoolExpr_And(expr).re).value;
      
      if (lval) then
        begin
        Result := BoolExpr_And(expr).le;
        BoolExpr_And(expr).re.Free;
        expr.Free;
        end
      else
        begin
        Result := BoolExpr_And(expr).re;
        BoolExpr_And(expr).le.Free;
        expr.Free;
        end;
      end; 
    end
  else
  if (expr is BoolExpr_Or) then 
    begin
    BoolExpr_Or(expr).le := optimizeBoolExpr(BoolExpr_Or(expr).le);
    BoolExpr_Or(expr).re := optimizeBoolExpr(BoolExpr_Or(expr).re);

    if (BoolExpr_Or(expr).le is BoolExpr_Const) and (BoolExpr_Or(expr).re is BoolExpr_Const) then
      begin
      lval := BoolExpr_Const(BoolExpr_Or(expr).le).value;
      rval := BoolExpr_Const(BoolExpr_Or(expr).re).value;

      Result := BoolExpr_Const.Create;
      BoolExpr_Const(Result).value := lval and rval;

      BoolExpr_Or(expr).le.Free;
      BoolExpr_Or(expr).re.Free;
      expr.Free;
      end
    else
		if (BoolExpr_Or(expr).le is BoolExpr_Const) then
		  begin
      lval := BoolExpr_Const(BoolExpr_Or(expr).le).value;
      
      if (lval) then
        begin
        Result := BoolExpr_Or(expr).le;
        BoolExpr_Or(expr).re.Free;
        expr.Free;
        end
      else
        begin
        Result := BoolExpr_Or(expr).re;
        BoolExpr_Or(expr).le.Free;
        expr.Free;
        end;
      end
    else
		if (BoolExpr_Or(expr).re is BoolExpr_Const) then
		  begin
      lval := BoolExpr_Const(BoolExpr_Or(expr).re).value;
      
      if (lval) then
        begin
        Result := BoolExpr_Or(expr).re;
        BoolExpr_Or(expr).le.Free;
        expr.Free;
        end
      else
        begin
        Result := BoolExpr_Or(expr).le;
        BoolExpr_Or(expr).re.Free;
        expr.Free;
        end;
      end; 
    end
  else
  if (expr is BoolExpr_Rel) then 
    begin
    BoolExpr_Rel(expr).le := optimizeExpr(BoolExpr_Rel(expr).le);
    BoolExpr_Rel(expr).re := optimizeExpr(BoolExpr_Rel(expr).re);
    end;
end;

function optimizeExpr(expr : Expr) : Expr;
var
	lval, rval : integer;
  bval : boolean;
begin
  Result := expr;

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
  			'&': emit('BAND');
  			'|': emit('BOR');
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
  if (expr is Expr_Bool) then
    begin
    Expr_Bool(expr).ex := optimizeBoolExpr(Expr_Bool(expr).ex); 
    end
  else
  if (expr is Expr_If) then
    begin
    Expr_If(expr).ce := optimizeBoolExpr(Expr_If(expr).ce); 

    if (Expr_If(expr).ce is BoolExpr_Const) then
      begin
      bval := BoolExpr_Const(Expr_If(expr).ce).value;

      if (bval) then
        Result := Expr_If(expr).le
      else
        Result := Expr_If(expr).re;
      end;
    end
  else
  if (expr is Expr_Loop) then
    begin
    Expr_Loop(expr).init := optimizeExpr(Expr_Loop(expr).init);
    Expr_Loop(expr).ce := optimizeBoolExpr(Expr_Loop(expr).ce);
    Expr_Loop(expr).step := optimizeExpr(Expr_Loop(expr).step);
    Expr_Loop(expr).body := optimizeExpr(Expr_Loop(expr).body);
    end;
end;

procedure showBoolExpr(expr : BoolExpr);
begin
  if (expr = nil) then
    exit;

  if (expr is BoolExpr_Const) then 
    begin
    if (BoolExpr_Const(expr).value) then
      emit('PUSHI 1')
    else
      emit('PUSHI 0');
    end
  else
  if (expr is BoolExpr_And) then 
    begin
    showBoolExpr(BoolExpr_And(expr).le);
    showBoolExpr(BoolExpr_And(expr).re);
    emit('AND');
    end
  else
  if (expr is BoolExpr_Or) then 
    begin
    showBoolExpr(BoolExpr_Or(expr).le);
    showBoolExpr(BoolExpr_Or(expr).re);
    emit('OR');
    end
  else
  if (expr is BoolExpr_Rel) then 
    begin
    showExpr(BoolExpr_Rel(expr).le);
    showExpr(BoolExpr_Rel(expr).re);

    if (BoolExpr_Rel(expr).op = '>') then
      emit('GT')
    else
    if (BoolExpr_Rel(expr).op = '<') then
      emit('LT')
    else
    if (BoolExpr_Rel(expr).op = '>=') then
      emit('GTE')
    else
    if (BoolExpr_Rel(expr).op = '=<') then
      emit('LTE')
    else
    if (BoolExpr_Rel(expr).op = '==') then
      emit('EQ');
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
			'&': emit('BAND');
			'|': emit('BOR');
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
    showBoolExpr(Expr_If(expr).ce); 

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
  if (expr is Expr_Bool) then
    begin
    showBoolExpr(Expr_Bool(expr).ex); 
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

		if (e.typ = _EXTERNAL) then
      emit('GET');
      
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
    showBoolExpr(Expr_Loop(Expr).ce);
    emit('JNZ L' + IntToStr(Expr_Loop(expr).lStart));
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