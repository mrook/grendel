unit area;

interface

uses
    SysUtils,
    Classes,
    constants,
    mudsystem,
    dtypes,
    clan,
    race,
    fsys,
    strip,
    util;


type
    GRoom = class;
    GShop = class;

    GWeather = record
      mmhg, change, sky : integer;
      temp, temp_mult, temp_avg : integer;
    end;

    GArea = class
      fname, name, author : string;
      m_lo, m_hi, r_lo, r_hi, o_lo, o_hi : integer;
      resets : GDLinkedList;
      flags : integer;
      nplayer : integer;
      age, max_age : integer;         { age/max in gamehours }
      reset_msg : string;              { msg when reset }
      weather : GWeather;             { current local weather }

      found_range : boolean;
      af : GFileReader;

      procedure areaBug(func : string; problem : string);

      procedure loadRooms;
      procedure loadNPCs;
      procedure loadObjects;
      procedure loadResets;
      procedure loadShops;

      procedure update;
      procedure reset;

      procedure load(fn : string);

      constructor Create;
      destructor Destroy; override;
    end;

    GObjectValues = array[1..4] of integer;

    GObjectIndex = class
      name, short, long : PString;
      area : GArea;
      flags : cardinal;
      item_type,wear1,wear2:integer;
      value : GObjectValues;
      weight:integer;
      cost:integer;
      timer:integer;
      obj_count:integer;
      vnum:integer;
    end;

    GObject = class
      node_world, node_room, node_in, node_carry : GListNode;

      contents : GDLinkedList;
      carried_by : pointer;
      in_obj : GObject;
      room : GRoom;
      value : GObjectValues;
      obj_index : GObjectIndex;

      name, short, long : PString;

      wear_location : integer;

      flags : cardinal;
      item_type,wear1,wear2:integer;
      weight:integer;
      cost:integer;
      count:integer;
      timer:integer;

      procedure extract;

      procedure toRoom(to_room : GRoom);
      procedure fromRoom;

      procedure toChar(c : pointer);
      procedure fromChar;

      procedure toObject(obj : GObject);
      procedure fromObject;

      function getWeight : integer;

      function clone : GObject;
      function group(obj : GObject) : boolean;
      procedure split(num : integer);
      procedure seperate;

      constructor Create;
      destructor Destroy; override;
    end;

    GExit = class
      vnum : integer;
      direction : integer;
      to_room : GRoom;
      keywords : PString;
      flags : cardinal;
      key : integer;
    end;

    GNPCIndex = class
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
      learned:array[0..MAX_SKILLS-1] of integer;
      programs : GDLinkedList;
      mpflags, act_flags : cardinal;
      area : GArea;
      clan : GClan;
      shop : GShop;

      destructor Destroy; override;
    end;

    GReset = class
      area : GArea;
      reset_type : char;
      arg1, arg2, arg3 : integer;
    end;

    GTeleport = class
      t_room : GRoom;
      timer : integer;
    end;

    GTrack = class
      who : string;
      life : integer;
      direction : integer;
    end;

    GExtraDescription = class
      keywords : string;
      description : string;
    end;

    GRoom = class
      node : GListNode;

      vnum : integer;
      name : PString;
      description : string;
      area : GArea;
      flags, sector : integer;
      televnum, teledelay : integer;
      max_level, min_level : integer;

      extra : GDLinkedList;
      exits : GDLinkedList;
      chars : GDLinkedList;
      objects : GDLinkedList;
      tracks : GDLinkedList;

      function findChar(c : pointer; name : string) : pointer;
      function findRandomChar : pointer;
      function findRandomGood : pointer;
      function findRandomEvil : pointer;
      function findObject(name : string) : pointer;

      function findDescription(keyword : string) : GExtraDescription;
      function findExit(dir : integer) : GExit;
      function findExitKeyword(s : string) : GExit;

      constructor Create(vn : integer; ar : GArea);
      destructor Destroy; override;
    end;

    GShop = class
      node : GListNode;
      keeper : integer;                        { keeper vnum }
      area : GArea;
      item_buy : array[1..MAX_TRADE] of integer;    { item_type to buy }
      open_hour, close_hour : integer;          { opening hours }
    end;


var
   area_list : GDLinkedList;
   room_list : GDLinkedList;
   object_list : GDLinkedList;
   shop_list : GDLinkedList;
   teleport_list : GDLinkedList;
   extracted_object_list : GDLinkedList;

   npc_list, obj_list : GDLinkedList;

procedure load_areas;

