{
  @abstract(Configuration and other mud specific functions)
  @lastmod($Id: mudsystem.pas,v 1.40 2003/06/24 21:41:34 ***REMOVED*** Exp $)
}

unit mudsystem;

interface
uses
{$IFDEF Win32}
    Winsock2,
{$ENDIF}
{$IFDEF LINUX}
    Libc,
{$ENDIF}
    SysUtils,
    Classes,
    constants,
    strip,
    clean,
    dtypes,
    FastStringFuncs,
    util;

const BOOTTYPE_SHUTDOWN = 1;
      BOOTTYPE_REBOOT   = 2;
      BOOTTYPE_COPYOVER = 3;

type
    GTime = record
      hour, day, month, year : integer;
      sunlight : integer;
    end;

    GBoot = record
       timer : integer;
       boot_type : integer;
       started_by : pointer;
     end;

    GSystem = record
      admin_email : string;        { email address of the administration }
      mud_name : string;           { name of the MUD Grendel is serving }
      port : integer;              { port on which Grendel runs }
      port6 : integer;		         { ipv6 port on which Grendel runs }
      log_all : boolean;           { log all player activity? }
      bind_ip : integer;           { IP the server should bind to (when using multiple interfaces) }
      level_forcepc : integer;     { level to force players }
      level_log : integer;         { level to get log messages }
      lookup_hosts : boolean;      { lookup host names of clients? }
      deny_newconns : boolean;     { deny new connections? }
      deny_newplayers : boolean;   { disable 'CREATE', e.g. no new players }
      max_conns : integer;         { max. concurrent connections on this server }
      show_clan_abbrev : boolean;  { show clan name abbreviations in who list(s) }
      
      arena_start, 
      arena_end : integer;         { vnum start/end of arena (battleground) }

      user_high, user_cur : integer;
     end;

     GSocial = class
       name : string;
       char_no_arg, others_no_arg: string;
       char_found, others_found, vict_found : string;
       char_auto, others_auto : string;
       char_object : string;      // Xenon (19/Feb/2001) : for objects (e.g. 'lick rapier')
       others_object : string;
     end;

     GDamMessage = class
       msg : array[1..3] of string;
       min, max : integer;
     end;

     GBattleground = record
       prize : pointer;
       lo_range, hi_range : integer;      { level range }
       winner : pointer;               { who has won the bg }
       count : integer;                   { seconds to start, -1 for running, -2 for no bg}
     end;

     GAuction = class
       item : pointer;
       seller, buyer : pointer;
       going : integer;         { 1,2, sold}
       bid : integer;
       pulse : integer;
       start : integer;

       procedure update;

       constructor Create;
     end;

var
   system_info : GSystem;
   time_info : GTime;
   boot_info : GBoot;
   bg_info : GBattleground;

   socials : GHashTable;
   dm_msg : GDLinkedList;

   clean_thread : GCleanThread;
   timer_thread : TThread;

   auction_good, auction_evil : GAuction;

   banned_masks, banned_names : TStringList;


var
  OldExit : pointer;
  LogFile : textfile;

  { system data }
  BootTime : TDateTime;
  mobs_loaded:integer;
  online_time:string;
  status : THeapStatus;
  mud_booted : boolean = false;
  grace_exit : boolean = false;
  boot_type : integer = BOOTTYPE_SHUTDOWN;


procedure writeDirect(text : string);
procedure writeLog(text : string);
procedure bugreport(func, pasfile, bug : string);
procedure calculateonline;

procedure load_system;
procedure save_system;
function isMaskBanned(host : string) : boolean;
function isNameBanned(name : string) : boolean;

procedure load_damage;

procedure load_socials;

function findSocial(cmd : string) : GSocial;
function checkSocial(c : pointer; cmd, param : string) : boolean;

procedure loadMudState();
procedure saveMudState();

procedure initSystem();
procedure cleanupSystem();

implementation

uses
    mudthread,
    chars,
    area,
    fsys,
    conns,
    console,
    Channels,
    RegExpr;

procedure writeDirect(text : string);
begin
  writeLog(text);

{$IFDEF CONSOLEBUILD}
  writeln(text);
{$ENDIF}
{$IFDEF LINUX}
  writeln(text);
{$ENDIF}
end;

procedure writeLog(text : string);
begin
  text := '[' + FormatDateTime('yyyymmdd hh:nn:ss', Now) + '] [LOG] ' + text;

  if (TTextRec(logfile).mode = fmOutput) then
    begin
    system.writeln(logfile, text);
    system.flush(logfile);
    end;
end;

