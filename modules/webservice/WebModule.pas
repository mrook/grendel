{ 
	Summary:
		SOAP Web Module
		
	## $Id: WebModule.pas,v 1.2 2003/09/25 17:53:24 ***REMOVED*** Exp $
}
unit WebModule;

interface

uses
  SysUtils, Classes, HTTPApp, InvokeRegistry, WSDLIntf, TypInfo,
  WebServExp, WSDLBind, XMLSchema, WSDLPubGrendel, SOAPPasInv, SOAPHTTPPasInv,
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

{$R *.dfm}

procedure TGrendelWebModule.WebModule2DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  WSDLHTMLPublish1.ServiceInfo(Sender, Request, Response, Handled);
end;

end.
