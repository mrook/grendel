program gvmtest;
uses gvm, Classes, TypInfo;

{$M+}
type GMath = class
     published
			 procedure blaat(a : string); stdcall;
     end;
{$M-}

procedure GMath.blaat(a : string); stdcall;
begin
  writeln('a: ', a);
end;

var
	gm : GMath;
  sig : GSignature;
  c : GContext;
  cb : GCodeBlock;
  p : integer;

begin
  sig.resultType := varNull;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[0] := varString;

  gm := GMath.Create;
  registerExternalMethod('blaat', gm, gm.MethodAddress('blaat'), sig);

  c := GContext.Create;

  cb := loadCode('test.cod');

  c.Load(cb);

  p := c.findSymbol('main');

  if (p <> -1) then
    begin
    writeln('Executing at ', p, '...');
    c.setEntryPoint(p);
    c.Execute;
    end
  else
    writeln('Could not find entrypoint.');
end.
