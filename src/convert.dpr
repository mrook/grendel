{
	Summary:
		SMAUG area convertor
	
	## $Id: convert.dpr,v 1.2 2004/04/21 21:44:34 ***REMOVED*** Exp $
}
program convert;
{$APPTYPE CONSOLE}
uses
	SysUtils,
	DateUtils,
	strip,
	util,
	debug,
	console,
	dtypes,
	constants,
	fsys,
	area;


// smaug defines
const 
	SMAUG_ACT_NPC = BV00;
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

	SMAUG_EX_ISDOOR = BV00;
	SMAUG_EX_CLOSED = BV01;
	SMAUG_EX_LOCKED = BV02;
	SMAUG_EX_SECRET = BV03;
	SMAUG_EX_SWIM = BV04;
	SMAUG_EX_PICKPROOF = BV05;
	SMAUG_EX_FLY = BV06;
	SMAUG_EX_CLIMB = BV07;
	SMAUG_EX_DIG = BV08;
	SMAUG_EX_EATKEY = BV09;
	SMAUG_EX_NOPASSDOOR = BV10;
	SMAUG_EX_HIDDEN = BV11;
	SMAUG_EX_PASSAGE = BV12;
	SMAUG_EX_PORTAL = BV13;
	SMAUG_EX_RES1 = BV14;
	SMAUG_EX_RES2 = BV15;
	SMAUG_EX_xCLIMB = BV16;
	SMAUG_EX_xENTER = BV17;
	SMAUG_EX_xLEAVE = BV18;
	SMAUG_EX_xAUTO = BV19;
	SMAUG_EX_NOFLEE = BV20;
	SMAUG_EX_xSEARCHABLE = BV21;
	SMAUG_EX_BASHED = BV22;
	SMAUG_EX_BASHPROOF = BV23;
	SMAUG_EX_NOMOB = BV24;
	SMAUG_EX_WINDOW = BV25;
	SMAUG_EX_xLOOK = BV26;
	SMAUG_EX_ISBOLT = BV27;
	SMAUG_EX_BOLTED = BV28;


type
  	GConsoleConvert = class(GConsoleWriter)
  	public
		procedure write(timestamp : integer; const text : string; debugLevel : integer = 0); override;
  	end;
  	
procedure GConsoleConvert.write(timestamp : integer; const text : string; debugLevel : integer = 0);
begin
	writeln('[' + FormatDateTime('hh:nn:ss', UnixToDateTime(timestamp)) + '] ', text);
end;	



var
   are : GArea;
   af : GFileReader;
   typ, s, g : string;
   npcindex : GNPCIndex;
   room : GRoom;
   ex : GExit;
   reset : GReset;
   act_flags : cardinal;
   tmp, arg1, arg2, arg3 : integer;
   f : textfile;
   node, node_ex : GListNode;
   cons : GConsole;