procedure bugreport(func, pasfile, bug : string);
begin
  writeConsole('[BUG] ' + func + ' -> ' + bug);

{  write_direct('[Extended error information]');
  write_direct('Location:    function ' + func + ' in ' + pasfile);
  write_direct('Description: ' + desc);
  write_direct(''); }
end;

procedure calculateonline;
var tim : TDateTime;
    days, hours, minutes : integer;
begin
  tim := Now;

  days := DiffDays(BootTime, Now);
  hours := DiffHours(BootTime, Now);
  minutes := DiffMinutes(BootTime, Now);

  dec(minutes, 60 * hours);
  dec(hours, 24 * days);

  online_time := inttostr(days) + ' day(s), ' +
                 inttostr(hours) + ' hours(s), ' +
                 inttostr(minutes) + ' minutes(s)';
end;

procedure load_system;
var
   s,g : string;
   af : GFileReader;
begin
  { first some defaults }
  system_info.mud_name := 'Grendel';
  system_info.admin_email := 'admin@localhost';

  system_info.port := 4444;
  system_info.port6 := 3333;
  system_info.lookup_hosts := false;
  system_info.deny_newconns := false;
  system_info.deny_newplayers := false;
  system_info.level_forcepc := LEVEL_HIGHGOD;
  system_info.level_log := LEVEL_GOD;
  system_info.bind_ip := INADDR_ANY;
  system_info.max_conns := 200;

  try
    af := GFileReader.Create(SystemDir + 'sysdata.dat');
  except
    bugreport('load_system', 'mudsystem.pas', 'could not open system\sysdata.dat.');
    exit;
  end;

  repeat
    s := af.readLine;

    g := uppercase(left(s,':'));

    if g='PORT' then
      system_info.port:=strtoint(right(s,' '))
    else
    if (g = 'PORT6') then
      system_info.port6 := strtoint(right(s, ' '))
    else
    if g='NAME' then
      system_info.mud_name := right(s,' ')
    else
    if g='EMAIL' then
      system_info.admin_email := right(s,' ')
    else
    if g='HOSTLOOKUP' then
      system_info.lookup_hosts:=strtoint(right(s,' '))<>0
    else
    if g='DENYNEWCONNS' then
      system_info.deny_newconns:=strtoint(right(s,' '))<>0
    else
    if g='DENYNEWPLAYERS' then
      system_info.deny_newplayers:=strtoint(right(s,' '))<>0
    else
    if g='LEVELFORCEPC' then
      system_info.level_forcepc:=strtoint(right(s,' '))
    else
    if g='LEVELLOG' then
      system_info.level_log:=strtoint(right(s,' '))
    else
    if g='BINDIP' then
      system_info.bind_ip:=inet_addr(pchar(right(s,' ')))
    else
    if (g = 'MAXCONNS') then
      system_info.max_conns := strtoint(right(s, ' '))
    else
    if (g = 'ARENASTART') then
      system_info.arena_start := strtoint(right(s, ' '))
    else
    if (g = 'ARENAEND') then
      system_info.arena_end := strtoint(right(s, ' '))
    else
    if (g = 'SHOWCLANABBREV') then
      system_info.show_clan_abbrev := strtoint(right(s, ' ')) <> 0;
  until (s = '$') or (af.eof);

  af.Free;

  try
    af := GFileReader.Create(SystemDir + 'bans.dat');
  except
    bugreport('load_system', 'mudsystem.pas', 'could not open system\bans.dat');
    exit;
  end;

  repeat
    s := af.readLine;

    if (s <> '$') then
      banned_masks.add(s);
  until (s = '$') or (af.eof);

  af.Free;

  try
    af := GFileReader.Create(SystemDir + 'names.dat');
  except
    bugreport('load_system', 'mudsystem.pas', 'could not open system\names.dat');
    exit;
  end;

  repeat
    s := af.readLine;

    if (s <> '$') then
      banned_names.add(lowercase(s));
  until (s = '$') or (af.eof);

  af.Free;
end;

procedure save_system;
var
  af : GFileWriter;
  t : TInAddr;
  a : integer;
