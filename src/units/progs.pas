{
  Summary:
  	Interface with GMC virtual machine
  	
	## $Id: progs.pas,v 1.7 2004/03/19 20:55:34 ***REMOVED*** Exp $
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
    published
      function left(const src, delim : string) : string; stdcall;
      function right(const src, delim : string) : string; stdcall;
      function match(const src, pattern : string) : boolean; stdcall;
      function IntToStr(x : integer) : string; stdcall;
      function StrToInt(const x : string) : integer; stdcall;
      function uppercase(const s : string) : string; stdcall;
    end;
    
    GGrendelLib = class
    published
    	function is_npc(target : integer) : boolean; stdcall;
    end;
{$M-}


procedure initProgs();


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
    

var
   gmlib : GMathLib;
   gslib : GStringLib;
   gglib : GGrendelLib;


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

// GGrendelLib
function GGrendelLib.is_npc(target : integer) : boolean; stdcall;
begin
	Result := GCharacter(target).IS_NPC;
end;

procedure grendelVMError(owner : TObject; const msg : string);
begin
  if (owner <> nil) then
    writeConsole('VM error in context of ' + GNPC(owner).name + ' (#' + IntToStr(GNPC(owner).npc_index.vnum) + '): ' + msg)
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
      end
		else
			writeConsole('VM error: unknown field "' + member + '"');
    end;
end;

procedure grendelSystemTrap(owner : TObject; const msg : string);
begin
  interpret(GNPC(owner), msg);
end;

procedure initProgs();
begin
  gmlib := GMathLib.Create();
  gslib := GStringLib.Create();
  gglib := GGrendelLib.Create();
   
  registerExternalMethod('cos', gmlib, varSingle, [varSingle]);
  registerExternalMethod('sin', gmlib, varSingle, [varSingle]);
  registerExternalMethod('tan', gmlib, varSingle, [varSingle]);
  registerExternalMethod('random', gmlib, varInteger, [varInteger]);

  registerExternalMethod('StrToInt', gslib, varInteger, [varString]);

  registerExternalMethod('left', gslib, varString, [varString, varString]);
  registerExternalMethod('right', gslib, varString, [varString, varString]);

  registerExternalMethod('match', gslib, varBoolean, [varString, varString]);

  registerExternalMethod('IntToStr', gslib, varString, [varInteger]);

  registerExternalMethod('uppercase', gslib, varString, [varString]);

	registerExternalMethod('is_npc', gglib, varBoolean, [varInteger]);

  setVMError(grendelVMError);
  setSystemTrap(grendelSystemTrap);
  setExternalTrap(grendelExternalTrap);
end;


end.
