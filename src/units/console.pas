{
	Summary:
  	Abstract console interface
  	
  ##	$Id: console.pas,v 1.10 2004/04/01 13:05:01 ***REMOVED*** Exp $
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
		procedure write(timestamp : TDateTime; const text : string; debugLevel : integer = 0); virtual; abstract;
	end;
  
	GConsoleLogWriter = class(GConsoleWriter)
	private
		logFile : textfile;

	public
		constructor Create(moduleName : string);
		destructor Destroy(); override;
	
		procedure write(timestamp : TDateTime; const text : string; debugLevel : integer = 0); override;
	end;

	GConsole = class(GSingleton)
	private
		writers : GDLinkedList;
		history : GDLinkedList;
		queue : GDLinkedList;
		
		synchronizer : TMultiReadExclusiveWriteSynchronizer;

	public
		constructor actualCreate(); override;
		destructor actualDestroy(); override;

	published
		procedure write(const text : string; debugLevel : integer = 0);
		procedure poll();

		procedure attachWriter(writer : GConsoleWriter);
		procedure detachWriter(writer : GConsoleWriter);

		procedure fetchHistory(callback : GConsoleWriter; max : integer = 0);
	end;

  
procedure writeConsole(const text : string; debugLevel : integer = 0);
procedure pollConsole();


implementation


uses
	mudsystem,
	fsys,
	debug,
	server;


type
	GConsoleHistoryElement = class
	private
		_timestamp : TDateTime;
		_text : string;
		_debugLevel : integer;

	public
		property timestamp : TDateTime read _timestamp write _timestamp;
		property text : string read _text write _text;
		property debugLevel : integer read _debugLevel write _debugLevel;
	end;
  

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
	
	synchronizer := TMultiReadExclusiveWriteSynchronizer.Create();
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
	
	synchronizer.Free();
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
procedure GConsole.write(const text : string; debugLevel : integer = 0);
var
	he : GConsoleHistoryElement;
	timestamp : TDateTime;
begin
	// lock write
	synchronizer.BeginWrite();
	
	timestamp := Now();

	he := GConsoleHistoryElement.Create();
	he.timestamp := timestamp;
	he.text := text;
	he.debugLevel := debugLevel;
	history.add(he);

	if (history.size() > CONSOLE_HISTORY_MAX) then
		begin
		he := GConsoleHistoryElement(history.head.element);
		history.remove(history.head);
		he.Free();
		end;

	he := GConsoleHistoryElement.Create();
	he.timestamp := timestamp;
	he.text := text;
	he.debugLevel := debugLevel;
	queue.add(he);
  
	if (not serverBooted) then
		poll();

	// unlock write
	synchronizer.EndWrite();
end;

{ Poll the console }
procedure GConsole.poll();
var
	he : GConsoleHistoryElement;
	queue_iterator, iterator : GIterator;
	writer : GConsoleWriter;
begin
	// lock read
	synchronizer.BeginRead();

	queue_iterator := queue.iterator();
	
	while (queue_iterator.hasNext()) do
		begin
		he := GConsoleHistoryElement(queue_iterator.next());
	
  		iterator := writers.iterator();
  
		while (iterator.hasNext()) do
			begin
			writer := GConsoleWriter(iterator.next());
			
			writer.write(he.timestamp, he.text, he.debugLevel);
			end;    

		iterator.Free();	
		end;
	
	queue_iterator.Free();

	// unlock read
	synchronizer.EndRead();
	
	// lock write
	synchronizer.BeginWrite();
	
	queue.clear();
	
	// unlock write
	synchronizer.EndWrite();
end;

{ Fetch (up to) max items from the history and feed them to callback }
procedure GConsole.fetchHistory(callback : GConsoleWriter; max : integer = 0);
var
	iterator : GIterator;
	he : GConsoleHistoryElement;
	count : integer;
begin
	// lock read
	synchronizer.BeginRead();

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

	// unlock read
	synchronizer.EndRead();
end;

procedure writeConsole(const text : string; debugLevel : integer = 0);
begin
	cons.write(text, debugLevel);
end;

procedure pollConsole();
begin
	cons.poll();
end;


{ GConsoleLogWriter constructor }
constructor GConsoleLogWriter.Create(moduleName : string);
begin
	inherited Create();

	{ open a standard log file, filename is given by current system time }
	AssignFile(logFile, translateFileName('logs\' + moduleName + '-' + FormatDateTime('yyyymmdd-hhnnss', Now) + '.log'));

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
procedure GConsoleLogWriter.write(timestamp : TDateTime; const text : string; debugLevel : integer = 0);
begin
	if (TTextRec(logfile).mode = fmOutput) then
		begin
		system.writeln(logfile, '[' + FormatDateTime('yyyymmdd hh:nn:ss', Now) + '] ' + text);
		system.flush(logfile);
		end;
end;


initialization
	cons := GConsole.Create();
	
finalization
	FreeAndNil(cons);
	
end.
