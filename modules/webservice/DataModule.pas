{
	Summary:
		SOAP Data Module
	
	## $Id: DataModule.pas,v 1.1 2003/09/24 14:31:45 ***REMOVED*** Exp $
}
Unit DataModule;

interface

uses SysUtils, Classes, InvokeRegistry, Midas, SOAPMidas, SOAPDm, GrendelWebServiceIntf;

type
  IGrendelDataModule = interface(IAppServerSOAP)
    ['{D7F54A30-5EDA-474C-9FE4-D1E13E48E220}']
  end;

  TGrendelDataModule = class(TSoapDataModule, IGrendelWebService)
  private
  
  public
    function HelloWorld(Param1 : String) : string; stdcall;
  end;

implementation

procedure TGrendelDataModuleCreateInstance(out obj: TObject);
begin
 obj := TGrendelDataModule.Create(nil);
end;

function TGrendelDataModule.HelloWorld(Param1:
    string): string; stdcall;
  begin
    Result := 'Hello World.  Your data: ' + Param1;
  end;

initialization
   InvRegistry.RegisterInvokableClass(TGrendelDataModule, TGrendelDataModuleCreateInstance);
   InvRegistry.RegisterInterface(TypeInfo(IGrendelDataModule));
end.
