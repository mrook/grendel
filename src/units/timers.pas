{
  Summary:
  	Timer class
    
  ## $Id: timers.pas,v 1.15 2004/06/10 18:10:56 ***REMOVED*** Exp $
}

unit timers;

interface


uses
{$IFDEF WIN32}
	Windows,
	JclDebug,
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
	private
		_name : string;
		_counter : integer;
		timer_func : TIMER_FUNC;
		timeout : integer;
		looping : boolean;

	published
		constructor Create(const name_ : string; func_ : TIMER_FUNC; timeout_ : integer; looping_ : boolean);
		
		property name : string read _name;
		property counter : integer read _counter write _counter;
	end;

	GSpecTimer = class (GTimer)
	private
		spec_func : SPEC_FUNC;
		ch, victim : GCharacter;
		timer_type : integer;
		sn : GSkill;

	published
		constructor Create(const name_ : string; timer_type_ : integer; func_ : SPEC_FUNC; timeout_ : integer; ch_, victim_ : GCharacter; sn_ : GSkill);
	end;

	{$IFDEF WIN32}
	GTimerThread = class(TJclDebugThread)
	{$ELSE}
	GTimerThread = class(TThread)
	{$ENDIF}
	private
		last_update : TDateTime;

	protected
		procedure Execute; override;
	
	published
		constructor Create();
		
		property lastUpdate : TDateTime read last_update;
	end;


var
	timer_list : GDLinkedList;


procedure registerTimer(const name : string; func : TIMER_FUNC; timeout : integer; looping : boolean); overload;
procedure registerTimer(const name : string; timer_type : integer; func : SPEC_FUNC; timeout : integer; ch, victim : GCharacter; sn : GSkill); overload;

procedure unregisterTimer(const name_ : string); overload;
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
	commands,
	update,
	area,
	debug,
	conns,
	player,
	server,
	Channels;


// GTimer
constructor GTimer.Create(const name_ : string; func_ : TIMER_FUNC; timeout_ : integer; looping_ : boolean);
begin
  inherited Create;

  Self._name := name_;
  Self._counter := timeout_;
  Self.timer_func := func_;
  Self.timeout := timeout_;
  Self.looping := looping_;
end;

// GSpecTimer
constructor GSpecTimer.Create(const name_ : string; timer_type_ : integer; func_ : SPEC_FUNC; timeout_ : integer; ch_, victim_ : GCharacter; sn_ : GSkill);
begin
  inherited Create(name_, nil, timeout_, false);

  Self.spec_func := func_;
  Self.timer_type := timer_type_;
  Self.ch := ch_;
  Self.victim := victim_;
  Self.sn := sn_;
end;


// GTimerThread
constructor GTimerThread.Create();
begin
  inherited Create(false);

  last_update := Now();
end;

{ TODO remove nodes }
procedure GTimerThread.Execute();
var
	node, node_next : GListNode;
	timer : GTimer;
	spec : GSpecTimer;
begin
	try
		while (not Terminated) do
			begin
			last_update := Now();

			node := timer_list.head;

			while (node <> nil) do
				begin
				timer := GTimer(node.element);
				node_next := node.next;

				try
					dec(timer._counter);

					if (timer._counter = 0) then
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
							timer.Free();
							end
						else
							timer._counter := timer.timeout;
						end;
				except
					{$IFDEF LINUX}
					on E : EQuit do Terminate();
					{$ENDIF}
					on E : EControlC do Terminate();
					on E : Exception do	
						begin
						{$IFDEF WIN32}
						HandleException();
						{$ELSE}
						reportException(E, 'timers.pas:GTimerThread.Execute()');
						{$ENDIF}
						timer_list.remove(node);
						timer.Free();
						end;
				end;

				node := node_next;
				end;

			Sleep(250);
			end;
	except
		on E : Exception do	
			begin
			{$IFDEF WIN32}
			HandleException();
			{$ELSE}
			reportException(E, 'timers.pas:GTimerThread.Execute()');
			{$ENDIF}
			end;
	end;	
end;

procedure registerTimer(const name : string; func : TIMER_FUNC; timeout : integer; looping : boolean);
var
   timer : GTimer;
begin
  timer := GTimer.Create(name, func, timeout, looping);

  timer_list.insertLast(timer);
