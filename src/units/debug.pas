{
	Summary:
		Internal debug routines
		
	## $Id: debug.pas,v 1.14 2004/04/10 22:24:03 ***REMOVED*** Exp $
}

unit debug;

interface


uses
	SysUtils;
	
 
procedure initDebug();
procedure cleanupDebug();

procedure reportException(E : Exception; const sourceFile : string = '');


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
	Classes,
	console;


{$IFDEF WIN32}
procedure AnyExceptionNotify(ExceptObj: TObject; ExceptAddr: Pointer; OSException: Boolean);
var
	list : TJclExceptFrameList;
begin
	list := JclLastExceptFrameList;
	
	// (definately a) handled exception, quit
	if (list.items[0].FrameKind = efkAnyException) then
		exit;

	if (ExceptObj = nil) then
		reportException(nil, 'debug.pas:AnyExceptionNotify')
	else
		reportException(ExceptObj as Exception, 'debug.pas:AnyExceptionNotify');
end;

function ExceptionFilter(ExceptionInfo: _EXCEPTION_POINTERS): longint; stdcall;
begin
	//MessageBox(0, 'filter', 'filter', 0);
	Result := 1;
end;

procedure reportException(E : Exception; const sourceFile : string = '');
var
	a : integer;
	strings : TStringList;
begin
	if (E = nil) then
		writeConsole('[EX ' + sourceFile + '] EUnknown', 1)
	else
		writeConsole('[EX ' + sourceFile + '] ' + E.ClassName + ': ' + E.Message, 1);
		
	strings := TStringList.Create();

	JclLastExceptStackListToStrings(strings, False, False, False);

	if (strings.count > 0) then
		begin
		writeConsole('Stacktrace follows:', 1);

		for a := 0 to strings.count - 1 do
			writeConsole(strings[a], 1);
		end
	else
		writeConsole('No stacktrace available.', 1);

	strings.Free();
end;

{$ENDIF}

{$IFDEF LINUX}
function backtrace(var __array; __size : integer) : integer; cdecl; external 'libc.so.6' name 'backtrace';

procedure findSymbol(addr : pointer);
var
	info : TDLInfo;
begin
	dladdr(addr, info);
	
	writeConsole('(' + IntToHex(integer(addr), 8) + ') ' + info.dli_sname + ' in ' + info.dli_fname, 1);
end;

procedure listBackTrace();
var
	l, ret : integer;
	x : array[0..15] of pointer;
begin
	ret := backtrace(x, 16);
	
	for l := 0 to ret - 1 do
		findSymbol(x[l]);
end;

procedure reportException(E : Exception; const sourceFile : string = '');
begin
	E := ExceptObject as Exception;

	writeConsole('[EX ' + sourceFile + '] ' + E.ClassName + ': ' + E.Message, 1);
		
	listBackTrace();
end;
{$ENDIF}

var
	oldExceptProc :  pointer;

procedure ExceptHandler(ExceptObject : TObject; ExceptAddr : Pointer);
begin
	ExceptProc := oldExceptProc;
	
	{$IFDEF LINUX}	
	reportException(ExceptObject as Exception, 'debug.pas:ExceptHandler');
	{$ENDIF}
	
	Halt(1);
end;

procedure initDebug();
begin
{$IFDEF WIN32}
	// initialize the debug 'fail-safe device'
	JclStackTrackingOptions := JclStackTrackingOptions + [stRawMode,stStaticModuleList,stExceptFrame];
	SetUnhandledExceptionFilter(@ExceptionFilter);

	JclStartExceptionTracking();
	JclInitializeLibrariesHookExcept();
	JclAddExceptNotifier(AnyExceptionNotify);
{$ENDIF}

	oldExceptProc := exceptProc;
	ExceptProc := @ExceptHandler;
end;

procedure cleanupDebug();
begin
{$IFDEF WIN32}
	JclStopExceptionTracking();
{$ENDIF}
end;
	
end.
