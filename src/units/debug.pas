{
	Summary:
		Internal debug routines
		
	## $Id: debug.pas,v 1.8 2004/03/13 15:47:51 ***REMOVED*** Exp $
}

unit debug;

interface


uses
	dtypes;
	

type
	GDebugWriter = class
	public
		procedure write(const msg : string; debugLevel : integer = 1); virtual; abstract;
	end;
	
	GDebugger = class(GSingleton)
	private
		writers : GDLinkedList;
	
	public
		constructor actualCreate(); override;
		destructor actualDestroy(); override;
		
	published
		procedure write(const msg : string; debugLevel : integer = 1);
		
		procedure attachWriter(writer : GDebugWriter);
		procedure detachWriter(writer : GDebugWriter);
	end;
	

var
	debugger : GDebugger;

 
procedure initDebug();
procedure cleanupDebug();

{$IFDEF LINUX}
procedure listBackTrace();
{$ENDIF}


implementation


uses
{$IFDEF WIN32}
	Windows,
	JclHookExcept,
	JclDebug,
{$ENDIF}
{$IFDEF LINUX}
	Libc,
{$ENDIF}
	SysUtils,
	Classes,
	console,
	mudsystem;



{ GDebugger constructor }
constructor GDebugger.actualCreate();
begin
	writers := GDLinkedList.Create();
end;

{ GDebugger destructor }
destructor GDebugger.actualDestroy();
begin
	writers.clear();
	writers.Free();
end;

{ Feeds a debug message to any attached writers }
procedure GDebugger.write(const msg : string; debugLevel : integer = 1);
var
	iterator : GIterator;
	writer : GDebugWriter;
begin
	iterator := writers.iterator();
	
	while (iterator.hasNext()) do
		begin
		writer := GDebugWriter(iterator.next());
		
		writer.write(msg, debugLevel);
		end;
		
	iterator.Free();
end;

{ Attach a writer to the debugger }
procedure GDebugger.attachWriter(writer : GDebugWriter);
begin
	writers.add(writer);
end;

{ Detach a writer from the debugger }
procedure GDebugger.detachWriter(writer : GDebugWriter);
begin
	writers.remove(writer);
end;


{$IFDEF WIN32}
procedure AnyExceptionNotify(ExceptObj: TObject; ExceptAddr: Pointer; OSException: Boolean);
var
	a : integer;
	e : Exception;
	strings : TStringList;
	list : TJclExceptFrameList;
begin
	list := JclLastExceptFrameList;
	
	// (definately a) handled exception, quit
	if (list.items[0].FrameKind = efkAnyException) then
		exit;

	if (ExceptObj <> nil) then
		begin
		e := ExceptObj as Exception;
		writeConsole('[EX Main:' + e.ClassName + '] ' + e.Message);
		end
	else
		writeConsole('[EX Unknown]');	
		
	strings := TStringList.Create();

	JclLastExceptStackListToStrings(strings, False, False, False);

	if (strings.count > 0) then
		begin
		writeConsole('Stacktrace follows:');

		for a := 0 to strings.count - 1 do
			writeConsole(strings[a]);
		end
	else
		writeConsole('No stacktrace available.');

	strings.Free();
end;

function ExceptionFilter(ExceptionInfo: _EXCEPTION_POINTERS): Longint; export; stdcall;
begin
	Result := 1;
end;
{$ENDIF}

{$IFDEF LINUX}
function backtrace(var __array; __size : integer) : integer; cdecl; external 'libc.so.6' name 'backtrace';

procedure findSymbol(addr : pointer);
var
	info : TDLInfo;
begin
	dladdr(addr, info);
	
	writeln('(', IntToHex(integer(addr), 8), ') ', info.dli_sname, ' in ', info.dli_fname);
end;

procedure listBackTrace();
var
	l, ret : integer;
	x : array[0..15] of pointer;
begin
	ret := backtrace(x, 16);
	
	for l := 0 to ret - 1 do
		begin
		findSymbol(x[l]);
		//writeln('backtrace: ', IntToHex(integer(x[l]), 8));
		end;
end;

procedure ExceptHandler(ExceptObject : TObject; ExceptAddr : Pointer);
var
	E : Exception;
begin
	E := ExceptObject as Exception;

	writeln('[EX] ' + E.ClassName + ': ' + E.Message);
	
	listBackTrace();

	if (E is EControlC) then
		grace_exit := true;

	halt;
end;
{$ENDIF}

procedure initDebug();
begin
{$IFDEF WIN32}
	// initialize the debug 'fail-safe device'

	ExceptProc := nil;

	JclStackTrackingOptions := JclStackTrackingOptions + [stRawMode,stStaticModuleList,stExceptFrame];
	SetUnhandledExceptionFilter(@ExceptionFilter);

	JclStartExceptionTracking;
	JclInitializeLibrariesHookExcept;
	JclAddExceptNotifier(AnyExceptionNotify);
{$ENDIF}
{$IFDEF LINUX}
	ExceptProc := @ExceptHandler;
{$ENDIF}
end;

procedure cleanupDebug();
begin
end;


initialization
	debugger := GDebugger.Create();
	
finalization
	debugger.Free();
	
end.
