{
	Summary:
		Player specific functions
	
	## $Id: player.pas,v 1.2 2003/12/12 23:01:18 ***REMOVED*** Exp $
}
unit player;

interface


uses
	md5,
	area,
	dtypes,
	conns,
	socket,
	constants,
	chars;


const
	PLAYER_FIELDS_HASHSIZE = 256;


type
	GPlayer = class;

	GPlayerConnection = class(GConnection)
	protected
		_state : integer;
		_ch : GPlayer;

		_pagepoint : integer;
		pagebuf : string;
		pagecmd : char;
		fcommand : boolean;

		procedure OnOpenEvent();
		procedure OnInputEvent();
		function OnTickEvent() : boolean;
		procedure OnOutputEvent();
		procedure OnCloseEvent();

	public
		constructor Create(socket : GSocket; from_copyover : boolean = false; copyover_name : string = '');

		procedure writePager(txt : string);
		procedure setPagerInput(argument : string);
		procedure outputPager;

		function findDualConnection(const name: string) : GPlayer;
		procedure nanny(argument : string);

	published
		property state : integer read _state write _state;

		property pagepoint : integer read _pagepoint write _pagepoint;

		property ch: GPlayer read _ch write _ch;
	end;
	
	GPlayer = class(GCharacter)   	
	protected
		_keylock: boolean;
		_afk : boolean;
		_fields : GHashTable;
		
		function getField(name : string) : TObject;
		procedure putField(name : string; obj : TObject);

	public
		edit_buffer : string;
		edit_dest : pointer;

		pagerlen : integer;
		title : string;                     { Title of PC }
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
		max_skills, max_spells : integer;
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

		property fields[name : string] : TObject read getField write putField; 

	published
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

		function load(fn : string) : boolean;
		function save(fn : string) : boolean;

		function getAge : integer;
		function getPlayed : integer;

		procedure die; override;
		procedure calcRank;

		procedure quit;

		procedure sendPrompt; override;
		procedure sendBuffer(s : string); override;
		procedure sendPager(txt : string); override;
		procedure emptyBuffer; override;

		procedure startEditing(text : string);
		procedure stopEditing;
		procedure editBuffer(text : string);
		procedure sendEdit(text : string);

		property keylock : boolean read _keylock write _keylock;
		property afk : boolean read _afk write _afk;	
	end;

	GPlayerField = class
	protected
  	_name : string;
  	
  public		
  	constructor Create(name : string);
  	
		function default() : TObject; virtual; abstract;
		function fromString(s : string) : TObject; virtual; abstract;
		function toString(x : TObject) : string; virtual; abstract;
		
		property name : string read _name;
	end;
	
	GPlayerFieldFlag = class(GPlayerField)
	public
  	function default() : TObject; override;
  	function fromString(s : string) : TObject; override;
  	function toString(x : TObject) : string; override;	
	end;

	GPlayerFieldInteger = class(GPlayerField)
	public
  	function default() : TObject; override;
  	function fromString(s : string) : TObject; override;
  	function toString(x : TObject) : string; override;	
	end;
	
	GPlayerFieldString = class(GPlayerField)
	public
  	function default() : TObject; override;
  	function fromString(s : string) : TObject; override;
  	function toString(x : TObject) : string; override;	
	end;


var
	fieldList : GHashTable;

procedure registerField(field : GPlayerField);
procedure unregisterField(name : string);

function findPlayerWorld(ch : GCharacter; name : string) : GCharacter;
function findPlayerWorldEx(ch : GCharacter; name : string) : GCharacter;

function existsPlayer(name : string) : boolean;

procedure initPlayers();
procedure cleanupPlayers();

implementation


uses
	Math,
	SysUtils,
	ansiio,
	timers,
	console,
	util,
	strip,
	commands,
	skills,
	fsys,
	race,
	mudsystem,
	mudhelp,
	clan,
	events,
	bulletinboard,
	Channels;
	

