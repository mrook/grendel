{
	Summary:
  	Abstract console interface
  	
  ##	$Id: console.pas,v 1.3 2004/02/27 22:24:21 ***REMOVED*** Exp $
}

unit console;

interface

uses
  SysUtils,
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
  public
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


const
  CONSOLE_HISTORY_MAX = 200;
  

var
  writers : GDLinkedList;
  history : GDLinkedList;
  queue : GDLinkedList;
  LogFile : textfile;

  
procedure registerConsoleDriver(writer : GConsoleWriter);
procedure unregisterConsoleDriver(writer : GConsoleWriter);
procedure writeConsole(const text : string);
procedure fetchConsoleHistory(max : integer; callback : GConsoleWriter);
procedure pollConsole();

procedure initConsole();
procedure cleanupConsole();

implementation

uses
	mudsystem,
	fsys;


procedure registerConsoleDriver(writer : GConsoleWriter);
begin
  writers.insertLast(writer);
end;

procedure unregisterConsoleDriver(writer : GConsoleWriter);
var
  node : GListNode;
begin
  node := writers.head;
  
  while (node <> nil) do
    begin
    if (node.element = writer) then
      begin
      writers.remove(node);
      exit;
      end;
      
    node := node.next;
    end;
end;

procedure writeConsole(const text : string);
var
  he : GConsoleHistoryElement;
  timestamp : TDateTime;
begin
  timestamp := Now();

  he := GConsoleHistoryElement.Create();
  he.timestamp := timestamp;
  he.text := text;
  history.insertLast(he);

  if (history.size() > CONSOLE_HISTORY_MAX) then
  	begin
  	GConsoleHistoryElement(history.head.element).Free();
    history.remove(history.head);
    end;
    
  he := GConsoleHistoryElement.Create();
  he.timestamp := timestamp;
  he.text := text;
  queue.insertLast(he);
  
  if (not mud_booted) or (system_info.terminated) then
  	pollConsole();
end;

procedure pollConsole();
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

procedure fetchConsoleHistory(max : integer; callback : GConsoleWriter);
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


// GConsoleDefault
procedure GConsoleDefault.write(timestamp : TDateTime; const text : string);
begin
{$IFDEF CONSOLEBUILD}
  writeln('[' + FormatDateTime('hh:nn', Now) + '] ', text);
{$ENDIF}
end;

procedure GConsoleLogWriter.write(timestamp : TDateTime; const text : string);
begin
  if (TTextRec(logfile).mode = fmOutput) then
    begin
    system.writeln(logfile, '[' + FormatDateTime('yyyymmdd hh:nn:ss', Now) + '] ' + text);
    system.flush(logfile);
    end;
end;

procedure initConsole();
begin
  writers := GDLinkedList.Create();
  queue := GDLinkedList.Create();
  history := GDLinkedlist.Create();
  registerConsoleDriver(GConsoleDefault.Create());
  registerConsoleDriver(GConsoleLogWriter.Create());
  
  { open a standard log file, filename is given by current system time }
  AssignFile(LogFile, translateFileName('logs\' + FormatDateTime('yyyymmdd-hhnnss', Now) + '.log'));

  {$I-}
  rewrite(LogFile);
  {$I+}

  if (IOResult <> 0) then
    writeConsole('NOTE: Could not open logfile. Messages are not being logged.');
end;

procedure cleanupConsole();
begin
	pollConsole();
	
  if (TTextRec(logfile).mode = fmOutput) then
    CloseFile(LogFile);

  writers.clean();
  writers.Free();

  queue.clean();
  queue.Free();
  
  history.clean();
  history.Free();
end;

end.
