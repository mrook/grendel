{
	Summary:
		Room classes
  
	## $Id: rooms.pas,v 1.1 2004/08/24 20:00:56 ***REMOVED*** Exp $
}

unit rooms;


interface


uses
	area,
	dtypes;


type
	{$M+}
	GRoom = class;

	GCoords = class  // x: west->east; y: south->north; z: down->up
	private
		_x, _y, _z : integer;
	
	public
		constructor Create(); overload;
		constructor Create(coords : GCoords); overload;
		
	published
		function toString() : string;
		
		procedure copyTo(coords : GCoords);
		procedure copyFrom(coords : GCoords);
		
		property x : integer read _x write _x;
		property y : integer read _y write _y;
		property z : integer read _z write _z;
	end;	
	
    GExit = class
    public
      vnum : integer;
      direction : integer;
      to_room : GRoom;
      keywords : PString;
      flags : cardinal;
      key : integer;
      constructor Create();
    end;

    GTeleport = class
    public
    	node : GListNode;
      t_room : GRoom;
      timer : integer;
    end;

    GTrack = class
    public
      who : string;
      life : integer;
      direction : integer;
    end;

    GExtraDescription = class
    public
      keywords : string;
      description : string;
    end;

    GRoom = class
    private
		_vnum : integer;
		_name : PString;
		_description : string;
		_sector : integer;
		_televnum, _teledelay : integer;
		_maxlevel, _minlevel : integer;
		_light : integer;
		_height : integer;

	public
		chars : GDLinkedList;
		area : GArea;
		areacoords : GCoords;
		worldcoords : GCoords; // not used yet
		extra : GDLinkedList;
		exits : GDLinkedList;
		objects : GDLinkedList;
		tracks : GDLinkedList;
		flags : GBitVector;

		function IS_DARK : boolean;

		function findChar(c : pointer; name : string) : pointer;
		function findRandomChar : pointer;
		function findRandomGood : pointer;
		function findRandomEvil : pointer;
		function findObject(name : string) : pointer;

		function findDescription(const keyword : string) : GExtraDescription;
		function isConnectedTo(dir : integer) : GRoom;
		function findExit(dir : integer) : GExit;
		function findExitKeyword(s : string) : GExit;

		procedure addCharacter(ch : pointer);
		procedure removeCharacter(ch : pointer);

		constructor Create(vn : integer; ar : GArea);
		destructor Destroy; override;

		procedure setName(const name : string);
		function getName() : string;

	published
		property name : string read getName write setName;
		property description : string read _description write _description;
		property vnum : integer read _vnum write _vnum;
		property sector : integer read _sector write _sector;
		property televnum : integer read _televnum write _televnum;
		property teledelay : integer read _teledelay write _teledelay;
		property minlevel : integer read _minlevel write _minlevel;
		property maxlevel : integer read _maxlevel write _maxlevel;
		property light : integer read _light write _light;
		property height : integer read _height write _height;
	end;


var
	room_list : GHashTable;
	teleport_list : GDLinkedList;


function createRoom(vnum : integer; area : GArea) : GRoom;
function findRoom(vnum : integer) : GRoom;
function findLocation(ch : pointer; const param : string) : GRoom;
function findDirectionShort(startroom, goalroom : GRoom) : string;


implementation


uses
	SysUtils,
	objects,
	chars,
	util,
	mudsystem,
	constants;
	

// GRoom
constructor GRoom.Create(vn : integer; ar : GArea);
begin
  inherited Create();

  _vnum := vn;
  _sector := 1;
  _light := 0;
  
  area := ar;
  areacoords := nil;
  worldcoords := nil;

  flags := GBitVector.Create(0);
  extra := GDLinkedList.Create();
  exits := GDLinkedList.Create();
  chars := GDLinkedList.Create();
  objects := GDLinkedList.Create();
  tracks := GDLinkedList.Create();
end;

destructor GRoom.Destroy;
begin
  unhash_string(_name);

  extra.clear();
  exits.clear();
  chars.clear();
  objects.clear();
  tracks.clear();

  extra.Free();
  exits.Free();
  chars.Free();
  objects.Free();
  tracks.Free();

  inherited Destroy();
end;

procedure GRoom.setName(const name : string);
begin 
  if (_name <> nil) then
    unhash_string(_name);
    
  _name := hash_string(name);
end;

function GRoom.getName() : string;
begin
  if (_name <> nil) then
    Result := _name^
  else
    Result := '';
end;

// Room is dark
function GRoom.IS_DARK : boolean;
begin
  if (light > 0) then
    begin
    Result := false;
    exit;
    end;

  if (sector = SECT_INSIDE) or (sector = SECT_CITY) then
    begin
    Result := false;
    exit;
    end;

  if (flags.isBitSet(ROOM_DARK)) then
    begin
    Result := true;
    exit;
    end;

  if (time_info.sunlight = SUN_SET) or (time_info.sunlight = SUN_DARK) then
    begin
    Result := true;
    exit;
    end;

  Result := false;
end;

