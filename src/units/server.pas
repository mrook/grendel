{
	Summary:
		Main server class
	
	## $Id: server.pas,v 1.17 2004/06/10 18:10:56 ***REMOVED*** Exp $
}
unit server;

interface


uses
	dtypes;
	

type
	GServerShutdownTypes = (SHUTDOWNTYPE_REBOOT, SHUTDOWNTYPE_COPYOVER, SHUTDOWNTYPE_HALT);
	
	GServerEvent = procedure() of object;
	
	GServer = class(GSingleton)
	private
		listenSockets : GDLinkedList;
		
		running : boolean;
		
		shutdownType : GServerShutdownTypes;
		shutdownDelay : integer;
		lastReportedDelay : integer;
		
		{ Called for every iteration in GServer.gameLoop() }
		FOnTick : GServerEvent;
		
		procedure openListenSockets();
		procedure processShutdownDelay();
		
	public
		constructor actualCreate(); override;
		destructor actualDestroy(); override;
	
	published
		function gameLoop() : GServerShutdownTypes;
		
		procedure init();
		procedure cleanup();
		
		procedure shutdown(shutdownType : GServerShutdownTypes; delay : integer = 0);

		function isRunning() : boolean;
		
		function getShutdownDelay() : integer;
		function getShutdownType() : GServerShutdownTypes;

		property OnTick : GServerEvent read FOnTick write FOnTick;
	end;


var
	serverBooted : boolean = false;
	
	
implementation


uses
	Math,
	SysUtils,
	conns,
	console,
	player,
	socket,
	constants,
	clan,
	mudsystem,
	timers,
	update,
	fight,
	fsys,
	modules,
	commands,
	NameGen,
	mudhelp,
	skills,
	clean,
	chars,
	Channels,
	Bulletinboard,
	progs,
	events,
	area,
	debug,
	race;


const
	{ Number of milliseconds to sleep each iteration }
	SERVER_PULSE_SLEEP = 25;
	
	{ Resolution of timer }
	SERVER_PULSE_RES = 1000 div 25;


{ GServer constructor }
constructor GServer.actualCreate();
begin
	inherited actualCreate();

	listenSockets := GDLinkedList.Create();
	
	running := false;
	shutdownType := SHUTDOWNTYPE_HALT;
	shutdownDelay := -1;
end;

{ GServer destructor }
destructor GServer.actualDestroy();
begin
	listenSockets.clear();
	listenSockets.Free();
	
	inherited actualDestroy();
end;

{ Opens listening sockets }
procedure GServer.openListenSockets();
var
	socket : GSocket;
begin
	listenSockets := GDLinkedList.Create();
	
	if (isSupported(SOCKTYPE_IPV4)) then
		begin
		socket := createSocket(SOCKTYPE_IPV4);
		
		try
			socket.openPort(system_info.port);
			listenSockets.add(socket);
		except
			socket.Free();
		end;
		end;

	if (isSupported(SOCKTYPE_IPV6)) then
		begin
		socket := createSocket(SOCKTYPE_IPV6);
		
		try
			socket.openPort(system_info.port6);
			listenSockets.add(socket);
		except
			socket.Free();
		end;
		end;
end;

{ Initializes the server }
procedure GServer.init();
begin
	writeConsole(version_info + ', ' + version_number + '.');
	writeConsole(version_copyright + '.');

	writeConsole('Initializing memory pool...');
	
	try
		initProgs();
		initClans();
		initCommands();
		initHelp();
		initChannels();
		initChars();
		initPlayers();
		initSkills();
		initAreas();
		initTimers();
		initRaces();
		initNotes();
		initSystem();
		initEvents();

		writeConsole('Booting server...');
		
		loadSystem();

		writeConsole('Booting "' + system_info.mud_name + '" database, ' + FormatDateTime('ddddd', Now()) + '.');

		writeConsole('Loading skills...');
		load_skills();

		writeConsole('Loading races...');
		loadRaces();

		writeConsole('Loading clans...');
		load_clans;

		writeConsole('Loading channels...');
		load_channels();

		writeConsole('Loading areas...');
		loadAreas();

		writeConsole('Loading help...');
		loadHelp('help.dat');

		writeConsole('Loading namegenerator data...');
		loadNameTables(NameTablesDataFile);

		writeConsole('Loading noteboards...');
		load_notes('boards.dat');

		writeConsole('Loading modules...');
		loadModules();

		writeConsole('Loading texts...');
		loadCommands();
		loadSocials();
		loadDamage();

		writeConsole('Loading mud state...');
		BootTime := Now;

		bg_info.count := -1;

		update_time;

		time_info.day := 1;
		time_info.month := 1;
		time_info.year := 1;

		loadMudState();

		randomize();

		resetAreas();

		openListenSockets();

		registerTimer('teleports', update_teleports, 1, true);
		registerTimer('fighting', update_fighting, CPULSE_VIOLENCE, true);
		registerTimer('battleground', update_battleground, CPULSE_VIOLENCE, true);
		registerTimer('objects', update_objects, CPULSE_TICK, true);
		registerTimer('characters', update_chars, CPULSE_TICK, true);
		registerTimer('gametime', update_time, CPULSE_GAMETIME, true);

		timer_thread := GTimerThread.Create();
		clean_thread := GCleanThread.Create();

		calculateonline();	
	except
		on E : Exception do
			begin
			reportException(E, 'GServer.init()');
			writeConsole('Server boot failed, halting!');
			Halt(1);
			end;
	end;
end;

procedure GServer.cleanup();
var
	iterator : GIterator;
