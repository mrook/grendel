{
  @abstract(Loadable module system)
  @lastmod($Id: modules.pas,v 1.2 2004/02/11 22:15:25 ***REMOVED*** Exp $)
}
  
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
  IModuleInterface = interface
  ['{8DF7865B-69A9-4AA8-A415-E82553597B1C}']

   	procedure registerModule();
  	procedure unregisterModule();
  end;

	GReturnModuleInterfaceFunction = function() : IModuleInterface;

  GModuleInfo = class
  private
    _handle : HMODULE;
    _filename : string;
    _description : string;
    _intf : IModuleInterface;
    
  published
  	constructor Create(handle_ : HMODULE; filename_ : string; description_ : string; intf_ : IModuleInterface);
  	
  	procedure clearInterface();
  	
  	property handle : HMODULE read _handle;
  	property filename : string read _filename;
  	property description : string read _description;
  	property intf : IModuleInterface read _intf;
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
  chars,
  util,
  commands,
  console,
  mudsystem;



constructor GModuleInfo.Create(handle_ : HMODULE; filename_ : string; description_ : string; intf_ : IModuleInterface);
begin
	inherited Create();
	
	_handle := handle_;
	_filename := filename_;
	_description := description_;
	_intf := intf_;
end;

procedure GModuleInfo.clearInterface();
begin
  _intf := nil;
end;


procedure do_modules(ch : GCharacter; param : string);
var
  iterator : GIterator;
  module : GModuleInfo;
  arg : string;
begin
  if (length(param) = 0) then
    begin
    iterator := module_list.iterator();

    ch.sendBuffer('Usage:  MODULES <load|unload> <modules_name>'#13#10#13#10);

    ch.sendBuffer('Registered modules:'#13#10#13#10);
  
    while (iterator.hasNext()) do
      begin
      module := GModuleInfo(iterator.next());
    
      ch.sendBuffer(module.filename + ' (' + module.description + ')'#13#10);
      end;

    iterator.Free();
    end
  else
    begin
    param := one_argument(param, arg);
    
    if (arg = 'load') then
      try
        addModule(param);
		    ch.sendBuffer('Module ' + param + ' was loaded.'#13#10);
      except
        on E : Exception do
          ch.sendBuffer('Could not load module ' + param + ': ' + E.Message + #13#10);
      end
    else
    if (arg = 'unload') then
      try
        removeModule(param);
		    ch.sendBuffer('Module ' + param + ' was unloaded.'#13#10);
      except
        on E : Exception do
          ch.sendBuffer('Could not load module ' + param + ': ' + E.Message + #13#10);
      end;    
    end;
end;

procedure loadModules();
var 
  t : TSearchRec;
begin
  module_list := GHashTable.Create(128);
  registerCommand('do_modules', do_modules);

{$IFDEF LINUX}
   if (FindFirst('modules' + PathDelimiter + 'bpl*.so', faAnyFile, t) = 0) then
{$ELSE}
   if (FindFirst('modules' + PathDelimiter + '*.bpl', faAnyFile, t) = 0) then
{$ENDIF}
    repeat     
      try
        addModule(t.name);
      except
        on E : Exception do
          bugreport('loadModules()', 'modules.pas', 'Unable to load module ' + t.name + ': ' + E.Message);
      end;
    until (FindNext(t) <> 0);

  FindClose(t);
end;

procedure unloadModules();
var
  iterator : GIterator;
  module : GModuleInfo;
begin
  iterator := module_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    module := GModuleInfo(iterator.next());

    writeConsole('Unloading module ' + module.filename);
    
    module.intf.unregisterModule();
    module.clearInterface();
    
    UnloadPackage(module.handle);
      
    writeConsole('Unloaded module ' + module.filename);
    end;
    
  module_list.clear();
  module_list.Free();
  
  iterator.Free();
end;

procedure addModule(name : string);
var
  hndl : HMODULE;
  module : GModuleInfo;
  returnModuleInterface : GReturnModuleInterfaceFunction;
begin
  if (module_list.get(name) <> nil) then
    raise Exception.Create('Module already loaded');
      
  hndl := LoadPackage('modules' + PathDelimiter + name);
  
  @returnModuleInterface := GetProcAddress(hndl, 'returnModuleInterface');
  
  if (@returnModuleInterface = nil) then
  	begin
  	writeConsole('Could not find interface function in ' + name);
  	UnloadPackage(hndl);
  	end
  else
  	begin     
  	module := GModuleInfo.Create(hndl, name, GetPackageDescription(PChar('modules' + PathDelimiter + name)), returnModuleInterface());
      
	  module.intf.registerModule();
      
  	module_list.put(name, module);

	  writeConsole('Loaded module ' + name + ' (' + module.description + ')');
	  end;
  
//  readMapFile(name, 'modules' + PathDelimiter + left(name, '.') + '.map');
end;

procedure removeModule(name : string);
var
  module : GModuleInfo;
begin
  module := GModuleInfo(module_list.get(name));
  
  if (module = nil) then
    raise Exception.Create('Module not loaded');
    
  module.intf.unregisterModule();
  module.clearInterface();

  UnloadPackage(module.handle);
    
  writeConsole('Unloaded module ' + module.filename);
  
  module_list.remove(name);
  module.Free;
end;


end.
