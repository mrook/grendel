/*

	Yacc grammar (and 95% of the compiler) for GMC (Grendel MudC)

*/

%{

uses YaccLib, LexLib, SysUtils, Classes, Strip, Windows;


const
  CONV_INT_FLOAT = 1;
  CONV_FLOAT_INT = 2;
	CONV_INT_STRING = 3;
	CONV_BOOL_STRING = 4;
	CONV_FLOAT_STRING = 5;


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
		
			Expr_Commandline = class(Expr)
			end;

      Expr_Assign = class(Expr)
        id, ex : Expr;
      end;

			Expr_Asm = class(Expr)
        line : string; 
      end;

			Expr_Func = class(Expr)
				id : string;
				init, body : Expr;
				lStart, lAfter : integer;
      end;

			Expr_Call = class(Expr)
			  id : string;
				params : Expr;
			end;

			Expr_Store = class(Expr)
				id : string;
			end;

			Expr_External = class(Expr)
				id : string;
				assoc : string;
      end;

			Expr_Trap = class(Expr)
				ex : Expr;
      end;

			Expr_Conv = class(expr)
				ex : Expr;

				cnv : integer;
				originaltyp : integer;	
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
      end;

var
	  curDispl : integer;
    labelNum : integer;
    tmp, varName : string;
		curFunction : string;
    varType : integer;
    environment : TList;
    f : textfile;


procedure startCompiler(root : Expr); forward;
procedure updateLabel(id : string; lbl : integer); forward;
procedure addEnvironment(lineNum : integer; id : string; typ, lbl : integer); forward;
function lookupEnv(id : string) : integer; forward;
procedure compilerError(lineNum : integer; msg : string); forward;


%}

%token IDENTIFIER
%token LINE
%token <Integer> INT       /* constants */
%token <Single> FLOAT      /* constants */
%type <Expr> expr
%type <Expr> stop_statement
%type <Expr> function_definition
%type <Expr> function_body
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
%token _DO _WHILE _FOR _REQUIRE
%token _VOID _BOOL _INT _FLOAT _STRING _EXTERNAL

%%

input	: /* empty */
  | input '\n' { yyaccept; }
	| input statement_list	 { startCompiler($2); }
	| error '\n'       { yyerrok; }
	;

statement_list	: { $$ := nil; }
								| statement										{ $$ := $1; }
								| statement_list statement		{ $$ := Expr_Seq.Create; Expr_Seq($$).seq := $2; Expr_Seq($$).ex := $1; }
								;

stop_statement  : { $$ := nil; }
								| _BREAK ';'	{ $$ := nil; }
								| _CONTINUE ';'	{ $$ := nil; }
								| _RETURN ';'	{ $$ := nil; }
								|	_RETURN expr ';'		{ $$ := $2; }
								| _RETURN '(' expr ')' ';'	{ $$ := $3; }
                ;

function_definition : type_specifier IDENTIFIER { curFunction := varName;	 $$ := Expr_Func.Create; Expr_Func($$).id := curFunction;
																				Expr_Func($$).lStart := labelNum; inc(labelNum);
																				Expr_Func($$).lAfter := labelNum; inc(labelNum);
																				addEnvironment(yylineno, varName, varType, Expr_Func($$).lStart); }
										;

statement	: { $$ := nil; }
					| function_definition '(' parameter_specifiers ')' function_body	{ $$ := $1; Expr_Func($$).init := $3; Expr_Func($$).body := $5; curFunction := ''; 
																																							if ($5 = nil) then updateLabel(Expr_Func($$).id, -1); }
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
					| _DO expr ';'																		{ $$ := Expr_Trap.Create; $$.lineNum := yylineno; Expr_Trap($$).ex := $2; }
          | _ASM '{' asm_list '}'														{ $$ := $3; }
          | stop_statement																	{ $$ := $1; }
          | _REQUIRE '"' LINE '"'														{ $$ := nil;
																													 		if (not FileExists(varName)) then
																															  compilerError(yylineno, 'could not open include file ' + varName)
																															else
																															  begin																													
																															  yyopen(varName);
  																															end;	}
          | ';'
					;

