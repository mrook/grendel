// $Id: constants.pas,v 1.41 2001/10/05 15:48:28 ***REMOVED*** Exp $

unit constants;

interface

const 
{$IFDEF LINUX}
  version_number = 'v0.4.1-linux';
{$ELSE}
  version_number = 'v0.4.1';
{$ENDIF}
  version_info = 'The Grendel Project - A Win32 MUD Server';
  version_copyright = 'Copyright (c) 2000,2001 by Michiel Rook';

{$IFDEF LINUX}
  PathDelimiter = '/';
{$ELSE}
  PathDelimiter = '\';
{$ENDIF}

  SystemDir = 'system' + PathDelimiter;

{ misc. bitvectors }
const BV00=1 shl 0;
      BV01=1 shl 1;
      BV02=1 shl 2;
      BV03=1 shl 3;
      BV04=1 shl 4;
      BV05=1 shl 5;
      BV06=1 shl 6;
      BV07=1 shl 7;
      BV08=1 shl 8;
      BV09=1 shl 9;
      BV10=1 shl 10;
      BV11=1 shl 11;
      BV12=1 shl 12;
      BV13=1 shl 13;
      BV14=1 shl 14;
      BV15=1 shl 15;
      BV16=1 shl 16;
      BV17=1 shl 17;
      BV18=1 shl 18;
      BV19=1 shl 19;
      BV20=1 shl 20;
      BV21=1 shl 21;
      BV22=1 shl 22;
      BV23=1 shl 23;
      BV24=1 shl 24;
      BV25=1 shl 25;
      BV26=1 shl 26;
      BV27=1 shl 27;
      BV28=1 shl 28;
      BV29=1 shl 29;
      BV30=1 shl 30;
      BV31=1 shl 31;
      { certainly don't use more than 32, for that won't fit in
        a dword: you probably don't want to use BV31 when using
        Delphi 2/3 }

{ system maxima }
const MAX_RECEIVE = 2048;
      MAX_WEAR = 25;
      MAX_TRADE = 5;

{ Wear constants }
const WEAR_NULL = 0;
      WEAR_RFINGER=1;
      WEAR_LFINGER=2;
      WEAR_NECK1=3;
      WEAR_NECK2=4;
      WEAR_BODY=5;
      WEAR_HEAD=6;
      WEAR_LEGS=7;
      WEAR_FEET=8;
      WEAR_HANDS=9;
      WEAR_ARMS=10;
      WEAR_SHIELD=11;
      WEAR_ABOUT=12;
      WEAR_WAIST=13;
      WEAR_RWRIST=14;
      WEAR_LWRIST=15;
      WEAR_FLOAT=16;
      WEAR_RHAND=17;                { primary hand }
      WEAR_LHAND=18;                { secondary hand, and dual wielding hand }
      WEAR_RSHOULDER=19;
      WEAR_LSHOULDER=20;
      WEAR_FACE=21;
      WEAR_REAR=22;
      WEAR_LEAR=23;
      WEAR_RANKLE=24;
      WEAR_LANKLE=25;
      WEAR_EYES=26;

const ARMOR_HAC=1;
      ARMOR_BAC=2;
      ARMOR_AAC=3;
      ARMOR_LAC=4;

{ Levels }
const LEVEL_START=1;
      LEVEL_MAX=500;
      LEVEL_IMMORTAL=990;
      LEVEL_MAX_IMMORTAL=1000;

      LEVEL_GUEST     =990;             { guest immortal }
      LEVEL_APPRENTICE=991;             { learning to be immo }
      LEVEL_AVATAR    =992;             { idem, more power }
      LEVEL_KNIGHT    =993;             { builder }
      LEVEL_LORD      =994;             { builder, more power }
      LEVEL_GUARDIAN  =995;             { player manager }
      LEVEL_DEMIGOD   =996;             { player manager, more power }
      LEVEL_LESSERGOD =997;             { system manager/coder }
      LEVEL_GOD       =998;             { high level manager }
      LEVEL_HIGHGOD   =999;             { top level manager }
      LEVEL_RULER     =1000;            { director }

      LEVEL_BUILD=LEVEL_KNIGHT;

      IMM_Types:array[LEVEL_GUEST..LEVEL_RULER] of string=('Guest',
                                                          'Apprentice',
                                                          'Avatar',
                                                          'Knight',
                                                          'Lord',
                                                          'Guardian',
                                                          'Demi God',
                                                          'Lesser God',
                                                          'God',
                                                          'High God',
                                                          'Ruler of All');

