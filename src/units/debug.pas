{
  @abstract(Internal debug routines)
  @lastmod($Id: debug.pas,v 1.3 2004/02/19 14:39:51 ***REMOVED*** Exp $)
}

unit debug;

interface

 
procedure initDebug();
procedure cleanupDebug();


implementation


uses
{$IFDEF WIN32}
	Windows,
	JclHookExcept,
	JclDebug,
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
begin
	if (ExceptObj <> nil) then
		begin
		e := ExceptObj as Exception;
		writeConsole('[EX Main:' + E.ClassName + '] ' + E.Message);
		end;
		
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
procedure ExceptHandler(ExceptObject : TObject; ExceptAddr : Pointer);
var
	E : Exception;
begin
	E := ExceptObject as Exception;

	writeln('[EX] ' + E.ClassName + ': ' + E.Message);

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
