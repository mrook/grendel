unit mudsystem;

interface
uses
    Winsock,
    SysUtils,
    constants,
    strip,
    dtypes,
    clean,
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

   socials : GHashObject;
   dm_msg : GDLinkedList;

   pulse_violence,pulse_tick,pulse_gamehour,
   pulse_autosave,pulse_sec : integer;
   pulse_gametime : integer;

   clean_thread : GCleanThread;

   auction_good, auction_evil : GAuction;

(* var time_info:TIME_DATA;
    system_info:SYSTEM_DATA;
    auction:AUCTION_DATA;
    bgdata:BATTLEGROUND_DATA;

    { these names cannot be used when creating characters }
    banned_names:TStringList;
    { from these sites nobody can log on }
    banned_sites:TStringList; *)

var
  OldExit : pointer;
  LogFile : textfile;

  { system data }
  BootTime : TDateTime;
  mobs_loaded:integer;
  online_time:string;
  status : THeapStatus;


const mud_booted : boolean = false;
const grace_exit : boolean = false;
const boot_type : integer = BOOTTYPE_SHUTDOWN;


procedure write_direct(s:string);
procedure write_console(s:string);
procedure write_log(s:string);
procedure bugreport(func, pasfile, bug, desc : string);
procedure calculateonline;

procedure init_system;
procedure load_system;
procedure save_system;

procedure load_damage;

procedure load_socials;

function findSocial(cmd : string) : GSocial;
function checkSocial(c : pointer; cmd, param : string) : boolean;


implementation

uses
    mudthread,
    chars,
    area,
    conns;

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

  if (mud_booted) then
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
    days : integer;
begin
  tim := Now - BootTime;

  days := Trunc (Now) - Trunc (BootTime);

  tim := tim - days;

  online_time := FormatDateTime('"' + inttostr(days) + ' day(s)," h "hour(s) and" m "minute(s)"',tim);
end;

procedure init_system;
begin
  (* banned_names:=TStringList.Create;
  banned_sites:=TStringList.Create; *)

  pulse_violence := CPULSE_VIOLENCE;
  pulse_tick := CPULSE_TICK;
  pulse_gamehour := CPULSE_GAMEHOUR;
  pulse_sec := CPULSE_PER_SEC;
  pulse_autosave := CPULSE_AUTOSAVE;
  pulse_gametime := CPULSE_GAMETIME;
end;

procedure load_system;
var f : textfile;
    s,g : string;
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

  assignfile(f, 'system\sysdata.dat');
  {$I-}
  reset(f);
  {$I+}
  if (IOResult <> 0) then
    begin
    bugreport('load_system', 'mudsystem.pas', 'could not open system\sysdata.dat.',
              'The system file sysdata.dat could not be opened.');
    exit;
    end;

  repeat
    readln(f,s);

    g := uppercase(stripl(s,':'));

    if g='PORT' then
      system_info.port:=strtoint(striprbeg(s,' '))
    else
    if g='NAME' then
      system_info.mud_name := striprbeg(s,' ')
    else
    if g='EMAIL' then
      system_info.admin_email := striprbeg(s,' ')
    else
    if g='HOSTLOOKUP' then
      system_info.lookup_hosts:=strtoint(striprbeg(s,' '))<>0
    else
    if g='DENYNEWCONNS' then
      system_info.deny_newconns:=strtoint(striprbeg(s,' '))<>0
    else
    if g='DENYNEWPLAYERS' then
      system_info.deny_newplayers:=strtoint(striprbeg(s,' '))<>0
    else
    if g='LEVELFORCEPC' then
      system_info.level_forcepc:=strtoint(striprbeg(s,' '))
    else
    if g='LEVELLOG' then
      system_info.level_log:=strtoint(striprbeg(s,' '))
    else
    if g='BINDIP' then
      system_info.bind_ip:=inet_addr(pchar(striprbeg(s,' ')));
  until (s = '$');
  close(f);

  (* assignfile(f,'system\bannednames.dat');
  {$I-}
  reset(f);
  {$I+}

  if (IOResult <> 0) then
    begin
    bugreport('load_system', 'mudsystem.pas', 'could not open system\bannednames.dat',
              'The system file bannednames.dat could not be opened.');
    exit;
    end;
  repeat
    readln(f,s);
    if s<>'$' then
      banned_names.add(uppercase(s));
  until (s='$') or (eof(f));
  close(f);

  assignfile(f,'system\bannedsites.dat');
  {$I-}
  reset(f);
  {$I+}

  if (IOResult <> 0) then
    begin
    bugreport('load_system', 'mudsystem.pas', 'could not open system\bannedsites.dat',
              'The system file bannedsites.dat could not be opened.');
    exit;
    end;
  repeat
    readln(f,s);
    if s<>'$' then
      banned_sites.add(uppercase(s));
  until (s='$') or (eof(f));
  close(f); *)
end;

procedure save_system;
var f:textfile;
    t:TInAddr;
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

(*  assignfile(f,'system\bannednames.dat');
  rewrite(f);

  for a:=0 to banned_names.count-1 do
    writeln(f,banned_names[a]);
  writeln(f,'$');

  closefile(f);
  assignfile(f,'system\bannedsites.dat');
  rewrite(f);

  for a:=0 to banned_sites.count-1 do
    writeln(f,banned_sites[a]);
  writeln(f,'$');

  closefile(f); *)