function_body : ';'		{ $$ := nil; }
							| compound_statement		{ $$ := $1; }
							;

parameter_specifiers 	: { $$ := nil; }
											| parameter_specifier	{ $$ := $1; }
											| parameter_specifiers ',' parameter_specifier { $$ := Expr_Seq.Create; Expr_Seq($$).seq := $3; Expr_Seq($$).ex := $1; }
										 	;

parameter_specifier  	:	type_specifier IDENTIFIER { $$ := Expr_Store.Create; Expr_Store($$).id := curFunction + ':' + varName; addEnvironment(yylineno, curFunction + ':' + varName, varType, -1); }
										 	;

parameter_list 	: { $$ := nil; }
								| expr												{ $$ := $1; }
								| parameter_list ',' expr		{ $$ := Expr_Seq.Create; Expr_Seq($$).seq := $3; Expr_Seq($$).ex := $1; }
								;

asm_list : asm_statement    					{ $$ := $1; }
         | asm_list asm_statement			{ $$ := Expr_Seq.Create; Expr_Seq($$).seq := $2; Expr_Seq($$).ex := $1; }
				 ;

asm_statement : '\"' LINE '\"'        { $$ := Expr_Asm.Create; Expr_Asm($$).line := varName; }
							;

compound_statement	: '{' '}'									{ $$ := nil; }
										| '{' declaration_list statement_list '}' {  $$ := $3;  }
										;

declaration_list		: { $$ := nil; }
										| declaration_list declaration  { $$ := nil; }
										;

declaration	: declaration_specifiers ';' { $$ := nil; }
						| declaration_specifiers init_declarator_list ';' { $$ := nil; }
						;

declaration_specifiers	: type_specifier { $$ := nil; }
												| type_specifier declaration_specifiers { $$ := nil; }
												;

init_declarator_list	: init_declarator
											| init_declarator_list ',' init_declarator
											;

init_declarator	: declarator
								| declarator '=' initializer
								;

declarator			: IDENTIFIER		{ varName := curFunction + ':' + varName; $$ := varName; addEnvironment(yylineno, varName, varType, -1); }
								;

