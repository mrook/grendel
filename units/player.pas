{
	Summary:
		Player specific functions
	
	## $Id: player.pas,v 1.4 2003/10/17 12:39:56 ***REMOVED*** Exp $
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

type
		GPlayer = class;
		
		GPlayerConnection = class(GConnection)
    protected
    	_state : integer;
      _ch : GPlayer;
      
      procedure OnOpenEvent();
      procedure OnInputEvent();
      procedure OnOutputEvent();
      procedure OnCloseEvent();

		public
    	constructor Create(socket : GSocket; from_copyover : boolean = false; copyover_name : string = '');
		
      procedure writePager(txt : string);
      procedure setPagerInput(argument : string);
      procedure outputPager;
      
    published
    	property state : integer read _state write _state;
    	
    	property ch: GPlayer read _ch write _ch;
		end;
		
    GPlayer = class(GCharacter)   	
    protected
      _keylock: boolean;
      _afk : boolean;
    
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
      destructor Destroy; override;

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
	clan,
	bulletinboard,
	Channels;
	

// GPlayerConnection
constructor GPlayerConnection.Create(socket : GSocket; from_copyover : boolean = false; copyover_name : string = '');
begin
	inherited Create(socket);
	
	FOnOpen := OnOpenEvent;
	FOnClose := OnCloseEvent;
	FOnInput := OnInputEvent;
	FOnOutput := OnOutputEvent;
end;

procedure GPlayerConnection.OnOpenEvent();
begin
end;

procedure GPlayerConnection.OnInputEvent();
begin
end;

procedure GPlayerConnection.OnCloseEvent();
begin
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
	if (state = CON_LOGGED_OUT) then
		dec(system_info.user_cur)
	else
		begin
		writeConsole('(' + IntToStr(socket.getDescriptor) + ') Connection reset by peer');
		ch.Free;
		end;
end;

procedure GPlayerConnection.OnOutputEvent();
begin
	ch.sendPrompt();
end;

procedure GPlayerConnection.writePager(txt : string);
begin
  if (_pagepoint = 0) then
    begin
    _pagepoint := 1;
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
var last : cardinal;
    c : GPlayer;
    pclines,lines:integer;
    buf:string;
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
        _pagepoint := 0;
        pagebuf := '';
        exit;
        end;
  else
    lines:=0;
  end;

  while (lines<0) and (_pagepoint >= 1) do
    begin
    if (pagebuf[_pagepoint] = #13) then
      inc(lines);

    dec(_pagepoint);
    end;

  if (_pagepoint < 1) then
    _pagepoint := 1;

  lines := 0;
  last := _pagepoint;

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
    _pagepoint := last;
    end;

  while (last <= length(pagebuf)) and (pagebuf[last] = ' ') do
    inc(last);

  if (last >= length(pagebuf)) then
    begin
    _pagepoint := 0;
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
   chan : TChannel;
   tc : TChannel;
begin
  inherited Create();

  pagerlen := 25;
  xptogo := round((20 * power(level, 1.2)) * (1 + (random(3) / 10)));

  title := 'the Newbie Adventurer';
  rank := 'an apprentice';
  snooping := nil;
  switching := nil;

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
    chan := TChannel(iterator.next());
    tc := TChannel.Create(chan.channelname);
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
  bash_timer := -2;
  cast_timer := 0;
  bashing := -2;
  mental_state := -10;
  in_command := false;
  
  keylock := false;
  afk := false;

	Self.conn := conn;
  conn.state := STATE_IDLE;
  conn.ch := Self;

  if (IS_GOOD) then
    room := findRoom(ROOM_VNUM_GOOD_PORTAL)
  else
  if (IS_EVIL) then
    room := findRoom(ROOM_VNUM_EVIL_PORTAL);

  fighting := nil;
end;

destructor GPlayer.Destroy();
var
   node, node_next : GListNode;
   tc : TChannel;
begin
  aliases.clean;
  aliases.Free;

  node := channels.head;
  while (node <> nil) do
    begin
    node_next := node.next;
    tc := node.element;
    channels.remove(node);
    tc.Free();

    node := node_next;
    end;
 
  channels.clean();
  channels.Free();

  skills_learned.clean();
  skills_learned.Free();

  inherited Destroy;
end;

procedure GPlayer.quit();
var
   vict : GCharacter;
   node : GListNode;
begin
  emptyBuffer;

{  if (IS_NPC) then
    begin
    if (conn <> nil) then
      conn.send('You''re an NPC, you can''t quit!'#13#10);
    exit;
    end; }

  if (conn = nil) then
    writeConsole('(Linkless) '+ name+ ' has logged out')
  else
  if (conn <> nil) then
    writeConsole('(' + IntToStr(conn.socket.getDescriptor) + ') ' + name + ' has logged out');

  { switched check}
  if (conn <> nil) and (not IS_NPC) then
    begin
    state := CON_LOGGED_OUT;

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
    node := char_list.head;

    while (node <> nil) do
      begin
      vict := node.element;

      if (vict <> Self) and ((vict.leader = Self) or (vict.master = Self)) then
        begin
        act(AT_REPORT,'You stop following $N.',false,vict,nil,Self,TO_CHAR);
        vict.master := nil;
        vict.leader := vict;
        end;

      node := node.next;
      end;
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
  node : GListNode;
  g : GLearned;
begin
  Result := 0;
  node := skills_learned.head;

  while (node <> nil) do
  begin
    g := node.element;
    if (GSkill(g.skill).skill_type <> SKILL_SPELL) then
      inc(Result);
    node := node.next;
  end;
end;

function GPlayer.getUsedSpellslots() : integer;       // returns nr. of spellslots occupied
var
  node : GListNode;
  g : GLearned;
begin
  Result := 0;
  node := skills_learned.head;

  while (node <> nil) do
  begin
    g := node.element;
    if (GSkill(g.skill).skill_type = SKILL_SPELL) then
      inc(Result);
    node := node.next;
  end;
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
    chan : GChannel;
    iterator : GIterator;
    tc : TChannel;
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
      repeat
        a := af.readLine;

        g := uppercase(left(a,':'));

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
            race := raceList.head.element;
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
        if g='PAGELEN' then
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
            tc := TChannel(iterator.next());
            
            if (tc.channelname = right(a, ' ')) then
              tc.ignored := true;
            end;
          end;
      until (uppercase(a)='#END') or (af.eof);

      if (uppercase(a)='#END') then
        dec(inner);
      end
    else
    if (s = '#SKILLS') then
      begin
      inc(inner);
      repeat
        a := af.readLine;

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
   tc : TChannel;
   iterator : GIterator;
   w1, w2 : string;
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
    tc := TChannel(iterator.next());
    
    if (tc.ignored) then
      af.writeLine('Ignore: ' + tc.channelname);
    end;
  
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

  af.Free;

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
var note : GNote;
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

procedure GPlayer.sendPrompt;
var
   s, pr, buf : string;
   c : GConnection;
   t : integer;
begin
  c := conn;
  if (not IS_NPC) then
    begin
    if (state = CON_EDITING) then
      begin
      c.send('> ');
      exit;
      end;

    if (c.pagepoint > 0) then
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
      c.send(' ');
      exit;
      end;

    if (state = CON_EDITING) then
      begin
      c.send('> ');
      exit;
      end;

    if (state = CON_EDIT_HANDLE) then
      begin
      c.send(' ');
      exit;
      end;

    if (c.pagepoint > 0) then
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

  if IS_SET(cfg_flags,CFG_BLANK) then
    c.send(#13#10);

  c.send(buf);
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

    removeAffect(Self, node.element);
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


end.