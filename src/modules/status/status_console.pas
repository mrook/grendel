{
	Summary:
		Module that hooks into systray.pas and displays console form on desktop
	
	## $Id: status_console.pas,v 1.11 2004/04/12 20:49:02 ***REMOVED*** Exp $
}
unit status_console;

interface


implementation

{$IFNDEF CONSOLEBUILD}
uses
	DateUtils,
	Classes,
	Windows,
	StdCtrls,
	ExtCtrls,
	SysUtils,
	Graphics,
	Forms,
	SyncObjs,
	console,
	modules,
	constants,
	systray;

  
type
	GConsoleWindowWriter = class(GConsoleWriter)
	public
		procedure write(timestamp : integer; const text : string; debugLevel : integer = 0); override;
	end;

	GConsoleModule = class(TInterfacedObject, IModuleInterface)
	private
		consoleMemo : TMemo;
		consoleFont : TFont;
		consoleTimer : TTimer;
		consoleDriver : GConsoleWindowWriter;
		
		procedure handleOnTimer(Sender : TObject);
	public
		procedure registerModule();
		procedure unregisterModule();
	end;

  
var
	consoleQueue : TStringList;
	consoleForm : TForm;
	cs : TCriticalSection;  

procedure showConsoleProc(id : integer);
begin
	consoleForm.Show();
end;
 
function returnModuleInterface() : IModuleInterface;
begin
	Result := GConsoleModule.Create();
end;

procedure GConsoleWindowWriter.write(timestamp : integer; const text : string; debugLevel : integer = 0);
begin
	cs.Acquire();
	
	consoleQueue.add('[' + FormatDateTime('hh:nn:ss', UnixToDateTime(timestamp)) + '] ' + text);
	
	cs.Release();
end;

procedure GConsoleModule.handleOnTimer(Sender: TObject);
var
	idx : integer;
begin
	cs.Acquire();
	
	for idx := 0 to consoleQueue.Count - 1 do
		begin
		consoleMemo.Lines.Add(consoleQueue[idx]);
		end;
		
	Application.ProcessMessages();
	consoleQueue.Clear();
	
	cs.Release();
end;

procedure GConsoleModule.registerModule();
var
	console : GConsole;
begin
	cs := TCriticalSection.Create();
	
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
	
	cs.Free();
end;


exports
	returnModuleInterface;
 
{$ENDIF}

end.