const hp_perc:array[0..5] of string=
      ('dead','awful','bad','hurt','good','fine');

const mv_perc:array[0..5] of string=
      ('exhausted','very tired','tired','beat','winded','energetic');

const sex_nm:array[0..2] of string=('him','her','it');
      sex_bm:array[0..2] of string=('his','her','its');
      sex_pm:array[0..2] of string=('he','she','it');

{ conditions }
const COND_DRUNK=1;                  { alcohol }
      COND_FULL=2;                   { eating }
      COND_THIRST=3;                 { drinking }
      COND_CAFFEINE=4;               { coffee/cola }
      COND_HIGH=5;                   { weed }
      COND_MAX=6;

      MAX_COND = 125;

      POS_DEAD=0;
      POS_MORTAL=1;
      POS_INCAP=2;
      POS_STUNNED=3;
      POS_SLEEPING=4;
      POS_MEDITATE=5;
      POS_RESTING=6;
      POS_SITTING=7;
      POS_FIGHTING=8;
      POS_STANDING=9;
      POS_CASTING=10;
      POS_SEARCHING=11;
      POS_BACKSTAB=12;
      POS_CIRCLE=13;
      POS_BASHED=14;

{ spell affects }
const AFF_BLIND = BV00;
      AFF_INVISIBLE = BV01;
      AFF_DETECT_INVIS = BV02;
      AFF_DETECT_HIDDEN = BV03;
      AFF_SANCTUARY = BV04;
      AFF_INFRAVISION = BV05;
      AFF_POISON = BV06;
      AFF_LEVITATION = BV07;
      AFF_BERSERK = BV08;
      AFF_AQUA_BREATH = BV09;
      AFF_PLAGUE = BV10;
      AFF_HIDE = BV11;
      AFF_SNEAK = BV12;
      AFF_ENCHANT = BV13;             { magical attacks }
      AFF_FLYING = BV14;              

