{
	Summary:
		NT Service main unit
	
	## $Id: servicemain.pas,v 1.1 2004/03/22 14:55:49 ***REMOVED*** Exp $
}

unit servicemain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs;

type
  TServiceGrendel = class(TService)
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStop(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceAfterInstall(Sender: TService; var Stopped: Boolean);
  private
    { Private declarations }
    procedure serverTick();
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  ServiceGrendel: TServiceGrendel;

implementation

{$R *.DFM}

uses
	Registry,
	conns,
	constants,
	console,
	server;

var
	serverInstance : GServer;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
	ServiceGrendel.Controller(CtrlCode);
end;

function TServiceGrendel.GetServiceController: TServiceController;
begin
	Result := ServiceController;
end;

procedure TServiceGrendel.serverTick();
begin
	ServiceThread.ProcessRequests(false);
end;

procedure TServiceGrendel.ServiceExecute(Sender: TService);
var
	shutdownType : GServerShutdownTypes;
begin
	writeConsole('Grendel ' + version_number + ' ready...');

	shutdownType := serverInstance.gameLoop();

	flushConnections();	

	serverInstance.cleanup();

	serverInstance.Free();
	
	Status := csStopped;
	ReportStatus();
end;

procedure TServiceGrendel.ServiceStart(Sender: TService;
  var Started: Boolean);
var
	cons : GConsole;
	path : string;
begin
	Started := false;
	
	path := ExtractFilePath(ParamStr(0));

 	if (not DirectoryExists(path)) then
  		begin
    	ErrCode := 1;
		LogMessage('Directory "' + path + '" does not exist', EVENTLOG_ERROR_TYPE, 0, 1);
    	exit;
    	end;

	ChDir(path);

	cons := GConsole.Create();
	cons.attachWriter(GConsoleLogWriter.Create('grendel'));
	cons.Free();

	serverInstance := GServer.Create();
	serverInstance.OnTick := serverTick;

	serverInstance.init();

 	writeConsole('Running as NT service...');

	Started := true;
end;

procedure TServiceGrendel.ServiceStop(Sender : TService; var Stopped: Boolean);
begin
	serverInstance.shutdown(SHUTDOWNTYPE_HALT, 0);
end;

procedure TServiceGrendel.ServiceAfterInstall(Sender: TService);
begin
	with TRegistry.Create(KEY_READ or KEY_WRITE) do
	try
		RootKey := HKEY_LOCAL_MACHINE;
		if OpenKey( 'SYSTEM\CurrentControlSet\Services\' + Name, True) then
			begin
			WriteString('Description', version_info + ' Version ' + version_number);
			end;
	finally
		Free();
	end;
end;

end.
