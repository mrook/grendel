program convert;
{$APPTYPE CONSOLE}
uses
  SysUtils,
  strip,
  util,
  dtypes,
  constants,
  fsys,
  area;


// smaug defines
const SMAUG_ACT_NPC = BV00;
      SMAUG_ACT_SENTINEL = BV01;
      SMAUG_ACT_SCAVENGER = BV02;
      SMAUG_ACT_AGGRESSIVE = BV05;
      SMAUG_ACT_STAY_AREA = BV06;
      SMAUG_ACT_WIMPY = BV07;
      SMAUG_ACT_PET = BV08;
      SMAUG_ACT_TRAIN = BV09;
      SMAUG_ACT_PRACTICE = BV10;
      SMAUG_ACT_IMMORTAL = BV11;
      SMAUG_ACT_DEADLY = BV12;
      SMAUG_ACT_POLYSELF = BV13;
      SMAUG_ACT_META_AGGR = BV14;
      SMAUG_ACT_GUARDIAN = BV15;
      SMAUG_ACT_RUNNING = BV16;
      SMAUG_ACT_NOWANDER = BV17;
      SMAUG_ACT_MOUNTABLE = BV18;
      SMAUG_ACT_MOUNTED = BV19;
      SMAUG_ACT_SCHOLAR = BV20;
      SMAUG_ACT_SECRETIVE = BV21;
      SMAUG_ACT_HARDHAT = BV22;
      SMAUG_ACT_MOBINVIS = BV23;
      SMAUG_ACT_NOASSIST = BV24;
      SMAUG_ACT_AUTONOMOUS = BV25;
      SMAUG_ACT_PACIFIST = BV26;
      SMAUG_ACT_NOATTACK = BV27;
      SMAUG_ACT_ANNOYING = BV28;
      SMAUG_ACT_STATSHIELD = BV29;
      SMAUG_ACT_PROTOTYPE = BV30;

      SMAUG_ROOM_DARK = BV00;
      SMAUG_ROOM_DEATH = BV01;
      SMAUG_ROOM_NO_MOB = BV02;
      SMAUG_ROOM_INDOORS = BV03;
      SMAUG_ROOM_LAWFUL = BV04;
      SMAUG_ROOM_NEUTRAL = BV05;
      SMAUG_ROOM_CHAOTIC = BV06;
      SMAUG_ROOM_NO_MAGIC = BV07;
      SMAUG_ROOM_TUNNEL = BV08;
      SMAUG_ROOM_PRIVATE = BV09;
      SMAUG_ROOM_SAFE = BV10;
      SMAUG_ROOM_SOLITARY = BV11;
      SMAUG_ROOM_PET_SHOP = BV12;
      SMAUG_ROOM_NO_RECALL = BV13;
      SMAUG_ROOM_DONATION = BV14;
      SMAUG_ROOM_NODROPALL = BV15;
      SMAUG_ROOM_SILENCE = BV16;
      SMAUG_ROOM_LOGSPEECH = BV17;
      SMAUG_ROOM_NODROP = BV18;
      SMAUG_ROOM_CLANSTOREROOM = BV19;
      SMAUG_ROOM_NO_SUMMON = BV20;
      SMAUG_ROOM_NO_ASTRAL = BV21;
      SMAUG_ROOM_TELEPORT = BV22;
      SMAUG_ROOM_TELESHOWDESC = BV23;
      SMAUG_ROOM_NOFLOOR = BV24;
      SMAUG_ROOM_NOSUPPLICATE = BV25;
      SMAUG_ROOM_ARENA = BV26;
      SMAUG_ROOM_NOMISSILE = BV27;
      SMAUG_ROOM_PROTOTYPE = BV30;
      SMAUG_ROOM_DND = BV31;

      SMAUG_SECT_INSIDE = 0;
      SMAUG_SECT_CITY = 1;
      SMAUG_SECT_FIELD = 2;
      SMAUG_SECT_FOREST = 3;
      SMAUG_SECT_HILLS = 4;
      SMAUG_SECT_MOUNTAIN = 5;
      SMAUG_SECT_WATER_SWIM = 6;
      SMAUG_SECT_WATER_NOSWIM = 7;
      SMAUG_SECT_UNDERWATER = 8;
      SMAUG_SECT_AIR = 9;
      SMAUG_SECT_DESERT = 10;
      SMAUG_SECT_DUNNO = 11;
      SMAUG_SECT_OCEANFLOOR = 12;
      SMAUG_SECT_UNDERGROUND = 13;
      SMAUG_SECT_LAVA = 14;
      SMAUG_SECT_SWAMP = 15;
      SMAUG_SECT_MAX = 16;

