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


var
  writers : GDLinkedList;

  
procedure registerConsoleDriver(writer : GConsoleWriter);

procedure writeConsole(text : string);


implementation


procedure registerConsoleDriver(writer : GConsoleWriter);
begin
  writers.insertLast(writer);
end;

procedure writeConsole(text : string);
var
  iterator : GIterator;
  writer : GConsoleWriter;
  timestamp : TDateTime;
begin
  timestamp := Now();
  iterator := writers.iterator();
  
  while (iterator.hasNext()) do
    begin
    writer := GConsoleWriter(iterator.next());
    
    writer.write(timestamp, text);
    end;
end;


procedure GConsoleWriter.write(timestamp : TDateTime; text : string);
begin
end;


initialization
  writers := GDLinkedList.Create();

finalization
  writers.clean();
  writers.Free();

end.
