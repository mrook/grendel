unit strip;

interface
uses Sysutils;

function stripl(s:string;f:char):string;  // returns everything from string s before char f

function striplend(s:string; f:char):string;

function stripr(s:string;f:char):string;

function StripRbeg(s:string;what:char):string;

function CharsInStr(s:string;what:char):integer;

implementation

function stripl(s:string;f:char):string;  // returns everything from string s before char f
var i:integer;
    g:string;
begin
  i:=pos(f,s);
  if i>0 then
    begin
    g:=s;
    delete(g,i,length(g)-i+1);
    stripl:=g;
    end
  else
    stripl:=s;
end;

function striplend(s:string;f:char):string;
var i:integer;
    g:string;
begin
  i := LastDelimiter(f, s);
  if (i > 0) then
    begin
    g:=s;
    delete(g,i,length(g)-i+1);
    striplend:=g;
    end
  else
    striplend:=s;
end;

function stripr(s:string;f:char):string;
var i:integer;
    g:string;
begin
  i:=pos(f,s);
  if i>0 then
    begin
    g:=s;
    delete(g,1,i);
    stripr:=g;
    end
  else
    stripr:=s;
end;

function StripRbeg;
var a:word;
begin
  a:=pos(what,s);
  if a=0 then
    begin
    striprbeg:=s;
    exit;
    end;
  delete(s,1,a);
  striprbeg:=s;
end;

function CharsInStr;
var a,b:integer;
begin
  b:=0;
  for a:=1 to length(s) do
   if s[a]=what then inc(b,1);
  CharsInStr:=b;
end;

end.
