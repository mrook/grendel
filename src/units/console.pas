{
	Summary:
  	Abstract console interface
  	
  ##	$Id: console.pas,v 1.6 2004/03/17 00:19:32 ***REMOVED*** Exp $
}

unit console;

interface

uses
  SysUtils,
  Contnrs,
  dtypes;
  

type
  GConsoleWriter = class
  public
    procedure write(timestamp : TDateTime; const text : string); virtual; abstract;
  end;
  
  GConsoleDefault = class(GConsoleWriter)
  public
    procedure write(timestamp : TDateTime; const text : string); override;
  end;

  GConsoleLogWriter = class(GConsoleWriter)
  private
	  logFile : textfile;
  
  public
  	constructor Create();
  	destructor Destroy(); override;
  	
    procedure write(timestamp : TDateTime; const text : string); override;
  end;
  
  GConsoleHistoryElement = class
  private
  	_timestamp : TDateTime;
  	_text : string;
  	
  public
    property timestamp : TDateTime read _timestamp write _timestamp;
    property text : string read _text write _text;
  end;
  
  GConsole = class(GSingleton)
  private
  	writers : GDLinkedList;
  	history : GDLinkedList;
  	queue : GDLinkedList;
 	
  public
  	constructor actualCreate(); override;
  	destructor actualDestroy(); override;
  	
  published
  	procedure write(const text : string);
  	procedure poll();
			
  	procedure attachWriter(writer : GConsoleWriter);
  	procedure detachWriter(writer : GConsoleWriter);
  	
  	procedure fetchHistory(callback : GConsoleWriter; max : integer = 0);
  end;



  
procedure writeConsole(const text : string);
procedure pollConsole();


implementation


uses
	mudsystem,
	fsys,
	server;


const
	{ Maximum number of items in the console history }
	CONSOLE_HISTORY_MAX = 200;
  

var
	cons : GConsole;


{ GConsole constructor }
constructor GConsole.ActualCreate();
begin
	writers := GDLinkedList.Create();
	history := GDLinkedList.Create();
	queue := GDLinkedList.Create();
end;

{ GConsole destructor }
destructor GConsole.ActualDestroy();
begin
	writers.clear();
	history.clear();
	queue.clear();
	
	writers.Free();
	history.Free();
	queue.Free();
end;

{ Attach a GConsoleWriter object to the console }
procedure GConsole.attachWriter(writer : GConsoleWriter);
begin
	writers.add(writer);
end;

{ Detach a GConsoleWriter object from the console }
procedure GConsole.detachWriter(writer : GConsoleWriter);
begin
	writers.remove(writer);
end;

{ Write a message to the console }
procedure GConsole.write(const text : string);
var
  he : GConsoleHistoryElement;
  timestamp : TDateTime;
begin
  timestamp := Now();

  he := GConsoleHistoryElement.Create();
  he.timestamp := timestamp;
  he.text := text;
  history.add(he);

  if (history.size() > CONSOLE_HISTORY_MAX) then
  	begin
  	GConsoleHistoryElement(history.head.element).Free();
    history.remove(history.head);
    end;
    
  he := GConsoleHistoryElement.Create();
  he.timestamp := timestamp;
  he.text := text;
  queue.add(he);
  
	if (not serverBooted) then
		poll();
end;

{ Poll the console }
procedure GConsole.poll();
var
	he : GConsoleHistoryElement;
	iterator : GIterator;
	writer : GConsoleWriter;
begin
	while (queue.head <> nil) do
		begin
		he := GConsoleHistoryElement(queue.head.element);
	
		queue.remove(queue.head);
  
  	iterator := writers.iterator();
  
		while (iterator.hasNext()) do
			begin
			writer := GConsoleWriter(iterator.next());

			writer.write(he.timestamp, he.text);
			end;    

		iterator.Free();
		
		he.Free();
		end;
end;

{ Fetch (up to) max items from the history and feed them to callback }
procedure GConsole.fetchHistory(callback : GConsoleWriter; max : integer = 0);
var
  iterator : GIterator;
  he : GConsoleHistoryElement;
  count : integer;
begin
  iterator := history.iterator();
  count := 0;
  
  while (iterator.hasNext()) do
    begin
    he := GConsoleHistoryElement(iterator.next());
    
    callback.write(he.timestamp, he.text);
    
    inc(count);
    
    if (max > 0) and (count >= max) then
      break;
    end;
    
  iterator.Free();
end;

procedure writeConsole(const text : string);
begin
	cons.write(text);
end;

procedure pollConsole();
begin
	cons.poll();
end;


{ Writes to stdout (if available) }
procedure GConsoleDefault.write(timestamp : TDateTime; const text : string);
begin
{$IFDEF CONSOLEBUILD}
  writeln('[' + FormatDateTime('hh:nn', Now) + '] ', text);
{$ENDIF}
end;

{ GConsoleLogWriter constructor }
constructor GConsoleLogWriter.Create();
begin
	inherited Create();

  { open a standard log file, filename is given by current system time }
  AssignFile(logFile, translateFileName('logs\' + FormatDateTime('yyyymmdd-hhnnss', Now) + '.log'));

  {$I-}
  rewrite(logFile);
  {$I+}

  if (IOResult <> 0) then
    writeConsole('Could not open logfile');
end;

{ GConsoleLogWriter destructor }
destructor GConsoleLogWriter.Destroy();
begin
  if (TTextRec(logfile).mode = fmOutput) then
    CloseFile(LogFile);
    
	inherited Destroy();
end;

{ Writes to logfile }
procedure GConsoleLogWriter.write(timestamp : TDateTime; const text : string);
begin
  if (TTextRec(logfile).mode = fmOutput) then
    begin
    system.writeln(logfile, '[' + FormatDateTime('yyyymmdd hh:nn:ss', Now) + '] ' + text);
    system.flush(logfile);
    end;
end;


initialization
	cons := GConsole.Create();
	
	cons.attachWriter(GConsoleDefault.Create());
	cons.attachWriter(GConsoleLogWriter.Create());
	
finalization
	FreeAndNil(cons);
	
end.
