{
  Summary:
    System events
  
  ##  $Id: events.pas,v 1.1 2003/11/05 11:28:29 ***REMOVED*** Exp $
}

unit events;

interface

uses
	dtypes,
	console;


type
	GEventFunc = function(eventname : string; var eventobject) : boolean;


var
	eventList : GHashTable;


procedure registerEvent(name : string);
procedure unregisterEvent(name : string);
	
procedure registerEventHandler(name : string; handler : GEventFunc);
procedure unregisterEventHandler(name : string; handler : GEventFunc);

procedure raiseEvent(name : string; var eventobject);

procedure initEvents();
procedure cleanupEvents();


implementation


uses
	SysUtils;
	

procedure registerEvent(name : string);
var
	list : GDLinkedList;
begin
	list := GDLinkedList.Create();
	
	eventList[name] := list;
end;

procedure unregisterEvent(name : string);
var
	list : GDLinkedList;
begin
	list := GDLinkedList(eventList[name]);
	
	if (list <> nil) then
		eventList.remove(name);
end;

procedure registerEventHandler(name : string; handler : GEventFunc);
begin
end;

procedure unregisterEventHandler(name : string; handler : GEventFunc);
begin
end;

procedure raiseEvent(name : string; var eventobject);
var
	list : GDLinkedList;
	handler : GEventFunc;
begin
	list := GDLinkedList(eventList[name]);
	
	if (list = nil) then
		raise Exception.Create('Unknown event ' + name);
		
	handler(name, eventobject);
end;

procedure initEvents();
begin
  eventList := GHashTable.Create(128);
end;

procedure cleanupEvents();
begin
  eventList.clear();
	eventList.Free();
end;

end.
