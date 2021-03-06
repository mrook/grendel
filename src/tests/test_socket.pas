{
  Summary:
  	Tests for socket.pas
  	
  ## $Id: test_socket.pas,v 1.2 2004/02/21 17:47:28 ***REMOVED*** Exp $
}


unit test_socket;

interface


uses
	TestFramework, 
	socket;
	
	
type 
	TTestSocket = class(TTestCase)
	private
		socket : GSocket;
		
	public
		procedure Setup(); override;
		procedure TearDown(); override;
		
	published
		procedure testFactory();
	end;
	
	
implementation


uses
{$IFDEF WIN32}
	WinSock2,
{$ENDIF}
{$IFDEF LINUX}
	Libc,
{$ENDIF}
	SysUtils;


procedure TTestSocket.Setup();
begin
	socket := createSocket(AF_INET);
end;

procedure TTestSocket.TearDown();
begin
	FreeAndNil(socket);
end;

procedure TTestSocket.testFactory();
begin
	check(socket is GSocket4, 'Class is ' + socket.ClassName);
end;


initialization
  RegisterTest('', TTestSocket.Suite);

end.