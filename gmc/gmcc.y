/*

	Yacc grammar (and 95% of the compiler) for GMC (Grendel MudC)

*/

%{

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


%}

%token IDENTIFIER
%token LINE
%token <Integer> INT       /* constants */
%token <Single> FLOAT      /* constants */
%type <Integer> type_specifier
%type <Expr> expr
%type <Expr> stop_statement
%type <Expr> function_definition
%type <Expr> function_body
%type <Expr> basic
%type <Expr> basic_list
%type <Expr> statement
%type <Expr> statement_list
%type <Expr> parameter_specifiers
%type <Expr> parameter_specifier
%type <Expr> parameter_list
%type <Expr> function_body
%type <Expr> compound_statement
%type <Expr> declaration
%type <Expr> declaration_list
%type <Expr> declaration_specifiers
%type <Expr> varname
%type <Expr> asm_list
%type <Expr> asm_statement
%type <ShortString> declarator
%type <ShortString> funcname
%type <ShortString> idlist
%type <BoolExpr> boolexpr

%left '|'
%left '&'
%left '+' '-'      	/* operators */
%left '*' '/' '%'
%right UMINUS

%start input

%token ILLEGAL 		/* illegal token */
%token _IF _ELSE _ASM
%token _TRUE _FALSE
%token _AND _OR
%token _RELGT _RELLT _RELGTE _RELLTE _RELEQ
%token _RETURN _BREAK _CONTINUE
%token _DO _SLEEP _WAIT _SIGNAL _WHILE _FOR _REQUIRE
%token _VOID _BOOL _INT _FLOAT _STRING _EXTERNAL

%%

input	: /* empty */
  | input '\n' { yyaccept; }
	| input basic_list	 { startCompiler($2); }
	| error '\n'       { yyerrok; }
	;

basic_list	: { $$ := nil; }
						| basic								{ $$ := $1; }
						| basic_list basic		{ $$ := Expr_Seq.Create; Expr_Seq($$).seq := $2; Expr_Seq($$).ex := $1; }
						;

statement_list	: { $$ := nil; }
	    					| statement					        	{ $$ := $1; }
			    			| statement_list statement		{ $$ := Expr_Seq.Create; Expr_Seq($$).seq := $2; Expr_Seq($$).ex := $1; }
					    	;

stop_statement  : { $$ := nil; }
								| _BREAK ';'	{ $$ := nil; }
								| _CONTINUE ';'	{ $$ := nil; }
								| _RETURN ';'	{ $$ := Expr_Return.Create; Expr_Return($$).ret := nil; Expr_Return($$).lineNum := yylineno; Expr_Return($$).id := curFunction; }
								|	_RETURN expr ';'		{ $$ := Expr_Return.Create; Expr_Return($$).ret := $2; Expr_Return($$).lineNum := yylineno; Expr_Return($$).id := curFunction; }
								| _RETURN '(' expr ')' ';'	{ $$ := Expr_Return.Create; Expr_Return($$).ret := $3; Expr_Return($$).lineNum := yylineno; Expr_Return($$).id := curFunction; }
                ;
									
basic : { $$ := nil; }
      | declaration_list { $$ := $1; }
      | _REQUIRE '"' LINE '"'														{ $$ := nil;
																											 		if (not FileExists(varName)) then
																													  compilerError(yylineno, 'could not open include file ' + varName)
																													else
																													  begin																													
																													  yyopen(varName);
																														end;	}
      ;

