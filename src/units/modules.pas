{
	Summary:
		Loadable module system

	## $Id: modules.pas,v 1.5 2004/04/10 22:24:03 ***REMOVED*** Exp $
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
  	constructor Create(handle_ : HMODULE; const filename_, description_ : string; intf_ : IModuleInterface);
  	
  	procedure clearInterface();
  	
  	property handle : HMODULE read _handle;
  	property filename : string read _filename;
  	property description : string read _description;
  	property intf : IModuleInterface read _intf;
  end;
  

procedure loadModules();
procedure unloadModules();

procedure addModule(const name : string);
procedure removeModule(const name : string);


var
	module_list : GHashTable;


implementation


uses
  constants,
  chars,
  debug,
  util,
  commands,
  console;


constructor GModuleInfo.Create(handle_ : HMODULE; const filename_, description_ : string; intf_ : IModuleInterface);
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
          writeConsole('Unable to load module ' + t.name + ': ' + E.Message);
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

		// possibly dangerous terrain
		try
			module.intf.unregisterModule();
			module.clearInterface();

			UnloadPackage(module.handle);
		except
			on E : Exception do reportException(E);
		end;

		writeConsole('Unloaded module ' + module.filename);
		end;

	module_list.clear();
	module_list.Free();

	iterator.Free();
end;

procedure addModule(const name : string);
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
		try
			module := GModuleInfo.Create(hndl, name, GetPackageDescription(PChar('modules' + PathDelimiter + name)), returnModuleInterface());

			module.intf.registerModule();

			module_list.put(name, module);

			writeConsole('Loaded module ' + name + ' (' + module.description + ')');			
		except
			on E : Exception do reportException(E);
		end;
		end;
end;

procedure removeModule(const name : string);
var
	module : GModuleInfo;
begin
	module := GModuleInfo(module_list.get(name));

	if (module = nil) then
		raise Exception.Create('Module not loaded');

	try
		module.intf.unregisterModule();
		module.clearInterface();
		UnloadPackage(module.handle);
	except
		on E : Exception do reportException(E);
	end;

	writeConsole('Unloaded module ' + module.filename, 1);

	module_list.remove(name);
	module.Free;
end;


end.