function findRoom(vnum : integer) : GRoom;
function findLocation(ch : pointer; param : string) : GRoom;
function findNPCIndex(vnum : integer) : GNPCIndex;
function findObjectIndex(vnum : integer) : GObjectIndex;

function instanceObject(o_index : GObjectIndex) : GObject;
procedure addCorpse(c : pointer);
function findHeading(s : string) : integer;

procedure cleanObjects;

function findObjectWorld(s : string) : GObject;

implementation

uses
    chars,
    skills,
    fight,
    progs,
    conns;


// GNPCIndex
destructor GNPCIndex.Destroy;
begin
  programs.clean;
  programs.Destroy;
  
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

  author := 'No author';
  reset_msg := 'No reset';
  name := 'New area';

  max_age := 10;
  age := 0;
  flags := 0;

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
  bugreport(func, 'area.pas', fname + ': ' + problem + ', line ' + inttostr(af.line),
            problem);
end;

procedure GArea.loadRooms;
var s : string;
    vnum : integer;
    room : GRoom;
    s_exit : GExit;
    s_extra : GExtraDescription;
    buf : string;
    node : GListNode;
    fnd : boolean;
begin
  repeat
    repeat
      s := af.readLine;
    until pos('#', s) = 1;

    if (uppercase(s) = '#END') then
      exit;

    delete(s, 1, 1);

    try
      vnum := strtoint(stripl(s, ' '));
    except
      areaBug('rooms_load', 'invalid numeric format ' + s);
      exit;
    end;

    room := GRoom.Create(vnum, Self);
    room.node := room_list.insertLast(room);

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
        if (vnum < area.r_lo) then
          area.r_lo := vnum;
        if (vnum > area.r_hi) then
          area.r_hi := vnum;
        end;

      name := hash_string(s);
      buf := '';

      repeat
        s := af.readLine;

        if (s <> '~') then
          buf := buf + s + #13#10;
      until (s = '~');

      description := buf;

      flags := af.readCardinal;
      min_level := af.readInteger;
      max_level := af.readInteger;
      sector := af.readCardinal;

      if (IS_SET(flags, ROOM_TELEPORT)) then
        begin
        televnum := af.readCardinal;
        teledelay := af.readInteger;
        end;

      if (max_level = 0) then
        max_level := LEVEL_MAX;

      while (true) do
        begin
        s := af.readWord;

        case s[1] of
          'S' : break;
          'D' : begin
                s_exit := GExit.Create;
                s_exit.vnum := af.readCardinal;
                s_exit.direction := af.readCardinal;
                s_exit.flags := af.readCardinal;
                s_exit.key := af.readInteger;

                if not (af.feol) then
                  s_exit.keywords := hash_string(af.readLine);

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
  until (uppercase(s) = '#END');
end;

procedure GArea.loadNPCs;
var s:string;
    a,num:integer;
    npc : GNPCIndex;
    prog : GProgram;
begin
  s := af.readLine;

  repeat
    while (pos('#',s) = 0) do
      s := af.readLine;

    if (uppercase(s)='#END') then
      exit;

    delete(s,1,1);

    try
      npc := GNPCIndex.Create;
      
      num := strtoint(s);

      npc.area := Self;

      with npc do
        begin
        programs := GDLinkedList.Create;

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

        mv:=500;
        str:=UMax(65+random(level div 50),100);
        con:=UMax(65+random(level div 51),100);
        dex:=UMax(65+random(level div 52),100);
        int:=UMax(65+random(level div 53),100);
        wis:=UMax(65+random(level div 54),100);
        hitroll:=UMax((level div 5)+50,100);
        hp:=(level+1)*((con div 4)+random(6)-3);

        damsizedie:=round(sqrt(level));
        damnumdie:=round(sqrt(level));

        sex := af.readInteger;

        if (not af.feol) then
          begin
          s := af.readQuoted;

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
            prog := GProgram.Create;

            prog.load(af, s, npc);
            end
          else
            begin
            s := striprbeg(s,' ');
            a := findSkill(s);

            if (a <> -1) then
              learned[a] := 100
            else
              areaBug('loadNPCs', 'unknown skill '+s);
            end;

          s := af.readLine;
          end;

        race := race_list.head.element;

        SET_BIT(act_flags, ACT_NPC);

        count := 0;

        npc_list.insertLast(npc);
        end;
      except
        bugreport('GArea.loadMobiles', 'area.pas', 'something went wrong',
                  'Something went wrong while loading mobiles. Please check your settings.');
        npc.Free;
      end;
  until (uppercase(s) = '#END');