type_specifier	: _VOID					{ varType := _VOID; }
								| _INT					{ varType := _INT; }
								| _BOOL					{ varType := _BOOL; }
								| _FLOAT				{ varType := _FLOAT; }
								| _STRING				{ varType := _STRING; }
								| _EXTERNAL 		{ varType := _EXTERNAL; }
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
      |  '\"' LINE '\"'		{ $$ := Expr_String.Create; $$.lineNum := yylineno; Expr_String($$).value := varName; }
		  |  varname '=' expr { if ($1 <> nil) then
															begin
															if ($1 is Expr_Commandline) then
																begin
																compilerError(yylineno, 'command line cannot be assigned to');
																$$ := nil;
																yyabort;
																end;

															$$ := Expr_Assign.Create; 
															Expr_Assign($$).id := $1; 
															Expr_Assign($$).ex := $3; 
															$$.lineNum := yylineno;
															end
														else
 															$$ := nil; }
		  |  varname		      { $$ := $1; }
			|  funcname '(' parameter_list ')'					{	if (lookupEnv(varName) = -1) then 
																					  					begin
																											compilerError(yylineno, 'undefined function ' + varName);
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

varname  : idlist    	{ tmp := curFunction + ':' + $1;

												varName := left(tmp, '.');
														
												if (varName = ':str0') then
													begin
													$$ := Expr_Commandline.Create;
													$$.lineNum := yylineno; 
													end
												else
												if (lookupEnv(varName) = -1) then 
													begin
													compilerError(yylineno, 'undeclared identifier ' + varName);
													$$ := nil;
													yyabort;
													end
												else
												if (varName <> tmp) then
                          begin
													$$ := Expr_External.Create;
													$$.lineNum := yylineno; 
													Expr_External($$).id := varName;
													Expr_External($$).assoc := right(tmp, '.');
													end
												else
													begin
													$$ := Expr_Id.Create;
													$$.lineNum := yylineno; 
													Expr_Id($$).id := varName;
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

procedure showExpr(expr : Expr); forward;
procedure showBoolExpr(expr : BoolExpr); forward;

function typeToString(typ : integer) : string; forward;


procedure emit(line : string);
begin
  writeln(output, line);
end;

procedure compilerError(lineNum : integer; msg : string);
begin
  writeln('error (line ', lineNum, '): ', msg);
 
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

procedure addEnvironment(lineNum : integer; id : string; typ, lbl : integer);
var
	  e : Env_Entry;
begin
  if (lookupEnv(id) <> -1) then
    begin
    compilerError(lineNum, 'identifier redeclared');
    exit;
    end;

  e := Env_Entry.Create;
  e.id := id;
  e.typ := typ;
	e.lbl := lbl;
 
  if (lbl = -1) then
    begin
	  e.displ := curDispl;
  	inc(curDispl);
		end
	else
		e.displ := -1;

  environment.add(e);
end;

function lookupEnv(id : string) : integer;
var
		a : integer;
    e : Env_Entry;
begin
  Result := -1;
 
  for a := 0 to environment.count - 1 do
    begin
    e := environment[a];
   
    if (e.id = id) then
      begin
      Result := e.typ;
      break; 
      end;
    end;
end;

function findDispl(id : string) : integer;
var
		a : integer;
    e : Env_Entry;
begin
  Result := 0;
 
  for a := 0 to environment.count - 1 do
    begin
    e := environment[a];
   
    if (e.id = id) then
      begin
      Result := e.displ;
      break; 
      end;
    end;
end;

function findLabel(id : string) : integer;
var
		a : integer;
    e : Env_Entry;
begin
  Result := 0;
 
  for a := 0 to environment.count - 1 do
    begin
    e := environment[a];
   
    if (e.id = id) then
      begin
      Result := e.lbl;
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
   
    else Result := 'unknown';
  end;
end;

function coerce(expr : Expr; src, dest: integer) : Expr;
var
	cn : Expr_Conv;
begin
  if (src = _INT) and (dest = _FLOAT) then
    begin
    cn := Expr_Conv.Create;
		cn.ex := expr;
		cn.cnv := CONV_INT_FLOAT;
		cn.originaltyp := src;

		Result := cn;
    end
  else
  if (src = _FLOAT) and (dest = _INT) then
    begin
    cn := Expr_Conv.Create;
		cn.ex := expr;
		cn.cnv := CONV_FLOAT_INT;
		cn.originaltyp := src;

		Result := cn;
    end
  else
  if (src = _INT) and (dest = _STRING) then
    begin
    cn := Expr_Conv.Create;
		cn.ex := expr;
		cn.cnv := CONV_INT_STRING;
		cn.originaltyp := src;

		Result := cn;
    end
  else
  if (src = _BOOL) and (dest = _STRING) then
    begin
    cn := Expr_Conv.Create;
		cn.ex := expr;
		cn.cnv := CONV_BOOL_STRING;
		cn.originaltyp := src;

		Result := cn;
    end
  else
  if (src = _FLOAT) and (dest = _STRING) then
    begin
    cn := Expr_Conv.Create;
		cn.ex := expr;
		cn.cnv := CONV_FLOAT_STRING;
		cn.originaltyp := src;

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
    Expr_Func(expr).init := typeExpr(Expr_Func(expr).init);
    Expr_Func(expr).body := typeExpr(Expr_Func(expr).body);

		t1 := lookupEnv(Expr_Func(expr).id);
   
    if (t1 <> -1) then
	    expr.typ := t1
    else
	    expr.typ := _VOID;
		end
  else
  if (expr is Expr_Call) then
    begin
		t1 := lookupEnv(Expr_Call(expr).id);
   
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
  if (expr is Expr_Commandline) then
    expr.typ := _STRING
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
		t1 := lookupEnv(Expr_Id(expr).id);
   
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
  if (expr is Expr_Trap) then
    begin
    Expr_Trap(expr).ex := typeExpr(Expr_Trap(expr).ex);

		expr.typ := Expr_Trap(expr).ex.typ;
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
begin
  if (expr = nil) then
    exit;

  if (expr is Expr_Op) then
    begin
    showExpr(Expr_Op(expr).re);
    showExpr(Expr_Op(expr).le);

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
  if (expr is Expr_Commandline) then
    emit('GETC')
  else
  if (expr is Expr_String) then
    emit('PUSHS ' + Expr_String(expr).value)
  else
  if (expr is Expr_If) then
    begin
    showBoolExpr(Expr_If(expr).ce); 

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
			emit('JMP L' + IntToStr(Expr_Func(expr).lAfter));
	    emit('L' + IntToStr(Expr_Func(expr).lStart) + ':');

			showExpr(Expr_Func(expr).init);
			showExpr(Expr_Func(expr).body);

			emit('RET');
	    emit('L' + IntToStr(Expr_Func(expr).lAfter) + ':');
	    end;
    end
  else
  if (expr is Expr_Call) then
    begin
		t := findLabel(Expr_Call(expr).id);

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
  if (expr is Expr_Store) then
    begin
    emit('POPR R' + IntToStr(findDispl(Expr_Store(expr).id)));
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
    emit('PUSHR R' + IntToStr(findDispl(Expr_Id(expr).id)));
    end 
  else
  if (expr is Expr_External) then
    begin
    emit('PUSHR R' + IntToStr(findDispl(Expr_External(expr).id)));
		emit('PUSHS ' + Expr_External(expr).assoc);
    emit('GET');
    end
  else
  if (expr is Expr_Assign) then
    begin
    showExpr(Expr_Assign(expr).ex);

		if (lookupEnv(Expr_Id(Expr_Assign(expr).id).id) = _EXTERNAL) then
      emit('GETR R' + IntToStr(findDispl(Expr_Id(Expr_Assign(expr).id).id)))
    else
      emit('POPR R' + IntToStr(findDispl(Expr_Id(Expr_Assign(expr).id).id)));
    end
  else
  if (expr is Expr_Asm) then
    begin
    emit(Expr_Asm(expr).line);
    end
  else
  if (expr is Expr_Trap) then
    begin
    showExpr(Expr_Trap(expr).ex);
    emit('TRAP');
    end
	else
  if (expr is Expr_Conv) then
    begin
    showExpr(Expr_Conv(expr).ex);

		case Expr_Conv(expr).cnv of
			CONV_INT_FLOAT : emit('ITOF');
			CONV_FLOAT_INT : emit('FTOI');
			CONV_INT_STRING : emit('ITOS');
			CONV_BOOL_STRING : emit('BTOS');
			CONV_FLOAT_STRING : emit('FTOS');
    end;
    end;
end;

procedure startCompiler(root : Expr);
begin
  root := typeExpr(root);

  if (not yyerrors) then
    begin
	  emit('$DATA ' + IntToStr(curDispl) + #13#10);
    showExpr(root); 
		emit('HALT');
	  writeln('Output file written, data size is ', curDispl, ' elements.');
		end;
end;

var
	ifname : string; 
  ofname : string;
  SI : TStartupInfo;
  PI : TProcessInformation;
  ex : DWORD;

begin
  DecimalSeparator := '.';
  writeln('GMCC - Grendel MudC compiler v0.2'#13#10);

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
  curDispl := 0;
  labelNum := 1;
  yylineno := 1;

  start(INITIAL);

  if yyparse=0 then { done; };

  closefile(output);

  if (not yyerrors) then
    begin
	  FillChar(SI, SizeOf(SI), 0);
	  SI.cb := SizeOf(SI);

	  CreateProcess(nil, PChar('gasm ' + ofname), nil, nil, false, NORMAL_PRIORITY_CLASS, nil, nil, SI, PI);

	  repeat
	    GetExitCodeProcess(PI.hProcess, ex);
	  until (ex <> STILL_ACTIVE);
    end;
end.
