// ************************************************************************ //
// The types declared in this file were generated from data read from the
// WSDL File described below:
// WSDL     : http://localhost:4041/wsdl/IGrendelWebService
// Encoding : utf-8
// Version  : 1.0
// (12-4-2004 22:04:57 - 1.33.2.5)
// ************************************************************************ //

unit WSDLIGrendelWebService;

interface

uses InvokeRegistry, SOAPHTTPClient, Types, XSBuiltIns;

type

  // ************************************************************************ //
  // The following types, referred to in the WSDL document are not being represented
  // in this file. They are either aliases[@] of other types represented or were referred
  // to but never[!] declared in the document. The types from the latter category
  // typically map to predefined/known XML or Borland types; however, they could also 
  // indicate incorrect WSDL documents that failed to declare or import a schema type.
  // ************************************************************************ //
  // !:string          - "http://www.w3.org/2001/XMLSchema"
  // !:boolean         - "http://www.w3.org/2001/XMLSchema"
  // !:int             - "http://www.w3.org/2001/XMLSchema"

  TStringArray = array of WideString;           { "urn:GrendelWebServiceIntf" }

  // ************************************************************************ //
  // Namespace : urn:GrendelWebServiceIntf-IGrendelWebService
  // soapAction: urn:GrendelWebServiceIntf-IGrendelWebService#%operationName%
  // transport : http://schemas.xmlsoap.org/soap/http
  // style     : rpc
  // binding   : IGrendelWebServicebinding
  // service   : IGrendelWebServiceservice
  // port      : IGrendelWebServicePort
  // URL       : http://localhost:4041/soap/IGrendelWebService
  // ************************************************************************ //
  IGrendelWebService = interface(IInvokable)
  ['{5E4DC4A3-54B6-5B9B-D147-2EB3BB220E16}']
    function  getRaces(const sessionHandle: WideString): TStringArray; stdcall;
    function  isOnline(const sessionHandle: WideString): Boolean; stdcall;
    function  getConsoleHistory(const sessionHandle: WideString; var timestamp: Integer): TStringArray; stdcall;
  end;

function GetIGrendelWebService(UseWSDL: Boolean=System.False; Addr: string=''; HTTPRIO: THTTPRIO = nil): IGrendelWebService;


implementation

function GetIGrendelWebService(UseWSDL: Boolean; Addr: string; HTTPRIO: THTTPRIO): IGrendelWebService;
const
  defWSDL = 'http://localhost:4041/wsdl/IGrendelWebService';
  defURL  = 'http://localhost:4041/soap/IGrendelWebService';
  defSvc  = 'IGrendelWebServiceservice';
  defPrt  = 'IGrendelWebServicePort';
var
  RIO: THTTPRIO;
begin
  Result := nil;
  if (Addr = '') then
  begin
    if UseWSDL then
      Addr := defWSDL
    else
      Addr := defURL;
  end;
  if HTTPRIO = nil then
    RIO := THTTPRIO.Create(nil)
  else
    RIO := HTTPRIO;
  try
    Result := (RIO as IGrendelWebService);
    if UseWSDL then
    begin
      RIO.WSDLLocation := Addr;
      RIO.Service := defSvc;
      RIO.Port := defPrt;
    end else
      RIO.URL := Addr;
  finally
    if (Result = nil) and (HTTPRIO = nil) then
      RIO.Free;
  end;
end;


initialization
  InvRegistry.RegisterInterface(TypeInfo(IGrendelWebService), 'urn:GrendelWebServiceIntf-IGrendelWebService', 'utf-8');
  InvRegistry.RegisterDefaultSOAPAction(TypeInfo(IGrendelWebService), 'urn:GrendelWebServiceIntf-IGrendelWebService#%operationName%');
  RemClassRegistry.RegisterXSInfo(TypeInfo(TStringArray), 'urn:GrendelWebServiceIntf', 'TStringArray');

end.
