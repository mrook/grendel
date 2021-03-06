{
	Summary:
		Player specific functions
	
	## $Id: player.pas,v 1.37 2004/08/24 20:32:49 ***REMOVED*** Exp $
}
unit player;

interface


uses
	Classes,
	md5,
	area,
	dtypes,
	conns,
	socket,
	constants,
	chars;


const
	PLAYER_FIELDS_HASHSIZE = 256;		{ estimated size of hash table for dynamic fields }
	PLAYER_MAX_QUEUESIZE = 16;			{ max size of command queue (per client) }


{$M+}
type
	{ The various states of GPlayerConnection}
	GPlayerConnectionStates = (	CON_STATE_PLAYING, CON_STATE_ACCEPTED, CON_STATE_NAME, CON_STATE_PASSWORD, 
												CON_STATE_NEW_NAME, CON_STATE_NEW_PASSWORD, CON_STATE_NEW_RACE, CON_STATE_NEW_SEX,
												CON_STATE_NEW_STATS, CON_STATE_PRESS_ENTER, CON_STATE_MOTD, CON_STATE_EDITING, 
												CON_STATE_LOGGED_OUT,	CON_STATE_CHECK_PASSWORD );

	GPlayer = class;

	GPlayerConnection = class(GConnection)
	protected
		_ch : GPlayer;
		
		_pagepoint : integer;
		pagebuf : string;
		pagecmd : char;
		fcommand : boolean;
		copyover : boolean;
		copyover_name : string;

		state : GPlayerConnectionStates;

		commandQueue : TStringList;

		procedure OnOpenEvent();
		procedure OnInputEvent();
		procedure OnTickEvent();
		procedure OnOutputEvent();
		procedure OnCloseEvent();
		
		procedure clearCommandQueue();
		procedure addCommandQueue(const line : string);
		procedure emptyCommandQueue();
		function checkAliases(line : string) : boolean;

	public
		destructor Destroy(); override;
		constructor Create(socket : GSocket; from_copyover : boolean = false; const copyover_name : string = '');

		procedure writePager(const txt : string);
		procedure setPagerInput(argument : string);
		procedure outputPager();

		function findDualConnection(const name: string) : GPlayer;
		procedure nanny(argument : string);
		
		function isPlaying() : boolean;
		function isEditing() : boolean;
		
		procedure startEditing();
		procedure stopEditing();
		
		procedure pulse();
		
		function stateAsString() : string;

	published
		property pagepoint : integer read _pagepoint write _pagepoint;

		property ch: GPlayer read _ch write _ch;
	end;
	
	GPlayer = class(GCharacter)   	
	protected
		_keylock: boolean;
		_afk : boolean;
		_fields : GHashTable;
		_title : string;                     { Title of PC }
		
		function getField(name : string) : TObject;
		procedure putField(name : string; obj : TObject);

	public
		edit_buffer : string;
		edit_dest : pointer;

		pagerlen : integer;
		age : longint;                     { Age in hours (irl) }
		cfg_flags, flags : cardinal;    { config flags and misc. flags }
		deaths : integer;
		bankgold : longint;           { Gold in bank }
		xptot, xptogo : longint;       { Experience earned total and needed to level }
		fightxp : longint;
		rank : string;
		clanleader : boolean;         { is clanleader? }
		password : string;
		md5_password : MD5Digest;
		prompt : string;
		remorts : integer;            { remorts done }
		condition : array[COND_DRUNK..COND_MAX-1] of integer;
		area: GArea;
		area_fname : string;
		r_lo, r_hi, m_lo, m_hi, o_lo, o_hi : integer;
		wiz_level : integer;          { level of wizinvis }
		bg_status, bg_points : integer;
		bg_room : pointer;
		war_points, quest_points : integer;
		snooping : GCharacter;
		switching : GCharacter;
		reply : GPlayer;
		trophy : array[1..15] of GTrophy;
		trophysize: integer;
		logon_first : TDateTime;
		logon_now : TDateTime;
		played : TDateTime;
		wimpy : integer;
		aliases : GDLinkedList;
		pracs : integer;
		bamfin, bamfout : string;
		taunt : string;
		channels : GDLinkedList;
		// profession:PROF_DATA;

		ld_timer : integer;

		conn : GPlayerConnection;

		active_board : integer;
		boards : array[BOARD1..BOARD_MAX-1] of integer;
		subject : string;

		constructor Create(conn : GPlayerConnection);
		destructor Destroy(); override;

		function ansiColor(color : integer) : string; override;

		function IS_IMMORT : boolean; override;
		function IS_WIZINVIS : boolean; override;
		function IS_HOLYWALK : boolean; override;
		function IS_HOLYLIGHT : boolean; override;
		function IS_AFK : boolean; override;
		function IS_KEYLOCKED : boolean; override;
		function IS_EDITING : boolean; override;
		function IS_DRUNK : boolean; override;

		function getUsedSkillslots() : integer;       // returns nr. of skillslots occupied
		function getUsedSpellslots() : integer;       // returns nr. of spellslots occupied

		function load(const fn : string) : boolean;
		function save(const fn : string) : boolean;

		function getAge() : integer;
		function getPlayed() : integer;

		procedure die; override;
		procedure calcRank();

		procedure quit;

		procedure sendPrompt; override;
		procedure sendBuffer(const s : string); override;
		procedure sendPager(const txt : string); override;
		procedure emptyBuffer; override;

		procedure startEditing(const text : string);
		procedure stopEditing();
		procedure editBuffer(text : string);
		procedure sendEdit(const text : string);

		property fields[name : string] : TObject read getField write putField; 
		property keylock : boolean read _keylock write _keylock;
		property afk : boolean read _afk write _afk;	

	published
		property title : string read _title write _title;
	end;

	GPlayerField = class
	protected
  	_name : string;
  	
	public		
  		constructor Create(const name : string);
  	
		function default() : TObject; virtual; abstract;
		function fromString(const s : string) : TObject; virtual; abstract;
		function toString(x : TObject) : string; virtual; abstract;
		
		property name : string read _name;
	end;
	
	GPlayerFieldFlag = class(GPlayerField)
	public
	  	function default() : TObject; override;
  		function fromString(const s : string) : TObject; override;
	  	function toString(x : TObject) : string; override;	
	end;

	GPlayerFieldInteger = class(GPlayerField)
	public
  		function default() : TObject; override;
	  	function fromString(const s : string) : TObject; override;
  		function toString(x : TObject) : string; override;	
	end;
	
	GPlayerFieldString = class(GPlayerField)
	public
	  	function default() : TObject; override;
  		function fromString(const s : string) : TObject; override;
	  	function toString(x : TObject) : string; override;	
	end;
{$M-}


var
	fieldList : GHashTable;

procedure registerField(field : GPlayerField);
procedure unregisterField(const name : string);

function findPlayerWorld(ch : GCharacter; name : string) : GCharacter;
function findPlayerWorldEx(ch : GCharacter; name : string) : GCharacter;

function existsPlayer(const name : string) : boolean;
procedure acceptConnection(list_socket : GSocket);

procedure initPlayers();
procedure cleanupPlayers();

function act_string(const acts : string; to_ch, ch : GCharacter; arg1, arg2 : pointer) : string;
function act_color(to_ch : GCharacter; const acts : string; sep : char) : string;

procedure act(atype : integer; const acts : string; hideinvis : boolean; ch : GCharacter; arg1, arg2 : pointer; typ : integer);

function playername(from_ch, to_ch : GCharacter) : string;


implementation


uses
	Math,
	SysUtils,
	FastStrings,
	FastStringFuncs,
	ansiio,
	timers,
	console,
	util,
	debug,
	strip,
	commands,
	skills,
	fsys,
	race,
	mudsystem,
	mudhelp,
	clan,
	events,
	rooms,
	objects,
	server,
	bulletinboard,
	Channels;
	

{ Array with symbolic names for connection states }
var
	con_states : array[CON_STATE_PLAYING..CON_STATE_CHECK_PASSWORD ] of string = (
							'CON_STATE_PLAYING', 'CON_STATE_ACCEPTED', 'CON_STATE_NAME',
							'CON_STATE_PASSWORD', 'CON_STATE_NEW_NAME', 'CON_STATE_NEW_PASSWORD',
							'CON_STATE_NEW_SEX', 'CON_STATE_NEW_RACE', 'CON_STATE_NEW_STATS',
							'CON_STATE_PRESS_ENTER', 'CON_STATE_MOTD', 'CON_STATE_EDITING',
							'CON_STATE_LOGGED_OUT', 'CON_STATE_CHECK_PASSWORD');


{ GPlayerConnection constructor }
constructor GPlayerConnection.Create(socket : GSocket; from_copyover : boolean = false; const copyover_name : string = '');
begin
	inherited Create(socket);
	
	FOnOpen := OnOpenEvent;
	FOnClose := OnCloseEvent;
	FOnTick := OnTickEvent;
	FOnInput := OnInputEvent;
	FOnOutput := OnOutputEvent;

	state := CON_STATE_NAME;

	ch := GPlayer.Create(Self);

	copyover := from_copyover;
	Self.copyover_name := copyover_name;

	commandQueue := TStringList.Create();
end;

{ GPlayerConnection destructor }
destructor GPlayerConnection.Destroy();
begin
	commandQueue.Clear();
	commandQueue.Free();
	
	inherited Destroy();
end;

