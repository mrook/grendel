{
  @abstract(Abstract console interface)
  @lastmod($Id: console.pas,v 1.7 2003/10/02 15:53:23 ***REMOVED*** Exp $)
}

unit console;

interface

uses
  SysUtils,
  dtypes;
  

type
  GConsoleWriter = class
  public
    procedure write(timestamp : TDateTime; text : string); virtual; abstract;
  end;
  
  GConsoleDefault = class(GConsoleWriter)
  public
    procedure write(timestamp : TDateTime; text : string); override;
  end;

  GConsoleLogWriter = class(GConsoleWriter)
  public
    procedure write(timestamp : TDateTime; text : string); override;
  end;
  
  GConsoleHistoryElement = class
  public
    timestamp : TDateTime;
    text : string;
  end;


const
  CONSOLE_HISTORY_MAX = 200;
  

var
  writers : GDLinkedList;
  history : GDLinkedList;
  LogFile : textfile;

  
procedure registerConsoleDriver(writer : GConsoleWriter);
procedure unregisterConsoleDriver(writer : GConsoleWriter);
procedure writeConsole(text : string);
procedure fetchConsoleHistory(max : integer; callback : GConsoleWriter);

procedure initConsole();
procedure cleanupConsole();

implementation

uses
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
      break;
      end;
      
    node := node.next;
    end;
end;

procedure writeConsole(text : string);
var
  iterator : GIterator;
  he : GConsoleHistoryElement;
  writer : GConsoleWriter;
  timestamp : TDateTime;
begin
  timestamp := Now();

  he := GConsoleHistoryElement.Create();
  he.timestamp := timestamp;
  he.text := text;
  history.insertLast(he);

  if (history.getSize() > CONSOLE_HISTORY_MAX) then
    history.remove(history.head);

  iterator := writers.iterator();
  
  while (iterator.hasNext()) do
    begin
    writer := GConsoleWriter(iterator.next());
    
    writer.write(timestamp, text);
    end;    
   
  iterator.Free();
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
procedure GConsoleDefault.write(timestamp : TDateTime; text : string);
begin
{$IFDEF CONSOLEBUILD OR LINUX}
  writeln(text);
{$ENDIF}
end;

procedure GConsoleLogWriter.write(timestamp : TDateTime; text : string);
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
  if (TTextRec(logfile).mode = fmOutput) then
    CloseFile(LogFile);

  writers.clean();
  writers.Free();
  
  history.clean();
  history.Free();
end;

end.
