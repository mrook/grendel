{
	Summary:
		Base unit for WebService
	
	## $Id: main.pas,v 1.1 2003/09/24 14:31:46 ***REMOVED*** Exp $
}
unit main;

interface

implementation

uses
  SysUtils, Classes, IdHTTPWebBrokerBridge, WebModule;

var
	FWebBrokerBridge: TIdHTTPWebBrokerBridge;


initialization
  // Create server.
  FWebBrokerBridge := TIdHTTPWebBrokerBridge.Create(nil);

  // Register web module class.
  FWebBrokerBridge.RegisterWebModuleClass(TGrendelWebModule);

  // Set default port.
  FWebBrokerBridge.DefaultPort := 4041;

  // Start server.
  FWebBrokerBridge.Active := True;
  
finalization
  // Stop server.
  FWebBrokerBridge.Active := False;

  // Free server component.
  FreeAndNil(FWebBrokerBridge);
end.
 