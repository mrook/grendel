unit clean;

interface

uses
    Windows,
    Classes;

{ This is the misc. thread function, also known as the 'simple task thread'.
  This thread performs some low-priority functions, such as console/immortal
  reboots/shutdowns, loading of background images, etc.
  This thread also takes care of autosaves, which are generated by the timer,
  to prevent excessive data loss with hard crashes.
  This all happens on the background as to relieve the server main thread. - Grimlord }

type GCleanThread = class(TThread)
     private
       t_message:integer;
       t_log:string;

     protected
       procedure StopMud;
       procedure BootMsg;
       procedure AutoSave;
       procedure SyncProc;
       procedure SyncWritelog(s:string);
       procedure Execute; override;

     public
       procedure SetMessage(msg:integer);
       constructor Create;
     end;

implementation

uses
    SysUtils,
    chars,
    conns,
    constants,
    dtypes,
    mudsystem;

constructor GCleanThread.Create;
begin
  inherited Create(false);

  SyncWritelog('Started cleanup thread.');
  t_message:=0;
  SetThreadPriority(Handle,THREAD_PRIORITY_IDLE);
  freeonterminate := true;
end;

procedure GCleanThread.SyncProc;
begin
  write_console(t_log);
end;

procedure GCleanThread.SyncWritelog(s:string);
begin
  t_log:=s;
  Synchronize(SyncProc);
end;

procedure GCleanThread.SetMessage(msg:integer);
begin
  t_message:=msg;
end;

procedure GCleanThread.BootMsg;
begin
  case boot_info.boot_type of
    BOOTTYPE_SHUTDOWN:begin
                      SyncWritelog(inttostr(boot_info.timer)+' seconds till shutdown');
                      to_channel(nil, '$B$1 ---- Server $3shutdown$1 in $7' + inttostr(boot_info.timer) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
                      end;
      BOOTTYPE_REBOOT:begin
                      SyncWritelog(inttostr(boot_info.timer)+' seconds till reboot');
                      to_channel(nil, '$B$1 ---- Server $3reboot$1 in $7' + inttostr(boot_info.timer) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
                      end;
    BOOTTYPE_COPYOVER:begin
                      SyncWritelog(inttostr(boot_info.timer)+' seconds till reboot');
                      to_channel(nil, '$B$1 ---- Server $3copyover$1 in $7' + inttostr(boot_info.timer) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
                      end;
  end;
end;

procedure GCleanThread.StopMud;
begin
  case boot_info.boot_type of
    BOOTTYPE_SHUTDOWN:begin
                      SyncWritelog('Timer reached zero, starting shutdown now');
                      to_channel(nil, '$B$1 ---- Server will $3shutdown $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
                      end;
      BOOTTYPE_REBOOT:begin
                      SyncWritelog('Timer reached zero, starting reboot now');
                      to_channel(nil, '$B$1 ---- Server will $3reboot $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
                      end;
    BOOTTYPE_COPYOVER:begin
                      SyncWritelog('Timer reached zero, starting copyover now');
                      to_channel(nil, '$B$1 ---- Server will $3copyover $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
                      end;
  end;
  boot_type:=boot_info.boot_type;
  grace_exit:=true;
  halt;
end;

procedure GCleanThread.AutoSave;
var
   ch : GCharacter;
   node : GListNode;
begin
  SyncWritelog('Autosaving characters...');

  node := char_list.head;

  while (node <> nil) do
    begin
    ch := node.element;

    if (not ch.IS_NPC) then
      ch.save(ch.name);

    node := node.next;
    end;
end;

procedure GCleanThread.Execute;
var msg:TMsg;
begin
  freeonterminate:=true;
  repeat
    if (t_message>0) then
      begin
      case t_message of
       CLEAN_BOOT_MSG:BootMsg;
       CLEAN_MUD_STOP:StopMud;
           CLEAN_STOP:Terminate;
       CLEAN_AUTOSAVE:AutoSave;
      end;
      t_message:=0;
      end;

    sleep(500);
  until (Terminated);
  SyncWritelog('Simple task thread terminated.');
end;

end.
