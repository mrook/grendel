unit systray;

interface

procedure registerSysTray();
procedure unregisterSysTray();

implementation

uses
  SysUtils,
  Windows,
  Messages,
  ShellAPI,
  Forms,
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
    
    menu : HMENU;
    
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
  
var
  sys : GSysTray;
 
  
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
  
  menu := CreatePopupMenu();
  AppendMenu(menu, MF_ENABLED or MF_STRING, 1, PChar('Open console'));
  AppendMenu(menu, MF_ENABLED or MF_STRING, 2, PChar('About'));
  AppendMenu(menu, MF_SEPARATOR, 0, nil);
  AppendMenu(menu, MF_ENABLED or MF_STRING, 20, PChar('Reboot'));
  AppendMenu(menu, MF_ENABLED or MF_STRING, 21, PChar('Shutdown'));

  handle := AllocateHWnd(windowHandler);
  
  SetMenu(handle, menu);
   
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
begin
  case LOWORD(Mess.WParam) of 
    2 : MessageBox(handle, version_info + ',' + version_number + '.'#13#10#13#10 + version_copyright + '.'#13#10#13#10 + 'This is free software, with ABSOLUTELY NO WARRANTY; view LICENSE.TXT.', 'About ' + version_info, MB_OK or MB_SETFOREGROUND);
    20 : begin
         boot_info.timer := 1;
         boot_info.started_by := nil;
         boot_info.boot_type := BOOTTYPE_REBOOT;
         end;
    21 : begin
         boot_info.timer := 1;
         boot_info.started_by := nil;
         boot_info.boot_type:=BOOTTYPE_SHUTDOWN;
         end;
  end;
    
  Mess.Result := 0;
end;

procedure registerSysTray();
begin
  sys := GSysTray.Create();
end;

procedure unregisterSysTray();
begin
  sys.Free();
end;


end.
