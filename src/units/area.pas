{
	Summary:
		Area loader & manager
  
  ## $Id: area.pas,v 1.7 2004/02/02 15:35:58 ***REMOVED*** Exp $
}

unit area;

interface

uses
	SysUtils,
	Classes,
	constants,
	dtypes,
	clan,
	race,
	fsys,
	gvm,
	strip,
	util;

{$M+}
type
    GRoom = class;
    GShop = class;

    GWeather = record
      mmhg, change, sky : integer;
      temp, temp_mult, temp_avg : integer;
    end;

    GArea = class
    private
      af : GFileReader;
    
      _age : integer;	
      _name, _author : string;
      _maxage : integer;
      _resetmsg : string;

      found_range : boolean;
    public     
      m_lo, m_hi, r_lo, r_hi, o_lo, o_hi : integer;
      fname : string;
      nplayer : integer;
      weather : GWeather;             { current local weather }
      flags : GBitVector;
      resets : GDLinkedList;

      procedure areaBug(func : string; problem : string);

      procedure loadRooms();
      procedure loadNPCs();
      procedure loadObjects();
      procedure loadResets();
      procedure loadShops();

      procedure update();
      procedure reset();

      procedure load(fn : string);
      procedure save(fn : string);

      constructor Create();
      destructor Destroy(); override;
    published
      property name : string read _name write _name;
      property author : string read _author write _author;
      property resetmsg : string read _resetmsg write _resetmsg;

      property maxage : integer read _maxage write _maxage;
    end;

    GObjectValues = array[1..4] of integer;

    GObject = class
    private
      _name, _short, _long : PString;
      _vnum : integer;
    public
      node_world, node_room, node_in, node_carry : GListNode;

      area : GArea;
      affects : GDLinkedList;
      contents : GDLinkedList;
      carried_by : pointer;
      in_obj : GObject;
      room : GRoom;
      value : GObjectValues;
      
      worn : string;
      wear_location1, wear_location2 : string;

      flags : cardinal;
      item_type : integer;
      weight:integer;
      cost:integer;
      count:integer;
      timer:integer;
      
      child_count : integer; { how many of me were cloned }

  	published
      procedure toRoom(to_room : GRoom);
      procedure fromRoom();

      procedure toChar(c : pointer);
      procedure fromChar();

      procedure toObject(obj : GObject);
      procedure fromObject();

      function getWeight() : integer;

      function clone() : GObject;
      function group(obj : GObject) : boolean;
      procedure split(num : integer);
      procedure seperate();

      constructor Create();
      destructor Destroy(); override;

      procedure setName(const name : string);
      procedure setShortName(const name : string);
      procedure setLongName(const name : string);
      function getName() : string;
      function getShortName() : string;
      function getLongName() : string;

      property vnum : integer read _vnum write _vnum;
      property name : string read getName write setName;
      property short : string read getShortName write setShortName;
      property long : string read getLongName write setLongName;
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

    GNPCIndex = class
    public
      str,con,dex,int,wis:integer;
      hp,mv,mana,apb,natural_ac:integer;
      hitroll:integer;
      damnumdie,damsizedie:integer;
      vnum:integer;
      count:longint;
      name,short,long : PString;
      sex:integer;
      race : GRace;
      alignment:integer;
      level:integer;
      gold,weight,height:integer;

      prog : GCodeBlock;
      progfile : string;

      skills_learned : GDLinkedList;

      act_flags : cardinal;
      area : GArea;
      clan : GClan;
      shop : GShop;

      destructor Destroy; override;
    end;

    GReset = class
    public
      area : GArea;
      reset_type : char;
      arg1, arg2, arg3 : integer;
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

    GCoords = class  // x: west->east; y: south->north; z: down->up
    public
      x, y, z : integer;
      constructor Create(); overload;
      constructor Create(coords : GCoords); overload;
      function toString() : string;
      procedure copyTo(coords : GCoords);
      procedure copyFrom(coords : GCoords);
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

    public
      area : GArea;
      areacoords : GCoords;
      worldcoords : GCoords; // not used yet
      extra : GDLinkedList;
      exits : GDLinkedList;
      chars : GDLinkedList;
      objects : GDLinkedList;
      tracks : GDLinkedList;
      flags : GBitVector;

      function IS_DARK : boolean;

      function findChar(c : pointer; name : string) : pointer;
      function findRandomChar : pointer;
      function findRandomGood : pointer;
      function findRandomEvil : pointer;
      function findObject(name : string) : pointer;

      function findDescription(keyword : string) : GExtraDescription;
      function isConnectedTo(dir : integer) : GRoom;
      function findExit(dir : integer) : GExit;
      function findExitKeyword(s : string) : GExit;

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
    end;

    GShop = class
    public
      node : GListNode;
      keeper : integer;                        { keeper vnum }
      area : GArea;
      item_buy : array[1..MAX_TRADE] of integer;    { item_type to buy }
      open_hour, close_hour : integer;          { opening hours }
    end;


var
   objectList : GDLinkedList;  
   objectIndices : GHashTable;
   
   area_list : GDLinkedList;
   room_list : GHashTable;
   shop_list : GDLinkedList;
   teleport_list : GDLinkedList;

   npc_list : GDLinkedList;

procedure loadAreas();

function createRoom(vnum : integer; area : GArea) : GRoom;
function findArea(fname : string) : GArea;

function findRoom(vnum : integer) : GRoom;
function findLocation(ch : pointer; param : string) : GRoom;
function findNPCIndex(vnum : integer) : GNPCIndex;

{ function findObjectIndex(vnum : integer) : GObjectIndex; }
{ function instanceObject(o_index : GObjectIndex) : GObject; }

function instanceNPC(npcindex : GNPCIndex) : pointer;
procedure addCorpse(c : pointer);
function findHeading(s : string) : integer;
function findDirectionShort(startroom, goalroom : GRoom) : string;

function findObjectWorld(s : string) : GObject;

procedure initAreas();
procedure cleanupAreas();

implementation

uses
	chars,
	player,
	skills,
	fight,
	console,
	mudsystem,
	conns;


// GNPCIndex
destructor GNPCIndex.Destroy;
begin
  if (prog <> nil) then
    prog.Free;

  inherited Destroy;
end;

// GArea
constructor GArea.Create;
begin
  inherited Create;

  resets := GDLinkedList.Create;

  m_lo := high(integer);
  m_hi := -1;
  r_lo := high(integer);
  r_hi := -1;
  o_lo := high(integer);
  o_hi := -1;

  _author := 'No author';
  _resetmsg := 'No reset';
  _name := 'New area';

  _maxage := 10;
  _age := 0;
  flags := GBitVector.Create(0);

  with weather do
    begin
    mmhg := 1000;
    sky := SKY_CLOUDLESS;
    change := 0;
    temp := 20;
    temp_avg := 20;
    temp_mult := 5;
    end;

  area_list.insertLast(Self);
end;

destructor GArea.Destroy;
begin
  resets.clean;
  resets.Free;

  inherited Destroy;
end;

procedure GArea.areaBug(func : string; problem : string);
begin
  bugreport(func, 'area.pas', fname + ': ' + problem + ', line ' + inttostr(af.line));
end;

procedure GArea.loadRooms;
var s : string;
    vnum : integer;
    room : GRoom;
    s_exit : GExit;
    s_extra : GExtraDescription;
    buf : string;
    fnd : boolean;
    node : GListNode;
