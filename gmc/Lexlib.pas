
{$I-}

unit LexLib;

(* Standard Lex library unit for TP Lex Version 3.0.
   2-11-91 AG *)

interface

uses
    fsys;

var

yyoutput : Text;        (* input and output file *)
yyfname : String;
yyline            : String;      (* current input line *)
yylineno, yycolno : Integer;     (* current input position *)
yytext            : String;      (* matched text (should be considered r/o) *)

function get_char : Char;
  (* obtain one character from the input file (null character at end-of-
     file) *)

procedure unget_char ( c : Char );
  (* return one character to the input file to be reread in subsequent calls
     to get_char *)

procedure put_char ( c : Char );
  (* write one character to the output file *)

procedure yyopen(fname : string);

(* Utility routines: *)

procedure echo;
  (* echoes the current match to the output stream *)

procedure yymore;
  (* append the next match to the current one *)

procedure yyless ( n : Integer );
  (* truncate yytext to size n and return the remaining characters to the
     input stream *)

procedure reject;
  (* reject the current match and execute the next one *)

  (* reject does not actually cause the input to be rescanned; instead,
     internal state information is used to find the next match. Hence
     you should not try to modify the input stream or the yytext variable
     when rejecting a match. *)

procedure return ( n : Integer );
procedure returnc ( c : Char );
  (* sets the return value of yylex *)

procedure start ( state : Integer );
  (* puts the lexical analyzer in the given start state; state=0 denotes
     the default start state, other values are user-defined *)

(* yywrap:

   The yywrap function is called by yylex at end-of-file (unless you have
   specified a rule matching end-of-file). You may redefine this routine
   in your Lex program to do application-dependent processing at end of
   file. In particular, yywrap may arrange for more input and return false
   in which case the yylex routine resumes lexical analysis. *)

function yywrap : Boolean;
  (* The default yywrap routine supplied here closes input and output files
     and returns true (causing yylex to terminate). *)

(* The following are the internal data structures and routines used by the
   lexical analyzer routine yylex; they should not be used directly. *)

var