// GPlayerConnection
constructor GPlayerConnection.Create(socket : GSocket; from_copyover : boolean = false; copyover_name : string = '');
begin
	inherited Create(socket);
	
	FOnOpen := OnOpenEvent;
	FOnClose := OnCloseEvent;
	FOnTick := OnTickEvent;
	FOnInput := OnInputEvent;
	FOnOutput := OnOutputEvent;
	
	state := CON_NAME;
	
	ch := GPlayer.Create(Self);

  node := connection_list.insertLast(Self);

	Resume();
end;

procedure GPlayerConnection.OnOpenEvent();
var
  temp_buf : string;
begin
  //if (not copyover) then
    begin
    state := CON_NAME;

    send(AnsiColor(2,0) + findHelp('M_DESCRIPTION_').text);

    temp_buf := AnsiColor(6,0) + #13#10;

    temp_buf := temp_buf + version_info + ', ' + version_number + '.'#13#10;
    temp_buf := temp_buf + version_copyright + '.';
    temp_buf := temp_buf + AnsiColor(7,0) + #13#10;

    send(temp_buf);

    send(#13#10#13#10'Enter your name or CREATE to create a new character.'#13#10'Please enter your name: ');
    end
{  else
  	begin
    conn.state := CON_MOTD;

    conn.ch.setName(copyover_name);
    conn.ch.load(copyover_name);
    conn.send(#13#10#13#10'Gradually, the clouds form real images again, recreating the world...'#13#10);
    conn.send('Copyover complete!'#13#10);

    nanny(conn, '');
    end; }
end;

procedure GPlayerConnection.OnCloseEvent();
begin
	if (state = CON_LOGGED_OUT) then
		dec(system_info.user_cur)
	else
	if (not ch.CHAR_DIED) and ((state = CON_PLAYING) or (state = CON_EDITING)) then
		begin
		writeConsole('(' + IntToStr(socket.getDescriptor) + ') ' + ch.name + ' has lost the link');

		if (ch.level >= LEVEL_IMMORTAL) then
			interpret(ch, 'return');

		ch.conn := nil;

		act(AT_REPORT,'$n has lost $s link.',false,ch,nil,nil,TO_ROOM);
		SET_BIT(ch.flags,PLR_LINKLESS);
		end
	else
		begin
		writeConsole('(' + IntToStr(socket.getDescriptor) + ') Connection reset by peer');
		ch.Free;
		end;
end;

function GPlayerConnection.OnTickEvent() : boolean;
begin
	if (fcommand) then
		begin
		if (pagepoint <> 0) then
			outputPager()
		else
			ch.emptyBuffer();
		end;
		
	if (ch.wait > 0) then
		Result := false
	else
		Result := true;
end;

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
			CON_PLAYING: begin
									 if (IS_SET(ch.flags,PLR_FROZEN)) and (cmdline <> 'quit') then
										 begin
										 ch.sendBuffer('You have been frozen by the gods and cannot do anything.'#13#10);
										 ch.sendBuffer('To be unfrozen, send an e-mail to the administration, '+system_info.admin_email+'.'#13#10);
										 exit;
										 end;

									 ch.in_command:=true;
									 
									 interpret(ch, cmdline);

									 if (not ch.CHAR_DIED) then
										 ch.in_command := false;
									 end;
			CON_EDIT_HANDLE: ch.editBuffer(cmdline);
			CON_EDITING: ch.editBuffer(cmdline);
			else
				nanny(cmdline);
		end;
end;

procedure GPlayerConnection.OnOutputEvent();
begin
	ch.sendPrompt();
end;

//jago : new func for finding if a new connection is from an already connected player
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
	h,top,x,temp:integer;
	buf, pwd : string;
begin
  case state of
        CON_NAME: begin
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
                      state := CON_NEW_NAME;
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
                      state := CON_PLAYING;
                      ch.sendPrompt();
                      end;

                    exit;
                    end;

                  if (not ch.load(argument)) then
                    begin
                    send(#13#10'Are you sure about that name?'#13#10'Name: ');
                    exit;
                    end;

                  state:=CON_PASSWORD;
                  send('Password: ');
                  end;
    CON_PASSWORD: begin
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
                    ch.Free;

                    ch := vict;
                    ch := vict;
                    vict.conn := Self;

                    ch.ld_timer := 0;

                    send('You have reconnected.'#13#10);
                    act(AT_REPORT, '$n has reconnected.', false, ch, nil, nil, TO_ROOM);
                    REMOVE_BIT(ch.flags, PLR_LINKLESS);
                    writeConsole('(' + inttostr(socket.getDescriptor) + ') ' + ch.name + ' has reconnected');

                    ch.sendPrompt();
                    state := CON_PLAYING;
                    exit;
                    end;

                  if (ch.IS_IMMORT) then
                    send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                  else
                    send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                  send('Press Enter.'#13#10);
                  state := CON_MOTD;
                  end;
        CON_MOTD: begin
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
                    ch.sendPrompt;

                  state := CON_PLAYING;
                  fcommand := true;
                 
                  raiseEvent('char-login', ch);
                  end;
    CON_NEW_NAME: begin
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
                  state := CON_NEW_PASSWORD;
                  send(#13#10'Allright, '+ch.name+', choose a password: ');
                  end;
CON_NEW_PASSWORD: begin
                  if (length(argument)=0) then
                    begin
                    send('Choose a password: ');
                    exit;
                    end;

                  ch.md5_password := MD5String(argument);
                  state := CON_CHECK_PASSWORD;
                  send(#13#10'Please retype your password: ');
                  end;
CON_CHECK_PASSWORD: begin
                    if (length(argument) = 0) then
                      begin
                      send('Please retype your password: ');
                      exit;
                      end;

                    if (not MD5Match(MD5String(argument), ch.md5_password)) then
                      begin
                      send(#13#10'Password did not match!'#13#10'Choose a password: ');
                      state := CON_NEW_PASSWORD;
                      exit;
                      end
                    else
                      begin
                      state := CON_NEW_SEX;
                      send(#13#10'What sex do you wish to be (M/F/N): ');
                      exit;
                      end;
                    end;
     CON_NEW_SEX: begin
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

                  state:=CON_NEW_RACE;
                  send(#13#10'Available races: '#13#10#13#10);

                  h:=1;
                  iterator := raceList.iterator();

                  while (iterator.hasNext()) do
                    begin
                    race := GRace(iterator.next());

                    buf := '  ['+inttostr(h)+']  '+pad_string(race.name,15);

                    if (race.def_alignment < 0) then
                      buf := buf + ANSIColor(12,0) + '<- EVIL'+ANSIColor(7,0);

                    buf := buf + #13#10;

                    send(buf);

                    inc(h);
                    end;
                    
                  iterator.Free();

                  send(#13#10'Choose a race: ');
                  end;
    CON_NEW_RACE: begin
                  if (length(argument)=0) then
                    begin
                    send(#13#10'Choose a race: ');
                    exit;
                    end;

                  try
                    x:=strtoint(argument);
                  except
                    x:=-1;
                  end;

                  race := nil;
                  iterator := raceList.iterator();
                  h := 1;

                  while (iterator.hasNext()) do
                    begin
                    if (h = x) then
                      begin
                      race := GRace(iterator.next());
                      break;
                      end
                    else
                      iterator.next();

                    inc(h);
                    end;
                    
                  iterator.Free();

                  if (race = nil) then
                    begin
                    send('Not a valid race.'#13#10);

                    h:=1;
										iterator := raceList.iterator();

										while (iterator.hasNext()) do
											begin
											race := GRace(iterator.next());

                      buf := '  ['+inttostr(h)+']  '+pad_string(race.name,15);

                      if (race.def_alignment < 0) then
                        buf := buf + ANSIColor(12,0) + '<- EVIL'+ANSIColor(7,0);

                      buf := buf + #13#10;

                      send(buf);

                      inc(h);
                      end;

										iterator.Free();
										
                    send(#13#10'Choose a race: ');
                    exit;
                    end;

                  ch.race:=race;
                  send(race.description);
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
                  state:=CON_NEW_STATS;
                  end;
   CON_NEW_STATS: begin
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
                        state:=CON_MOTD;
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
                        state:=CON_NEW_NAME;
                        end;
                  else
                    send('Do you wish to (C)ontinue, (R)eroll or (S)art over? ');
                    exit;
                 end;
                 end;
    else
      bugreport('nanny', 'mudthread.pas', 'illegal state ' + inttostr(state));
  end;
end;

procedure GPlayerConnection.writePager(txt : string);
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
        c.sendPrompt;
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


// GPlayer
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

  aliases := GDLinkedList.Create;
  skills_learned := GDLinkedList.Create;

  max_skills := 0;
  max_spells := 0;

  pracs := 10; // default for new players(?)

  channels := GDLinkedList.Create();
  iterator := channellist.iterator();
  
  while (iterator.hasNext()) do
    begin
    chan := GUserChannel(iterator.next());
    tc := GUserChannel.Create(chan.channelname);
    channels.insertLast(tc);
    end;

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

destructor GPlayer.Destroy();
var
	node, node_next : GListNode;
	tc : GUserChannel;
begin
  aliases.clean;
  aliases.Free;

  node := channels.head;
  while (node <> nil) do
    begin
    node_next := node.next;
    tc := GUserChannel(node.element);
    channels.remove(node);
    tc.Free();

    node := node_next;
    end;
 
  channels.clean();
  channels.Free();

  skills_learned.clean();
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

procedure GPlayer.quit();
var
	vict : GCharacter;
	iterator : GIterator;
begin
  raiseEvent('char-logout', Self);

  emptyBuffer();

  if (conn = nil) then
    writeConsole('(Linkless) '+ name+ ' has logged out')
  else
  if (conn <> nil) then
    writeConsole('(' + IntToStr(conn.socket.getDescriptor) + ') ' + name + ' has logged out');

  { switched check}
  if (conn <> nil) and (not IS_NPC) then
    begin
    conn.state := CON_LOGGED_OUT;

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

function GPlayer.getAge : integer;
begin
  getAge := 17 + (getPlayed div 1000);
end;

function GPlayer.getPlayed : integer;
begin
  getPlayed := trunc(((played + (Now - logon_now)) * MSecsPerDay) / 60000);
end;

function GPlayer.IS_IMMORT : boolean;
begin
  Result := inherited IS_IMMORT;

  if (level >= LEVEL_IMMORTAL) then
    IS_IMMORT := true;
end;

function GPlayer.IS_WIZINVIS : boolean;
begin
  Result := IS_SET(flags, PLR_WIZINVIS);
end;

function GPlayer.IS_HOLYWALK : boolean;
begin
  Result := inherited IS_HOLYWALK;

  if (IS_SET(flags, PLR_HOLYWALK)) then
    Result := true;
end;

function GPlayer.IS_HOLYLIGHT : boolean;
begin
  Result := inherited IS_HOLYLIGHT;

  if (IS_SET(flags, PLR_HOLYLIGHT)) then
    Result := true;
end;

function GPlayer.IS_AFK : boolean;
begin
  if IS_SET(flags, PLR_LINKLESS) then
    IS_AFK := false
  else
    IS_AFK := afk = true;
end;

function GPlayer.IS_KEYLOCKED : boolean;
begin
  if IS_SET(flags, PLR_LINKLESS) then
    IS_KEYLOCKED := false
  else
    IS_KEYLOCKED := keylock = true;
end;

function GPlayer.IS_EDITING : boolean;
begin
  IS_EDITING := conn.state = CON_EDITING;
end;

function GPlayer.IS_DRUNK : boolean;
begin
	IS_DRUNK := (condition[COND_DRUNK] > 80);
end;

function GPlayer.getUsedSkillslots() : integer;       // returns nr. of skillslots occupied
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

function GPlayer.getUsedSpellslots() : integer;       // returns nr. of spellslots occupied
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

function GPlayer.load(fn : string) : boolean;
var d, x : longint;
    af : GFileReader;
    g , a, t : string;
    obj : GObject;
    aff : GAffect;
    len, modif, inner : integer;
    s: string;
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

  _name := hash_string(s);
  _short := hash_string(s + ' is here');
  _long := hash_string(s + ' is standing here');

  try
    af := GFileReader.Create('players\' + fn + '.usr');
  except
    load := false;
    exit;
  end;

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
        if g='RACE' then
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
        if g='AGE' then
          age:=strtoint(right(a,' '))
        else
        if g='WEIGHT' then
          weight:=strtoint(right(a,' '))
        else
        if g='HEIGHT' then
          height:=strtoint(right(a,' '))
        else
        if g='STATS' then
          begin
          a := right(a,' ');
          str:=strtoint(left(a,' '));
          a := right(a,' ');
          con:=strtoint(left(a,' '));
          a := right(a,' ');
          dex:=strtoint(left(a,' '));
          a := right(a,' ');
          int:=strtoint(left(a,' '));
          a := right(a,' ');
          wis:=strtoint(left(a,' '));
          end
        else
        if (g = 'MAX_SKILLS') then
          max_skills := strtoint(right(a,' '))
        else
        if (g = 'MAX_SPELLS') then
          max_spells := strtoint(right(a,' '))
        else
        if (g = 'PRACTICES') then
          pracs := strtoint(right(a,' '))
        else
        if g='APB' then
          apb:=strtoint(right(a,' '))
        else
        if g='MANA' then
          begin
          a:=right(a,' ');
          mana:=strtoint(left(a,' '));
          a:=right(a,' ');
          max_mana:=strtoint(left(a,' '));
          end
        else
        if g='HP' then
          begin
          a:=right(a,' ');
          hp:=strtoint(left(a,' '));
          a:=right(a,' ');
          max_hp:=strtoint(left(a,' '));
          end
        else
        if g='MV' then
          begin
          a:=right(a,' ');
          mv:=strtoint(left(a,' '));
          a:=right(a,' ');
          max_mv:=strtoint(left(a,' '));
          end
        else
        if g='AC' then
          ac:=strtoint(right(a,' '))
        else
        if g='HAC' then
          hac:=strtoint(right(a,' '))
        else
        if g='BAC' then
          bac:=strtoint(right(a,' '))
        else
        if g='AAC' then
          aac:=strtoint(right(a,' '))
        else
        if g='LAC' then
          lac:=strtoint(right(a,' '))
        else
        if g='GOLD' then
          begin
          a:=right(a,' ');
          gold := UMax(strtointdef(left(a, ' '), 0), 0);
          a:=right(a,' ');
          bankgold := UMax(strtointdef(left(a, ' '), 0), 0);
          end
        else
        if g='XP' then
          begin
          a:=right(a,' ');
          xptot:=strtoint(left(a,' '));
          a:=right(a,' ');
          xptogo:=strtoint(left(a,' '));
          end
        else
        if g='ROOMVNUM' then
          room := findRoom(strtoint(right(a, ' ')))
        else
        if g='KILLS' then
          kills:=strtoint(right(a,' '))
        else
        if g='DEATHS' then
          deaths:=strtoint(right(a,' '))
        else
        if g='FLAGS' then
          flags:=strtoint(right(a,' '))
        else
        if g='CLAN' then
          begin
          clan := findClan(right(a,' '));

          if (clan <> nil) and(clan.leader = name) then
            clanleader := true;
          end
        else
        if g='CONFIG' then
          cfg_flags:=strtoint(right(a,' '))
        else
        if g='AC_MOD' then
          ac_mod:=strtoint(right(a,' '))
        else
        // for backward compatibility only
        if g='PASSWORD' then
          begin
          password := right(a,' ');
          md5_password := MD5String(password);
          end
        else
        // the new md5 encrypted pwd
        if g='MD5-PASSWORD' then
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
        if g='REMORTS' then
          remorts:=strtoint(right(a,' '))
        else
        if g='WIMPY' then
          wimpy:=strtoint(right(a,' '))
        else
        if g='AFF_FLAGS' then
          aff_flags:=strtoint(right(a,' '))
        else
        if g='MENTALSTATE' then
          mental_state:=strtoint(right(a,' '))
        else
        if g='CONDITION' then
          begin
          a:=right(a,' ');
          condition[COND_DRUNK]:=strtoint(left(a,' '));
          a:=right(a,' ');
          condition[COND_FULL]:=strtoint(left(a,' '));
          a:=right(a,' ');
          condition[COND_THIRST]:=strtoint(left(a,' '));
          a:=right(a,' ');
          condition[COND_CAFFEINE]:=strtoint(left(a,' '));
          a:=right(a,' ');
          condition[COND_HIGH]:=strtoint(left(a,' '));
          end
        else
        if g='AREA' then
          begin
          area_fname := right(a,' ');
          area := findArea(area_fname);
          end
        else
        if g='RANGES' then
          begin
          a:=right(a,' ');
          r_lo:=strtoint(left(a,' '));
          a:=right(a,' ');
          r_hi:=strtoint(left(a,' '));
          a:=right(a,' ');
          m_lo:=strtoint(left(a,' '));
          a:=right(a,' ');
          m_hi:=strtoint(left(a,' '));
          a:=right(a,' ');
          o_lo:=strtoint(left(a,' '));
          a:=right(a,' ');
          o_hi:=strtoint(left(a,' '));
          end
        else
        if g='WIZLEVEL' then
          wiz_level:=strtoint(right(a,' '))
        else
        if g='BGPOINTS' then
          bg_points:=strtoint(right(a,' '))
        else
        if g='PAGERLEN' then
          pagerlen:=strtoint(right(a,' '))
        else
        if g='LOGON' then
          begin
          a:=right(a,' ');
          logon_first:=strtoint(left(a,' '));
          a:=right(a,' ');
          logon_first:=logon_first + (strtoint(left(a,' '))/MSecsPerDay);
          if (logon_first = 0)then
            logon_first:=Now;
          end
        else
        if g='PLAYED' then
          begin
          a:=right(a,' ');
          played:=strtoint(left(a,' '));
          a:=right(a,' ');
          played:=played + (strtoint(left(a,' '))/MSecsPerDay);

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
          aff := GAffect.Create;

          with aff do
            begin
            a := right(a, '''');

            name := hash_string(left(a, ''''));

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
          al := GAlias.Create;

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
      repeat
        g := af.readLine;

        if (uppercase(g) <> '#END') and (not af.eof) then
          begin
          obj := GObject.Create;

          with obj do
            begin
            vnum := af.readInteger();
            name := af.readLine();
            short := af.readLine();
            long := af.readLine();

            a := af.readLine;
            item_type:=StrToInt(left(a,' '));
            a:=right(a,' ');
            wear_location1 := left(a,' ');
            a:=right(a,' ');
            wear_location2 := left(a,' ');

            a := af.readLine;
            value[1]:=StrToInt(left(a,' '));
            a:=right(a,' ');
            value[2]:=StrToInt(left(a,' '));
            a:=right(a,' ');
            value[3]:=StrToInt(left(a,' '));
            a:=right(a,' ');
            value[4]:=StrToInt(left(a,' '));

            a := af.readLine;
            weight:=StrToInt(left(a,' '));
            a:=right(a,' ');
            flags:=StrToInt(left(a,' '));
            a:=right(a,' ');
            cost:=StrToInt(left(a,' '));
            a := right(a, ' ');
            count := strtointdef(left(a, ' '), 1);
            if (count = 0) then
              count := 1;

            room:=nil;
            end;

					obj.node_world := objectList.insertLast(obj);
					
				  obj.worn := g;
				  
				  if (obj.worn = 'none') then
				    obj.worn := '';
	            
          obj.toChar(Self);         
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
          g:=right(g,' ');
          trophy[trophysize].name := left(g,' ');
          g:=right(g,' ');
          trophy[trophysize].level:=strtoint(left(g,' '));
          g:=right(g,' ');
          trophy[trophysize].times:=strtoint(left(g,' '));
          end;
      until (uppercase(g) = '#END') or (af.eof);

      if (uppercase(g) = '#END') then
        dec(inner);
      end;
  until (af.eof);

  af.Free;

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

  if (max_skills = 0) then
    max_skills := race.max_skills;

  if (max_spells = 0) then
    max_spells := race.max_spells;

  calcAC;
  calcRank;
  
  // backwards compatibility fixes
  REMOVE_BIT(aff_flags, AFF_BASHED);
  REMOVE_BIT(aff_flags, AFF_STUNNED);

  load := true;
end;

function GPlayer.save(fn : string) : boolean;
var
	af : GFileWriter;
	temp : TDateTime;
	h : integer;
	obj : GObject;
	al : GAlias;
	g : GLearned;
	aff : GAffect;
	fl : cardinal;
	tc : GUserChannel;
	iterator : GIterator;
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

		af.writeLine('Max_skills: ' + IntToStr(max_skills));
		af.writeLine('Max_spells: ' + IntToStr(max_spells));

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

			af.writeLine( 'Skill: ''' + GSkill(g.skill).name^ + ''' ' + IntToStr(g.perc));
			end;

		af.writeLine('#END');
		af.writeLine('');

		af.writeLine('#AFFECTS');

		iterator := affects.iterator();

		while (iterator.hasNext()) do
			begin
			aff := GAffect(iterator.next());

			with aff do
				begin
				af.writeString('''' + name^ + ''' ''' + wear_msg + ''' ');
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

					af.writeString(' } ');
					end;

				af.writeLine('');
				end;
			end;

		af.writeLine('#END');
		af.writeLine('');

		af.writeLine( '#ALIASES');

		iterator := aliases.iterator();

		while (iterator.hasNext()) do
			begin
			al := GAlias(iterator.next());

			af.writeLine(al.alias + ':' + al.expand);
			end;

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
			end;

		iterator.Free();

		af.writeLine('#END');
		af.writeLine('');

		af.writeLine('#TROPHY');
		for h := 1 to trophysize do
			af.writeLine('Trophy: ' + trophy[h].name + ' ' + IntToStr(trophy[h].level) + ' ' + IntToStr(trophy[h].times));
		af.writeLine('#END');
	finally
		af.Free;
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

procedure GPlayer.sendBuffer(s : string);
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

procedure GPlayer.sendPager(txt : string);
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

procedure GPlayer.startEditing(text : string);
begin
  if (conn = nil) then
    exit;

  if (substate = SUB_SUBJECT) then
    begin
    sendBuffer(ansiColor(7) + #13#10 + 'Subject: ');
    state := CON_EDITING;
    exit;
    end;

  GConnection(conn).send(ansiColor(7) + #13#10 + 'Use ~ on a blank line to end. Use .h on a blank line to get help.'#13#10);
  GConnection(conn).send(ansiColor(7) + '----------------------------------------------------------------------'#13#10'> ');

  edit_buffer := text;
  afk := true;
  conn.state := CON_EDITING;
end;

procedure GPlayer.stopEditing;
begin
  sendBuffer('Ok.'#13#10);

  edit_buffer := '';
  substate := SUB_NONE;
  afk := false;
  conn.state := CON_PLAYING;

  sendBuffer('You are now back at your keyboard.'#13#10);
  act(AT_REPORT,'$n has returned to $s keyboard.',false,Self,nil,nil,to_room);
end;

procedure GPlayer.sendEdit(text : string);
begin
  case substate of
    SUB_NOTE:
      begin
        postNote(Self, text);

        edit_buffer := '';
        substate := SUB_NONE;

        conn.state := CON_PLAYING;
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
        conn.state := CON_PLAYING;
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

  if (state = CON_EDIT_HANDLE) then
    begin
    if (uppercase(text) = 'A') then
      begin
      stopEditing;
      exit;
      end;

    if (uppercase(text) = 'V') then
      begin
      GConnection(conn).send(ansiColor(7) + 'Current text:' + #13#10);
      GConnection(conn).send(ansiColor(7) + '----------------------------------------------------------------------' + #13#10);
      GConnection(conn).send(ansiColor(7) + edit_buffer + #13#10);
      GConnection(conn).send(ansiColor(7) + '(C)ontinue, (V)iew, (S)end or (A)bort? ');
      exit;
      end;

    if (uppercase(text) = 'C') then
      begin
      GConnection(conn).send(ansiColor(7) + 'Ok. Continue writing...' + #13#10);
      GConnection(conn).send(ansiColor(7) + '----------------------------------------------------------------------' + #13#10);
      GConnection(conn).send(ansiColor(7) + edit_buffer);
      state := CON_EDITING;
      sendPrompt;
      exit;
      end;

    if (uppercase(text) = 'S') then
      begin
      sendEdit(edit_buffer);
      exit;
      end;

    GConnection(conn).send(#13#10 + ansiColor(7) + '(C)ontinue, (V)iew, (S)end or (A)bort? ');
    exit;
    end;

  if (text = '~') then
    begin
    state := CON_EDIT_HANDLE;
    GConnection(conn).send(#13#10 + ansiColor(7) + '(C)ontinue, (V)iew, (S)end or (A)bort? ');
    exit;
    end
  else
  if (length(text) > 0) and (text[1] = '.') then
  begin
    text := uppercase(text);
    case text[2] of
      'H' :
        begin
          GConnection(conn).send(ansiColor(7) + '.h  this help' + #13#10);
          GConnection(conn).send(ansiColor(7) + '.c  clear current text' + #13#10);
          GConnection(conn).send(ansiColor(7) + '.v  see current text' + #13#10);
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
        end
    else
      begin
        GConnection(conn).send(ansiColor(7) + 'Enter .h on a blank line for help.' + #13#10);
      end;
    end;
    sendPrompt;
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

procedure GPlayer.sendPrompt();
var
   s, pr, buf : string;
   t : integer;
begin
  if (not IS_NPC) then
    begin
    if (state = CON_EDITING) then
      begin
      conn.send('> ');
      exit;
      end;

    if (conn.pagepoint > 0) then
     exit;
    end;

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

    if (state = CON_EDITING) then
      begin
      conn.send('> ');
      exit;
      end;

    if (state = CON_EDIT_HANDLE) then
      begin
      conn.send(' ');
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
    conn.send(#13#10);

  conn.send(buf);
end;

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
    fromRoom;
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

procedure GPlayer.calcRank();
var r:string;
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
constructor GPlayerField.Create(name : string);
begin
	inherited Create();
	
	_name := prep(name);
end;

// GPlayerFieldFlag
function GPlayerFieldFlag.default() : TObject;
begin
	Result := GBitVector.Create(0);
end;

function GPlayerFieldFlag.fromString(s : string) : TObject;
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

function GPlayerFieldInteger.fromString(s : string) : TObject;
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

function GPlayerFieldString.fromString(s : string) : TObject;
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

procedure unregisterField(name : string);
begin
	fieldList.remove(prep(name));
end;


function findPlayerWorld(ch : GCharacter; name : string) : GCharacter;
var
	iterator : GIterator;
	vict : GCharacter;
	number,count : integer;
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
   number,count : integer;
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

function existsPlayer(name : string) : boolean;
begin
	Result := FileExists('players\' + name + '.usr');
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

end.