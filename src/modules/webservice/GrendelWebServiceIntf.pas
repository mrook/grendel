{ 
	Summary:
		Webservice interface
		
	## $Id: GrendelWebServiceIntf.pas,v 1.2 2004/04/12 21:09:05 ***REMOVED*** Exp $
}

unit GrendelWebServiceIntf;

interface

uses 
	SysUtils,
	InvokeRegistry, 
	Types, 
	Classes;

type
	TStringArray = array of string;

	IGrendelWebService = interface(IInvokable)
	['{C8B5F909-183B-4D12-9DE3-1BB4F1AD64E9}']
		function isOnline(const sessionHandle : string) : boolean; stdcall;
		function getConsoleHistory(const sessionHandle : string; var timestamp : integer) : TStringArray; stdcall;
	end;

	TGrendelWebService = class(TInvokableClass, IGrendelWebService)
	private

	public
		function isOnline(const sessionHandle : string) : boolean; stdcall;
		function getConsoleHistory(const sessionHandle : string; var timestamp : integer) : TStringArray; stdcall;
	end;

implementation

uses
	DateUtils,
	soapauth,
	mudsystem, race, dtypes, console, server;
	

type
	GConsoleStringListWriter = class(GConsoleWriter)
	public
		procedure write(timestamp : integer; const text : string; debugLevel : integer = 0); override;
	end;

	
var
	consoleList : TStringList;
	consoleStringListWriter : GConsoleStringListWriter;
	
	
procedure GConsoleStringListWriter.write(timestamp : integer; const text : string; debugLevel : integer = 0);
begin
	consoleList.add('[' + FormatDateTime('hh:nn:ss', UnixToDateTime(timestamp)) + '] ' + text);
end;


procedure TGrendelDataModuleCreateInstance(out obj: TObject);
begin
	obj := TGrendelWebService.Create();
end;

function TGrendelWebService.isOnline(const sessionHandle : string) : boolean; stdcall;
begin
	checkSession(sessionHandle);
	
	Result := serverBooted;
end;

function TGrendelWebService.getConsoleHistory(const sessionHandle : string; var timestamp : integer) : TStringArray; stdcall;
var
	console : GConsole;
	strings : TStringArray;
	idx : integer;
begin
	checkSession(sessionHandle);

	try
		console := GConsole.Create();
		
		timestamp := console.fetchHistoryTimestamp(consoleStringListWriter, timestamp);
		
		SetLength(strings, consoleList.Count);
		
		for idx := 0 to consoleList.Count - 1 do	
			strings[idx] := consoleList[idx];
			
		Result := strings;
		
		consoleList.Clear();
	finally
		console.Free();
	end;
end;

initialization
	InvRegistry.RegisterInvokableClass(TGrendelWebService);
	InvRegistry.RegisterInterface(TypeInfo(IGrendelWebService));

	consoleList := TStringList.Create();
	consoleStringListWriter := GConsoleStringListWriter.Create();

finalization
	consoleList.Free();
	consoleStringListWriter.Free();

end.
 