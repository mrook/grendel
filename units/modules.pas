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
procedure unloadModules();

procedure addModule(name : string);
procedure removeModule(name : string);

var
  module_list : GHashTable;

implementation

uses
  strip,
  debug,
  chars,
  util,
  mudthread,
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

procedure unloadModules();
var
  iterator : GIterator;
  module : GModule;
begin
  iterator := module_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    module := GModule(iterator.next());
    
    UnloadPackage(module.handle);
      
    write_console('Unloaded module ' + module.fname);
    end;
    
  module_list.clear();
  module_list.Free();
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

    write_console('Loaded module ' + name + ' (' + module.desc + ')');
    
    readMapFile(name, 'modules' + PathDelimiter + left(name, '.') + '.map');
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
      
    UnloadPackage(module.handle);
      
    write_console('Unloaded module ' + module.fname);
    
    module_list.remove(name);
    module.Free;
  except      
    on E : Exception do raise GException.Create('modules.pas:addModule()',E.Message);
  end;
end;

procedure do_modules(ch : GCharacter; param : string);
var
  iterator : GIterator;
  module : GModule;
  arg : string;
begin
  if (length(param) = 0) then
    begin
    iterator := module_list.iterator();
      
    ch.sendBuffer('Registered modules:'#13#10#13#10);
  
    while (iterator.hasNext()) do
      begin
      module := GModule(iterator.next());
    
      ch.sendBuffer(module.fname + ' (' + module.desc + ')'#13#10);
      end;
    end
  else
    begin
    param := one_argument(param, arg);
    
    if (arg = 'load') then
      try
        addModule(param);
      except
        on E : GException do
          ch.sendBuffer('Could not load module ' + param + ': ' + E.Message + #13#10);
      end
    else
    if (arg = 'unload') then
      try
        removeModule(param);
      except
        on E : GException do
          ch.sendBuffer('Could not load module ' + param + ': ' + E.Message + #13#10);
      end;
    end;
end;

begin
  module_list := GHashTable.Create(128);
  registerCommand('do_modules', do_modules);
end.