end;

procedure GArea.loadObjects;
var s:string;
    num:integer;
    o_index:GObjectIndex;
begin
  repeat
    s := af.readLine;

    if (uppercase(s) = '#END') then
      exit;

    num:=0;
    try
      num:=StrToInt(striprbeg(s,'#'));
    except
      areaBug('load_objects','illegal numeric format '+s);
      exit;
    end;

    if (findObjectIndex(num) <> nil) then
      begin
      areaBug('load_objects','vnum conflict ('+inttostr(num)+')');
      exit;
      end;

    o_index := GObjectIndex.Create;
    o_index.area := Self;

    with o_index do
      begin
      name := hash_string(af.readLine);
      short := hash_string(af.readLine);
      long := hash_string(af.readLine);

      vnum:=num;

      if (not found_range) then
        begin
        if (vnum < area.o_lo) then
          area.o_lo := vnum;
        if (vnum > area.o_hi) then
          area.o_hi := vnum;
        end;

      item_type := af.readInteger;

      wear1 := af.readInteger;
      wear2 := af.readInteger;

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

      weight := af.readInteger;
      flags := af.readCardinal;
      cost := af.readInteger;

      obj_count:=0;
      end;

    obj_list.insertLast(o_index);
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
        d := stripl(s,':');
        reset_type := d[1];

        s := striprbeg(s,' ');
        arg1 := strtoint(stripl(s,' '));
        s := striprbeg(s,' ');
        arg2 := strtoint(stripl(s,' '));
        s := striprbeg(s,' ');
        arg3 := strtoint(stripl(s,' '));

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
          if (findObjectIndex(arg1) = nil) then
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
          if (findObjectIndex(arg1) = nil) then
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
          if (findObjectIndex(arg1) = nil) then
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
          if (findObjectIndex(arg1) = nil) then
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
      shop.keeper := strtoint(stripl(s,' '));

      npc := findNPCIndex(shop.keeper);

      if (npc = nil) then
        areaBug('GArea.loadShops', 'shopkeeper '+inttostr(shop.keeper)+' null')
      else
        npc.shop := shop;

      s := af.readLine;

      shop.item_buy[1]:=strtoint(stripl(s,' '));

      s:=striprbeg(s,' ');
      shop.item_buy[2]:=strtoint(stripl(s,' '));

      s:=striprbeg(s,' ');
      shop.item_buy[3]:=strtoint(stripl(s,' '));

      s:=striprbeg(s,' ');
      shop.item_buy[4]:=strtoint(stripl(s,' '));

      s:=striprbeg(s,' ');
      shop.item_buy[5]:=strtoint(stripl(s,' '));

      s := af.readLine;
      shop.open_hour:=strtoint(stripl(s,' '));

      s:=striprbeg(s,' ');
      shop.close_hour:=strtoint(stripl(s,' '));

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
    bugreport('GArea.load', 'area.pas', 'could not open ' + fn,
              'The area list file could not be opened.');
    exit;
  end;

  fname := fn;
  found_range := false;

  repeat
    s := af.readLine;
    s := uppercase(s);

    if (s = '#AREA') then
      begin
      name := af.readLine;
      author := af.readLine;
      reset_msg := af.readLine;

      max_age := af.readInteger;

      with weather do
        begin
        temp_mult := af.readInteger;
        temp_avg := af.readInteger;
        end;

      flags := af.readCardinal;
      age := 0;
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
      loadRooms
    else
    if (s = '#MOBILES') then
      loadNPCs
    else
    if (s = '#OBJECTS') then
      loadObjects
    else
    if (s = '#RESETS') then
      loadResets
    else
    if (s = '#SHOPS') then
      loadShops;
  until (s = '$');

  af.Free;
end;

procedure load_areas;
var to_room, room : GRoom;
    pexit : GExit;
    s : string;
    lf : TextFile;
    area : GArea;
    node, node_exit : GListNode;