statement	: { $$ := nil; }
					| compound_statement															{ $$ := $1; if ($$ <> nil) then $$.lineNum := yylineno; }
					| expr ';'																				{ $$ := $1; if ($$ <> nil) then $$.lineNum := yylineno; }
  				| _IF '(' boolexpr ')' statement _ELSE statement 	{ $$ := Expr_If.Create; Expr_If($$).ce := $3;	$$.lineNum := yylineno;
																														Expr_If($$).le := $5; Expr_If($$).re := $7; 
																														Expr_If($$).lThen := labelNum; inc(labelNum); 
																														Expr_If($$).lElse := labelNum; inc(labelNum); 
																														Expr_If($$).lAfter := labelNum; inc(labelNum); }
					| _IF '(' boolexpr ')' statement									{ $$ := Expr_If.Create; Expr_If($$).ce := $3; $$.lineNum := yylineno;	
																														Expr_If($$).le := $5; Expr_If($$).re := nil; 
																														Expr_If($$).lThen := labelNum; inc(labelNum); 
																														Expr_If($$).lAfter := labelNum; inc(labelNum); }
  				| _FOR '('expr ';' boolexpr ';' expr ')' statement { $$ := Expr_Loop.Create; Expr_Loop($$).init := $3;
  				                                                    $$.lineNum := yylineno; Expr_Loop($$).ce := $5;
  				                                                    Expr_Loop($$).lStart := labelNum; inc(labelNum);
  				                                                    Expr_Loop($$).step := $7; Expr_Loop($$).body := $9; }
					| _DO expr ';'																		{ $$ := Expr_Special.Create; $$.lineNum := yylineno; Expr_Special($$).spec := SPECIAL_TRAP; $$.lineNum := yylineno; Expr_Special($$).ex := $2; }
					| _SLEEP expr ';'																	{ $$ := Expr_Special.Create; $$.lineNum := yylineno; Expr_Special($$).spec := SPECIAL_SLEEP; $$.lineNum := yylineno; Expr_Special($$).ex := $2; }
					| _WAIT expr ';'																	{ $$ := Expr_Special.Create; $$.lineNum := yylineno; Expr_Special($$).spec := SPECIAL_WAIT; $$.lineNum := yylineno; Expr_Special($$).ex := $2; }
					| _SIGNAL expr ';'																{ $$ := Expr_Special.Create; $$.lineNum := yylineno; Expr_Special($$).spec := SPECIAL_SIGNAL; $$.lineNum := yylineno; Expr_Special($$).ex := $2; }
          | _ASM '{' asm_list '}'														{ $$ := $3; }
          | stop_statement																	{ $$ := $1; }
          | ';'                                             { $$ := nil; }
					;

parameter_specifiers 	: { $$ := nil; }
											| parameter_specifier	{ $$ := $1; }
											| parameter_specifiers ',' parameter_specifier { $$ := nil; }
										 	;
 
parameter_specifier  	:	type_specifier IDENTIFIER { $$ := nil; addEnvironment(yylineno, curFunction + ':' + varName, varType, -1, VARTYPE_PARAM); }
										 	;

parameter_list 	: { $$ := nil; }
								| expr												{ $$ := $1; }
								| parameter_list ',' expr		  { $$ := Expr_Seq.Create; Expr_Seq($$).seq := $1; Expr_Seq($$).ex := $3; }
								;

asm_list : asm_statement    					{ $$ := $1; }
         | asm_list asm_statement			{ $$ := Expr_Seq.Create; Expr_Seq($$).seq := $2; Expr_Seq($$).ex := $1; }
				 ;

asm_statement : '\"' LINE '\"'        { $$ := Expr_Asm.Create; Expr_Asm($$).line := varName; }
							;

compound_statement	: '{' '}'									{  $$ := Expr_Seq.Create; Expr_Seq($$).seq := nil; Expr_Seq($$).ex := nil; }
										| '{' declaration_list statement_list '}' {  $$ := $3;  }
										;

declaration_list		: { $$ := nil; }
										| declaration { $$ := $1; }
										| declaration_list declaration  { $$ := Expr_Seq.Create; Expr_Seq($$).seq := $2; Expr_Seq($$).ex := $1; }
										;

function_definition : type_specifier IDENTIFIER { curFunction := varName;	 $$ := Expr_Func.Create; Expr_Func($$).id := curFunction;
																				Expr_Func($$).lStart := labelNum; inc(labelNum);
																				addEnvironment(yylineno, varName, varType, Expr_Func($$).lStart, VARTYPE_FUNCTION); }
										;