{ Fired by timer 4 times per second }
procedure GPlayerConnection.pulse();
begin
	inc(_idle);
	
	if ((state = CON_STATE_NAME) and (idle > IDLE_NAME)) or
		((state <> CON_STATE_PLAYING) and (idle > IDLE_NOT_PLAYING)) or
		((idle > IDLE_PLAYING) and (ch <> nil) and (not ch.afk) and (not ch.IS_IMMORT)) or
		((idle > IDLE_AFK) and (ch.afk)) then
		begin
		send(#13#10'You have been idle too long. Disconnecting.'#13#10);
		Terminate();

		exit;
		end;

	if (state = CON_STATE_PLAYING) and (not ch.in_command) then
		ch.emptyBuffer();

	if (state = CON_STATE_PLAYING) and (ch.wait > 0) then
		dec(ch.wait);
end;

{ Event handler for OnOpen }
procedure GPlayerConnection.OnOpenEvent();
var
	temp_buf : string;
begin
	if (not copyover) then
		begin
		state := CON_STATE_NAME;
		
		send(AnsiColor(2,0) + findHelp('M_DESCRIPTION_').text);

		temp_buf := AnsiColor(6,0) + #13#10;
		temp_buf := temp_buf + version_info + ', ' + version_number + '.'#13#10;
		temp_buf := temp_buf + version_copyright + '.';
		temp_buf := temp_buf + AnsiColor(7,0) + #13#10;

		send(temp_buf);

		send(#13#10#13#10'Enter your name or CREATE to create a new character.'#13#10'Please enter your name: ');
		end
	else
  		begin
		state := CON_STATE_MOTD;
    
		ch.setName(copyover_name);
		ch.load(copyover_name);
		send(#13#10#13#10'Gradually, the clouds form real images again, recreating the world...'#13#10);
		send('Copyover complete!'#13#10);

		nanny('');
		end;
end;

{ Event handler for OnClose }
procedure GPlayerConnection.OnCloseEvent();
begin
	if (state = CON_STATE_LOGGED_OUT) then
		begin
		char_list.remove(ch);
		dec(system_info.user_cur);
		end
	else
	if (not ch.CHAR_DIED) and ((state = CON_STATE_PLAYING) or (state = CON_STATE_EDITING)) then
		begin
		writeConsole('(' + IntToStr(socket.getDescriptor) + ') ' + ch.name + ' has lost the link');

		act(AT_REPORT,'$n has lost $s link.', false, ch, nil, nil, TO_ROOM);

		if (ch.level >= LEVEL_IMMORTAL) then
			interpret(ch, 'return');
			
		ch.conn := nil;
		SET_BIT(ch.flags, PLR_LINKLESS);	
		end
	else
		begin
		char_list.remove(ch);
		ch.Free();
		end;	
end;

{ Event handler for OnTick }
procedure GPlayerConnection.OnTickEvent();
begin
	if (fcommand) then
		begin
		if (pagepoint <> 0) then
			outputPager()
		else
			ch.emptyBuffer();
			
		fcommand := false;
		end;
	
	emptyCommandQueue();
end;

{ Event handler for OnInput }
procedure GPlayerConnection.OnInputEvent();
var
	cmdline : string;
	i : integer;
begin
	cmdline := trim(comm_buf);

	i := pos(#13, cmdline);
	if (i <> 0) then
		delete(cmdline, i, 1);

	i := pos(#10, cmdline);
	if (i <> 0) then
		delete(cmdline, i, 1);
		
	comm_buf := '';

	fcommand := true;

	if (pagepoint <> 0) then
		setPagerInput(cmdline)
	else
		case state of
			CON_STATE_PLAYING: 	begin
						if (IS_SET(ch.flags,PLR_FROZEN)) and (cmdline <> 'quit') then
							begin
							ch.sendBuffer('You have been frozen by the gods and cannot do anything.'#13#10);
							ch.sendBuffer('To be unfrozen, send an e-mail to the administration, '+system_info.admin_email+'.'#13#10);
							exit;
							end;
						
						if (not checkAliases(cmdline)) then
							addCommandQueue(cmdline);

						emptyCommandQueue();
						end;
			CON_STATE_EDITING: ch.editBuffer(cmdline);
			else
				nanny(cmdline);
		end;
end;

{ Find aliases matching 'line' }
function GPlayerConnection.checkAliases(line : string) : boolean;
var
	iterator : GIterator;
	al : GAlias;
	cmdline, ale, param : string;
begin
	Result := false;
	
	param := one_argument(line, cmdline);
	cmdline := uppercase(cmdline);

	iterator := ch.aliases.iterator();

	while (iterator.hasNext()) do
		begin
		al := GAlias(iterator.next());
		
		if (uppercase(al.alias) = cmdline) then
			begin
			ale := stringreplace(al.expand, '%', param, [rfReplaceAll]);

			while (pos(':', ale) > 0) do
				begin
				line := left(ale, ':');
				ale := right(ale, ':');

				addCommandQueue(line);
				end;

			addCommandQueue(ale);
			
			Result := true;

			break;
			end;
		end;

	iterator.Free();
end;

{ Event handler for OnOutput }
procedure GPlayerConnection.OnOutputEvent();
begin
	ch.sendPrompt();
end;

{ Flush all lines from the command queue }
procedure GPlayerConnection.clearCommandQueue();
begin
	commandQueue.Clear();
end;

{ Add a line to the command queue}
procedure GPlayerConnection.addCommandQueue(const line : string);
begin
	if (commandQueue.Count < PLAYER_MAX_QUEUESIZE) then
		begin
		commandQueue.Add(line);
		end
	else
		begin
		ch.sendBuffer('Stop spamming all those commands!'#13#10);
		end;
end;

{ Execute all lines in the command queue }
procedure GPlayerConnection.emptyCommandQueue();
begin
	while (commandQueue.Count > 0) and (not Terminated) do
		begin
		if (ch.wait > 0) then
			break;
		
		ch.in_command := true;

		interpret(ch, commandQueue[0]);
		
		commandQueue.delete(0);

		if (not ch.CHAR_DIED) then
			ch.in_command := false;
		end;
end;

{ Returns true if connection has state CON_STATE_PLAYING }
function GPlayerConnection.isPlaying() : boolean;
begin
	Result := (state = CON_STATE_PLAYING);
end;

{ Returns true if connection has state CON_STATE_EDITING }
function GPlayerConnection.isEditing() : boolean;
begin
	Result := (state = CON_STATE_EDITING);
end;

{ Sets the state to CON_STATE_EDITING }
procedure GPlayerConnection.startEditing();
begin
	state := CON_STATE_EDITING;
end;

{ Sets the state to CON_STATE_PLAYING }
procedure GPlayerConnection.stopEditing();
begin
	state := CON_STATE_PLAYING;
end;

{ Returns a text version of the state of the connection }
function GPlayerConnection.stateAsString() : string;
begin
	Result := con_states[state];
end;

{ Find out wether 'name' is already connected }
function GPlayerConnection.findDualConnection(const name: string): GPlayer;
var
	iterator : GIterator;
	dual: GPlayerConnection;
begin
	Result := nil;
	iterator := connection_list.iterator();

	while (iterator.hasNext()) do
  		begin
		dual := GPlayerConnection(iterator.next());

		// is there another conn with exactly the same name?
		if  (dual <> Self)  and (Assigned(dual)) and Assigned(dual.ch) and (lowercase(dual.ch.name) = lowercase(name)) then
			begin
			Result := dual.ch;
			exit;
			end;
		end;
	  
	iterator.Free();
end;

procedure GPlayerConnection.nanny(argument : string);
var 
	vict : GPlayer;
	tmp : GCharacter;
	iterator : GIterator;
	race : GRace;
	digest : MD5Digest;
	top, x, temp : integer;
	buf, pwd : string;
begin
	case state of
        CON_STATE_NAME: begin
                  pwd := one_argument(argument, argument);
                  
                  if (length(argument) = 0) then
                    begin
                    send('Please enter your name: ');
                    exit;
                    end;

                  if (uppercase(argument) = 'CREATE') then
                    begin
                    if (system_info.deny_newplayers) then
                    begin
                      send(#13#10'Currently we do not accept new players. Please come back some other time.'#13#10#13#10);
                      send('Name: '); 
                      exit;
                    end
                    else
                    begin
                      send(#13#10'By what name do you wish to be known? ');
                      state := CON_STATE_NEW_NAME;
                      exit;
                    end;
                    end;
                    
                  if (isNameBanned(argument)) then
                    begin;
                    send('Illegal name.'#13#10);
                    send('Please enter your name: ');
                    exit;
                    end;

                  vict := findDualConnection(argument); // returns nil if player is not yet connected

                  if (vict <> nil) and (not vict.IS_NPC) and (vict.conn <> nil) and (cap(vict.name) = cap(argument)) then
                    begin
                    if (not MD5Match(MD5String(pwd), GPlayer(vict).md5_password)) then
                      begin
                      send(#13#10'You are already logged in under that name! Type your name and password on one line to break in.'#13#10);
                      Terminate();
                      end
                    else
                      begin
                      GConnection(vict.conn).Terminate();

                      while (not IS_SET(vict.flags, PLR_LINKLESS)) do;

                      vict.conn := Self;
                      ch := vict;
                      REMOVE_BIT(ch.flags,PLR_LINKLESS);
                      state := CON_STATE_PLAYING;
                      ch.sendPrompt();
                      end;

                    exit;
                    end;

                  if (not ch.load(argument)) then
                    begin
                    send(#13#10'Are you sure about that name?'#13#10'Name: ');
                    exit;
                    end;

                  state := CON_STATE_PASSWORD;
                  send('Password: ');
                  end;
    CON_STATE_PASSWORD: begin
                  if (length(argument) = 0) then
                    begin
                    send('Password: ');
                    exit;
                    end;

                  if (not MD5Match(MD5String(argument), ch.md5_password)) then
                    begin
                    writeConsole('(' + inttostr(socket.getDescriptor) + ') Failed password');
                    send('Wrong password.'#13#10);
                    send('Password: ');
                    exit;
                    end;

                  vict := findDualConnection( ch.name); // returns nil if player is not dual connected

                  if (not Assigned(vict)) then
                    vict := GPlayer(findPlayerWorldEx(nil, ch.name));

                  if (vict <> nil) and (vict.conn = nil) then
                    begin
                    ch.Free();

                    ch := vict;
                    vict.conn := Self;

                    ch.ld_timer := 0;

                    send('You have reconnected.'#13#10);
                    act(AT_REPORT, '$n has reconnected.', false, ch, nil, nil, TO_ROOM);
                    REMOVE_BIT(ch.flags, PLR_LINKLESS);
                    writeConsole('(' + inttostr(socket.getDescriptor) + ') ' + ch.name + ' has reconnected');

                    ch.sendPrompt();
                    state := CON_STATE_PLAYING;
                    exit;
                    end;

                  if (ch.IS_IMMORT) then
                    send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                  else
                    send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                  send('Press Enter.'#13#10);
                  state := CON_STATE_MOTD;
                  end;
        CON_STATE_MOTD: begin
                  send(ch.ansiColor(6) + #13#10#13#10'Welcome, ' + ch.name + ', to this MUD. May your stay be pleasant.'#13#10);

                  with system_info do
                    begin
                    user_cur := connection_list.size();
                    if (user_cur > user_high) then
                      user_high := user_cur;
                    end;

                  ch.toRoom(ch.room);

                  act(AT_WHITE, '$n enters through a magic portal.', true, ch, nil, nil, TO_ROOM);
                  writeConsole('(' + inttostr(socket.getDescriptor) + ') '+ ch.name +' has logged in');

                  ch.node_world := char_list.insertLast(ch);
                  ch.logon_now := Now;

                  if (ch.level = LEVEL_RULER) then
                    interpret(ch, 'uptime')
                  else
                    ch.sendPrompt();

                  state := CON_STATE_PLAYING;
                  fcommand := true;
                 
                  raiseEvent('char-login', ch);
                  end;
    CON_STATE_NEW_NAME: begin
                  if (length(argument) = 0) then
                    begin
                    send('By what name do you wish to be known? ');
                    exit;
                    end;

                  if (FileExists('players\' + argument + '.usr')) or (findDualConnection(argument) <> nil) then
                    begin
                    send('That name is already used.'#13#10);
                    send('By what name do you wish to be known? ');
                    exit;
                    end;

                  tmp := findPlayerWorldEx(nil, argument);
                  
                  if (isNameBanned(argument)) or (tmp <> nil) then
                    begin
                    send('That name cannot be used.'#13#10);
                    send('By what name do you wish to be known? ');
                    exit;
                    end;

                  if (length(argument) < 3) or (length(argument) > 15) then
                    begin
                    send('Your name must be between 3 and 15 characters long.'#13#10);
                    send('By what name do you wish to be known? ');
                    exit;
                    end;

                  ch.setName(cap(argument));
                  state := CON_STATE_NEW_PASSWORD;
                  send(#13#10'Alright, '+ch.name+', choose a password: ');
                  end;
CON_STATE_NEW_PASSWORD: begin
                  if (length(argument)=0) then
                    begin
                    send('Choose a password: ');
                    exit;
                    end;

                  ch.md5_password := MD5String(argument);
                  state := CON_STATE_CHECK_PASSWORD;
                  send(#13#10'Please retype your password: ');
                  end;
CON_STATE_CHECK_PASSWORD: begin
                    if (length(argument) = 0) then
                      begin
                      send('Please retype your password: ');
                      exit;
                      end;

                    if (not MD5Match(MD5String(argument), ch.md5_password)) then
                      begin
                      send(#13#10'Password did not match!'#13#10'Choose a password: ');
                      state := CON_STATE_NEW_PASSWORD;
                      exit;
                      end
                    else
                      begin
                      state := CON_STATE_NEW_SEX;
                      send(#13#10'What sex do you wish to be (M/F/N): ');
                      exit;
                      end;
                    end;
     CON_STATE_NEW_SEX: begin
                  if (length(argument) = 0) then
                    begin
                    send('Choose a sex (M/F/N): ');
                    exit;
                    end;

                  case upcase(argument[1]) of
                    'M':ch.sex:=0;
                    'F':ch.sex:=1;
                    'N':ch.sex:=2;
                  else
                    begin
                    send('That is not a valid sex.'#13#10);
                    send('Choose a sex (M/F/N): ');
                    exit;
                    end;
                  end;

                  state := CON_STATE_NEW_RACE;
                  send(#13#10'Available races: '#13#10#13#10);

                  iterator := raceList.iterator();

                  while (iterator.hasNext()) do
                    begin
                    race := GRace(iterator.next());
                    
                    if (race.convert) then
                      begin
	                    buf := '  [' + ANSIColor(11,0) + race.short + ANSIColor(7,0) + ']  ' + pad_string(race.name, 15);

	                    if (race.def_alignment < 0) then
	                      buf := buf + ANSIColor(12,0) + '<- EVIL' + ANSIColor(7,0);

	                    buf := buf + #13#10;

	                    send(buf);
	                    end;
                    end;
                    
                  iterator.Free();

                  send(#13#10'Choose a race: ');
                  end;
    CON_STATE_NEW_RACE: begin
                  if (length(argument) = 0) then
                    begin
                    send(#13#10'Choose a race: ');
                    exit;
                    end;

                  race := findRace(argument);

                  if (race = nil) or (race.convert = false) then
                    begin
                    send('Not a valid race.'#13#10);										
                    send(#13#10'Choose a race: ');
                    exit;
                    end;

                  ch.race := race;
                  send(race.description + #13#10#13#10);
                  send('250 stat points will be randomly distributed over your five attributes.'#13#10);
                  send('It is impossible to get a lower or a higher total of stat points.'#13#10);

                  with ch do
                    begin
                    top:=250;

                    str:=URange(25,random(UMax(top,75))+ch.race.str_bonus,75);
                    dec(top,str);

                    con:=URange(25,random(UMax(top,75))+ch.race.con_bonus,75);
                    dec(top,con);

                    dex:=URange(25,random(UMax(top,75))+ch.race.dex_bonus,75);
                    dec(top,dex);

                    int:=URange(25,random(UMax(top,75))+ch.race.int_bonus,75);
                    dec(top,int);

                    wis:=URange(25,random(UMax(top,75))+ch.race.wis_bonus,75);
                    dec(top,wis);

                    while (top>0) do
                      begin
                      x:=random(5);

                      case x of
                        0:begin
                          temp:=UMax(75-str,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            str := str + temp;
                            end;
                          end;
                        1:begin
                          temp:=UMax(75-con,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            con := con + temp;
                            end;
                          end;
                        2:begin
                          temp:=UMax(75-dex,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            dex := dex + temp;
                            end;
                          end;
                        3:begin
                          temp:=UMax(75-int,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            int := int + temp;
                            end;
                          end;
                        4:begin
                          temp:=UMax(75-wis,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            wis := wis + temp;
                            end;
                          end;
                      end;
                      end;

                    //top:=str+con+dex+int+wis;
                    end;

                  send(#13#10'Your character statistics are: '#13#10#13#10);

                  buf := 'Strength:     '+ANSIColor(10,0)+inttostr(ch.str)+ANSIColor(7,0)+#13#10 +
                         'Constitution: '+ANSIColor(10,0)+inttostr(ch.con)+ANSIColor(7,0)+#13#10 +
                         'Dexterity:    '+ANSIColor(10,0)+inttostr(ch.dex)+ANSIColor(7,0)+#13#10 +
                         'Intelligence: '+ANSIColor(10,0)+inttostr(ch.int)+ANSIColor(7,0)+#13#10 +
                         'Wisdom:       '+ANSIColor(10,0)+inttostr(ch.wis)+ANSIColor(7,0)+#13#10;
                  send(buf);

                  send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                  state := CON_STATE_NEW_STATS;
                  end;
   CON_STATE_NEW_STATS: begin
                  if (length(argument) =0) then
                    begin
                    send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                    exit;
                    end;

                  case (upcase(argument[1])) of
                    'C':begin
                        digest := ch.md5_password;

                        ch.load(ch.name);
                        ch.md5_password := digest;
                        ch.save(ch.name);

                        send(#13#10'Thank you. You have completed your entry.'#13#10);

                        send(ch.ansiColor(2) + #13#10);

                        if (ch.IS_IMMORT) then
                          send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                        else
                          send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                        send('Press Enter.'#13#10);
                        state := CON_STATE_MOTD;
                        end;
                    'R':begin
                        with ch do
                          begin
                          top:=250;

                          str:=URange(25,random(UMax(top,75))+ch.race.str_bonus,75);
                          dec(top,str);

                          con:=URange(25,random(UMax(top,75))+ch.race.con_bonus,75);
                          dec(top,con);

                          dex:=URange(25,random(UMax(top,75))+ch.race.dex_bonus,75);
                          dec(top,dex);

                          int:=URange(25,random(UMax(top,75))+ch.race.int_bonus,75);
                          dec(top,int);

                          wis:=URange(25,random(UMax(top,75))+ch.race.wis_bonus,75);
                          dec(top,wis);

                          while (top>0) do
                            begin
                            x:=random(5);

                            case x of
                              0:begin
                                temp:=UMax(75-str,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  str := str + temp;
                                  end;
                                end;
                              1:begin
                                temp:=UMax(75-con,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  con := con + temp;
                                  end;
                                end;
                              2:begin
                                temp:=UMax(75-dex,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  dex := dex + temp;
                                  end;
                                end;
                              3:begin
                                temp:=UMax(75-int,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  int := int + temp;
                                  end;
                                end;
                              4:begin
                                temp:=UMax(75-wis,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  wis := wis + temp;
                                  end;
                                end;
                            end;
                            end;

                          //top:=str+con+dex+int+wis;
                          end;

                        send(#13#10'Your character statistics are: '#13#10#13#10);

                        buf := 'Strength:     '+ANSIColor(10,0)+inttostr(ch.str)+ANSIColor(7,0)+#13#10 +
                               'Constitution: '+ANSIColor(10,0)+inttostr(ch.con)+ANSIColor(7,0)+#13#10 +
                               'Dexterity:    '+ANSIColor(10,0)+inttostr(ch.dex)+ANSIColor(7,0)+#13#10 +
                               'Intelligence: '+ANSIColor(10,0)+inttostr(ch.int)+ANSIColor(7,0)+#13#10 +
                               'Wisdom:       '+ANSIColor(10,0)+inttostr(ch.wis)+ANSIColor(7,0)+#13#10;
                        send(buf);

                        send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                        end;
                    'S':begin
                        send(#13#10'Very well, restarting.'#13#10);
                        send('By what name do you wish to be known?');
                        state := CON_STATE_NEW_NAME;
                        end;
                  else
                    send('Do you wish to (C)ontinue, (R)eroll or (S)art over? ');
                    exit;
                 end;
                 end;
    else
      bugreport('nanny', 'mudthread.pas', 'illegal state');
  end;
end;

procedure GPlayerConnection.writePager(const txt : string);
begin
  if (pagepoint = 0) then
    begin
    pagepoint := 1;
    pagecmd:=#0;
    end;

  pagebuf := pagebuf + txt;
end;

procedure GPlayerConnection.setPagerInput(argument : string);
begin
  argument := trim(argument);

  if (length(argument) > 0) then
    pagecmd := argument[1];
end;

procedure GPlayerConnection.outputPager();
var 
	c : GPlayer;
	last, pclines, lines : integer;
	buf : string;
begin
  if (pagepoint = 0) then
    exit;

{  if (original <> nil) then
    c := original
  else
    c := ch; }
  c := ch;

  pclines := UMax(c.pagerlen, 5) - 2;

  c.emptyBuffer;
  
  if (pagecmd <> #0) then
    send(#13#10);
    
  case pagecmd of
    'b':lines:=-1-(pclines*2);
    'r':lines:=-1-pclines;
    'q':begin
        ch.sendBuffer(' ');
        pagepoint := 0;
        pagebuf := '';
        exit;
        end;
  else
    lines:=0;
  end;

  while (lines<0) and (pagepoint >= 1) do
    begin
    if (pagebuf[pagepoint] = #13) then
      inc(lines);

    pagepoint := pagepoint - 1;
    end;

  if (pagepoint < 1) then
    pagepoint := 1;

  lines := 0;
  last := pagepoint;

  while (lines < pclines) and (last <= length(pagebuf)) do
    begin
    if (pagebuf[last] = #0) then
      break
    else
    if (pagebuf[last] = #13) then
      inc(lines);

    inc(last);
    end;

  if (last <= length(pagebuf)) and (pagebuf[last] = #10) then
    inc(last);

  if (last <> pagepoint) then
    begin
    buf := copy(pagebuf, pagepoint, last - pagepoint);
    send(buf);
    pagepoint := last;
    end;

  while (last <= length(pagebuf)) and (pagebuf[last] = ' ') do
    inc(last);

  if (last >= length(pagebuf)) then
    begin
    pagepoint := 0;
    c.sendPrompt;
    pagebuf := '';
    exit;
    end;

  pagecmd:=#0;

  send(#13#10'(C)ontinue, (R)efresh, (B)ack, (Q)uit: ');
end;


// GPlayer constructor
constructor GPlayer.Create(conn : GPlayerConnection);
var
	iterator : GIterator;
	chan : GUserChannel;
	tc : GUserChannel;
begin
  inherited Create();

  pagerlen := 25;
  xptogo := round((20 * power(level, 1.2)) * (1 + (random(3) / 10)));

  title := 'the Newbie Adventurer';
  rank := 'an apprentice';
  snooping := nil;
  switching := nil;
  reply := nil;

  cfg_flags := CFG_ASSIST or CFG_BLANK or CFG_ANSI or CFG_AUTOPEEK;
  bankgold := 500;
  clan := nil;
  clanleader := false;
  condition[COND_FULL] := 100;
  condition[COND_THIRST] := 100;
  condition[COND_DRUNK] := 0;
  condition[COND_HIGH] := 0;
  condition[COND_CAFFEINE] := 0;
  logon_first := Now;
  ld_timer := 0;
  edit_buffer := '';
  edit_dest := nil;

  aliases := GDLinkedList.Create();
  skills_learned := GDLinkedList.Create();

  pracs := 10; // default for new players(?)

  channels := GDLinkedList.Create();
  iterator := channellist.iterator();
  
  while (iterator.hasNext()) do
    begin
    chan := GUserChannel(iterator.next());
    tc := GUserChannel.Create(chan.channelname);
    channels.insertLast(tc);
    end;
    
	iterator.Free();

  active_board := 1;
  boards[BOARD1] := 0;
  boards[BOARD2] := 0;
  boards[BOARD3] := 0;
  boards[BOARD_NEWS] := 0;
  boards[BOARD_IMM] := 0;

  apb := 7;
  hp := 50 + con + random(11); max_hp:=hp;
  mv := 40 + (dex div 4); max_mv := mv;
  mana := 25; max_mana := 25;
  ac_mod := 0;
  natural_ac := 0;
  hitroll := 50;

  position := POS_STANDING;
  state := STATE_IDLE;
  bash_timer := -2;
  cast_timer := 0;
  bashing := -2;
  mental_state := -10;
  in_command := false;
  
  keylock := false;
  afk := false;

	Self.conn := conn;

  if (IS_GOOD) then
    room := findRoom(ROOM_VNUM_GOOD_PORTAL)
  else
  if (IS_EVIL) then
    room := findRoom(ROOM_VNUM_EVIL_PORTAL);

  fighting := nil;
  
  _fields := GHashTable.Create(PLAYER_FIELDS_HASHSIZE);
end;

// GPlayer destructor
destructor GPlayer.Destroy();
var
	node, node_next : GListNode;
	tc : GUserChannel;
begin
  aliases.clear();
  aliases.Free();

  node := channels.head;
  while (node <> nil) do
    begin
    node_next := node.next;
    tc := GUserChannel(node.element);
    channels.remove(node);
    tc.Free();

    node := node_next;
    end;
 
  channels.clear();
  channels.Free();

  skills_learned.clear();
  skills_learned.Free();
  
  _fields.clear();
  _fields.Free();

  inherited Destroy;
end;

function GPlayer.getField(name : string) : TObject;
begin
	if (_fields = nil) then
		Result := GPlayerField(fieldList[name]).default()
	else
		begin
		name := prep(name);

		if (_fields[name] = nil) then
			_fields[name] := GPlayerField(fieldList[name]).default();

		Result := _fields[name];
		end;
end;

procedure GPlayer.putField(name : string; obj : TObject);
begin
	if (_fields = nil) then
		exit;

  name := prep(name);

	if (_fields[name] <> nil) then
		begin
		_fields[name].Free();
		_fields.remove(name);
		end;
	
	_fields[name] := obj;
end;

// Quit procedure
procedure GPlayer.quit();
var
	vict : GCharacter;
	iterator : GIterator;
begin
  raiseEvent('char-logout', Self);

  emptyBuffer();

  if (conn = nil) then
    writeConsole('(Linkless) '+ name + ' has logged out')
  else
  if (conn <> nil) then
    writeConsole('(' + IntToStr(conn.socket.getDescriptor) + ') ' + name + ' has logged out');

  { switched check}
  if (conn <> nil) and (not IS_NPC) then
    begin
    conn.state := CON_STATE_LOGGED_OUT;

    try
      conn.Terminate();
    except
      writeConsole('could not delete thread of ' + name);
    end;

    conn := nil;
    end
  else
  if (not IS_NPC) and (not IS_SET(GPlayer(Self).flags, PLR_LINKLESS)) then
    interpret(Self, 'return sub');

  { perform the cleanup }
  if (snooping <> nil) then
    begin
    snooping.snooped_by := nil;
    snooping := nil;
    end;

  if (switching <> nil) then
    begin
    switching.snooped_by := nil;
    switching := nil;
    end;

  if (leader <> Self) then
    begin
    to_channel(leader, '$B$7[Group]: ' + name + ' has left the group.', CHANNEL_GROUP, AT_WHITE);
    leader := nil;
    end
  else
    begin
    iterator := char_list.iterator();

    while (iterator.hasNext()) do
      begin
      vict := GCharacter(iterator.next());

      if (vict <> Self) and ((vict.leader = Self) or (vict.master = Self)) then
        begin
        act(AT_REPORT,'You stop following $N.',false,vict,nil,Self,TO_CHAR);
        vict.master := nil;
        vict.leader := vict;
        end;
      end;
    
    iterator.Free();
    end;

  save(name);

  extract(true);
end;

function GPlayer.getAge() : integer;
begin
  getAge := 17 + (getPlayed div 1000);
end;

function GPlayer.getPlayed : integer;
begin
  getPlayed := trunc(((played + (Now - logon_now)) * MSecsPerDay) / 60000);
end;

// Player is Immortal
function GPlayer.IS_IMMORT : boolean;
begin
  Result := inherited IS_IMMORT;

  if (level >= LEVEL_IMMORTAL) then
    IS_IMMORT := true;
end;

// Player is wizinvis
function GPlayer.IS_WIZINVIS : boolean;
begin
  Result := IS_SET(flags, PLR_WIZINVIS);
end;

// Player has holywalk
function GPlayer.IS_HOLYWALK : boolean;
begin
  Result := inherited IS_HOLYWALK;

  if (IS_SET(flags, PLR_HOLYWALK)) then
    Result := true;
end;

// Player has holylight
function GPlayer.IS_HOLYLIGHT : boolean;
begin
  Result := inherited IS_HOLYLIGHT;

  if (IS_SET(flags, PLR_HOLYLIGHT)) then
    Result := true;
end;

// Player is AFK
function GPlayer.IS_AFK : boolean;
begin
  if IS_SET(flags, PLR_LINKLESS) then
    IS_AFK := false
  else
    IS_AFK := afk = true;
end;

// Player has a locked keyboard
function GPlayer.IS_KEYLOCKED : boolean;
begin
  if IS_SET(flags, PLR_LINKLESS) then
    IS_KEYLOCKED := false
  else
    IS_KEYLOCKED := keylock = true;
end;

// Player is editing (writing a note)
function GPlayer.IS_EDITING : boolean;
begin
  IS_EDITING := (conn.isEditing());
end;

// Player is drunk
function GPlayer.IS_DRUNK : boolean;
begin
	IS_DRUNK := (condition[COND_DRUNK] > 80);
end;

// Returns nr. of skillslots occupied
function GPlayer.getUsedSkillslots() : integer;
var
  iterator : GIterator;
  g : GLearned;
begin
  Result := 0;
  iterator := skills_learned.iterator();

  while (iterator.hasNext()) do
  	begin
    g := GLearned(iterator.next());
    if (GSkill(g.skill).skill_type <> SKILL_SPELL) then
      inc(Result);
	  end;
	
	iterator.Free();
end;

// Returns nr. of spellslots occupied
function GPlayer.getUsedSpellslots() : integer;
var
  iterator : GIterator;
  g : GLearned;
begin
  Result := 0;
  iterator := skills_learned.iterator();

  while (iterator.hasNext()) do
  	begin
    g := GLearned(iterator.next());
    if (GSkill(g.skill).skill_type = SKILL_SPELL) then
      inc(Result);
	  end;
	
	iterator.Free();
end;

// Load player file
function GPlayer.load(const fn : string) : boolean;
var
	num, d, x : longint;
  af : GFileReader;
  g , a, t : string;
  obj, lastobj : GObject;
  aff : GAffect;
  len, modif, inner : integer;
  s : string;
  sk : GSkill;
  al : GAlias;
  node : GListNode;
  iterator : GIterator;
  tc : GUserChannel;
begin
  inner := 0;

  level := 1;
  s := fn;
  s[1] := upcase(s[1]);

  try
    af := GFileReader.Create('players\' + fn + '.usr');
  except
    load := false;
    exit;
  end;
  
  _name := hash_string(s);
  _short := hash_string(s + ' is here');
  _long := hash_string(s + ' is standing here');

  repeat
    repeat
      s := af.readLine;
      s := uppercase(s);
    until (pos('#', s) = 1) or (af.eof);

    if (s = '#PLAYER') then
      begin
      inc(inner);

      a := af.readLine();
      
      while (a <> '#END') and (not af.eof()) do
      	begin
        g := uppercase(left(a,':'));

				if (g = 'USER') then
				else
				if (g = 'LAST-LOGIN') then
				else
        if (g = 'TITLE') then
          title := right(a,' ')
        else
        if (g ='SEX') then
          sex := strtoint(right(a, ' '))
        else
        if (g = 'RACE') then
          begin
          race := findRace(right(a, ' '));
          
          if (race = nil) then
            begin
            bugreport('GPlayer.load', 'chars.pas', 'Unknown race ' + right(a, ' ') + ', reverting to default instead');
            race := GRace(raceList.head.element);
            end;
          end
        else
        if (g = 'ALIGNMENT') then
          alignment := strtoint(right(a, ' '))
        else
        if (g = 'LEVEL') then
          level := UMin(strtoint(right(a, ' ')), LEVEL_MAX_IMMORTAL)
        else
        if (g = 'AGE') then
          age := strtoint(right(a,' '))
        else
        if (g = 'WEIGHT') then
          weight := strtoint(right(a,' '))
        else
        if (g = 'HEIGHT') then
          height := strtoint(right(a,' '))
        else
        if (g = 'STATS') then
          begin
          a := right(a,' ');
          str := strtoint(left(a,' '));
          a := right(a,' ');
          con := strtoint(left(a,' '));
          a := right(a,' ');
          dex := strtoint(left(a,' '));
          a := right(a,' ');
          int := strtoint(left(a,' '));
          a := right(a,' ');
          wis := strtoint(left(a,' '));
          end
        else
        if (g = 'PRACTICES') then
          pracs := strtoint(right(a,' '))
        else
        if (g = 'APB') then
          apb := strtoint(right(a,' '))
        else
        if (g = 'MANA') then
          begin
          a := right(a,' ');
          mana := strtoint(left(a,' '));
          a := right(a,' ');
          max_mana := strtoint(left(a,' '));
          end
        else
        if (g = 'HP') then
          begin
          a := right(a,' ');
          hp := strtoint(left(a,' '));
          a := right(a,' ');
          max_hp := strtoint(left(a,' '));
          end
        else
        if (g = 'MV') then
          begin
          a := right(a,' ');
          mv := strtoint(left(a,' '));
          a := right(a,' ');
          max_mv := strtoint(left(a,' '));
          end
        else
        if (g = 'AC') then
          ac := strtoint(right(a,' '))
        else
        if (g = 'HAC') then
          hac := strtoint(right(a,' '))
        else
        if (g = 'BAC') then
          bac := strtoint(right(a,' '))
        else
        if (g = 'AAC') then
          aac := strtoint(right(a,' '))
        else
        if (g = 'LAC') then
          lac := strtoint(right(a,' '))
        else
        if (g = 'GOLD') then
          begin
          a := right(a,' ');
          gold := UMax(strtointdef(left(a, ' '), 0), 0);
          a := right(a,' ');
          bankgold := UMax(strtointdef(left(a, ' '), 0), 0);
          end
        else
        if (g = 'XP') then
          begin
          a := right(a,' ');
          xptot := strtoint(left(a,' '));
          a := right(a,' ');
          xptogo := strtoint(left(a,' '));
          end
        else
        if (g = 'ROOMVNUM') then
          room := findRoom(strtoint(right(a, ' ')))
        else
        if (g = 'KILLS') then
          kills := strtoint(right(a,' '))
        else
        if (g = 'DEATHS') then
          deaths := strtoint(right(a,' '))
        else
        if (g = 'FLAGS') then
          flags := strtoint(right(a,' '))
        else
        if (g = 'CLAN') then
          begin
          clan := findClan(right(a,' '));

          if (clan <> nil) and(clan.leader = name) then
            clanleader := true;
          end
        else
        if (g = 'CONFIG') then
          cfg_flags := strtoint(right(a,' '))
        else
        if (g = 'AC_MOD') then
          ac_mod := strtoint(right(a,' '))
        else
        // for backward compatibility only
        if (g = 'PASSWORD') then
          begin
          password := right(a,' ');
          md5_password := MD5String(password);
          end
        else
        // the new md5 encrypted pwd
        if (g = 'MD5-PASSWORD') then
          begin
          t := right(a,' ');

          d := 1;
          x := 0;

          while (d <= length(t)) do
            begin
            md5_password[x] := strtoint('$' + t[d] + t[d+1]);
            inc(x);
            inc(d, 2);
            end;
          end
        else
        if (g = 'REMORTS') then
          remorts := strtoint(right(a,' '))
        else
        if (g = 'WIMPY') then
          wimpy := strtoint(right(a,' '))
        else
        if (g = 'AFF_FLAGS') then
          aff_flags := strtoint(right(a,' '))
        else
        if (g = 'MENTALSTATE') then
          mental_state := strtoint(right(a,' '))
        else
        if (g = 'CONDITION') then
          begin
          a := right(a,' ');
          condition[COND_DRUNK] := strtoint(left(a,' '));
          a := right(a,' ');
          condition[COND_FULL] := strtoint(left(a,' '));
          a := right(a,' ');
          condition[COND_THIRST] := strtoint(left(a,' '));
          a := right(a,' ');
          condition[COND_CAFFEINE] := strtoint(left(a,' '));
          a := right(a,' ');
          condition[COND_HIGH] := strtoint(left(a,' '));
          end
        else
        if (g = 'AREA') then
          begin
          area_fname := right(a,' ');
          area := findArea(area_fname);
          end
        else
        if (g = 'RANGES') then
          begin
          a := right(a,' ');
          r_lo := strtoint(left(a,' '));
          a := right(a,' ');
          r_hi := strtoint(left(a,' '));
          a := right(a,' ');
          m_lo := strtoint(left(a,' '));
          a := right(a,' ');
          m_hi := strtoint(left(a,' '));
          a := right(a,' ');
          o_lo := strtoint(left(a,' '));
          a := right(a,' ');
          o_hi := strtoint(left(a,' '));
          end
        else
        if (g = 'WIZLEVEL') then
          wiz_level := strtoint(right(a,' '))
        else
        if (g = 'BGPOINTS') then
          bg_points := strtoint(right(a,' '))
        else
        if (g = 'PAGERLEN') then
          pagerlen := strtoint(right(a,' '))
        else
        if (g = 'LOGON') then
          begin
          a := right(a,' ');
          logon_first := strtoint(left(a,' '));
          a := right(a,' ');
          logon_first := logon_first + (strtoint(left(a,' ')) / MSecsPerDay);
          
          if (logon_first = 0) then
            logon_first := Now;
          end
        else
        if (g = 'PLAYED') then
          begin
          a := right(a,' ');
          played := strtoint(left(a,' '));
          a := right(a,' ');
          played := played + (strtoint(left(a,' ')) / MSecsPerDay);
          end
        else
        if (g = 'BAMFIN') then
          bamfin := right(a, ' ')
        else
        if (g = 'BAMFOUT') then
          bamfout := right(a, ' ')
        else
        if (g = 'TAUNT') then
          taunt := right(a, ' ')
        else
        if (g = 'PROMPT') then
          prompt := right(a, ' ')
        else
        if (g = 'ACTIVE_BOARD') then
          active_board := strtoint(right(a,' '))
        else
        if (g = 'READ-NOTES') then
          begin
          a := right(a,' ');
          boards[BOARD1] := strtoint(left(a,' '));
          a := right(a,' ');
          boards[BOARD2] := strtoint(left(a,' '));
          a := right(a,' ');
          boards[BOARD3] := strtoint(left(a,' '));
          a := right(a,' ');
          boards[BOARD_NEWS] := strtoint(left(a,' '));
          a := right(a,' ');
          boards[BOARD_IMM] := strtoint(left(a,' '));
          end
        else
        if (g = 'IGNORE') then
          begin
          iterator := channels.iterator();
          
          while (iterator.hasNext()) do
            begin
            tc := GUserChannel(iterator.next());
            
            if (tc.channelname = right(a, ' ')) then
              tc.ignored := true;
            end;
          end
				else
					begin
					if (fieldList[g] <> nil) then
						_fields[g] := GPlayerField(fieldList[g]).fromString(right(a, ' '))
					else
						writeConsole('Dropping unknown field "' + g + '"');
					end;

        a := af.readLine();
        end;

      if (uppercase(a)='#END') then
        dec(inner);
      end
    else
    if (s = '#SKILLS') then
      begin
      inc(inner);
      repeat
        a := af.readLine();

        if (uppercase(a) <> '#END') and (not af.eof) then
          begin
          a := right(right(a,' '),'''');
          g := left(a,'''');
          a := right(right(a,''''),' ');
          sk := findSkill(g);

          if (sk <> nil) then
            SET_LEARNED(strtointdef(left(a,' '), 0), sk)
          else
            bugreport('GArea.load', 'charlist.pas', 'skill '+g+' does not exist');
          end;
      until (uppercase(a)='#END') or (af.eof);

      if (uppercase(a)='#END') then
        dec(inner);
      end
    else
    if (s = '#AFFECTS') then
      begin
      inc(inner);

      repeat
        a := af.readLine;

        if (uppercase(a) <> '#END') and (not af.eof) then
          begin
          aff := GAffect.Create();

          with aff do
            begin
            a := right(a, '''');

            name := left(a, '''');

            a := right(right(a, ''''), '''');
            
            wear_msg := left(a, '''');

            a := trim(right(a, ''''));

            duration := strtointdef(left(a, ' '), 0);
            len := 1;
            
            while (pos('{', a) > 0) do
              begin
              a := trim(right(a, '{'));

              setLength(modifiers, len);

              modifiers[len - 1].apply_type := findApply(left(a, ' '));

              a := right(a, ' ');

              try
                modif := strtoint(left(a, ' '));
              except
                modif := cardinal(hash_string(left(a, ' ')));
              end;

              modifiers[len - 1].modifier := modif;

              a := trim(right(a, '}'));
              inc(len);
              end;
            end;

          aff.applyTo(Self);
          end;
      until (uppercase(a)='#END') or (af.eof);

      if (uppercase(a)='#END') then
        dec(inner);
      end
    else
    if (s = '#ALIASES') then
      begin
      inc(inner);
      repeat
        a := af.readLine;

        if (uppercase(a) <> '#END') and (not af.eof) then
          begin
          al := GAlias.Create();

          al.alias := left(a, ':');
          al.expand := right(a, ':');

          al.node := aliases.insertLast(al);
          end;
      until (uppercase(a)='#END') or (af.eof);

      if (uppercase(a)='#END') then
        dec(inner);
      end
    else
    if (s = '#OBJECTS') then
      begin
      inc(inner);
      g := af.readLine;

      repeat
        if (uppercase(g) <> '#END') and (not af.eof) then
          begin
          if (g = '##') then
          	begin
          	obj := GObject.Create();
          	obj.worn := '';
          	lastobj.contents.add(obj);
          	end
          else
          	begin
          	obj := GObject.Create();
			obj.worn := g;
			
			if (obj.worn = 'none') then
				obj.worn := '';
			
			if (obj.worn <> '') then
				equipment.put(obj.worn, obj)
			else
				inventory.add(obj);
			
			lastobj := obj;
			end;

          with obj do
            begin
            vnum := af.readInteger();
            name := af.readLine();
            short := af.readLine();
            long := af.readLine();

            a := af.readLine;
            item_type :=StrToInt(left(a,' '));
            a := right(a,' ');
            wear_location1 := left(a,' ');
            a := right(a,' ');
            wear_location2 := left(a,' ');

            a := af.readLine;
            value[1] := StrToInt(left(a,' '));
            a := right(a,' ');
            value[2] := StrToInt(left(a,' '));
            a := right(a,' ');
            value[3] := StrToInt(left(a,' '));
            a := right(a,' ');
            value[4] := StrToInt(left(a,' '));

            a := af.readLine;
            weight := StrToInt(left(a,' '));
            a := right(a,' ');
            flags := StrToInt(left(a,' '));
            a := right(a,' ');
            cost := StrToInt(left(a,' '));
            a := right(a, ' ');
            count := strtointdef(left(a, ' '), 1);
            
            inc(carried_weight, weight);
            
            if (count = 0) then
              count := 1;

            room := nil;
  
						g := af.readToken();
						
						if (g = 'A') then
							begin
							aff := GAffect.Create();

							aff.name := af.readToken();
							aff.wear_msg := '';

							aff.duration := af.readInteger();
							num := 1;

							while (not af.eol) and (af.readToken() = '{') do
								begin
								setLength(aff.modifiers, num);

								aff.modifiers[num - 1].apply_type := findApply(af.readToken);

								g := af.readToken();

								modif := cardinal(findSkill(g));

								if (modif = 0) then
									modif := strtointdef(g, 0);

								aff.modifiers[num - 1].modifier := modif;

								g := af.readToken();

								inc(num);
								end;
							
							obj.affects.insertLast(aff);

							g := af.readLine();
        			end;
        		end;
			
			objectList.add(obj);
			end;		            
      until (uppercase(g) = '#END') or (af.eof);

      if (uppercase(g) = '#END') then
        dec(inner);
      end
    else
    if (s = '#TROPHY') then
      begin
      inc(inner);
      repeat
        g := af.readLine;

        if (uppercase(g) <> '#END') and (not af.eof) then
          begin
          inc(trophysize);
          g := right(g,' ');
          trophy[trophysize].name := left(g,' ');
          g := right(g,' ');
          trophy[trophysize].level := strtoint(left(g,' '));
          g := right(g,' ');
          trophy[trophysize].times := strtoint(left(g,' '));
          end;
      until (uppercase(g) = '#END') or (af.eof);

      if (uppercase(g) = '#END') then
        dec(inner);
      end;
  until (af.eof);

  af.Free();

  if (inner <> 0) then
    begin
    bugreport('GPlayer.load', 'chars.pas', 'corrupted playerfile ' + name);

    race := GRace(raceList.head.element);
    end;

  if (race <> nil) then
    begin
    save_poison := race.save_poison;
    save_cold := race.save_cold;
    save_para := race.save_para;
    save_breath := race.save_breath;
    save_spell := race.save_spell;
    hitroll := UMax((level div 5)+50,100);
    
    node := race.abilities.head;
    
    while (node <> nil) do
      begin
      SET_LEARNED(100, GSkill(node.element));
      
      node := node.next;
      end;
    end
  else
  	begin
    bugreport('GPlayer.load', 'chars.pas', 'corrupted playerfile ' + name);

    race := GRace(raceList.head.element);
    end;

  calcAC();
  calcRank();
  
  // backwards compatibility fixes
  REMOVE_BIT(aff_flags, AFF_BASHED);
  REMOVE_BIT(aff_flags, AFF_STUNNED);

  load := true;
end;

// Save player
function GPlayer.save(const fn : string) : boolean;
var
	af : GFileWriter;
	temp : TDateTime;
	h : integer;
	obj, obj_in : GObject;
	al : GAlias;
	g : GLearned;
	aff : GAffect;
	fl : cardinal;
	tc : GUserChannel;
	iterator, inner_iterator : GIterator;
	w1, w2 : string;
	field : GPlayerField;
begin
  if (IS_NPC) then
    begin
    Result := false;
    exit;
    end;

  try
    af := GFileWriter.Create('players\' + fn + '.usr');
  except
    save := false;
    exit;
  end;

	// reset the character to a basic state (without affects) before writing
	iterator := affects.iterator();

	while (iterator.hasNext()) do
		begin
		aff := GAffect(iterator.next());

		aff.modify(Self, false);
		end;

	try
		af.writeLine('#PLAYER');
		af.writeLine('User: ' + name);
		af.writeLine('MD5-Password: ' + MD5Print(md5_password));
		af.writeLine('Sex: ' + IntToStr(sex));
		af.writeLine('Race: ' + race.name);
		af.writeLine('Alignment: ' + IntToStr(alignment));
		af.writeLine('Level: ' + IntToStr(level));
		af.writeLine('Weight: ' + IntToStr(weight));
		af.writeLine('Height: ' + IntToStr(height));
		af.writeLine('aff_flags: ' + IntToStr(aff_flags));
		af.writeLine('Mentalstate: ' + IntToStr(mental_state));
		af.writeLine('Last-login: ' + DateTimeToStr(Now));

		af.writeLine('Title: ' + title);
		af.writeLine('Age: ' + IntToStr(age));
		af.writeLine('Gold: ' + IntToStr(gold) + ' ' + IntToStr(bankgold));
		af.writeLine('XP: ' + IntToStr(xptot) + ' ' + IntToStr(xptogo));
		af.writeLine('Kills: ' + IntToStr(kills));
		af.writeLine('Deaths: ' + IntToStr(deaths));
		af.writeLine('Practices: ' + IntToStr( pracs));
		af.writeLine('Bamfin: ' + bamfin);
		af.writeLine('Bamfout: ' + bamfout);
		af.writeLine('Taunt: ' + taunt);
		af.writeLine('Prompt: ' + prompt);
		af.writeLine('Active_board: ' + IntToStr( active_board));
		af.writeLine('Read-notes: ' + IntToStr(boards[BOARD1]) +  ' ' + IntToStr(boards[BOARD2]) + ' ' + IntToStr(boards[BOARD3]) + ' ' + IntToStr(boards[BOARD_NEWS]) + ' ' + IntToStr(boards[BOARD_IMM]));

		fl := flags;
		REMOVE_BIT(fl, PLR_LINKLESS);
		REMOVE_BIT(fl, PLR_LOADED);

		af.writeLine('Flags: ' + IntToStr(fl));
		af.writeLine('Config: ' + IntToStr(cfg_flags));
		af.writeLine('Remorts: ' + IntToStr(remorts));
		af.writeLine('Wimpy: ' + IntToStr(wimpy));
		af.writeLine('Logon: ' + IntToStr(trunc(logon_first)) + ' ' + IntToStr(trunc(frac(logon_first)*MSecsPerDay)));

		temp:=played + (Now - logon_now);
		af.writeLine('Played: ' + IntToStr(trunc(temp)) + ' ' + IntToStr(trunc(frac(temp)*MSecsPerDay)));

		af.writeLine('Condition: ' + IntToStr(condition[COND_DRUNK]) + ' ' + IntToStr(condition[COND_FULL]) +
						' ' + IntToStr(condition[COND_THIRST]) + ' ' + IntToStr(condition[COND_CAFFEINE]) + ' ' + IntToStr(condition[COND_HIGH]));

		if clan<>nil then
			af.writeLine('Clan: ' + clan.name);

		if area_fname<>'' then
			af.writeLine('Area: ' + area_fname);

		af.writeLine('Ranges: ' + IntToStr(r_lo) + ' ' + IntToStr(r_hi) + ' ' + IntToStr(m_lo) + ' ' + IntToStr(m_hi) + ' ' + IntToStr(o_lo) + ' ' + IntToStr(o_hi));

		af.writeLine('Wizlevel: ' + IntToStr(wiz_level));
		af.writeLine('BGpoints: ' + IntToStr(bg_points));
		af.writeLine('Pagerlen: ' + IntToStr(pagerlen));

		af.writeLine('Stats: ' + IntToStr(str) + ' ' + IntToStr(con) + ' ' + IntToStr(dex) + ' ' + IntToStr(int) + ' ' + IntToStr(wis));

		af.writeLine('APB: ' + IntToStr(apb));
		af.writeLine('Mana: ' + IntToStr(mana) + ' ' + IntToStr(max_mana));
		af.writeLine('HP: ' + IntToStr(hp) + ' ' + IntToStr(max_hp));
		af.writeLine('Mv: ' + IntToStr(mv) + ' ' + IntToStr(max_mv));
		af.writeLine('AC: ' + IntToStr(ac));
		af.writeLine('HAC: ' + IntToStr(hac));
		af.writeLine('BAC: ' + IntToStr(bac));
		af.writeLine('AAC: ' + IntToStr(aac));
		af.writeLine('LAC: ' + IntToStr(lac));
		af.writeLine('AC_mod: ' + IntToStr(ac_mod));
		af.writeLine('RoomVNum: ' + IntToStr(room.vnum));

		iterator := channels.iterator();

		while (iterator.hasNext()) do
			begin
			tc := GUserChannel(iterator.next());

			if (tc.ignored) then
				af.writeLine('Ignore: ' + tc.channelname);
			end;

		iterator.Free();

		iterator := fieldList.iterator();

		while (iterator.hasNext()) do
			begin
			field := GPlayerField(iterator.next());

			af.writeLine(field.name + ': ' + field.toString(fields[field.name]));
			end;

		iterator.Free();

		af.writeLine('#END');
		af.writeLine('');

		af.writeLine('#SKILLS');

		iterator := skills_learned.iterator();

		while (iterator.hasNext()) do
			begin
			g := GLearned(iterator.next());

			af.writeLine( 'Skill: ''' + GSkill(g.skill).name + ''' ' + IntToStr(g.perc));
			end;
			
		iterator.Free();

		af.writeLine('#END');
		af.writeLine('');

		af.writeLine('#AFFECTS');

		iterator := affects.iterator();

		while (iterator.hasNext()) do
			begin
			aff := GAffect(iterator.next());

			with aff do
				begin
				af.writeString('''' + name + ''' ''' + wear_msg + ''' ');
				af.writeInteger(duration);

				for h := 0 to length(modifiers) - 1 do
					begin
					af.writeString(' { ');

					af.writeString(printApply(modifiers[h].apply_type) + ' ');

					case modifiers[h].apply_type of
						APPLY_STRIPNAME: af.writeString(PString(modifiers[h].modifier)^);
						else
							af.writeInteger(modifiers[h].modifier);
					end;

					af.writeString(' }');
					end;

				af.writeLine('');
				end;
			end;
			
		iterator.Free();

		af.writeLine('#END');
		af.writeLine('');

		af.writeLine( '#ALIASES');

		iterator := aliases.iterator();

		while (iterator.hasNext()) do
			begin
			al := GAlias(iterator.next());

			af.writeLine(al.alias + ':' + al.expand);
			end;
			
		iterator.Free();

		af.writeLine( '#END');
		af.writeLine('');

		af.writeLine('#OBJECTS');

		iterator := inventory.iterator();

		while (iterator.hasNext()) do
			begin
			obj := GObject(iterator.next());

			af.writeLine('none');

			af.writeLine(IntToStr(obj.vnum));

			af.writeLine(obj.name);
			af.writeLine(obj.short);
			af.writeLine(obj.long);
			af.writeLine(IntToStr(obj.item_type) + ' ' + obj.wear_location1 + ' ' + obj.wear_location2);
			af.writeLine(IntToStr(obj.value[1]) + ' ' + IntToStr(obj.value[2]) + ' ' + IntToStr(obj.value[3]) + ' ' + IntToStr(obj.value[4]));
			af.writeLine(IntToStr(obj.weight) + ' ' + IntToStr(obj.flags) + ' ' + IntToStr(obj.cost) + ' ' + IntToStr(obj.count));

			if (obj.affects.size() > 0) then
				begin
				inner_iterator := obj.affects.iterator();
				
				while (inner_iterator.hasNext()) do
					begin
					aff := GAffect(inner_iterator.next());
					
					with aff do
						begin
						af.writeString('A "' + name + '" ');
						af.writeInteger(duration);

						for h := 0 to length(modifiers) - 1 do
							begin
							af.writeString(' { ');

							af.writeString(printApply(modifiers[h].apply_type) + ' ');

							case modifiers[h].apply_type of
								APPLY_STRIPNAME: af.writeString(PString(modifiers[h].modifier)^);
								else
									af.writeInteger(modifiers[h].modifier);
							end;

							af.writeString(' }');
							end;

						af.writeLine('');
						end;
					end;

				inner_iterator.Free();
				end;
				
			if (obj.contents.size() > 0) then
				begin
				inner_iterator := obj.contents.iterator();
				
				while (inner_iterator.hasNext()) do
					begin
					obj_in := GObject(inner_iterator.next());
			
					af.writeLine('##');

					af.writeLine(IntToStr(obj_in.vnum));

					af.writeLine(obj_in.name);
					af.writeLine(obj_in.short);
					af.writeLine(obj_in.long);
					af.writeLine(IntToStr(obj_in.item_type) + ' ' + obj_in.wear_location1 + ' ' + obj_in.wear_location2);
					af.writeLine(IntToStr(obj_in.value[1]) + ' ' + IntToStr(obj_in.value[2]) + ' ' + IntToStr(obj_in.value[3]) + ' ' + IntToStr(obj_in.value[4]));
					af.writeLine(IntToStr(obj_in.weight) + ' ' + IntToStr(obj_in.flags) + ' ' + IntToStr(obj_in.cost) + ' ' + IntToStr(obj_in.count));
					end;
					
				inner_iterator.Free();
				end;
			end;

		iterator.Free();

		iterator := equipment.iterator();

		while (iterator.hasNext()) do
			begin
			obj := GObject(iterator.next());

			af.writeLine(obj.worn);

			af.writeLine(IntToStr(obj.vnum));

			af.writeLine(obj.name);
			af.writeLine(obj.short);
			af.writeLine(obj.long);

			if (obj.wear_location1 = '') then
				w1 := 'none'
			else
				w1 := obj.wear_location1;

			if (obj.wear_location2 = '') then
				w2 := 'none'
			else
				w2 := obj.wear_location2;

			af.writeLine(IntToStr(obj.item_type) + ' ' + w1 + ' ' + w2);
			af.writeLine(IntToStr(obj.value[1]) + ' ' + IntToStr(obj.value[2]) + ' ' + IntToStr(obj.value[3]) + ' ' + IntToStr(obj.value[4]));
			af.writeLine(IntToStr(obj.weight) + ' ' + IntToStr(obj.flags) + ' ' + IntToStr(obj.cost) + ' ' + IntToStr(obj.count));

			if (obj.affects.size() > 0) then
				begin
				inner_iterator := obj.affects.iterator();
				
				while (inner_iterator.hasNext()) do
					begin
					aff := GAffect(inner_iterator.next());
					
					with aff do
						begin
						af.writeString('A "' + name + '" ');
						af.writeInteger(duration);

						for h := 0 to length(modifiers) - 1 do
							begin
							af.writeString(' { ');

							af.writeString(printApply(modifiers[h].apply_type) + ' ');

							case modifiers[h].apply_type of
								APPLY_STRIPNAME: af.writeString(PString(modifiers[h].modifier)^);
								else
									af.writeInteger(modifiers[h].modifier);
							end;

							af.writeString(' }');
							end;

						af.writeLine('');
						end;
					end;
				inner_iterator.Free();
				end;

			if (obj.contents.size() > 0) then
				begin
				inner_iterator := obj.contents.iterator();
				
				while (inner_iterator.hasNext()) do
					begin
					obj_in := GObject(inner_iterator.next());
			
					af.writeLine('##');

					af.writeLine(IntToStr(obj_in.vnum));

					af.writeLine(obj_in.name);
					af.writeLine(obj_in.short);
					af.writeLine(obj_in.long);
					af.writeLine(IntToStr(obj_in.item_type) + ' ' + obj_in.wear_location1 + ' ' + obj_in.wear_location2);
					af.writeLine(IntToStr(obj_in.value[1]) + ' ' + IntToStr(obj_in.value[2]) + ' ' + IntToStr(obj_in.value[3]) + ' ' + IntToStr(obj_in.value[4]));
					af.writeLine(IntToStr(obj_in.weight) + ' ' + IntToStr(obj_in.flags) + ' ' + IntToStr(obj_in.cost) + ' ' + IntToStr(obj_in.count));
					end;
					
				inner_iterator.Free();
				end;
			end;

		iterator.Free();

		af.writeLine('#END');
		af.writeLine('');

		af.writeLine('#TROPHY');
		for h := 1 to trophysize do
			af.writeLine('Trophy: ' + trophy[h].name + ' ' + IntToStr(trophy[h].level) + ' ' + IntToStr(trophy[h].times));
		af.writeLine('#END');
	finally
		af.Free();
	end;

	// re-apply affects to character
	iterator := affects.iterator();

	while (iterator.hasNext()) do
		begin
		aff := GAffect(iterator.next());

		aff.modify(Self, true);
		end;

  save := true;
end;

procedure GPlayer.sendBuffer(const s : string);
begin
  if (snooped_by <> nil) then
   	begin
   	if (not snooped_by.IS_NPC) then
    	GConnection(GPlayer(snooped_by).conn).send(s); 
    end;

// Xenon 21/Feb/2001: I think someone snooping still wants to see output of his own commands
// Grimlord 18/Aug/2002: A switched player should not, too much clutter
  if (conn = nil) or (not IS_NPC and (switching <> nil)) then
    exit;

  if (IS_EDITING) then
    exit;

	GConnection(conn).writeBuffer(s, in_command);
end;

procedure GPlayer.sendPager(const txt : string);
begin
  if (conn = nil) then
    exit;

  if (IS_NPC) or (not IS_SET(cfg_flags,CFG_PAGER)) then
    sendBuffer(txt)
  else
    conn.writePager(txt);
end;

procedure GPlayer.emptyBuffer();
begin
  if (conn = nil) then
    exit;

	conn.emptyBuffer();
end;

// Start editing mode
procedure GPlayer.startEditing(const text : string);
begin
  if (conn = nil) then
    exit;

	conn.startEditing();

  if (substate = SUB_SUBJECT) then
    begin
    sendBuffer(ansiColor(7) + #13#10 + 'Subject: ');
    exit;
    end;

  GConnection(conn).send(ansiColor(7) + #13#10 + 'Use ~ on a blank line to end. Use .h on a blank line to get help.'#13#10);
  GConnection(conn).send(ansiColor(7) + '----------------------------------------------------------------------'#13#10'> ');

  edit_buffer := text;
  afk := true;
end;

// Return from editing mode
procedure GPlayer.stopEditing();
begin
  sendBuffer('Ok.'#13#10);

  edit_buffer := '';
  substate := SUB_NONE;
  afk := false;
  
  conn.stopEditing();

  sendBuffer('You are now back at your keyboard.'#13#10);
  act(AT_REPORT,'$n has returned to $s keyboard.',false,Self,nil,nil,to_room);
end;

procedure GPlayer.sendEdit(const text : string);
begin
  case substate of
    SUB_NOTE:
      begin
        postNote(Self, text);

        edit_buffer := '';
        substate := SUB_NONE;

        conn.stopEditing();
        afk := false;

        sendBuffer('Note posted.'#13#10);

        act(AT_REPORT,'You are now back at your keyboard.',false,Self,nil,nil,TO_CHAR);
        act(AT_REPORT,'$n finished $s note and is now back at the keyboard.',false,Self,nil,nil,TO_ROOM);

        if (active_board = BOARD_IMM) then
          begin
          act(AT_REPORT,'There is a new note on the ' + board_names[active_board] + ' board.', false, Self, nil, nil, TO_IMM);
          act(AT_REPORT,'Written by ' + name + '.',false,Self,nil,nil,TO_IMM);
          end
        else
          begin
          act(AT_REPORT,'There is a new note on the ' + board_names[active_board] + ' board.', false, Self, nil, nil, TO_ALL);
          act(AT_REPORT,'Written by ' + name + '.', false, Self, nil, nil, TO_ALL);
          end;

        exit;
      end;
    SUB_ROOM_DESC :
      begin
        interpret(Self, 'redit');
        conn.stopEditing();
        afk := false;
        edit_buffer := '';
        substate := SUB_NONE;
        edit_dest := nil;
      end
    else
    begin
      bugreport('GPlayer.sendEdit()', 'chars.pas', 'unrecognized substate');
    end;
  end;
end;

procedure GPlayer.editBuffer(text : string);
begin
  if (conn = nil) then
    exit;

  if (substate = SUB_SUBJECT) then
    begin
    if (length(text) = 0) then
      subject := 'nil'
    else
      subject := text;

    substate := SUB_NOTE;
    startEditing('');
    exit;
    end;

  if (length(text) > 0) and (text[1] = '.') then
	  begin
    text := uppercase(text);
    
    case text[2] of
      'H' :
      	begin
				GConnection(conn).send(ansiColor(7) + '.h  this help' + #13#10);
				GConnection(conn).send(ansiColor(7) + '.c  clear current text' + #13#10);
				GConnection(conn).send(ansiColor(7) + '.v  see current text' + #13#10);
				GConnection(conn).send(ansiColor(7) + '.w  to write and quit' + #13#10);
				GConnection(conn).send(ansiColor(7) + '.q  to quit without writing' + #13#10);
				end;
      'C' :
        begin
				edit_buffer := '';
				GConnection(conn).send(ansiColor(7) + 'Ok, buffer cleared.' + #13#10);
        end;
      'V' :
        begin
				GConnection(conn).send(ansiColor(7) + 'Current text:' + #13#10);
				GConnection(conn).send(ansiColor(7) + '----------------------------------------------------------------------' + #13#10);
				GConnection(conn).send(ansiColor(7) + edit_buffer + #13#10);
        end;
      'W' :
      	begin
	      sendEdit(edit_buffer);
      	end;
      'Q' :
      	begin
      	stopEditing();
      	end;
    
    else
        GConnection(conn).send(ansiColor(7) + 'Enter .h on a blank line for help.' + #13#10);
    end;
    
    sendPrompt();
    exit;
  	end;

  edit_buffer := edit_buffer + text + #13#10;
  GConnection(conn).send(ansiColor(7) + '> ');
end;

function GPlayer.ansiColor(color : integer) : string;
begin
  if (not IS_SET(cfg_flags, CFG_ANSI)) then
    ansiColor := ''
  else
    ansiColor := ansiio.ANSIColor(color, 0);
end;

// Send prompt
procedure GPlayer.sendPrompt();
var
   s, pr, buf : string;
   t : integer;
begin
	if (conn.isEditing()) then
		begin
		conn.send('> ');
		exit;
		end;

	if (conn.pagepoint > 0) then
		exit;

  if (prompt = '') then
    pr := '%hhp %mmv %ama (%l)%t%f> '
  else
    pr := prompt;

  buf := ansiColor(7);

  if (bash_timer > 0) then
    buf := buf +  '[' + inttostr(bash_timer) + '] (Bashed) ';

  if (bashing > 0) then
    buf := buf +  '[' + inttostr(bashing) + '] ';

  if (IS_AFK) then
    buf := buf +  '(AFK) ';

  if (not IS_NPC) then
    begin
    if (substate = SUB_SUBJECT) then
      begin
      conn.send(' ');
      exit;
      end;

    if (conn.isEditing()) then
      begin
      conn.send('> ');
      exit;
      end;

    if (conn.pagepoint > 0) then
      exit;
    end;

  if (hasTimer(Self, TIMER_ACTION) <> nil) then
    buf := buf + '+';

  if (IS_IMMORT) then
    buf := buf + '#' + inttostr(room.vnum) + ' [' + sector_types[room.sector] + '] ';

  if (IS_IMMORT) and (room.areacoords <> nil) then
    buf := buf + room.areacoords.toString() + ' ';
    
  t := 1;
  s := '';

  while (t <= length(pr)) do
    begin
    if (pr[t] = '%') then
      begin
      case pr[t + 1] of
        'h':  s := s + inttostr(hp);
        'H':  s := s + inttostr(max_hp);
        'm':  s := s + inttostr(mv);
        'M':  s := s + inttostr(max_mv);
        'a':  s := s + inttostr(mana);
        'A':  s := s + inttostr(max_mana);
        'l':  s := s + inttostr(level);
        'x':  s := s + inttostr(xptogo);
        'f':  begin
              if (fighting <> nil) and (state = STATE_FIGHTING) then
                begin
                s := s + ' [Oppnt: ';

                with fighting do
                  s := s + hp_perc[UMax(round((hp / max_hp) * 5), 0)];

                s := s + ']';
                end;
              end;
        't':  begin
              if (fighting <> nil) and (position = STATE_FIGHTING) then
               if (fighting.fighting <> nil) and (fighting.fighting <> Self) then
                 begin
                 s := s + ' [' + fighting.fighting.name + ': ';

                 with fighting.fighting do
                   s := s + hp_perc[UMax(round((hp / max_hp) * 5), 0)];

                 s := s + ']';
                 end;
              end;
        else s := s + '%' + pr[t + 1];
      end;

      inc(t);
      end
    else
      s := s + pr[t];

    inc(t);
    end;

  buf := buf + act_color(Self, s, '%') + '> ';

{  if (snooped_by <> nil) then
    begin
    if IS_SET(snooped_by.cfg_flags,CFG_BLANK) then   // Xenon 21/Feb/2001: send extra blank line if config says so
      GConnection(snooped_by.conn).send(#13#10);
    GConnection(snooped_by.conn).send(buf);
    end; }

  if (IS_SET(cfg_flags, CFG_BLANK)) then
		conn.send(#13#10 + buf)
	else  
	  conn.send(buf);
end;

// Player dies
procedure GPlayer.die();
var
   node : GListNode;
begin
  inherited die();

  { when ch died in bg, get him back to room - Grimlord }
  if (bg_status = BG_PARTICIPATE) then
    begin
    hp := max_hp;
    bg_status := BG_NOJOIN;
    fromRoom();
    toRoom(bg_room);
    exit;
    end;

  extract(false);
  hp := 5;
  mana := 0;
  condition[COND_FULL] := 100;
  condition[COND_THIRST] := 100;
  condition[COND_DRUNK] := 0;
  condition[COND_HIGH] := 0;
  condition[COND_CAFFEINE] := 0;
  mv := max_mv;

  while (true) do
    begin
    node := affects.head;

    if (node = nil) then
      break;

    removeAffect(Self, GAffect(node.element));
    end;
end;

// Calculate rank
procedure GPlayer.calcRank();
var
	r : string;
begin
  if level<30 then
    r:='an apprentice'
  else
  if level<60 then
    r:='a student'
  else
  if level<100 then
    r:='a scholar'
  else
  if level<150 then
    r:='knowledgeable'
  else
  if level<200 then
    r:='skilled'
  else
  if level<250 then
    r:='experienced'
  else
  if level<300 then
    r:='well known'
  else
  if level<350 then
    r:='powerful'
  else
  if level<400 then
    r:='brave'
  else
  if level<450 then
    r:='a hero'
  else
  if level<=500 then
    r:='a legend'
  else
    r:='a god';

  rank := r;
end;


// GPlayerField
constructor GPlayerField.Create(const name : string);
begin
	inherited Create();
	
	_name := prep(name);
end;

// GPlayerFieldFlag
function GPlayerFieldFlag.default() : TObject;
begin
	Result := GBitVector.Create(0);
end;

function GPlayerFieldFlag.fromString(const s : string) : TObject;
begin
	Result := GBitVector.Create(StrToIntDef(s, 0));
end;

function GPlayerFieldFlag.toString(x : TObject) : string;
begin
	Result := IntToStr((x as GBitVector).value);
end;

// GPlayerFieldInteger
function GPlayerFieldInteger.default() : TObject;
begin
	Result := GInteger.Create(0);
end;

function GPlayerFieldInteger.fromString(const s : string) : TObject;
begin
	Result := GInteger.Create(StrToIntDef(s, 0));
end;

function GPlayerFieldInteger.toString(x : TObject) : string;
begin
	Result := IntToStr((x as GInteger).value);
end;

// GPlayerFieldString
function GPlayerFieldString.default() : TObject;
begin
	Result := GString.Create('');
end;

function GPlayerFieldString.fromString(const s : string) : TObject;
begin
	Result := GString.Create(s);
end;

function GPlayerFieldString.toString(x : TObject) : string;
begin
	Result := (x as GString).value;
end;

procedure registerField(field : GPlayerField);
begin
	if (fieldList[field.name] <> nil) then
		fieldList.remove(field.name);
		
	fieldList[field.name] := field;
end;

procedure unregisterField(const name : string);
begin
	fieldList.remove(prep(name));
end;

// Find player by name
function findPlayerWorld(ch : GCharacter; name : string) : GCharacter;
var
	iterator : GIterator;
	vict : GCharacter;
	number, count : integer;
begin
  Result := nil;

  number := findNumber(name); // eg 2.char

  if (uppercase(name) = 'SELF') and (not ch.IS_NPC) then
    begin
    Result := ch;
    exit;
    end;

  count := 0;

  iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if ((isName(vict.name,name)) or (isName(vict.short,name))) and (not vict.IS_NPC) then
      begin    
      if (ch <> nil) and (not ch.CAN_SEE(vict)) then
        continue;

      inc(count);

      if (count = number) then
        begin
        Result := vict;
        exit;
        end;
      end;
    end;
    
  iterator.Free();
end;

function findPlayerWorldEx(ch : GCharacter; name : string) : GCharacter;
var
   iterator : GIterator;
   vict : GCharacter;
   number, count : integer;
begin
  Result := nil;

  number := findNumber(name); // eg 2.char

  if (uppercase(name) = 'SELF') and (not ch.IS_NPC) then
    begin
    Result := ch;
    exit;
    end;

  count := 0;

  iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (lowercase(vict.name) = lowercase(name)) and (not vict.IS_NPC) then
      begin    
      if (ch <> nil) and (not ch.CAN_SEE(vict)) then
        continue;

      inc(count);

      if (count = number) then
        begin
        Result := vict;
        exit;
        end;
      end;
    end;
    
  iterator.Free();
end;

function existsPlayer(const name : string) : boolean;
begin
	Result := FileExists('players\' + name + '.usr');
end;

procedure acceptConnection(list_socket : GSocket);
var
  ac : GSocket;
  conn : GPlayerConnection;
begin
  ac := list_socket.acceptConnection(system_info.lookup_hosts);
  
  ac.setNonBlocking();

  if (isMaskBanned(ac.hostString)) then
    begin
    writeConsole('(' + IntToStr(ac.getDescriptor) + ') Closed banned IP (' + ac.hostString + ')');

    ac.send(system_info.mud_name + #13#10#13#10);
    ac.send('Your site has been banned from this server.'#13#10);
    ac.send('For more information, please mail the administration, ' + system_info.admin_email + '.'#13#10);
    
    ac.Free();
    end
  else
  if (not serverBooted) then
    begin
    ac.send(system_info.mud_name+#13#10#13#10);
    ac.send('Currently, this server is in the process of a reboot.'#13#10);
    ac.send('Please try again later.'#13#10);
    ac.send('For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

    ac.Free();
    end
  else
  if system_info.deny_newconns then
    begin
    ac.send(system_info.mud_name+#13#10#13#10);
    ac.send('Currently, this server is refusing new connections.'#13#10);
    ac.send('Please try again later.'#13#10);
    ac.send('For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

    ac.Free();
    end
  else
  if (connection_list.size() >= system_info.max_conns) then
    begin
    ac.send(system_info.mud_name+#13#10#13#10);
    ac.send('Currently, this server is too busy to accept new connections.'#13#10);
    ac.send('Please try again later.'#13#10);
    ac.send('For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

    ac.Free();
    end
  else
  	begin
  	conn := GPlayerConnection.Create(ac, false, '');
  	conn.Resume();
  	end;
end;

procedure initPlayers();
begin
	fieldList := GHashTable.Create(PLAYER_FIELDS_HASHSIZE);
end;

procedure cleanupPlayers();
begin
	fieldList.clear();
	fieldList.Free();
end;

function playername(from_ch, to_ch : GCharacter) : string;
begin
  if (not to_ch.CAN_SEE(from_ch)) then
    playername := 'someone'
  else
  if (not to_ch.IS_NPC) and (not from_ch.IS_NPC) then
    begin
    if (from_ch.IS_IMMORT) then
      playername := from_ch.name
    else
    if (not to_ch.IS_SAME_ALIGN(from_ch)) then
      begin
      if (from_ch.race.name[1] in ['A','E','O','I','U']) then
        playername := '+* An ' + from_ch.race.name + ' *+'
      else
        playername := '+* A ' + from_ch.race.name + ' *+';
      end
    else
      playername := from_ch.name;
    end
  else
    playername := from_ch.name;

  if (from_ch = to_ch) then
    playername := 'you';
end;

function act_color(to_ch : GCharacter; const acts : string; sep : char) : string;
var
  last, current : integer;
  boldflag : boolean;
  res : string;
begin
  last := 1;
  current := FastCharPos(acts, sep, last);
  boldflag := false;
  res := '';
  
  while (current <> 0) do
    begin
    if (current - last > 0) then
      res := res + CopyStr(acts, last, current - last);

    last := current + 2;
       
    case acts[current + 1] of
        'B': boldflag := true;
        'A': boldflag := false;
   '0'..'9': begin
             if (boldflag) then
               res := res + to_ch.ansiColor(strtoint(acts[current + 1]) + 8)
             else
               res := res + to_ch.ansiColor(strtoint(acts[current + 1])); 
             end;
    end;
    
    current := FastCharPos(acts, sep, last);
    end;
    
  Result := res + CopyStr(acts, last, length(acts) - last + 1)
end;

function act_string(const acts : string; to_ch, ch : GCharacter; arg1, arg2 : pointer) : string;
var
  last, current : integer;
  res, temp : string;
  vch : GCharacter;
  obj1, obj2 : TObject;
  ex : GExit;
begin
  last := 1;
  current := FastCharPos(acts, '$', last);
  res := '';
  vch := arg2;
  obj1 := arg1; obj2 := arg2;

  while (current <> 0) do
    begin
    if (current - last > 0) then
      res := res + CopyStr(acts, last, current - last);

    last := current + 2;
       
		case acts[current + 1] of
			'n': res := res + playername(ch, to_ch);
			'N': begin
					 if (vch = nil) then
						 writeConsole('[BUG]: act() -> vch null')
					 else
						 res := res + playername(vch, to_ch);
					 end;
			'm': res := res + sex_nm[ch.sex];
			'M': begin
					 if (vch = nil) then
						 writeConsole('[BUG]: act() -> vch null')
					 else
						 res := res + sex_nm[vch.sex];
					 end;
			's': res := res + sex_bm[ch.sex];
			'S': begin
					 if (vch = nil) then
						 writeConsole('[BUG]: act() -> vch null')
					 else
						 res := res + sex_bm[vch.sex];
					 end;
			'e': res := res + sex_pm[ch.sex];
			'E': begin
					 if (vch = nil) then
						 writeConsole('[BUG]: act() -> vch null')
					 else
						 res := res + sex_pm[vch.sex];
					 end;
		 'o': begin
					 if (obj1 = nil) then
						 writeConsole('[BUG]: act() -> obj1 null')
					 else
						 res := res + GObject(obj1).name;
					 end;
			'O': begin
					 if (obj2 = nil) then
						 writeConsole('[BUG]: act() -> obj2 null')
					 else
						 res := res + GObject(obj2).name;
					 end;
			'p': begin
					 if (obj1 = nil) then
						 writeConsole('[BUG]: act() -> obj1 null')
					 else
						 res := res + GObject(obj1).short;
					 end;
			'P': begin
					 if (obj2 = nil) then
						 writeConsole('[BUG]: act() -> obj2 null')
					 else
						 res := res + GObject(obj2).short;
					 end;
			't': begin
					 if (arg1 = nil) then
						 writeConsole('[BUG]: act() -> pchar(arg1) null')
					 else
						 res := res + (PString(arg1))^;
					 end;
			'T': begin
					 if (arg2 = nil) then
						 writeConsole('[BUG]: act() -> pchar(arg2) null')
					 else
						 res := res + (PString(arg2))^;
					 end;
			'd': begin
						 if (arg2 = nil) then
							 writeConsole('[BUG]: act() -> arg2 is nil')
						 else
						 begin
							 ex := GExit(arg2);

							 if ((ex.keywords <> nil) and (length(ex.keywords^) = 0)) then
								 res := res + 'door'
							 else
							   begin
								 one_argument(ex.keywords^, temp);
								 res := res + temp;
								 end;
						 end;
					 end;
			else
			  res := res + '$' + acts[current + 1];
		end;
    
    current := FastCharPos(acts, '$', last);
    end;
    
  res := cap(res + CopyStr(acts, last, length(acts) - last + 1));

  Result := act_color(to_ch, res, '$');
end;

procedure act(atype : integer; const acts : string; hideinvis : boolean; ch : GCharacter;
              arg1, arg2 : pointer; typ : integer);
{ Documentation of act routine:

  atype         - Ansi color to start with
  acts          - A string to send
  hideinvis     - Hide action when ch is invisible?
  ch            - Number of character
  arg1, arg2    - Respectively object or character
  type          - Who gets the resulting string:
                      TO_ROOM     = everybody in the room, except ch
                      TO_VICT     = character in vict
                      TO_NOTVICT  = everybody in the room, except ch and vict
                      TO_CHAR     = to ch
                      TO_ALL      = to everyone, except ch
  prompt        - Do we need to send a prompt after the string?
}

function HIDE_VIS(ch, vict : GCharacter) : boolean;
begin
  if (ch = nil) then
    HIDE_VIS := false
  else
    HIDE_VIS := (not ch.CAN_SEE(vict)) and (hideinvis);
end;

var 
	txt : string;
	vch : GCharacter;
	to_ch : GCharacter;
	node : GListNode;
	actList : TList;
	x : integer;

label wind;
begin
  if (length(acts) = 0) then
    exit;

  vch := GCharacter(arg2);

  if (ch = nil) and (typ <> TO_ALL) then
    begin
    writeConsole('[BUG]: act() -> ch null');
    exit;
    end;

  if (typ = TO_CHAR) then
    node := ch.node_world
  else
  if (typ = TO_VICT) then
    begin
    if (vch = nil) then
      begin
      writeConsole('[BUG]: act() -> vch null');
      exit;
      end;

    node := vch.node_world;
    end
  else
  if (typ = TO_ALL) then
    node := char_list.head
  else
  if (typ = TO_ROOM) or (typ = TO_NOTVICT) then
    node := ch.room.chars.head
  else
    node := nil;
    
  actList := TList.Create();

  while (node <> nil) do
    begin
    to_ch := GCharacter(node.element);

    if ((not to_ch.IS_AWAKE) and (to_ch <> ch)) then goto wind;

    if (typ = TO_CHAR) and (to_ch <> ch) then
      goto wind;
    if (typ = TO_VICT) and ((to_ch <> vch) or (to_ch = ch) or (HIDE_VIS(to_ch, ch))) then
      goto wind;
    if (typ = TO_ROOM) and ((to_ch = ch) or (HIDE_VIS(to_ch, ch))) then
      goto wind;
    if (typ = TO_ALL) and (to_ch = ch) then
      goto wind;
    if (typ = TO_NOTVICT) and ((to_ch = ch) or (to_ch = vch)) then
      goto wind;
    if (typ = TO_IMM) and ((to_ch = ch) or (not to_ch.IS_IMMORT)) then
     goto wind;

    txt := act_string(acts, to_ch, ch, arg1, arg2);

    to_ch.sendBuffer(to_ch.ansiColor(atype) + txt + #13#10);

    if (to_ch.IS_NPC) and (to_ch <> ch) then
    	begin
    	if (GNPC(to_ch).context.existsSymbol('onAct')) then
    		actList.add(to_ch);
    	end;

wind:
     if (typ = TO_CHAR) or (typ = TO_VICT) or (typ = TO_IMM) then
       node := nil
     else
     if (typ = TO_ROOM) or (typ = TO_NOTVICT) or (typ = TO_ALL) then
       node := node.next;
     end;

	if (actList.Count > 0) then
		begin
		for x := 0 to actList.Count - 1 do
			begin
			GNPC(actList[x]).context.runSymbol('onAct', [integer(actList[x]), integer(ch), txt]);
			end;
		end;
	
	actList.Free();
end;

end.