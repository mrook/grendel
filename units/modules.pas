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

var
  module_list : GDLinkedList;

implementation

uses
  mudsystem;

procedure loadModules();
var 
  t : TSearchRec;
  hndl : HMODULE;
  module : GModule;
begin
   if (FindFirst('modules' + PathDelimiter + '*.bpl', faAnyFile, t) = 0) then
    repeat     
      try
        hndl := LoadPackage('modules' + PathDelimiter + t.name);
        
        module := GModule.Create();
        
        module.handle := hndl;
        module.fname := t.name;
        module.desc := GetPackageDescription(PChar('modules' + PathDelimiter + t.name));
        
        module_list.insertLast(module);

        write_console('Loaded ' + t.name + ' (' + module.desc + ')');
      except
        bugreport('loadModules()', 'grendel.dpr', 'Unable to load module ' + t.name);
      end;
    until (FindNext(t) <> 0);

  FindClose(t);
end;

begin
  module_list := GDLinkedList.Create;
end.