begin
  assignfile(lf, 'areas\area.list');

  {$I-}
  reset(lf);
  {$I+}

  if (IOResult <> 0) then
    begin
    bugreport('load_areas', 'area.pas', 'could not open areas\area.list',
              'The area list file could not be opened.');
    exit;
    end;

  repeat
    readln(lf, s);
    if (s <> '$') then
      begin
      area := GArea.Create;
      area.load(s);

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

      write_console(s);
      end;
  until (s = '$');

  closefile(lf);

  write_console('Checking exits...');

  { Checking rooms for errors }

  node := room_list.head;
  
  while (node <> nil) do
    begin
    room := node.element;

    node_exit := room.exits.head;

    while (node_exit <> nil) do
      begin
      pexit := node_exit.element;

      to_room := findRoom(pexit.vnum);

      if not (pexit.direction in [DIR_NORTH..DIR_SOMEWHERE]) then
        begin
        bugreport('room_check', 'area.pas', 'room #'+inttostr(room.vnum)+' illegal direction '+
                  inttostr(pexit.direction), 'The room parser encountered a flaw in this area.');

        room.exits.remove(node_exit);

        node_exit := room.exits.head;
        end
      else
      if (to_room=nil) then
        begin
        bugreport('room_check', 'area.pas', 'room #'+inttostr(room.vnum)+' '+
                   headings[pexit.direction]+' -> '+inttostr(pexit.vnum)+' null',
                   'The room parser encountered a flaw in this area.');

        room.exits.remove(node_exit);

        node_exit := room.exits.head;
        end
      else
        begin
        pexit.to_room:=to_room;

        node_exit := node_exit.next;
        end;
      end;

    node := node.next;
    end;

  { check the links }
  (* CHECK_LINKS(areas_first,areas_last,0,4,'areas');
  CHECK_LINKS(rooms_first,rooms_last,0,4,'rooms');
  CHECK_LINKS(obj_reset_first,obj_reset_last,0,4,'obj_reset');
  CHECK_LINKS(mob_reset_first,mob_reset_last,0,4,'mob_reset'); *)

  { reset the areas }
  node := area_list.head;

  while (node <> nil) do
    begin
    GArea(node.element).reset;

    node := node.next;
    end;
end;

procedure GArea.reset;
var reset : GReset;
    npc, vict, lastmob : GCharacter;
    obj, lastobj : GObject;
    npcindex : GNPCIndex;
    objindex : GObjectIndex;
    room : GRoom;
    pexit : GExit;
    conn : GConnection;
    node_reset, node_char : GListNode;
    buf : string;
