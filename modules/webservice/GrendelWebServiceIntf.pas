{ Invokable interface IGrendelWebService }

unit GrendelWebServiceIntf;

interface

uses InvokeRegistry, Types, XSBuiltIns;

type

  { Invokable interfaces must derive from IInvokable }
  IGrendelWebService = interface(IInvokable)
  ['{C8B5F909-183B-4D12-9DE3-1BB4F1AD64E9}']

    { Methods of Invokable interface must not use the default }
    { calling convention; stdcall is recommended }
    function HelloWorld(Param1: string): string; stdcall;
  end;

implementation

initialization
  { Invokable interfaces must be registered }
  InvRegistry.RegisterInterface(TypeInfo(IGrendelWebService));

end.
 