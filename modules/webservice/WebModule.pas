{ 
	Summary:
		SOAP Web Module
		
	## $Id: WebModule.pas,v 1.1 2003/09/24 14:31:46 ***REMOVED*** Exp $
}
unit WebModule;

interface

uses
  SysUtils, Classes, HTTPApp, InvokeRegistry, WSDLIntf, TypInfo,
  WebServExp, WSDLBind, XMLSchema, WSDLPub, SOAPPasInv, SOAPHTTPPasInv,
  SOAPHTTPDisp, WebBrokerSOAP;

type
  TGrendelWebModule = class(TWebModule)
    HTTPSoapDispatcher1: THTTPSoapDispatcher;
    HTTPSoapPascalInvoker1: THTTPSoapPascalInvoker;
    WSDLHTMLPublish1: TWSDLHTMLPublish;
    procedure WebModule2DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GrendelWebModule: TGrendelWebModule;

implementation

uses WebReq;

{$R *.dfm}

procedure TGrendelWebModule.WebModule2DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  WSDLHTMLPublish1.ServiceInfo(Sender, Request, Response, Handled);
end;

initialization
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := TGrendelWebModule;

end.