begin
  lastmob := nil;

  node_char := connection_list.head;
  while (node_char <> nil) do
    begin
    conn := node_char.element;

    if (conn.state=CON_PLAYING) and (conn.ch.room.area = Self) then
      begin
      buf := conn.ch.ansiColor(AT_REPORT) + reset_msg + #13#10;
      conn.ch.sendBuffer(buf);
      end;

    node_char := node_char.next;
    end;

  node_reset := resets.head;
  while (node_reset <> nil) do
    begin
    reset := node_reset.element;

    case reset.reset_type of
      'M':begin
          npcindex := findNPCIndex(reset.arg1);

          if (npcindex = nil) then
            bugreport('GArea.reset', 'area.pas', 'vnum '+inttostr(reset.arg1)+' null',
                      'There is no mobile with the specified vnum.')
          else
            begin
            lastmob := nil;
            npc := nil;

            if (npcindex.count < reset.arg3) then
              begin

              npc := GCharacter.Create;

              with npc do
                begin
                ability.str:=npcindex.str;
                ability.con:=npcindex.con;
                ability.dex:=npcindex.dex;
                ability.int:=npcindex.int;
                ability.wis:=npcindex.wis;
                point.hp:=npcindex.hp;
                point.max_hp:=npcindex.hp;
                point.mv:=npcindex.mv;
                point.max_mv:=npcindex.mv;
                point.mana:=npcindex.mana;
                point.max_mana:=npcindex.mana;
                point.natural_ac:=npcindex.natural_ac;
                point.ac_mod:=0;
                point.hitroll:=npcindex.hitroll;
{                  point.dam_type:=npcindex.dam_type; }
                point.damnumdie:=npcindex.damnumdie;
                point.damsizedie:=npcindex.damsizedie;
                point.apb:=npcindex.apb;
                move(npcindex.learned,learned,sizeof(learned));
                clan:=npcindex.clan;
                conn:=nil;
                npc.room := findRoom(reset.arg2);
                position:=POS_STANDING;
                npc.npc_index := npcindex;

                name := hash_string(npcindex.name);
                short := hash_string(npcindex.short);
                long := hash_string(npcindex.long);

                sex:=npcindex.sex;
                race:=npcindex.race;
                alignment:=npcindex.alignment;
                level:=npcindex.level;
                weight:=npcindex.weight;
                height:=npcindex.height;
                act_flags:=npcindex.act_flags;
                end;

              inc(npcindex.count);
              npc.node_world := char_list.insertLast(npc);

              if (npc.room = nil) then
                begin
                bugreport('GArea.reset', 'area.pas', 'room vnum #'+inttostr(reset.arg2)+' null',
                          'The room to reset a mobile in does not exist.');

                npc.extract(true);
                end
              else
                begin
                npc.calcAC;

                npc.toRoom(npc.room);
                lastmob := npc;
                inc(mobs_loaded);
                resetTrigger(npc);
                end;
              end;
            end;
          end;
      'E':begin
          objindex:=findObjectIndex(reset.arg1);
          npc:=nil;

          if (reset.arg3<>0) then
            begin
            node_char := char_list.head;

            while (node_char <> nil) do
              begin
              vict := node_char.element;

              if (vict.IS_NPC) and (vict.npc_index.vnum = reset.arg3) then
                begin
                npc:=vict;
                break;
                end;

              node_char := node_char.next;
              end;

            if (npc = nil) then
              begin
              bugreport('GArea.reset', 'area.pas', '('+inttostr(reset.arg1)+') npc vnum '+inttostr(reset.arg3)+' null',
                        'Attempted to reset an object to a null mobile.');
              node_reset := node_reset.next;
              continue;
              end;
            end
          else
            npc:=lastmob;

          if lastmob=nil then
            begin
            node_reset := node_reset.next;
            continue;
            end;

          if (objindex = nil) then
            bugreport('GArea.reset', 'area.pas', 'vnum '+inttostr(reset.arg1)+' null',
                      'Attempted to reset a null object to a mobile.')
          else
          if npc=nil then
            bugreport('GArea.reset', 'area.pas', '('+inttostr(reset.arg1)+') npc vnum '+inttostr(reset.arg3)+' null',
                      'Attempted to reset an object to a null mobile.')
          else
          if (number_percent <= reset.arg2) then
            begin
            obj := instanceObject(findObjectIndex(reset.arg1));
            npc.equip(obj);

            lastobj := obj;
            end;
          end;
      'G':begin
          objindex := findObjectIndex(reset.arg1);
          npc := nil;

          if (reset.arg3 <> 0) then
            begin
            node_char := char_list.head;

            while (node_char <> nil) do
              begin
              vict := node_char.element;
              
              if (vict.IS_NPC) and (vict.npc_index.vnum = reset.arg3) then
                begin
                npc := vict;
                break;
                end;

              node_char := node_char.next;
              end;

            if (npc = nil) then
              begin
              bugreport('GArea.reset', 'area.pas', '('+inttostr(reset.arg1)+') npc vnum '+inttostr(reset.arg3)+' null',
                        'Attempted to reset an object to a null mobile.');
              node_reset := node_reset.next;
              continue;
              end;
            end
          else
            npc:=lastmob;

          if lastmob=nil then
            begin
            node_reset := node_reset.next;
            continue;
            end;

          if objindex=nil then
            bugreport('GArea.reset', 'area.pas', 'vnum '+inttostr(reset.arg1)+' null',
                      'Attempted to reset a null object to a mobile.')
          else
            begin
            obj := instanceObject(findObjectIndex(reset.arg1));
            obj.toChar(npc);

            lastobj := obj;
            end;
          end;
      'O':begin
          objindex:=findObjectIndex(reset.arg1);

          if objindex=nil then
            bugreport('GArea.reset', 'area.pas', 'vnum '+inttostr(reset.arg1)+' null',
                      'Attempted to reset a null object.')
          else
          if (objindex.area.nplayer=0) and (reset.arg3>objindex.obj_count) then
            begin
            obj := instanceObject(objindex);
            obj.toRoom(findRoom(reset.arg2));

            lastobj := obj;
            end;
          end;
      'I':begin
          objindex := findObjectIndex(reset.arg1);

          if lastobj=nil then
            begin
            node_reset := node_reset.next;
            continue;
            end;

          if objindex=nil then
            bugreport('GArea.reset', 'area.pas', 'vnum '+inttostr(reset.arg1)+' null',
                      'Attempted to reset a null object.')
          else
          if (objindex.area.nplayer=0) and (reset.arg3>objindex.obj_count) then
            begin
            obj := instanceObject(objindex);
            obj.toObject(lastobj);
            end;
          end;
      'D':begin
          room := findRoom(reset.arg1);
          if (room = nil) then
            begin
            bugreport('GArea.reset', 'area.pas', 'vnum '+inttostr(reset.arg1)+' null',
                      'Attempted to reset a null room.');
            exit;
            end;

          pexit := room.findExit(reset.arg2);
          if (pexit = nil) then
            begin
            bugreport('GArea.reset', 'area.pas', 'direction '+inttostr(reset.arg2) + ' has no exit in room ' + inttostr(reset.arg1),
                      'Attempted to reset a null exit.');
            exit;
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

  age:=0;