begin
  t.s_addr := system_info.bind_ip;

  try
    af := GFileWriter.Create(SystemDir + 'sysdata.dat');
  except
    exit;
  end;

  af.writeLine('Name: ' + system_info.mud_name);
  af.writeLine('EMail: ' + system_info.admin_email);
  af.writeLine('Port: ' + IntToStr(system_info.port));
  af.writeLine('Port6: ' + IntToStr(system_info.port6));
  af.writeLine('DenyNewConns: ' + IntToStr(integer(system_info.deny_newconns)));
  af.writeLine('DenyNewPlayers: ' + IntToStr(integer(system_info.deny_newplayers)));
  af.writeLine('HostLookup: ' + IntToStr(integer(system_info.lookup_hosts)));
  af.writeLine('LevelForcePC: ' + IntToStr(system_info.level_forcepc));
  af.writeLine('LevelLog: ' + IntToStr(system_info.level_log));
  af.writeLine('BindIP: ' + inet_ntoa(t));
  af.writeLine('MaxConns: ' + IntToStr(system_info.max_conns));
  af.writeLine('ArenaStart: ' + IntToStr(system_info.arena_start));
  af.writeLine('ArenaEnd: ' + IntToStr(system_info.arena_end));
  af.writeLine('ShowClanAbbrev: ' + IntToStr(integer(system_info.show_clan_abbrev))); 
  af.writeLine('$');

  af.Free();

  try
    af := GFileWriter.Create(SystemDir + 'bans.dat');
  except
    exit;
  end;

  for a := 0 to banned_masks.count-1 do
    af.writeLine(banned_masks[a]);

  af.writeLine('$');

  af.Free();

  try
    af := GFileWriter.Create(SystemDir + 'names.dat');
  except
    exit;
  end;

  for a := 0 to banned_names.count-1 do
    af.writeLine(banned_names[a]);

  af.writeLine('$');

  af.Free();
end;

function isMaskBanned(host : string) : boolean;
var
   a : integer;
begin
  Result := false;

  for a := 0 to banned_masks.count-1 do
    if (StringMatches(host, banned_masks[a])) then
      begin
      Result := true;
      end;
end;

function isNameBanned(name : string) : boolean;
var
  a : integer;
begin
  Result := false;
  
  name := lowercase(name);
  
  // exclude any names that contains non-alpha characters
  for a := 1 to length(name) do 
    if (not (name[a] in ['a'..'z'])) then
      begin
      Result := true;
      exit;
      end;

  for a := 0 to banned_names.count-1 do
    begin
      if (ExecRegExpr(banned_names[a], name)) then
      begin
        Result := true;
        exit;
      end;
    end;
end;

// socials
procedure load_socials;
var
  af : GFileReader;
  s, g : string;
  social : GSocial;
begin
  try
    af := GFileReader.Create(SystemDir + 'socials.dat');
  except
    bugreport('load_socials', 'mudsystem.pas', 'could not open system\socials.dat');
    exit;
  end;

  repeat
    repeat
      s := af.readLine();
    until (uppercase(s) = '#SOCIAL') or (af.eof());

    if (af.eof()) then
      break;

    social := GSocial.Create;

    with social do
      repeat
      s := af.readLine();

      s := trim(s);

      g := uppercase(left(s,':'));

      if g = 'NAME' then
        name := uppercase(right(s,' '))
      else
      if g='CHARNOARG' then
        char_no_arg := right(s,' ')
      else
      if g='OTHERSNOARG' then
        others_no_arg := right(s,' ')
      else
      if g='CHARAUTO' then
        char_auto := right(s,' ')
      else
      if g='OTHERSAUTO' then
        others_auto := right(s,' ')
      else
      if g='CHARFOUND' then
        char_found := right(s,' ')
      else
      if g='VICTFOUND' then
        vict_found := right(s,' ')
      else
      if g='OTHERSFOUND' then
        others_found := right(s,' ')
      else
      if g='CHAROBJECT' then
        char_object := right(s,' ')
      else
      if g='OTHERSOBJECT' then
        others_object := right(s,' ');
      until (uppercase(s)='#END') or (af.eof());

    if (findSocial(social.name) <> nil) then
      begin
      writeConsole('duplicate social "' + social.name + '" on line ' + inttostr(af.line) + ', discarding');
      social.Free;
      end
    else
      socials.put(social.name, social);
  until (af.eof());

  af.Free();
end;

function findSocial(cmd : string) : GSocial;
begin
  Result := GSocial(socials.get(cmd));
end;

{ Xenon 19/Feb/2001 :   - added socials on objects
                        - added checks on social-strings (if empty, ignore) to fix odd behaviour i noticed }
function checkSocial(c : pointer; cmd, param : string) : boolean;
var social : GSocial;
    chance : integer;
    ch, vict : GCharacter;
    obj : GObject;
    t : integer;
