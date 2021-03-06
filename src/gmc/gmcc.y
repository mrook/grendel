/*

	Yacc grammar (and 95% of the compiler) for GMC (Grendel MudC)

*/

%{

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

%left '|'
%left '&'
%left '+' '-'      	/* operators */
%left '*' '/' '%'
%right UMINUS

%start input

%token ILLEGAL 		/* illegal token */
%token _IF _ELSE _ASM
%token _TRUE _FALSE
%token _AND _OR _NOT
%token _RELGT _RELLT _RELGTE _RELLTE _RELEQ
%token _RETURN _BREAK _CONTINUE
%token _DO _SLEEP _WAIT _SIGNAL _WHILE _FOR _REQUIRE _EXPORT
%token _VOID _INT _FLOAT _STRING _EXTERNAL

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
				| _RETURN ';'	{ $$ := Expr_Return.Create; Expr_Return($$).ret := nil; Expr_Return($$).id := curFunction; }
				|	_RETURN expr ';'		{ $$ := Expr_Return.Create; Expr_Return($$).ret := $2; Expr_Return($$).id := curFunction; }
				| _RETURN '(' expr ')' ';'	{ $$ := Expr_Return.Create; Expr_Return($$).ret := $3; Expr_Return($$).id := curFunction; }
                ;
									
basic 	: { $$ := nil; }
      	| declaration_list { $$ := $1; }
      	| _EXPORT IDENTIFIER { $$ := nil; lookupEnv(varName, true); }
		| _REQUIRE '"' LINE '"'			{ 	$$ := nil;
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
												end;	}
		;

statement	: { $$ := nil; }
			| compound_statement															{ $$ := $1; if ($$ <> nil) then $$.lineNum := yylineno; }
			| expr ';'																				{ $$ := $1; if ($$ <> nil) then $$.lineNum := yylineno; }
			| _IF '(' expr ')' statement _ELSE statement 	{ $$ := Expr_If.Create; Expr_If($$).ce := $3;	
																														Expr_If($$).le := $5; Expr_If($$).re := $7; 
																														Expr_If($$).lThen := labelNum; inc(labelNum); 
																														Expr_If($$).lElse := labelNum; inc(labelNum); 
																														Expr_If($$).lAfter := labelNum; inc(labelNum); }
			| _IF '(' expr ')' statement									{ $$ := Expr_If.Create; Expr_If($$).ce := $3; 
																														Expr_If($$).le := $5; Expr_If($$).re := nil; 
																														Expr_If($$).lThen := labelNum; inc(labelNum); 
																														Expr_If($$).lAfter := labelNum; inc(labelNum); }
  			| _FOR '('expr ';' expr ';' expr ')' statement { $$ := Expr_Loop.Create; Expr_Loop($$).init := $3;
  				                                                    Expr_Loop($$).ce := $5;
  				                                                    Expr_Loop($$).lStart := labelNum; inc(labelNum);
  				                                                    Expr_Loop($$).step := $7; Expr_Loop($$).body := $9; }
			| _DO expr ';'																		{ $$ := Expr_Special.Create; Expr_Special($$).spec := SPECIAL_TRAP; Expr_Special($$).ex := $2; }
			| _SLEEP expr ';'																	{ $$ := Expr_Special.Create; Expr_Special($$).spec := SPECIAL_SLEEP; Expr_Special($$).ex := $2; }
			| _WAIT expr ';'																	{ $$ := Expr_Special.Create; Expr_Special($$).spec := SPECIAL_WAIT; Expr_Special($$).ex := $2; }
			| _SIGNAL expr ';'																{ $$ := Expr_Special.Create; Expr_Special($$).spec := SPECIAL_SIGNAL; Expr_Special($$).ex := $2; }
			| _ASM '{' asm_list '}'														{ $$ := $3; }
			| stop_statement																	{ $$ := $1; }
			| ';'                                             { $$ := nil; }
					;

parameter_specifiers 	: { $$ := nil; }
						| parameter_specifier	{ $$ := $1; }
						| parameter_specifiers ',' parameter_specifier { $$ := nil; }
						;
 
parameter_specifier  	:	type_specifier IDENTIFIER { $$ := nil; addEnvironment(curFunction + ':' + varName, varType, -1, VARTYPE_PARAM); }
						;

parameter_list 	: { $$ := nil; }
				| expr												{ $$ := $1; }
				| parameter_list ',' expr		  { $$ := Expr_Seq.Create; Expr_Seq($$).seq := $1; Expr_Seq($$).ex := $3; }
				;

asm_list : asm_statement    					{ $$ := $1; }
         | asm_list asm_statement			{ $$ := Expr_Seq.Create; Expr_Seq($$).seq := $2; Expr_Seq($$).ex := $1; }
		 ;

asm_statement 	: '\"' LINE '\"'        { $$ := Expr_Asm.Create; Expr_Asm($$).line := varName; }
				;

compound_statement	: '{' '}'									{  $$ := Expr_Seq.Create; Expr_Seq($$).seq := nil; Expr_Seq($$).ex := nil; }
					| '{' declaration_list statement_list '}' {  $$ := $3;  }
					;

declaration_list	: { $$ := nil; }
					| declaration { $$ := $1; }
					| declaration_list declaration  { $$ := Expr_Seq.Create; Expr_Seq($$).seq := $2; Expr_Seq($$).ex := $1; }
					;

function_definition : type_specifier IDENTIFIER { curFunction := varName;	 $$ := Expr_Func.Create; Expr_Func($$).id := curFunction;
																				Expr_Func($$).lStart := labelNum; inc(labelNum);
																				addEnvironment(varName, varType, Expr_Func($$).lStart, VARTYPE_FUNCTION); }
					;

function_body 	: ';'		{ $$ := nil; }
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
                                    addEnvironment(varName, varType, -1, VARTYPE_GLOBAL)
                                  else
                                    addEnvironment(varName, varType, -1, VARTYPE_LOCAL); }

