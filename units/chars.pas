unit chars;

interface

uses
    SysUtils,
    Math,
    Winsock,
    constants,
    strip,
    area,
    race,
    md5,
    ansiio,
    fsys,
    util,
    clan,
    dtypes;


type
    GCharacter = class;

    GAffect = class
      sn : integer;
      aff_type : char;
      aff_flag : longint;
      duration : longint;
      modifier : longint;

      node : GListNode;
    end;

    GTrophy = record
      name : string;
      level, times : integer;
    end;

    GAlias = class
      alias : string;
      expand : string;

      node : GListNode;
    end;

    GPlayer = record
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
      remorts : integer;            { remorts done }
      condition : array[COND_DRUNK..COND_MAX-1] of integer;
      (* area: GArea;
      area_fname : pchar;
      r_lo, r_hi, m_lo, m_hi, o_lo, o_hi : integer; *)
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
      bamfin, bamfout : string;
      taunt : string;
      // profession:PROF_DATA;

      ld_timer : integer;
    end;

    GAbility = record
      str, con, dex, int, wis : integer;
    end;

    GPoint = record
      mana, max_mana : integer;      { Current mana and maximum mana }
      hp, max_hp : integer;          { Current hp and maximum hp }
      mv, max_mv : integer;          { Current move and maximum move }
      apb : integer;                { Attack Power Bonus }
      ac_mod : integer;             { AC modifier (spells?) }
      natural_ac : integer;         { Natural AC (race based for PC's) }
      hac, bac, aac, lac, ac : integer; { head, body, arm, leg and overall ac }
      hitroll : integer;            { the hit roll }
      damnumdie, damsizedie : integer;
      save_poison, save_cold, save_para,  { saving throws }
      save_breath, save_spell :integer;
    end;

    GCharacter = class
      node_world, node_room : GListNode;
      objects : GDLinkedList;

      reply, master, leader : GCharacter;
      fighting , hunting : GCharacter;
      snooped_by : GCharacter;
      editor : pointer;
      ability : GAbility;
      point : GPoint;
      conn : pointer;
      dest_buf : pointer;
      player : ^GPlayer; { Only players have this record }
      position : integer;
      gold : longint;               { Gold carried }
      mental_state : integer;
      room : GRoom;
      substate : integer;
      trust : integer;
      kills : integer;
      wait : integer;
      learned : array[0..MAX_SKILLS-1] of integer;
      cast_timer, bash_timer, bashing : integer;
      in_command : boolean;
      npc_index : GNPCIndex;
      name, short, long : PString;
      sex : integer;
      race : GRace;
      alignment : integer;
      level : integer;
      carried_weight : integer;             { weight of items carried }
      weight, height : integer;       { weight/height of (N)PC }
      last_cmd : pointer;
      affects : GDLinkedList;
      act_flags, aff_flags : cardinal;
      clan : GClan;                 { joined a clan? }
      tracking : string;

      function load(fn : string) : boolean;
      function save(fn : string) : boolean;

      procedure sendPrompt;
      procedure sendBuffer(s : string);
      procedure sendPager(txt : string);
      procedure emptyBuffer;

      function ansiColor(color : integer) : string;

      function getAge : integer;
      function getPlayed : integer;
      function getTrust : integer;

      function CHAR_DIED : boolean;

      function IS_IMMORT : boolean;
      function IS_NPC : boolean;
      function IS_LEARNER : boolean;
      function IS_AWAKE : boolean;
      function IS_INVIS : boolean;
      function IS_HIDDEN : boolean;
      function IS_WIZINVIS : boolean;
      function IS_GOOD : boolean;
      function IS_EVIL : boolean;
      function IS_SAME_ALIGN(vict : GCharacter) : boolean;
      function IS_FLYING : boolean;
      function IS_BANKER : boolean;
      function IS_SHOPKEEPER : boolean;
      function IS_OUTSIDE : boolean;
      function IS_AFFECT(affect : integer) : boolean;
      function CAN_FLY : boolean;
      function CAN_SEE(vict : GCharacter) : boolean;
      function IS_AFK : boolean;
      function IS_KEYLOCKED : boolean;

      procedure extract(pull : boolean);
      procedure quit;
      procedure fromRoom;
      procedure toRoom(to_room : GRoom);

      function getEQ(location : integer) : GObject;
      function getWield(item_type : integer) : GObject;
      function getDualWield : GObject;
      procedure affectObject(obj : GObject; remove: boolean);
      function equip(obj : GObject) : boolean;

      procedure die;

      procedure setWait(ticks : integer);

      function calcxp2lvl : cardinal;

      procedure calcAC;
      procedure calcRank;

      procedure startFlying;
      procedure stopFlying;

      function findInventory(s : string) : GObject;

      constructor Create;
      destructor Destroy; override;
    end;

    GExtractedCharacter = class
      node : GListNode;

      ch : GCharacter;
      pull : boolean;
    end;

var
   char_list : GDLinkedList;
   extracted_chars : GDLinkedList;

function findCharWorld(ch : GCharacter; name : string) : GCharacter;

procedure cleanChars;

implementation

uses
    conns,
    skills,
    mudsystem,
    mudthread;

constructor GCharacter.Create;
var
   h : integer;
begin
  inherited Create;

  objects := GDLinkedList.Create;
  affects := GDLinkedList.Create;

  SET_BIT(act_flags, ACT_NPC);

  player := nil;
  reply := nil;
  master := nil;
  snooped_by := nil;
  leader := Self;
  tracking := '';
end;

destructor GCharacter.Destroy;
var
   s : integer;
   node : GListNode;
   obj : GObject;
begin
  if (player <> nil) then
    begin
    player^.aliases.clean;
    player^.aliases.Free;
    dispose(player);
    end;

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

procedure GCharacter.quit;
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
    begin
    interpret(Self, 'return sub');
    end;

  { perform the cleanup }
  if (not IS_NPC) and (player^.snooping <> nil) then
    begin
    player^.snooping.snooped_by := nil;
    player^.snooping := nil;
    end;

  if (snooped_by <> nil) then
    begin
    snooped_by.player^.snooping := nil;
    snooped_by.sendBuffer('No longer snooping.'#13#10);
    snooped_by := nil;
    end;

  if (leader <> Self) then
    begin
    to_group(leader, '$B$7[Group]: ' + name^ + ' has left the group.');
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

  if (not IS_NPC) then
    save(name^)
  else
    dec(npc_index.count);

  extract(true);
end;

function GCharacter.getAge : integer;
begin
  getAge := 17 + (getPlayed div 1000);
end;

function GCharacter.getPlayed : integer;
begin
  getPlayed := trunc(((player^.played + (Now - player^.logon_now)) * MSecsPerDay) / 60000);
end;

function GCharacter.getTrust : integer;
var
   ch : GCharacter;
begin
  if (conn <> nil) and (GConnection(conn).original <> nil) then
    ch := GConnection(conn).original
  else
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


function GCharacter.IS_IMMORT : boolean;
begin
  IS_IMMORT := false;

  if (not IS_NPC) and (level >= LEVEL_IMMORTAL) then
    IS_IMMORT := true;

  if (IS_NPC) and (IS_SET(act_flags, ACT_IMMORTAL)) then
    IS_IMMORT := true;
end;

function GCharacter.IS_NPC : boolean;
begin
  IS_NPC := IS_SET(act_flags, ACT_NPC);
end;

function GCharacter.IS_LEARNER : boolean;
begin
  IS_LEARNER := IS_SET(act_flags, ACT_TEACHER);
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
  if (IS_NPC) then
    IS_WIZINVIS := IS_SET(act_flags, ACT_MOBINVIS)
  else
    IS_WIZINVIS := IS_SET(player^.flags, PLR_WIZINVIS);
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
  IS_FLYING := IS_SET(act_flags, ACT_FLYING);
end;

function GCharacter.IS_BANKER : boolean;
begin
  IS_BANKER := IS_SET(act_flags, ACT_BANKER);
end;

function GCharacter.IS_SHOPKEEPER : boolean;
begin
  IS_SHOPKEEPER := IS_SET(act_flags, ACT_SHOPKEEP);
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

function GCharacter.CAN_FLY : boolean;
begin
  CAN_FLY := false;

  if (IS_SET(aff_flags, AFF_FLYING)) then
    CAN_FLY := true;

  if (IS_NPC) and (IS_SET(player^.flags, PLR_FLYCAP)) then
    CAN_FLY := true;
end;

{ can ch see vict? }
function GCharacter.CAN_SEE(vict : GCharacter) : boolean;
begin
  CAN_SEE := true;

  if (Self = vict) then
    exit;

  if (not IS_AWAKE) then
    CAN_SEE := false;

  if (vict.IS_INVIS) and (not (IS_SET(aff_flags, AFF_DETECT_INVIS)
   or IS_IMMORT)) then
    CAN_SEE:=false;

  if (vict.IS_HIDDEN) and (not (IS_SET(aff_flags, AFF_DETECT_HIDDEN)
   or IS_IMMORT)) then
    CAN_SEE := false;

  if (vict.IS_WIZINVIS) and (level < vict.player^.wiz_level) then
    CAN_SEE := false;

  if (IS_SET(aff_flags, AFF_BLIND)) then
    CAN_SEE := false;
end;

{ Utility function - Nemesis }
function GCharacter.IS_AFK : boolean;
begin
  if (IS_NPC) then
    IS_AFK := false
  else
  if IS_SET(player^.flags, PLR_LINKLESS) then
    IS_AFK := false
  else
    IS_AFK := GConnection(conn).afk = true;
end;

{ utility function - Nemesis }
function GCharacter.IS_KEYLOCKED : boolean;
begin
  if (IS_NPC) then
    IS_KEYLOCKED := false
  else
  if IS_SET(player^.flags, PLR_LINKLESS) then
    IS_KEYLOCKED := false
  else
    IS_KEYLOCKED := GConnection(conn).keylock = true;
end;

function GCharacter.load(fn : string) : boolean;
var d, x : longint;
    af : GFileReader;
    g , a, t : string;
    obj : GObject;
    aff : GAffect;
    inner : integer;
    s: string;
    al : GAlias;
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

  if (player <> nil) then
    begin
    dispose(player);

    player := nil;
    end;

  new(player);
  fillchar(player^, sizeof(GPlayer), 0);

  // fill in default values
  with player^ do
    begin
    pagerlen := 25;
    xptogo := round((20 * power(level, 1.2)) * (1 + (random(3) / 10)));

    title := 'the Newbie Adventurer';
    snooping := nil;

    cfg_flags := CFG_ASSIST or CFG_BLANK or CFG_ANSI;
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

    aliases := GDLinkedList.Create;
    end;

  with point do
    begin
    apb := 7;
    hp := 50 + ability.con+random(11); max_hp:=hp;
    mv := 40 + (ability.dex div 4); max_mv:=mv;
    mana := 25; max_mana := 25;
    ac_mod := 0;
    natural_ac := 0;
    hitroll := 50;
    end;

  act_flags := 0;
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

        g := uppercase(stripl(a,':'));

        if (g = 'TITLE') then
          player^.title := striprbeg(a,' ')
        else
        if (g ='SEX') then
          sex := strtoint(striprbeg(a, ' '))
        else
        if g='RACE' then
          race := findRace(pchar(striprbeg(a, ' ')))
        else
        if (g = 'ALIGNMENT') then
          alignment := strtoint(striprbeg(a, ' '))
        else
        if (g = 'LEVEL') then
          level := strtoint(striprbeg(a, ' '))
        else
        if g='HOMETOWN' then
          player^.hometown:=strtoint(striprbeg(a,' '))
        else
        if g='AGE' then
          player^.age:=strtoint(striprbeg(a,' '))
        else
        if g='WEIGHT' then
          weight:=strtoint(striprbeg(a,' '))
        else
        if g='HEIGHT' then
          height:=strtoint(striprbeg(a,' '))
        else
        if g='STATS' then
          begin
          a:=striprbeg(a,' ');
          ability.str:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          ability.con:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          ability.dex:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          ability.int:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          ability.wis:=strtoint(stripl(a,' '));
          end
        else
        if g='APB' then
          point.apb:=strtoint(striprbeg(a,' '))
        else
        if g='MANA' then
          begin
          a:=striprbeg(a,' ');
          point.mana:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          point.max_mana:=strtoint(stripl(a,' '));
          end
        else
        if g='HP' then
          begin
          a:=striprbeg(a,' ');
          point.hp:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          point.max_hp:=strtoint(stripl(a,' '));
          end
        else
        if g='MV' then
          begin
          a:=striprbeg(a,' ');
          point.mv:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          point.max_mv:=strtoint(stripl(a,' '));
          end
        else
        if g='AC' then
          point.ac:=strtoint(striprbeg(a,' '))
        else
        if g='HAC' then
          point.hac:=strtoint(striprbeg(a,' '))
        else
        if g='BAC' then
          point.bac:=strtoint(striprbeg(a,' '))
        else
        if g='AAC' then
          point.aac:=strtoint(striprbeg(a,' '))
        else
        if g='LAC' then
          point.lac:=strtoint(striprbeg(a,' '))
        else
        if g='GOLD' then
          begin
          a:=striprbeg(a,' ');
          gold:=UMin(strtoint(stripl(a,' ')),0);
          a:=striprbeg(a,' ');
          player^.bankgold:=UMin(strtoint(stripl(a,' ')),0);
          end
        else
        if g='XP' then
          begin
          a:=striprbeg(a,' ');
          player^.xptot:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.xptogo:=strtoint(stripl(a,' '));
          end
        else
        if g='ROOMVNUM' then
          room := findRoom(strtoint(striprbeg(a, ' ')))
        else
        if g='KILLS' then
          kills:=strtoint(striprbeg(a,' '))
        else
        if g='DEATHS' then
          player^.deaths:=strtoint(striprbeg(a,' '))
        else
        if g='FLAGS' then
          player^.flags:=strtoint(striprbeg(a,' '))
        else
        if g='CLAN' then
          begin
          clan := findClan(striprbeg(a,' '));

          if (clan <> nil) and(clan.leader = name^) then
            player^.clanleader := true;
          end
        else
        if g='CONFIG' then
          player^.cfg_flags:=strtoint(striprbeg(a,' '))
        else
        if g='AC_MOD' then
          point.ac_mod:=strtoint(striprbeg(a,' '))
        else
        // for backward compatibility only
        if g='PASSWORD' then
          begin
          player^.password := striprbeg(a,' ');
          player^.md5_password := MD5String(player^.password);
          end
        else
        // the new md5 encrypted pwd
        if g='MD5-PASSWORD' then
          begin
          t := striprbeg(a,' ');

          d := 1;
          x := 0;

          while (d <= length(t)) do
            begin
            player^.md5_password[x] := strtoint('$' + t[d] + t[d+1]);
            inc(x);
            inc(d, 2);
            end;
          end
        else
        if g='REMORTS' then
          player^.remorts:=strtoint(striprbeg(a,' '))
        else
        if g='WIMPY' then
          player^.wimpy:=strtoint(striprbeg(a,' '))
        else
        if g='AFF_FLAGS' then
          aff_flags:=strtoint(striprbeg(a,' '))
        else
        if g='MENTALSTATE' then
          mental_state:=strtoint(striprbeg(a,' '))
        else
        if g='CONDITION' then
          begin
          a:=striprbeg(a,' ');
          player^.condition[COND_DRUNK]:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.condition[COND_FULL]:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.condition[COND_THIRST]:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.condition[COND_CAFFEINE]:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.condition[COND_HIGH]:=strtoint(stripl(a,' '));
          end
        else
        {if g='AREA' then
          begin
          alloc_string(striprbeg(a,' '),player^.area_fname);
          player^.area:=FindArea(player^.area_fname);
          end
        else
        if g='RANGES' then
          begin
          a:=striprbeg(a,' ');
          player^.r_lo:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.r_hi:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.m_lo:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.m_hi:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.o_lo:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.o_hi:=strtoint(stripl(a,' '));
          end
        else }
        if g='WIZLEVEL' then
          player^.wiz_level:=strtoint(striprbeg(a,' '))
        else
        if g='BGPOINTS' then
          player^.bg_points:=strtoint(striprbeg(a,' '))
        else
        if g='ACTFLAGS' then
          act_flags:=strtoint(striprbeg(a,' '))
        else
        if g='PAGELEN' then
          player^.pagerlen:=strtoint(striprbeg(a,' '))
        else
        if g='LOGON' then
          begin
          a:=striprbeg(a,' ');
          player^.logon_first:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.logon_first:=player^.logon_first + (strtoint(stripl(a,' '))/MSecsPerDay);
          if (player^.logon_first = 0) then
            player^.logon_first:=Now;
          end
        else
        if g='PLAYED' then
          begin
          a:=striprbeg(a,' ');
          player^.played:=strtoint(stripl(a,' '));
          a:=striprbeg(a,' ');
          player^.played:=player^.played + (strtoint(stripl(a,' '))/MSecsPerDay);
          end
        else
        if (g = 'BAMFIN') then
          player^.bamfin := striprbeg(a, ' ')
        else
        if (g = 'BAMFOUT') then
          player^.bamfout := striprbeg(a, ' ')
        else
        if (g = 'TAUNT') then
          player^.taunt := striprbeg(a, ' ');
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
          a := striprbeg(striprbeg(a,' '),'''');
          g := stripl(a,'''');
          a := striprbeg(striprbeg(a,''''),' ');
          d := findSkill(g);

          if (d <> -1) then
            learned[d] := strtoint(stripl(a,' '))
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
          a:=striprbeg(striprbeg(a,' '),'''');
          g:=stripl(a,'''');
          a:=striprbeg(striprbeg(a,''''),' ');

          aff := GAffect.Create;

          with aff do
            begin
            sn := findSkill(g);

            g:=stripl(a,' ');
            aff_type:=g[1];
            a:=striprbeg(a,' ');
            duration:=strtoint(stripl(a,' '));
            a:=striprbeg(a,' ');
            modifier:=strtoint(stripl(a,' '));
            a:=striprbeg(a,' ');
            aff_flag:=strtoint(stripl(a,' '));
            end;

          if (aff.sn <> -1) then
            doAffect(Self, aff);
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

          al.alias := stripl(a, ':');
          al.expand := striprbeg(a, ':');

          al.node := player^.aliases.insertLast(al);
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
            item_type:=StrToInt(stripl(a,' '));
            a:=striprbeg(a,' ');
            wear1:=StrToInt(stripl(a,' '));
            a:=striprbeg(a,' ');
            wear2:=StrToInt(stripl(a,' '));

            a := af.readLine;
            value[1]:=StrToInt(stripl(a,' '));
            a:=striprbeg(a,' ');
            value[2]:=StrToInt(stripl(a,' '));
            a:=striprbeg(a,' ');
            value[3]:=StrToInt(stripl(a,' '));
            a:=striprbeg(a,' ');
            value[4]:=StrToInt(stripl(a,' '));

            a := af.readLine;
            weight:=StrToInt(stripl(a,' '));
            a:=striprbeg(a,' ');
            flags:=StrToInt(stripl(a,' '));
            a:=striprbeg(a,' ');
            cost:=StrToInt(stripl(a,' '));
            a := striprbeg(a, ' ');
            count := strtointdef(stripl(a, ' '), 1);
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
          inc(player^.trophysize);
          g:=striprbeg(g,' ');
          player^.trophy[player^.trophysize].name := stripl(g,' ');
          g:=striprbeg(g,' ');
          player^.trophy[player^.trophysize].level:=strtoint(stripl(g,' '));
          g:=striprbeg(g,' ');
          player^.trophy[player^.trophysize].times:=strtoint(stripl(g,' '));
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
    point.save_poison:=race.save_poison;
    point.save_cold:=race.save_cold;
    point.save_para:=race.save_para;
    point.save_breath:=race.save_breath;
    point.save_spell:=race.save_spell;
    point.hitroll:=UMax((level div 5)+50,100);
    end;

  calcAC;
  calcRank;

  load := true;
end;

function GCharacter.save(fn : string) : boolean;
var
   f : textfile;
   temp : TDateTime;
   h : integer;
   node : GListNode;
   obj : GObject;
   al : GAlias;
   aff : GAffect;
   fl : cardinal;
begin
  if (IS_NPC) then
    exit;

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
  writeln(f,'MD5-Password: '+MD5Print(player^.md5_password));
  writeln(f,'Sex: ',sex);
  writeln(f,'Race: ',race.name);
  writeln(f,'Alignment: ',alignment);
  writeln(f,'Level: ',level);
  writeln(f,'Weight: ',weight);
  writeln(f,'Height: ',height);
  writeln(f,'aff_flags: ',aff_flags);
  writeln(f,'Mentalstate: ',mental_state);
  writeln(f,'act_flags: ',act_flags);
  writeln(f,'Last-login: ', DateTimeToStr(Now));

  with player^ do
    begin
    writeln(f,'Title: ',title);
    writeln(f,'Home: ',hometown);
    writeln(f,'Age: ',age);
    writeln(f,'Gold: ',gold,' ',bankgold);
    writeln(f,'XP: ',xptot,' ',xptogo);
    writeln(f,'Kills: ',kills);
    writeln(f,'Deaths: ',deaths);
    writeln(f,'Bamfin: ',bamfin);
    writeln(f,'Bamfout: ',bamfout);
    writeln(f,'Taunt: ', taunt);

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

    (* if area_fname<>'' then
      writeln(f,'Area: ',area_fname);

    writeln(f,'Ranges: ',r_lo,' ',r_hi,' ',m_lo,' ',m_hi,' ',o_lo,' ',o_hi); *)

    writeln(f,'Wizlevel: ',wiz_level);
    writeln(f,'BGpoints: ',bg_points);
    writeln(f,'Pagerlen: ',pagerlen);
    end;

  with ability do
    writeln(f,'Stats: ',str,' ',con,' ',dex,' ',int,' ',wis);

  with point do
    begin
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
    end;
  writeln(f,'RoomVNum: ',room.vnum);
  writeln(f,'#END');
  writeln(f);

  writeln(f,'#SKILLS');
  for h:=0 to MAX_SKILLS-1 do
   if (learned[h]>0) and (learned[h]<=100) then
    if skill_table[h].name <> '' then
     writeln(f,'Skill: ''',skill_table[h].name,''' ',learned[h]);
  writeln(f,'#END');
  writeln(f);

  writeln(f,'#AFFECTS');
  node := affects.head;

  while (node <> nil) do
    begin
    aff := node.element;

    with aff do
      writeln(f,'Affect: ''',skill_table[sn].name,''' ',
               aff_type,' ',duration,' ',modifier,' ',aff_flag);

    node := node.next;
    end;
  writeln(f,'#END');
  writeln(f);

  writeln(f, '#ALIASES');
  node := player^.aliases.head;

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
  for h:=1 to player^.trophysize do
    writeln(f,'Trophy: ',player^.trophy[h].name,' ',player^.trophy[h].level,' ',player^.trophy[h].times);
  writeln(f,'#END');

  closefile(f);

  save := true;
end;

procedure GCharacter.sendBuffer(s : string);
var
   c : GConnection;
begin
  if (snooped_by <> nil) then
    GConnection(snooped_by.conn).send(s);

  if (conn = nil) or (not IS_NPC and (player^.snooping <> nil)) then
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

procedure GCharacter.sendPager(txt : string);
var
   c : GConnection;
begin
  if (conn = nil) then
    exit;

  c := conn;

  if (IS_NPC) or (not IS_SET(player^.cfg_flags,CFG_PAGER)) then
    sendBuffer(txt)
  else
    c.writePager(txt);
end;

procedure GCharacter.emptyBuffer;
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

{ function GCharacter.get_ansi_line(color:integer):string;
begin
  if color>8 then
    get_ansi_line:='$B$'+inttostr(color-8)
  else
    get_ansi_line:='$A$'+inttostr(color);
end; }

function GCharacter.ansiColor(color : integer) : string;
begin
  if (IS_NPC) or (not IS_SET(player^.cfg_flags, CFG_ANSI)) then
    ansiColor := ''
  else
    ansiColor := ansiio.ANSIColor(color, 0);
end;

procedure GCharacter.sendPrompt;
var
   buf : string;
   c : GConnection;
begin
  c := conn;
  if (not IS_NPC) then
    begin
    if (c.state = CON_EDITING) then
      begin
      c.send('> ');
      exit;
      end;

    (* if (c.pagepoint <> nil) then
      exit; *)
    end;

  buf := ansiColor(7);

  if (bash_timer > 0) then
    buf := buf +  '[' + inttostr(bash_timer) + '] (Bashed) ';

  if (bashing > 0) then
    buf := buf +  '[' + inttostr(bashing) + '] ';

  if (position = POS_CASTING) then
    buf := buf + '+';

  if (IS_IMMORT) then
    buf := buf + '#' + inttostr(room.vnum) + ' [' + sector_types[room.sector] + '] ';

  { buf := buf +
         inttostr(point.hp) + '/' + inttostr(point.max_hp) + 'hp ' +
         inttostr(point.mv) + '/' + inttostr(point.max_mv) + 'mv ' +
         inttostr(point.mana) + 'ma ' + inttostr(level); }

  buf := buf +
         inttostr(point.hp) + 'hp ' +
         inttostr(point.mv) + 'mv ' +
         inttostr(point.mana) + 'ma ' + inttostr(level);

  if (not IS_NPC) then
    buf := buf + ' (' + inttostr(player^.xptogo) + ')';

  if (fighting <> nil) and (position >= POS_FIGHTING) then
    begin
    buf := buf + ' [Oppnt: ';

    with fighting do
      buf := buf + hp_perc[UMin(round((point.hp / point.max_hp) * 5), 0)];

    buf := buf + ']';
    end;

  if (fighting <> nil) and (position >= POS_FIGHTING) then
   if (fighting.fighting <> nil) and (fighting.fighting <> Self) then
     begin
     buf := buf + ' [' + fighting.fighting.name^ + ': ';

     with fighting.fighting do
       buf := buf + hp_perc[UMin(round((point.hp / point.max_hp) * 5), 0)];

    buf := buf + ']';
     end;

  buf := buf + '> ';

  if (snooped_by <> nil) then
    GConnection(snooped_by.conn).send(buf);

  if (not IS_NPC) then
   if IS_SET(player^.cfg_flags,CFG_BLANK) then
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

    if (IS_EVIL)  then
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
var
   node : GListNode;
begin
  addCorpse(Self);

  { when ch died in bg, get him back to room - Grimlord }
  if (not IS_NPC) then
    begin
    if (player^.bg_status = BG_PARTICIPATE) then
      begin
      point.hp := point.max_hp;
      player^.bg_status := BG_NOJOIN;
      fromRoom;
      toRoom(player^.bg_room);
      exit;
      end;

    extract(false);
    point.hp := 5;
    point.mana := 0;
    player^.condition[COND_FULL] := 100;
    player^.condition[COND_THIRST] := 100;
    player^.condition[COND_DRUNK] := 0;
    player^.condition[COND_HIGH] := 0;
    player^.condition[COND_CAFFEINE] := 0;
    point.mv := point.max_mv;

    while (true) do
      begin
      node := affects.head;
      
      if (node = nil) then
        break;

      removeAffect(Self, node.element);
      end;
    end
  else
    begin
    dec(npc_index.count);
    extract(true);
    dec(mobs_loaded);
    end;
end;

procedure GCharacter.setWait(ticks : integer);
begin
  wait := UMin(wait, ticks);
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
  if (learned[gsn_dual_wield] = 0) then
    exit;

  if (getEQ(WEAR_RHAND) <> nil) and (getEQ(WEAR_LHAND) <> nil) then
    getDualWield := getEQ(WEAR_LHAND);
end;

procedure GCharacter.affectObject(obj : GObject; remove : boolean);
begin
  with obj do
    case obj.item_type of
      ITEM_ARMOR: calcAC;
      ITEM_LIGHT: ;
      ITEM_GEM: if (remove) then
                  dec(point.max_mana, obj.value[3])
                else
                  inc(point.max_mana, obj.value[3]);
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
   i,dex_mod:integer;
   node : GListNode;
   obj : GObject;
begin
  dex_mod := (ability.dex-50) div 12;
  point.hac := point.natural_ac - dex_mod - point.ac_mod;
  point.bac := point.natural_ac - dex_mod - point.ac_mod;
  point.aac := point.natural_ac - dex_mod - point.ac_mod;
  point.lac := point.natural_ac - dex_mod - point.ac_mod;

  node := objects.head;
  while (node <> nil) do
    begin
    obj := node.element;

    if (obj.wear_location > WEAR_NULL) and (obj.item_type = ITEM_ARMOR) then
      case obj.value[2] of
        ARMOR_HAC : dec(point.hac, obj.value[3]);
        ARMOR_BAC : dec(point.bac, obj.value[3]);
        ARMOR_AAC : dec(point.aac, obj.value[3]);
        ARMOR_LAC : dec(point.lac, obj.value[3]);
      end;

    node := node.next;
    end;

  point.ac:=(point.hac+point.bac+point.aac+point.lac) div 4;
end;

procedure GCharacter.calcRank;
var r:string;
begin
  if (IS_NPC) then
    exit;

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

  player^.rank := r;
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
    SET_BIT(act_flags, ACT_FLYING);
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
    REMOVE_BIT(act_flags,ACT_FLYING);
    
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

    if (obj.wear_location = WEAR_NULL) and ((pos(s, obj.name^) <> 0) or (pos(s, obj.short^) <> 0)) then
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

    if (obj.wear_location <> WEAR_NULL) and ((pos(s, obj.name^) <> 0) or (pos(s, obj.short^) <> 0)) then
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

    if isName(vict.name^,name) or isName(vict.short^,name) and (ch.CAN_SEE(vict)) then
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

initialization
char_list := GDLinkedList.Create;
extracted_chars := GDLinkedList.Create;

end.
