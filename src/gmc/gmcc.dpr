
(* Yacc parser template (TP Yacc V3.0), V1.2 6-17-91 AG *)

(* global definitions: *)


{$APPTYPE CONSOLE}
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
	VARTYPE_STATIC = 5;


type 	
	Root = class
		lineNum : integer;
		fname : string;
		typ : integer;
		
		constructor Create();
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

	Env_Entry = class(Root)
		id : string;
		lbl : integer;
		displ : integer;
		varTyp : integer;
		used : boolean;
	end;


var
	labelNum : integer;
	globalCount : integer;
	tmp, varName, varGlob : string;
	curFunction : string;
	varType : integer;
	includeList : TStringList;
	environment : TList;
	f : textfile;


procedure startCompiler(root : Expr); forward;
procedure updateLabel(id : string; lbl : integer); forward;
procedure addEnvironment(id : string; typ, lbl, varTyp : integer); forward;
function lookupEnv(id : string; lookupCounts : boolean = false) : Env_Entry; forward;
procedure compilerError(lineNum : integer; const fname, msg : string); forward;
procedure compilerWarning(lineNum : integer; const fname, msg : string); forward;


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
const _EXPORT = 286;
const _VOID = 287;
const _INT = 288;
const _FLOAT = 289;
const _STRING = 290;
const _EXTERNAL = 291;

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
         yyval.yyExpr := Expr_Return.Create; Expr_Return(yyval.yyExpr).ret := nil; Expr_Return(yyval.yyExpr).id := curFunction; 
       end;
  15 : begin
         yyval.yyExpr := Expr_Return.Create; Expr_Return(yyval.yyExpr).ret := yyv[yysp-1].yyExpr; Expr_Return(yyval.yyExpr).id := curFunction; 
       end;
  16 : begin
         yyval.yyExpr := Expr_Return.Create; Expr_Return(yyval.yyExpr).ret := yyv[yysp-2].yyExpr; Expr_Return(yyval.yyExpr).id := curFunction; 
       end;
  17 : begin
         yyval.yyExpr := nil; 
       end;
  18 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  19 : begin
         yyval.yyExpr := nil; lookupEnv(varName, true); 
       end;
  20 : begin
         	yyval.yyExpr := nil;
         											if (not FileExists(varName)) then
         												compilerError(yylineno, yyfname, 'could not open include file ' + varName)
         											else
         												begin
         												if (includeList.IndexOf(varName) > -1) then
         													compilerWarning(yylineno, yyfname, 'ignoring previously included file ' + varName)
         												else
         													begin
         													includeList.Add(varName);
         													yyopen(varName);
         													end;
         												end;	
       end;
  21 : begin
         yyval.yyExpr := nil; 
       end;
  22 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; if (yyval.yyExpr <> nil) then yyval.yyExpr.lineNum := yylineno; 
       end;
  23 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr; if (yyval.yyExpr <> nil) then yyval.yyExpr.lineNum := yylineno; 
       end;
  24 : begin
         yyval.yyExpr := Expr_If.Create; Expr_If(yyval.yyExpr).ce := yyv[yysp-4].yyExpr;	
         																														Expr_If(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_If(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
         																														Expr_If(yyval.yyExpr).lThen := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lElse := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lAfter := labelNum; inc(labelNum); 
       end;
  25 : begin
         yyval.yyExpr := Expr_If.Create; Expr_If(yyval.yyExpr).ce := yyv[yysp-2].yyExpr; 
         																														Expr_If(yyval.yyExpr).le := yyv[yysp-0].yyExpr; Expr_If(yyval.yyExpr).re := nil; 
         																														Expr_If(yyval.yyExpr).lThen := labelNum; inc(labelNum); 
         																														Expr_If(yyval.yyExpr).lAfter := labelNum; inc(labelNum); 
       end;
  26 : begin
         yyval.yyExpr := Expr_Loop.Create; Expr_Loop(yyval.yyExpr).init := yyv[yysp-6].yyExpr;
         				                                                    Expr_Loop(yyval.yyExpr).ce := yyv[yysp-4].yyExpr;
         				                                                    Expr_Loop(yyval.yyExpr).lStart := labelNum; inc(labelNum);
         				                                                    Expr_Loop(yyval.yyExpr).step := yyv[yysp-2].yyExpr; Expr_Loop(yyval.yyExpr).body := yyv[yysp-0].yyExpr; 
       end;
  27 : begin
         yyval.yyExpr := Expr_Special.Create; Expr_Special(yyval.yyExpr).spec := SPECIAL_TRAP; Expr_Special(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  28 : begin
         yyval.yyExpr := Expr_Special.Create; Expr_Special(yyval.yyExpr).spec := SPECIAL_SLEEP; Expr_Special(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  29 : begin
         yyval.yyExpr := Expr_Special.Create; Expr_Special(yyval.yyExpr).spec := SPECIAL_WAIT; Expr_Special(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  30 : begin
         yyval.yyExpr := Expr_Special.Create; Expr_Special(yyval.yyExpr).spec := SPECIAL_SIGNAL; Expr_Special(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  31 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr; 
       end;
  32 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  33 : begin
         yyval.yyExpr := nil; 
       end;
  34 : begin
         yyval.yyExpr := nil; 
       end;
  35 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  36 : begin
         yyval.yyExpr := nil; 
       end;
  37 : begin
         yyval.yyExpr := nil; addEnvironment(curFunction + ':' + varName, varType, -1, VARTYPE_PARAM); 
       end;
  38 : begin
         yyval.yyExpr := nil; 
       end;
  39 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  40 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-2].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
       end;
  41 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  42 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-0].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  43 : begin
         yyval.yyExpr := Expr_Asm.Create; Expr_Asm(yyval.yyExpr).line := varName; 
       end;
  44 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := nil; Expr_Seq(yyval.yyExpr).ex := nil; 
       end;
  45 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr;  
       end;
  46 : begin
         yyval.yyExpr := nil; 
       end;
  47 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  48 : begin
         yyval.yyExpr := Expr_Seq.Create; Expr_Seq(yyval.yyExpr).seq := yyv[yysp-0].yyExpr; Expr_Seq(yyval.yyExpr).ex := yyv[yysp-1].yyExpr; 
       end;
  49 : begin
         curFunction := varName;	 yyval.yyExpr := Expr_Func.Create; Expr_Func(yyval.yyExpr).id := curFunction;
         																				Expr_Func(yyval.yyExpr).lStart := labelNum; inc(labelNum);
         																				addEnvironment(varName, varType, Expr_Func(yyval.yyExpr).lStart, VARTYPE_FUNCTION); 
       end;
  50 : begin
         yyval.yyExpr := nil; 
       end;
  51 : begin
         yyval.yyExpr := yyv[yysp-0].yyExpr; 
       end;
  52 : begin
         yyval.yyExpr := nil; 
       end;
  53 : begin
         yyval.yyExpr := yyv[yysp-4].yyExpr; Expr_Func(yyval.yyExpr).body := yyv[yysp-0].yyExpr; 
         if (yyv[yysp-0].yyExpr = nil) then updateLabel(curFunction, -1);  curFunction := ''; 
       end;
  54 : begin
         yyval := yyv[yysp-0];
       end;
  55 : begin
         yyval := yyv[yysp-2];
       end;
  56 : begin
         varName := curFunction + ':' + varName; 
         yyval.yyShortString := varName; 
         if (curFunction = '') then
         addEnvironment(varName, varType, -1, VARTYPE_GLOBAL)
         else
         addEnvironment(varName, varType, -1, VARTYPE_LOCAL); 
       end;
  57 : begin
         varType := _VOID; yyval.yyInteger := _VOID; 
       end;
  58 : begin
         varType := _INT; yyval.yyInteger := _INT; 
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
         yyval.yyExpr := Expr_Op.Create; Expr_Op(yyval.yyExpr).op := '+'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  64 : begin
         yyval.yyExpr := Expr_Op.Create; Expr_Op(yyval.yyExpr).op := '-'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  65 : begin
         yyval.yyExpr := Expr_Op.Create; Expr_Op(yyval.yyExpr).op := '*'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  66 : begin
         yyval.yyExpr := Expr_Op.Create; Expr_Op(yyval.yyExpr).op := '/'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  67 : begin
         yyval.yyExpr := Expr_Op.Create; Expr_Op(yyval.yyExpr).op := '%'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  68 : begin
         yyval.yyExpr := Expr_Op.Create; Expr_Op(yyval.yyExpr).op := '&'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  69 : begin
         yyval.yyExpr := Expr_Op.Create; Expr_Op(yyval.yyExpr).op := '|'; Expr_Op(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Op(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  70 : begin
         yyval.yyExpr := yyv[yysp-1].yyExpr; 
       end;
  71 : begin
         yyval.yyExpr := Expr_Neg.Create; Expr_Neg(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
       end;
  72 : begin
         yyval.yyExpr := Expr_ConstInt.Create; Expr_ConstInt(yyval.yyExpr).value := yyv[yysp-0].yyInteger; 
       end;
  73 : begin
         yyval.yyExpr := Expr_ConstFloat.Create; Expr_ConstFloat(yyval.yyExpr).value := yyv[yysp-0].yySingle; 
       end;
  74 : begin
         yyval.yyExpr := Expr_String.Create; Expr_String(yyval.yyExpr).value := ''; 
       end;
  75 : begin
         yyval.yyExpr := Expr_String.Create; Expr_String(yyval.yyExpr).value := varName; 
       end;
  76 : begin
         yyval.yyExpr := Expr_Cast.Create; Expr_Cast(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; Expr_Cast(yyval.yyExpr).desttype := yyv[yysp-2].yyInteger; 
       end;
  77 : begin
         if (yyv[yysp-2].yyExpr <> nil) then
         								begin
         								yyval.yyExpr := Expr_Assign.Create; 
         								Expr_Assign(yyval.yyExpr).id := yyv[yysp-2].yyExpr; 
         								Expr_Assign(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
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
         																		compilerError(yylineno, yyfname, 'undefined function "' + yyv[yysp-3].yyShortString + '"');
         																		yyval.yyExpr := nil;
         																		yyabort;
         																		end;
         																	yyval.yyExpr := Expr_Call.Create; Expr_Call(yyval.yyExpr).id := yyv[yysp-3].yyShortString; Expr_Call(yyval.yyExpr).params := yyv[yysp-1].yyExpr; 
       end;
  80 : begin
         yyval.yyExpr := Expr_Rel.Create; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '>';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  81 : begin
         yyval.yyExpr := Expr_Rel.Create; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '<';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  82 : begin
         yyval.yyExpr := Expr_Rel.Create; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '>=';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  83 : begin
         yyval.yyExpr := Expr_Rel.Create; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '=<';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  84 : begin
         yyval.yyExpr := Expr_Rel.Create; Expr_Rel(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Rel(yyval.yyExpr).op := '==';  Expr_Rel(yyval.yyExpr).re := yyv[yysp-0].yyExpr; 
       end;
  85 : begin
         yyval.yyExpr := Expr_And.Create; Expr_And(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_And(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  86 : begin
         yyval.yyExpr := Expr_Or.Create; Expr_Or(yyval.yyExpr).le := yyv[yysp-2].yyExpr; Expr_Or(yyval.yyExpr).re := yyv[yysp-0].yyExpr; yyval.yyExpr.lineNum := yylineno;
       end;
  87 : begin
         yyval.yyExpr := Expr_Not.Create; Expr_Not(yyval.yyExpr).ex := yyv[yysp-0].yyExpr; 
       end;
  88 : begin
         yyval.yyExpr := Expr_ConstInt.Create; Expr_ConstInt(yyval.yyExpr).value := 1; 
       end;
  89 : begin
         yyval.yyExpr := Expr_ConstInt.Create; Expr_ConstInt(yyval.yyExpr).value := 0; 
       end;
  90 : begin
         yyval.yyShortString := varName; 
       end;
  91 : begin
         varGlob := ':' + yyv[yysp-0].yyShortString;
         tmp := curFunction + varGlob;
         varGlob := left(varGlob, '.');
         												varName := left(tmp, '.');
         																																		
         												if (varName <> tmp) then
         begin
         if (lookupEnv(varName) <> nil) then
         begin
         													yyval.yyExpr := Expr_External.Create;
         													Expr_External(yyval.yyExpr).id := varName;
         													Expr_External(yyval.yyExpr).assoc := right(tmp, '.');
         													end
         												else
         												  begin
         													compilerError(yylineno, yyfname, 'undeclared identifier "' + right(varGlob, ':') + '"');
         													yyval.yyExpr := nil;
         	  												yyabort;
         	  												end;
         													end
         												else
         												if (lookupEnv(varName) <> nil) then 
         													begin
         													yyval.yyExpr := Expr_Id.Create;
         													Expr_Id(yyval.yyExpr).id := varName;
         													end
         												else
         												if (lookupEnv(varGlob) <> nil) then 
         													begin
         													yyval.yyExpr := Expr_Id.Create;
         													Expr_Id(yyval.yyExpr).id := varGlob;
         													end
         												else
         													begin
         													compilerError(yylineno, yyfname, 'undeclared identifier "' + right(varGlob, ':') + '"');
         													yyval.yyExpr := nil;
         													yyabort;
         													end; 
       end;
  92 : begin
       end;
  93 : begin
         yyval.yyShortString := varName; 
       end;
  94 : begin
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

yynacts   = 1771;
yyngotos  = 198;
yynstates = 163;
yynrules  = 94;

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
  ( sym: 291; act: -1 ),
{ 1: }
  ( sym: 0; act: 0 ),
  ( sym: 10; act: 9 ),
  ( sym: 285; act: 10 ),
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
{ 2: }
  ( sym: 10; act: 17 ),
{ 3: }
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
  ( sym: 0; act: -18 ),
  ( sym: 10; act: -18 ),
  ( sym: 285; act: -18 ),
  ( sym: 286; act: -18 ),
{ 4: }
{ 5: }
  ( sym: 285; act: 10 ),
  ( sym: 286; act: 11 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
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
  ( sym: 257; act: 25 ),
{ 12: }
{ 13: }
{ 14: }
{ 15: }
{ 16: }
{ 17: }
{ 18: }
{ 19: }
{ 20: }
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
  ( sym: 41; act: -34 ),
  ( sym: 44; act: -34 ),
{ 21: }
  ( sym: 44; act: 29 ),
  ( sym: 59; act: 30 ),
{ 22: }
{ 23: }
  ( sym: 40; act: -49 ),
  ( sym: 44; act: -56 ),
  ( sym: 59; act: -56 ),
{ 24: }
  ( sym: 258; act: 31 ),
{ 25: }
{ 26: }
{ 27: }
  ( sym: 41; act: 32 ),
  ( sym: 44; act: 33 ),
{ 28: }
  ( sym: 257; act: 34 ),
{ 29: }
  ( sym: 257; act: 36 ),
{ 30: }
{ 31: }
  ( sym: 34; act: 37 ),
{ 32: }
  ( sym: 59; act: 40 ),
  ( sym: 123; act: 41 ),
{ 33: }
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
{ 34: }
{ 35: }
{ 36: }
{ 37: }
{ 38: }
{ 39: }
{ 40: }
{ 41: }
  ( sym: 125; act: 44 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
  ( sym: 34; act: -46 ),
  ( sym: 37; act: -46 ),
  ( sym: 38; act: -46 ),
  ( sym: 40; act: -46 ),
  ( sym: 42; act: -46 ),
  ( sym: 43; act: -46 ),
  ( sym: 45; act: -46 ),
  ( sym: 46; act: -46 ),
  ( sym: 47; act: -46 ),
  ( sym: 59; act: -46 ),
  ( sym: 61; act: -46 ),
  ( sym: 123; act: -46 ),
  ( sym: 124; act: -46 ),
  ( sym: 257; act: -46 ),
  ( sym: 259; act: -46 ),
  ( sym: 260; act: -46 ),
  ( sym: 263; act: -46 ),
  ( sym: 265; act: -46 ),
  ( sym: 266; act: -46 ),
  ( sym: 267; act: -46 ),
  ( sym: 268; act: -46 ),
  ( sym: 269; act: -46 ),
  ( sym: 270; act: -46 ),
  ( sym: 271; act: -46 ),
  ( sym: 272; act: -46 ),
  ( sym: 273; act: -46 ),
  ( sym: 274; act: -46 ),
  ( sym: 275; act: -46 ),
  ( sym: 276; act: -46 ),
  ( sym: 277; act: -46 ),
  ( sym: 278; act: -46 ),
  ( sym: 279; act: -46 ),
  ( sym: 280; act: -46 ),
  ( sym: 281; act: -46 ),
  ( sym: 282; act: -46 ),
  ( sym: 284; act: -46 ),
{ 42: }
{ 43: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 41 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 282; act: 71 ),
  ( sym: 284; act: 72 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
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
{ 44: }
{ 45: }
  ( sym: 46; act: 73 ),
  ( sym: 37; act: -91 ),
  ( sym: 38; act: -91 ),
  ( sym: 41; act: -91 ),
  ( sym: 42; act: -91 ),
  ( sym: 43; act: -91 ),
  ( sym: 44; act: -91 ),
  ( sym: 45; act: -91 ),
  ( sym: 47; act: -91 ),
  ( sym: 59; act: -91 ),
  ( sym: 61; act: -91 ),
  ( sym: 124; act: -91 ),
  ( sym: 268; act: -91 ),
  ( sym: 269; act: -91 ),
  ( sym: 271; act: -91 ),
  ( sym: 272; act: -91 ),
  ( sym: 273; act: -91 ),
  ( sym: 274; act: -91 ),
  ( sym: 275; act: -91 ),
{ 46: }
  ( sym: 40; act: 74 ),
{ 47: }
  ( sym: 61; act: 75 ),
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
  ( sym: 271; act: -78 ),
  ( sym: 272; act: -78 ),
  ( sym: 273; act: -78 ),
  ( sym: 274; act: -78 ),
  ( sym: 275; act: -78 ),
{ 48: }
{ 49: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 41 ),
  ( sym: 125; act: 77 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 282; act: 71 ),
  ( sym: 284; act: 72 ),
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
{ 50: }
{ 51: }
{ 52: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 59; act: 84 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 53: }
  ( sym: 34; act: 93 ),
  ( sym: 258; act: 94 ),
{ 54: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 55: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 56: }
{ 57: }
  ( sym: 40; act: -90 ),
  ( sym: 37; act: -93 ),
  ( sym: 38; act: -93 ),
  ( sym: 41; act: -93 ),
  ( sym: 42; act: -93 ),
  ( sym: 43; act: -93 ),
  ( sym: 44; act: -93 ),
  ( sym: 45; act: -93 ),
  ( sym: 46; act: -93 ),
  ( sym: 47; act: -93 ),
  ( sym: 59; act: -93 ),
  ( sym: 61; act: -93 ),
  ( sym: 124; act: -93 ),
  ( sym: 268; act: -93 ),
  ( sym: 269; act: -93 ),
  ( sym: 271; act: -93 ),
  ( sym: 272; act: -93 ),
  ( sym: 273; act: -93 ),
  ( sym: 274; act: -93 ),
  ( sym: 275; act: -93 ),
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
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 65: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 102 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 103 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 66: }
  ( sym: 59; act: 104 ),
{ 67: }
  ( sym: 59; act: 105 ),
{ 68: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 69: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 70: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 71: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 72: }
  ( sym: 40; act: 110 ),
{ 73: }
  ( sym: 257; act: 111 ),
{ 74: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 41; act: -38 ),
  ( sym: 44; act: -38 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 75: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 76: }
{ 77: }
{ 78: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 79: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 80: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 81: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 82: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 83: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 84: }
{ 85: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 86: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 87: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 88: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 89: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 90: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 91: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 92: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 93: }
{ 94: }
  ( sym: 34; act: 129 ),
{ 95: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 41; act: 130 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 96: }
  ( sym: 41; act: 131 ),
{ 97: }
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
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
{ 98: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 99: }
  ( sym: 34; act: 135 ),
{ 100: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -87 ),
  ( sym: 44; act: -87 ),
  ( sym: 59; act: -87 ),
{ 101: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 59; act: 136 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 102: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 287; act: 12 ),
  ( sym: 288; act: 13 ),
  ( sym: 289; act: 14 ),
  ( sym: 290; act: 15 ),
  ( sym: 291; act: 16 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 103: }
{ 104: }
{ 105: }
{ 106: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 59; act: 138 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 107: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 59; act: 139 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 108: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 59; act: 140 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 109: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 59; act: 141 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 110: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 111: }
{ 112: }
  ( sym: 41; act: 143 ),
  ( sym: 44; act: 144 ),
{ 113: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -39 ),
  ( sym: 44; act: -39 ),
{ 114: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -77 ),
  ( sym: 44; act: -77 ),
  ( sym: 59; act: -77 ),
{ 115: }
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
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
{ 116: }
  ( sym: 37; act: 78 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 38; act: -68 ),
  ( sym: 41; act: -68 ),
  ( sym: 44; act: -68 ),
  ( sym: 59; act: -68 ),
  ( sym: 124; act: -68 ),
{ 117: }
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
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
{ 118: }
  ( sym: 37; act: 78 ),
  ( sym: 42; act: 80 ),
  ( sym: 47; act: 83 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 38; act: -63 ),
  ( sym: 41; act: -63 ),
  ( sym: 43; act: -63 ),
  ( sym: 44; act: -63 ),
  ( sym: 45; act: -63 ),
  ( sym: 59; act: -63 ),
  ( sym: 124; act: -63 ),
{ 119: }
  ( sym: 37; act: 78 ),
  ( sym: 42; act: 80 ),
  ( sym: 47; act: 83 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 38; act: -64 ),
  ( sym: 41; act: -64 ),
  ( sym: 43; act: -64 ),
  ( sym: 44; act: -64 ),
  ( sym: 45; act: -64 ),
  ( sym: 59; act: -64 ),
  ( sym: 124; act: -64 ),
{ 120: }
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
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
{ 121: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -69 ),
  ( sym: 44; act: -69 ),
  ( sym: 59; act: -69 ),
  ( sym: 124; act: -69 ),
{ 122: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -85 ),
  ( sym: 44; act: -85 ),
  ( sym: 59; act: -85 ),
{ 123: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -86 ),
  ( sym: 44; act: -86 ),
  ( sym: 59; act: -86 ),
{ 124: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -80 ),
  ( sym: 44; act: -80 ),
  ( sym: 59; act: -80 ),
{ 125: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -81 ),
  ( sym: 44; act: -81 ),
  ( sym: 59; act: -81 ),
{ 126: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -82 ),
  ( sym: 44; act: -82 ),
  ( sym: 59; act: -82 ),
{ 127: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -83 ),
  ( sym: 44; act: -83 ),
  ( sym: 59; act: -83 ),
{ 128: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -84 ),
  ( sym: 44; act: -84 ),
  ( sym: 59; act: -84 ),
{ 129: }
{ 130: }
{ 131: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
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
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 132: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 41; act: 146 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 133: }
{ 134: }
  ( sym: 34; act: 135 ),
  ( sym: 125; act: 148 ),
{ 135: }
  ( sym: 258; act: 149 ),
{ 136: }
{ 137: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 41; act: 150 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 138: }
{ 139: }
{ 140: }
{ 141: }
{ 142: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 59; act: 151 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 143: }
{ 144: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 44; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 145: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -76 ),
  ( sym: 44; act: -76 ),
  ( sym: 59; act: -76 ),
{ 146: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 41 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 282; act: 71 ),
  ( sym: 284; act: 72 ),
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
{ 147: }
{ 148: }
{ 149: }
  ( sym: 34; act: 154 ),
{ 150: }
  ( sym: 59; act: 155 ),
  ( sym: 37; act: -70 ),
  ( sym: 38; act: -70 ),
  ( sym: 42; act: -70 ),
  ( sym: 43; act: -70 ),
  ( sym: 45; act: -70 ),
  ( sym: 47; act: -70 ),
  ( sym: 124; act: -70 ),
  ( sym: 268; act: -70 ),
  ( sym: 269; act: -70 ),
  ( sym: 271; act: -70 ),
  ( sym: 272; act: -70 ),
  ( sym: 273; act: -70 ),
  ( sym: 274; act: -70 ),
  ( sym: 275; act: -70 ),
{ 151: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 59; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 152: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
  ( sym: 41; act: -40 ),
  ( sym: 44; act: -40 ),
{ 153: }
  ( sym: 264; act: 157 ),
  ( sym: 34; act: -25 ),
  ( sym: 37; act: -25 ),
  ( sym: 38; act: -25 ),
  ( sym: 40; act: -25 ),
  ( sym: 42; act: -25 ),
  ( sym: 43; act: -25 ),
  ( sym: 45; act: -25 ),
  ( sym: 46; act: -25 ),
  ( sym: 47; act: -25 ),
  ( sym: 59; act: -25 ),
  ( sym: 61; act: -25 ),
  ( sym: 123; act: -25 ),
  ( sym: 124; act: -25 ),
  ( sym: 125; act: -25 ),
  ( sym: 257; act: -25 ),
  ( sym: 259; act: -25 ),
  ( sym: 260; act: -25 ),
  ( sym: 263; act: -25 ),
  ( sym: 265; act: -25 ),
  ( sym: 266; act: -25 ),
  ( sym: 267; act: -25 ),
  ( sym: 268; act: -25 ),
  ( sym: 269; act: -25 ),
  ( sym: 270; act: -25 ),
  ( sym: 271; act: -25 ),
  ( sym: 272; act: -25 ),
  ( sym: 273; act: -25 ),
  ( sym: 274; act: -25 ),
  ( sym: 275; act: -25 ),
  ( sym: 276; act: -25 ),
  ( sym: 277; act: -25 ),
  ( sym: 278; act: -25 ),
  ( sym: 279; act: -25 ),
  ( sym: 280; act: -25 ),
  ( sym: 281; act: -25 ),
  ( sym: 282; act: -25 ),
  ( sym: 284; act: -25 ),
{ 154: }
{ 155: }
{ 156: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 59; act: 158 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 157: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 41 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 282; act: 71 ),
  ( sym: 284; act: 72 ),
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
{ 158: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 37; act: -62 ),
  ( sym: 38; act: -62 ),
  ( sym: 41; act: -62 ),
  ( sym: 42; act: -62 ),
  ( sym: 43; act: -62 ),
  ( sym: 47; act: -62 ),
  ( sym: 124; act: -62 ),
  ( sym: 268; act: -62 ),
  ( sym: 269; act: -62 ),
  ( sym: 271; act: -62 ),
  ( sym: 272; act: -62 ),
  ( sym: 273; act: -62 ),
  ( sym: 274; act: -62 ),
  ( sym: 275; act: -62 ),
  ( sym: 46; act: -92 ),
  ( sym: 61; act: -92 ),
{ 159: }
{ 160: }
  ( sym: 37; act: 78 ),
  ( sym: 38; act: 79 ),
  ( sym: 41; act: 161 ),
  ( sym: 42; act: 80 ),
  ( sym: 43; act: 81 ),
  ( sym: 45; act: 82 ),
  ( sym: 47; act: 83 ),
  ( sym: 124; act: 85 ),
  ( sym: 268; act: 86 ),
  ( sym: 269; act: 87 ),
  ( sym: 271; act: 88 ),
  ( sym: 272; act: 89 ),
  ( sym: 273; act: 90 ),
  ( sym: 274; act: 91 ),
  ( sym: 275; act: 92 ),
{ 161: }
  ( sym: 34; act: 53 ),
  ( sym: 40; act: 54 ),
  ( sym: 45; act: 55 ),
  ( sym: 59; act: 56 ),
  ( sym: 123; act: 41 ),
  ( sym: 257; act: 57 ),
  ( sym: 259; act: 58 ),
  ( sym: 260; act: 59 ),
  ( sym: 263; act: 60 ),
  ( sym: 265; act: 61 ),
  ( sym: 266; act: 62 ),
  ( sym: 267; act: 63 ),
  ( sym: 270; act: 64 ),
  ( sym: 276; act: 65 ),
  ( sym: 277; act: 66 ),
  ( sym: 278; act: 67 ),
  ( sym: 279; act: 68 ),
  ( sym: 280; act: 69 ),
  ( sym: 281; act: 70 ),
  ( sym: 282; act: 71 ),
  ( sym: 284; act: 72 ),
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
{ 162: }
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
  ( sym: -25; act: 21 ),
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
  ( sym: -12; act: 26 ),
  ( sym: -11; act: 27 ),
  ( sym: -2; act: 28 ),
{ 21: }
{ 22: }
{ 23: }
{ 24: }
{ 25: }
{ 26: }
{ 27: }
{ 28: }
{ 29: }
  ( sym: -21; act: 35 ),
{ 30: }
{ 31: }
{ 32: }
  ( sym: -14; act: 38 ),
  ( sym: -6; act: 39 ),
{ 33: }
  ( sym: -12; act: 42 ),
  ( sym: -2; act: 28 ),
{ 34: }
{ 35: }
{ 36: }
{ 37: }
{ 38: }
{ 39: }
{ 40: }
{ 41: }
  ( sym: -16; act: 43 ),
  ( sym: -15; act: 4 ),
  ( sym: -5; act: 7 ),
  ( sym: -2; act: 8 ),
{ 42: }
{ 43: }
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
{ 44: }
{ 45: }
{ 46: }
{ 47: }
{ 48: }
{ 49: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -14; act: 48 ),
  ( sym: -9; act: 76 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 ),
{ 50: }
{ 51: }
{ 52: }
{ 53: }
{ 54: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 95 ),
  ( sym: -2; act: 96 ),
{ 55: }
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
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 100 ),
{ 65: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 101 ),
{ 66: }
{ 67: }
{ 68: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 106 ),
{ 69: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 107 ),
{ 70: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 108 ),
{ 71: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 109 ),
{ 72: }
{ 73: }
{ 74: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -13; act: 112 ),
  ( sym: -3; act: 113 ),
{ 75: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 114 ),
{ 76: }
{ 77: }
{ 78: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 115 ),
{ 79: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 116 ),
{ 80: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 117 ),
{ 81: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 118 ),
{ 82: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 119 ),
{ 83: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 120 ),
{ 84: }
{ 85: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 121 ),
{ 86: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 122 ),
{ 87: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 123 ),
{ 88: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 124 ),
{ 89: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 125 ),
{ 90: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 126 ),
{ 91: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 127 ),
{ 92: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 128 ),
{ 93: }
{ 94: }
{ 95: }
{ 96: }
{ 97: }
{ 98: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 132 ),
{ 99: }
  ( sym: -20; act: 133 ),
  ( sym: -19; act: 134 ),
{ 100: }
{ 101: }
{ 102: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 137 ),
  ( sym: -2; act: 96 ),
{ 103: }
{ 104: }
{ 105: }
{ 106: }
{ 107: }
{ 108: }
{ 109: }
{ 110: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 142 ),
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
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 145 ),
{ 132: }
{ 133: }
{ 134: }
  ( sym: -20; act: 147 ),
{ 135: }
{ 136: }
{ 137: }
{ 138: }
{ 139: }
{ 140: }
{ 141: }
{ 142: }
{ 143: }
{ 144: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 152 ),
{ 145: }
{ 146: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -14; act: 48 ),
  ( sym: -9; act: 153 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 ),
{ 147: }
{ 148: }
{ 149: }
{ 150: }
{ 151: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 156 ),
{ 152: }
{ 153: }
{ 154: }
{ 155: }
{ 156: }
{ 157: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -14; act: 48 ),
  ( sym: -9; act: 159 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 ),
{ 158: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -3; act: 160 ),
{ 159: }
{ 160: }
{ 161: }
  ( sym: -23; act: 45 ),
  ( sym: -22; act: 46 ),
  ( sym: -18; act: 47 ),
  ( sym: -14; act: 48 ),
  ( sym: -9; act: 162 ),
  ( sym: -4; act: 51 ),
  ( sym: -3; act: 52 )
{ 162: }
);

yyd : array [0..yynstates-1] of Integer = (
{ 0: } 0,
{ 1: } 0,
{ 2: } 0,
{ 3: } 0,
{ 4: } -47,
{ 5: } 0,
{ 6: } -6,
{ 7: } 0,
{ 8: } 0,
{ 9: } -2,
{ 10: } 0,
{ 11: } 0,
{ 12: } -57,
{ 13: } -58,
{ 14: } -59,
{ 15: } -60,
{ 16: } -61,
{ 17: } -4,
{ 18: } -48,
{ 19: } -7,
{ 20: } 0,
{ 21: } 0,
{ 22: } -54,
{ 23: } 0,
{ 24: } 0,
{ 25: } -19,
{ 26: } -35,
{ 27: } 0,
{ 28: } 0,
{ 29: } 0,
{ 30: } -52,
{ 31: } 0,
{ 32: } 0,
{ 33: } 0,
{ 34: } -37,
{ 35: } -55,
{ 36: } -56,
{ 37: } -20,
{ 38: } -51,
{ 39: } -53,
{ 40: } -50,
{ 41: } 0,
{ 42: } -36,
{ 43: } 0,
{ 44: } -44,
{ 45: } 0,
{ 46: } 0,
{ 47: } 0,
{ 48: } -22,
{ 49: } 0,
{ 50: } -9,
{ 51: } -32,
{ 52: } 0,
{ 53: } 0,
{ 54: } 0,
{ 55: } 0,
{ 56: } -33,
{ 57: } 0,
{ 58: } -72,
{ 59: } -73,
{ 60: } 0,
{ 61: } 0,
{ 62: } -88,
{ 63: } -89,
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
{ 76: } -10,
{ 77: } -45,
{ 78: } 0,
{ 79: } 0,
{ 80: } 0,
{ 81: } 0,
{ 82: } 0,
{ 83: } 0,
{ 84: } -23,
{ 85: } 0,
{ 86: } 0,
{ 87: } 0,
{ 88: } 0,
{ 89: } 0,
{ 90: } 0,
{ 91: } 0,
{ 92: } 0,
{ 93: } -74,
{ 94: } 0,
{ 95: } 0,
{ 96: } 0,
{ 97: } 0,
{ 98: } 0,
{ 99: } 0,
{ 100: } 0,
{ 101: } 0,
{ 102: } 0,
{ 103: } -14,
{ 104: } -12,
{ 105: } -13,
{ 106: } 0,
{ 107: } 0,
{ 108: } 0,
{ 109: } 0,
{ 110: } 0,
{ 111: } -94,
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
{ 127: } 0,
{ 128: } 0,
{ 129: } -75,
{ 130: } -70,
{ 131: } 0,
{ 132: } 0,
{ 133: } -41,
{ 134: } 0,
{ 135: } 0,
{ 136: } -15,
{ 137: } 0,
{ 138: } -27,
{ 139: } -28,
{ 140: } -29,
{ 141: } -30,
{ 142: } 0,
{ 143: } -79,
{ 144: } 0,
{ 145: } 0,
{ 146: } 0,
{ 147: } -42,
{ 148: } -31,
{ 149: } 0,
{ 150: } 0,
{ 151: } 0,
{ 152: } 0,
{ 153: } 0,
{ 154: } -43,
{ 155: } -16,
{ 156: } 0,
{ 157: } 0,
{ 158: } 0,
{ 159: } -24,
{ 160: } 0,
{ 161: } 0,
{ 162: } -26
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
{ 12: } 43,
{ 13: } 43,
{ 14: } 43,
{ 15: } 43,
{ 16: } 43,
{ 17: } 43,
{ 18: } 43,
{ 19: } 43,
{ 20: } 43,
{ 21: } 50,
{ 22: } 52,
{ 23: } 52,
{ 24: } 55,
{ 25: } 56,
{ 26: } 56,
{ 27: } 56,
{ 28: } 58,
{ 29: } 59,
{ 30: } 60,
{ 31: } 60,
{ 32: } 61,
{ 33: } 63,
{ 34: } 68,
{ 35: } 68,
{ 36: } 68,
{ 37: } 68,
{ 38: } 68,
{ 39: } 68,
{ 40: } 68,
{ 41: } 68,
{ 42: } 110,
{ 43: } 110,
{ 44: } 152,
{ 45: } 152,
{ 46: } 171,
{ 47: } 172,
{ 48: } 190,
{ 49: } 190,
{ 50: } 227,
{ 51: } 227,
{ 52: } 227,
{ 53: } 242,
{ 54: } 244,
{ 55: } 274,
{ 56: } 301,
{ 57: } 301,
{ 58: } 321,
{ 59: } 321,
{ 60: } 321,
{ 61: } 322,
{ 62: } 323,
{ 63: } 323,
{ 64: } 323,
{ 65: } 350,
{ 66: } 375,
{ 67: } 376,
{ 68: } 377,
{ 69: } 402,
{ 70: } 427,
{ 71: } 452,
{ 72: } 477,
{ 73: } 478,
{ 74: } 479,
{ 75: } 505,
{ 76: } 532,
{ 77: } 532,
{ 78: } 532,
{ 79: } 559,
{ 80: } 586,
{ 81: } 613,
{ 82: } 640,
{ 83: } 667,
{ 84: } 694,
{ 85: } 694,
{ 86: } 721,
{ 87: } 748,
{ 88: } 775,
{ 89: } 802,
{ 90: } 829,
{ 91: } 856,
{ 92: } 883,
{ 93: } 910,
{ 94: } 910,
{ 95: } 911,
{ 96: } 926,
{ 97: } 927,
{ 98: } 944,
{ 99: } 969,
{ 100: } 970,
{ 101: } 987,
{ 102: } 1002,
{ 103: } 1032,
{ 104: } 1032,
{ 105: } 1032,
{ 106: } 1032,
{ 107: } 1047,
{ 108: } 1062,
{ 109: } 1077,
{ 110: } 1092,
{ 111: } 1117,
{ 112: } 1117,
{ 113: } 1119,
{ 114: } 1135,
{ 115: } 1152,
{ 116: } 1169,
{ 117: } 1186,
{ 118: } 1203,
{ 119: } 1220,
{ 120: } 1237,
{ 121: } 1254,
{ 122: } 1271,
{ 123: } 1288,
{ 124: } 1305,
{ 125: } 1322,
{ 126: } 1339,
{ 127: } 1356,
{ 128: } 1373,
{ 129: } 1390,
{ 130: } 1390,
{ 131: } 1390,
{ 132: } 1417,
{ 133: } 1432,
{ 134: } 1432,
{ 135: } 1434,
{ 136: } 1435,
{ 137: } 1435,
{ 138: } 1450,
{ 139: } 1450,
{ 140: } 1450,
{ 141: } 1450,
{ 142: } 1450,
{ 143: } 1465,
{ 144: } 1465,
{ 145: } 1491,
{ 146: } 1508,
{ 147: } 1546,
{ 148: } 1546,
{ 149: } 1546,
{ 150: } 1547,
{ 151: } 1562,
{ 152: } 1587,
{ 153: } 1603,
{ 154: } 1641,
{ 155: } 1641,
{ 156: } 1641,
{ 157: } 1656,
{ 158: } 1694,
{ 159: } 1719,
{ 160: } 1719,
{ 161: } 1734,
{ 162: } 1772
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
{ 11: } 42,
{ 12: } 42,
{ 13: } 42,
{ 14: } 42,
{ 15: } 42,
{ 16: } 42,
{ 17: } 42,
{ 18: } 42,
{ 19: } 42,
{ 20: } 49,
{ 21: } 51,
{ 22: } 51,
{ 23: } 54,
{ 24: } 55,
{ 25: } 55,
{ 26: } 55,
{ 27: } 57,
{ 28: } 58,
{ 29: } 59,
{ 30: } 59,
{ 31: } 60,
{ 32: } 62,
{ 33: } 67,
{ 34: } 67,
{ 35: } 67,
{ 36: } 67,
{ 37: } 67,
{ 38: } 67,
{ 39: } 67,
{ 40: } 67,
{ 41: } 109,
{ 42: } 109,
{ 43: } 151,
{ 44: } 151,
{ 45: } 170,
{ 46: } 171,
{ 47: } 189,
{ 48: } 189,
{ 49: } 226,
{ 50: } 226,
{ 51: } 226,
{ 52: } 241,
{ 53: } 243,
{ 54: } 273,
{ 55: } 300,
{ 56: } 300,
{ 57: } 320,
{ 58: } 320,
{ 59: } 320,
{ 60: } 321,
{ 61: } 322,
{ 62: } 322,
{ 63: } 322,
{ 64: } 349,
{ 65: } 374,
{ 66: } 375,
{ 67: } 376,
{ 68: } 401,
{ 69: } 426,
{ 70: } 451,
{ 71: } 476,
{ 72: } 477,
{ 73: } 478,
{ 74: } 504,
{ 75: } 531,
{ 76: } 531,
{ 77: } 531,
{ 78: } 558,
{ 79: } 585,
{ 80: } 612,
{ 81: } 639,
{ 82: } 666,
{ 83: } 693,
{ 84: } 693,
{ 85: } 720,
{ 86: } 747,
{ 87: } 774,
{ 88: } 801,
{ 89: } 828,
{ 90: } 855,
{ 91: } 882,
{ 92: } 909,
{ 93: } 909,
{ 94: } 910,
{ 95: } 925,
{ 96: } 926,
{ 97: } 943,
{ 98: } 968,
{ 99: } 969,
{ 100: } 986,
{ 101: } 1001,
{ 102: } 1031,
{ 103: } 1031,
{ 104: } 1031,
{ 105: } 1031,
{ 106: } 1046,
{ 107: } 1061,
{ 108: } 1076,
{ 109: } 1091,
{ 110: } 1116,
{ 111: } 1116,
{ 112: } 1118,
{ 113: } 1134,
{ 114: } 1151,
{ 115: } 1168,
{ 116: } 1185,
{ 117: } 1202,
{ 118: } 1219,
{ 119: } 1236,
{ 120: } 1253,
{ 121: } 1270,
{ 122: } 1287,
{ 123: } 1304,
{ 124: } 1321,
{ 125: } 1338,
{ 126: } 1355,
{ 127: } 1372,
{ 128: } 1389,
{ 129: } 1389,
{ 130: } 1389,
{ 131: } 1416,
{ 132: } 1431,
{ 133: } 1431,
{ 134: } 1433,
{ 135: } 1434,
{ 136: } 1434,
{ 137: } 1449,
{ 138: } 1449,
{ 139: } 1449,
{ 140: } 1449,
{ 141: } 1449,
{ 142: } 1464,
{ 143: } 1464,
{ 144: } 1490,
{ 145: } 1507,
{ 146: } 1545,
{ 147: } 1545,
{ 148: } 1545,
{ 149: } 1546,
{ 150: } 1561,
{ 151: } 1586,
{ 152: } 1602,
{ 153: } 1640,
{ 154: } 1640,
{ 155: } 1640,
{ 156: } 1655,
{ 157: } 1693,
{ 158: } 1718,
{ 159: } 1718,
{ 160: } 1733,
{ 161: } 1771,
{ 162: } 1771
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
{ 29: } 21,
{ 30: } 22,
{ 31: } 22,
{ 32: } 22,
{ 33: } 24,
{ 34: } 26,
{ 35: } 26,
{ 36: } 26,
{ 37: } 26,
{ 38: } 26,
{ 39: } 26,
{ 40: } 26,
{ 41: } 26,
{ 42: } 30,
{ 43: } 30,
{ 44: } 41,
{ 45: } 41,
{ 46: } 41,
{ 47: } 41,
{ 48: } 41,
{ 49: } 41,
{ 50: } 48,
{ 51: } 48,
{ 52: } 48,
{ 53: } 48,
{ 54: } 48,
{ 55: } 53,
{ 56: } 57,
{ 57: } 57,
{ 58: } 57,
{ 59: } 57,
{ 60: } 57,
{ 61: } 57,
{ 62: } 57,
{ 63: } 57,
{ 64: } 57,
{ 65: } 61,
{ 66: } 65,
{ 67: } 65,
{ 68: } 65,
{ 69: } 69,
{ 70: } 73,
{ 71: } 77,
{ 72: } 81,
{ 73: } 81,
{ 74: } 81,
{ 75: } 86,
{ 76: } 90,
{ 77: } 90,
{ 78: } 90,
{ 79: } 94,
{ 80: } 98,
{ 81: } 102,
{ 82: } 106,
{ 83: } 110,
{ 84: } 114,
{ 85: } 114,
{ 86: } 118,
{ 87: } 122,
{ 88: } 126,
{ 89: } 130,
{ 90: } 134,
{ 91: } 138,
{ 92: } 142,
{ 93: } 146,
{ 94: } 146,
{ 95: } 146,
{ 96: } 146,
{ 97: } 146,
{ 98: } 146,
{ 99: } 150,
{ 100: } 152,
{ 101: } 152,
{ 102: } 152,
{ 103: } 157,
{ 104: } 157,
{ 105: } 157,
{ 106: } 157,
{ 107: } 157,
{ 108: } 157,
{ 109: } 157,
{ 110: } 157,
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
{ 130: } 161,
{ 131: } 161,
{ 132: } 165,
{ 133: } 165,
{ 134: } 165,
{ 135: } 166,
{ 136: } 166,
{ 137: } 166,
{ 138: } 166,
{ 139: } 166,
{ 140: } 166,
{ 141: } 166,
{ 142: } 166,
{ 143: } 166,
{ 144: } 166,
{ 145: } 170,
{ 146: } 170,
{ 147: } 177,
{ 148: } 177,
{ 149: } 177,
{ 150: } 177,
{ 151: } 177,
{ 152: } 181,
{ 153: } 181,
{ 154: } 181,
{ 155: } 181,
{ 156: } 181,
{ 157: } 181,
{ 158: } 188,
{ 159: } 192,
{ 160: } 192,
{ 161: } 192,
{ 162: } 199
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
{ 28: } 20,
{ 29: } 21,
{ 30: } 21,
{ 31: } 21,
{ 32: } 23,
{ 33: } 25,
{ 34: } 25,
{ 35: } 25,
{ 36: } 25,
{ 37: } 25,
{ 38: } 25,
{ 39: } 25,
{ 40: } 25,
{ 41: } 29,
{ 42: } 29,
{ 43: } 40,
{ 44: } 40,
{ 45: } 40,
{ 46: } 40,
{ 47: } 40,
{ 48: } 40,
{ 49: } 47,
{ 50: } 47,
{ 51: } 47,
{ 52: } 47,
{ 53: } 47,
{ 54: } 52,
{ 55: } 56,
{ 56: } 56,
{ 57: } 56,
{ 58: } 56,
{ 59: } 56,
{ 60: } 56,
{ 61: } 56,
{ 62: } 56,
{ 63: } 56,
{ 64: } 60,
{ 65: } 64,
{ 66: } 64,
{ 67: } 64,
{ 68: } 68,
{ 69: } 72,
{ 70: } 76,
{ 71: } 80,
{ 72: } 80,
{ 73: } 80,
{ 74: } 85,
{ 75: } 89,
{ 76: } 89,
{ 77: } 89,
{ 78: } 93,
{ 79: } 97,
{ 80: } 101,
{ 81: } 105,
{ 82: } 109,
{ 83: } 113,
{ 84: } 113,
{ 85: } 117,
{ 86: } 121,
{ 87: } 125,
{ 88: } 129,
{ 89: } 133,
{ 90: } 137,
{ 91: } 141,
{ 92: } 145,
{ 93: } 145,
{ 94: } 145,
{ 95: } 145,
{ 96: } 145,
{ 97: } 145,
{ 98: } 149,
{ 99: } 151,
{ 100: } 151,
{ 101: } 151,
{ 102: } 156,
{ 103: } 156,
{ 104: } 156,
{ 105: } 156,
{ 106: } 156,
{ 107: } 156,
{ 108: } 156,
{ 109: } 156,
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
{ 129: } 160,
{ 130: } 160,
{ 131: } 164,
{ 132: } 164,
{ 133: } 164,
{ 134: } 165,
{ 135: } 165,
{ 136: } 165,
{ 137: } 165,
{ 138: } 165,
{ 139: } 165,
{ 140: } 165,
{ 141: } 165,
{ 142: } 165,
{ 143: } 165,
{ 144: } 169,
{ 145: } 169,
{ 146: } 176,
{ 147: } 176,
{ 148: } 176,
{ 149: } 176,
{ 150: } 176,
{ 151: } 180,
{ 152: } 180,
{ 153: } 180,
{ 154: } 180,
{ 155: } 180,
{ 156: } 180,
{ 157: } 187,
{ 158: } 191,
{ 159: } 191,
{ 160: } 191,
{ 161: } 198,
{ 162: } 198
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
{ 19: } ( len: 2; sym: -7 ),
{ 20: } ( len: 4; sym: -7 ),
{ 21: } ( len: 0; sym: -9 ),
{ 22: } ( len: 1; sym: -9 ),
{ 23: } ( len: 2; sym: -9 ),
{ 24: } ( len: 7; sym: -9 ),
{ 25: } ( len: 5; sym: -9 ),
{ 26: } ( len: 9; sym: -9 ),
{ 27: } ( len: 3; sym: -9 ),
{ 28: } ( len: 3; sym: -9 ),
{ 29: } ( len: 3; sym: -9 ),
{ 30: } ( len: 3; sym: -9 ),
{ 31: } ( len: 4; sym: -9 ),
{ 32: } ( len: 1; sym: -9 ),
{ 33: } ( len: 1; sym: -9 ),
{ 34: } ( len: 0; sym: -11 ),
{ 35: } ( len: 1; sym: -11 ),
{ 36: } ( len: 3; sym: -11 ),
{ 37: } ( len: 2; sym: -12 ),
{ 38: } ( len: 0; sym: -13 ),
{ 39: } ( len: 1; sym: -13 ),
{ 40: } ( len: 3; sym: -13 ),
{ 41: } ( len: 1; sym: -19 ),
{ 42: } ( len: 2; sym: -19 ),
{ 43: } ( len: 3; sym: -20 ),
{ 44: } ( len: 2; sym: -14 ),
{ 45: } ( len: 4; sym: -14 ),
{ 46: } ( len: 0; sym: -16 ),
{ 47: } ( len: 1; sym: -16 ),
{ 48: } ( len: 2; sym: -16 ),
{ 49: } ( len: 2; sym: -5 ),
{ 50: } ( len: 1; sym: -6 ),
{ 51: } ( len: 1; sym: -6 ),
{ 52: } ( len: 3; sym: -15 ),
{ 53: } ( len: 5; sym: -15 ),
{ 54: } ( len: 1; sym: -25 ),
{ 55: } ( len: 3; sym: -25 ),
{ 56: } ( len: 1; sym: -21 ),
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
{ 80: } ( len: 3; sym: -3 ),
{ 81: } ( len: 3; sym: -3 ),
{ 82: } ( len: 3; sym: -3 ),
{ 83: } ( len: 3; sym: -3 ),
{ 84: } ( len: 3; sym: -3 ),
{ 85: } ( len: 3; sym: -3 ),
{ 86: } ( len: 3; sym: -3 ),
{ 87: } ( len: 2; sym: -3 ),
{ 88: } ( len: 1; sym: -3 ),
{ 89: } ( len: 1; sym: -3 ),
{ 90: } ( len: 1; sym: -22 ),
{ 91: } ( len: 1; sym: -18 ),
{ 92: } ( len: 0; sym: -23 ),
{ 93: } ( len: 1; sym: -23 ),
{ 94: } ( len: 3; sym: -23 )
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



constructor Root.Create();
begin
	inherited Create();
	
	lineNum := yylineno;
	fname := yyfname;
end;


procedure emit(line : string);
begin
  writeln(output, line);
end;

procedure compilerError(lineNum : integer; const fname, msg : string);
begin
  writeln('error (line ', lineNum, ', file ', fname, '): ', msg);
 
  yyerrors := true;
end;

procedure compilerWarning(lineNum : integer; const fname, msg : string);
begin
  writeln('warning (line ', lineNum, ', file ', fname, '): ', msg);
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

procedure addEnvironment(id : string; typ, lbl, varTyp : integer);
var
	  e : Env_Entry;
begin
  if (lookupEnv(id) <> nil) then
    begin
    compilerError(yylineno, yyfname, 'identifier redeclared');
    exit;
    end;
       
  e := Env_Entry.Create;
  e.id := id;
  e.typ := typ;
	e.lbl := lbl;
	e.varTyp := varTyp;
	e.used := false;
	e.lineNum := yylineno;
	e.fname := yyfname;
	
	if (varTyp = VARTYPE_GLOBAL) then
	  begin
	  e.displ := globalCount;
	  inc(globalCount);
	  end
	else
	 	e.displ := 0;		

  environment.add(e);
end;

function lookupEnv(id : string; lookupCounts : boolean = false) : Env_Entry;
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
      if (lookupCounts) then
        e.used := true;
      
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

function cleanIdentifier(const id : string) : string;
begin
	Result := right(id, ':');
end;

function reportEnvEntry(e : Env_Entry) : string;
var
	typ : string;
begin
	case e.varTyp of
		VARTYPE_LOCAL: typ := 'local variable';
		VARTYPE_GLOBAL: typ := 'global variable';
		VARTYPE_PARAM: typ := 'parameter';
		VARTYPE_FUNCTION: typ := 'function';
		VARTYPE_STATIC: typ := 'static variabel';
	end;
	
	Result := typ + ' "' + cleanIdentifier(e.id) + '"';
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
    compilerError(expr.lineNum, expr.fname, 'no appropriate conversion from ''' + typeToString(src) + ''' to ''' + typeToString(dest) + '''');
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
		t1 := lookupEnv(Expr_Func(expr).id, true).typ;
		
		if (t1 = _VOID) then
		  begin
		  if (Expr_Return(expr).ret <> nil) then
		    compilerError(expr.lineNum, expr.fname, 'can not assign return value to void function');
		    
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

		t1 := lookupEnv(Expr_Call(expr).id, true).typ;
		 
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
		t1 := lookupEnv(Expr_Id(expr).id, true).typ;
   
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
      compilerError(expr.lineNum, expr.fname, 'no appropriate conversion from ''' + typeToString(t1) + ''' to ''' + typeToString(t2) + '''');

    expr.typ := _INT;
    end
  else
  if (expr is Expr_Not) then 
    begin
	  Expr_Not(expr).ex := typeExpr(Expr_Not(expr).ex);

		t1 := Expr_Not(expr).ex.typ;

    if (t1 <> _INT) then
      compilerError(expr.lineNum, expr.fname, 'impossible to negate non-integer value');

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
      compilerError(expr.lineNum, expr.fname, 'impossible to and non-integer value');

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
      compilerError(expr.lineNum, expr.fname, 'impossible to or non-integer value');

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
    if (not lookupEnv(Expr_Func(expr).id).used) then
    	begin
    	Result := nil;
    	exit;
    	end;
    	
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
		t := lookupEnv(Expr_Call(expr).id, true).lbl;

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
    e := lookupEnv(Expr_Id(expr).id, true);
    
    if (e.varTyp = VARTYPE_GLOBAL) then
      emit('PUSHR R' + IntToStr(e.displ))
    else
      emit('PUSHDISP ' + IntToStr(e.displ));
    end 
  else
  if (expr is Expr_External) then
    begin
    e := lookupEnv(Expr_External(expr).id, true);
    
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

    e := lookupEnv(Expr_Id(Expr_Assign(expr).id).id, true);

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

procedure optimizeEnvironment();
var
	e : Env_Entry;
	x : integer;
begin
	for x := 0 to environment.Count - 1 do
		begin
		e := Env_Entry(environment[x]);

		if (e.varTyp in [VARTYPE_LOCAL,VARTYPE_GLOBAL,VARTYPE_STATIC]) and (not e.used) then
			begin
			compilerWarning(e.lineNum, e.fname, reportEnvEntry(e) + ' unused');
			end;
			
		if (e.varTyp in [VARTYPE_FUNCTION]) and (e.lbl > -1) and (not e.used) then
			begin
			compilerWarning(e.lineNum, e.fname, reportEnvEntry(e) + ' unused, if incorrect add "export ' + cleanIdentifier(e.id) + '" at the end of the file');
			end;
		end;
	
	environment.Pack();
end;

procedure startCompiler(root : Expr);
var
  a : integer;
  e : Env_Entry;
begin
  root := typeExpr(root);

  optimizeEnvironment();

  if (not yyerrors) then
    root := optimizeExpr(root);
    
  if (not yyerrors) then
    begin
    emit('$DATA ' + IntToStr(globalCount));
    
    for a := 0 to environment.count - 1 do
      begin
      e := environment[a];
   
      if (e.lbl > 0) and (e.used) then
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
  includeList := TStringList.Create();
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