type_specifier	: _VOID					{ varType := _VOID; $$ := _VOID; }
				| _INT					{ varType := _INT; $$ := _INT; }
				| _FLOAT				{ varType := _FLOAT; $$ := _FLOAT; }
				| _STRING				{ varType := _STRING; $$ := _STRING; }
				| _EXTERNAL 		{ varType := _EXTERNAL; $$ := _EXTERNAL; }
				;

expr 	:  { $$ := nil; }
		|  expr '+' expr	 	{ $$ := Expr_Op.Create; Expr_Op($$).op := '+'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
		|  expr '-' expr	 	{ $$ := Expr_Op.Create; Expr_Op($$).op := '-'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
		|  expr '*' expr	 	{ $$ := Expr_Op.Create; Expr_Op($$).op := '*'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
		|  expr '/' expr	 	{ $$ := Expr_Op.Create; Expr_Op($$).op := '/'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
		|  expr '%' expr	 	{ $$ := Expr_Op.Create; Expr_Op($$).op := '%'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
		|  expr '&' expr	 	{ $$ := Expr_Op.Create; Expr_Op($$).op := '&'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
		|  expr '|' expr	 	{ $$ := Expr_Op.Create; Expr_Op($$).op := '|'; Expr_Op($$).le := $1; Expr_Op($$).re := $3; }
		|  '(' expr ')'		 	{ $$ := $2; }
		|  '-' expr        	{ $$ := Expr_Neg.Create; Expr_Neg($$).ex := $2; }
		%prec UMINUS
		|  INT             	{ $$ := Expr_ConstInt.Create; Expr_ConstInt($$).value := $1; }
		|  FLOAT           	{ $$ := Expr_ConstFloat.Create; Expr_ConstFloat($$).value := $1; }
		|  '\"' '\"'		    { $$ := Expr_String.Create; Expr_String($$).value := ''; }
		|  '\"' LINE '\"'		{ $$ := Expr_String.Create; Expr_String($$).value := varName; }
		| '(' type_specifier ')' expr { $$ := Expr_Cast.Create; Expr_Cast($$).ex := $4; Expr_Cast($$).desttype := $2; }
		|  varname '=' expr { if ($1 <> nil) then
								begin
								$$ := Expr_Assign.Create; 
								Expr_Assign($$).id := $1; 
								Expr_Assign($$).ex := $3; 
								end
							else
								$$ := nil; }
		|  varname		      { $$ := $1; }
		|  funcname '(' parameter_list ')'					{	if (lookupEnv($1) = nil) then 
																	begin
																		compilerError(yylineno, yyfname, 'undefined function "' + $1 + '"');
																		$$ := nil;
																		yyabort;
																		end;
																	$$ := Expr_Call.Create; Expr_Call($$).id := $1; Expr_Call($$).params := $3; }
		| expr _RELGT expr   { $$ := Expr_Rel.Create; Expr_Rel($$).le := $1; Expr_Rel($$).op := '>';  Expr_Rel($$).re := $3; }
		| expr _RELLT expr   { $$ := Expr_Rel.Create; Expr_Rel($$).le := $1; Expr_Rel($$).op := '<';  Expr_Rel($$).re := $3; }
		| expr _RELGTE expr  { $$ := Expr_Rel.Create; Expr_Rel($$).le := $1; Expr_Rel($$).op := '>=';  Expr_Rel($$).re := $3; }
		| expr _RELLTE expr  { $$ := Expr_Rel.Create; Expr_Rel($$).le := $1; Expr_Rel($$).op := '=<';  Expr_Rel($$).re := $3; }
		| expr _RELEQ expr   { $$ := Expr_Rel.Create; Expr_Rel($$).le := $1; Expr_Rel($$).op := '==';  Expr_Rel($$).re := $3; }
		| expr _AND expr	   { $$ := Expr_And.Create; Expr_And($$).le := $1; Expr_And($$).re := $3; $$.lineNum := yylineno;}
		| expr _OR expr	 	   { $$ := Expr_Or.Create; Expr_Or($$).le := $1; Expr_Or($$).re := $3; $$.lineNum := yylineno;}
		| _NOT expr          { $$ := Expr_Not.Create; Expr_Not($$).ex := $2; };
		| _TRUE			      	 { $$ := Expr_ConstInt.Create; Expr_ConstInt($$).value := 1; }
		| _FALSE				     { $$ := Expr_ConstInt.Create; Expr_ConstInt($$).value := 0; }
		;

funcname 	: IDENTIFIER		{ $$ := varName; }
			;

varname  : idlist    	{ varGlob := ':' + $1;
                        tmp := curFunction + varGlob;
                        varGlob := left(varGlob, '.');
												varName := left(tmp, '.');
																																		
												if (varName <> tmp) then
                          begin
                          if (lookupEnv(varName) <> nil) then
                            begin
  													$$ := Expr_External.Create;
  													Expr_External($$).id := varName;
  													Expr_External($$).assoc := right(tmp, '.');
  													end
  												else
  												  begin
  													compilerError(yylineno, yyfname, 'undeclared identifier "' + right(varGlob, ':') + '"');
  													$$ := nil;
	  												yyabort;
	  												end;
													end
												else
												if (lookupEnv(varName) <> nil) then 
													begin
													$$ := Expr_Id.Create;
													Expr_Id($$).id := varName;
													end
												else
												if (lookupEnv(varGlob) <> nil) then 
													begin
													$$ := Expr_Id.Create;
													Expr_Id($$).id := varGlob;
													end
												else
													begin
													compilerError(yylineno, yyfname, 'undeclared identifier "' + right(varGlob, ':') + '"');
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
