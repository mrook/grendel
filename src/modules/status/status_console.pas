unit status_console;

interface


implementation

{$IFNDEF CONSOLEBUILD}
uses
  Windows,
  StdCtrls,
  SysUtils,
  Graphics,
  Forms,
  console,
  modules,
  constants,
  systray;
  
type
  GConsoleWindowWriter = class(GConsoleWriter)
  public
    procedure write(timestamp : TDateTime; text : string); override;
  end;
  
  GConsoleModule = class(TInterfacedObject, IModuleInterface)
  	procedure registerModule();
  	procedure unregisterModule();
  end;
  
var
  consoleForm : TForm;
  consoleMemo : TMemo;
  consoleFont : TFont;
  consoleDriver : GConsoleWindowWriter;
  

procedure showConsoleProc(id : integer);
begin
  consoleForm.Show();
end;
 
function returnModuleInterface() : IModuleInterface;
begin
	Result := GConsoleModule.Create();
end;

procedure GConsoleWindowWriter.write(timestamp : TDateTime; text : string);
begin
	if (consoleMemo <> nil) then
		begin
  	consoleMemo.Lines.add('[' + FormatDateTime('hh:nn', Now) + '] ' + text);
  	Application.ProcessMessages();
  	end;
end;

procedure GConsoleModule.registerModule();
begin
	Application.Title := 'Grendel ' + version_number;

  consoleForm := TForm.Create(nil);
  consoleForm.Caption := version_info + ': Server console';
  consoleForm.Position := poScreenCenter;
  consoleForm.BorderStyle := bsSingle;
  consoleForm.BorderIcons := [biSystemMenu];
  consoleForm.Width := 600;
  consoleForm.Height := 400;
  
  consoleFont := TFont.Create();
  consoleFont.Name := 'Courier';
  consoleFont.Size := 10;
  
  consoleMemo := TMemo.Create(consoleForm);
  consoleMemo.Width := consoleForm.ClientWidth;
  consoleMemo.Height := consoleForm.ClientHeight;
  consoleMemo.Parent := consoleForm;
  consoleMemo.ScrollBars := ssVertical;
  consoleMemo.ReadOnly := True;
  consoleMemo.WordWrap := false;
  consoleMemo.Font := consoleFont;
  
  consoleDriver := GConsoleWindowWriter.Create();

  registerMenuItem('Show console', showConsoleProc);

  fetchConsoleHistory(0, consoleDriver);
  
  registerConsoleDriver(consoleDriver);
end;

procedure GConsoleModule.unregisterModule();
begin
  FreeAndNil(consoleMemo);
	FreeAndNil(consoleFont);
	FreeAndNil(consoleForm);

  unregisterConsoleDriver(consoleDriver);
  unregisterMenuItem('Show console');
  
  consoleDriver.Free();
end;


exports
	returnModuleInterface;
 
{$ENDIF}

end.
