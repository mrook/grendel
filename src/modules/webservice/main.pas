{
	Summary:
		Base unit for WebService
	
	## $Id: main.pas,v 1.1 2003/12/12 13:19:58 ***REMOVED*** Exp $
}
unit main;

interface

implementation

uses
  SysUtils, Classes, IdHTTPWebBrokerBridge, WebModule, modules;

var
	FWebBrokerBridge: TIdHTTPWebBrokerBridge;


type
  GWebServiceModule = class(TInterfacedObject, IModuleInterface)
  	procedure registerModule();
  	procedure unregisterModule();
  end;


function returnModuleInterface() : IModuleInterface;
begin
	Result := GWebServiceModule.Create();
end;


procedure GWebServiceModule.registerModule();
begin
  // Create server.
  FWebBrokerBridge := TIdHTTPWebBrokerBridge.Create(nil);

  // Register web module class.
  FWebBrokerBridge.RegisterWebModuleClass(TGrendelWebModule);

  // Set default port.
  FWebBrokerBridge.DefaultPort := 4041;

  // Start server.
  FWebBrokerBridge.Active := True;
end;

procedure GWebServiceModule.unregisterModule();
begin
  // Stop server.
  FWebBrokerBridge.Active := False;

  // Free server component.
  FreeAndNil(FWebBrokerBridge);
end;


exports
	returnModuleInterface;

  
end.
 