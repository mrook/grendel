{
  Summary:
  	(N)PC classes & routines
  	
  ## $Id: chars.pas,v 1.14 2004/04/10 22:24:03 ***REMOVED*** Exp $
}

unit chars;

interface

uses
    SysUtils,
    Math,
{$IFDEF LINUX}
    Libc,
{$ENDIF}
    area,
    race,
	clan,
    dtypes,
    gvm;


{$M+}
type
    GCharacter = class;

    GTrophy = record
      name : string;
      level, times : integer;
    end;

    GAlias = class
    public
      alias : string;
      expand : string;

      node : GListNode;
    end;

    GHistoryElement = class
    public
        time : TDateTime;
        contents : PString;
        constructor Create(const txt : string);
        destructor Destroy(); override;
      end;

    GUserChannel = class
    public
			channelname : string;
			history : GDLinkedList;
			ignored : boolean;
			
			constructor Create(const name : string);
			destructor Destroy(); override;
		end;

    GLearned = class
    public
      node : GListNode;

      skill : pointer;
      perc : integer;

      constructor Create(perc_ : integer; skill_ : pointer);
    end;

    {$M+}
    GCharacter = class
      node_world, node_room : GListNode;
      inventory : GDLinkedList;
      equipment : GHashTable;

      master, leader : GCharacter;
      fighting, hunting : GCharacter;
      snooped_by : GCharacter;

    protected
      _level : integer;
      _str, _con, _dex, _int, _wis : integer;
      _hp, _max_hp : integer;
      _mv, _max_mv : integer;
      _mana, _max_mana : integer;
      _apb : integer;

      _alignment : integer;
      
      _gold : integer;               { Gold carried }
      _sex : integer;

      _save_poison, _save_cold, _save_para,  { saving throws }
      _save_breath, _save_spell : integer;

      _name, _short, _long : PString;

    public
      ac_mod : integer;             { AC modifier (spells?) }
      natural_ac : integer;         { Natural AC (race based for PC's) }
      hac, bac, aac, lac, ac : integer; { head, body, arm, leg and overall ac }
      hitroll : integer;            { the hit roll }
      damnumdie, damsizedie : integer;

      tracking : string;

      logging : boolean;

      position : integer;
      state : integer;
      mental_state : integer;
      room : GRoom;
      substate : integer;
      trust : integer;
      kills : integer;
      wait : integer;
      skills_learned : GDLinkedList;
      cast_timer, bash_timer, bashing : integer;
      in_command : boolean;
      race : GRace;
      carried_weight : integer;             { weight of items carried }
      weight, height : integer;       { weight/height of (N)PC }
      last_cmd : pointer;
      affects : GDLinkedList;
      aff_flags : cardinal;
      clan : GClan;                 { joined a clan? }

      procedure sendPrompt; virtual;
      procedure sendBuffer(const s : string); virtual;
      procedure sendPager(const txt : string); virtual;
      procedure emptyBuffer; virtual;

      function ansiColor(color : integer) : string; virtual;

      function getTrust() : integer;

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
      function CAN_SEE(target : TObject) : boolean;

      function LEARNED(skill : pointer) : integer;
      procedure SET_LEARNED(perc : integer; skill : pointer);

      procedure extract(pull : boolean);
      procedure fromRoom();
      procedure toRoom(to_room : GRoom);

      function getEQ(const location : string) : GObject;
      function getWield(item_type : integer) : GObject;
      function getDualWield() : GObject;
      procedure affectObject(obj : GObject; remove: boolean);
      function equip(obj : GObject; silent : boolean = false) : boolean;

      procedure die(); virtual;

      procedure setWait(ticks : integer);

      function calcxp2lvl : cardinal;

      procedure calcAC();

      procedure startFlying();
      procedure stopFlying();

      function findInventory(s : string) : GObject;
      function findEquipment(const s : string) : GObject;

      constructor Create();
      destructor Destroy(); override;

      procedure setName(const name : string);
      procedure setShortName(const name : string);
      procedure setLongName(const name : string);
      function getName() : string;
      function getShortName() : string;
      function getLongName() : string;
      function getRaceName() : string;

    published
    // properties   
      property level : integer read _level write _level;
      property str : integer read _str write _str;
      property con : integer read _con write _con;
      property dex : integer read _dex write _dex;
      property int : integer read _int write _int;
      property wis : integer read _wis write _wis;

      property hp : integer read _hp write _hp;
      property max_hp : integer read _max_hp write _max_hp;
      property mv : integer read _mv write _mv;
      property max_mv : integer read _max_mv write _max_mv;
      property mana : integer read _mana write _mana;
      property max_mana : integer read _max_mana write _max_mana;

      property apb : integer read _apb write _apb;
      
      property alignment : integer read _alignment write _alignment;

      property gold : integer read _gold write _gold;
      property sex : integer read _sex write _sex;

      property save_poison : integer read _save_poison write _save_poison;
      property save_cold : integer read _save_cold write _save_cold;
      property save_para : integer read _save_para write _save_para;
      property save_breath : integer read _save_breath write _save_breath;
      property save_spell : integer read _save_spell write _save_spell;

      property name : string read getName write setName;
      property short : string read getShortName write setShortName;
      property long : string read getLongName write setLongName;
      property rname : string read getRaceName;
    end;

    GNPC = class(GCharacter)
    public
      npc_index : GNPCIndex;
      act_flags : cardinal;
      context : GContext;

    published
    	constructor Create();
    	destructor Destroy(); override;
    	
      function IS_IMMORT : boolean; override;
      function IS_NPC : boolean; override;
      function IS_LEARNER : boolean; override;
      function IS_WIZINVIS : boolean; override;
      function IS_BANKER : boolean; override;
      function IS_SHOPKEEPER : boolean; override;

      procedure sendBuffer(const s : string); override;
      procedure die; override;
    end;
{$M-}


var
   char_list : GDLinkedList;
   extracted_chars : GDLinkedList;


function findCharWorld(ch : GCharacter; name : string) : GCharacter;

procedure cleanExtractedChars();

procedure initChars();
procedure cleanupChars();


implementation


uses
	constants,
    util,
	player,
	conns,
	skills,
	console,
	mudsystem;


constructor GHistoryElement.Create(const txt : string);
begin
  inherited Create();
  
  time := Now();
  contents := hash_string(txt);
end;

destructor GHistoryElement.Destroy();
begin
  unhash_string(contents);
  inherited Destroy();
end;

constructor GUserChannel.Create(const name : string);
begin
  inherited Create();
  
  channelname := name;
  history := GDLinkedList.Create();
  ignored := false;
end;

destructor GUserChannel.Destroy();
begin	
  history.clear();
  history.Free();
  
  inherited Destroy();
end;

// GCharacter constructor
constructor GCharacter.Create();
begin
  inherited Create();

  inventory := GDLinkedList.Create();
  equipment := GHashTable.Create(32);
  equipment.setHashFunc(sortedHash);
  affects := GDLinkedList.Create();

  master := nil;
  snooped_by := nil;
  leader := Self;
  tracking := '';
end;

// GCharacter destructor
destructor GCharacter.Destroy();
begin
  affects.clear();
  affects.Free();

  inventory.clear();
  inventory.Free();
  
  equipment.clear();
  equipment.Free();

  hunting := nil;

  unhash_string(_name);
  unhash_string(_short);
  unhash_string(_long);

  inherited Destroy;
end;

procedure GCharacter.extract(pull : boolean);
{ set pull to false if you wish for character to stay
  alive, e.g. in portal or so. don't set to false for NPCs - Grimlord }
begin
  if (CHAR_DIED) then
    begin
    bugreport('extract_char', 'area.pas', 'ch already extracted');
    exit;
    end;

  if (room <> nil) then
    fromRoom();

  if (not pull) then
    begin
    if (IS_EVIL) then
      toRoom(findRoom(ROOM_VNUM_EVIL_PORTAL))
    else
      toRoom(findRoom(ROOM_VNUM_GOOD_PORTAL));
    end
  else
    begin
    { TODO: 
    if (conn <> nil) then
      GConnection(conn).ch := nil; }

    char_list.remove(node_world);
    node_world := extracted_chars.insertLast(Self);
    end;
end;

procedure GCharacter.setName(const name : string);
begin
  _name := hash_string(name);
end;

procedure GCharacter.setShortName(const name : string);
begin
  _short := hash_string(name);
end;

procedure GCharacter.setLongName(const name : string);
begin
  _long := hash_string(name);
end;

function GCharacter.getName() : string;
begin
  if (_name <> nil) then
    Result := _name^
  else
    Result := '';
end;

function GCharacter.getShortName() : string;
begin
  if (_short <> nil) then
    Result := _short^
  else
    Result := '';
end;

function GCharacter.getLongName() : string;
begin
  if (_long <> nil) then
    Result := _long^
  else
    Result := '';
end;

function GCharacter.getRaceName() : string;
begin
  if (race <> nil) then
    Result := race.name
  else
    Result := '';
end;

function GCharacter.getTrust() : integer;
var
   ch : GCharacter;
begin
  if (snooped_by <> nil) and (GPlayer(snooped_by).switching = Self) then
    ch := snooped_by
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
  iterator : GIterator;
  ch : GCharacter;
begin
  CHAR_DIED := false;

  if (Self = nil) then
    begin
    CHAR_DIED := true;
    exit;
    end;

  iterator := extracted_chars.iterator();
  
  while (iterator.hasNext()) do
    begin
    ch := GCharacter(iterator.next());

    if (ch = Self) then
      begin
      CHAR_DIED := true;
      break;
      end;
    end;
  
  iterator.Free();
end;

procedure GCharacter.sendPrompt();
begin
end;

procedure GCharacter.sendBuffer(const s : string);
begin
end;

procedure GCharacter.sendPager(const txt : string);
begin
end;

procedure GCharacter.emptyBuffer();
begin
end;

function GCharacter.IS_IMMORT : boolean;
begin
  Result := false;
end;

function GCharacter.IS_NPC : boolean;
begin
  Result := false;
end;

function GCharacter.IS_LEARNER : boolean;
begin
  Result := false;
end;

function GCharacter.IS_AWAKE : boolean;
begin
  IS_AWAKE := (state <> STATE_SLEEPING);
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
  Result := (position = POS_FLYING);
end;

function GCharacter.IS_BANKER : boolean;
begin
  Result := false;
end;

function GCharacter.IS_SHOPKEEPER : boolean;
begin
  Result := false;
end;

function GCharacter.IS_OUTSIDE : boolean;
begin
  IS_OUTSIDE := (room.sector <> SECT_INSIDE) and (not room.flags.isBitSet(ROOM_INDOORS));
end;

function GCharacter.IS_AFFECT(affect : integer) : boolean;
begin
  IS_AFFECT := IS_SET(aff_flags, affect);
end;

function GCharacter.IS_DRUNK : boolean;
begin
	IS_DRUNK := false;
end;

// Char is wearing an object of type <item_type>
function GCharacter.IS_WEARING(item_type : integer) : boolean;
var
  iterator : GIterator;
  obj : GObject;
begin
  Result := false;
  
  iterator := equipment.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (obj.item_type = item_type) then
      begin
      Result := true;
      break;
      end;
    end;
  
  iterator.Free();
end;

function GCharacter.IS_HOLYWALK : boolean;
begin
  Result := false;
end;

function GCharacter.IS_HOLYLIGHT : boolean;
begin
  Result := false;
end;

{ Utility function - Nemesis }
function GCharacter.IS_AFK : boolean;
begin
  Result := false;
end;

{ utility function - Nemesis }
function GCharacter.IS_KEYLOCKED : boolean;
begin
  Result := false;
end;

function GCharacter.IS_EDITING : boolean;
begin
   Result := false;
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

  if (Self = target) then
    exit;
    
  if (not IS_AWAKE) then
    CAN_SEE := false;

	if (target is GRoom) then
		begin
	  if (room.IS_DARK) and (not IS_HOLYLIGHT) and (not IS_SET(aff_flags, AFF_INFRAVISION)) then
	    CAN_SEE := false;
	  end;

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

// Check what percentage char has learned <skill>
function GCharacter.LEARNED(skill : pointer) : integer;
var
	iterator : GIterator;
	g : GLearned;
begin
  Result := 0;

  iterator := skills_learned.iterator();

  while (iterator.hasNext()) do
    begin
    g := GLearned(iterator.next());

    if (g.skill = skill) then
      begin
      Result := g.perc;
      break;
      end;
    end;
  
  iterator.Free();
end;

// Xenon 10/Apr/2001: Modified SET_LEARNED() to remove skill from linked list when perc = 0
procedure GCharacter.SET_LEARNED(perc : integer; skill : pointer);
var
	iterator : GIterator;
	g, x : GLearned;
begin
	g := nil;
  iterator := skills_learned.iterator();

  while (iterator.hasNext()) do
    begin
    x := GLearned(iterator.next());
    
    if (x.skill = skill) then
      begin
      g := x;
      break;
      end;
    end;
  
  iterator.Free();

  if (g = nil) then
    begin
    g := GLearned.Create(perc, skill);
    g.node := skills_learned.insertLast(g);
    end
  else
  	begin
    if (perc > 0) then
      g.perc := perc
    else
      skills_learned.remove(g.node);
    end;
end;

function GCharacter.ansiColor(color : integer) : string;
begin
  Result := '';
end;

// Char from room
procedure GCharacter.fromRoom();
begin
  if (room = nil) then
    begin
    bugreport('GCharacter.fromRoom', 'chars.pas', 'room null');
    exit;
    end;

  room.chars.remove(node_room);

  if (IS_WEARING(ITEM_LIGHT)) and (room.light > 0) then
    room.light := room.light - 1;

  { Only PCs register as players, so increase the number! - Grimlord }
  if (not IS_NPC) then
    dec(room.area.nplayer);

  room := nil;
end;

// Char to room
procedure GCharacter.toRoom(to_room : GRoom);
var
	tele : GTeleport;
	iterator : GIterator;
begin
  if (to_room = nil) then
    begin
    bugreport('GCharacter.toRoom', 'chars.pas', 'room null, moving to portal');

    if (IS_IMMORT) then
    begin
      to_room := findRoom(ROOM_VNUM_IMMORTAL_PORTAL);
      if (to_room = nil) then
      begin
        bugreport('GCharacter.toRoom', 'chars.pas', 'immortal portal not found');
      end;
    end;

    if (to_room = nil) then
      if (IS_EVIL) then
        to_room := findRoom(ROOM_VNUM_EVIL_PORTAL)
      else
        to_room := findRoom(ROOM_VNUM_GOOD_PORTAL);

    if (to_room = nil) then
      begin
      bugreport('GCharacter.toRoom', 'chars.pas', 'HELP! even portal is NULL room! what did you do?');

      writeConsole('System is unstable - prepare for a rough ride');
      exit;
      end;
    end;

  room := to_room;

  if (IS_WEARING(ITEM_LIGHT)) then
    room.light := room.light + 1;

  node_room := room.chars.insertLast(Self);

  { Only PCs register as players, so increase the number! - Grimlord }
  if (not IS_NPC) then
    inc(to_room.area.nplayer);

  { check for teleports }
  if (to_room.flags.isBitSet(ROOM_TELEPORT)) and (to_room.teledelay > 0) then
    begin
    iterator := teleport_list.iterator();

    while (iterator.hasNext()) do
      begin
      tele := GTeleport(iterator.next());
      
      if (tele.t_room = to_room) then
        begin
        iterator.Free();
        exit;
        end;
      end;
      
    iterator.Free();

    tele := GTeleport.Create();
    tele.t_room := to_room;
    tele.timer := to_room.teledelay;

    tele.node := teleport_list.insertLast(tele);
    end;
end;

// Char dies
procedure GCharacter.die();
begin
  { snooping/switching immortals should stop doing so when we die }
	if (snooped_by <> nil) then
    begin
    GPlayer(snooped_by).snooping := nil;
    GPlayer(snooped_by).switching := nil;
    snooped_by.sendBuffer('Ok.'#13#10);
    snooped_by := nil;
    end;

  addCorpse(Self);
end;

// GNPC
constructor GNPC.Create();
begin
	inherited Create();
	
	context := nil;
end;

destructor GNPC.Destroy();
begin
	if (Assigned(context)) then
		FreeAndNil(context);
		
	inherited Destroy();
end;

function GNPC.IS_SHOPKEEPER : boolean;
begin
  Result := IS_SET(act_flags, ACT_SHOPKEEP);
end;

function GNPC.IS_BANKER : boolean;
begin
  Result := IS_SET(act_flags, ACT_BANKER);
end;

function GNPC.IS_WIZINVIS : boolean;
begin
  Result := IS_SET(act_flags, ACT_MOBINVIS)
end;

function GNPC.IS_LEARNER : boolean;
begin
  Result := IS_SET(act_flags, ACT_TEACHER);
end;

function GNPC.IS_NPC : boolean;
begin
  Result := true;
end;

function GNPC.IS_IMMORT : boolean;
begin
  Result := inherited IS_IMMORT;

  if (IS_SET(act_flags, ACT_IMMORTAL)) then
    IS_IMMORT := true;
end;

procedure GNPC.die();
begin
  inherited die();

  dec(npc_index.count);
  extract(true);
  dec(mobs_loaded);
end;

procedure GNPC.sendBuffer(const s : string);
begin
	if (snooped_by <> nil) then
    GPlayer(snooped_by).conn.send(s); 
end;

procedure GCharacter.setWait(ticks : integer);
begin
  wait := UMax(wait, ticks);
end;

// Get object wearing at bodypart <location>
function GCharacter.getEQ(const location : string) : GObject;
var
	iterator : GIterator;
  obj : GObject;
begin
  Result := nil;

	iterator := equipment.iterator();
	
  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (obj.worn = location) then
      begin
      Result := obj;
      break;
      end;
    end;
    
  iterator.Free();
end;

// Get wielded object by <item_type>
function GCharacter.getWield(item_type : integer) : GObject;
var
   obj : GOBject;
begin
  getWield := nil;

  obj := getEQ('rightwield');
  if (obj <> nil) and (obj.item_type = item_type) then
    begin
    getWield := obj;
    exit;
    end;

  obj := getEQ('leftwield');
  if (obj <> nil) and (obj.item_type = item_type) then
    begin
    getWield:=obj;
    exit;
    end;
end;

function GCharacter.getDualWield() : GObject;
begin
  getDualWield := nil;

  { can't dual wield }
  if (LEARNED(gsn_dual_wield) = 0) then
    exit;

  if (getEQ('rightwield') <> nil) and (getEQ('leftwield') <> nil) then
    getDualWield := getEQ('leftwield');
end;

// Apply/Remove special affects on an object
procedure GCharacter.affectObject(obj : GObject; remove : boolean);
var
   iterator : GIterator;
   aff : GAffect;
begin
  with obj do
    case obj.item_type of
      ITEM_ARMOR: calcAC;
      ITEM_LIGHT: if (remove) then
                    Self.room.light := room.light - 1
                  else
                    Self.room.light := room.light + 1;
      ITEM_GEM: if (remove) then
                  max_mana := max_mana - obj.value[3]
                else
                  max_mana := max_mana + obj.value[3]
    end;

  iterator := obj.affects.iterator();
  
	while (iterator.hasNext()) do
		begin
		aff := GAffect(iterator.next());

		aff.modify(Self, not remove);
		end;
end;

// Equip object
function GCharacter.equip(obj : GObject; silent : boolean = false) : boolean;
var
  bodypart : GBodyPart;
begin
  Result := true;

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

  if (obj.wear_location1 <> '') and (getEQ(obj.wear_location1) = nil) then      { Wear on spot #1}
    begin
    bodypart := GBodyPart(race.bodyparts[obj.wear_location1]);
    
    if (bodypart = nil) then
      begin
      act(AT_REPORT, 'You do not have the right anatomy to wear $p.', false, Self, obj, nil, TO_CHAR);
      Result := false;
      exit;
      end;

	if (not silent) then
		begin
		act(AT_REPORT, bodypart.char_message, false, Self, obj, nil, TO_CHAR);
		act(AT_REPORT, bodypart.room_message, false, Self, obj, nil, TO_ROOM);
		end;

    obj.fromChar();
    obj.worn := obj.wear_location1;
    obj.toChar(Self);

    affectObject(obj, false);
    end
  else
  if (obj.wear_location2 <> '') and (getEQ(obj.wear_location2) = nil) then      { Wear on spot #2}
    begin
    bodypart := GBodyPart(race.bodyparts[obj.wear_location2]);
    
    if (bodypart = nil) then
      begin
      act(AT_REPORT, 'You do not have the right anatomy to wear $p.', false, Self, obj, nil, TO_CHAR);
      Result := false;
      exit;
      end;
      
	if (not silent) then
		begin
		act(AT_REPORT, bodypart.char_message, false, Self, obj, nil, TO_CHAR);
		act(AT_REPORT, bodypart.room_message, false, Self, obj, nil, TO_ROOM);
		end;
		
    obj.fromChar();
    obj.worn := obj.wear_location2;
    obj.toChar(Self);

    affectObject(obj, false);
    end
  else                                              { No spots left }
    begin
    sendBuffer('You are already wearing something there!'#13#10);
    Result := false;
    end; 
end;

function GCharacter.calcxp2lvl : cardinal;
begin
  calcxp2lvl := round((20*power(level,1.2))*(1+(random(2)/10)));
end;

// Calculate Armour Class
procedure GCharacter.calcAC();
var
  dex_mod : integer;
  iterator : GIterator;
  obj : GObject;
begin
  dex_mod := (dex-50) div 12;
  hac := natural_ac - dex_mod + ac_mod;
  bac := natural_ac - dex_mod + ac_mod;
  aac := natural_ac - dex_mod + ac_mod;
  lac := natural_ac - dex_mod + ac_mod;

  iterator := equipment.iterator();
  
  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (obj.item_type = ITEM_ARMOR) then
      case obj.value[2] of
        ARMOR_HAC : dec(hac, obj.value[3]);
        ARMOR_BAC : dec(bac, obj.value[3]);
        ARMOR_AAC : dec(aac, obj.value[3]);
        ARMOR_LAC : dec(lac, obj.value[3]);
      end;
    end;
    
  iterator.Free();

  ac := (hac + bac + aac + lac) div 4;
end;

// Start flying
procedure GCharacter.startFlying();
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
    position := POS_FLYING;

    act(AT_REPORT,'You begin to fly again!',false,Self,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n gently floats up in the air.',false,Self,nil,nil,TO_ROOM);
    end
  else
    begin
    act(AT_REPORT,'You flap your arms, but never leave the ground.',false,Self,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n flaps $s arms to fly, but can''t.',false,Self,nil,nil,TO_ROOM);
    end;
end;

// Stop flying
procedure GCharacter.stopFlying();
begin
  if (IS_FLYING) then
    begin
    position := POS_STANDING;

    act(AT_REPORT,'You slowly land on the ground.',false,Self,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n gently lands on the ground.',false,Self,nil,nil,TO_ROOM);
    end;
end;

// Find object in inventory by name
function GCharacter.findInventory(s : string) : GObject;
var 
  obj : GObject;
  iterator : Giterator;
  number, count : integer;
begin
  Result := nil;
  
  number := findNumber(s); // eg 2.object

  count := 0;

  iterator := inventory.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());
    
    if (isObjectName(obj.name, s) or isObjectName(obj.short, s)) then
      begin
      inc(count);
  
      if (count = number) then
        begin
        Result := obj;
        break;
        end;
      end;
    end;
    
  iterator.Free();
end;

// Find object in equipment by name
function GCharacter.findEquipment(const s : string) : GObject;
var 
  obj : GObject;
  iterator : GIterator;
begin
  Result := nil;

  iterator := equipment.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (isObjectName(obj.name, s) or isObjectName(obj.short, s)) then
      begin
      Result := obj;
      break;
      end;
    end;
    
  iterator.Free();
end;

{ Added 2.<char> - Nemesis }
function findCharWorld(ch : GCharacter; name : string) : GCharacter;
var
	iterator : GIterator;
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

  iterator := char_list.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (isName(vict.name,name)) or (isName(vict.short,name)) and (ch.CAN_SEE(vict)) then
      begin
      inc(count);

      if (count = number) then
        begin
        findCharWorld := vict;
        break;
        end;
      end;
    end;
    
	iterator.Free();
end;

{ GLearned }
constructor GLearned.Create(perc_: integer; skill_: pointer);
begin
  inherited Create;

  perc := perc_;
  skill := skill_;
end;

procedure cleanExtractedChars();
begin
  extracted_chars.clear();
end;

procedure initChars();
begin
  char_list := GDLinkedList.Create();
  extracted_chars := GDLinkedList.Create();
  extracted_chars.ownsObjects := false;
end;

procedure cleanupChars();
begin
  char_list.clear();
  char_list.Free();

  extracted_chars.clear();
  extracted_chars.Free();
end;

end.

