program gman;

uses
  QForms,
  mainform in 'mainform.pas' {Form1},
  WSDLIGrendelWebService in 'WSDLIGrendelWebService.pas',
  WSDLISOAPAuthenticator in 'WSDLISOAPAuthenticator.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
