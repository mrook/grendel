// $Id: chars.pas,v 1.43 2001/07/12 16:37:01 ***REMOVED*** Exp $

unit chars;

interface

uses
    SysUtils,
    Math,
    Winsock2,
    constants,
    strip,
    area,
    race,
    md5,
    ansiio,
    fsys,
    util,
    clan,
    dtypes,
    gvm,
    bulletinboard;


type
    GCharacter = class;

    GTrophy = record
      name : string;
      level, times : integer;
    end;

    GAlias = class
      alias : string;
      expand : string;

      node : GListNode;
    end;

    THistoryElement = // channelhistory stuff
      class
        time : TDateTime;
        contents : PString;
        constructor Create(txt : string);
        destructor Destroy(); override;
      end;

    TChannel =
      class
        channelname : string;
        history : GDLinkedList;
        ignored : boolean;
        constructor Create(txt : string);
        destructor Destroy(); override;
      end;

    GLearned = class
      skill : pointer;
      perc : integer;

      constructor Create(perc_ : integer; skill_ : pointer);
    end;

    {$M+}
    GCharacter = class
      node_world, node_room : GListNode;
      objects : GDLinkedList;

      reply, master, leader : GCharacter;
      fighting , hunting : GCharacter;
      snooped_by : GCharacter;

    private
      _level : integer;
      _str, _con, _dex, _int, _wis : integer;
      _hp, _max_hp : integer;
      _mv, _max_mv : integer;
      _mana, _max_mana : integer;
      _apb : integer;

    public
      ac_mod : integer;             { AC modifier (spells?) }
      natural_ac : integer;         { Natural AC (race based for PC's) }
      hac, bac, aac, lac, ac : integer; { head, body, arm, leg and overall ac }
      hitroll : integer;            { the hit roll }
      damnumdie, damsizedie : integer;
      save_poison, save_cold, save_para,  { saving throws }
      save_breath, save_spell :integer;
      tracking : string;

      logging : boolean;

      position : integer;
      gold : longint;               { Gold carried }
      mental_state : integer;
      room : GRoom;
      substate : integer;
      trust : integer;
      kills : integer;
      wait : integer;
      skills_learned : GDLinkedList;
      cast_timer, bash_timer, bashing : integer;
      in_command : boolean;
      name, short, long : PString;
      sex : integer;
      race : GRace;
      alignment : integer;
      carried_weight : integer;             { weight of items carried }
      weight, height : integer;       { weight/height of (N)PC }
      last_cmd : pointer;
      affects : GDLinkedList;
      aff_flags : cardinal;
      clan : GClan;                 { joined a clan? }
      conn : pointer;

    published
      procedure sendPrompt; virtual;
      procedure sendBuffer(s : string); virtual;
      procedure sendPager(txt : string); virtual;
      procedure emptyBuffer; virtual;

      function ansiColor(color : integer) : string; virtual;

      function getTrust : integer;

      function CHAR_DIED : boolean;

      function IS_IMMORT : boolean; virtual;
      function IS_NPC : boolean; virtual;
      function IS_LEARNER : boolean; virtual;
      function IS_AWAKE : boolean; virtual;
      function IS_INVIS : boolean; virtual;
      function IS_HIDDEN : boolean; virtual;
      function IS_WIZINVIS : boolean; virtual;
      function IS_GOOD : boolean; virtual;
      function IS_EVIL : boolean; virtual;
      function IS_SAME_ALIGN(vict : GCharacter) : boolean; virtual;
      function IS_FLYING : boolean; virtual;
      function IS_BANKER : boolean; virtual;
      function IS_SHOPKEEPER : boolean; virtual;
      function IS_OUTSIDE : boolean; virtual;
      function IS_AFFECT(affect : integer) : boolean; virtual;
      function IS_DRUNK : boolean; virtual;
      function IS_WEARING(item_type : integer) : boolean; virtual;
      function IS_HOLYWALK : boolean; virtual;
      function IS_HOLYLIGHT : boolean; virtual;
      function IS_AFK : boolean; virtual;
      function IS_KEYLOCKED : boolean; virtual;
      function IS_EDITING : boolean; virtual;
      function CAN_FLY : boolean; virtual;
      function CAN_SEE(target : TObject) : boolean; virtual;

      function LEARNED(skill : pointer) : integer;
      procedure SET_LEARNED(perc : integer; skill : pointer);

      procedure extract(pull : boolean);
      procedure fromRoom;
      procedure toRoom(to_room : GRoom);

      function getEQ(location : integer) : GObject;
      function getWield(item_type : integer) : GObject;
      function getDualWield : GObject;
      procedure affectObject(obj : GObject; remove: boolean);
      function equip(obj : GObject) : boolean;

      procedure die; virtual;

      procedure setWait(ticks : integer);

      function calcxp2lvl : cardinal;

      procedure calcAC;

      procedure startFlying;
      procedure stopFlying;

      function findInventory(s : string) : GObject;
      function findEquipment(s : string) : GObject;

      constructor Create;
      destructor Destroy; override;

    // properties
      function getName() : string;

      property level : integer read _level write _level;
      property str : integer read _str write _str;
      property con : integer read _str write _str;
      property dex : integer read _str write _str;
      property int : integer read _str write _str;
      property wis : integer read _str write _str;

      property hp : integer read _hp write _hp;
      property max_hp : integer read _max_hp write _max_hp;
      property mv : integer read _mv write _mv;
      property max_mv : integer read _max_mv write _max_mv;
      property mana : integer read _mana write _mana;
      property max_mana : integer read _max_mana write _max_mana;

      property apb : integer read _apb write _apb;

      property pname : string read getName;
    end;

    GNPC = class(GCharacter)
    public
      npc_index : GNPCIndex;
      act_flags : cardinal;
      context : GContext;

    published
      function IS_IMMORT : boolean; override;
      function IS_NPC : boolean; override;
      function IS_LEARNER : boolean; override;
      function IS_WIZINVIS : boolean; override;
      function IS_BANKER : boolean; override;
      function IS_SHOPKEEPER : boolean; override;

      procedure die; override;
    end;

    GPlayer = class(GCharacter)
    public
      edit_buffer : string;
      edit_dest : pointer;

      pagerlen : integer;
      title : string;                     { Title of PC }
      hometown : integer;                { Hometown (vnum of portal) }
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
      trophy : array[1..15] of GTrophy;
      trophysize: integer;
      switched : GCharacter;
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

      active_board : integer;
      boards : array[BOARD1..BOARD_MAX-1] of integer;
      subject : string;

      constructor Create;
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
    end;
    {$M-}

    GExtractedCharacter = class
      node : GListNode;

      ch : GCharacter;
      pull : boolean;
    end;

var
   char_list : GDLinkedList;
   extracted_chars : GDLinkedList;

function findCharWorld(ch : GCharacter; name : string) : GCharacter;
function findPlayerWorld(ch : GCharacter; name : string) : GPlayer;

procedure cleanChars;

implementation

uses
    conns,
    skills,
    mudsystem,
    mudthread,
    Channels;

constructor THistoryElement.Create(txt : string);
begin
  inherited Create();
  time := Now();
  contents := hash_string(txt);
end;

destructor THistoryElement.Destroy();
begin
  unhash_string(contents);
  inherited Destroy();
end;

constructor TChannel.Create(txt : string);
begin
  inherited Create();
  channelname := txt;
  history := GDLinkedList.Create();
  ignored := false;
end;

destructor TChannel.Destroy();
var
  node : GListNode;
  he : THistoryElement;
begin
  node := history.head;
  while (node <> nil) do
  begin
    he := node.element;
    history.remove(node);
    he.Free();
    node := node.next;
  end;
  history.clean();
  history.Free();
  inherited Destroy();
end;

constructor GCharacter.Create;
begin
  inherited Create;

  objects := GDLinkedList.Create;
  affects := GDLinkedList.Create;

  reply := nil;
  master := nil;
  snooped_by := nil;
  leader := Self;
  tracking := '';
end;

destructor GCharacter.Destroy;
var
   obj : GObject;
   node : GListNode;
   tc : TChannel;
begin
  affects.clean;
  affects.Free;

  if (objects.tail <> nil) then
    repeat
      obj := objects.tail.element;
      obj.extract;
    until (objects.tail = nil);

  objects.Free;

  hunting := nil;

  unhash_string(name);
  unhash_string(short);
  unhash_string(long);

  inherited Destroy;
end;

procedure GCharacter.extract(pull : boolean);
{ set pull to false if you wish for character to stay
  alive, e.g. in portal or so. don't set to false for NPCs - Grimlord }
var
   ext : GExtractedCharacter;
begin
  if (CHAR_DIED) then
    begin
    bugreport('extract_char', 'area.pas', 'ch already extracted',
              'Heavy desyncing occured: attempt to extract a character twice.');
    exit;
    end;

  if (room <> nil) then
    fromRoom;

  ext := GExtractedCharacter.Create;
  ext.ch := Self;
  ext.pull := pull;

  ext.node := extracted_chars.insertLast(ext);

  if (not pull) then
    begin
    if (IS_EVIL) then
      toRoom(findRoom(ROOM_VNUM_EVIL_PORTAL))
    else
      toRoom(findRoom(ROOM_VNUM_GOOD_PORTAL));
    end
  else
    begin
    if (conn <> nil) then
      GConnection(conn).ch := nil;

    char_list.remove(node_world);
    end;
end;

function GCharacter.getName() : string;
begin
  if (name <> nil) then
    Result := name^
  else
    Result := '';
end;

function GCharacter.getTrust : integer;
var
   ch : GCharacter;
begin
{  if (conn <> nil) and (GConnection(conn).original <> nil) then
    ch := GConnection(conn).original
  else }
    ch := Self;

  if (ch.trust <> 0) then
    begin
    getTrust := ch.trust;
    exit;
    end;

  if (ch.IS_NPC) then
    getTrust := UMax(ch.level, 500)
  else
    getTrust := ch.level;
end;

function GCharacter.CHAR_DIED : boolean;
var
   ext : GExtractedCharacter;
   node : GListNode;
begin
  CHAR_DIED := false;

  if (Self = nil) then
    begin
    CHAR_DIED := true;
    exit;
    end;

  node := extracted_chars.head;

  while (node <> nil) do
    begin
    ext := node.element;

    if (ext.ch = Self) then
      begin
      CHAR_DIED := true;
      exit;
      end;

    node := node.next;
    end;
end;

procedure GCharacter.sendPrompt;
begin
end;

procedure GCharacter.sendBuffer(s : string);
begin
end;

procedure GCharacter.sendPager(txt : string);
begin
end;

procedure GCharacter.emptyBuffer;
begin
end;

// GPlayer
constructor GPlayer.Create;
var
   node : GListNode;
   chan : TChannel;
   tc : TChannel;

begin
  inherited Create;

  pagerlen := 25;
  xptogo := round((20 * power(level, 1.2)) * (1 + (random(3) / 10)));

  title := 'the Newbie Adventurer';
  rank := 'an apprentice';
  snooping := nil;

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

  if (race <> nil) then
    begin
    max_skills := race.max_skills;
    max_spells := race.max_spells;
    end
  else
    begin
    max_skills := 0;
    max_spells := 0;
    end;

  pracs := 10; // default for new players(?)

  channels := GDLinkedList.Create();
  node := channellist.head;

  while (node <> nil) do
    begin
    chan := node.element;
    tc := TChannel.Create(chan.channelname);
    channels.insertLast(tc);
    node := node.next;
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

  if (IS_GOOD) then
    room := findRoom(ROOM_VNUM_GOOD_PORTAL)
  else
  if (IS_EVIL) then
    room := findRoom(ROOM_VNUM_EVIL_PORTAL);

  fighting := nil;
end;

destructor GPlayer.Destroy;
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

  inherited Destroy;
end;

procedure GPlayer.quit;
var
   vict : GCharacter;
   node : GListNode;
   c : GConnection;
begin
  emptyBuffer;

  c := conn;

  if (IS_NPC) then
    begin
    if (c <> nil) then
      c.send('You''re an NPC, you can''t quit!'#13#10);
    exit;
    end;

  if (c = nil) then
    write_console('(Linkless) '+ name^+ ' has logged out')
  else
  if (c <> nil) then
    write_console('(' + inttostr(c.socket) + ') ' + name^ + ' has logged out');

  { switched check}
  if (conn <> nil) and (not IS_NPC) then
    begin
    c.state := CON_LOGGED_OUT;
    c.ch := nil;

    try
      c.thread.terminate;
    except
      write_console('could not delete thread of ' + name^);
    end;

    conn := nil;

    closesocket(c.socket);
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

{  if (snooped_by <> nil) then
    begin
    snooped_by.player^.snooping := nil;
    snooped_by.sendBuffer('No longer snooping.'#13#10);
    snooped_by := nil;
    end; }

  if (leader <> Self) then
    begin
    to_channel(leader, '$B$7[Group]: ' + name^ + ' has left the group.', CHANNEL_GROUP, AT_WHITE);
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

  save(name^);

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

function GCharacter.IS_IMMORT : boolean;
begin
  Result := false;
end;

function GNPC.IS_IMMORT : boolean;
begin
  Result := inherited IS_IMMORT;

  if (IS_SET(act_flags, ACT_IMMORTAL)) then
    IS_IMMORT := true;
end;

function GPlayer.IS_IMMORT : boolean;
begin
  Result := inherited IS_IMMORT;

  if (level >= LEVEL_IMMORTAL) then
    IS_IMMORT := true;
end;

function GCharacter.IS_NPC : boolean;
begin
  Result := false;
end;

function GNPC.IS_NPC : boolean;
begin
  Result := true;
end;

function GCharacter.IS_LEARNER : boolean;
begin
  Result := false;
end;

function GNPC.IS_LEARNER : boolean;
begin
  Result := IS_SET(act_flags, ACT_TEACHER);
end;

function GCharacter.IS_AWAKE : boolean;
begin
  IS_AWAKE := (position <> POS_SLEEPING);
end;

function GCharacter.IS_INVIS : boolean;
begin
  IS_INVIS := IS_SET(aff_flags, AFF_INVISIBLE);
end;

function GCharacter.IS_HIDDEN : boolean;
begin
  IS_HIDDEN := IS_SET(aff_flags, AFF_HIDE);
end;

function GCharacter.IS_WIZINVIS : boolean;
begin
  Result := false;
end;

function GNPC.IS_WIZINVIS : boolean;
begin
  Result := IS_SET(act_flags, ACT_MOBINVIS)
end;

function GPlayer.IS_WIZINVIS : boolean;
begin
  Result := IS_SET(flags, PLR_WIZINVIS);
end;

function GCharacter.IS_GOOD : boolean;
begin
  IS_GOOD := (alignment >= 0) and (not IS_IMMORT);
end;

function GCharacter.IS_EVIL : boolean;
begin
  IS_EVIL := (alignment < 0) and (not IS_IMMORT);
end;

function GCharacter.IS_SAME_ALIGN(vict : GCharacter) : boolean;
begin
  IS_SAME_ALIGN := false;

  if (vict.IS_IMMORT or IS_IMMORT) or (IS_EVIL and vict.IS_EVIL) or
   (IS_GOOD and vict.IS_GOOD) then
    IS_SAME_ALIGN := true;
end;

function GCharacter.IS_FLYING : boolean;
begin
  Result := IS_SET(aff_flags, AFF_FLYING);
end;

function GCharacter.IS_BANKER : boolean;
begin
  Result := false;
end;

function GNPC.IS_BANKER : boolean;
begin
  Result := IS_SET(act_flags, ACT_BANKER);
end;

function GCharacter.IS_SHOPKEEPER : boolean;
begin
  Result := false;
end;

function GNPC.IS_SHOPKEEPER : boolean;
begin
  Result := IS_SET(act_flags, ACT_SHOPKEEP);
end;

function GCharacter.IS_OUTSIDE : boolean;
begin
  IS_OUTSIDE := (room.sector <> SECT_INSIDE) and
               (not IS_SET(room.flags, ROOM_INDOORS));
end;

function GCharacter.IS_AFFECT(affect : integer) : boolean;
begin
  IS_AFFECT := IS_SET(aff_flags, affect);
end;

function GCharacter.IS_DRUNK : boolean;
begin
  if (IS_NPC) then
    IS_DRUNK := false
  else
    IS_DRUNK := (GPlayer(Self).condition[COND_DRUNK] > 80);
end;

function GCharacter.IS_WEARING(item_type : integer) : boolean;
var
   node : GListNode;
   obj : GObject;
begin
  node := objects.head;
  Result := false;

  while (node <> nil) do
    begin
    obj := node.element;

    if (obj.wear_location <> WEAR_NULL) and (obj.item_type = item_type) then
      begin
      Result := true;
      break;
      end;

    node := node.next;
    end;
end;

function GCharacter.IS_HOLYWALK : boolean;
begin
  Result := false;
end;

function GPlayer.IS_HOLYWALK : boolean;
begin
  Result := inherited IS_HOLYWALK;

  if (IS_SET(flags, PLR_HOLYWALK)) then
    Result := true;
end;

function GCharacter.IS_HOLYLIGHT : boolean;
begin
  Result := false;
end;

function GPlayer.IS_HOLYLIGHT : boolean;
begin
  Result := inherited IS_HOLYLIGHT;

  if (IS_SET(flags, PLR_HOLYLIGHT)) then
    Result := true;
end;

{ Utility function - Nemesis }
function GCharacter.IS_AFK : boolean;
begin
  Result := false;
end;

function GPlayer.IS_AFK : boolean;
begin
  if IS_SET(flags, PLR_LINKLESS) then
    IS_AFK := false
  else
    IS_AFK := GConnection(conn).afk = true;
end;

{ utility function - Nemesis }
function GCharacter.IS_KEYLOCKED : boolean;
begin
  Result := false;
end;

function GPlayer.IS_KEYLOCKED : boolean;
begin
  if IS_SET(flags, PLR_LINKLESS) then
    IS_KEYLOCKED := false
  else
    IS_KEYLOCKED := GConnection(conn).keylock = true;
end;

function GCharacter.IS_EDITING : boolean;
begin
   Result := false;
end;

function GPlayer.IS_EDITING : boolean;
begin
  IS_EDITING := GConnection(conn).state = CON_EDITING;
end;

function GCharacter.CAN_FLY : boolean;
begin
  Result := false;

  if (IS_SET(aff_flags, AFF_LEVITATION)) then
    Result := true;
end;

{ can ch see ? }
function GCharacter.CAN_SEE(target : TObject) : boolean;
var
  vict : GCharacter;
begin
  CAN_SEE := true;

  if (Self = vict) then
    exit;

  if (not IS_AWAKE) then
    CAN_SEE := false;

  if (room.IS_DARK) and (not IS_HOLYLIGHT) and (not IS_SET(aff_flags, AFF_INFRAVISION)) then
    CAN_SEE := false;

  if (target is GCharacter) then
    begin
    vict := GCharacter(target);

    if (vict.IS_INVIS) and (not (IS_SET(aff_flags, AFF_DETECT_INVIS)
     or IS_IMMORT)) then
      CAN_SEE:=false;

    if (vict.IS_HIDDEN) and (not (IS_SET(aff_flags, AFF_DETECT_HIDDEN)
     or IS_IMMORT)) then
      CAN_SEE := false;

    if (vict.IS_WIZINVIS) and (level < GPlayer(vict).wiz_level) then
      CAN_SEE := false;
    end;

  if (IS_SET(aff_flags, AFF_BLIND)) then
    CAN_SEE := false;
end;

function GCharacter.LEARNED(skill : pointer) : integer;
var
   node : GListNode;
   g : GLearned;
begin
  Result := 0;

  node := skills_learned.head;

  while (node <> nil) do
    begin
    g := node.element;

    if (g.skill = skill) then
      begin
      Result := g.perc;
      break;
      end;

    node := node.next;
    end;
end;

// Xenon 10/Apr/2001: Modified SET_LEARNED() to remove skill from linked list when perc = 0
procedure GCharacter.SET_LEARNED(perc : integer; skill : pointer);
var
   g : GLearned;
   node : GListNode;
begin
  g := nil;
  node := skills_learned.head;

  while (node <> nil) do
    begin
    if (GLearned(node.element).skill = skill) then
      begin
      g := node.element;
      break;
      end;

    node := node.next;
    end;

  if (g = nil) then
    skills_learned.insertLast(GLearned.Create(perc, skill))
  else
    if (perc > 0) then
      g.perc := perc
    else
      skills_learned.remove(node);
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
    tc : TChannel;
begin
  inner := 0;

  level := 1;
  s := fn;
  s[1] := upcase(s[1]);

  name := hash_string(s);
  short := hash_string(s + ' is here');
  long := hash_string(s + ' is standing here');

  if (race <> nil) then
    alignment := race.def_alignment
  else
    alignment := 0;

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
          race := findRace(right(a, ' '))
        else
        if (g = 'ALIGNMENT') then
          alignment := strtoint(right(a, ' '))
        else
        if (g = 'LEVEL') then
          level := strtoint(right(a, ' '))
        else
        if g='HOMETOWN' then
          hometown:=strtoint(right(a,' '))
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

          if (clan <> nil) and(clan.leader = name^) then
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
            bugreport('GArea.load', 'charlist.pas', 'skill '+g+' does not exist',
                      'The skill specified in the pfile does not exist.');
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
            name := hash_string(left(a, ' '));
            wear_msg := 'boe';

            a := right(a, ' ');

            duration := strtointdef(left(a, ' '), 0);
            len := 1;

            while (pos('{', a) > 0) do
              begin
              a := trim(right(a, '{'));

              setLength(modifiers, len);

              modifiers[len - 1].apply_type := findApply(left(a, ' '));

              a := right(a, ' ');

              modif := cardinal(findSkill(left(a, ' ')));

              if (modif = 0) then
                modif := strtointdef(left(a, ' '), 0);

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
            d := af.readInteger;

            if (d <> -1 ) then
              begin
              obj_index := findObjectIndex(d);

              if (obj_index = nil) then
                bugreport('load_user', 'charlist.pas', 'illegal vnum ' + inttostr(d),
                          'There is no index for this object.')
              else
                inc(obj_index.obj_count);
              end;

            a := af.readLine;
            name := hash_string(a);
            a := af.readLine;
            short := hash_string(a);
            a := af.readLine;
            long := hash_string(a);

            a := af.readLine;
            item_type:=StrToInt(left(a,' '));
            a:=right(a,' ');
            wear1:=StrToInt(left(a,' '));
            a:=right(a,' ');
            wear2:=StrToInt(left(a,' '));

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

          obj.node_world := object_list.insertLast(obj);

          obj.toChar(Self);

          obj.wear_location := strtoint(g);

          if (obj.wear_location < WEAR_NULL) then
            obj.wear_location := WEAR_NULL;
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
    bugreport('GCharacter.load', 'chars.pas', 'bugged playerfile ' + name^,
              'The pfile of this character was corrupted.');

    race := GRace(race_list.head.element);
    end;

  if (race <> nil) then
    begin
    save_poison:=race.save_poison;
    save_cold:=race.save_cold;
    save_para:=race.save_para;
    save_breath:=race.save_breath;
    save_spell:=race.save_spell;
    hitroll:=UMax((level div 5)+50,100);
    end;

  if (max_skills = 0) then
  begin
    bugreport('GCharacter.load', 'chars.pas', 'bugged playerfile ' + name^,
              'The pfile of this character lacks a Max_skills field. ' +
              'Fixing this *now* by setting these fields to race-max value. ' +
              'Make sure to (force) save this player.');
    max_skills := race.max_skills;
  end;
  
  if (max_spells = 0) then
  begin
    bugreport('GCharacter.load', 'chars.pas', 'bugged playerfile ' + name^,
              'The pfile of this character lacks a Max_spells field. ' +
              'Fixing this *now* by setting these fields to race-max value. ' +
              'Make sure to (force) save this player.');
    max_spells := race.max_spells;
  end;
  
  calcAC;
  calcRank;

  load := true;
end;

function GPlayer.save(fn : string) : boolean;
var
   f : textfile;
   temp : TDateTime;
   h : integer;
   node : GListNode;
   obj : GObject;
   al : GAlias;
   g : GLearned;
   aff : GAffect;
   fl : cardinal;
begin
  if (IS_NPC) then
    begin
    Result := false;
    exit;
    end;

  assignfile(f, 'players\' + fn + '.usr');

  {$I-}
  rewrite(f);
  {$I+}

  if (IOResult <> 0) then
    begin
    save := false;
    exit;
    end;

  writeln(f,'#PLAYER');
  writeln(f,'User: '+name^);
  writeln(f,'MD5-Password: '+MD5Print(md5_password));
  writeln(f,'Sex: ',sex);
  writeln(f,'Race: ',race.name);
  writeln(f,'Alignment: ',alignment);
  writeln(f,'Level: ',level);
  writeln(f,'Weight: ',weight);
  writeln(f,'Height: ',height);
  writeln(f,'aff_flags: ',aff_flags);
  writeln(f,'Mentalstate: ',mental_state);
  writeln(f,'Last-login: ', DateTimeToStr(Now));

  writeln(f,'Title: ',title);
  writeln(f,'Home: ',hometown);
  writeln(f,'Age: ',age);
  writeln(f,'Gold: ',gold,' ',bankgold);
  writeln(f,'XP: ',xptot,' ',xptogo);
  writeln(f,'Kills: ',kills);
  writeln(f,'Deaths: ',deaths);
  writeln(f,'Practices: ', pracs);
  writeln(f,'Bamfin: ',bamfin);
  writeln(f,'Bamfout: ',bamfout);
  writeln(f,'Taunt: ', taunt);
  writeln(f,'Prompt: ', prompt);
  writeln(f,'Active_board: ', active_board);
  writeln(f,'Read-notes: ', boards[BOARD1], ' ', boards[BOARD2], ' ', boards[BOARD3], ' ', boards[BOARD_NEWS], ' ', boards[BOARD_IMM]);

  fl := flags;
  REMOVE_BIT(fl, PLR_LINKLESS);
  REMOVE_BIT(fl, PLR_LOADED);

  writeln(f,'Flags: ', fl);
  writeln(f,'Config: ',cfg_flags);
  writeln(f,'Remorts: ',remorts);
  writeln(f,'Wimpy: ',wimpy);
  writeln(f,'Logon: ',trunc(logon_first),' ',trunc(frac(logon_first)*MSecsPerDay));

  temp:=played + (Now - logon_now);
  writeln(f,'Played: ',trunc(temp),' ',trunc(frac(temp)*MSecsPerDay));
  writeln(f,'Condition: ',condition[COND_DRUNK],' ',condition[COND_FULL],
          ' ',condition[COND_THIRST],' ',condition[COND_CAFFEINE],' ',condition[COND_HIGH]);

  if clan<>nil then
    writeln(f,'Clan: ',clan.name);

  if area_fname<>'' then
    writeln(f,'Area: ',area_fname);

  writeln(f,'Ranges: ',r_lo,' ',r_hi,' ',m_lo,' ',m_hi,' ',o_lo,' ',o_hi);

  writeln(f,'Wizlevel: ',wiz_level);
  writeln(f,'BGpoints: ',bg_points);
  writeln(f,'Pagerlen: ',pagerlen);

  writeln(f,'Stats: ',str,' ',con,' ',dex,' ',int,' ',wis);

  writeln(f, 'Max_skills: ', max_skills);
  writeln(f, 'Max_spells: ', max_spells);

  writeln(f,'APB: ',apb);
  writeln(f,'Mana: ',mana,' ',max_mana);
  writeln(f,'HP: ',hp,' ',max_hp);
  writeln(f,'Mv: ',mv,' ',max_mv);
  writeln(f,'AC: ',ac);
  writeln(f,'HAC: ',hac);
  writeln(f,'BAC: ',bac);
  writeln(f,'AAC: ',aac);
  writeln(f,'LAC: ',lac);
  writeln(f,'AC_mod: ',ac_mod);
  writeln(f,'RoomVNum: ',room.vnum);
  writeln(f,'#END');
  writeln(f);

  writeln(f,'#SKILLS');
  node := skills_learned.head;;

  while (node <> nil) do
    begin
    g := node.element;

    writeln(f, 'Skill: ''', GSkill(g.skill).name^, ''' ', g.perc);

    node := node.next;
    end;

  writeln(f,'#END');
  writeln(f);

  writeln(f,'#AFFECTS');
  node := affects.head;

  while (node <> nil) do
    begin
    aff := node.element;

{    with aff do
      writeln(f,'Affect: ''', skill.name, ''' ',
               printApply(apply_type), ' ', duration, ' ', modifier); }

    node := node.next;
    end;
  writeln(f,'#END');
  writeln(f);

  writeln(f, '#ALIASES');
  node := aliases.head;

  while (node <> nil) do
    begin
    al := node.element;

    writeln(f, al.alias, ':', al.expand);

    node := node.next;
    end;

  writeln(f, '#END');
  writeln(f);

  writeln(f,'#OBJECTS');
  node := objects.head;

  while (node <> nil) do
    begin
    obj := node.element;

    writeln(f, obj.wear_location);

    if (obj.obj_index <> nil) then
      writeln(f,obj.obj_index.vnum)
    else
      writeln(f,-1);

    writeln(f,obj.name^);
    writeln(f,obj.short^);
    writeln(f,obj.long^);
    writeln(f,obj.item_type,' ',obj.wear1,' ',obj.wear2,' ');
    writeln(f,obj.value[1],' ',obj.value[2],' ',obj.value[3],' ',obj.value[4]);
    writeln(f,obj.weight,' ',obj.flags,' ',obj.cost, ' ', obj.count);

    node := node.next;
    end;

  writeln(f,'#END');
  writeln(f);

  writeln(f,'#TROPHY');
  for h:=1 to trophysize do
    writeln(f,'Trophy: ',trophy[h].name,' ',trophy[h].level,' ',trophy[h].times);
  writeln(f,'#END');

  closefile(f);

  save := true;
end;

procedure GPlayer.sendBuffer(s : string);
var
   c : GConnection;
begin
  if (snooped_by <> nil) then
    GConnection(snooped_by.conn).send(s);

// Xenon 21/Feb/2001: I think someone snooping still wants to see output of his own commands
  if (conn = nil) {or (not IS_NPC and (player^.snooping <> nil))} then
    exit;

  if (IS_EDITING) then
    exit;

  c := conn;

  if ((length(c.sendbuffer) + length(s)) > 2048) then
    begin
    c.send(c.sendbuffer);
    c.sendbuffer := '';
    end;

  if (not in_command) and (length(c.sendbuffer) = 0) then
    c.sendbuffer := c.sendbuffer + #13#10;

  c.sendbuffer := c.sendbuffer + s;
end;

procedure GPlayer.sendPager(txt : string);
var
   c : GConnection;
begin
  if (conn = nil) then
    exit;

  c := conn;

  if (IS_NPC) or (not IS_SET(cfg_flags,CFG_PAGER)) then
    sendBuffer(txt)
  else
    c.writePager(txt);
end;

procedure GPlayer.emptyBuffer;
var
   c : GConnection;
begin
  if (conn = nil) then
    exit;

  c := conn;

  if (c.empty_busy) then
    exit;

  c.empty_busy := true;

  if (length(c.sendbuffer) > 0) then
    begin
    c.send(c.sendbuffer);
    sendPrompt;
    c.sendbuffer := '';
    end;

  c.empty_busy := false;
end;

procedure GPlayer.startEditing(text : string);
begin
  if (conn = nil) then
    exit;

  if (substate = SUB_SUBJECT) then
    begin
    sendBuffer(ansiColor(7) + #13#10 + 'Subject: ');
    GConnection(conn).state := CON_EDITING;
    exit;
    end;

  GConnection(conn).send(ansiColor(7) + #13#10 + 'Use ~ on a blank line to end. Use .h on a blank line to get help.'#13#10);
  GConnection(conn).send(ansiColor(7) + '----------------------------------------------------------------------'#13#10'> ');

  edit_buffer := text;
  GConnection(conn).afk := true;
  GConnection(conn).state := CON_EDITING;
end;

procedure GPlayer.stopEditing;
begin
  sendBuffer('Ok.'#13#10);

  edit_buffer := '';
  substate := SUB_NONE;
  GConnection(conn).afk := false;
  GConnection(conn).state := CON_PLAYING;

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

        GConnection(conn).state := CON_PLAYING;
        GConnection(conn).afk := false;

        sendBuffer('Note posted.'#13#10);

        act(AT_REPORT,'You are now back at your keyboard.',false,Self,nil,nil,TO_CHAR);
        act(AT_REPORT,'$n finished $s note and is now back at the keyboard.',false,Self,nil,nil,TO_ROOM);

        if (active_board = BOARD_IMM) then
          begin
          act(AT_REPORT,'There is a new note on the ' + board_names[active_board] + ' board.', false, Self, nil, nil, TO_IMM);
          act(AT_REPORT,'Written by ' + name^ + '.',false,Self,nil,nil,TO_IMM);
          end
        else
          begin
          act(AT_REPORT,'There is a new note on the ' + board_names[active_board] + ' board.', false, Self, nil, nil, TO_ALL);
          act(AT_REPORT,'Written by ' + name^ + '.', false, Self, nil, nil, TO_ALL);
          end;

        exit;
      end;
    SUB_ROOM_DESC :
      begin
        interpret(Self, 'redit');
        GConnection(conn).state := CON_PLAYING;
        GConnection(conn).afk := false;
        edit_buffer := '';
        substate := SUB_NONE;
        edit_dest := nil;
      end
    else
    begin
      bugreport('GCharacter.sendEdit()', 'chars.pas', 'unrecognized substate', 'The substate this character is in has not been recognized.');
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

  if (GConnection(conn).state = CON_EDIT_HANDLE) then
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
      GConnection(conn).state := CON_EDITING;
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
    GConnection(conn).state := CON_EDIT_HANDLE;
    GConnection(conn).send(#13#10 + ansiColor(7) + '(C)ontinue, (V)iew, (S)end or (A)bort? ');
    exit;
    end
  else
  if (text[1] = '.') then
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

function GCharacter.ansiColor(color : integer) : string;
begin
  Result := '';
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
    if (c.state = CON_EDITING) then
      begin
      c.send('> ');
      exit;
      end;

    if (c.pagepoint > 0) then
     exit;
    end;

  if (prompt = '') then
    pr := '%hhp %mmv %ama (%l)> '
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

    if (c.state = CON_EDITING) then
      begin
      c.send('> ');
      exit;
      end;

    if (c.state = CON_EDIT_HANDLE) then
      begin
      c.send(' ');
      exit;
      end;

    if (c.pagepoint > 0) then
      exit;
    end;

  if (position = POS_CASTING) then
    buf := buf + '+';

  if (IS_IMMORT) then
    buf := buf + '#' + inttostr(room.vnum) + ' [' + sector_types[room.sector] + '] ';

  if (IS_IMMORT) and (room.areacoords <> nil) then
    buf := buf + room.areacoords.toString() + ' ';
    
  t := 1;
  s := '';

  while (t <= length(prompt)) do
    begin
    if (prompt[t] = '%') then
      begin
      case prompt[t + 1] of
        'h':  s := s + inttostr(hp);
        'H':  s := s + inttostr(max_hp);
        'm':  s := s + inttostr(mv);
        'M':  s := s + inttostr(max_mv);
        'a':  s := s + inttostr(mana);
        'A':  s := s + inttostr(max_mana);
        'l':  s := s + inttostr(level);
        'x':  s := s + inttostr(xptogo);
        'f':  begin
              if (fighting <> nil) and (position >= POS_FIGHTING) then
                begin
                s := s + ' [Oppnt: ';

                with fighting do
                  s := s + hp_perc[UMax(round((hp / max_hp) * 5), 0)];

                s := s + ']';
                end;
              end;
        't':  begin
              if (fighting <> nil) and (position >= POS_FIGHTING) then
               if (fighting.fighting <> nil) and (fighting.fighting <> Self) then
                 begin
                 s := s + ' [' + fighting.fighting.name^ + ': ';

                 with fighting.fighting do
                   s := s + hp_perc[UMax(round((hp / max_hp) * 5), 0)];

                 s := s + ']';
                 end;
              end;
        else s := s + '%' + prompt[t + 1]; 
      end;

      inc(t);
      end
    else
      s := s + prompt[t];

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

procedure GCharacter.fromRoom;
begin
  if (room = nil) then
    begin
    bugreport('GCharacter.fromRoom', 'chars.pas', 'room null',
              'Attempted to remove character from a null room.');
    exit;
    end;

  room.chars.remove(node_room);

  if (IS_WEARING(ITEM_LIGHT)) and (room.light > 0) then
    inc(room.light);

  { Only PCs register as players, so increase the number! - Grimlord }
  if (not IS_NPC) then
    dec(room.area.nplayer);

  room:=nil;
end;

procedure GCharacter.toRoom(to_room : GRoom);
var
   tele : GTeleport;
   node : GListNode;
begin
  if (to_room = nil) then
    begin
    bugreport('GCharacter.toRoom', 'chars.pas', 'room null, moving to portal',
              'Character was forced to re-move to portal.');

    if (IS_IMMORT) then
    begin
      to_room := findRoom(ROOM_VNUM_IMMORTAL_PORTAL);
      if (to_room = nil) then
      begin
        bugreport('GCharacter.toRoom', 'chars.pas', 'immortal portal not found',
                  'This immortal could not be moved to the immortal portal because '+
                  'it doesn''t exit. Immortals get moved to this room when they ' +
                  'logged out in a room that has now been removed.'#13#10 +
                  'To fix this, please create a room with vnum #' + IntToStr(ROOM_VNUM_IMMORTAL_PORTAL) + ', ' +
                  'or change the ROOM_VNUM_IMMORTAL_PORTAL constant in constants.pas to an ' +
                  'existing vnum and recompile Grendel.');
      end;
    end;

    if (to_room = nil) then      
      if (IS_EVIL) then
        to_room := findRoom(ROOM_VNUM_EVIL_PORTAL)
      else
        to_room := findRoom(ROOM_VNUM_GOOD_PORTAL);

    if (to_room = nil) then
      begin
      bugreport('GCharacter.toRoom', 'chars/pas', 'HELP! even portal is NULL room! what did you do?',
                'There are some serious problems with the limbo area! The portal does NOT exist!');

      write_console('System is unstable - prepare for a rough ride');
      exit;
      end;
    end;

  room := to_room;

  if (IS_WEARING(ITEM_LIGHT)) then
    inc(room.light);

  node_room := room.chars.insertLast(Self);

  { Only PCs register as players, so increase the number! - Grimlord }

  if (not IS_NPC) then
    inc(to_room.area.nplayer);

  { check for teleports }
  if (IS_SET(to_room.flags, ROOM_TELEPORT)) and (to_room.teledelay>0) then
    begin
    node := teleport_list.head;

    while (node <> nil) do
      begin
      tele := node.element;
      if (tele.t_room=to_room) then
        exit;

      node := node.next;
      end;

    tele := GTeleport.Create;
    tele.t_room := to_room;
    tele.timer := to_room.teledelay;

    teleport_list.insertLast(tele);
    end;
end;

procedure GCharacter.die;
begin
  addCorpse(Self);
end;

procedure GPlayer.die;
var
   node : GListNode;
begin
  inherited die;

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

procedure GNPC.die;
begin
  inherited die;

  dec(npc_index.count);
  extract(true);
  dec(mobs_loaded);
end;

procedure GCharacter.setWait(ticks : integer);
begin
  wait := UMax(wait, ticks);
end;

function GCharacter.getEQ(location : integer) : GObject;
var
   node : GListNode;
   obj : GObject;
begin
  Result := nil;

  node := objects.head;
  while (node <> nil) do
    begin
    obj := node.element;

    if (obj.wear_location = location) then
      begin
      Result := obj;
      break;
      end;

    node := node.next;
    end;
end;

function GCharacter.getWield(item_type : integer) : GObject;
var
   obj : GOBject;
begin
  getWield := nil;

  obj := getEQ(WEAR_RHAND);
  if (obj <> nil) and (obj.item_type = item_type) then
    begin
    getWield := obj;
    exit;
    end;

  obj := getEQ(WEAR_LHAND);
  if (obj <> nil) and (obj.item_type = item_type) then
    begin
    getWield:=obj;
    exit;
    end;
end;

function GCharacter.getDualWield : GObject;
begin
  getDualWield := nil;

  { can't dual wield }
  if (LEARNED(gsn_dual_wield) = 0) then
    exit;

  if (getEQ(WEAR_RHAND) <> nil) and (getEQ(WEAR_LHAND) <> nil) then
    getDualWield := getEQ(WEAR_LHAND);
end;

procedure GCharacter.affectObject(obj : GObject; remove : boolean);
var
   node : GListNode;
   aff : GAffect;
begin
  with obj do
    case obj.item_type of
      ITEM_ARMOR: calcAC;
      ITEM_LIGHT: if (remove) then
                    dec(Self.room.light)
                  else
                    inc(Self.room.light);
      ITEM_GEM: if (remove) then
                  max_mana := max_mana - obj.value[3]
                else
                  max_mana := max_mana + obj.value[3]
    end;

  if (obj.obj_index <> nil) then
    begin
    node := obj.obj_index.affects.head;

    while (node <> nil) do
      begin
      aff := node.element;

      aff.modify(Self, not remove);

      node := node.next;
      end;
    end;
end;

function GCharacter.equip(obj : GObject) : boolean;
const wr_string:array[WEAR_RFINGER..WEAR_EYES, 1..2] of string =
      (('on your finger', 'on $s finger'),
       ('on your finger', 'on $s finger'),
       ('around your neck', 'around $s neck'),
       ('around your neck', 'around $s neck'),
       ('on your body', 'on $s body'),
       ('on your head', 'on $s head'),
       ('on your legs', 'on $s legs'),
       ('on your feet', 'on $s feet'),
       ('on your hands', 'on $s hands'),
       ('on your arms', 'on $s arms'),
       ('as your shield', 'as $s shield'),
       ('about your body', 'about $s body'),
       ('around your waist', 'around $s waist'),
       ('around your right wrist', 'around $s right wrist'),
       ('around your left wrist', 'around $s left wrist'),
       ('near your head', 'near $s head'),
       ('in your hand', 'in $s hand'),
       ('in your hand', 'in $s hand'),
       ('on your shoulder', 'on $s shoulder'),
       ('on your shoulder', 'on $s shoulder'),
       ('on your face', 'on $s face'),
       ('in your ear', 'in $s ear'),
       ('in your ear', 'in $s ear'),
       ('on your ankle', 'on $s ankle'),
       ('on your ankle', 'on $s ankle'),
       ('on your eyes', 'on $s eyes'));
begin
  equip := true;

  if IS_SET(obj.flags,OBJ_ANTI_GOOD) and IS_GOOD then
    begin
    act(AT_REPORT,'You are zapped by $p!',false,Self,obj,nil,TO_CHAR);
    act(AT_REPORT,'$n is zapped by $p and burns $s hands.',false,Self,obj,nil,TO_ROOM);

    obj.fromChar;
    obj.toRoom(room);
    exit;
    end;

  if IS_SET(obj.flags,OBJ_ANTI_EVIL) and IS_EVIL then
    begin
    act(AT_REPORT,'You are zapped by $p!',false,Self,obj,nil,TO_CHAR);
    act(AT_REPORT,'$n is zapped by $p and burns $s hands.',false,Self,obj,nil,TO_ROOM);

    obj.fromChar;
    obj.toRoom(room);
    exit;
    end;

  if (obj.wear1 > 0) and (getEQ(obj.wear1) = nil) then      { Wear on spot #1}
    begin
    act(AT_REPORT,'You wear $p ' + wr_string[obj.wear1, 1] + '.',false, Self, obj, nil, TO_CHAR);
    act(AT_REPORT,'$n wears $p ' + wr_string[obj.wear1, 2] + '.',false, Self, obj, nil, TO_ROOM);
    obj.wear_location := obj.wear1;
    affectObject(obj, false);
    end
  else
  if (obj.wear2 > 0) and (getEQ(obj.wear2) = nil) then      { Wear on spot #2}
    begin
    act(AT_REPORT,'You wear $p ' + wr_string[obj.wear2, 1] + '.',false, Self, obj, nil, TO_CHAR);
    act(AT_REPORT,'$n wears $p ' + wr_string[obj.wear2, 2] + '.',false, Self, obj, nil, TO_ROOM);
    obj.wear_location := obj.wear2;
    affectObject(obj, false);
    end
  else                                              { No spots left }
    begin
    act(AT_REPORT,'You are already wearing something there!',false,Self,nil,nil,TO_CHAR);
    equip := false;
    end;
end;

function GCharacter.calcxp2lvl : cardinal;
begin
  calcxp2lvl := round((20*power(level,1.2))*(1+(random(2)/10)));
end;

procedure GCharacter.calcAC;
var
   dex_mod:integer;
   node : GListNode;
   obj : GObject;
begin
  dex_mod := (dex-50) div 12;
  hac := natural_ac - dex_mod - ac_mod;
  bac := natural_ac - dex_mod - ac_mod;
  aac := natural_ac - dex_mod - ac_mod;
  lac := natural_ac - dex_mod - ac_mod;

  node := objects.head;
  while (node <> nil) do
    begin
    obj := node.element;

    if (obj.wear_location > WEAR_NULL) and (obj.item_type = ITEM_ARMOR) then
      case obj.value[2] of
        ARMOR_HAC : dec(hac, obj.value[3]);
        ARMOR_BAC : dec(bac, obj.value[3]);
        ARMOR_AAC : dec(aac, obj.value[3]);
        ARMOR_LAC : dec(lac, obj.value[3]);
      end;

    node := node.next;
    end;

  ac := (hac + bac + aac + lac) div 4;
end;

procedure GPlayer.calcRank;
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

procedure GCharacter.startFlying;
begin
  if (not IS_OUTSIDE) then
    begin
    sendBuffer('You cannot fly while indoors!'#13#10);
    exit;
    end;

  if (IS_FLYING) then
    begin
    sendBuffer('You are already flying!'#13#10);
    exit;
    end
  else
  if (CAN_FLY) then
    begin
    SET_BIT(aff_flags, AFF_FLYING);

    act(AT_REPORT,'You begin to fly again!',false,Self,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n gently floats up in the air.',false,Self,nil,nil,TO_ROOM);
    end
  else
    begin
    act(AT_REPORT,'You flap your arms, but never leave the ground.',false,Self,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n flaps $s arms to fly, but can''t.',false,Self,nil,nil,TO_ROOM);
    end;
end;

procedure GCharacter.stopFlying;
begin
  if (IS_FLYING) then
    begin
    REMOVE_BIT(aff_flags, AFF_FLYING);

    act(AT_REPORT,'You slowly land on the ground.',false,Self,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n gently lands on the ground.',false,Self,nil,nil,TO_ROOM);
    end;
end;

function GCharacter.findInventory(s : string) : GObject;
var obj : GObject;
    node : GListNode;
begin
  findInventory := nil;
  node := objects.head;

  while (node <> nil) do
    begin
    obj := node.element;
    if (obj.wear_location = WEAR_NULL) and (isObjectName(obj.name^, s) or isObjectName(obj.short^, s)) then
      begin
      findInventory := obj;
      exit;
      end;

    node := node.next;
    end;
end;

{ Xenon 20/Feb/2001: like findInventory searches thru inv, findEquipment searches thru stuff being worn }
function GCharacter.findEquipment(s : string) : GObject;
var obj : GObject;
    node : GListNode;
begin
  findEquipment := nil;
  node := objects.head;

  while (node <> nil) do
    begin
    obj := node.element;

    if (obj.wear_location <> WEAR_NULL) and (isObjectName(obj.name^, s) or isObjectName(obj.short^, s)) then
      begin
      findEquipment := obj;
      exit;
      end;

    node := node.next;
    end;
end;

{ Added 2.<char> - Nemesis }
function findCharWorld(ch : GCharacter; name : string) : GCharacter;
var
   node : GListNode;
   vict : GCharacter;
   number,count : integer;
begin
  findCharWorld := nil;

  number := findNumber(name); // eg 2.char

  if (uppercase(name) = 'SELF') then
    begin
    findCharWorld := ch;
    exit;
    end;

  count := 0;

  node := char_list.head;

  while (node <> nil) do
    begin
    vict := node.element;

    if (isName(vict.name^,name)) or (isName(vict.short^,name)) and (ch.CAN_SEE(vict)) then
      begin
      inc(count);

      if (count = number) then
        begin
        findCharWorld := vict;
        exit;
        end;
      end;

    node := node.next;
    end;
end;

function findPlayerWorld(ch : GCharacter; name : string) : GPlayer;
var
   node : GListNode;
   vict : GCharacter;
   number,count : integer;
begin
  Result := nil;

  number := findNumber(name); // eg 2.char

  if (uppercase(name) = 'SELF') and (not ch.IS_NPC) then
    begin
    Result := GPlayer(ch);
    exit;
    end;

  count := 0;

  node := char_list.head;

  while (node <> nil) do
    begin
    vict := node.element;

    if (isName(vict.name^,name)) or (isName(vict.short^,name)) and (ch.CAN_SEE(vict)) and (not ch.IS_NPC) then
      begin
      inc(count);

      if (count = number) then
        begin
        Result := GPlayer(vict);
        exit;
        end;
      end;

    node := node.next;
    end;
end;

procedure cleanChars;
var
   ext : GExtractedCharacter;
   node : GListNode;
begin
  while (true) do
    begin
    node := extracted_chars.tail;

    if (node = nil) then
      exit;

    ext := node.element;

    extracted_chars.remove(node);

    if (ext.pull) then
      ext.ch.Free;

    ext.free;
    end;
end;

{ GLearned }
constructor GLearned.Create(perc_: integer; skill_: pointer);
begin
  inherited Create;

  perc := perc_;
  skill := skill_;
end;

initialization
char_list := GDLinkedList.Create;
extracted_chars := GDLinkedList.Create;

end.