// Find char in room by name
function GRoom.findChar(c : pointer; name : string) : pointer;
var
	iterator : GIterator;
	num, cnt : integer;
	ch, vict : GCharacter;
begin
  Result := nil;

	if (name = '') then
		exit;

  if (name = 'SELF') then
    begin
    Result := c;
    exit;
    end;

  ch := c;

  num := findNumber(name);

  name := uppercase(name);
  cnt := 0;

  iterator := chars.iterator();
  
  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (((name = 'GOOD') and (not vict.IS_NPC) and (vict.IS_GOOD)) or
      ((name = 'EVIL') and (not vict.IS_NPC) and (vict.IS_EVIL)) or
      isNameStart(vict.name, name) or isNameStart(vict.short, name) or
      ((not vict.IS_NPC) and (not ch.IS_SAME_ALIGN(vict)) and
      (isNameAny(vict.race.name, name)))) and (ch.CAN_SEE(vict)) then
      begin
      inc(cnt);

      if (cnt = num) then
        begin
        Result := vict;
        break;
        end;
      end;
    end;

  iterator.Free();
  
  if (Result = nil) then
  	begin
		iterator := chars.iterator();

		while (iterator.hasNext()) do
			begin
			vict := GCharacter(iterator.next());

			if (((name = 'GOOD') and (not vict.IS_NPC) and (vict.IS_GOOD)) or
				((name = 'EVIL') and (not vict.IS_NPC) and (vict.IS_EVIL)) or
				isNameAny(vict.name, name) or isNameAny(vict.short, name) or
				((not vict.IS_NPC) and (not ch.IS_SAME_ALIGN(vict)) and
				(isNameAny(vict.race.name, name)))) and (ch.CAN_SEE(vict)) then
				begin
				inc(cnt);

				if (cnt = num) then
					begin
					Result := vict;
					break;
					end;
				end;
			end;

		iterator.Free();
		end;
end;

// Find random char in room
function GRoom.findRandomChar() : pointer;
var
	a, num : integer;
  node : GListNode;
begin
  Result := nil;
  
  if (chars.size() = 0) then
    exit;
  
  num := random(chars.size());

  node := chars.head;
  for a := 0 to num do
    node := node.next;

  if (node <> nil) then
    Result := node.element;
end;

// Find random good aligned char in room
function GRoom.findRandomGood() : pointer;
var 
	a, cnt, num : integer;
	vict : GCharacter;
	iterator : GIterator;
begin
  Result := nil;

  cnt := 0;
  iterator := chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_GOOD) then
      inc(cnt);
    end;

  iterator.Free();

  num := random(cnt);
  a := 0;

  iterator := chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_GOOD) and (a = num) then
      begin
      Result := vict;
      break;
      end;
    end;

  iterator.Free();
end;

// Find random evil aligned char in room
function GRoom.findRandomEvil() : pointer;
var 
	a, cnt, num : integer;
	vict : GCharacter;
	iterator : GIterator;
begin
  Result := nil;

  cnt := 0;
  iterator := chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_EVIL) then
      inc(cnt);
    end;

  iterator.Free();

  num := random(cnt);
  a := 0;

  iterator := chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_EVIL) and (a = num) then
      begin
      Result := vict;
      break;
      end;
    end;

  iterator.Free();
end;

// Find object by name in room
function GRoom.findObject(name : string) : pointer;
var
	iterator : GIterator;
	obj : GObject;
	num, cnt : integer;
begin
  Result := nil;
  
  if (name = '') then
  	exit;

  iterator := objects.iterator();
  num := findNumber(name);
  cnt := 0;

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if isObjectName(obj.name, name) or isObjectName(obj.short, name) or isObjectName(obj.long, name) then
      begin
      inc(cnt, obj.count);

      if (cnt >= num) then
        begin
        Result := obj;
        break;
        end;
      end;
    end;
    
	iterator.Free();
end;

function GRoom.findDescription(const keyword : string) : GExtraDescription;
var
	iterator : GIterator;
	s_extra : GExtraDescription;
	s, p : integer;
	sub, key : string;
begin
  Result := nil;
  
  if (keyword = '') then
  	exit;
  	
  p := high(integer);

  iterator := extra.iterator();
  while (iterator.hasNext()) do
    begin
    s_extra := GExtraDescription(iterator.next());
    key := s_extra.keywords;

    while (length(key) > 0) do
      begin
      key := one_argument(key, sub);
      
      s := pos(keyword, sub);
      if (s > 0) and (s < p) then
        begin
        p := s;
        Result := s_extra;
        end;
      end;
    end;

	iterator.Free();
end;

{ Xenon 7/6/2001: added isConnectedTo() because I needed it for do_map() :-) }
function GRoom.isConnectedTo(dir : integer) : GRoom;
var
	iterator : GIterator;
	pexit : GExit;
begin
	Result := nil;

  iterator := exits.iterator();
  
  while (iterator.hasNext()) do
    begin
    pexit := GExit(iterator.next());

    if (pexit.direction = dir) then
    	begin
      Result := pexit.to_room;
      break;
    	end;
    end;
    
	iterator.Free();
end;

