unit progs;

interface

{$M+}
type
    GMathLib = class
    published
		  function cos(x : single) : single; stdcall;
		  function sin(x : single) : single; stdcall;
    end;

    GStringLib = class
    end;
{$M-}

var
   gmlib : GMathLib;
   gslib : GStringLib;

procedure init_progs;

implementation

uses
    chars,
    dtypes,
    mudthread,
    mudsystem,
    gvm;

// GMathLib
function GMathLib.cos(x : single) : single; stdcall;
begin
  Result := System.Cos(x);
end;

function GMathLib.sin(x : single) : single; stdcall;
begin
  Result := System.Sin(x);
end;

procedure grendelVMError(owner : TObject; msg : string);
begin
  if (owner <> nil) then
    write_console('VM error in context of ' + GNPC(owner).name^ + ': ' + msg)
  else
    write_console('VM error: ' + msg);
end;

procedure grendelSystemTrap(owner : TObject; msg : string);
begin
  interpret(GNPC(owner), msg);
end;

procedure init_progs;
var
  sig : GSignature;
begin
  gmlib := GMathLib.Create;

  sig.resultType := varSingle;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[0] := varSingle;

  registerExternalMethod('cos', gmlib, gmlib.MethodAddress('cos'), sig);
  registerExternalMethod('sin', gmlib, gmlib.MethodAddress('sin'), sig);

  setVMError(grendelVMError);
  setSystemTrap(grendelSystemTrap);
end;

end.
