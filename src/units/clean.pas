{
	Summary:
		Cleaning (system janitor) thread
	
	## $Id: clean.pas,v 1.9 2004/04/10 22:24:03 ***REMOVED*** Exp $
}

unit clean;

interface

uses
{$IFDEF Win32}
	Windows,
{$ENDIF}
	Classes;

{ This is the misc. thread function, also known as the 'simple task thread'.
  This thread takes care of autosaves and autocleans,
  and serves as a watchdog for both the timer thread and the individual
  user threads. }

type 
	GCleanThread = class(TThread)
	protected
		procedure AutoSave();
		procedure Execute; override;

	public
		constructor Create();
	end;


implementation

uses
{$IFDEF LINUX}
	Libc,
{$ENDIF}
	SysUtils,
	chars,
	player,
	console,
	mudsystem,
	constants,
	timers,
	util,
	conns,
	dtypes,
	debug;
	

constructor GCleanThread.Create();
begin
  inherited Create(false);

  writeConsole('Started cleanup thread.');
{$IFDEF WIN32}
  SetThreadPriority(Handle, THREAD_PRIORITY_IDLE);
{$ENDIF}
  freeonterminate := true;
end;

procedure GCleanThread.AutoSave();
var
	ch : GCharacter;
	iterator : GIterator;
begin
  writeConsole('Autosaving characters...');

  iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    ch := GCharacter(iterator.next());

    if (not ch.IS_NPC) then
      GPlayer(ch).save(ch.name);
    end;
  
  iterator.Free();
end;

// kill a non-responsive thread after 30 seconds
const
     THREAD_TIMEOUT = 0.5 / 1440.0;

procedure GCleanThread.Execute;
var
   a : integer;
   node, node_next : GListNode;
   conn : GPlayerConnection;
begin
  a := 0;
  repeat
    try
      sleep(10000);

      inc(a);

      if (a = 15) then
        begin
        AutoSave();
        a := 0;
        end;
  
      {$IFNDEF NOCRASHDETECTION}
      node := connection_list.head;

      while (node <> nil) do
        begin
        node_next := node.next;
        conn := GPlayerConnection(node.element);
        
        if (conn.last_update = 0) then
        	begin
        	writeConsole('Stale thread detected, system is unstable!');
        	end
        else
        if (conn.last_update + THREAD_TIMEOUT < Now()) then
          begin
          bugreport('GCleanThread.Execute', 'clean.pas', 'Thread of ' + conn.ch.name + ' probably died (last update at: ' + TimeToStr(conn.last_update) + ')');
          
          conn.ch.emptyBuffer();

          conn.send('Your previous command possibly triggered an illegal action on this server.'#13#10);
          conn.send('The administration has been notified, and you have been disconnected'#13#10);
          conn.send('to prevent any data loss.'#13#10);
          conn.send('Your character is linkless, and it would be wise to reconnect as soon'#13#10);
          conn.send('as possible.'#13#10);

          conn.ch.conn := nil;

          act(AT_REPORT,'$n has lost $s link.',false,conn.ch,nil,nil,TO_ROOM);
          SET_BIT(conn.ch.flags,PLR_LINKLESS);

          conn.Free();

          {$IFDEF LINUX}
          pthread_kill(conn.ThreadID, 9);
          {$ENDIF}
          {$IFDEF WIN32}
          TerminateThread(conn.handle, 1);
          {$ENDIF}

          node := node_next;
          continue;
          end;

        node := node_next;
        end;
      {$ENDIF}

      if (GTimerThread(timer_thread).lastUpdate + THREAD_TIMEOUT < Now()) then
        begin
        bugreport('GCleanThread.Execute', 'clean.pas', 'Timer thread probably died');

        {$IFDEF LINUX}
        pthread_kill(timer_thread.ThreadID, 9);
        {$ENDIF}
        {$IFDEF WIN32}
        TerminateThread(timer_thread.handle, 1);
        {$ENDIF}

        timer_thread := GTimerThread.Create;
        end;

//      cleanExtractedChars();
    except
    	{$IFDEF LINUX}
    	on E : EQuit do break;
    	{$ENDIF}
    	on E : EControlC do break;
	on E : Exception do reportException(E);
    end;    
  until (Terminated); 
end;

end.
