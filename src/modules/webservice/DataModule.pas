{
	Summary:
		SOAP Data Module
	
	## $Id: DataModule.pas,v 1.1 2003/12/12 13:19:57 ***REMOVED*** Exp $
}
Unit DataModule;

interface

uses 
	SysUtils, Classes, InvokeRegistry, Midas, SOAPMidas, SOAPDm, GrendelWebServiceIntf, 
	race, dtypes, console;

type
  IGrendelDataModule = interface(IAppServerSOAP)
    ['{D7F54A30-5EDA-474C-9FE4-D1E13E48E220}']
  end;

  TGrendelDataModule = class(TSoapDataModule, IGrendelWebService)
  private
  
  public
    function getRaces() : TStringArray; stdcall;
  end;

implementation

{$R *.dfm}

procedure TGrendelDataModuleCreateInstance(out obj: TObject);
begin
 obj := TGrendelDataModule.Create(nil);
end;

function TGrendelDataModule.getRaces() : TStringArray; stdcall;
var
	iterator : GIterator;
	list : TStringArray;
	i : integer;
begin
	SetLength(list, racelist.size());
	iterator := raceList.iterator();
	i := 0;
	
	while (iterator.hasNext()) do
		begin
		list[i] := GRace(iterator.next()).name;
		inc(i);
		end;
  
  iterator.Free();
  
  Result := list;
end;

initialization
   InvRegistry.RegisterInvokableClass(TGrendelDataModule, TGrendelDataModuleCreateInstance);
   InvRegistry.RegisterInterface(TypeInfo(IGrendelDataModule));

//   InvRegistry.RegisterHeaderClass(TypeInfo(GRace), GRace);
end.