begin
  vnum := 0;
  repeat
    repeat
      s := af.readLine;
    until pos('#', s) = 1;

    if (uppercase(s) = '#END') then
      exit;

    delete(s, 1, 1);

    try
      vnum := strtoint(left(s, ' '));
    except
      areaBug('rooms_load', 'invalid numeric format ' + s);
      exit;
    end;

    room := GRoom.Create(vnum, Self);

    with room do
      begin
      s := af.readLine;

      if (pos('#', s) = 1) then
        begin
        areaBug('rooms_load', 'unexpected new room');
        exit;
        end;

      if (not found_range) then
        begin
        if (vnum < r_lo) then
          r_lo := vnum;
        if (vnum > area.r_hi) then
          r_hi := vnum;
        end;

      _name := hash_string(s);
      buf := '';

      repeat
        s := af.readLine;

        if (s <> '~') then
          buf := buf + s + #13#10;
      until (s = '~');

      _description := buf;

      flags.value := af.readCardinal;
      _minlevel := af.readInteger;
      _maxlevel := af.readInteger;
      _sector := af.readCardinal;

      if (_maxlevel = 0) then
        _maxlevel := LEVEL_MAX;

      if (flags.isBitSet(ROOM_TELEPORT)) then
        begin
        _televnum := af.readCardinal;
        _teledelay := af.readInteger;
        end;

      while (true) do
        begin
        s := af.readToken;

        if (s = '#END') then
          break;

        case s[1] of
          'S' : break;
          'D' : begin
                s_exit := GExit.Create;
                s_exit.vnum := af.readCardinal;
                s_exit.direction := af.readCardinal;
                s_exit.flags := af.readCardinal;
                s_exit.key := af.readInteger;

                if not (af.feol) then
                  s_exit.keywords := hash_string(af.readLine)
                else
                  s_exit.keywords := hash_string('');

                if (exits.head = nil) then
                  exits.insertLast(s_exit)
                else
                  begin
                  fnd := false;
                  node := exits.head;

                  while (node <> nil) do
                    begin
                    if (s_exit.direction < GExit(node.element).direction) then
                      begin
                      fnd := true;
                      break;
                      end;

                    node := node.next;
                    end;

                  if (fnd) and (node <> nil) then
                    exits.insertBefore(node, s_exit)
                  else
                    exits.insertLast(s_exit);
                  end;
                end;
          'E' : begin
                s_extra := GExtraDescription.Create;

                s_extra.keywords := af.readLine;
                s_extra.description := '';

                repeat
                  s := trim(af.readLine);

                  if (s <> '~') then
                    s_extra.description := s_extra.description + s + #13#10;
                until (s = '~');

                extra.insertLast(s_extra);
                end;
          end;
        end;
      end;

    room_list.put(vnum, room);
  until (uppercase(s) = '#END');
end;

procedure GArea.loadNPCs;
var 
	s:string;
	num:integer;
	sk : GSkill;
	npc : GNPCIndex;
	g : GLearned;
