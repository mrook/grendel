{
	Summary:
		SOAP Data Module
	
	## $Id: DataModule.pas,v 1.2 2003/09/26 06:15:59 ***REMOVED*** Exp $
}
Unit DataModule;

interface

uses SysUtils, Classes, InvokeRegistry, Midas, SOAPMidas, SOAPDm, GrendelWebServiceIntf, race;

type
  IGrendelDataModule = interface(IAppServerSOAP)
    ['{D7F54A30-5EDA-474C-9FE4-D1E13E48E220}']
  end;

  TGrendelDataModule = class(TSoapDataModule, IGrendelWebService)
  private
  
  public
    function getRaces() : GRace; stdcall;
  end;

implementation

procedure TGrendelDataModuleCreateInstance(out obj: TObject);
begin
 obj := TGrendelDataModule.Create(nil);
end;

function TGrendelDataModule.getRaces() : GRace; stdcall;
begin
  Result := nil;
end;

initialization
   InvRegistry.RegisterInvokableClass(TGrendelDataModule, TGrendelDataModuleCreateInstance);
   InvRegistry.RegisterInterface(TypeInfo(IGrendelDataModule));

//   InvRegistry.RegisterHeaderClass(TypeInfo(GRace), GRace);
end.