end;

procedure GArea.update;
var buf : string;
    diff:integer;
    conn : GConnection;
    node : GListNode;
begin
  inc(age);

  if (age >= max_age) then
    begin
    write_console('Resetting ' + fname + '...');

    reset;
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
     bugreport('GArea.update', 'update.pas', 'bad sky',
               'The sky identifier given is unknown.');
     weather.sky:=SKY_CLOUDLESS;
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

  node := connection_list.head;

  while (node <> nil) do
    begin
    conn := node.element;
    
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

    node := node.next;
    end;
end;


// GRoom
constructor GRoom.Create(vn : integer; ar : GArea);
begin
  inherited Create;

  vnum := vn;
  area := ar;

  extra := GDLinkedList.Create;
  exits := GDLinkedList.Create;
  chars := GDLinkedList.Create;
  objects := GDLinkedList.Create;
  tracks := GDLinkedList.Create;

  sector := 1;
  flags := 0;
end;

destructor GRoom.Destroy;
begin
  unhash_string(name);

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

function GRoom.findChar(c : pointer; name : string) : pointer;
var
   node : GListNode;
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

  node := chars.head;

  while (node <> nil) do
    begin
    vict := node.element;

    if ((name = 'GOOD') and (not vict.IS_NPC) and (vict.IS_GOOD)) or
     ((name = 'EVIL') and (not vict.IS_NPC) and (vict.IS_EVIL)) or
      ((pos(name, uppercase(vict.name^)) <> 0) or
       (pos(name, uppercase(vict.short^))<>0) or
        ((not vict.IS_NPC) and (not ch.IS_SAME_ALIGN(vict)) and (pos(name, uppercase(vict.race.name)) <> 0)))
         and (ch.CAN_SEE(vict)) then
      begin
      inc(cnt);

      if (cnt = num) then
        begin
        findChar := vict;
        exit;
        end;
      end;

    node := node.next;
    end;
end;

function GRoom.findRandomChar : pointer;
var a, num : integer;
    node : GListNode;
begin
  Result := nil;
  num := random(chars.getSize);

  node := chars.head;
  for a := 0 to num do
    node := node.next;

  if (node <> nil) then
    Result := node.element;
end;

function GRoom.findRandomGood : pointer;
var a, cnt, num : integer;
    vict : GCharacter;
    node : GListNode;
begin
  Result := nil;

  cnt := 0;
  node := chars.head;
  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.IS_GOOD) then
      inc(cnt);

    node := node.next;
    end;

  num := random(cnt);
  a := 0;

  node := chars.head;
  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.IS_GOOD) and (a = num) then
      begin
      Result := vict;
      break;
      end;

    node := node.next;
    end;
end;

function GRoom.findRandomEvil : pointer;
var a, cnt, num : integer;
    vict : GCharacter;
    node : GListNode;
begin
  Result := nil;

  cnt := 0;
  node := chars.head;
  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.IS_EVIL) then
      inc(cnt);

    node := node.next;
    end;

  num := random(cnt);
  a := 0;

  node := chars.head;
  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.IS_EVIL) and (a = num) then
      begin
      Result := vict;
      break;
      end;

    node := node.next;
    end;
end;

function GRoom.findObject(name : string) : pointer;
var
   node : GListNode;
   obj : GObject;
   num, cnt : integer;
begin
  node := objects.head;
  num := findNumber(name);
  findObject := nil;
  cnt := 0;

  while (node <> nil) do
    begin
    obj := node.element;

    if (pos(name, obj.name^) > 0) or (pos(name, obj.short^) > 0) or (pos(name, obj.long^) > 0) then
      begin
      inc(cnt, obj.count);

      if (cnt >= num) then
        begin
        findObject := obj;
        exit;
        end;
      end;

    node := node.next;
    end;
end;

function GRoom.findDescription(keyword : string) : GExtraDescription;
var
   node : GListNode;
   s_extra : GExtraDescription;
   s, p : integer;
   sub, key : string;
begin
  Result := nil;
  p := high(integer);

  node := extra.head;
  while (node <> nil) do
    begin
    s_extra := node.element;
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

    node := node.next;
    end;
end;

