// $Id: mudsystem.pas,v 1.21 2001/06/06 18:59:54 xenon Exp $

unit mudsystem;

interface
uses
    Winsock2,
    SysUtils,
    Classes,
    constants,
    strip,
    clean,
    dtypes,
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
      port : integer;             { port on which Grendel runs }
      log_all : boolean;          { log all player activity? }
      bind_ip : u_long;           { IP the server should bind to (when using multiple interfaces) }
      level_forcepc : integer;    { level to force players }
      level_log : integer;        { level to get log messages }
      lookup_hosts : boolean;     { lookup host names of clients? }
      deny_newconns : boolean;    { deny new connections? }
      deny_newplayers : boolean;  { disable 'CREATE', e.g. no new players }

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

   banned_masks : TStringList;


var
  OldExit : pointer;
  LogFile : textfile;

  { system data }
  BootTime : TDateTime;
  mobs_loaded:integer;
  online_time:string;
  status : THeapStatus;


const mud_booted : boolean = false;
      grace_exit : boolean = false;
      boot_type : integer = BOOTTYPE_SHUTDOWN;
      stable_system : boolean = true;


procedure write_direct(s:string);
procedure write_console(s:string);
procedure write_log(s:string);
procedure bugreport(func, pasfile, bug, desc : string);
procedure calculateonline;

procedure load_system;
procedure save_system;
function isMaskBanned(host : string) : boolean;

procedure load_damage;

procedure load_socials;

function findSocial(cmd : string) : GSocial;
function checkSocial(c : pointer; cmd, param : string) : boolean;


implementation

uses
    mudthread,
    chars,
    area,
    fsys,
    conns,
    Channels;

procedure write_direct(s : string);
begin
  write_log(s);
  writeln(s);
end;

procedure write_console(s:string);
begin
  write_log(s);

  s := FormatDateTime('[tt] ', Now) + s;

  writeln(s);

  if (mud_booted and channels_loaded) then
    to_channel(nil, s + '$7',CHANNEL_LOG,AT_LOG);
end;

procedure write_log(s:string);
begin
  s := '[' + DateTimeToStr(now) + '] [LOG] ' + s;

  if TTextRec(logfile).mode=fmOutput then
    system.writeln(logfile,s);
end;

procedure bugreport(func, pasfile, bug, desc : string);
begin
  write_console('[BUG] ' + func + ' -> ' + bug);
  write_direct('[Extended error information]');
  write_direct('Location:    function ' + func + ' in ' + pasfile);
  write_direct('Description: ' + desc);
  write_direct('');
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
  system_info.lookup_hosts := false;
  system_info.deny_newconns := false;
  system_info.deny_newplayers := false;
  system_info.level_forcepc := LEVEL_HIGHGOD;
  system_info.level_log := LEVEL_GOD;
  system_info.bind_ip := INADDR_ANY;

  try
    af := GFileReader.Create('system\sysdata.dat');
  except
    bugreport('load_system', 'mudsystem.pas', 'could not open system\sysdata.dat.',
              'The system file sysdata.dat could not be opened.');
    exit;
  end;

  repeat
    s := af.readLine;

    g := uppercase(left(s,':'));

    if g='PORT' then
      system_info.port:=strtoint(right(s,' '))
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
      system_info.bind_ip:=inet_addr(pchar(right(s,' ')));
  until (s = '$') or (af.eof);

  af.Free;

  try
    af := GFileReader.Create('system\bans.dat');
  except
    bugreport('load_system', 'mudsystem.pas', 'could not open system\bans.dat',
              'The system file bans.dat could not be opened.');
    exit;
  end;

  repeat
    s := af.readLine;

    if (s <> '$') then
      banned_masks.add(s);
  until (s = '$') or (af.eof);

  af.Free;
end;

procedure save_system;
var f : textfile;
    t : TInAddr;
    a : integer;