begin
	cons := GConsole.Create();
	cons.attachWriter(GConsoleConvert.Create());
	cons.Free();

  	writeConsole('Convert 1.0 - converts Smaug .are to Grendel .area');
  
  	if (paramcount < 2) then
    	begin
    	writeConsole('usage:  convert <.are input file> <.area output file>');
    	exit;
    	end;

	initDebug();
	initAreas();

	are := GArea.Create();

	try
		af := GFileReader.Create(ParamStr(1));
	except
		writeConsole('Could not open ' + ParamStr(1) + '!');
		exit;
	end;

	writeConsole('Loading: ' + ParamStr(1));

	while (not af.eof) do
		begin
		s := af.readLine;

		if (pos('#AREA',s) > 0) then
			are.name := trim(left(right(s, ' '), '~'))
		else
		if (pos('#AUTHOR',s) > 0) then
			are.author := trim(left(right(s, ' '), '~'))
		else
		if (s = '#ROOMS') then
			repeat
			s := af.readLine;

			if (s <> '#0') then
			begin
			// vnum
			act_flags := strtoint(right(s, '#'));

			room := GRoom.Create(act_flags, are);
			room_list.put(act_flags, room);

			// name
			s := af.readLine;
			room.name := left(s, '~');

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
			s := af.readToken();
			act_flags := af.readCardinal();
			act_flags := af.readInteger();

			if (not af.eol()) then
				begin
				room.teledelay := af.readInteger();
				room.televnum := af.readInteger();
				end;

				repeat
				s := af.readLine;

				if (pos('D', s) > 0) then
					begin
					ex := GExit.Create;
					room.exits.insertLast(ex);

					// direction
					ex.direction := strtoint(right(s, 'D')) + 1;

					// description
					repeat
						s := af.readLine();
					until (s = '~');

					// keyword(s)
					s := af.readLine();
					ex.keywords := hash_string(left(s, '~'));

					// exit_flags key to_room
					act_flags := af.readCardinal();
					ex.flags := 0;

					if (IS_SET(act_flags, SMAUG_EX_ISDOOR)) then
						SET_BIT(ex.flags, EX_ISDOOR);

					if (IS_SET(act_flags, SMAUG_EX_CLOSED)) then
						SET_BIT(ex.flags, EX_CLOSED);

					if (IS_SET(act_flags, SMAUG_EX_LOCKED)) then
						SET_BIT(ex.flags, EX_LOCKED);

					if (IS_SET(act_flags, SMAUG_EX_SECRET)) then
						SET_BIT(ex.flags, EX_SECRET);

					if (IS_SET(act_flags, SMAUG_EX_SWIM)) then
						SET_BIT(ex.flags, EX_SWIM);

					if (IS_SET(act_flags, SMAUG_EX_PICKPROOF)) then
						SET_BIT(ex.flags, EX_PICKPROOF);

					if (IS_SET(act_flags, SMAUG_EX_FLY)) then
						SET_BIT(ex.flags, EX_FLY);

					if (IS_SET(act_flags, SMAUG_EX_CLIMB)) then
						SET_BIT(ex.flags, EX_CLIMB);

					if (IS_SET(act_flags, SMAUG_EX_PORTAL)) then
						SET_BIT(ex.flags, EX_PORTAL);

					if (IS_SET(act_flags, SMAUG_EX_BASHPROOF)) then
						SET_BIT(ex.flags, EX_NOBREAK);

					if (IS_SET(act_flags, SMAUG_EX_NOMOB)) then
						SET_BIT(ex.flags, EX_NOMOB);

					tmp := af.readInteger();
					ex.vnum := af.readInteger();
					end
				else
				if (s = 'E') then
					begin
					// keyword(s)
					s := af.readLine();

					// description
					repeat
						s := af.readLine();
					until (s = '~');
					end;
				until (s = 'S');
				end;
			until (s = '#0')
		else
		if (s = '#MOBILES') then
			repeat
			s := af.readLine();

			if (s <> '#0') then
				begin
				npcindex := GNPCIndex.Create;
				npc_list.insertLast(npcindex);

				// vnum
				npcindex.vnum := strtoint(right(s, '#'));

				// name and short name
				s := af.readLine();
				s := af.readLine();

				npcindex.name := hash_string(left(s, '~'));
				npcindex.short := npcindex.name;

				// long name
				g := '';
				repeat
					s := af.readLine();

					if (s <> '~') then
						g := g + s + #13#10;
				until (s = '~');

				if (g[length(g) - 2] = '.') then
					delete(g, length(g), 1);

				npcindex.long := hash_string(g);

				// description
				repeat
					s := af.readLine();
				until (s = '~');

				// act_flags aff_flags alignment type
				act_flags := af.readCardinal();
				npcindex.act_flags := 0;

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

				act_flags := af.readCardinal();
				npcindex.alignment := af.readInteger();
				typ := af.readToken();

				// level hitroll armor hitdie damdie
				npcindex.level := af.readInteger();
				npcindex.hitroll := af.readInteger();
				npcindex.natural_ac := af.readInteger();
				s := af.readToken();
				s := af.readToken();

				// gold xp
				npcindex.gold := af.readInteger();
				act_flags := af.readInteger();

				// position position sex
				act_flags := af.readInteger();
				act_flags := af.readInteger();
				npcindex.sex := af.readInteger();

				if (typ = 'C') then
					begin
					// str int wis dex con cha lck
					act_flags := af.readInteger();
					act_flags := af.readInteger();
					act_flags := af.readInteger();
					act_flags := af.readInteger();
					act_flags := af.readInteger();
					act_flags := af.readInteger();
					act_flags := af.readInteger();

					// sav1 sav2 sav3 sav4 sav5
					act_flags := af.readInteger();
					act_flags := af.readInteger();
					act_flags := af.readInteger();
					act_flags := af.readInteger();
					act_flags := af.readInteger();

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
			until (s = '#0')
		else
		if (s = '#RANGES') then
			begin
			are.r_lo := af.readInteger();
			are.r_hi := af.readInteger();
			are.m_lo := af.readInteger();
			are.m_hi := af.readInteger();
			s := af.readLine;
			end
		else   
		if (s = '#RESETS') then
			repeat
				s := af.readLine;

				if (s <> 'S') then
					begin
					reset := GReset.Create;
					//reset.area := are;
					are.resets.insertLast(reset);

					reset.reset_type := left(s, ' ')[1];
					s := right(s, ' ');

					s := right(s, ' ');
					arg1 := strtointdef(left(s, ' '), 0);

					s := right(s, ' ');
					arg2 := strtointdef(left(s, ' '), 0);

					s := right(s, ' ');
					arg3 := strtointdef(left(s, ' '), 0);

					case reset.reset_type of
					'M' : begin
					reset.arg1 := arg1;
					reset.arg2 := arg3;
					reset.arg3 := arg2;
					end;
					'D' : begin
					reset.arg1 := arg1;
					reset.arg2 := arg2 + 1;
					reset.arg3 := arg3;
					end;
					else
						begin
						reset.arg1 := arg1;
						reset.arg2 := arg2;
						reset.arg3 := arg3;
						end;
					end;
					end;
			until (s = 'S');
		end;

	af.Free;
	
	writeConsole('Saving to: ' + ParamStr(2));

	are.save(ParamStr(2));

	writeConsole('All done.');
	
	cleanupAreas();
	cleanupDebug();
end.