// Find exit by direction in room
function GRoom.findExit(dir : integer) : GExit;
var
	iterator : GIterator;
	pexit : GExit;
begin
  Result := nil;

  iterator := exits.iterator();
  
  while (iterator.hasNext()) do
    begin
    pexit := GExit(iterator.next());

    if (pexit.direction = dir) then
      begin
      Result := pexit;
      break;
      end;
    end;
    
	iterator.Free();
end;

// Find exit by exit keyword
function GRoom.findExitKeyword(s : string) : GExit;
var
	iterator : GIterator;
	pexit : GExit;
begin
  Result := nil;
  
  if (s = '') then
  	exit;
  	
  s := uppercase(s);

  iterator := exits.iterator();
  
  while (iterator.hasNext()) do
    begin
    pexit := GExit(iterator.next());

    if (Assigned(pexit.keywords)) and (pos(s, uppercase(pexit.keywords^)) <> 0) then
      begin
      Result := pexit;
      break;
      end;
    end;
    
	iterator.Free();
end;

// Add character to room
procedure GRoom.addCharacter(ch : pointer);
var
	iterator : GIterator;
	tele : GTeleport;
begin
	if (GCharacter(ch).IS_WEARING(ITEM_LIGHT)) then
		light := light + 1;

	chars.add(ch);

	{ Only PCs register as players, so increase the number! - Grimlord }
	if (not GCharacter(ch).IS_NPC) then
		inc(area.nplayer);

	{ check for teleports }
	if (flags.isBitSet(ROOM_TELEPORT)) and (teledelay > 0) then
		begin
		iterator := teleport_list.iterator();

		while (iterator.hasNext()) do
			begin
			tele := GTeleport(iterator.next());

			if (tele.t_room = Self) then
				begin
				iterator.Free();
				exit;
				end;
			end;

		iterator.Free();

		tele := GTeleport.Create();
		tele.t_room := Self;
		tele.timer := teledelay;

		tele.node := teleport_list.insertLast(tele);
		end;
end;

// Remove character from room
procedure GRoom.removeCharacter(ch : pointer);
begin
	chars.remove(GCharacter(ch));

	if (GNPC(ch).IS_WEARING(ITEM_LIGHT)) and (light > 0) then
		light := light - 1;

	{ Only PCs register as players, so increase the number! - Grimlord }
	if (not GNPC(ch).IS_NPC) then
		dec(area.nplayer);
end;

// GExit
constructor GExit.Create();
begin
  inherited Create();
// Make sure variables are at least initialised to a value
  vnum := -1;
  direction := 0;
  to_room := nil;
  keywords := nil;
  flags := 0;
  key := 0;
end;

function createRoom(vnum : integer; area : GArea) : GRoom;
var
	room : GRoom;
begin
	room := GRoom.Create(vnum, area);
	room.name := 'Floating in a void';
	room.description := 'Merely wisps of gas and steam, this room has not yet been clearly defined.'#13#10;

	room_list.put(vnum, room);

	Result := room;
end;

// Find room by vnum
function findRoom(vnum : integer) : GRoom;
begin
	Result := GRoom(room_list.get(vnum));
end;

{Jago 5/Jan/01 : func required for do_goto and do_transfer }
function findLocation(ch : pointer; const param : string) : GRoom;
var
	room : GRoom;
	searchVNum : integer;
	victim : GCharacter;
begin
	result := nil;

	if (param = '') then	
		exit;
	
	searchVNum := StrToIntDef(param, -1);

	if (searchVnum > -1) then
		begin
		room := findRoom(searchVNum);
		Result := room;
		exit;
		end
	else
		begin
		victim := findCharWorld(ch, param);

		if (victim <> nil) then
			begin
			Result := GRoom(victim.room);
			exit;
			end;
	end;
end;

function findDirectionShort(startroom, goalroom : GRoom) : string;
var
	i : integer;
begin
	Result := '';
	

	for i := DIR_NORTH to DIR_UP do
		begin
		if (startroom.isConnectedTo(i) = goalroom) then
			begin
			Result := headings_short[i];
			exit;
			end;
		end;
end;


constructor GCoords.Create();
begin
  inherited Create();
  
  _x := 0;
  _y := 0;
  _z := 0;
end;

constructor GCoords.Create(coords : GCoords);
begin
  inherited Create();
  
  copyFrom(coords);
end;

function GCoords.toString() : string;
begin
  Result := '(' + IntToStr(_x) + ',' + IntToStr(_y) + ',' + IntToStr(_z) + ')';
end;

procedure GCoords.copyTo(coords : GCoords);
begin
  coords.x := _x;
  coords.y := _y;
  coords.z := _z;
end;

procedure GCoords.copyFrom(coords : GCoords);
begin
  _x := coords.x;
  _y := coords.y;
  _z := coords.z;
end;


initialization
	room_list := GHashTable.Create(32768);
	room_list.ownsObjects := false;

	teleport_list := GDLinkedList.Create();

finalization
	room_list.clear();
	room_list.Free();

	teleport_list.clear();
	teleport_list.Free();


end.