begin
  social := findSocial(cmd);

  if (social = nil) then
    begin
    checkSocial := false;
    exit;
    end;

  ch := GCharacter(c);

  with social do
    begin
    vict := ch.room.findChar(ch, param);
    obj := ch.room.findObject(param);
    if (obj = nil) then
      obj := ch.findEquipment(param);
    if (obj = nil) then
      obj := ch.findInventory(param);

    if (length(param)=0) then   // no victim, e.g. 'lick'
      begin
      if (length(char_no_arg) = 0) then
        ch.sendBuffer(' ')
      else
        act(AT_SOCIAL,char_no_arg,false,ch,nil,vict,TO_CHAR);

      if (length(others_no_arg) <> 0) then
        act(AT_SOCIAL,others_no_arg,false,ch,nil,vict,TO_ROOM);
      end
    else
    if vict=ch then             // victim yourself, e.g. 'lick self'
      begin
      if (length(char_auto) = 0) then
        ch.sendBuffer(' ')
      else
        act(AT_SOCIAL,char_auto,false,ch,nil,vict,TO_CHAR);
      if (length(others_auto) <> 0) then
        act(AT_SOCIAL,others_auto,false,ch,nil,vict,TO_ROOM);
      end
    else
    if (obj <> nil) then        // victim is object, e.g. 'lick rapier'
      begin
      if (length(char_object) = 0) then
        ch.sendBuffer(' ')
      else
        act(AT_SOCIAL,char_object,false,ch,obj,nil,TO_CHAR);
      if (length(others_object) <> 0) then
        act(AT_SOCIAL,others_object,false,ch,obj,nil,TO_ROOM);
      end
    else
    if vict=nil then            // victim not there, e.g. 'lick blablablabla'
      act(AT_SOCIAL,'They are not here.',false,ch,nil,nil,TO_CHAR)
    else
    begin                     // victim, e.g. 'lick grimlord'
      if (length(char_found) = 0) then
        ch.sendBuffer(' ')
      else
        act(AT_SOCIAL,char_found,false,ch,nil,vict,TO_CHAR);
      if (length(others_found) <> 0) then
        act(AT_SOCIAL,others_found,false,ch,nil,vict,TO_NOTVICT);
      if (length(vict_found) <> 0) then
        act(AT_SOCIAL,vict_found,false,ch,nil,vict,TO_VICT);

      if ((not ch.IS_NPC)) and (vict.IS_NPC) and (vict.IS_AWAKE) then
      begin
        if (ch <> vict) then
        begin
          t := GNPC(vict).context.findSymbol('onEmoteTarget');

          if (t <> -1) then
          begin
            GNPC(vict).context.push(name);
            GNPC(vict).context.push(integer(ch));   // actor
            GNPC(vict).context.push(integer(vict)); // vict
            GNPC(vict).context.setEntryPoint(t);
            GNPC(vict).context.Execute;
          end
          else
          begin
            chance:=random(10);
            case chance of
              1,2,3,4,5,6:begin
                          if (length(vict_found) <> 0) then
                            act(AT_SOCIAL,vict_found,false,vict,nil,ch,TO_VICT);
                          if (length(others_found) <> 0) then
                            act(AT_SOCIAL,others_found,false,vict,nil,ch,TO_NOTVICT);
                          if (length(char_found) = 0) then
                            ch.sendBuffer(' ')
                          else
                            act(AT_SOCIAL,char_found,false,vict,nil,ch,TO_CHAR);
                          end;
                      7,8:begin     // Xenon (19/Feb/2001) : kinda odd, this one ;)
                          interpret(vict,'say Cut it out!');
                          interpret(vict,'sigh');
                          end;
              else
                          begin
                          act(AT_SOCIAL,'$n slaps you.',false,vict,nil,ch,TO_VICT);
                          act(AT_SOCIAL,'$n slaps $N.',false,vict,nil,ch,TO_NOTVICT);
                          act(AT_SOCIAL,'You slap $N.',false,vict,nil,ch,TO_CHAR);
                          end;
            end;
          end;
        end;
      end;
    end;
    end;

  checkSocial := true;
end;

procedure load_damage;
var
  af : GFileReader;
  s : string;
  dam : GDamMessage;
begin
  try
    af := GFileReader.Create(SystemDir + 'damage.dat');
  except
    bugreport('load_damage', 'mudsystem.pas', 'could not open system\damage.dat');
    exit;
  end;

  repeat
    s := af.readLine();
    
    if (length(trim(s)) > 0) then
      begin
      dam := GDamMessage.Create;

      with dam do
        begin
        min := strtoint(left(s,' '));
        max := strtoint(right(s,' '));

        msg[1] := af.readLine();
        msg[2] := af.readLine();
        msg[3] := af.readLine();
        end;

      dm_msg.insertLast(dam);
      end;
  until (af.eof());

  af.Free();
end;

