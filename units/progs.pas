unit progs;

interface

{$M+}
type
    GMathLib = class
    published
		  function cos(x : single) : single; stdcall;
		  function sin(x : single) : single; stdcall;
		  function tan(x : single) : single; stdcall;
    end;

    GStringLib = class
      function left(src, delim : string) : string; stdcall;
      function right(src, delim : string) : string; stdcall;
    end;
{$M-}

var
   gmlib : GMathLib;
   gslib : GStringLib;

procedure init_progs;

implementation

uses
    Math,
    Strip,
    TypInfo,
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

function GMathLib.tan(x : single) : single; stdcall;
begin
  Result := Math.Tan(x);
end;

// GStringLib
function GStringLib.left(src, delim : string) : string; stdcall;
begin
  Result := Strip.left(src, delim[1]);
end;

function GStringLib.right(src, delim : string) : string; stdcall;
begin
  Result := Strip.right(src, delim[1]);
end;

procedure grendelVMError(owner : TObject; msg : string);
begin
  if (owner <> nil) then
    write_console('VM error in context of ' + GNPC(owner).name^ + ': ' + msg)
  else
    write_console('VM error: ' + msg);
end;

function grendelExternalTrap(obj : variant; member : string) : variant;
var
  s : TObject;
  prop : PPropInfo;
  v : variant;
begin
  Result := Null;

  if (varType(obj) = varString) then
    begin
    Result := integer(findCharWorld(nil, obj));
    end
  else
  if (varType(obj) = varInteger) then
    begin
    s := TObject(integer(obj));

    prop := GetPropInfo(s.ClassInfo(), member);

    if (prop <> nil) then
      case (prop.PropType^.Kind) of
        tkInteger: Result := GetOrdProp(s, prop);
        tkFloat:   Result := GetFloatProp(s, prop);
        tkString:  Result := GetStrProp(s, prop);
        tkVariant: Result := GetVariantProp(s, prop);
      end;
    end;
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
  gslib := GStringLib.Create;

  sig.resultType := varSingle;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[0] := varSingle;

  registerExternalMethod('cos', gmlib, gmlib.MethodAddress('cos'), sig);
  registerExternalMethod('sin', gmlib, gmlib.MethodAddress('sin'), sig);
  registerExternalMethod('tan', gmlib, gmlib.MethodAddress('tan'), sig);

  sig.resultType := varString;
  setLength(sig.paramTypes, 2);
  sig.paramTypes[0] := varString;
  sig.paramTypes[1] := varString;

  registerExternalMethod('left', gslib, gslib.MethodAddress('left'), sig);
  registerExternalMethod('right', gslib, gslib.MethodAddress('right'), sig);

  setVMError(grendelVMError);
  setSystemTrap(grendelSystemTrap);
  setExternalTrap(grendelExternalTrap);
end;

end.