function_body : ';'		{ $$ := nil; }
							| compound_statement		{ $$ := $1; }
							;

declaration	: type_specifier init_declarator_list ';' { $$ := nil; }
            | function_definition '(' parameter_specifiers ')' function_body { $$ := $1; Expr_Func($$).body := $5; 
                                                                               if ($5 = nil) then updateLabel(curFunction, -1);  curFunction := ''; }
						;

init_declarator_list	: declarator
											| init_declarator_list ',' declarator
											;

declarator			: IDENTIFIER		{ varName := curFunction + ':' + varName; 
                                  $$ := varName; 
                                  if (curFunction = '') then
                                    addEnvironment(yylineno, varName, varType, -1, VARTYPE_GLOBAL)
                                  else
                                    addEnvironment(yylineno, varName, varType, -1, VARTYPE_LOCAL); }

type_specifier	: _VOID					{ varType := _VOID; $$ := _VOID; }
								| _INT					{ varType := _INT; $$ := _INT; }
								| _BOOL					{ varType := _BOOL; $$ := _BOOL; }
								| _FLOAT				{ varType := _FLOAT; $$ := _FLOAT; }
								| _STRING				{ varType := _STRING; $$ := _STRING; }
								| _EXTERNAL 		{ varType := _EXTERNAL; $$ := _EXTERNAL; }
								;