function GRoom.findExit(dir : integer) : GExit;
var
   node : GListNode;
   pexit : Gexit;
begin
  findExit := nil;

  node := exits.head;
  while (node <> nil) do
    begin
    pexit := node.element;

    if (pexit.direction = dir) then
      begin
      findExit := pexit;
      exit;
      end;

    node := node.next;
    end;
end;

function GRoom.findExitKeyword(s : string) : GExit;
var
   node : GListNode;
   pexit : GExit;
begin
  Result := nil;
  s := uppercase(s);

  node := exits.head;
  while (node <> nil) do
    begin
    pexit := node.element;

    if (pos(s, uppercase(pexit.keywords^)) <> 0) then
      begin
      Result := pexit;
      exit;
      end;

    node := node.next;
    end;
end;


// GObject
constructor GObject.Create;
begin
  inherited Create;

  wear_location := WEAR_NULL;
  contents := GDLinkedList.Create;
  obj_index := nil;
  count := 1;
end;

destructor GObject.Destroy;
begin
  unhash_string(name);
  unhash_string(short);
  unhash_string(long);

  contents.clean;
  contents.Free;
  
  inherited Destroy;
end;

procedure GObject.extract;
var obj_in : GObject;
    node : GListNode;
begin
  object_list.remove(node_world);
  node_world := nil;

  node := contents.head;

  while (node <> nil) do
    begin
    obj_in := node.element;

    obj_in.extract;

    node := node.next;
    end;

  if (room <> nil) then
    fromRoom;

  if (carried_by <> nil) then
    fromChar;

  if (in_obj <> nil) then
    fromObject;

  if (obj_index <> nil) then
    dec(obj_index.obj_count);

  extracted_object_list.insertLast(Self);
end;

procedure GObject.toRoom(to_room : GRoom);
var
   node : GListNode;
   otmp : GObject;
begin
  if (to_room = nil) then
    begin
    bugreport('GObject.toRoom', 'area.pas', 'room null',
              'Attempt to put object in null room.');
    exit;
    end;

  node := to_room.objects.head;

  while (node <> nil) do
    begin
    otmp := node.element;

    if (otmp.group(Self)) then
      exit;

    node := node.next;
    end;

  node_room := to_room.objects.insertLast(Self);

  room := to_room;
  in_obj := nil;
  carried_by := nil;
end;

procedure Gobject.fromRoom;
begin
  if (room=nil) then
    bugreport('obj_from_room', 'area.pas', 'room null',
              'Attempt to remove object from null room.');

  room.objects.remove(node_room);
  node_room := nil;
  room := nil;
end;

procedure GObject.toChar(c : pointer);
var grouped : boolean;
    ch : GCharacter;
    node : GListNode;
    otmp : GObject;
    oweight : integer;
begin
  oweight := getWeight;
  ch := GCharacter(c);
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
    end;

  if (not grouped) then
    begin
    node_carry := ch.objects.insertLast(Self);
    carried_by := c;
    end;

  inc(ch.carried_weight, oweight);
end;

procedure GObject.fromChar;
begin
  GCharacter(carried_by).objects.remove(node_carry);
  dec(GCharacter(carried_by).carried_weight, getWeight);

  wear_location := WEAR_NULL;

  node_carry := nil;
  carried_by := nil;
end;

{ grouped obj.toObject - Nemesis }
procedure GObject.toObject(obj : GObject);
var node : GListNode;
    otmp : GObject;
begin
  node := obj.contents.head;

  while (node <> nil) do
    begin
    otmp := node.element;

    if (otmp.group(Self)) then
      exit;

    node := node.next;
    end;

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
var we : integer;
    node : GListNode;
    obj : GObject;
begin
  we := count * weight;

  node := contents.head;

  while (node <> nil) do
    begin
    obj := node.element;
    inc(we, obj.getWeight);

    node := node.next;
    end;

  getWeight := we;
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

  try
    searchVNum := StrToInt(param);
    room := findRoom(searchVNum);
    Result := room;
    exit;
  except
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

	Result := nil;
end;

function findRoom(vnum : integer) : GRoom;
var
   node : GListNode;
   room : GRoom;
begin
  findRoom := nil;

  node := room_list.head;

  while (node <> nil) do
    begin
    room := GRoom(node.element);

    if (room.vnum = vnum) then
      begin
      findRoom := room;
      exit;
      end;

    node := node.next;
    end;
end;

function findNPCIndex(vnum : integer) : GNPCIndex;
var
   node : GListNode;
   npc : GNPCIndex;
