unit timers;

interface

uses
    Windows,
    SysUtils,
    Classes,
    dtypes,
    chars;


type
    TIMER_FUNC = procedure;
    SPEC_FUNC = procedure(ch, victim : GCharacter; sn : integer);

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

      sn : integer;

      constructor Create(timer_type_ : integer; func_ : SPEC_FUNC; timeout_ : integer; ch_, victim_ : GCharacter; sn_ : integer);
    end;

    GTimerThread = class (TThread)
      procedure Execute; override;

      constructor Create;
    end;

var
   timer_list : GDLinkedList;

procedure registerTimer(name_ : string; func_ : TIMER_FUNC; timeout_ : integer; looping_ : boolean); overload;
procedure registerTimer(timer_type_ : integer; func_ : SPEC_FUNC; timeout_ : integer; ch_, victim_ : GCharacter; sn_ : integer); overload;

procedure unregisterTimer(name_ : string); overload;
procedure unregisterTimer(ch : GCharacter; timer_type : integer); overload;

function hasTimer(ch : GCharacter; timer_type : integer) : GTimer;

implementation

uses
    constants,
    mudsystem,
    skills,
    util,
    update,
    debug,
    area,
    conns;


// GTimer
constructor GTimer.Create(name_ : string; func_ : TIMER_FUNC; timeout_ : integer; looping_ : boolean);
begin
  inherited Create;

  name := name_;
  timer_func := func_;
  timeout := timeout_;
  counter := timeout_;
  looping := looping_;
end;

// GSpecTimer
constructor GSpecTimer.Create(timer_type_ : integer; func_ : SPEC_FUNC; timeout_ : integer; ch_, victim_ : GCharacter; sn_ : integer);
begin
  inherited Create(timer_names[timer_type_], nil, timeout_, false);

  spec_func := func_;
  timer_type := timer_type_;
  ch := ch_;
  victim := victim_;
  sn := sn_;
end;


// GTimerThread
constructor GTimerThread.Create;
begin
  inherited Create(false);
end;

procedure GTimerThread.Execute;
var
   node, node_next : GListNode;
   timer : GTimer;
   spec : GSpecTimer;
begin
  while (not Terminated) do
    begin
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
        on E : EExternal do
          outputError(E.ExceptionRecord.ExceptionAddress)
        else
          bugreport('GTimerThread.Execute', 'timers.pas', 'Timer "' + timer.name + '" failed to execute correctly', 'Timer "' + timer.name + '" failed to execute correctly');

        if (timer is GSpecTimer) then
          begin
          timer_list.remove(node);
          timer.Free;
          end
        else
          timer.counter := timer.timeout;
      end;

      node := node_next;
      end;

    Sleep(250);
    end;
end;

procedure registerTimer(name_ : string; func_ : TIMER_FUNC; timeout_ : integer; looping_ : boolean);
var
   timer : GTimer;
begin
  timer := GTimer.Create(name_, func_, timeout_, looping_);

  timer_list.insertLast(timer);
end;

procedure registerTimer(timer_type_ : integer; func_ : SPEC_FUNC; timeout_ : integer; ch_, victim_ : GCharacter; sn_ : integer); overload;
var
   timer : GSpecTimer;
begin
  timer := GSpecTimer.Create(timer_type_, func_, timeout_, ch_, victim_, sn_);

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

      if (spec.ch = ch) and (spec.timer_type = timer_type) then
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
      (conn.idle > IDLE_PLAYING)) and (not conn.ch.IS_IMMORT) then
       begin
       conn.send(#13#10'You have been idle too long. Disconnecting.'#13#10);
       conn.thread.terminate;

       node := node_next;
       continue;
       end;

    if (conn.state=CON_PLAYING) and (not conn.ch.in_command) then
      conn.ch.emptyBuffer;

    if (conn.state=CON_PLAYING) and (conn.ch.wait>0) then
      dec(conn.ch.wait);

    node := node_next;
    end;

  cleanChars;
  cleanObjects;
end;

procedure update_gamehour;
var
   node, node_next : GListNode;
   area : GArea;
   ch : GCharacter;
begin
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

    if (not ch.IS_NPC) and (IS_SET(ch.player^.flags, PLR_LINKLESS)) then
      begin
      inc(ch.player^.ld_timer);

      if (ch.player^.ld_timer > IDLE_LINKDEAD) then
        begin
        node := node_next;
        ch.quit;
        continue;
        end;
      end;

    node := node_next;
    end;
end;

procedure update_sec;
begin
  calculateonline;

  if (boot_info.timer>=0) then
    begin
    dec(boot_info.timer);

    case boot_info.timer of
      60,30,10,5 : clean_thread.SetMessage(CLEAN_BOOT_MSG);
      0 : clean_thread.SetMessage(CLEAN_MUD_STOP);
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

procedure update_autosave;
begin
  status := GetHeapStatus;
  clean_thread.SetMessage(CLEAN_AUTOSAVE);
end;


begin
  timer_list := GDLinkedList.Create;

  registerTimer('main', update_main, 1, true);
  registerTimer('auction', update_auction, 1, true);
  registerTimer('gamehour', update_gamehour, CPULSE_GAMEHOUR, true);
  registerTimer('second', update_sec, CPULSE_PER_SEC, true);
  registerTimer('autosave', update_autosave, CPULSE_AUTOSAVE, true);
end.
