unit modules;

interface

uses 
{$IFDEF WIN32}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Libc,
{$ENDIF}
  SysUtils,
  constants,
  dtypes;


type 
  GModule = class
    handle : HMODULE;
    fname : string;
    desc : string;
  end;

procedure loadModules();
procedure addModule(name : string);
procedure removeModule(name : string);

var
  module_list : GHashTable;

implementation

uses
  mudsystem;

procedure loadModules();
var 
  t : TSearchRec;
begin
{$IFDEF LINUX}
   if (FindFirst('modules' + PathDelimiter + 'bpl*.so', faAnyFile, t) = 0) then
{$ELSE}
   if (FindFirst('modules' + PathDelimiter + '*.bpl', faAnyFile, t) = 0) then
{$ENDIF}
    repeat     
      try
        addModule(t.name);
      except
        on E : GException do
          bugreport('loadModules()', 'modules.pas', 'Unable to load module ' + t.name + ': ' + E.Message);
      end;
    until (FindNext(t) <> 0);

  FindClose(t);
end;

procedure addModule(name : string);
var
  hndl : HMODULE;
  module : GModule;
begin
  try
    if (module_list.get(name) <> nil) then
      raise GException.Create('modules.pas:addModule()','Module already loaded');
      
    hndl := LoadPackage('modules' + PathDelimiter + name);
        
    module := GModule.Create();
        
    module.handle := hndl;
    module.fname := name;
    module.desc := GetPackageDescription(PChar('modules' + PathDelimiter + name));
        
    module_list.put(name, module);

    write_console('Loaded ' + name + ' (' + module.desc + ')');
  except
    on E : Exception do raise GException.Create('modules.pas:addModule()',E.Message);
  end;
end;

procedure removeModule(name : string);
var
  module : GModule;
begin
  try
    module := GModule(module_list.get(name));
    
    if (module = nil) then
      raise GException.Create('modules.pas:addModule()','Module not loaded');
      
    write_console('Unloaded ' + module.fname);
    
    module_list.remove(name);
    module.Free;
  except      
    on E : Exception do raise GException.Create('modules.pas:addModule()',E.Message);
  end;
end;

begin
  module_list := GHashTable.Create(128);
end.