end;

procedure registerTimer(const name : string; timer_type : integer; func : SPEC_FUNC; timeout : integer; ch, victim : GCharacter; sn : GSkill);
var
   timer : GSpecTimer;
begin
  timer := GSpecTimer.Create(name, timer_type, func, timeout, ch, victim, sn);

  timer_list.insertLast(timer);
end;

{ TODO remove nodes }
procedure unregisterTimer(const name_ : string);
var
   timer : GTimer;
   node : GListNode;
begin
  node := timer_list.head;

  while (node <> nil) do
    begin
    timer := GTimer(node.element);

    if (timer.name = name_) then
      begin
      timer_list.remove(node);
      timer.Free();
      break;
      end;

    node := node.next;
    end;
end;

{ TODO remove nodes }
procedure unregisterTimer(ch : GCharacter; timer_type : integer);
var
   timer : GTimer;
   spec : GSpecTimer;
   node : GListNode;
begin
  node := timer_list.head;

  while (node <> nil) do
    begin
    timer := GTimer(node.element);

    if (timer is GSpecTimer) then
      begin
      spec := GSpecTimer(timer);

      if (spec.ch = ch) and (spec.timer_type = timer_type) then
        begin
        timer_list.remove(node);
        timer.Free();
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
  iterator : GIterator;
begin
  Result := nil;

  iterator := timer_list.iterator();

  while (iterator.hasNext()) do
    begin
    timer := GTimer(iterator.next());

    if (timer is GSpecTimer) then
      begin
      spec := GSpecTimer(timer);

      if (spec.ch = ch) and (spec.timer_type = timer_type) and (spec.counter > 0) then
        begin
        Result := timer;
        break;
        end;
      end;
    end;
    
  iterator.Free();
end;

function hasTimer(ch : GCharacter; const timer_name : string) : GTimer;
var
  timer : GTimer;
  spec : GSpecTimer;
  iterator : GIterator;
begin
  Result := nil;

  iterator := timer_list.iterator();

  while (iterator.hasNext()) do
    begin
    timer := GTimer(iterator.next());

    if (timer is GSpecTimer) then
      begin
      spec := GSpecTimer(timer);

      if (spec.ch = ch) and (spec.name = timer_name) and (spec.counter > 0) then
        begin
        Result := timer;
        break;
        end;
      end;
    end;
    
  iterator.Free();
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

procedure update_main();
var
  iterator : GIterator;
  conn : GPlayerConnection;
begin
  iterator := connection_list.iterator();

  while (iterator.hasNext()) do
    begin
    conn := GPlayerConnection(iterator.next());

		conn.pulse();
    end;
    
  iterator.Free();
end;

procedure update_gamehour();
var
  iterator : GIterator;
  area : GArea;
  ch : GCharacter;
begin
{$IFDEF WIN32}
  status := GetHeapStatus;
{$ENDIF}

  update_affects;
  update_tracks;

  { update age of areas and reset if hit timer }
  iterator := area_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    area := GArea(iterator.next());

    area.update();
    end;
  
  iterator.Free();

  iterator := char_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    ch := GCharacter(iterator.next());

    if (not ch.IS_NPC) and (IS_SET(GPlayer(ch).flags, PLR_LINKLESS)) then
      begin
      inc(GPlayer(ch).ld_timer);

      if (GPlayer(ch).ld_timer > IDLE_LINKDEAD) then
        begin
        GPlayer(ch).quit();
        iterator.remove();
        end;
      end;
    end;
  
  iterator.Free();
end;

procedure update_sec();
begin
	calculateonline();
	
	if (bg_info.count > 0) then
		begin
		dec(bg_info.count);

		case bg_info.count of
			60,30,10,5,2 : battlegroundMessage();
			0 : startBattleground();
		end;
		end;

	regenerate_chars();
end;

procedure initTimers();
begin
  timer_list := GDLinkedList.Create();

  registerTimer('main', update_main, 1, true);
  registerTimer('auction', update_auction, 1, true);
  registerTimer('gamehour', update_gamehour, CPULSE_GAMEHOUR, true);
  registerTimer('second', update_sec, CPULSE_PER_SEC, true);
end;

procedure cleanupTimers();
begin
  timer_list.clear();
  timer_list.Free();
end;

end.