expr 	:  { $$ := nil; }
			|  expr '+' expr	 	{ $$ := Expr_Op.Create; $$.lineNum := yylineno; Expr_Op($$).op := '+'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
			|  expr '-' expr	 	{ $$ := Expr_Op.Create; $$.lineNum := yylineno; Expr_Op($$).op := '-'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
			|  expr '*' expr	 	{ $$ := Expr_Op.Create; $$.lineNum := yylineno; Expr_Op($$).op := '*'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
			|  expr '/' expr	 	{ $$ := Expr_Op.Create; $$.lineNum := yylineno; Expr_Op($$).op := '/'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
			|  expr '%' expr	 	{ $$ := Expr_Op.Create; $$.lineNum := yylineno; Expr_Op($$).op := '%'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
			|  expr '&' expr	 	{ $$ := Expr_Op.Create; $$.lineNum := yylineno; Expr_Op($$).op := '&'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
			|  expr '|' expr	 	{ $$ := Expr_Op.Create; $$.lineNum := yylineno; Expr_Op($$).op := '|'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
			|  '(' expr ')'		 	{ $$ := $2; }
			|  '-' expr        	{ $$ := Expr_Neg.Create; $$.lineNum := yylineno; Expr_Neg($$).ex := $2; }
         %prec UMINUS
			|  INT             	{ $$ := Expr_ConstInt.Create; $$.lineNum := yylineno; Expr_ConstInt($$).value := $1; }
			|  FLOAT           	{ $$ := Expr_ConstFloat.Create; $$.lineNum := yylineno; Expr_ConstFloat($$).value := $1; }
      |  '\"' '\"'		    { $$ := Expr_String.Create; $$.lineNum := yylineno; Expr_String($$).value := ''; }
      |  '\"' LINE '\"'		{ $$ := Expr_String.Create; $$.lineNum := yylineno; Expr_String($$).value := varName; }
      | '(' type_specifier ')' expr { $$ := Expr_Cast.Create; $$.lineNum := yylineno; Expr_Cast($$).ex := $4; Expr_Cast($$).desttype := $2; }
		  |  varname '=' expr { if ($1 <> nil) then
															begin
															$$ := Expr_Assign.Create; 
															Expr_Assign($$).id := $1; 
															Expr_Assign($$).ex := $3; 
															$$.lineNum := yylineno;
															end
														else
 															$$ := nil; }
		  |  varname		      { $$ := $1; }
			|  funcname '(' parameter_list ')'					{	if (lookupEnv($1) = nil) then 
																					  					begin
																											compilerError(yylineno, 'undefined function ' + $1);
																											$$ := nil;
																											yyabort;
																											end;
																										$$ := Expr_Call.Create; Expr_Call($$).id := $1; Expr_Call($$).params := $3; $$.lineNum := yyLineno; }
			| boolexpr { $$ := Expr_Bool.Create; $$.lineNum := yyLineno; Expr_Bool($$).ex := $1; }
      ;

boolexpr : _TRUE				 { $$ := BoolExpr_Const.Create; $$.lineNum := yylineno; BoolExpr_Const($$).value := True; $$.lineNum := yylineno;}
				 | _FALSE				 { $$ := BoolExpr_Const.Create; $$.lineNum := yylineno; BoolExpr_Const($$).value := False; $$.lineNum := yylineno;}
         | boolexpr _AND boolexpr	 	{ $$ := BoolExpr_And.Create; $$.lineNum := yylineno; BoolExpr_And($$).le := $1; BoolExpr_And($$).re := $3; $$.lineNum := yylineno;}
         | boolexpr _OR boolexpr	 	{ $$ := BoolExpr_Or.Create; $$.lineNum := yylineno; BoolExpr_Or($$).le := $1; BoolExpr_Or($$).re := $3; $$.lineNum := yylineno;}
         | expr _RELGT expr   { $$ := BoolExpr_Rel.Create; $$.lineNum := yylineno; BoolExpr_Rel($$).le := $1; BoolExpr_Rel($$).op := '>';  BoolExpr_Rel($$).re := $3; $$.lineNum := yylineno;}
         | expr _RELLT expr   { $$ := BoolExpr_Rel.Create; $$.lineNum := yylineno; BoolExpr_Rel($$).le := $1; BoolExpr_Rel($$).op := '<';  BoolExpr_Rel($$).re := $3; $$.lineNum := yylineno;}
         | expr _RELGTE expr   { $$ := BoolExpr_Rel.Create; $$.lineNum := yylineno; BoolExpr_Rel($$).le := $1; BoolExpr_Rel($$).op := '>=';  BoolExpr_Rel($$).re := $3; $$.lineNum := yylineno;}
         | expr _RELLTE expr   { $$ := BoolExpr_Rel.Create; $$.lineNum := yylineno; BoolExpr_Rel($$).le := $1; BoolExpr_Rel($$).op := '=<';  BoolExpr_Rel($$).re := $3; $$.lineNum := yylineno;}
         | expr _RELEQ expr   { $$ := BoolExpr_Rel.Create; $$.lineNum := yylineno; BoolExpr_Rel($$).le := $1; BoolExpr_Rel($$).op := '==';  BoolExpr_Rel($$).re := $3; $$.lineNum := yylineno;}
         | '(' boolexpr ')' 			 	{ $$ := $2; }
         ;


funcname 	: IDENTIFIER		{ $$ := varName; }
					;

varname  : idlist    	{ varGlob := ':' + $1;
                        tmp := curFunction + varGlob;
												varName := left(tmp, '.');
																							
												if (varName <> tmp) then
                          begin
													$$ := Expr_External.Create;
													$$.lineNum := yylineno; 
													Expr_External($$).id := varName;
													Expr_External($$).assoc := right(tmp, '.');
													end
												else
												if (lookupEnv(varName) <> nil) then 
													begin
													$$ := Expr_Id.Create;
													$$.lineNum := yylineno; 
													Expr_Id($$).id := varName;
													end
												else
												if (lookupEnv(varGlob) <> nil) then 
													begin
													$$ := Expr_Id.Create;
													$$.lineNum := yylineno; 
													Expr_Id($$).id := varGlob;
													end
												else
													begin
													compilerError(yylineno, 'undeclared identifier "' + right(varGlob, ':') + '"');
													$$ := nil;
													yyabort;
													end; }
         ;

idlist	:
				| IDENTIFIER	{ $$ := varName; }
				| idlist '.' IDENTIFIER { $$ := $1 + '.' + varName; }
				;

%%

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
