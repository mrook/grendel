unit status_console;

interface


implementation

{$IFNDEF CONSOLEBUILD}
uses
	Classes,
	Windows,
	StdCtrls,
	ExtCtrls,
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
		procedure write(timestamp : TDateTime; const text : string; debugLevel : integer = 0); override;
	end;

	GConsoleModule = class(TInterfacedObject, IModuleInterface)
	private
		procedure handleOnTimer(Sender : TObject);
	public
		procedure registerModule();
		procedure unregisterModule();
	end;

  
var
	consoleQueue : TStringList;
	consoleForm : TForm;
	consoleMemo : TMemo;
	consoleFont : TFont;
	consoleTimer : TTimer;
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
	consoleQueue.add('[' + FormatDateTime('hh:nn', timestamp) + '] ' + text);
end;

procedure GConsoleModule.handleOnTimer(Sender: TObject);
var
	idx : integer;
begin
	for idx := 0 to consoleQueue.Count - 1 do
		begin
		consoleMemo.Lines.Add(consoleQueue[idx]);
		end;
		
	Application.ProcessMessages();
	consoleQueue.Clear();
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
	
	consoleTimer := TTimer.Create(consoleForm);
	consoleTimer.Interval := 250;
	consoleTimer.OnTimer := handleOnTimer;

	consoleQueue := TStringList.Create();
	consoleQueue.Duplicates := dupAccept;
	consoleQueue.Sorted := false;

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
	consoleTimer.Enabled := false;
	
	console := GConsole.Create();
	console.detachWriter(consoleDriver);
	console.Free();

	consoleForm.Release();

	unregisterMenuItem('Show console');

	consoleDriver.Free();
	
	consoleQueue.Free();
end;


exports
	returnModuleInterface;
 
{$ENDIF}

end.
