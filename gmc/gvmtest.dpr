uses gvm, Classes, TypInfo;

{$M+}
type GMath = class
     published
			 function cos(x : single) : single; stdcall;
     end;
{$M-}

function GMath.cos(x : single) : single; stdcall;
begin
  Result := System.Cos(x);
end;

var
	gm : GMath;
  sig : GSignature;
  c : GContext;
  cb : GCodeBlock;

begin
  sig.resultType := varSingle;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[1] := varSingle;

  gm := GMath.Create;
  registerExternalMethod('cos', gm, gm.MethodAddress('cos'), sig);

  c := GContext.Create;

  cb := loadCode('test.cod');

  c.Load(cb);

  c.Execute;
end.