var
   are : GArea;
   af : GFileReader;
   typ, s : string;
   npcindex : GNPCIndex;
   room : GRoom;
   ex : GExit;
   act_flags : integer;
   f : textfile;
   node, node_ex : GListNode;

begin
  writeln('Convert 1.0 - converts Smaug .are to Grendel .area'#13#10);

  if (paramcount < 2) then
    begin
    writeln('usage:  convert <.are input file> <.area output file>');
    exit;
    end;

  are := GArea.Create;

  try
    af := GFileReader.Create(paramstr(1));
  except
    writeln('Could not open ', paramstr(1), '!');
    exit;
  end;

  while (not af.eof) do
    begin
    s := af.readLine;

    if (pos('#AREA',s) > 0) then
      are.name := trim(stripl(striprbeg(s, ' '), '~'))
    else
    if (pos('#AUTHOR',s) > 0) then
      are.author := trim(stripl(striprbeg(s, ' '), '~'))
    else
    if (s = '#ROOMS') then
      repeat
        s := af.readLine;

        if (s <> '#0') then
          begin
          // vnum
          act_flags := strtoint(striprbeg(s, '#'));

          room := GRoom.Create(act_flags, are);
          room_list.insertLast(room);

          // name
          s := af.readLine;
          room.name := stripl(s, '~');

          // description
          room.description := '';
          repeat
            s := af.readLine;

            if (s <> '~') then
              room.description := room.description + s + #13#10;
          until (s = '~');

          // delete the last #13#10
          room.description := copy(room.description, 1, length(room.description) - 2);

          // area room-flags sector-type (teledelay televnum)
          s := af.readWord;
          act_flags := af.readCardinal;
          act_flags := af.readInteger;

          if (not af.feol) then
            begin
            room.teledelay := af.readInteger;
            room.televnum := af.readInteger;
            end;

          repeat
            s := af.readLine;

            if (pos('D', s) > 0) then
              begin
              ex := GExit.Create;
              room.exits.insertLast(ex);

              // direction
              ex.direction := strtoint(stripr(s, 'D')) + 1;

              // description
              repeat
                s := af.readLine;
              until (s = '~');

              // keyword(s)
              s := af.readLine;
              ex.keyword := stripl(s, '~');

              // exit_flags key to_room
              act_flags := af.readCardinal;
              act_flags := af.readInteger;
              ex.vnum := af.readInteger;
              end
            else
            if (s = 'E') then
              begin
              // keyword(s)
              s := af.readLine;

              // description
              repeat
                s := af.readLine;
              until (s = '~');
              end;
          until (s = 'S');
          end;
      until (s = '#0')
    else
    if (s = '#MOBILES') then
      repeat
        s := af.readLine;

        if (s <> '#0') then
          begin
          npcindex := GNPCIndex.Create;
          npc_reset.insertLast(npcindex);

          // vnum
          npcindex.vnum := strtoint(striprbeg(s, '#'));

          // name
          s := af.readLine;
          npcindex.name := stripl(s, '~');

          // short name
          s := af.readLine;
          npcindex.short := stripl(s, '~');

          // long name
          npcindex.long := '';
          repeat
            s := af.readLine;

            if (s <> '~') then
              npcindex.long := npcindex.long + s + #13#10;
          until (s = '~');

          // delete the last #13#10
          npcindex.long := copy(npcindex.long, 1, length(npcindex.long) - 2);

          // description
          repeat
            s := af.readLine;
          until (s = '~');

          // act_flags aff_flags alignment type
          act_flags := af.readCardinal;
          npcindex.act_flags := 0;

          if (IS_SET(act_flags, SMAUG_ACT_NPC)) then
            SET_BIT(npcindex.act_flags, ACT_NPC);

          if (IS_SET(act_flags, SMAUG_ACT_SENTINEL) or IS_SET(act_flags, SMAUG_ACT_NOWANDER)) then
            SET_BIT(npcindex.act_flags, ACT_SENTINEL);

          if (IS_SET(act_flags, SMAUG_ACT_SCAVENGER)) then
            SET_BIT(npcindex.act_flags, ACT_SCAVENGER);

          if (IS_SET(act_flags, SMAUG_ACT_AGGRESSIVE)) then
            SET_BIT(npcindex.act_flags, ACT_AGGRESSIVE);

          if (IS_SET(act_flags, SMAUG_ACT_STAY_AREA)) then
            SET_BIT(npcindex.act_flags, ACT_STAY_AREA);

          if (IS_SET(act_flags, SMAUG_ACT_TRAIN) or IS_SET(act_flags, SMAUG_ACT_PRACTICE)) then
            SET_BIT(npcindex.act_flags, ACT_TEACHER);

          if (IS_SET(act_flags, SMAUG_ACT_NPC)) then
            SET_BIT(npcindex.act_flags, ACT_NPC);

          if (IS_SET(act_flags, SMAUG_ACT_IMMORTAL)) then
            SET_BIT(npcindex.act_flags, ACT_IMMORTAL);

          if (IS_SET(act_flags, SMAUG_ACT_RUNNING)) then
            SET_BIT(npcindex.act_flags, ACT_FASTHUNT);

          if (IS_SET(act_flags, SMAUG_ACT_MOBINVIS)) then
            SET_BIT(npcindex.act_flags, ACT_MOBINVIS);

          if (IS_SET(act_flags, SMAUG_ACT_NOATTACK)) then
            SET_BIT(npcindex.act_flags, ACT_SPIRIT);

          if (IS_SET(act_flags, SMAUG_ACT_PROTOTYPE)) then
            SET_BIT(npcindex.act_flags, ACT_PROTO);

          act_flags := af.readCardinal;
          npcindex.alignment := af.readInteger;
          typ := af.readWord;

          // level hitroll armor hitdie damdie
          npcindex.level := af.readInteger;
          npcindex.hitroll := af.readInteger;
          npcindex.natural_ac := af.readInteger;
          s := af.readWord;
          s := af.readWord;

          // gold xp
          npcindex.gold := af.readInteger;
          act_flags := af.readInteger;

          // position position sex
          act_flags := af.readInteger;
          act_flags := af.readInteger;
          npcindex.sex := af.readInteger;

          if (typ = 'C') then
            begin
            // str int wis dex con cha lck
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;

            // sav1 sav2 sav3 sav4 sav5
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;

            // race class height weight speaks speaking numattacks
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            npcindex.height := af.readInteger;
            npcindex.weight := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;

            // hitroll damroll xflas res imm sus attacks defenses
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            act_flags := af.readInteger;
            end;
          end;
      until (s = '#0');
    end;

  af.Free;

  assign(f, paramstr(2));
  {$I-}
  rewrite(f);
  {$I+}

  if (IOResult <> 0) then
    begin
    writeln('Could not open ', paramstr(2), '!');
    exit;
    end;

  writeln(f, '#AREA');
  writeln(f, are.name);
  writeln(f, are.author);
  writeln(f, 'You hear birds sign.');
  writeln(f, '10');
  writeln(f, '2 20 0');
  writeln(f);
  writeln(f, '#ROOMS');

  node := room_list.head;
  while (node <> nil) do
    begin
    room := node.element;

    writeln(f, '#', room.vnum);
    writeln(f, room.name);
    writeln(f, room.description);
    writeln(f, '~');

    write(f, room.flags, ' ', room.min_level, ' ', room.max_level, ' ', room.sector);

    if (IS_SET(room.flags, ROOM_TELEPORT)) then
      writeln(f, ' ', room.televnum, ' ', room.teledelay)
    else
      writeln(f);

    node_ex := room.exits.head;
    while (node_ex <> nil) do
      begin
      ex := node_ex.element;

      write(f, 'D ', ex.vnum, ' ', ex.direction, ' ', ex.exit_flag, ' ', ex.key);

      if (length(ex.keyword) > 0) then
        writeln(f, ' ', ex.keyword)
      else
        writeln(f);

      node_ex := node_ex.next;
      end;

    writeln(f, 'S');

    node := node.next;
    end;

  writeln(f, '#END');
  writeln(f);
  writeln(f, '#MOBILES');

  node := npc_reset.head;
  while (node <> nil) do
    begin
    npcindex := node.element;

    writeln(f, '#', npcindex.vnum);
    
    writeln(f, npcindex.name);
    writeln(f, npcindex.short);
    writeln(f, npcindex.long);

    writeln(f, npcindex.level, ' ', npcindex.sex);
    writeln(f, npcindex.natural_ac, ' ', npcindex.act_flags, ' ', npcindex.gold, ' ', npcindex.height, ' ', npcindex.weight);

    node := node.next;
    end;

  writeln(f, '#END');
  writeln(f);
  writeln(f, '$');

  closefile(f);

  writeln('All done.');
end.
