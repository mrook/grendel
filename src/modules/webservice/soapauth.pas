{
	Summary:
		SOAP Authentication interface/implementation
		
		Inspiration: BDN article by Daniel Polistchuck
			
	## $Id: soapauth.pas,v 1.1 2004/04/12 21:07:30 ***REMOVED*** Exp $
}

unit soapauth;

interface


uses 
	SysUtils, Classes, InvokeRegistry;
	

type
	ISOAPAuthenticator = interface(IInvokable)
		['{D3A18AD8-FDAE-41CA-BBAB-9DE35BE51ADD}']	

		function login(const username, password : string; out sessionHandle : string) : boolean; stdcall;
		function logout(sessionHandle : string) : boolean; stdcall;
	end;
	
	GSOAPAuthenticator = class(TInvokableClass, ISOAPAuthenticator)
	private
		function getUniqueHandle() : string;
		
	public
		function login(const username, password : string; out sessionHandle : string) : boolean; stdcall;
		function logout(sessionHandle : string) : boolean; stdcall;
	end;
	

function checkSession(const sessionHandle : string) : boolean;


implementation


uses
	GrendelWebServiceIntf,
	SyncObjs,
	dtypes;
	

type
	GSOAPSession = class
		handle : string;
		lastAction : TDateTime;
	end;
	
	
var
	cs : TCriticalSection;
	sessions : GHashTable;


function checkSession(const sessionHandle : string) : boolean;
begin
	Result := true;
	
	if (sessionHandle = '') then
		begin
		Result := false;
		raise ERemotableException.Create('Invalid session handle');
		end;
		
	try
		cs.Acquire();

		Result := (sessions[sessionHandle] <> nil);
	finally
		cs.Release();
	end;
	
	if (not Result) then
		raise ERemotableException.Create('Invalid session');
end;

function GSoapAuthenticator.getUniqueHandle() : string;
var
	guid : TGUID;
begin
	CreateGUID(guid);
	
	Result := GUIDToString(guid);
end;

function GSoapAuthenticator.login(const username, password : string; out sessionHandle : string) : boolean;
var
	session : GSOAPSession;
begin
	if (username <> 'piet') or (password <> 'henk') then
		begin
		Result := false;
		exit;
		end;

	Result := true;

	try	
		cs.Acquire();
		
		session := GSOAPSession.Create();
		session.handle := getUniqueHandle();
		
		sessions[session.handle] := session;
		
		sessionHandle := session.handle;
	finally
		cs.Release();
	end;
end;

function GSoapAuthenticator.logout(sessionHandle : string) : boolean;
begin
	Result := false;
	
	checkSession(sessionHandle);

	try
		cs.Acquire();
		
		sessions.remove(sessionHandle);
		
		Result := true;
	finally
		cs.Release();
	end;
end;


initialization
	InvRegistry.RegisterInterface(TypeInfo(ISOAPAuthenticator));
	InvRegistry.RegisterInvokableClass(GSOAPAuthenticator);
	
	sessions := GHashTable.Create(32);
	cs := TCriticalSection.Create();

finalization
	cs.Free();	
	sessions.clear();
	sessions.Free();
	
end.