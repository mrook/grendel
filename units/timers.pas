{
  @abstract(Timer class)
  @lastmod($Id: timers.pas,v 1.21 2003/10/02 15:53:23 ***REMOVED*** Exp $)
}

unit timers;

interface

uses
{$IFDEF WIN32}
    Windows,
{$ENDIF}
    SysUtils,
    Classes,
    skills,
    dtypes,
    chars;


type
    TIMER_FUNC = procedure;
    SPEC_FUNC = procedure(ch, victim : GCharacter; sn : GSkill);

    GTimer = class
      name : string;
      timer_func : TIMER_FUNC;
      counter, timeout : integer;
      looping : boolean;
	
      constructor Create(name_ : string; func_ : TIMER_FUNC; timeout_ : integer; looping_ : boolean);
    end;

    GSpecTimer = class (GTimer)
      spec_func : SPEC_FUNC;

      ch, victim : GCharacter;

      timer_type : integer;

      sn : GSkill;

      constructor Create(name_ : string; timer_type_ : integer; func_ : SPEC_FUNC; timeout_ : integer; ch_, victim_ : GCharacter; sn_ : GSkill);
    end;

    GTimerThread = class (TThread)
      last_update : TDateTime;

      procedure Execute; override;
      constructor Create;
    end;

var
   timer_list : GDLinkedList;

procedure registerTimer(name : string; func : TIMER_FUNC; timeout : integer; looping : boolean); overload;
procedure registerTimer(name : string; timer_type : integer; func : SPEC_FUNC; timeout : integer; ch, victim : GCharacter; sn : GSkill); overload;

procedure unregisterTimer(name_ : string); overload;
procedure unregisterTimer(ch : GCharacter; timer_type : integer); overload;

function hasTimer(ch : GCharacter; timer_type : integer) : GTimer; overload;
function hasTimer(ch : GCharacter; const timer_name : string) : GTimer; overload;

procedure initTimers();
procedure cleanupTimers();

implementation

uses
{$IFDEF WIN32}
    Winsock2,
{$ENDIF}
    constants,
    console,
    mudsystem,
    util,
    mudthread,
    update,
    area,
    conns,
    Channels;


// GTimer
constructor GTimer.Create(name_ : string; func_ : TIMER_FUNC; timeout_ : integer; looping_ : boolean);
begin
  inherited Create;

  Self.name := name_;
  Self.timer_func := func_;
  Self.timeout := timeout_;
  Self.counter := timeout_;
  Self.looping := looping_;
end;

// GSpecTimer
constructor GSpecTimer.Create(name_ : string; timer_type_ : integer; func_ : SPEC_FUNC; timeout_ : integer; ch_, victim_ : GCharacter; sn_ : GSkill);
begin
  inherited Create(name_, nil, timeout_, false);

  Self.spec_func := func_;
  Self.timer_type := timer_type_;
  Self.ch := ch_;
  Self.victim := victim_;
  Self.sn := sn_;
end;


// GTimerThread
constructor GTimerThread.Create;
begin
  inherited Create(false);

  last_update := Now();
end;

procedure GTimerThread.Execute;
var
   node, node_next : GListNode;
   timer : GTimer;
   spec : GSpecTimer;
begin
  while (not Terminated) do
    begin
    last_update := Now();

    node := timer_list.head;

    while (node <> nil) do
      begin
      timer := node.element;
      node_next := node.next;

      try
      dec(timer.counter);

      if (timer.counter = 0) then
        begin
        if (timer is GSpecTimer) then
          begin
          spec := GSpecTimer(timer);

          if (assigned(spec.spec_func)) then
            spec.spec_func(spec.ch, spec.victim, spec.sn);
          end
        else
          if (assigned(timer.timer_func)) then
            timer.timer_func;

        if (not timer.looping) then
          begin
          timer_list.remove(node);
          timer.Free;
          end
        else
          timer.counter := timer.timeout;
        end;

      except
{        on E : EExternal do
          begin
          bugreport('GTimerThread.Execute', 'timers.pas', 'Timer "' + timer.name + '" failed to execute correctly');
          outputError(E);
          end;
        on E : Exception do
          bugreport('GTimerThread.Execute', 'timers.pas', 'Timer "' + timer.name + '" failed: ' + E.Message)
        else }
        bugreport('GTimerThread.Execute', 'timers.pas', 'Timer "' + timer.name + '" failed to execute correctly');

