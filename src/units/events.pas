{
  Summary:
    System events
  
  ##  $Id: events.pas,v 1.2 2004/02/27 22:24:21 ***REMOVED*** Exp $
}

unit events;

interface

uses
	dtypes,
	console;


type
	GEventHandlerFunc = function(const eventname : string; eventobject : TObject) : boolean;


var
	eventList : GHashTable;


procedure registerEvent(const name : string);
procedure unregisterEvent(const name : string);
	
procedure registerEventHandler(const name : string; handler_func : GEventHandlerFunc);
procedure unregisterEventHandler(const name : string; handler_func : GEventHandlerFunc);

procedure raiseEvent(const name : string; eventobject : TObject);

procedure initEvents();
procedure cleanupEvents();


implementation


uses
	SysUtils;


type
	GEventHandler = class
		func : GEventHandlerFunc;
		node : GListNode;
	end;
	

procedure registerEvent(const name : string);
var
	list : GDLinkedList;
begin
	list := GDLinkedList.Create();
	
	eventList[name] := list;
end;

procedure unregisterEvent(const name : string);
var
	list : GDLinkedList;
begin
	list := GDLinkedList(eventList[name]);
	
	if (list <> nil) then
		begin
		list.clean();
		list.Free();
		eventList.remove(name);
		end;
end;

procedure registerEventHandler(const name : string; handler_func : GEventHandlerFunc);
var
	handler : GEventHandler;
	list : GDLinkedList;
begin
	list := GDLinkedList(eventList[name]);
	
	if (list = nil) then
		raise Exception.Create('Unknown event ' + name)
	else
		begin
		handler := GEventHandler.Create();
		handler.func := handler_func;
		handler.node := list.insertLast(handler);
		end;
end;

procedure unregisterEventHandler(const name : string; handler_func : GEventHandlerFunc);
var
	handler : GEventHandler;
	list : GDLinkedList;
	iterator : GIterator;
	found : boolean;
begin
	list := GDLinkedList(eventList[name]);
	
	if (list = nil) then
		raise Exception.Create('Unknown event ' + name)
	else
		begin
		iterator := list.iterator();
		found := false;

		while (iterator.hasNext()) do
			begin
			handler := GEventHandler(iterator.next());

			if (@handler.func = @handler_func) then
				begin
				list.remove(handler.node);
				handler.Free();
				found := true;
				break;
				end;
			end;

		iterator.Free();

		if (not found) then
			raise Exception.Create('Event handler not found for "' + name + '"');
		end;
end;

procedure raiseEvent(const name : string; eventobject : TObject);
var
	list : GDLinkedList;
	iterator : GIterator;
	handler : GEventHandler;
begin
	list := GDLinkedList(eventList[name]);
	
	if (list = nil) then
		raise Exception.Create('Unknown event ' + name)
	else
		begin
		iterator := list.iterator();

		while (iterator.hasNext()) do
			begin
			handler := GEventHandler(iterator.next());

			handler.func(name, eventobject);
			end;

		iterator.Free();
		end;
end;

procedure initEvents();
begin
	eventList := GHashTable.Create(128);
  
	// default events
	registerEvent('char-login');
	registerEvent('char-logout');
	registerEvent('char-look-char');
	registerEvent('char-look-object');
	registerEvent('char-look-room');
	registerEvent('mud-boot');
	registerEvent('mud-shutdown');
	registerEvent('room-enter');
	registerEvent('room-leave');
end;

procedure cleanupEvents();
begin
	eventList.clear();
	eventList.Free();
end;

end.