{ PC status flags}
const PLR_NPC=BV00;
//      PLR_FLYCAP=BV01;          { can fly }
      PLR_WIZINVIS=BV02;        { is wizinvis? }
      PLR_LINKLESS=BV04;        { linkless dude? }
      PLR_LOADED=BV05;          { loaded up by immo }
      PLR_DENY=BV06;            { denied? }
      PLR_FROZEN=BV07;          { frozen }
      PLR_SILENCED=BV08;        { silenced }
      PLR_HOLYWALK = BV09;      { walk thru anything }
      PLR_HOLYLIGHT = BV10;     { see anything }
      PLR_CLOAK = BV11;	{ immortals don't get logged }

{ Config flags }
const CFG_ASSIST=BV01;
      CFG_AUTOLOOT=BV02;
      CFG_AUTOSAC=BV03;
      CFG_AUTOSCALP=BV04;
      CFG_BLANK=BV05;           { blank line }
      CFG_BRIEF=BV06;           { brief descriptions }
      CFG_ANSI=BV07;            { receive ansi }
      CFG_PAGER=BV08;           { see pager }
      CFG_AUTOPEEK = BV09;      { peek automatically on look }

{ NPC/PC flags }
const ACT_AGGRESSIVE=BV02;      { aggressive NPC? }
      ACT_SENTINEL=BV03;        { stays in room, guard }
      ACT_SCAVENGER=BV04;       { picks up trash }
      ACT_STAY_AREA=BV05;       { stays in area }
      ACT_HUNTING=BV06;         { is hunting a PC now? }
      ACT_FASTHUNT=BV07;        { fast hunting cap? }
      ACT_MOBINVIS=BV08;        { equal to wizinvis }
      ACT_TEACHER=BV09;         { can NPC teach PC's? }
      ACT_BANKER=BV10;          { a banker? }
      ACT_SPIRIT=BV11;          { spirit -> non-magic attacks fail }
      ACT_NOBASH=BV12;          { cannot be bashed (dragon?) }
      ACT_SHOPKEEP=BV13;        { shop keeper }
      ACT_IMMORTAL=BV14;        { immortal NPC }
      ACT_PROTO = cardinal(BV31);

{ Item Types }
const ITEM_WEAPON=1;
      ITEM_ARMOR=2;
      ITEM_FOOD=3;
      ITEM_DRINK=4;
      ITEM_LIGHT=5;
      ITEM_TRASH=6;
      ITEM_MONEY=7;
      ITEM_SPECIAL=8;
      ITEM_GEM=9;
      ITEM_CONTAINER=10;
      ITEM_CORPSE=11;
      ITEM_FOUNTAIN=12;
      ITEM_BLOOD=13;
      ITEM_PORTAL=14;
      ITEM_KEY=15;

{ Wear constants }
const eq_string:array[1..MAX_WEAR] of string=
      ('on left finger','on right finger','around neck','around neck',
       'on body','on head','on legs','on feet','on hands','on arms',
       'as shield','about body','around waist','around left wrist',
       'around right wrist','near head','in primary hand','in secondary hand',
       'on left shoulder','on right shoulder','on face',
       'in left ear','in right ear','on left ankle','on right ankle');

// do NOT just change the order of these exit constants; used in a couple for-loops
{ directions }
const DIR_NORTH=1;
      DIR_EAST=2;
      DIR_SOUTH=3;
      DIR_WEST=4;
      DIR_DOWN=5;
      DIR_UP=6;
      DIR_SOMEWHERE=7;

{ headings and inverted headings }
const headings :array[DIR_NORTH..DIR_SOMEWHERE] of string=('north','east','south','west','down','up','somewhere');
      headingsi:array[DIR_NORTH..DIR_SOMEWHERE] of string=('the south','the west','the north','the east','above','below','somewhere');
      headings_short :array[DIR_NORTH..DIR_SOMEWHERE] of string=('n','e','s','w','d','u','?');
      headings_short_i :array[DIR_NORTH..DIR_SOMEWHERE] of string=('s','w','n','e','u','d','?');
      dir_inv:array[DIR_NORTH..DIR_SOMEWHERE] of integer=(DIR_SOUTH,DIR_WEST,
                                                          DIR_NORTH,DIR_EAST,
                                                          DIR_UP,DIR_DOWN,
                                                          DIR_SOMEWHERE);

{ standard room vnums }
const ROOM_VNUM_GOOD_PORTAL=0;
      ROOM_VNUM_EVIL_PORTAL=1;
      ROOM_VNUM_IMMORTAL_PORTAL=10;

{ room flags }
const ROOM_DARK=BV00;           { can't see without light }
      ROOM_DEATH=BV01;          { death trap on entering }
      ROOM_NOMOB=BV02;          { not for mobs }
      ROOM_INDOORS=BV03;        { indoors, whatever sector type says }
      ROOM_GOOD=BV04;           { only for good aligned }
      ROOM_EVIL=BV05;           { only for evil aligned }
      ROOM_NOCAST=BV06;         { magic not allowed }
      ROOM_TUNNEL=BV07;         { tunnel -> big trolls won't fit }
      ROOM_PRIVATE=BV08;        { private room -> only for immortals/builders }
      ROOM_SAFE=BV09;           { safe -> no fighting allowed }
      ROOM_SOLITARY=BV10;       { only one person allowed at a time }
      ROOM_NORECALL=BV11;       { can't recall }
      ROOM_NODROPALL=BV12;      { can't drop all }
      ROOM_NOSUMMON=BV13;       { can't summon players/mobs }
      ROOM_CLANSTORE=BV14;      { clan store room }
      ROOM_TELEPORT=BV15;       { teleporting room }
      ROOM_NOFLOOR=BV16;        { no floor -> when not flying, ch falls down }
      ROOM_MANAROOM=BV17;       { manaroom, fast magic regeneration }
      ROOM_NOTRADE=BV18;        { no dropping, no giving, no getting }
      ROOM_PROTO = cardinal(BV31);

const room_flags:array[0..30] of string = ('dark','death','nomob',
                                        'indoors','good','evil',
                                        'nocast','tunnel','private',
                                        'safe','solitary','norecall',
                                        'nodropall','nosummon',
                                        'clanstore','teleport',
                                        'nofloor','manaroom','bv18',
                                        'bv19','bv20','bv21','bv22',
                                        'bv23','bv24','bv25','bv26',
                                        'bv27','bv28','bv29','proto');
                                        
{ sector types }
const SECT_INSIDE=1;
      SECT_CITY=2;
      SECT_FIELD=3;
      SECT_FOREST=4;
      SECT_HILLS=5;
      SECT_MOUNTAIN=6;
      SECT_DESERT=7;
      SECT_WATER_SWIM=8;
      SECT_WATER_NOSWIM=9;
      SECT_UNDERWATER=10;
      SECT_OCEANFLOOR=11;
      SECT_UNDERGROUND=12;
      SECT_AIR=13;
      SECT_NOPASSAGE=14;
      SECT_UNKNOWN=15;
      SECT_MAX=16;

const sector_types:array[1..15] of string=('inside','city','field',
                                          'forest','hills','mountain',
                                          'desert','waterswim','waternoswim',
                                          'underwater','oceanfloor',
                                          'underground','air',
                                          'nopassage','unknown');

const movement_loss:array[SECT_INSIDE..SECT_MAX-1] of integer=
      (1,2,2,3,4,6,5,4,1,6,7,4,10,2,5);

{ exit flags }
const EX_ISDOOR=BV00;
      EX_CLOSED=BV01;
      EX_LOCKED=BV02;
      EX_PICKPROOF=BV03;
      EX_SECRET=BV04;
      EX_SWIM=BV05;
      EX_FLY=BV06;
      EX_CLIMB=BV07;
      EX_PORTAL=BV08;
      EX_NOBREAK=BV09;
      EX_NOMOB=BV10;
      EX_ENTER=BV11;
      EX_UNDERWATER=BV12;

const exit_flags:array[0..12] of string = ('isdoor','closed','locked',
                                        'pickproof','secret','swim',
                                        'fly','climb','portal',
                                        'nobreak','nomob','enter',
                                        'underwater');

{ area flags }
const AREA_NORESET=BV00;
      AREA_NOPC=BV01;
      AREA_PROTO=BV02;

{ object flags }
const OBJ_NOPICKUP=BV00;
      OBJ_GLOW=BV01;
      OBJ_HUM=BV02;
      OBJ_ANTI_GOOD=BV03;
      OBJ_ANTI_EVIL=BV04;
      OBJ_LOYAL=BV05;
      OBJ_NOREMOVE=BV06;
      OBJ_NODROP=BV07;
      OBJ_CLANOBJECT=BV08;
      OBJ_HIDDEN=BV09;
      OBJ_POISON=BV10;
      OBJ_MISSILE=BV11;
      OBJ_NOSAC=BV12;
      OBJ_NODECAY=BV13;
      OBJ_PROTO = cardinal(BV31);

{ weather }
const SUN_DAWN=1;
      SUN_RISE=2;
      SUN_LIGHT=3;
      SUN_SET=4;
      SUN_MOON=5;
      SUN_DARK=6;

      SKY_CLOUDLESS=1;
      SKY_CLOUDY=2;
      SKY_RAINING=3;
      SKY_SNOWING=4;
      SKY_STORMING=5;
      SKY_LIGHTNING=6;

      sky_types:array[SKY_CLOUDLESS..SKY_LIGHTNING] of string=(
                'cloudless','cloudy','raining','snowing','storming','lightning');

const CPULSE_PER_SEC = 4;
      CPULSE_VIOLENCE = 2 * CPULSE_PER_SEC;
      CPULSE_TICK = 60 * CPULSE_PER_SEC;
      CPULSE_GAMEHOUR = 25 * CPULSE_PER_SEC;
      CPULSE_AUCTION = 16 * CPULSE_PER_SEC;
      CPULSE_GAMETIME = 150 * CPULSE_PER_SEC;

      IDLE_NAME = 480;                              // disconnect after 2 mins when not responding at login
      IDLE_NOT_PLAYING = 1200;                      // disconnect after 5 mins when not responding somewhere in nanny()
      IDLE_PLAYING = 3600;                          // disconnect after 15 mins when playing
      IDLE_LINKDEAD = 300 / CPULSE_GAMEHOUR;       // quit ld chars after 15 mins

{ Connect states for sockets }
const CON_PLAYING=0;
      CON_ACCEPTED=1;
      CON_NAME=2;
      CON_PASSWORD=3;
      CON_NEW_NAME=4;
      CON_NEW_PASSWORD=5;
      CON_NEW_SEX=6;
      CON_NEW_RACE=7;
      CON_NEW_STATS=8;
      CON_PRESS_ENTER=9;
      CON_MOTD=10;
      CON_EDITING=11;
      CON_LOGGED_OUT=12;
      CON_CHECK_PASSWORD=13;
      CON_EDIT_HANDLE=14;
      CON_MAX=14;

      con_states:array[CON_PLAYING..CON_MAX] of string =(
                'CON_PLAYING','CON_ACCEPTED','CON_NAME',
                'CON_PASSWORD','CON_NEW_NAME','CON_NEW_PASSWORD',
                'CON_NEW_SEX','CON_NEW_RACE','CON_NEW_STATS',
                'CON_PRESS_ENTER','CON_MOTD','CON_EDITING',
                'CON_LOGGED_OUT','CON_CHECK_PASSWORD','CON_EDIT_HANDLE');

{ Bulletinboards - Nemesis }
const BOARD1     = 1;
      BOARD2     = 2;
      BOARD3     = 3;
      BOARD_NEWS = 4;
      BOARD_IMM  = 5;
      BOARD_MAX  = 6;

      board_names : array [BOARD1..BOARD_MAX-1] of string =
      ('General', 'Bugs', 'Quests', 'News', 'Immortal');

      board_descr : array [BOARD1..BOARD_MAX-1] of string =
      ('General discussion', 'Bugs, Typos', 'Information about quests', 'News from the Immortals', 'Immortal business');


{ character substates }
const SUB_NONE        = 0;
      SUB_PLAYER_DESC = 1;
      SUB_ROOM_DESC   = 2;
      SUB_NOTE        = 3;
      SUB_SUBJECT     = 4;

{ act targets }
const TO_ROOM=0;
      TO_VICT=1;
      TO_NOTVICT=2;
      TO_CHAR=3;
      TO_ALL=4;
      TO_IMM=5;

{ act colors }
const AT_BLACK=0;
      AT_DBLUE=1;
      AT_DGREEN=2;
      AT_DCYAN=3;
      AT_DRED=4;
      AT_PURPLE=5;
      AT_BROWN=6;
      AT_GREY=7;
      AT_DGREY=8;
      AT_BLUE=9;
      AT_GREEN=10;
      AT_CYAN=11;
      AT_RED=12;
      AT_PINK=13;
      AT_YELLOW=14;
      AT_WHITE=15;
      AT_BLINK=16;

      AT_CORPSE=AT_DRED;
      AT_ECHO=AT_YELLOW;
      AT_FIGHT=AT_WHITE;
      AT_FIGHT_HIT=AT_CYAN;
      AT_FIGHT_YOU=AT_PINK;
      AT_KILLED=AT_WHITE;
      AT_NPC=AT_CYAN;
      AT_OBJ=AT_DCYAN;
      AT_PC=AT_PINK;
      AT_PRAY=AT_PINK;
      AT_REPORT=AT_GREY;
      AT_SAY=AT_WHITE;
      AT_SLAY=AT_RED;
      AT_SOCIAL=AT_GREY;
      AT_SPELL=AT_BROWN;
      AT_SUGGEST=AT_CYAN;
      AT_TELL=AT_DGREEN;

      AT_LOG=AT_YELLOW;

// these values MUST correspond with the ChannelData Name fields in system\channels.xml
const
    CHANNEL_LOG = 'LOG';
    CHANNEL_ALL = 'ALL';
    CHANNEL_CHAT = 'CHAT';
    CHANNEL_IMMTALK = 'IMMTALK';
    CHANNEL_RAID = 'WARTALK';
    CHANNEL_AUCTION = 'AUCTALK';
    CHANNEL_CLAN = 'CLANTALK';
    CHANNEL_BABBEL = 'BABBEL';          { dutch only channel ;) }
    CHANNEL_THUNDER = 'THUNDER';
    CHANNEL_YELL = 'YELL';
    CHANNEL_GROUP = 'GROUPTELL';

    CHANNEL_HISTORY_MAX = 20; // max. lines in channel history
     
{ battleground status }
const BG_NOJOIN=0;              { ch will not join bg on start }
      BG_JOIN=1;                { ch will join bg on start }
      BG_PARTICIPATE=2;         { ch is participating in bg }

{ skill types }
const SKILL_SPELL=1;
      SKILL_SKILL=2;
      SKILL_WEAPON=3;

{ liquids }
type GLiquid = record
       name : string;
       affect : array[COND_DRUNK..COND_CAFFEINE] of integer;
     end;

const LIQ_WATER=1;
      LIQ_BEER=2;
      LIQ_ALE=3;
      LIQ_WHISKEY=4;
      LIQ_VODKA=5;
      LIQ_WINE=6;
      LIQ_JUICE=7;
      LIQ_MILK=8;
      LIQ_TEA=9;
      LIQ_COFFEE=10;
      LIQ_COLA=11;
      LIQ_SPECIAL=12;   { Grimlords Special Brew  :P }
      LIQ_MAX=13;

const liq_types:array[LIQ_WATER..LIQ_SPECIAL] of GLiquid =((name:'water';affect:(0,0,25,0)),
                                                         (name:'beer';affect:(5,0,20,0)),
                                                         (name:'ale';affect:(7,0,20,0)),
                                                         (name:'whiskey';affect:(10,0,15,0)),
                                                         (name:'vodka';affect:(12,0,15,0)),
                                                         (name:'wine';affect:(7,0,18,0)),
                                                         (name:'juice';affect:(0,0,22,0)),
                                                         (name:'milk';affect:(0,0,23,0)),
                                                         (name:'tea';affect:(0,0,22,4)),
                                                         (name:'coffee';affect:(0,0,20,10)),
                                                         (name:'cola';affect:(0,0,22,7)),
                                                         (name:'special brew';affect:(18,0,15,0)));

{ Xenon 22/Apr/2001: if you change any of these TARGET_* fields,
                     **ALSO** have a look at do_spells()! Else
                     do_spells might start bugging *severely*. }
{ spell targets }
const
      TARGET_OFF_ATTACK=1;         { attack spell }
      TARGET_OFF_AREA=2;           { area attack spell }
      TARGET_DEF_SELF=3;           { only cast this on yourself }
      TARGET_DEF_SINGLE=4;         { defensive spell (e.g. heal) }
      TARGET_DEF_AREA=5;           { area defensive }
      TARGET_DEF_WORLD=6;          { world defensive (e.g. summon) }
      TARGET_OBJECT=7;             { ignore target (for object spells) }

{ return types }
const RESULT_NONE=0;
      RESULT_CHARDIED=1;
      RESULT_VICTDIED=2;
      RESULT_CHARBASHED=3;
      RESULT_BUG=4;

{ timer types }
const TIMER_GAME = 0;                { game timer, used internally }
      TIMER_COMBAT=1;                { combat timer }
      TIMER_SEARCH=2;                { search }
      TIMER_BACKSTAB=3;              { backstab }
      TIMER_CIRCLE=4;                { circle }
      TIMER_CAST=5;                  { casting timer }
      TIMER_TRACK=6;                 { tracking }

      TIMER_MAX = TIMER_TRACK;

      timer_names : array[TIMER_GAME..TIMER_MAX] of string =
      ('game', 'combat', 'search', 'backstab', 'circle', 'cast', 'track');

{ combat types }
const COMBAT_MOBILE=0;               { mobile/same align }
      COMBAT_SEEN=1;                 { opp. align seen }
      COMBAT_PKILL=2;                { pkill opp. align }

      { timer values for combat types (in ticks) }
      combat_timer:array[COMBAT_MOBILE..COMBAT_PKILL] of integer=(200,75,350);

{ vnum's of regularly used objects, like money }
const OBJ_VNUM_GOOD_PORTAL=0;
      OBJ_VNUM_EVIL_PORTAL=1;
      OBJ_VNUM_CORPSE=10;
      OBJ_VNUM_WITHDRAW=11;
      OBJ_VNUM_BLOODTRAIL=12;

{ cleaning thread flags }
const CLEAN_BOOT_MSG=1;
      CLEAN_MUD_STOP=2;
      CLEAN_AUTOSAVE=3;
      CLEAN_STOP=10;

{ modifiers }
const MOD_HP     = 1;
      MOD_MAX_HP = 2;
      MOD_MV     = 3;
      MOD_MAX_MV = 4;
      MOD_MA     = 5;
      MOD_MAX_MA = 6;

{ consider constants }
const cons_perc_you : array[0..5] of string=(
                                'This will be a very close battle.',
                                'You will probably win.',
                                'You will kill $N with ease.',
                                'You will have no problems with $N.',
                                'You will rip $N apart.',
                                'You will laugh over $N''s bodyparts!');

const cons_perc_oppnt:array[0..5] of string=(
                                '$N could win.',
                                '$N will probably win.',
                                '$N will kill you at leisure.',
                                '$N will have no problems with you.',
                                '$N will laugh as $E rips you apart!',
                                '$N will EAT you alive!');

{ Mob program types }
const MPROG_ACT=BV01;           { mob reacts to act from ch}
      MPROG_GREET=BV02;         { mob greets ch }
      MPROG_ALLGREET=BV03;      { mob greets ALL, even invis }
      MPROG_ENTER=BV04;         { mob enters a room }
      MPROG_DEATH=BV05;         { mob dies }
      MPROG_BRIBE=BV06;         { mob is bribed }
      MPROG_FIGHT=BV07;         { mob is fighting }
      MPROG_RAND=BV08;          { random trigger, update_chars }
      MPROG_BLOCK=BV09;         { mob is blocking an exit }
      MPROG_RESET=BV10;         { mob is reset }
      MPROG_GIVE=BV11;          { mob gets object }
                                
{ constants for do_map() in cmd_build.inc }
const
  MAP_SIZE_X = 39;
  MAP_SIZE_Y = 9;

type GApplyTypes = (APPLY_NONE, APPLY_STR, APPLY_DEX, APPLY_INT, APPLY_WIS, APPLY_CON,
  APPLY_HP, APPLY_MAX_HP, APPLY_MV, APPLY_MAX_MV, APPLY_MANA, APPLY_MAX_MANA,
  APPLY_AC, APPLY_APB, APPLY_AFFECT, APPLY_REMOVE,
  APPLY_STRIPNAME, APPLY_FULL, APPLY_THIRST, APPLY_DRUNK, APPLY_CAFFEINE,

(*  APPLY_HITROLL, APPLY_DAMROLL, APPLY_SAVING_POISON, APPLY_SAVING_ROD,
  APPLY_SAVING_PARA, APPLY_SAVING_BREATH, APPLY_SAVING_SPELL,
  APPLY_BACKSTAB, APPLY_PICK, APPLY_TRACK,
  APPLY_STEAL, APPLY_SNEAK, APPLY_HIDE, APPLY_DODGE,
  APPLY_PEEK, APPLY_SCAN, APPLY_GOUGE, APPLY_SEARCH, APPLY_DISARM,
  APPLY_KICK, APPLY_PARRY, APPLY_BASH, APPLY_STUN, APPLY_PUNCH, APPLY_CLIMB,
  APPLY_GRIP, APPLY_SCRIBE, APPLY_BREW,
  APPLY_EMOTION, APPLY_MENTALSTATE, APPLY_STRIPSN, APPLY_REMOVE, APPLY_DIG,
  APPLY_RECURRINGSPELL, APPLY_CONTAGIOUS, APPLY_EXT_AFFECT, APPLY_ODOR,
  APPLY_ROOMFLAG, APPLY_SECTORTYPE, APPLY_ROOMLIGHT, APPLY_TELEVNUM,
  APPLY_TELEDELAY, *)
  MAX_APPLY_TYPE);

// Drunkness strings - Nemesis - Constants.pas
const drunkbuf : array[0..25] of string =
	                    ('Zsszzsz', 'y', 'XzsZ', 'wWwWW', 'vVvvV', 'uUUu', 't', 'sSzzsss',
                             'Rrr', 'ququ', 'P', 'ooOo', 'nNn', 'mmm', 'l', 'K', 'j', 'ii',
                             'hhh', 'g', 'fff', 'e', 'D', 'ch', 'b', 'Ah');  
implementation

end.

