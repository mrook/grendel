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
	debug,
	modules,
	constants,
	systray;

  
type
	GConsoleWindowWriter = class(GConsoleWriter)
	public
		procedure write(timestamp : TDateTime; const text : string; debugLevel : integer = 0); override;
	end;

	GConsoleModule = class(TInterfacedObject, IModuleInterface)
	public
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

procedure GConsoleWindowWriter.write(timestamp : TDateTime; const text : string; debugLevel : integer = 0);
begin
	if (consoleMemo = nil) then
		exit;
		
	if (debugLevel = 0) then
		begin
		consoleMemo.Lines.add('[' + FormatDateTime('hh:nn', Now) + '] ' + text);
		Application.ProcessMessages();
		end;
end;

procedure GConsoleModule.registerModule();
var
	console : GConsole;
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

	console := GConsole.Create();
	console.fetchHistory(consoleDriver);  
	console.attachWriter(consoleDriver);	
	console.Free();
end;

procedure GConsoleModule.unregisterModule();
var
	console : GConsole;
begin
	console := GConsole.Create();
	console.detachWriter(consoleDriver);
	console.Free();

	FreeAndNil(consoleMemo);
	FreeAndNil(consoleFont);
	consoleForm.Release();

	unregisterMenuItem('Show console');

	consoleDriver.Free();
end;


exports
	returnModuleInterface;
 
{$ENDIF}

end.