begin
  t.s_addr := system_info.bind_ip;

  assignfile(f,'system\sysdata.dat');
  rewrite(f);

  writeln(f,'Name: ',system_info.mud_name);
  writeln(f,'EMail: ',system_info.admin_email);
  writeln(f,'Port: ',system_info.port);
  writeln(f,'DenyNewConns: ',integer(system_info.deny_newconns));
  writeln(f,'DenyNewPlayers: ',integer(system_info.deny_newplayers));
  writeln(f,'HostLookup: ',integer(system_info.lookup_hosts));
  writeln(f,'LevelForcePC: ',system_info.level_forcepc);
  writeln(f,'LevelLog: ',system_info.level_log);
  writeln(f,'BindIP: ',inet_ntoa(t));
  writeln(f,'$');
  closefile(f);

  assignfile(f, 'system\bans.dat');
  rewrite(f);

  for a := 0 to banned_masks.count-1 do
    writeln(f, banned_masks[a]);

  writeln(f,'$');
  closefile(f);
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

// socials
procedure load_socials;
var f : textfile;
    s, g : string;
    social : GSocial;
    line_num : integer;
begin
  assignfile(f, 'system\socials.dat');
  {$I-}
  reset(f);
  {$I+}

  if (IOResult <> 0) then
    begin
    bugreport('load_socials', 'mudsystem.pas', 'could not open system\socials.dat',
              'The system file socials.dat could not be opened.');
    exit;
    end;

  line_num := 0;

  repeat
    repeat
      readln(f,s);
      inc(line_num);
    until (uppercase(s)='#SOCIAL') or eof(f);

    if (eof(f)) then
      break;

    social := GSocial.Create;

    with social do
      repeat
      readln(f,s);
      inc(line_num);

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
      until (uppercase(s)='#END') or eof(f);

    if (findSocial(social.name) <> nil) then
      begin
      write_console('duplicate social "' + social.name + '" on line ' + inttostr(line_num) + ', discarding');
      social.Free;
      end
    else
      socials.put(social.name, social);
  until eof(f);

  closefile(f);
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
var f:textfile;
    s:string;
    dam : GDamMessage;
begin
  assignfile(f,'system\damage.dat');
  {$I-}
  reset(f);
  {$I+}
  if IOResult<>0 then
    begin
    bugreport('load_damage', 'mudsystem.pas', 'could not open system\damage.dat',
              'The system file damage.dat could not be opened.');
    exit;
    end;

  repeat
    readln(f,s);

    dam := GDamMessage.Create;

    with dam do
      begin
      min := strtoint(left(s,' '));
      max := strtoint(right(s,' '));

      readln(f,s);
      msg[1] := s;

      readln(f,s);
      msg[2] := s;

      readln(f,s);
      msg[3] := s;
      end;

    dm_msg.insertLast(dam);

    readln(f,s);
  until eof(f);
  close(f);
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
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name^ + '$1] $7' + cap(GObject(item).name^);

          if (going = 1) then
            buf := buf + ' $1is going ONCE to '
          else
            buf := buf + ' $1is going TWICE to ';

          buf := buf + GCharacter(buyer).name^ + ' for ' + inttostr(bid) + ' coins.';
          to_channel(GCharacter(seller),buf,CHANNEL_AUCTION,AT_REPORT);
          end
        else
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name^ + '$1] Anyone?$7 ' + cap(GObject(item).name^) + '$1 for ' + inttostr(start) + ' coins?';
          to_channel(GCharacter(seller),buf,CHANNEL_AUCTION,AT_REPORT);
          end;
        end;
      3:begin
        if (bid > 0) then
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name^ + '$1] $7' + cap(GObject(item).name^);

          buf := buf + ' $1has been SOLD to ' + GCharacter(buyer).name^ + ' for ' + inttostr(bid) + ' coins.';

          to_channel(GCharacter(seller),buf,CHANNEL_AUCTION,AT_REPORT);

          GObject(item).toChar(buyer);

          act(AT_REPORT,'You have won the auction! '+cap(GObject(item).name^)+' at '+
              inttostr(bid)+' coins.',false,buyer,nil,nil,TO_CHAR);

          dec(GPlayer(buyer).bankgold, bid);
          inc(GPlayer(seller).bankgold, bid);
          end
        else
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name^ + '$1] Due to lack of bidders, auction has been halted.';

          to_channel(GCharacter(seller),buf,CHANNEL_AUCTION,AT_REPORT);

          GObject(item).toChar(seller);
          end;

        seller:=nil;
        buyer:=nil;
        item:=nil;
        end;
  end;
end;

initialization
socials := GHashTable.Create(512);
socials.setHashFunc(firstHash);
dm_msg := GDLinkedList.Create;
auction_good := GAuction.Create;
auction_evil := GAuction.Create;
banned_masks := TStringList.Create;

end.

