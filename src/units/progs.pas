{
  Summary:
  	Interface with GMC virtual machine
  	
	## $Id: progs.pas,v 1.4 2004/02/28 15:53:24 hemko Exp $
}

unit progs;

interface

{$M+}
type
    GMathLib = class
    published
		  function cos(x : single) : single; stdcall;
		  function sin(x : single) : single; stdcall;
		  function tan(x : single) : single; stdcall;
      function random(x : integer) : integer; stdcall;
    end;

    GStringLib = class
      function left(const src, delim : string) : string; stdcall;
      function right(const src, delim : string) : string; stdcall;
      function match(const src, pattern : string) : boolean; stdcall;
      function IntToStr(x : integer) : string; stdcall;
      function StrToInt(const x : string) : integer; stdcall;
      function uppercase(const s : string) : string; stdcall;
    end;
{$M-}

var
   gmlib : GMathLib;
   gslib : GStringLib;

procedure init_progs;

implementation

uses
    Variants,
    Math,
    Strip,
    SysUtils,
    TypInfo,
    chars,
    console,
    dtypes,
    util,
    commands,
    mudsystem,
    gvm,
    FastStringFuncs;
    

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

function GMathLib.random(x : integer) : integer; stdcall;
begin
  Result := System.Random(x);
end;

// GStringLib
function GStringLib.left(const src, delim : string) : string; stdcall;
begin
  Result := Strip.left(src, delim[1]);
end;

function GStringLib.right(const src, delim : string) : string; stdcall;
begin
  Result := Strip.right(src, delim[1]);
end;

function GStringLib.match(const src, pattern : string) : boolean; stdcall;
begin
  Result := StringMatches(src, pattern);
end;

function GStringLib.IntToStr(x : integer) : string; stdcall;
begin
  Result := Sysutils.IntToStr(x);
end;

function GStringLib.StrToInt(const x : string) : integer; stdcall;
begin
  Result := Sysutils.StrToInt(x);
end;

function GStringLib.uppercase(const s : string) : string; stdcall;
begin
  Result := Sysutils.Uppercase(s);
end;

procedure grendelVMError(owner : TObject; const msg : string);
begin
  if (owner <> nil) then
    writeConsole('VM error in context of ' + GNPC(owner).name + ': ' + msg)
  else
    writeConsole('VM error: ' + msg);
end;

function grendelExternalTrap(obj : variant; const member : string) : variant;
var
  s : TObject;
  prop : PPropInfo;
begin
  Result := 0;

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
        tkLString:  Result := GetStrProp(s, prop);
        tkVariant: Result := GetVariantProp(s, prop);
      end;
    end;
end;

procedure grendelSystemTrap(owner : TObject; const msg : string);
begin
  interpret(GNPC(owner), msg);
end;

procedure init_progs;
var
  sig : GSignature;
begin
  gmlib := GMathLib.Create();
  gslib := GStringLib.Create();

  sig.resultType := varSingle;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[0] := varSingle;

  registerExternalMethod('cos', gmlib, gmlib.MethodAddress('cos'), sig);
  registerExternalMethod('sin', gmlib, gmlib.MethodAddress('sin'), sig);
  registerExternalMethod('tan', gmlib, gmlib.MethodAddress('tan'), sig);

  sig.resultType := varInteger;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[0] := varInteger;

  registerExternalMethod('random', gmlib, gmlib.MethodAddress('random'), sig);

  sig.resultType := varInteger;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[0] := varString;

  registerExternalMethod('StrToInt', gslib, gslib.MethodAddress('StrToInt'), sig);

  sig.resultType := varString;
  setLength(sig.paramTypes, 2);
  sig.paramTypes[0] := varString;
  sig.paramTypes[1] := varString;

  registerExternalMethod('left', gslib, gslib.MethodAddress('left'), sig);
  registerExternalMethod('right', gslib, gslib.MethodAddress('right'), sig);

  sig.resultType := varBoolean;
  setLength(sig.paramTypes, 2);
  sig.paramTypes[0] := varString;
  sig.paramTypes[1] := varString;

  registerExternalMethod('match', gslib, gslib.MethodAddress('match'), sig);

  sig.resultType := varString;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[0] := varInteger;
  
  registerExternalMethod('IntToStr', gslib, gslib.MethodAddress('IntToStr'), sig);

  sig.resultType := varString;
  setLength(sig.paramTypes, 1);
  sig.paramTypes[0] := varString;
  
  registerExternalMethod('uppercase', gslib, gslib.MethodAddress('uppercase'), sig);

  setVMError(grendelVMError);
  setSystemTrap(grendelSystemTrap);
  setExternalTrap(grendelExternalTrap);
end;

end.