procedure loadMudState();
var
   af : GFileREader;
   s : string;
   area : GArea;
begin
  try
    af := GFileReader.Create(SystemDir + 'mudstate.dat');
  except
    bugreport('loadMudState()', 'mudsystem.pas', 'Could not load mud state');
    exit;
  end;

  with time_info do
    begin
    af.readToken();

    hour := af.readInteger();
    day := af.readInteger();
    month := af.readInteger();
    year := af.readInteger();
    sunlight := af.readInteger();
    end;

  repeat
    if (af.eof()) then
      break;

    s := af.readLine();

    if (s <> '$') then
      begin
      area := findArea(s);

      if (area = nil) then
        bugreport('loadMudState()', 'mudsystem.pas', 'area ' + s + ' not found')
      else
        with area.weather do
          begin
          af.readToken();
          
          mmhg := af.readInteger();
          change := af.readInteger();
          sky := af.readInteger();
          temp := af.readInteger();
          end;
        end;
  until (s = '$');

  af.Free;
end;

procedure saveMudState();
var
  af : GFileWriter;
  node : GListNode;
  area : GArea;
begin
  try
    af := GFileWriter.Create(SystemDir + 'mudstate.dat');
  except
    bugreport('saveMudState()', 'mudsystem.pas', 'Could not save mud state');
    exit;
  end;

  with time_info do
    af.writeLine('Time: ' + IntToStr(hour) + ' ' + IntToStr(day) + ' ' +
                 IntToStr(month) + ' ' + IntToStr(year) + ' ' + IntToStr(sunlight));

  node := area_list.head;

  while (node <> nil) do
    begin
    area := node.element;

    if (not area.flags.isBitSet(AREA_PROTO)) then
      with area do
        begin
        af.writeLine(fname);
        af.writeLine('Weather: ' + IntToStr(weather.mmhg) + ' ' + IntToStr(weather.change) +
                     ' ' + IntToStr(weather.sky) + ' ' + IntToStr(weather.temp));
        end;

    node := node.next;
    end;

  af.writeLine('$');
  af.Free;
end;


// GAuction
constructor GAuction.Create;
begin
  inherited Create;

  pulse := 0;
  item := nil;
  seller := nil;
  buyer := nil;
end;

procedure GAuction.update;
var
   buf : string;
begin
  inc(going);

  case going of
    1,2:begin
        if (bid > 0) then
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name + '$1] $7' + cap(GObject(item).name);

          if (going = 1) then
            buf := buf + ' $1is going ONCE to '
          else
            buf := buf + ' $1is going TWICE to ';

          buf := buf + GCharacter(buyer).name + ' for ' + inttostr(bid) + ' coins.';
          to_channel(GCharacter(seller),buf,CHANNEL_AUCTION,AT_REPORT);
          end
        else
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name + '$1] Anyone?$7 ' + cap(GObject(item).name) + '$1 for ' + inttostr(start) + ' coins?';
          to_channel(GCharacter(seller),buf,CHANNEL_AUCTION,AT_REPORT);
          end;
        end;
      3:begin
        if (bid > 0) then
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name + '$1] $7' + cap(GObject(item).name);

          buf := buf + ' $1has been SOLD to ' + GCharacter(buyer).name + ' for ' + inttostr(bid) + ' coins.';

          to_channel(GCharacter(seller),buf,CHANNEL_AUCTION,AT_REPORT);

          GObject(item).toChar(buyer);

          act(AT_REPORT,'You have won the auction! '+cap(GObject(item).name)+' at '+
              inttostr(bid)+' coins.',false,buyer,nil,nil,TO_CHAR);

          dec(GPlayer(buyer).bankgold, bid);
          inc(GPlayer(seller).bankgold, bid);
          end
        else
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name + '$1] Due to lack of bidders, auction has been halted.';

          to_channel(GCharacter(seller),buf,CHANNEL_AUCTION,AT_REPORT);

          GObject(item).toChar(seller);
          end;

        seller:=nil;
        buyer:=nil;
        item:=nil;
        end;
  end;
end;

procedure initSystem();
begin
  socials := GHashTable.Create(512);
  socials.setHashFunc(firstHash);
  dm_msg := GDLinkedList.Create;
  auction_good := GAuction.Create;
  auction_evil := GAuction.Create;
  banned_masks := TStringList.Create;
  banned_names := TStringList.Create;
end;

procedure cleanupSystem();
begin
  socials.clear();
  socials.Free();

  dm_msg.clean();
  dm_msg.Free();
  
  auction_good.Free();
  auction_evil.Free();
  banned_masks.Free();
  banned_names.Free();
end;

end.

