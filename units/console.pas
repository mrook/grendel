{
  @abstract(Abstract console interface)
  @lastmod($Id)
}

unit console;

interface

uses
  SysUtils,
  dtypes;
  

type
  GConsoleWriter = class
  public
    procedure write(timestamp : TDateTime; text : string); virtual;
  end;
  
  GConsoleDefault = class(GConsoleWriter)
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

  
procedure registerConsoleDriver(writer : GConsoleWriter);
procedure unregisterConsoleDriver(writer : GConsoleWriter);
procedure writeConsole(text : string);
procedure fetchConsoleHistory(max : integer; callback : GConsoleWriter);

procedure initConsole();
procedure cleanupConsole();

implementation

uses
  mudsystem;


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


// GConsoleWriter
procedure GConsoleWriter.write(timestamp : TDateTime; text : string);
begin
end;

// GConsoleDefault
procedure GConsoleDefault.write(timestamp : TDateTime; text : string);
begin
  writeLog(text);
  
{$IFDEF CONSOLEBUILD}
  writeln(FormatDateTime('[tt] ', timestamp) + text);
{$ENDIF}
{$IFDEF LINUX}
  writeln(FormatDateTime('[tt] ', timestamp) + text);
{$ENDIF}
end;

procedure initConsole();
begin
  writers := GDLinkedList.Create();
  history := GDLinkedlist.Create();
  
  registerConsoleDriver(GConsoleDefault.Create());
end;

procedure cleanupConsole();
begin
  writers.clean();
  writers.Free();
  
  history.clean();
  history.Free();
end;

end.
