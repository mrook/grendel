unit status_console;

interface


implementation

uses
  Windows,
  StdCtrls,
  Forms,
  console,
  constants,
  systray;
  
type
  GConsoleWindowWriter = class(GConsoleWriter)
  public
    procedure write(timestamp : TDateTime; text : string); override;
  end;
  
var
  consoleForm : TForm;
  consoleMemo : TMemo;
  consoleDriver : GConsoleWindowWriter;
  
procedure GConsoleWindowWriter.write(timestamp : TDateTime; text : string);
begin
  consoleMemo.Lines.add(text);
end;
  
procedure showConsoleProc(id : integer);
begin
  consoleForm.Show();
end;

initialization 
  consoleForm := TForm.Create(nil);
  consoleForm.Caption := version_info + ': Server console';
  consoleForm.Position := poScreenCenter;
  consoleForm.BorderStyle := bsSingle;
  consoleForm.BorderIcons := [biSystemMenu];
  consoleForm.Width := 500;
  
  consoleMemo := TMemo.Create(consoleForm);
  consoleMemo.Width := consoleForm.ClientWidth;
  consoleMemo.Height := consoleForm.ClientHeight;
  consoleMemo.Parent := consoleForm;
  consoleMemo.ScrollBars := ssVertical;
  consoleMemo.ReadOnly := True;
  consoleMemo.WordWrap := false;
  
  consoleDriver := GConsoleWindowWriter.Create();

  registerMenuItem('Show console', showConsoleProc);

  fetchConsoleHistory(0, consoleDriver);
  
  registerConsoleDriver(consoleDriver);
  

finalization  
  unregisterConsoleDriver(consoleDriver);
  unregisterMenuItem('Show console');
  
  
end.
