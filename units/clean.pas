// $Id: clean.pas,v 1.7 2001/04/29 16:55:41 xenon Exp $

unit clean;

interface

uses
    Windows,
    Classes;

{ This is the misc. thread function, also known as the 'simple task thread'.
  This thread takes care of autosaves and autocleans,
  and serves as a watchdog for both the timer thread and the individual
  user threads. }

type GCleanThread = class(TThread)
     private
       t_log : string;

     protected
       procedure AutoSave;
       procedure SyncWrite;
       procedure SyncWritelog(s:string);
       procedure Execute; override;

     public
       constructor Create;
     end;

implementation

uses
    SysUtils,
    chars,
    conns,
    constants,
    dtypes,
    area,
    util,
    timers,
    Winsock2,
    mudthread,
    mudsystem;

constructor GCleanThread.Create;
begin
  inherited Create(false);

  SyncWritelog('Started cleanup thread.');
  SetThreadPriority(Handle, THREAD_PRIORITY_IDLE);
  freeonterminate := true;
end;

procedure GCleanThread.SyncWrite;
begin
  write_console(t_log);
end;

procedure GCleanThread.SyncWritelog(s:string);
begin
  t_log := s;
  Synchronize(SyncWrite);
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
      ch.save(ch.name^);

    node := node.next;
    end;
end;

// kill a non-responsive thread after 30 seconds
const
     THREAD_TIMEOUT = 0.5 / 1440.0;

procedure GCleanThread.Execute;
var
   a : integer;
   node, node_next : GListNode;
   conn : GConnection;
begin
  a := 0;
  repeat
    sleep(10000);

    inc(a);

    if (a = 15) then
      begin
      AutoSave;
      a := 0;
      end;

    node := connection_list.head;

    while (node <> nil) do
      begin
      node_next := node.next;
      conn := node.element;

{$IFNDEF NOCRASHDETECTION}
      if (GGameThread(conn.thread).last_update + THREAD_TIMEOUT < Now()) then
        begin
        bugreport('update_main', 'timers.pas', 'Thread of ' + conn.ch.name^ + ' probably died',
                  'The server has detected a malfunctioning user thread and will terminate it.');

        conn.ch.emptyBuffer;

        conn.send('Your previous command possibly triggered an illegal action on this server.'#13#10);
        conn.send('The administration has been notified, and you have been disconnected'#13#10);
        conn.send('to prevent any data loss.'#13#10);
        conn.send('Your character is linkless, and it would be wise to reconnect as soon'#13#10);
        conn.send('as possible.'#13#10);

        closesocket(conn.socket);

        conn.ch.conn := nil;

        act(AT_REPORT,'$n has lost $s link.',false,conn.ch,nil,nil,TO_ROOM);
        SET_BIT(conn.ch.player^.flags,PLR_LINKLESS);

        conn.Free;

        TerminateThread(conn.thread.handle, 1);

        node := node_next;
        continue;
        end;
{$ENDIF}
        
      node := node_next;
      end;

    if (GTimerThread(timer_thread).last_update + THREAD_TIMEOUT < Now()) then
      begin
      bugreport('update_main', 'timers.pas', 'Timer thread probably died',
                'The server has detected that the timer is malfunctioning and will try to restart it.');

      TerminateThread(timer_thread.handle, 1);

      timer_thread := GTimerThread.Create;
      end;

    cleanChars;
    cleanObjects;
  until (Terminated);

  SyncWritelog('Simple task thread terminated.');
end;

end.