{        if (timer is GSpecTimer) then
          begin
          timer_list.remove(node);
          timer.Free;
          end
        else
          timer.counter := timer.timeout; }
      end;

      node := node_next;
      end;

    Sleep(250);
    end;
end;

procedure registerTimer(name : string; func : TIMER_FUNC; timeout : integer; looping : boolean);
var
   timer : GTimer;
begin
  timer := GTimer.Create(name, func, timeout, looping);

  timer_list.insertLast(timer);
end;

procedure registerTimer(name : string; timer_type : integer; func : SPEC_FUNC; timeout : integer; ch, victim : GCharacter; sn : GSkill);
var
   timer : GSpecTimer;
begin
  timer := GSpecTimer.Create(name, timer_type, func, timeout, ch, victim, sn);

  timer_list.insertLast(timer);
end;

procedure unregisterTimer(name_ : string);
var
   timer : GTimer;
   node : GListNode;
begin
  node := timer_list.head;

  while (node <> nil) do
    begin
    timer := node.element;

    if (timer.name = name_) then
      begin
      timer_list.remove(node);
      timer.Free;
      break;
      end;

    node := node.next;
    end;
end;

procedure unregisterTimer(ch : GCharacter; timer_type : integer);
var
   timer : GTimer;
   spec : GSpecTimer;
   node : GListNode;
begin
  node := timer_list.head;

  while (node <> nil) do
    begin
    timer := node.element;

    if (timer is GSpecTimer) then
      begin
      spec := GSpecTimer(timer);

      if (spec.ch = ch) and (spec.timer_type = timer_type) then
        begin
        timer_list.remove(node);
        timer.Free;
        break;
        end;
      end;

    node := node.next;
    end;
end;

function hasTimer(ch : GCharacter; timer_type : integer) : GTimer;
var
   timer : GTimer;
   spec : GSpecTimer;
   node : GListNode;
begin
  Result := nil;

  node := timer_list.head;

  while (node <> nil) do
    begin
    timer := node.element;

    if (timer is GSpecTimer) then
      begin
      spec := GSpecTimer(timer);

      if (spec.ch = ch) and (spec.timer_type = timer_type) and (spec.counter > 0) then
        begin
        Result := timer;
        break;
        end;
      end;

    node := node.next;
    end;
end;

function hasTimer(ch : GCharacter; const timer_name : string) : GTimer;
var
   timer : GTimer;
   spec : GSpecTimer;
   node : GListNode;
begin
  Result := nil;

  node := timer_list.head;

  while (node <> nil) do
    begin
    timer := node.element;

    if (timer is GSpecTimer) then
      begin
      spec := GSpecTimer(timer);

      if (spec.ch = ch) and (spec.name = timer_name) and (spec.counter > 0) then
        begin
        Result := timer;
        break;
        end;
      end;

    node := node.next;
    end;
end;

// main timers
procedure update_auction;
begin
  if (auction_good.pulse > 0) then
    dec(auction_good.pulse)
  else
  if (auction_good.item <> nil) then
    begin
    auction_good.update;
    auction_good.pulse := CPULSE_AUCTION;
    end;

  if (auction_evil.pulse > 0) then
    dec(auction_evil.pulse)
  else
  if (auction_evil.item <> nil) then
    begin
    auction_evil.update;
    auction_evil.pulse := CPULSE_AUCTION;
    end;
end;

procedure update_main;
var
   node, node_next : GListNode;
   conn : GConnection;
