// ************************************************************************ //
// The types declared in this file were generated from data read from the
// WSDL File described below:
// WSDL     : http://localhost:4041/wsdl/ISOAPAuthenticator
// Encoding : utf-8
// Version  : 1.0
// (12-4-2004 19:27:29 - 1.33.2.5)
// ************************************************************************ //

unit WSDLISOAPAuthenticator;

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


  // ************************************************************************ //
  // Namespace : urn:soapauth-ISOAPAuthenticator
  // soapAction: urn:soapauth-ISOAPAuthenticator#%operationName%
  // transport : http://schemas.xmlsoap.org/soap/http
  // style     : rpc
  // binding   : ISOAPAuthenticatorbinding
  // service   : ISOAPAuthenticatorservice
  // port      : ISOAPAuthenticatorPort
  // URL       : http://localhost:4041/soap/ISOAPAuthenticator
  // ************************************************************************ //
  ISOAPAuthenticator = interface(IInvokable)
  ['{5AE15F68-E5A0-C561-048D-D92D688E849D}']
    function  login(const username: WideString; const password: WideString; out sessionHandle: WideString): Boolean; stdcall;
    function  logout(const sessionHandle: WideString): Boolean; stdcall;
  end;

function GetISOAPAuthenticator(UseWSDL: Boolean=System.False; Addr: string=''; HTTPRIO: THTTPRIO = nil): ISOAPAuthenticator;


implementation

function GetISOAPAuthenticator(UseWSDL: Boolean; Addr: string; HTTPRIO: THTTPRIO): ISOAPAuthenticator;
const
  defWSDL = 'http://localhost:4041/wsdl/ISOAPAuthenticator';
  defURL  = 'http://localhost:4041/soap/ISOAPAuthenticator';
  defSvc  = 'ISOAPAuthenticatorservice';
  defPrt  = 'ISOAPAuthenticatorPort';
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
    Result := (RIO as ISOAPAuthenticator);
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
  InvRegistry.RegisterInterface(TypeInfo(ISOAPAuthenticator), 'urn:soapauth-ISOAPAuthenticator', 'utf-8');
  InvRegistry.RegisterDefaultSOAPAction(TypeInfo(ISOAPAuthenticator), 'urn:soapauth-ISOAPAuthenticator#%operationName%');

end.