//    prog : GProgram;
//    progfile : string;
begin
  npc := nil;
  s := af.readLine;

  repeat
    while (pos('#',s) = 0) do
      s := af.readLine;

    if (uppercase(s)='#END') then
      exit;

    delete(s,1,1);

    try
      num := strtoint(s);

      npc := GNPCIndex.Create;

      npc.prog := nil;
      npc.area := Self;
      npc.skills_learned := GDLinkedList.Create;

      with npc do
        begin
        vnum := num;

        if (not found_range) then
          begin
          if (vnum < area.m_lo) then
            area.m_lo := vnum;
          if (vnum > area.m_hi) then
            area.m_hi := vnum;
          end;

        name := hash_string(af.readLine);
        short := hash_string(af.readLine);
        long := hash_string(af.readLine);

        level := af.readCardinal;

        mv := 500;
        
        str := UMin(65 + random(level div 50), 100);
        con := UMin(65 + random(level div 51), 100);
        dex := UMin(65 + random(level div 52), 100);
        int := UMin(65 + random(level div 53), 100);
        wis := UMin(65 + random(level div 54), 100);

        hitroll := UMin((level div 5) + 50, 100);

        hp := (level + 1) * ((con div 4) + random(6) - 3);

        damsizedie:=round(sqrt(level));
        damnumdie:=round(sqrt(level));

        sex := af.readInteger;

        if (not af.feol) then
          begin
          s := af.readToken();

          clan := findClan(s);
          end;

        natural_ac := af.readInteger;
        act_flags := af.readCardinal;
        gold := af.readInteger;
        height := af.readInteger;
        weight := af.readInteger;

        s := af.readLine;

        while (pos('>', s) <> 0) or (pos('skill:', s) <> 0) do
          begin
          if (pos('>', s) <> 0) then
            begin
            progfile := 'progs' + PathDelimiter + right(s, ' ');
            prog := loadCode(progfile);
            if (prog = nil) then
              areaBug('loadNPCs', 'error loading ''' + progfile + '''; file doesn''t exist?');
            end
          else
            begin
            s := right(s,' ');
            sk := findSkill(s);

            if (sk <> nil) then
            	begin
            	g := GLearned.Create(100, sk);
              g.node := skills_learned.insertLast(g);
              end
            else
              areaBug('loadNPCs', 'unknown skill '+s);
            end;

          s := af.readLine;
          end;

        race := GRace(raceList.head.element);

        count := 0;

        npc_list.insertLast(npc);
        end;
      except
        areaBug('GArea.loadMobiles', 'Exception while loading mobile section, please check your area');
        npc.Free;
      end;
  until (uppercase(s) = '#END');
end;

procedure GArea.loadObjects;
var 
  s:string;
  modif, num:integer;
  obj : GObject;
  aff : GAffect;
begin
  num:=0;
  s := af.readLine;

  repeat
    if (uppercase(s) = '#END') then
      exit;

    try
      num:=StrToInt(right(s,'#'));
    except
      areaBug('load_objects','illegal numeric format '+s);
      exit;
    end;

    if (objectIndices[num] <> nil) then
      begin
      areaBug('load_objects','vnum conflict ('+inttostr(num)+')');
      exit;
      end;

    obj := GObject.Create();
    obj.area := Self;

    with obj do
      begin
      name := af.readLine();
      short := af.readLine();
      long := af.readLine();
      
      vnum:=num;

      if (not found_range) then
        begin
        if (vnum < area.o_lo) then
          area.o_lo := vnum;
        if (vnum > area.o_hi) then
          area.o_hi := vnum;
        end;

      item_type := af.readInteger;

      wear_location1 := af.readToken;
      wear_location2 := af.readToken;
      
      if (IntToStr(StrToIntDef(wear_location1, 0)) = wear_location1) then
      	writeConsole('hint on line ' + IntToStr(af.line) + ': wear_location1 no longer numeric (now ' + wear_location1 + ')');
      	
      if (IntToStr(StrToIntDef(wear_location2, 0)) = wear_location2) then
      	writeConsole('hint on line ' + IntToStr(af.line) + ': wear_location2 no longer numeric (now ' + wear_location2 + ')');
      
      if (wear_location1 = 'none') then
        wear_location1 := '';

      if (wear_location2 = 'none') then
        wear_location2 := '';

      value[1] := af.readInteger;
      value[2] := af.readInteger;
      value[3] := af.readInteger;
      value[4] := af.readInteger;

      case item_type of
        // if initial condition is set use that, else use max. condition
        ITEM_FOOD : if (value[1] > 0) then
                      timer := value[1]
                    else
                      timer := value[3];
        else
          timer := 0;
      end;

      weight := af.readInteger();
      flags := af.readCardinal();
      cost := af.readInteger();

      s := af.readToken();

      if (s = 'A') then
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

          s := af.readToken();

          modif := cardinal(findSkill(s));

          if (modif = 0) then
            modif := strtointdef(s, 0);

          aff.modifiers[num - 1].modifier := modif;

          s := af.readToken();

          inc(num);
          end;

        aff.node := affects.insertLast(aff);

        s := af.readLine;
        end;
      end;

    objectIndices[obj.vnum] := obj;
  until (uppercase(s) = '#END');
end;

procedure GArea.loadResets;
var g : GReset;
    d, s : string;
begin
  repeat
    s := af.readLine;

    if (uppercase(s) <> '#END') then
      begin
      g := GReset.Create;
      g.area := Self;

      with g do
        begin
        d := left(s,':');
        reset_type := d[1];

        s := right(s,' ');
        arg1 := strtoint(left(s,' '));
        s := right(s,' ');
        arg2 := strtoint(left(s,' '));
        s := right(s,' ');
        arg3 := strtoint(left(s,' '));

        if (reset_type = 'M') then
          begin
          if (findNPCIndex(arg1) = nil) then
            begin
            areaBug('GArea.loadResets', 'npc reset ' + inttostr(arg1) + ' null');
            g.Free;
            end
          else
            resets.insertLast(g);
          end
        else
        if (reset_type = 'O') then
          begin
          if (objectIndices[arg1] = nil) then
            begin
            areaBug('GArea.loadResets', 'obj reset ' + inttostr(arg1) + ' null');
            g.Free;
            end
          else
            resets.insertLast(g);
          end
        else
        if (reset_type = 'E') then
          begin
          if (objectIndices[arg1] = nil) then
            begin
            areaBug('GArea.loadResets', 'equip reset ' + inttostr(arg1) + ' null');
            g.Free;
            end
          else
            resets.insertLast(g);
          end
        else
        if (reset_type = 'I') then
          begin
          if (objectIndices[arg1] = nil) then
            begin
            areaBug('GArea.loadResets', 'insert reset ' + inttostr(arg1) + ' null');
            g.Free;
            end
          else
            resets.insertLast(g);
          end
        else
        if (reset_type = 'G') then
          begin
          if (objectIndices[arg1] = nil) then
            begin
            areaBug('GArea.loadResets', 'give reset ' + inttostr(arg1) + ' null');
            g.Free;
            end
          else
            resets.insertLast(g);
          end
        else
        if (reset_type = 'D') then
          resets.insertLast(g);
        end;
      end;
  until (uppercase(s) = '#END');
end;

procedure GArea.loadShops;
var
   shop : GShop;
   npc : GNPCIndex;
   s : string;
begin
  repeat
    s := af.readLine;

    if (uppercase(s) <> '#END') then
      begin
      shop := GShop.Create;
      shop.area := Self;
      shop.keeper := strtoint(left(s,' '));

      npc := findNPCIndex(shop.keeper);

      if (npc = nil) then
        areaBug('GArea.loadShops', 'shopkeeper '+inttostr(shop.keeper)+' null')
      else
        npc.shop := shop;

      s := af.readLine;

      shop.item_buy[1]:=strtoint(left(s,' '));

      s:=right(s,' ');
      shop.item_buy[2]:=strtoint(left(s,' '));

      s:=right(s,' ');
      shop.item_buy[3]:=strtoint(left(s,' '));

      s:=right(s,' ');
      shop.item_buy[4]:=strtoint(left(s,' '));

      s:=right(s,' ');
      shop.item_buy[5]:=strtoint(left(s,' '));

      s := af.readLine;
      shop.open_hour:=strtoint(left(s,' '));

      s:=right(s,' ');
      shop.close_hour:=strtoint(left(s,' '));

      repeat
        s := af.readLine;
      until s='~';

      shop.node := shop_list.insertLast(shop);
      end;
  until (uppercase(s) = '#END');
end;

procedure GArea.load(fn : string);
var s : string;
begin
  try
    af := GFileReader.Create('areas\' + fn);
  except
    exit;
  end;

  fname := fn;
  found_range := false;

  repeat
    s := af.readLine;
    s := uppercase(s);

    if (s = '#AREA') then
      begin
      _name := af.readLine;
      _author := af.readLine;
      _resetmsg := af.readLine;
      _maxage := af.readInteger;

      with weather do
        begin
        temp_mult := af.readInteger;
        temp_avg := af.readInteger;
        end;

      flags.value := af.readCardinal;
      _age := 0;
      end
    else
    if (s = '#RANGES') then
      begin
      found_range := true;

      r_lo := af.readInteger;
      r_hi := af.readInteger;
      m_lo := af.readInteger;
      m_hi := af.readInteger;
      o_lo := af.readInteger;
      o_hi := af.readInteger;
      end
    else
    if (s = '#ROOMS') then
      loadRooms()
    else
    if (s = '#MOBILES') then
      loadNPCs()
    else
    if (s = '#OBJECTS') then
      loadObjects()
    else
    if (s = '#RESETS') then
      loadResets()
    else
    if (s = '#SHOPS') then
      loadShops();
  until (s = '$') or (af.eof());

  af.Free;
end;

procedure loadAreas();
var
  af : GFileReader;
  to_room, room : GRoom;
  pexit : GExit;
  s : string;
  area : GArea;
  iterator : GIterator;
  node_exit : GListNode;
  tm : TDateTime;
begin
  tm := Now();

  try
    af := GFileReader.Create('areas\area.list');
  except
  	exit;
  end;

  repeat
    s := af.readLine();

    if (s <> '$') then
      begin
      area := GArea.Create;
      area.load(trim(s));

      s := pad_string(area.fname, 15);

      with area do
        begin
        if (r_lo <> high(integer)) and (r_hi<>-1) then
          s:=s+' R '+pad_integer(r_lo,5)+'-'+pad_integer(r_hi,5);
        if (m_lo <> high(integer)) and (m_hi<>-1) then
          s:=s+' M '+pad_integer(m_lo,5)+'-'+pad_integer(m_hi,5);
        if (o_lo <> high(integer)) and (o_hi<>-1) then
          s:=s+' O '+pad_integer(o_lo,5)+'-'+pad_integer(o_hi,5);
        end;

      writeConsole(s);
      end;
  until (s = '$');

  af.Free();

  writeConsole('Checking exits...');

  { Checking rooms for errors }

	iterator := room_list.iterator();
	
	while (iterator.hasNext()) do
		begin
		room := GRoom(iterator.next());

		node_exit := room.exits.head;

		while (node_exit <> nil) do
			begin
			pexit := GExit(node_exit.element);

			to_room := findRoom(pexit.vnum);

			if not (pexit.direction in [DIR_NORTH..DIR_SOMEWHERE]) then
				begin
				bugreport('loadAreas()', 'area.pas', 'illegal direction ' + IntToStr(pexit.direction) +
									' for exit in room #' + IntToStr(room.vnum));

				room.exits.remove(node_exit);

				node_exit := room.exits.head;
				end
			else
			if (to_room = room) then
				begin
				bugreport('loadAreas()', 'area.pas', 'cyclic exit ' + headings[pexit.direction] + ' found in room #' + IntToStr(room.vnum));

				room.exits.remove(node_exit);

				node_exit := room.exits.head;
				end
			else
			if (to_room = nil) then
				begin
				bugreport('loadAreas()', 'area.pas', 'exit ' + headings[pexit.direction] +
									' from room #' + IntToStr(room.vnum) + ' to unexisting room # '+ IntToStr(pexit.vnum));

				room.exits.remove(node_exit);

				node_exit := room.exits.head;
				end
			else
				begin
				pexit.to_room:=to_room;

				node_exit := node_exit.next;
				end;
			end;
		end;
		
	iterator.Free();

  { reset the areas }
  iterator := area_list.iterator();

  while (iterator.hasNext()) do
    GArea(iterator.next()).reset();

	iterator.Free();
	
  tm := Now() - tm;

  writeConsole('Area loading took ' + FormatDateTime('s "second(s)," z "millisecond(s)"', tm));
end;

{ Xenon 28/Apr/2001 : added saving of #RANGES; fixed bug that caused areas
                      not to save (and their length set to 0) }
procedure GArea.save(fn : string);
var
   f : textfile;
   g : GLearned;
   node_ex : GListNode;
   ex : GExit;
   extra : GExtraDescription;
   room : GRoom;
   npcindex : GNPCIndex;
   reset : GReset;
   iterator : GIterator;
   shop : GShop;
   obj : GObject;
begin
  assign(f, 'areas\' + fn);
  {$I-}
  rewrite(f);
  {$I+}

  if (IOResult <> 0) then
    begin
    bugreport('GArea.save', 'area.pas', 'Could not open ' + fn + '!');
    exit;
    end;

  writeln(f, '#RANGES');
  writeln(f, Format('%d %d %d %d %d %d', [r_lo, r_hi, m_lo, m_hi, o_lo, o_hi]));
  writeln(f);
  
  writeln(f, '#AREA');
  writeln(f, Self.name);
  writeln(f, Self.author);
  writeln(f, Self.resetmsg);
  writeln(f, Self.maxage);
  writeln(f, Self.weather.temp_mult, ' ', Self.weather.temp_avg, ' ', Self.flags.value);
  writeln(f);
  writeln(f, '#ROOMS');
  
  iterator := room_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    room := GRoom(iterator.next());

    if (room.area <> Self) then
      continue;

    writeln(f, '#', room.vnum);
    writeln(f, room.name);
    write(f, room.description);
    writeln(f, '~');

    write(f, room.flags.value, ' ', room.minlevel, ' ', room.maxlevel, ' ', room.sector);

    if (room.flags.isBitSet(ROOM_TELEPORT)) then
      writeln(f, ' ', room.televnum, ' ', room.teledelay)
    else
      writeln(f);

    node_ex := room.exits.head;
    while (node_ex <> nil) do
      begin
      ex := GExit(node_ex.element);

      write(f, 'D ', ex.vnum, ' ', ex.direction, ' ', ex.flags, ' ', ex.key);

      if (ex.keywords <> nil) and (length(ex.keywords^) > 0) then
        writeln(f, ' ', ex.keywords^)
      else
        writeln(f);

      node_ex := node_ex.next;
      end;

    node_ex := room.extra.head;
    while (node_ex <> nil) do
      begin
      extra := GExtraDescription(node_ex.element);

      writeln(f, 'E ', extra.keywords);
      write(f, extra.description);
      writeln(f, '~');

      node_ex := node_ex.next;
      end;

    writeln(f, 'S');
    end;
    
  iterator.Free();

  writeln(f, '#END');
  writeln(f);
  
  writeln(f, '#MOBILES');

  iterator := npc_list.iterator();
  while (iterator.hasNext()) do
    begin
    npcindex := GNPCIndex(iterator.next());

    if (npcindex.area <> Self) then
      continue;

    writeln(f, '#', npcindex.vnum);

    writeln(f, npcindex.name^);
    writeln(f, npcindex.short^);
    writeln(f, npcindex.long^);

    write(f, npcindex.level, ' ', npcindex.sex);

    if (npcindex.clan <> nil) then
      writeln(f, '''' + npcindex.clan.name + '''')
    else
      writeln(f);

    writeln(f, npcindex.natural_ac, ' ', npcindex.act_flags, ' ', npcindex.gold, ' ', npcindex.height, ' ', npcindex.weight);

{    node_ex := npcindex.programs.head;
    while (node_ex <> nil) do
      begin
      prog := node_ex.element;

      case prog.prog_type of
             MPROG_ACT : write(f, '> on_act ');
           MPROG_GREET : write(f, '> on_greet ');
        MPROG_ALLGREET : write(f, '> on_allgreet ');
           MPROG_ENTER : write(f, '> on_enter ');
           MPROG_DEATH : write(f, '> on_death ');
           MPROG_BRIBE : write(f, '> on_bribe ');
           MPROG_FIGHT : write(f, '> on_fight ');
            MPROG_RAND : write(f, '> on_rand ');
           MPROG_BLOCK : write(f, '> on_block ');
           MPROG_RESET : write(f, '> on_reset ');
           MPROG_GIVE  : write(f, '> on_give ');
      end;

      writeln(f, prog.args);

      write(f, prog.code);
      writeln(f,'~');

      node_ex := node_ex.next;
      end; }

    node_ex := npcindex.skills_learned.head;;
    while (node_ex <> nil) do
      begin
      g := GLearned(node_ex.element);

      writeln(f, 'Skill: ''', GSkill(g.skill).name, ''' ', g.perc);

      node_ex := node_ex.next;
      end;
      
    if (npcindex.progfile <> '') then
    	writeln(f, '>', right(npcindex.progfile, PathDelimiter));
    end;
  iterator.Free();

  writeln(f, '#END');
  writeln(f);
  writeln(f, '#OBJECTS');

  iterator := objectIndices.iterator();
  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (obj.area <> Self) then
      continue;

    writeln(f, '#',obj.vnum);
    writeln(f, obj.name);
    writeln(f, obj.short);
    writeln(f, obj.long);
    writeln(f, obj.item_type,' ',obj.wear_location1,' ',obj.wear_location2);
    writeln(f, obj.value[1],' ',obj.value[2],' ',obj.value[3],' ',obj.value[4]);
    writeln(f, obj.weight,' ',obj.flags,' ',obj.cost);
    end;
  iterator.Free();

  writeln(f, '#END');
  writeln(f);
  writeln(f, '#RESETS');

  iterator := Self.resets.iterator();
  while (iterator.hasNext()) do
    begin
    reset := GReset(iterator.next());

    writeln(f, reset.reset_type, ' ', reset.arg1, ' ', reset.arg2, ' ', reset.arg3);
    end;
  iterator.Free();

  writeln(f, '#END');
  writeln(f);
  writeln(f, '#SHOPS');

  iterator := shop_list.iterator();
  while (iterator.hasNext()) do
    begin
    shop := GShop(iterator.next());

    if (shop.area <> Self) then
      continue;

    writeln(f, shop.keeper);
    writeln(f, shop.item_buy[1],' ',shop.item_buy[2],' ',
               shop.item_buy[3],' ',shop.item_buy[4],' ',shop.item_buy[5]);
    writeln(f, shop.open_hour,' ',shop.close_hour);
    writeln(f, '~');
    end;
  iterator.Free();

  writeln(f, '#END');
  writeln(f);
  writeln(f, '$');

  closefile(f);
end;

{jago - utility func, move to area.pas}
function instanceNPC(npcindex : GNPCIndex) : pointer;
var
  npc : GNPC;
begin
  // note : this func doesnt check
  // npcindex.count + 1 < reset.max
  // this is so imms can mload more npcs than the reset maximum

  // this func does not place the npc in a room, the calling func is
  // responsible for that

  if (npcindex = nil) then
    begin
    bugreport('instanceNPC', 'area.pas', 'npc_index null');
    Result := nil;
    exit;
    end;

  npc := GNPC.Create;
  npc.context := GContext.Create;
  npc.context.load(npcindex.prog);
  npc.context.owner := npc;

  with npc do
    begin
    str := npcindex.str;
    con := npcindex.con;
    dex := npcindex.dex;
    int := npcindex.int;
    wis := npcindex.wis;
    hp:=npcindex.hp;
    max_hp:=npcindex.hp;
    mv:=npcindex.mv;
    max_mv:=npcindex.mv;
    mana:=npcindex.mana;
    max_mana:=npcindex.mana;
    natural_ac:=npcindex.natural_ac;
    ac_mod:=0;
    hitroll:=npcindex.hitroll;

    damnumdie:=npcindex.damnumdie;
    damsizedie:=npcindex.damsizedie;
    apb:=npcindex.apb;
    skills_learned := npcindex.skills_learned;
    clan:=npcindex.clan;
    npc.room := nil;
    position := POS_STANDING;
    state := STATE_IDLE;
    npc.npc_index := npcindex;

	  name := npcindex.name^;
    short := npcindex.short^;
    long := npcindex.long^;

    sex := npcindex.sex;
    race := npcindex.race;
    alignment := npcindex.alignment;
    level := npcindex.level;
    weight := npcindex.weight;
    height := npcindex.height;
    act_flags := npcindex.act_flags;
    end;

  inc(npcindex.count);
  npc.node_world := char_list.insertLast(npc);

  npc.calcAC;

  Result := npc;
end;

procedure GArea.reset;
var 
	reset : GReset;
	npc, lastmob : GNPC;
	vict : GCharacter;
	obj, lastobj, tempobj : GObject;
	npcindex : GNPCIndex;
	room : GRoom;
	pexit : GExit;
	conn : GPlayerConnection;
	node_reset : GListNode;
	iterator : GIterator;
	buf : string;
	p : integer;
begin
  lastobj := nil;
  lastmob := nil;

	iterator := connection_list.iterator();
	
  while (iterator.hasNext()) do
    begin
    conn := GPlayerConnection(iterator.next());

    if (conn.state=CON_PLAYING) and (conn.ch.room.area = Self) then
      begin
      buf := conn.ch.ansiColor(AT_REPORT) + resetmsg + #13#10;
      conn.ch.sendBuffer(buf);
      end;
    end;
    
  iterator.Free();

  node_reset := resets.head;
  while (node_reset <> nil) do
    begin
    reset := GReset(node_reset.element);

    case reset.reset_type of
      'M':begin
          npcindex := findNPCIndex(reset.arg1);

          if (npcindex = nil) then
            bugreport('GArea.reset (M) area: ' + name, 'area.pas', 'npc #' + IntToStr(reset.arg1) + ' null')
          else
            begin
            lastmob := nil;

            if (npcindex.count < reset.arg3) then
              begin
              npc := instanceNPC(npcindex);
              npc.room := findRoom(reset.arg2);

              if (npc.room = nil) then
                begin
                bugreport('GArea.reset (M) area: ' + name, 'area.pas', 'room #' + IntToStr(reset.arg2) + ' null');

                npc.extract(true);
                end
              else
                begin
                npc.calcAC;

                npc.toRoom(npc.room);
                lastmob := npc;
                inc(mobs_loaded);

                p := npc.context.findSymbol('onReset');

                if (p <> -1) then
                  begin
                  npc.context.push(integer(npc));
                  npc.context.setEntryPoint(p);
                  npc.context.Execute;
                  end;
                end;
              end;
            end;
          end;
      'E':begin
          npc:=nil;

          if (reset.arg3<>0) then
            begin
            iterator := char_list.iterator();

            while (iterator.hasNext()) do
              begin
              vict := GCharacter(iterator.next());

              if (vict.IS_NPC) and (GNPC(vict).npc_index.vnum = reset.arg3) then
                begin
                npc := GNPC(vict);
                break;
                end;
              end;
              
            iterator.Free();

            if (npc = nil) then
              begin
              bugreport('GArea.reset (E) area: ' + name, 'area.pas', '(' + IntToStr(reset.arg1) + ') npc #' + IntToStr(reset.arg3) + ' null');
              node_reset := node_reset.next;
              continue;
              end;
            end
          else
            npc := lastmob;

          if lastmob=nil then
            begin
            node_reset := node_reset.next;
            continue;
            end;

          if (npc = nil) then
            bugreport('GArea.reset (E) area: ' + name, 'area.pas', '(' + IntToStr(reset.arg1) + ') npc #' + IntToStr(reset.arg3) + ' null')
          else
          if (number_percent <= reset.arg2) then
            begin
            tempobj := GObject(objectIndices[reset.arg1]);
            
            if (tempobj <> nil) then
              begin
              obj := tempobj.clone();

	            obj.toChar(npc);
	            npc.equip(obj);

	            lastobj := obj;
	            end
	          else
              bugreport('GArea.reset (E) area: ' + name, 'area.pas', 'obj #' + IntToStr(reset.arg1) + ' null');
            end;
          end;
      'G':begin
          npc := nil;

          if (reset.arg3 <> 0) then
            begin
            iterator := char_list.iterator();

            while (iterator.hasNext()) do
              begin
              vict := GCharacter(iterator.next());

              if (vict.IS_NPC) and (GNPC(vict).npc_index.vnum = reset.arg3) then
                begin
                npc := GNPC(vict);
                break;
                end;
              end;
              
            iterator.Free();

            if (npc = nil) then
              begin
              bugreport('GArea.reset (G) area: ' + name, 'area.pas', '(' + IntToStr(reset.arg1) + ') npc #' + IntToStr(reset.arg3) + ' null');
              node_reset := node_reset.next;
              continue;
              end;
            end
          else
            npc := lastmob;

          if lastmob=nil then
            begin
            node_reset := node_reset.next;
            continue;
            end;

					tempobj := GObject(objectIndices[reset.arg1]);
					
					if (tempobj <> nil) then
					  begin
            obj := tempobj.clone();
            obj.toChar(npc);

            lastobj := obj;
					  end
					else
            bugreport('GArea.reset (G) area: ' + name, 'area.pas', 'obj #' + IntToStr(reset.arg1) + ' null');
          end;
      'O':begin
          tempobj := GObject(objectIndices[reset.arg1]);
          
          if (tempobj = nil) then
            bugreport('GArea.reset (O) area: ' + name, 'area.pas', 'obj #' + IntToStr(reset.arg1) + ' null')
          else
          if (tempobj.area.nplayer = 0) and (reset.arg3 > tempobj.child_count) then
            begin
            obj := tempobj.clone();
            obj.toRoom(findRoom(reset.arg2));

            lastobj := obj;
            end;
          end;
      'I':begin
          tempobj := GObject(objectIndices[reset.arg1]);

          if (lastobj = nil) then
            begin
            node_reset := node_reset.next;
            continue;
            end;

          if (tempobj = nil) then
            bugreport('GArea.reset (I) area: ' + name, 'area.pas', 'obj #' + IntToStr(reset.arg1) + ' null')
          else
          if (tempobj.area.nplayer = 0) and (reset.arg3 > tempobj.child_count) then
            begin
            obj := tempobj.clone();
            obj.toObject(lastobj);
            end;
          end;
      'D':begin
          room := findRoom(reset.arg1);

          if (room = nil) then
            begin
            bugreport('GArea.reset (D) area: ' + name, 'area.pas', 'room #' + IntToStr(reset.arg1) + ' null');
	    node_reset := node_reset.next;
            continue;
            end;

          pexit := room.findExit(reset.arg2);

          if (pexit = nil) then
            begin
            bugreport('GArea.reset (D) area: ' + name, 'area.pas', 'direction ' + IntToStr(reset.arg2) + ' has no exit in room ' + IntToStr(reset.arg1));
            node_reset := node_reset.next;
            continue;
            end;

          // Added reverse exits - Nemesis
          case reset.arg3 of
          // open door
            0 : begin
                REMOVE_BIT(pexit.flags, EX_LOCKED);
                REMOVE_BIT(pexit.flags, EX_CLOSED);

                // reverse exit
                room := findRoom(pexit.vnum);
                pexit := room.findExit(dir_inv[reset.arg2]);

                REMOVE_BIT(pexit.flags, EX_LOCKED);
                REMOVE_BIT(pexit.flags, EX_CLOSED);
                end;
          // closed door
            1 : begin
                REMOVE_BIT(pexit.flags, EX_LOCKED);
                SET_BIT(pexit.flags, EX_CLOSED);

                // reverse exit
                room := findRoom(pexit.vnum);
                pexit := room.findExit(dir_inv[reset.arg2]);

                REMOVE_BIT(pexit.flags, EX_LOCKED);
                SET_BIT(pexit.flags, EX_CLOSED);
                end;
          // closed secret door
            2 : begin
                REMOVE_BIT(pexit.flags, EX_LOCKED);
                SET_BIT(pexit.flags, EX_CLOSED);
                SET_BIT(pexit.flags, EX_SECRET);

                // reverse exit
                room := findRoom(pexit.vnum);
                pexit := room.findExit(dir_inv[reset.arg2]);

                REMOVE_BIT(pexit.flags, EX_LOCKED);
                SET_BIT(pexit.flags, EX_CLOSED);
                SET_BIT(pexit.flags, EX_SECRET);
                end;
          // locked door
            3 : begin
                SET_BIT(pexit.flags, EX_LOCKED);
                SET_BIT(pexit.flags, EX_CLOSED);

                // reverse exit
                room := findRoom(pexit.vnum);
                pexit := room.findExit(dir_inv[reset.arg2]);

                SET_BIT(pexit.flags, EX_LOCKED);
                SET_BIT(pexit.flags, EX_CLOSED);
                end;
          // locked secret door
            4 : begin
                SET_BIT(pexit.flags, EX_LOCKED);
                SET_BIT(pexit.flags, EX_CLOSED);
                SET_BIT(pexit.flags, EX_SECRET);

                // reverse exit
                room := findRoom(pexit.vnum);
                pexit := room.findExit(dir_inv[reset.arg2]);

                SET_BIT(pexit.flags, EX_LOCKED);
                SET_BIT(pexit.flags, EX_CLOSED);
                SET_BIT(pexit.flags, EX_SECRET);
                end;
          end;
          end;
    end;

    node_reset := node_reset.next;
    end;

  _age := 0;
end;

procedure GArea.update;
var 
	buf : string;
	diff:integer;
	conn : GPlayerConnection;
	iterator : GIterator;
begin
  inc(_age);

  if (_age >= _maxage) then
    begin
    writeConsole('Resetting ' + fname + '...');

    reset();
    end;

  { weather routine, adapted from Smaug code - Grimlord }
  { put into local mode, different weather for different areas }

  buf := '';

  if (time_info.month >= 9) and (time_info.month <= 16) then
    begin
    if (weather.mmhg > 985) then
      diff := -2
    else
      diff := 2;
    end
  else
    begin
    if (weather.mmhg > 1015) then
      diff := -2
    else
      diff := 2;
    end;

  inc(weather.change, diff*rolldice(1,4)+rolldice(2,6)-rolldice(2,6));
  weather.change := URange(-12, weather.change, 12);

  weather.mmhg := URANGE(960,weather.mmhg + weather.change,1060);
  weather.temp:=round(sin((time_info.hour-12)*PI/12)*weather.temp_mult)+weather.temp_avg+diff;

  case weather.sky of
    SKY_CLOUDLESS:begin
                  if (weather.mmhg<1000) or
                   ((weather.mmhg<1020) and (random(4)<2)) then
                    begin
                    buf := 'The sky is getting cloudy.';
                    weather.sky:=SKY_CLOUDY;
                    end;
                  end;
       SKY_CLOUDY:begin
                  if (weather.mmhg<980) or
                   ((weather.mmhg<1000) and (random(4)<2)) then
                    begin
                    buf := 'It starts to rain.';
                    weather.sky:=SKY_RAINING;
                    end
                  else
                  if (weather.mmhg>1030) and (random(4)<2) then
                    begin
                    buf := 'The clouds disappear.';
                    weather.sky:=SKY_CLOUDLESS;
                    end;
                  end;
      SKY_RAINING:begin
                  if (weather.mmhg<970) then
                   case random(4) of
                     1:begin
                       buf := 'Lightning flashes in the sky.';
                       weather.sky:=SKY_LIGHTNING;
                       end;
                     2:begin
                       buf := 'Fierce winds start blowing as a storm approaches.';
                       weather.sky:=SKY_STORMING;
                       end;
                   end;
                  if (weather.mmhg>1030) or
                   ((weather.mmhg>1010) and (random(4)<2)) then
                    begin
                    buf := 'The rain stopped.';
                    weather.sky:=SKY_CLOUDY;
                    end
                  else
                  if (weather.temp<0) then
                    begin
                    buf := 'Snowflakes fall on your head.';
                    weather.sky:=SKY_SNOWING;
                    end;
                  end;
      SKY_SNOWING:begin
                  if (weather.mmhg<970) then
                   case random(4) of
                     1:begin
                       buf := 'The sky lights up as lightning protrudes the snow.';
                       weather.sky:=SKY_LIGHTNING;
                       end;
                     2:begin
                       buf := 'A blizzard blows snow in your face.';
                       weather.sky:=SKY_STORMING;
                       end;
                   end;
                  if (weather.mmhg>1030) or
                   ((weather.mmhg>1010) and (random(4)<2)) then
                    begin
                    buf := 'The snowflakes stop falling down';
                    weather.sky:=SKY_CLOUDY;
                    end
                  else
                  if (weather.temp>1) then
                    begin
                    buf := 'The snow turns into wet rain.';
                    weather.sky:=SKY_RAINING;
                    end;
                  end;
    SKY_LIGHTNING:begin
                  if (weather.mmhg>1010) or
                   ((weather.mmhg>990) and (random(4)<2)) then
                    begin
                    buf := 'The lightning has stopped.';
                    weather.sky:=SKY_RAINING;
                    end;
                  end;
     SKY_STORMING:begin
                  if (weather.mmhg>1010) or
                   ((weather.mmhg>990) and (random(4)<2)) then
                    begin
                    buf := 'The winds subside.';
                    weather.sky:=SKY_CLOUDY;
                    end;
                  end;
   else
     begin
     bugreport('GArea.update', 'update.pas', 'bad sky identifier');
     weather.sky := SKY_CLOUDLESS;
     end;
  end;

  if (weather.temp<1) then
    begin
    if (length(buf) > 0) then
      buf := buf + #13#10;

    buf := buf + 'Brrr... it is very cold...';
    end
  else
  if (weather.temp>28) and (weather.temp<35) then
    begin
    if (length(buf) > 0) then
      buf := buf + #13#10;

    buf := buf + 'It is quite hot!';
    end
  else
  if (weather.temp>=35) then
    begin
    if (length(buf) > 0) then
      buf := buf + #13#10;

    buf := buf + 'It is VERY hot!';
    end;

  iterator := connection_list.iterator();

  while (iterator.hasNext()) do
    begin
    conn := GPlayerConnection(iterator.next());
    
    if (conn.state = CON_PLAYING) and (conn.ch.room.area = Self) and (conn.ch.IS_OUTSIDE) then
      begin
      if (length(buf) > 0) and (conn.ch.IS_AWAKE) then
        act(AT_REPORT,buf,false,conn.ch,nil,nil,TO_CHAR);

      case weather.sky of
(*        SKY_RAINING:if not IS_SET(conn.ch.aff_flags,AFF_COLD) then
                     if number_percent<=5 then
                      if not saving_throw(0,conn.ch.point.save_cold,conn.ch) then
                       begin
                       act(AT_REPORT,'You begin to sneeze... WWWWAAAAATTTCHA!',false,conn.ch,nil,nil,TO_CHAR);
                       act(AT_REPORT,'WWWWWAAAAAAAAAAAAAAAAAAATCHAAAAAAA!!!!! $n sneezes loudly.',false,conn.ch,nil,nil,TO_ROOM);
                       add_affect(conn.ch,skill_table[gsn_cold].affect);
                       end; *)
      SKY_LIGHTNING:if number_percent<=5 then
                      begin
                      act(AT_REPORT,'ZAP! A lightning bolt hits you!',false,conn.ch,nil,nil,TO_CHAR);
                      act(AT_REPORT,'$n''s hairs are scorched as a lightning bolt hits $m.',false,conn.ch,nil,nil,TO_ROOM);
                      damage(conn.ch,conn.ch,25,TYPE_SILENT);
                      end;
      end;
      end;
    end;
  
  iterator.Free();
end;

{ Xenon 28/Apr/2001: moved createRoom() from cmd_build.inc to area.pas }
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

{ 24/02/2001 - Nemesis }
function findArea(fname : string) : GArea;
var node : GListNode;
    area : GArea;
begin
  findArea := nil;

  node := area_list.head;

  while (node <> nil) do
    begin
    area := GArea(node.element);

    if (area.fname = fname) then
      begin
      findArea := area;
      exit;
      end;

    node := node.next;
    end;
end;

constructor GCoords.Create();
begin
  inherited Create();
  
  x := 0;
  y := 0;
  z := 0;
end;

constructor GCoords.Create(coords : GCoords);
begin
  inherited Create();
  
  copyFrom(coords);
end;

function GCoords.toString() : string;
begin
  Result := '(' + IntToStr(x) + ',' + IntToStr(y) + ',' + IntToStr(z) + ')';
end;

procedure GCoords.copyTo(coords : GCoords);
begin
  coords.x := x;
  coords.y := y;
  coords.z := z;
end;

procedure GCoords.copyFrom(coords : GCoords);
begin
  x := coords.x;
  y := coords.y;
  z := coords.z;
end;

// GRoom
constructor GRoom.Create(vn : integer; ar : GArea);
begin
  inherited Create;

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

  extra.clean;
  exits.clean;
  chars.clean;
  objects.clean;
  tracks.clean;

  extra.Free;
  exits.Free;
  chars.Free;
  objects.Free;
  tracks.Free;

  inherited Destroy;
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

function GRoom.findChar(c : pointer; name : string) : pointer;
var
	iterator : GIterator;
	num, cnt : integer;
	ch, vict : GCharacter;
begin
  findChar := nil;
  ch := c;

  num := findnumber(name);

  name := uppercase(name);
  cnt := 0;

  if (uppercase(name) = 'SELF') then
    begin
    findChar := ch;
    exit;
    end;

  iterator := chars.iterator();
  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (((name = 'GOOD') and (not vict.IS_NPC) and (vict.IS_GOOD)) or
      ((name = 'EVIL') and (not vict.IS_NPC) and (vict.IS_EVIL)) or
      isName(vict.name, name) or isName(vict.short, name) or
      ((not vict.IS_NPC) and (not ch.IS_SAME_ALIGN(vict)) and
      (isName(vict.race.name, name)))) and (ch.CAN_SEE(vict)) then
      begin
      inc(cnt);

      if (cnt = num) then
        begin
        findChar := vict;
        exit;
        end;
      end;
    end;
  iterator.Free();
end;

function GRoom.findRandomChar() : pointer;
var a, num : integer;
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

function GRoom.findObject(name : string) : pointer;
var
	iterator : GIterator;
	obj : GObject;
	num, cnt : integer;
begin
  iterator := objects.iterator();
  num := findNumber(name);
  Result := nil;
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

function GRoom.findDescription(keyword : string) : GExtraDescription;
var
	iterator : GIterator;
	s_extra : GExtraDescription;
	s, p : integer;
	sub, key : string;
begin
  Result := nil;
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

function GRoom.findExitKeyword(s : string) : GExit;
var
	iterator : GIterator;
	pexit : GExit;
begin
  Result := nil;
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


// GObject
constructor GObject.Create();
begin
  inherited Create;
  
  _name := nil;
  _short := nil;
  _long := nil;

  worn := '';
  wear_location1 := '';
  wear_location2 := '';
  contents := GDLinkedList.Create();
  affects := GDLinkedList.Create();
  child_count := 0;
  count := 1;
end;

destructor GObject.Destroy();
var 
  obj_in : GObject;
begin
  objectList.remove(node_world);
  node_world := nil;

  while (contents.tail <> nil) do
    begin
    obj_in := GObject(contents.tail.element);

    obj_in.Free();
    end;

  if (room <> nil) then
    fromRoom();

  if (carried_by <> nil) then
    fromChar();

  if (in_obj <> nil) then
    fromObject();

  obj_in := GObject(objectIndices[vnum]);
  
  if (obj_in <> nil) then
    dec(obj_in.child_count);

  if (_name <> nil) then
    unhash_string(_name);
    
  if (_short <> nil) then
    unhash_string(_short);

  if (_long <> nil) then
    unhash_string(_long);

  contents.Free();
  
  inherited Destroy();
end;

procedure GObject.toRoom(to_room : GRoom);
var
	iterator : GIterator;
	otmp : GObject;
begin
  if (to_room = nil) then
    begin
    bugreport('GObject.toRoom', 'area.pas', 'room null');
    exit;
    end;

  iterator := to_room.objects.iterator();

  while (iterator.hasNext()) do
    begin
    otmp := GObject(iterator.next());

    if (otmp.group(Self)) then
    	begin
		  iterator.Free();
      exit;
      end;
    end;

	iterator.Free();
	
  node_room := to_room.objects.insertLast(Self);

  room := to_room;
  in_obj := nil;
  carried_by := nil;
end;

procedure Gobject.fromRoom;
begin
  if (room=nil) then
    bugreport('obj_from_room', 'area.pas', 'room null');

  room.objects.remove(node_room);
  node_room := nil;
  room := nil;
end;

procedure GObject.toChar(c : pointer);
var 
{	grouped : boolean;
	node : GListNode;
	otmp : GObject; }
	ch : GCharacter;
	oweight : integer;
begin
  oweight := getWeight();
  ch := GCharacter(c);
  
{  
	
	*** TODO!!
	
	grouped := false;

  node := ch.objects.head;

  while (node <> nil) do
    begin
    otmp := node.element;

    if (otmp.group(Self)) then
      begin
      grouped := true;
      break;
      end;

    node := node.next;
    end; }

  if (worn <> '') then
    ch.equipment[worn] := Self
  else
    node_carry := ch.inventory.insertFirst(Self);
  
  carried_by := c;

  inc(ch.carried_weight, oweight);
end;

procedure GObject.fromChar;
begin
  if (worn <> '') then
    GCharacter(carried_by).equipment.remove(worn)
  else
    GCharacter(carried_by).inventory.remove(node_carry);
    
  dec(GCharacter(carried_by).carried_weight, getWeight);

  worn := '';
  node_carry := nil;
  carried_by := nil;
end;

{ grouped obj.toObject - Nemesis }
procedure GObject.toObject(obj : GObject);
var 
	iterator : GIterator;
	otmp : GObject;
begin
  iterator := obj.contents.iterator();

  while (iterator.hasNext()) do
    begin
    otmp := GObject(iterator.next());

    if (otmp.group(Self)) then
    	begin
		  iterator.Free();
      exit;
      end;
    end;
    
  iterator.Free();

  node_in := obj.contents.insertLast(Self);
  in_obj := obj;
end;

procedure GObject.fromObject;
begin
  in_obj.contents.remove(node_in);
  node_in := nil;
  in_obj := nil;
end;

function GObject.getWeight : integer;
var 
	we : integer;
	iterator : GIterator;
	obj : GObject;
begin
  we := count * weight;

  iterator := contents.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());
    inc(we, obj.getWeight);
    end;
    
	iterator.Free();

  Result := we;
end;

procedure GObject.setName(const name : string);
begin
  if (_name <> nil) then
    unhash_string(_name);

  _name := hash_string(name);
end;

procedure GObject.setShortName(const name : string);
begin
  if (_short <> nil) then
    unhash_string(_short);

  _short := hash_string(name);
end;

procedure GObject.setLongName(const name : string);
begin
  if (_long <> nil) then
    unhash_string(_long);

  _long := hash_string(name);
end;

function GObject.getName() : string;
begin
  if (_name <> nil) then
    Result := _name^
  else
    Result := '';
end;

function GObject.getShortName() : string;
begin
  if (_short <> nil) then
    Result := _short^
  else
    Result := '';
end;

function GObject.getLongName() : string;
begin
  if (_long <> nil) then
    Result := _long^
  else
    Result := '';
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

// misc
{Jago 5/Jan/01 : func required for do_goto and do_transfer
		- should probably be placed elsewhere }
function findLocation(ch : pointer; param : string) : GRoom;
var
  room : GRoom;
  searchVNum : integer;
  victim : GCharacter;
begin
  result := nil;

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

    if victim <> nil then
      begin
      Result := victim.room;
      exit;
      end;
    end;

 {left out obj's for today}
 (*    if ( ( obj = get_obj_world( ch, arg ) ) != NULL )
	return obj->in_room;
*)
end;

function findRoom(vnum : integer) : GRoom;
begin
  Result := GRoom(room_list.get(vnum));
end;

function findNPCIndex(vnum : integer) : GNPCIndex;
var
	iterator : GIterator;
	npc : GNPCIndex;
begin
  Result := nil;

  iterator := npc_list.iterator();

  while (iterator.hasNext()) do
    begin
    npc := GNPCIndex(iterator.next());

    if (npc.vnum = vnum) then
      begin
      Result := npc;
      break;
      end;
    end;
    
	iterator.Free();
end;

{ function findObjectIndex(vnum : integer) : GObjectIndex;
var
   node : GListNode;
   obj : GObjectIndex;
begin
  findObjectIndex := nil;

  node := obj_list.head;

  while (node <> nil) do
    begin
    obj := node.element;

    if (obj.vnum = vnum) then
      begin
      findObjectIndex := obj;
      exit;
      end;

    node := node.next;
    end;
end;

function instanceObject(o_index : GObjectIndex) : GObject;
var obj : GObject;
begin
  if (o_index = nil) then
    begin
    bugreport('instanceObject', 'area.pas', 'o_index null');
    instanceObject := nil;
    exit;
    end;

  obj := GObject.Create;

  with obj do
    begin
    name := o_index.name^;
    short := o_index.short^;
    long := o_index.long^;

    item_type:=o_index.item_type;
    wear1:=o_index.wear1;
    wear2:=o_index.wear2;
    value:=o_index.value;
    weight:=o_index.weight;
    flags:=o_index.flags;
    cost:=o_index.cost;
    timer:=o_index.timer;
    obj_index:=o_index;
    room:=nil;
    end;

  inc(o_index.obj_count);

  obj.node_world := object_list.insertLast(obj);
  instanceObject:=obj;
end; }

{ Revised 29/Jan/2001 - Nemesis }
procedure addCorpse(c : pointer);
var 
  obj,obj_in : GObject;
  iterator : GIterator;
  ch : GCharacter;
begin
  ch := c;

  obj_in := GObject(objectIndices[OBJ_VNUM_CORPSE]);
  
  if (obj_in = nil) then
  	begin
  	bugreport('area.pas', 'addCorpse', 'index for OBJ_VNUM_CORPSE (' + IntToStr(OBJ_VNUM_CORPSE) + ') not found');
    exit;
    end;
    
  obj := obj_in.clone();

  with obj do
    begin
    name := 'a corpse';
    short := '$4the corpse of ' + ch.name + '$7';
    long := '$4The corpse of ' + ch.name + ' is lying here$7';

    if (not ch.IS_NPC) then
      SET_BIT(flags, OBJ_NOSAC);

    SET_BIT(flags, OBJ_NOPICKUP);

    // player corpses will remain longer than mobiles to give players more
    // opportunity to retreive their items.

    if (ch.IS_NPC) then
      obj.timer := 5
    else
      obj.timer := 20;
    end;

  { when ch dies in bg, we don't want to have him lose all his items! - Grimlord }
  if not (not ch.IS_NPC and (GPlayer(ch).bg_status=BG_PARTICIPATE)) then
    begin
    // Inventory put into corpse as well, but not for shopkeepers of course :)
    if (not ch.IS_SHOPKEEPER) then
      begin
      iterator := ch.inventory.iterator();
      
      while (iterator.hasNext()) do
        begin
        obj_in := GObject(iterator.next());

        if (not IS_SET(obj_in.flags, OBJ_LOYAL)) and (not ((obj_in.worn <> '') and (IS_SET(obj_in.flags, OBJ_NOREMOVE)))) then
          begin
          obj_in.fromChar;
          obj_in.toObject(obj);
          end;
        end;
        
      iterator.Free();

      iterator := ch.equipment.iterator();
      
      while (iterator.hasNext()) do
        begin
        obj_in := GObject(iterator.next());

        if (not IS_SET(obj_in.flags, OBJ_LOYAL)) and (not ((obj_in.worn <> '') and (IS_SET(obj_in.flags, OBJ_NOREMOVE)))) then
          begin
          obj_in.fromChar;
          obj_in.toObject(obj);
          end;
        end;
        
      iterator.Free();
      end;
    end;
    
  if (ch.gold > 0) then
    begin
    obj_in := GObject.Create();
    
    with obj_in do
      begin
      if (ch.gold = 1) then
        begin
        name := 'one gold coin';
        short := 'one gold coin';
        long := 'one gold coin';
        end
      else
        begin
        name := IntToStr(ch.gold) + ' gold coins';
        short := IntToStr(ch.gold) + ' gold coins';
        long := IntToStr(ch.gold) + ' gold coins';
        end;

      item_type := ITEM_MONEY;

      value[1] := ch.gold;
      
      worn := '';
      wear_location1 := ''; wear_location2 := '';
      weight := 0;
      timer := 0;
      end;

    obj_in.node_world := objectList.insertLast(obj_in);

    obj_in.toObject(obj);
    
    ch.gold := 0;
    end;

  obj.toRoom(ch.room);
end;

function findHeading(s : string) : integer;
var a:integer;
begin
  FindHeading:=-1;
  s:=lowercase(s);
  for a:=DIR_NORTH to DIR_UP do
   if pos(s,headings[a])=1 then
    begin
    FindHeading:=a;
    break;
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

function GObject.clone() : GObject;
var
  obj : GObject;
  obj_in : GObject;
begin
  obj := GObject.Create();

  obj.name := name;
  obj.short := short;
  obj.long := long;
  obj.item_type := item_type;
  obj.wear_location1 := wear_location1;
  obj.wear_location2 := wear_location2;
  obj.flags := flags;
  obj.value[1] := value[1];
  obj.value[2] := value[2];
  obj.value[3] := value[3];
  obj.value[4] := value[4];
  obj.weight := weight;
  obj.cost := cost;
  obj.count := 1;
  obj.vnum := vnum;
  obj.timer := timer;
  
  obj_in := GObject(objectIndices[vnum]);

  if (obj_in <> nil) then
    inc(obj_in.child_count);

  obj.node_world := objectList.insertLast(obj);

  Result := obj;
end;

function GObject.group(obj : GObject) : boolean;
begin
  Result := false;

{  if (obj = nil) or (obj = Self) then
    exit;

  if (Self.name = obj.name) and
   (Self.short = obj.short) and
   (Self.long = obj.long) and
   (Self.item_type = obj.item_type) and
   (Self.wear1 = obj.wear1) and
   (Self.wear2 = obj.wear2) and
   (Self.flags = obj.flags) and
   (Self.cost = obj.cost) and
   (Self.weight = obj.weight) and
   (Self.value[1] = obj.value[1]) and
   (Self.value[2] = obj.value[2]) and
   (Self.value[3] = obj.value[3]) and
   (Self.value[4] = obj.value[4]) and
   (Self.wear_location = obj.wear_location) and
   (Self.contents.getSize() = 0) and (obj.contents.getSize() = 0) then
    begin
    inc(count, obj.count);

    if (obj_index <> nil) then
      inc(obj_index.obj_count, obj.count);

    obj.extract();

    Result := true;
    exit;
    end; }
end;

procedure GObject.split(num : integer);
{ var
   rest : GObject; }
begin
{  if (count <= num) or (num = 0) then
    exit;

  rest := clone();

  if (obj_index <> nil) then
    dec(obj_index.obj_count);

  rest.count := count - num;
  count := num;

  if (carried_by <> nil) then
    begin
    rest.node_carry := GCharacter(carried_by).objects.insertLast(rest);
    rest.carried_by := carried_by;
    rest.room := nil;
    rest.in_obj := nil;
    end
  else
  if (room <> nil) then
    begin
    rest.node_room := room.objects.insertLast(rest);
    rest.carried_by := nil;
    rest.room := room;
    rest.in_obj := nil;
    end
  else
  if (in_obj <> nil) then
    begin
    rest.toObject(in_obj);
    rest.in_obj := in_obj;
    rest.room := nil;
    rest.carried_by := nil;
    end; }
end;

procedure GObject.seperate;
begin
  split(1);
end;

{Jago 10/Jan/2001 - utility function }
{ Revised 28/Jan/2001 - Nemesis }
function findObjectWorld(s : string) : GObject;
var 
  obj : GObject;
  iterator : GIterator;
  number, count : integer;
begin
  number := findNumber(s); // eg 2.sword

  count := 0;

  iterator := objectList.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (isName(obj.name,s)) then
      begin
      inc(count);

      if (count = number) then
        begin
        Result := obj;
        exit;
        end;
      end;
    end;

  Result := nil;
end;

procedure initAreas();
begin
  area_list := GDLinkedList.Create;
  room_list := GHashTable.Create(32768);
  shop_list := GDLinkedList.Create;
  teleport_list := GDLinkedList.Create;

  npc_list := GDLinkedList.Create;
  
  objectList := GDLinkedList.Create();
  objectIndices := GHashTable.Create(32768);
end;

procedure cleanupAreas();
begin
  area_list.clean();
  area_list.Free();
  
  room_list.clear();
  room_list.Free();

  shop_list.clean();
  shop_list.Free();

  teleport_list.clean();
  teleport_list.Free();

  npc_list.clean();
  npc_list.Free();

  //objectList.clean();
  objectList.Free();

  objectIndices.clear();
  objectIndices.Free();
end;

end.