begin
  node := connection_list.head;

  while (node <> nil) do
    begin
    node_next := node.next;
    conn := node.element;

    inc(conn.idle);

    if (((conn.state = CON_NAME) and (conn.idle > IDLE_NAME)) or
     ((conn.state <> CON_PLAYING) and (conn.idle > IDLE_NOT_PLAYING)) or
      (conn.idle > IDLE_PLAYING)) and ((conn.ch <> nil) and (not conn.ch.IS_IMMORT)) then
       begin
       conn.send(#13#10'You have been idle too long. Disconnecting.'#13#10);
       conn.thread.terminate;

       node := node_next;
       continue;
       end;

    if (conn.state=CON_PLAYING) and (not conn.ch.in_command) then
      GPlayer(conn.ch).emptyBuffer;

    if (conn.state=CON_PLAYING) and (conn.ch.wait>0) then
      dec(conn.ch.wait);

    node := node_next;
    end;
end;

procedure update_gamehour;
var
   node, node_next : GListNode;
   area : GArea;
   ch : GCharacter;
begin
{$IFDEF WIN32}
  status := GetHeapStatus;
{$ENDIF}

  update_affects;
  update_tracks;

  { update age of areas and reset if hit timer }
  node := area_list.head;

  while (node <> nil) do
    begin
    area := node.element;

    area.update;

    node := node.next;
    end;

  node := char_list.head;

  while (node <> nil) do
    begin
    ch := node.element;
    node_next := node.next;

    if (not ch.IS_NPC) and (IS_SET(GPlayer(ch).flags, PLR_LINKLESS)) then
      begin
      inc(GPlayer(ch).ld_timer);

      if (GPlayer(ch).ld_timer > IDLE_LINKDEAD) then
        begin
        node := node_next;
        GPlayer(ch).quit;
        continue;
        end;
      end;

    node := node_next;
    end;
end;

procedure update_sec;
begin
  calculateonline;

  if (boot_info.timer >= 0) then
    begin
    dec(boot_info.timer);

    case boot_info.timer of
      60,30,10,5 :  begin
                    case boot_info.boot_type of
                      BOOTTYPE_SHUTDOWN:begin
                                        writeConsole(inttostr(boot_info.timer)+' seconds till shutdown');
                                        to_channel(nil, '$B$1 ---- Server $3shutdown$1 in $7' + inttostr(boot_info.timer) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
                                        end;
                        BOOTTYPE_REBOOT:begin
                                        writeConsole(inttostr(boot_info.timer)+' seconds till reboot');
                                        to_channel(nil, '$B$1 ---- Server $3reboot$1 in $7' + inttostr(boot_info.timer) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
                                        end;
                      BOOTTYPE_COPYOVER:begin
                                        writeConsole(inttostr(boot_info.timer)+' seconds till reboot');
                                        to_channel(nil, '$B$1 ---- Server $3copyover$1 in $7' + inttostr(boot_info.timer) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
                                        end;
                    end;
                    end;

      0 :           begin
                    case boot_info.boot_type of
                      BOOTTYPE_SHUTDOWN:begin
                                        writeConsole('Timer reached zero, starting shutdown now');
                                        to_channel(nil, '$B$1 ---- Server will $3shutdown $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
                                        end;
                        BOOTTYPE_REBOOT:begin
                                        writeConsole('Timer reached zero, starting reboot now');
                                        to_channel(nil, '$B$1 ---- Server will $3reboot $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
                                        end;
                      BOOTTYPE_COPYOVER:begin
                                        writeConsole('Timer reached zero, starting copyover now');
                                        to_channel(nil, '$B$1 ---- Server will $3copyover $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
                                        end;
                    end;

                    boot_type := boot_info.boot_type;
                    grace_exit := true;

                    halt;
                    end;
    end;
    end;

  if (bg_info.count > 0) then
    begin
    dec(bg_info.count);

    case bg_info.count of
      60,30,10,5,2 : battlegroundMessage;
      0 : startBattleground;
    end;
    end;

  regenerate_chars;
end;

procedure initTimers();
begin
  timer_list := GDLinkedList.Create;

  registerTimer('main', update_main, 1, true);
  registerTimer('auction', update_auction, 1, true);
  registerTimer('gamehour', update_gamehour, CPULSE_GAMEHOUR, true);
  registerTimer('second', update_sec, CPULSE_PER_SEC, true);
end;

procedure cleanupTimers();
begin
  timer_list.clean();
  timer_list.Free();
end;

end.
