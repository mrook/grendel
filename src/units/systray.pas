{
  @abstract(System tray icon routines)
  @lastmod($Id: systray.pas,v 1.1 2003/12/12 13:20:09 ***REMOVED*** Exp $)
}

unit systray;

interface

type
  GMenuCallBack = procedure(id : integer);

procedure registerSysTray();
procedure unregisterSysTray();

procedure addMenuSeparator();
procedure registerMenuItem(name : string; callback : GMenuCallBack);
procedure unregisterMenuItem(name : string);

procedure initSysTray();
procedure cleanupSysTray();

implementation

uses
  SysUtils,
  Windows,
  Messages,
  ShellAPI,
  Forms,
  dtypes,
  mudsystem,
  constants;


const
  WM_TASKICON = WM_USER + 14;
  taskIconID = 10;
  
  
type
  GSysTray = class
  private
    icon : TNotifyIconData;
    handle : HWND;
       
    procedure windowHandler(var msg : TMessage);
    
    procedure WMLButtonUp(var Mess: TMessage); message WM_LBUTTONUP;
    procedure WMLButtonDown(var Mess: TMessage); message WM_LBUTTONDOWN;
    procedure WMLButtonDblClk(var Mess: TMessage); message WM_LBUTTONDBLCLK;
    
    procedure WMRButtonUp(var Mess: TMessage); message WM_RBUTTONUP;
    procedure WMRButtonDown(var Mess: TMessage); message WM_RBUTTONDOWN;
    procedure WMRButtonDblClk(var Mess: TMessage); message WM_RBUTTONDBLCLK;
    
    procedure WMCommand(var Mess : TMessage); message WM_COMMAND;

  public
    constructor Create();
    destructor Destroy; override;
  end;
  
  GMenuItem = class
  public
    id : integer;
    name : string;
    callback : GMenuCallBack;
  end;
  
var
  sys : GSysTray;
  menuitems : GDLinkedList;
  menu : HMENU;
 
  
procedure GSysTray.windowHandler(var msg : TMessage);
var
  TempMess: TMessage;
begin
  msg.Result := 1;
  
  if (msg.WParam = taskIconID) then
    begin
    TempMess.Msg := msg.LParam;
    TempMess.WParam := msg.WParam;
    Dispatch(TempMess);
    end
  else
    Dispatch(msg);
end;

constructor GSysTray.Create();
begin
  inherited Create();
   
  handle := AllocateHWnd(windowHandler); 
   
  with icon do
    begin
    cbSize              := SizeOf(TNotifyIconData);
    Wnd                 := handle;
    uID                 := taskIconID;
    uFlags              := NIF_MESSAGE OR NIF_TIP OR NIF_ICON;
    uCallbackMessage    := WM_TASKICON;
    hIcon               := Application.Icon.Handle;
    szTip               := version_info;
    end;

  Shell_NotifyIcon(NIM_ADD, @icon);
end;

destructor GSysTray.Destroy();
begin
  Shell_NotifyIcon(NIM_DELETE, @icon); 

  DeAllocateHWnd(handle);

  inherited Destroy();
end;

procedure GSysTray.WMLButtonUp(var Mess: TMessage);
begin
end;

procedure GSysTray.WMLButtonDown(var Mess: TMessage);
begin
end;

procedure GSysTray.WMLButtonDblClk(var Mess: TMessage);
begin
end;

procedure GSysTray.WMRButtonUp(var Mess: TMessage);
begin
end;

procedure GSysTray.WMRButtonDown(var Mess: TMessage);
var
  coord : TPoint;
begin
  SetForegroundWindow(handle);

  GetCursorPos(coord);
  
  TrackPopupMenu(menu, TPM_RIGHTBUTTON, coord.x, coord.y, 0, handle, nil);
  
  PostMessage(handle, WM_NULL, 0, 0); 
  
  Mess.Result := 0;
end;

procedure GSysTray.WMRButtonDblClk(var Mess: TMessage);
begin
end;

procedure GSysTray.WMCommand(var Mess : TMessage);
var
  iterator : GIterator;
  item : GMenuItem;
  id : integer;
begin
  id := LOWORD(Mess.WParam);
  iterator := menuitems.iterator();
  
  while (iterator.hasNext()) do
    begin
    item := GMenuItem(iterator.next());
    
    if (item.id = id) then
      begin
      item.callback(id);
      Mess.Result := 0;
      break;
      end;
    end;

  iterator.Free();
end;

procedure registerSysTray();
begin
  sys := GSysTray.Create();
end;

procedure unregisterSysTray();
begin
  sys.Free();
end;


function getFreeMenuID() : integer;
var
  iterator : GIterator;
  item : GMenuItem;
  id : integer;
begin
  iterator := menuitems.iterator();
  id := -1;
  
  while (iterator.hasNext()) do
    begin
    item := GMenuItem(iterator.next());
    
    if (item.id > id) then
      id := item.id;
    end;
    
  iterator.Free();
  
  Result := id + 1;
end;

procedure addMenuSeparator();
begin
  InsertMenu(menu, 0, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
end;

procedure registerMenuItem(name : string; callback : GMenuCallBack);
var
  item : GMenuItem;
begin
  item := GMenuItem.Create();
  
  item.id := getFreeMenuID();
  item.name := name;
  item.callback := callback;
  
  InsertMenu(menu, 0, MF_BYPOSITION or MF_ENABLED or MF_STRING, item.id, PChar(item.name));
  
  menuitems.insertLast(item);
end;

procedure unregisterMenuItem(name : string);
var
  node : GListNode;
  item : GMenuItem;
begin
  node := menuitems.head;
  
  while (node <> nil) do
    begin
    item := GMenuItem(node.element);
    
    if (item.name = name) then
      begin
      RemoveMenu(menu, item.id, MF_BYCOMMAND);
      menuitems.remove(node);
      item.Free();
      
      break;
      end;
    
    node := node.next;
    end;
end;


procedure aboutProc(id : integer);
begin
  MessageBox(0, version_info + ',' + version_number + '.'#13#10#13#10 + version_copyright + '.'#13#10#13#10 + 'This is free software, with ABSOLUTELY NO WARRANTY; view LICENSE.TXT.', 'About ' + version_info, MB_OK or MB_SETFOREGROUND);
end;

procedure copyoverProc(id : integer);
begin
  boot_info.timer := 1;
  boot_info.started_by := nil;
  boot_info.boot_type := BOOTTYPE_COPYOVER;
end;

procedure rebootProc(id : integer);
begin
  boot_info.timer := 1;
  boot_info.started_by := nil;
  boot_info.boot_type := BOOTTYPE_REBOOT;
end;

procedure shutdownProc(id : integer);
begin
  boot_info.timer := 1;
  boot_info.started_by := nil;
  boot_info.boot_type := BOOTTYPE_SHUTDOWN;
end;


procedure initSysTray();
begin
  menu := CreatePopupMenu();
  menuitems := GDLinkedList.Create();

  registerMenuItem('Shutdown', shutdownProc);
  registerMenuItem('Reboot', rebootProc);
  registerMenuItem('Copyover', copyoverProc);
  addMenuSeparator();
  registerMenuItem('About', aboutProc);
  addMenuSeparator();
end;
  
procedure cleanupSysTray();
begin
  DestroyMenu(menu);
  
  menuitems.clean();
  menuitems.Free();
end;
  
end.