begin
	try
		writeConsole('Terminating threads...');

		timer_thread.Terminate();
		clean_thread.Terminate();

		Sleep(100);

		writeConsole('Saving mudstate...');

		saveMudState();

		writeConsole('Unloading modules...');

		unloadModules();

		writeConsole('Releasing allocated memory...');

		iterator := char_list.iterator();
		
		while (iterator.hasNext()) do
			begin
			GCharacter(iterator.next()).extract(true);
			iterator.remove();
			end;
			
		iterator.Free();

		writeConsole('Cleaning channels...');
		cleanupChannels();

		writeConsole('Cleaning players...');
		cleanupPlayers();

		writeConsole('Cleaning chars...');
		cleanupChars();

		writeConsole('Cleaning clans...');
		cleanupClans();

		writeConsole('Cleaning commands...');
		cleanupCommands();

		writeConsole('Cleaning help...');
		cleanupHelp();

		writeConsole('Cleaning skills...');
		cleanupSkills();

		writeConsole('Cleaning areas...');
		cleanupAreas();

		writeConsole('Cleaning timers...');
		cleanupTimers();

		writeConsole('Cleaning races...');
		cleanupRaces();

		writeConsole('Cleaning system...');
		cleanupSystem();

		writeConsole('Cleaning notes...');
		cleanupNotes();

		writeConsole('Cleaning events...');
		cleanupEvents();	
	except
		on E : Exception do reportException(E, 'GServer.cleanup()');
	end;

	writeConsole('Cleanup complete.');
end;

{ Decreases shutdownDelay (if > 0), reports shutdown times to channels/console }
procedure GServer.processShutdownDelay();
var
	delay_sec : integer;
begin
	if (shutdownDelay > 0) then
		begin
		delay_sec := getShutdownDelay();
		
		if (lastReportedDelay <> delay_sec) then
			begin
			lastReportedDelay := delay_sec;
			
			case delay_sec of
			  60,30,20,10,5 :  case shutdownType of
							  SHUTDOWNTYPE_HALT:begin
												writeConsole('Starting shutdown in ' + IntToStr(delay_sec) + ' seconds...');
												to_channel(nil, '$B$1 ---- Server $3shutdown$1 in $7' + IntToStr(delay_sec) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
												end;
							SHUTDOWNTYPE_REBOOT:begin
												writeConsole('Starting reboot in ' + IntToStr(delay_sec) + ' seconds...');
												to_channel(nil, '$B$1 ---- Server $3reboot$1 in $7' + IntToStr(delay_sec) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
												end;
						  SHUTDOWNTYPE_COPYOVER:begin
												writeConsole('Starting copyover in ' + IntToStr(delay_sec) + ' seconds...');
												to_channel(nil, '$B$1 ---- Server $3copyover$1 in $7' + IntToStr(delay_sec) + '$1 seconds! ----',CHANNEL_ALL,AT_REPORT);
												end;
							end;
			end;
			end;
		
		dec(shutdownDelay);
		end
	else
	if (shutdownDelay = 0) then
		begin
		running := false;
		
		case shutdownType of
			  SHUTDOWNTYPE_HALT:begin
								writeConsole('Starting shutdown now...');
      							to_channel(nil, '$B$1 ---- Server will $3shutdown $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
								end;
			SHUTDOWNTYPE_REBOOT:begin
								writeConsole('Starting reboot now...');
      							to_channel(nil, '$B$1 ---- Server will $3reboot $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
								end;
		  SHUTDOWNTYPE_COPYOVER:begin
								writeConsole('Starting copyover now...');
      							to_channel(nil, '$B$1 ---- Server will $3copyover $7NOW!$1 ----',CHANNEL_ALL,AT_REPORT);
								end;
		end;
		end;
end;

{ Gameloop, call this from main program or TService.Execute }
function GServer.gameLoop() : GServerShutdownTypes;
var
	iterator : GIterator;
	socket : GSocket;
begin
	running := true;	
	serverBooted := true;
	
  	while (running) do
		begin
		try
			iterator := listenSockets.iterator();

			while (iterator.hasNext()) do
				begin
				socket := GSocket(iterator.next());
	
				if (socket.canRead()) then
					acceptConnection(socket);
				end;

			iterator.Free();
		
			Sleep(SERVER_PULSE_SLEEP);
		
			if (Assigned(FOnTick)) then
				FOnTick();
				
			processShutdownDelay();	
		except
			{$IFDEF LINUX}
			on E : EQuit do break;
			{$ENDIF}
			on E : EControlC do break;
			on E : Exception do reportException(E, 'GServer.gameLoop()');
		end;
		end;
	
	running := false;
	serverBooted := false;
	
	Result := shutdownType;
end;

{ Initiate a shutdown/reboot/copyover procedure, delay is in seconds }
procedure GServer.shutdown(shutdownType : GServerShutdownTypes; delay : integer = 0);
begin
	{ Internal shutdownDelay is one tick every 1/40th of a second (25 msec) }
	Self.shutdownDelay := delay * SERVER_PULSE_RES;

	Self.shutdownType := shutdownType;
end;

{ Returns the shutdown type }
function GServer.getShutdownType() : GServerShutdownTypes;
begin
	Result := shutdownType;
end;

{ Returns the shutdown delay (divided by 40 to return to seconds) }
function GServer.getShutdownDelay() : integer;
begin
	Result := Ceil(shutdownDelay / SERVER_PULSE_RES);
end;

{ Returns true if server is running }
function GServer.isRunning() : boolean;
begin
	Result := running;
end;

end.