begin
  findNPCIndex := nil;

  node := npc_list.head;

  while (node <> nil) do
    begin
    npc := node.element;

    if (npc.vnum = vnum) then
      begin
      findNPCIndex := npc;
      exit;
      end;

    node := node.next;
    end;
end;

function findObjectIndex(vnum : integer) : GObjectIndex;
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
    bugreport('instanceObject', 'area.pas', 'o_index null',
              'The index to create an object from is invalid.');
    instanceObject := nil;
    exit;
    end;

  obj := GObject.Create;

  with obj do
    begin
    name := hash_string(o_index.name);
    short := hash_string(o_index.short);
    long := hash_string(o_index.long);

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
end;

{ Revised 29/Jan/2001 - Nemesis }
procedure addCorpse(c : pointer);
var obj,obj_in : GObject;
    node : GListNode;
    ch : GCharacter;
    h:integer;
begin
  ch := c;

  obj := instanceObject(findObjectIndex(OBJ_VNUM_CORPSE));

  if (obj = nil) then
    exit;

  with obj do
    begin
    name := hash_string('a corpse');
    short := hash_string('$4the corpse of ' + ch.name^ + '$7');
    long := hash_string('$4The corpse of ' + ch.name^ + ' is lying here$7');

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
  if not (not ch.IS_NPC and (ch.player^.bg_status=BG_PARTICIPATE)) then
    begin
    node := ch.objects.head;

    // Inventory put into corpse as well, but not for shopkeepers of course :)

    if (not ch.IS_SHOPKEEPER) then
      begin
      while (node <> nil) do
        begin
        obj_in := node.element;

        if (not IS_SET(obj_in.flags, OBJ_LOYAL)) and (not ((obj_in.wear_location > WEAR_NULL) and (IS_SET(obj_in.flags, OBJ_NOREMOVE)))) then
          begin
          obj_in.fromChar;
          obj_in.toObject(obj);
          end;

        node := node.next;

        end;
      end;
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

function GObject.clone : GObject;
var
   obj : GObject;
begin
  obj := GObject.Create;

  obj.obj_index := obj_index;
  obj.name := hash_string(name);
  obj.short := hash_string(short);
  obj.long := hash_string(long);
  obj.item_type := item_type;
  obj.wear1 := wear1;
  obj.wear2 := wear2;
  obj.flags := flags;
  obj.value[1] := value[1];
  obj.value[2] := value[2];
  obj.value[3] := value[3];
  obj.value[4] := value[4];
  obj.weight := weight;
  obj.cost := cost;
  obj.count := 1;

  if (obj_index <> nil) then
    inc(obj_index.obj_count);

  obj.node_world := object_list.insertLast(obj);

  Result := obj;
end;

function GObject.group(obj : GObject) : boolean;
begin
  Result := false;

  if (obj = nil) or (obj = Self) then
    exit;

  if (Self.obj_index = obj.obj_index) and
   (Self.name = obj.name) and
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

    obj.extract;

    Result := true;
    exit;
    end;
end;

procedure GObject.split(num : integer);
var
   rest : GObject;
begin
  if (count <= num) or (num = 0) then
    exit;

  rest := clone;

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
    end;
end;

procedure GObject.seperate;
begin
  split(1);
end;

procedure cleanObjects;
var
   ext : GObject;
   node : GListNode;
begin
  while (true) do
    begin
    node := extracted_chars.tail;

    if (node = nil) then
      exit;

    ext := node.element;

    extracted_object_list.remove(node);

    ext.Free;
    end;
end;

{Jago 10/Jan/2001 - utility function }
{ Revised 28/Jan/2001 - Nemesis }
function findObjectWorld(s : string) : GObject;
var obj : GObject;
    obj_node : GListNode;
    number, count : integer;
begin

  number := findNumber(s); // eg 2.sword

  count := 0;

  obj_node := object_list.head;

  while (obj_node <> nil) do
    begin

    obj := GObject(obj_node.element);

    if isName(obj.name^,s) then
      begin

      inc(count);

      if (count = number) then
        begin
        Result := obj;
        exit;
        end;
      end;

    obj_node := obj_node.next;
    end;

  Result := nil;
end;

initialization
area_list := GDLinkedList.Create;
room_list := GDLinkedList.Create;
object_list := GDLinkedList.Create;
shop_list := GDLinkedList.Create;
teleport_list := GDLinkedList.Create;
extracted_object_list := GDLinkedList.Create;

npc_list := GDLinkedList.Create;
obj_list := GDLinkedList.Create;

end.
