{
	Summary:
		Internal debug routines
		
	## $Id: debug.pas,v 1.7 2004/03/07 15:37:37 ***REMOVED*** Exp $
}

unit debug;

interface

 
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
 
end.