yystate    : Integer; (* current state of lexical analyzer *)
yyactchar  : Char;    (* current character *)
yylastchar : Char;    (* last matched character (#0 if none) *)
yyrule     : Integer; (* matched rule *)
yyreject   : Boolean; (* current match rejected? *)
yydone     : Boolean; (* yylex return value set? *)
yyretval   : Integer; (* yylex return value *)

procedure yynew;
  (* starts next match; initializes state information of the lexical
     analyzer *)

procedure yyscan;
  (* gets next character from the input stream and updates yytext and
     yyactchar accordingly *)

procedure yymark ( n : Integer );
  (* marks position for rule no. n *)

procedure yymatch ( n : Integer );
  (* declares a match for rule number n *)

function yyfind ( var n : Integer ) : Boolean;
  (* finds the last match and the corresponding marked position and adjusts
     the matched string accordingly; returns:
     - true if a rule has been matched, false otherwise
     - n: the number of the matched rule *)

function yydefault : Boolean;
  (* executes the default action (copy character); returns true unless
     at end-of-file *)

procedure yyclear;
  (* reinitializes state information after lexical analysis has been
     finished *)

implementation

procedure fatal ( msg : String );
  (* writes a fatal error message and halts program *)
  begin
    writeln('LexLib: ', msg);
    halt(1);
  end(*fatal*);

(* I/O routines: *)

const nl = #10;  (* newline character *)
      max_chars = 32768;
      max_inputs = 16;
      max_matches = 1024;
      max_rules   = 256;

var
  bufptr : Integer;
  buf    : array [1..max_chars] of Char;
  iptr : Integer;
  inputStack : array[1..max_inputs] of GFileReader;

function get_char : Char;
  var i : Integer;
  begin
    if (bufptr=0) and (not inputStack[iptr].eof()) then
      begin
      yylineno := inputStack[iptr].line;
      yyline := inputStack[iptr].readLine();

      yycolno := 1;
      buf[1] := nl;
      for i := 1 to length(yyline) do
        buf[i+1] := yyline[length(yyline)-i+1];
      inc(bufptr, length(yyline)+1);
      end;

    if bufptr>0 then
      begin
        get_char := buf[bufptr];
        dec(bufptr);
        inc(yycolno);
      end
    else
      get_char := #0;
  end(*get_char*);

procedure unget_char ( c : Char );
  begin
    if bufptr=max_chars then fatal('input buffer overflow');
    inc(bufptr);
    dec(yycolno);
    buf[bufptr] := c;
  end(*unget_char*);

procedure put_char ( c : Char );
  begin
    if c=#0 then
      { ignore }
    else if c=nl then
      writeln(yyoutput)
    else
      write(yyoutput, c)
  end(*put_char*);

procedure yyopen(fname : string);
begin
  inc(iptr);

  try
    inputStack[iptr] := GFileReader.Create(fname);
  except
    writeln('Could not open ', fname);
    exit;
  end;

  yyfname := inputStack[iptr].fname;

	yylineno := 0;
end;


var
	yystext            : String;
	yysstate, yylstate : Integer;
	yymatches          : Integer;
	yystack            : array [1..max_matches] of Integer;
	yypos              : array [1..max_rules] of Integer;
	yysleng            : Byte;

(* Utilities: *)

procedure echo;
  var i : Integer;
  begin
    for i := 1 to length(yytext) do
      put_char(yytext[i])
  end(*echo*);

procedure yymore;
  begin
    yystext := yytext;
  end(*yymore*);

procedure yyless ( n : Integer );
  var i : Integer;
  begin
    for i := length(yytext) downto n+1 do
      unget_char(yytext[i]);

    setlength(yytext, n);
  end(*yyless*);

procedure reject;
  var i : Integer;
  begin
    yyreject := true;
    for i := length(yytext)+1 to yysleng do
      yytext := yytext+get_char;
    dec(yymatches);
  end(*reject*);

procedure return ( n : Integer );
  begin
    yyretval := n;
    yydone := true;
  end(*return*);

procedure returnc ( c : Char );
  begin
    yyretval := ord(c);
    yydone := true;
  end(*returnc*);

procedure start ( state : Integer );
  begin
    yysstate := state;
  end(*start*);

(* yywrap: *)

function yywrap : Boolean;
  begin
    inputStack[iptr].Free;
    dec(iptr);

    if (iptr > 0) then
      begin
      yylineno := inputStack[iptr].line;
      yywrap := false;
			bufptr := 0;
      yyfname := inputStack[iptr].fname;
      end
    else
      yywrap := true;
  end(*yywrap*);

(* Internal routines: *)

procedure yynew;
  begin
    if yylastchar<>#0 then
      if yylastchar=nl then
        yylstate := 1
      else
        yylstate := 0;
    yystate := yysstate+yylstate;
    yytext  := yystext;
    yystext := '';
    yymatches := 0;
    yydone := false;
  end(*yynew*);

procedure yyscan;
  begin
    yyactchar := get_char;
    yytext := yytext + yyactchar;
  end(*yyscan*);

procedure yymark ( n : Integer );
  begin
    if n>max_rules then fatal('too many rules');
    yypos[n] := length(yytext);
  end(*yymark*);

procedure yymatch ( n : Integer );
  begin
    inc(yymatches);
    if yymatches>max_matches then fatal('match stack overflow');
    yystack[yymatches] := n;
  end(*yymatch*);

function yyfind ( var n : Integer ) : Boolean;
  begin
    yyreject := false;
    while (yymatches>0) and (yypos[yystack[yymatches]]=0) do
      dec(yymatches);
    if yymatches>0 then
      begin
        yysleng := length(yytext);
        n       := yystack[yymatches];
        yyless(yypos[n]);
        yypos[n] := 0;

        if length(yytext) > 0 then
          yylastchar := yytext[length(yytext)]
        else
          yylastchar := #0;
        yyfind := true;
      end
    else
      begin
        yyless(0);
        yylastchar := #0;
        yyfind := false;
      end
  end(*yyfind*);

function yydefault : Boolean;
  begin
    yyreject := false;
    yyactchar := get_char;
    if yyactchar<>#0 then
      begin
        put_char(yyactchar);
        yydefault := true;
      end
    else
      begin
        yylstate := 1;
        yydefault := false;
      end;
    yylastchar := yyactchar;
  end(*yydefault*);

procedure yyclear;
  begin
    bufptr := 0;
    yysstate := 0;
    yylstate := 1;
    yylastchar := #0;
    yytext := '';
    yystext := '';
  end(*yyclear*);

begin
{  yyopen(''); }
  assign(yyoutput, '');
  rewrite(yyoutput);
  yylineno := 0;
  iptr := 0;
  yyclear;
end(*LexLib*).