end;

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

      g:=uppercase(stripl(s,':'));
      
      if g = 'NAME' then
        name := hash_string(uppercase(striprbeg(s,' ')))
      else
      if g='CHARNOARG' then
        char_no_arg := striprbeg(s,' ')
      else
      if g='OTHERSNOARG' then
        others_no_arg := striprbeg(s,' ')
      else
      if g='CHARAUTO' then
        char_auto := striprbeg(s,' ')
      else
      if g='OTHERSAUTO' then
        others_auto := striprbeg(s,' ')
      else
      if g='CHARFOUND' then
        char_found := striprbeg(s,' ')
      else
      if g='VICTFOUND' then
        vict_found := striprbeg(s,' ')
      else
      if g='OTHERSFOUND' then
        others_found := striprbeg(s,' ');
      until (uppercase(s)='#END') or eof(f);

    if (findSocial(social.name) <> nil) then
      begin
      write_console('duplicate social "' + social.name + '" on line ' + inttostr(line_num) + ', discarding');
      social.Free;
      end
    else
      socials.hashObject(social, social.name);
  until eof(f);

  socials.hashStats;

  closefile(f);
end;

function findSocial(cmd : string) : GSocial;
var
   hash : integer;
   node : GListNode;
   social : GSocial;
begin
  hash := socials.getHash(cmd);
  findSocial := nil;

  node := socials.bucketList[hash].head;

  while (node <> nil) do
    begin
    social := node.element;

    if (cmd = social.name) then
      begin
      findSocial := social;
      break;
      end;

    node := node.next;
    end;
end;

function checkSocial(c : pointer; cmd, param : string) : boolean;
var social : GSocial;
    chance : integer;
    ch, vict : GCharacter;
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

    if (length(param)=0) then
      begin
      act(AT_SOCIAL,char_no_arg,false,ch,nil,vict,TO_CHAR);
      act(AT_SOCIAL,others_no_arg,false,ch,nil,vict,TO_ROOM);
      end
    else
    if vict=ch then
      begin
      act(AT_SOCIAL,char_auto,false,ch,nil,vict,TO_CHAR);
      act(AT_SOCIAL,others_auto,false,ch,nil,vict,TO_ROOM);
      end
    else
    if vict=nil then
      act(AT_SOCIAL,'They are not here.',false,ch,nil,nil,TO_CHAR)
    else
      begin
      act(AT_SOCIAL,char_found,false,ch,nil,vict,TO_CHAR);
      act(AT_SOCIAL,others_found,false,ch,nil,vict,TO_NOTVICT);
      act(AT_SOCIAL,vict_found,false,ch,nil,vict,TO_VICT);

      if ((not ch.IS_NPC)) and (vict.IS_NPC) and
       // not IS_SET(vict.npc_index.mpflags,MPROG_ACT) and
       (vict.IS_AWAKE) then
        begin
        chance:=random(10);
        case chance of
          1,2,3,4,5,6:begin
                      act(AT_SOCIAL,vict_found,false,vict,nil,ch,TO_VICT);
                      act(AT_SOCIAL,others_found,false,vict,nil,ch,TO_NOTVICT);
                      act(AT_SOCIAL,char_found,false,vict,nil,ch,TO_CHAR);
                      end;
                  7,8:begin
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
      min := strtoint(stripl(s,' '));
      max := strtoint(striprbeg(s,' '));

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
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name + '$1] $7' + cap(GObject(item).name);

          if (going = 1) then
            buf := buf + ' $1is going ONCE to '
          else
            buf := buf + ' $1is going TWICE to ';

          buf := buf + GCharacter(buyer).name + ' for ' + inttostr(bid) + ' coins.';
          to_channel(seller,buf,CHANNEL_AUCTION,AT_REPORT);
          end
        else
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name + '$1] Anyone?$7 ' + cap(GObject(item).name) + '$1 for ' + inttostr(start) + ' coins?';
          to_channel(seller,buf,CHANNEL_AUCTION,AT_REPORT);
          end;
        end;
      3:begin
        if (bid > 0) then
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name + '$1] $7' + cap(GObject(item).name);

          buf := buf + ' $1has been SOLD to ' + GCharacter(buyer).name + ' for ' + inttostr(bid) + ' coins.';

          to_channel(seller,buf,CHANNEL_AUCTION,AT_REPORT);

          GObject(item).toChar(buyer);

          act(AT_REPORT,'You have won the auction! '+cap(GObject(item).name)+' at '+
              inttostr(bid)+' coins.',false,buyer,nil,nil,TO_CHAR);

          dec(GCharacter(buyer).player^.bankgold, bid);
          inc(GCharacter(seller).player^.bankgold, bid);
          end
        else
          begin
          buf := '$B$2<Auction> $1[$7' + GCharacter(seller).name + '$1] Due to lack of bidders, auction has been halted.';

          to_channel(seller,buf,CHANNEL_AUCTION,AT_REPORT);

          GObject(item).toChar(seller);
          end;

        seller:=nil;
        buyer:=nil;
        item:=nil;
        end;
  end;
end;

begin
  socials := GHashObject.Create(512);
  dm_msg := GDLinkedList.Create;

  auction_good := GAuction.Create;
  auction_evil := GAuction.Create;
end.

