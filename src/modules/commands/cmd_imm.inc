// $Id: cmd_imm.inc,v 1.5 2004/02/09 20:18:36 hemko Exp $

procedure do_shutdown(ch:GCharacter;param:string);
var
   haltparam : string;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: SHUTDOWN <stop/halt/reboot/copyover> [time]'#13#10#13#10);
    ch.sendBuffer('If time is not given, a default of 30 seconds is assumed.'#13#10);
    ch.sendBuffer('Using "stop" as a parameter halts the shutdown.'#13#10);
    ch.sendBuffer('Using "now" as time value enables immediate shutdown.'#13#10);
    exit;
    end;

  param := one_argument(param, haltparam);

  if (haltparam = 'stop') then
    begin
    act(AT_REPORT, 'Timer stopped.',false,ch,nil,nil,TO_CHAR);
    boot_info.boot_type := 0;
    boot_info.started_by := nil;
    boot_info.timer := -1;
    exit;
    end
  else
  if (haltparam = 'reboot') then
    begin
    act(AT_REPORT,'REBOOT started.',false,ch,nil,nil,TO_CHAR);

    boot_info.boot_type := BOOTTYPE_REBOOT;
    end
  else
  if (haltparam = 'halt') then
    begin
    act(AT_REPORT,'SHUTDOWN started.',false,ch,nil,nil,TO_CHAR);

    boot_info.boot_type := BOOTTYPE_SHUTDOWN;
    end
  else
  if (haltparam = 'copyover') then
    begin
    act(AT_REPORT, 'COPYOVER started.',false,ch,nil,nil,TO_CHAR);

    boot_info.boot_type := BOOTTYPE_COPYOVER;
    end
  else
    begin
    ch.sendBuffer('Illegal parameter: use "stop", "halt", "reboot" or "copyover".'#13#10);
    exit;
    end;

  if (length(param) > 0) then
    begin
    if (param = 'now') then
      boot_info.timer := 1
    else
      try
        boot_info.timer := strtoint(param) + 1;
      except
        ch.sendBuffer('Boot timer must be a valid numeric value!'#13#10);
        exit;
      end
    end
  else
    boot_info.timer := 31;

  boot_info.started_by := ch;
end;

procedure do_echo(ch:GCharacter;param:string);
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage: ECHO <text>'#13#10);
    exit;
    end;
  act(AT_LOG,param,false,ch,nil,nil,TO_CHAR);
  act(AT_ECHO,param,false,ch,nil,nil,TO_ALL);
end;

procedure do_wizinvis(ch:GCharacter;param:string);
var level:integer;
begin
  if (ch.IS_NPC) then
    exit;

  if (ch.IS_WIZINVIS) then
    begin
    act(AT_REPORT,'You feel yourself brightening.',false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'A light shines and $n appears.',false,ch,nil,nil,TO_ROOM);
    REMOVE_BIT(GPlayer(ch).flags,PLR_WIZINVIS);
    GPlayer(ch).wiz_level:=0;
    end
  else
    begin
    if (length(param)>0) then
      try
        level:=strtoint(param);
      except
        ch.sendBuffer('Invalid numeric format.'#13#10);
        exit;
      end
    else
      level:=ch.level;

    act(AT_REPORT,'You wave your hand and disappear.',false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'$n waves $s hand and disappears in a storm of colors.',false,ch,nil,nil,TO_ROOM);
    SET_BIT(GPlayer(ch).flags,PLR_WIZINVIS);
    GPlayer(ch).wiz_level:=level;
    end;
end;

procedure do_sla(ch:GCharacter;param:string);
begin
  ch.sendBuffer('You must type out the command.'#13#10);
end;

procedure do_slay(ch:GCharacter;param:string);
var t:GCharacter;
    dam:integer;
begin
  if (length(param)=0) then
    ch.sendBuffer('Slay whom?'#13#10)
  else
    begin
    t := ch.room.findChar(ch, param);

    if (t = nil) then
      ch.sendBuffer('They are not here.'#13#10)
    else
    if (t = ch) then
      ch.sendBuffer('You can''t slay yourself!'#13#10)
    else
      begin
      act(AT_SLAY,'You slay $N in cold blood!',false,ch,nil,t,TO_CHAR);
      act(AT_SLAY,'$n slays you in cold blood!',false,ch,nil,t,TO_VICT);
      act(AT_SLAY,'$n slays $N in cold blood!',false,ch,nil,t,TO_NOTVICT);
      dam := UMax(t.max_hp, 800);
      damage(ch,t,dam,TYPE_SLAY);
      end;
    end;
end;

procedure do_advance(ch:GCharacter;param:string);
var vict:GCharacter;
    lvl,num,a:integer;
    vict_nm:string;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Advance whom?'#13#10);
    exit;
    end;

  param:=one_argument(param,vict_nm);
  vict:=findcharworld(ch,vict_nm);

  if (vict.IS_NPC()) then
  begin
    ch.sendBuffer('This command does not work on NPCs.'#13#10);
    exit;
  end;

  try
    lvl:=strtoint(param);
  except
    ch.sendBuffer('Invalid numeric format.'#13#10);
    exit;
  end;
  if (lvl > LEVEL_MAX) then
    ch.sendBuffer('Use GRACE to give a character immortal status.'#13#10)
  else
  if (vict = nil) then
    ch.sendBuffer('That character is not online right now.'#13#10)
  else
  begin
    num := lvl - vict.level;
    vict.in_command:=true;

    for a:=1 to num do
      gain_xp(GPlayer(vict), GPlayer(vict).xptogo);

    act(AT_REPORT,'You have advanced $N to level '+inttostr(vict.level)+'.',false,ch,nil,vict,TO_CHAR);
    act(AT_REPORT,'$N has advanced you to level '+inttostr(vict.level)+'!',false,vict,nil,ch,TO_CHAR);

    vict.in_command:=false;
  end;
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
{ Xenon 22/Apr/2001: added (vict = nil) check }
procedure do_grace(ch:GCharacter;param:string);
var 
	vict:GCharacter;
	lev:integer;
	vict_nm : string;
begin
  if (length(param)=0) then
  begin
    ch.sendBuffer( 'Usage: GRACE <character> <level>'#13#10#13#10);
    ch.sendBuffer( 'Use this command to immortalize players.'#13#10);
    exit;
  end;

  param:=one_argument(param, vict_nm);
  vict:=findcharworld(ch, vict_nm);

  if (vict = nil) then
    begin
    ch.sendBuffer('Couldn''t find that player online.'#13#10);
    exit;
    end;
  
  lev:=strtointdef(param, 0);

  if (vict.IS_NPC) then
    ch.sendBuffer( 'Can only grace players.'#13#10)
  else
  if (ch.level < LEVEL_MAX) then
    ch.sendBuffer( 'That character is too low a level, use ADVANCE first.'#13#10)
  else
  if (lev > ch.level) then
    ch.sendBuffer( 'You cannot raise someone to that level.'#13#10)
  else
  if (vict = nil) then
    ch.sendBuffer( 'That character is not online right now.'#13#10)
  else
  if (lev < LEVEL_IMMORTAL) or (lev > LEVEL_MAX_IMMORTAL) then
    ch.sendBuffer( string('That level is not in the appropriate range. Use ' + inttostr(LEVEL_IMMORTAL) + ' to ' + inttostr(LEVEL_MAX_IMMORTAL) + '.'#13#10))
  else
    begin
    act(AT_REPORT,'You suddenly feel a pressure on you...',false,vict,nil,nil,TO_CHAR);
    act(AT_REPORT,'You have become more powerful!'#13#10,false,vict,nil,nil,TO_CHAR);

    if ((lev > LEVEL_MAX) and (lev <= LEVEL_MAX_IMMORTAL)) then         // Xenon 20/Feb/2001 : replaced vict.level = 500 with lev = 1000
      begin
      { Set hps etc. to immortal level }
      vict.max_hp := 15000;
      vict.max_mv := 15000;
      vict.max_mana := 15000;
      vict.hp := 15000;
      vict.mv := 15000;
      vict.mana := 15000;
      vict.str := 100;
      vict.con := 100;
      vict.dex := 100;
      vict.int := 100;
      vict.wis := 100;
      vict.sendBuffer(findHelp('M_IMMORTALIZE_').text);
      end
    else
      act(AT_REPORT,'You feel yourself growing... to a higher level of understanding.',false,vict,nil,nil,TO_CHAR);

    vict.level:=lev;
    act(AT_REPORT,'You have attained the rank of '+IMM_Types[vict.level]+'.',false,vict,nil,nil,TO_CHAR);
    ch.sendBuffer('Ok.'#13#10);
    //recalcac(ch);
    ch.calcAC;
    end;
end;

procedure do_destroy(ch:GCharacter;param:string);
var
   vict : GCharacter;
   f : textfile;
   s,g : string;
   level : integer;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage:  DESTROY <player>'#13#10#13#10);
    ch.sendBuffer('Logs this player out and moves the playerfile to the backup directory.'#13#10);
    exit;
    end;

  vict := findCharWorld(ch,param);

  if (vict <> nil) then
    begin
    if (vict.IS_NPC) then
      ch.sendBuffer('Can only destroy players.'#13#10)
    else
    if (vict.IS_IMMORT) then
      ch.sendBuffer('That player cannot be destroyed.'#13#10)
    else
    if (vict = ch) then
      ch.sendBuffer('Use DELETE to erase yourself.'#13#10)
    else
      begin
      stopfighting(vict);
      vict.sendBuffer(#13#10 + findHelp('M_DESTROY_').text);
      vict.emptyBuffer;
      GPlayer(vict).quit;

      ch.sendBuffer('Ok.'#13#10);
      writeConsole(vict.name + ' has been destroyed.');

      assignfile(f, 'players\' + vict.name + '.usr');
      rename(f, 'backup\' + vict.name + '.usr');
      exit;
      end;
    end;

  if FileExists('players\' + param + '.usr') then
    begin

    assignfile(f,'players\' + param + '.usr');
    reset(f);

    repeat
      readln(f, s);

      g := uppercase(left(s, ':'));

      if (g = 'LEVEL') then
        begin
        level := strtoint(right(s, ' '));

        if (level >= 990) then
          begin
          ch.sendBuffer('That player cannot be destroyed.'#13#10);
          exit;
          end;
        end;
    until (eof(f));

    closefile(f);

    writeConsole(param + ' has been destroyed.');
    ch.sendBuffer('Ok.'#13#10);

    rename(f, 'backup\' + param + '.usr');
    end
  else
    begin
    ch.sendBuffer('That player cannot be found.'#13#10);
    exit;
    end;
end;

{Jago 5/Jan/01 : implemented do_force to use GCharacter instead of CHAR_DATA}
procedure do_force(ch:GCharacter;param:string);
var
 vict_node: GListnode;
  vict:GCharacter;
    //sub:array[0..63] of char;
    sub : string;
begin
  if (length(param)=0) then
  begin
    ch.sendBuffer('Usage:  FORCE <[name]/ALL/ALLPC> <command>'#13#10);
    exit;
  end;

  param:=one_argument(param,sub);

  if (sub = 'all') then // Force ALL
  begin
    if  ch.getTrust < system_info.level_forcepc then
      begin
      ch.sendBuffer('You must be a higher level to force players.'#13#10);
      exit;
      end;
    act(AT_WHITE,'You force everybody to "'+param+'".',false,ch,nil,nil,TO_CHAR);

    vict_node := char_list.head;

    while vict_node <> nil do begin
      vict := GCharacter(vict_node.element);
      if vict <> ch then
      begin
        act(AT_WHITE,'$n forces you to "' + param + '"',false,ch,nil,vict,TO_VICT);
        interpret(vict,param);
      end;
      vict_node := vict_node.next;
    end {while}

  end
  else
  if (sub = 'allpc') then // force ALLPC
  begin
    if ch.getTrust < system_info.level_forcepc then
      begin
      ch.sendBuffer('You must be a higher level to force players.'#13#10);
      exit;
      end;
    act(AT_WHITE,'You force all players to "'+param+'".',false,ch,nil,nil,TO_CHAR);

    vict_node := char_list.head;

    while vict_node <> nil do begin
      vict := GCharacter(vict_node.element);
      if (vict <> ch) and (not vict.IS_NPC) then
      begin
        act(AT_WHITE,'$n forces you to "' + param + '"',false,ch,nil,vict,TO_VICT);
       interpret(vict,param);
      end;
      vict_node := vict_node.next;
    end {while}
  end
  else // force <name>
    begin
    { first find victim in room, if any }
    vict := ch.room.findChar(ch,sub);

    if vict=nil then
      vict:=FindCharWorld(ch,sub);
    if vict=nil then
      ch.sendBuffer('They aren''t here.'#13#10)
    else
      begin
      if (not vict.IS_NPC) and (ch.getTrust < system_info.level_forcepc) then
        begin
        ch.sendBuffer('You must be a higher level to force players.'#13#10);
        exit;
        end;
      act(AT_WHITE,'You force $N to "'+param+'".$A$7',false,ch,nil,vict,TO_CHAR);
      act(AT_WHITE,'$n forces you to "' + param + '"',false,ch,nil,vict,TO_VICT);
      interpret(vict,param);

      end;
    end;
end;

{Jago 5/Jan/01 : implemented do_transfer as done in MERC (implementation not quite identical to MERC)}
procedure do_transfer( ch : GCharacter; param : string );
var
  arg1, arg2 : string;
 location : GRoom;
 victim : GCharacter;
 char_node : GListNode;
begin
  param := one_argument( param, arg1 ); // who to trans
  param := one_argument( param, arg2 ); // where to trans

  if length(arg1) = 0 then
  begin
   ch.sendBuffer('Transfer whom (and where)?'#13#10);
   exit;
  end;

  // get the trans location.  could be ch.room or a location given by arg2
  if length(arg2) = 0 then
  begin
    location := ch.room;
  end
  else
  begin
    location := findLocation(ch, arg2);
  end;

  if location = nil then
  begin
   ch.sendBuffer('Transfer them where??');
   exit;
  end;

  if uppercase(arg1) = 'ALL' then // transfer all
  begin
   char_node := char_list.head;

   while char_node <> nil do
   begin
     victim := GCharacter(char_node.element);

     if not victim.IS_NPC then // players only!! 
     begin
       if victim.fighting <> nil then
         stopFighting(victim);
       act(AT_WHITE,'$n disappears in a mushroom cloud.',false,victim,nil,nil,TO_ROOM);
       victim.fromRoom;
       victim.toRoom(location);
       act(AT_WHITE,'$n arrives from a puff of smoke.',false,victim,nil,nil,TO_ROOM);
       if ch <> victim then
         act(AT_WHITE,'$n has transferred you.',false,ch,nil,victim,TO_VICT);
       interpret(victim, 'look _AUTO');
     end;

      char_node := char_node.next;
   end; {while}

  end
  else // transfer single victim
  begin
   victim := findCharWorld(ch, arg1);

   if (victim <> nil) then
     begin
     if victim.fighting <> nil then
      stopFighting(victim);
      
     act(AT_WHITE,'$n disappears in a mushroom cloud.',false,victim,nil,nil,TO_ROOM);
     victim.fromRoom;
     victim.toRoom(location);
     act(AT_WHITE,'$n arrives from a puff of smoke.',false,victim,nil,nil,TO_ROOM);

     if ch <> victim then
       act(AT_WHITE,'$n has transferred you.',false,ch,nil,victim,TO_VICT);

     interpret(victim, 'look _AUTO');
     end;
  end;
end;

{Jago 5/Jan/01 : implemented do_goto as done in MERC }
procedure do_goto(ch : GCharacter; param: string);
var
  location : GRoom;
  locn_name : string;
  vnum : integer;
  new_room : GRoom;
begin
 param := one_argument(param, locn_name);

 if length(locn_name) = 0 then
 begin
   ch.sendBuffer('Goto where?' + #13#10);
   exit;
 end;

 location := findLocation(ch, locn_name);

 if (not ch.IS_NPC) and (location = nil) then // if vnum doesn't exist yet and vnum is in builders range, create the room
   begin
   try
     if (length(GPlayer(ch).area_fname) = 0) then
       raise Exception.Create('no area assigned');

     vnum := StrToInt(locn_name);
     
     if (vnum >= GPlayer(ch).r_lo) and (vnum < GPlayer(ch).r_hi) then
       if (GPlayer(ch).area = nil) then
         begin
         ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
         exit;
         end
       else
         begin
         ch.sendBuffer(ch.ansiColor(15) + 'Creating room #' + inttostr(vnum) + '.' + ch.ansiColor(7) + #13#10#13#10);
         new_room := createRoom(vnum, GPlayer(ch).area);
         ch.fromRoom();
         ch.toRoom(new_room);
         interpret(ch, 'look');
         exit;
       end
     else
     begin
       ch.sendBuffer('That vnum is not within your assigned room ranges.'#13#10);
       exit;
     end;
   except
     ch.sendBuffer('No such location!' + #13#10);
     exit;
   end;
 end;

 if (location.flags.isBitSet(ROOM_PRIVATE)) then
   begin
   ch.sendBuffer('That room is private right now.' + #13#10);
   exit;
   end;

 if (ch.fighting <> nil) then
   stopFighting(ch);

 {goto while hunting not tested! - result may be unpredictable!!}
 {if ch.hunting <> nil then
 begin
  ch.hunting := nil;
  REMOVE_BIT(ch.act_flags, ACT_HUNTING);
 end;}

  if (not ch.IS_WIZINVIS) and (not ch.IS_NPC) then
    begin
    if (GPlayer(ch).bamfout <> '') then
      act(AT_WHITE, GPlayer(ch).bamfout,false,ch,nil,nil,TO_ROOM)
    else
      act(AT_WHITE,'$n leaves in a swirling mist.',false,ch,nil,nil,TO_ROOM);
    end;

  ch.fromRoom;
  ch.toRoom(location);

  if (not ch.IS_WIZINVIS) and (not ch.IS_NPC) then
    begin
    if (GPlayer(ch).bamfin <> '') then
      act(AT_WHITE, GPlayer(ch).bamfin,false,ch,nil,nil,TO_ROOM)
    else
      act(AT_WHITE,'$n appears in a swirling mist.',false,ch,nil,nil,TO_ROOM);
    end;

  interpret(ch, 'look _AUTO');
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
procedure do_connections(ch:GCharacter;param:string);
var
  s:string;
  conn: GPlayerConnection;
  iterator : GIterator;
begin
  act(AT_REPORT, '$8[$B$1Nr.$A$8] [$B$1State           $A$8] [$B$1' + pad_string('IP', 32) + '$A$8] [$B$1Name$A$8]'#13#10,false,ch,nil,nil,TO_CHAR);

  iterator := connection_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    conn := GPlayerConnection(iterator.next());
    
    if (conn.ch <> nil) and (not conn.ch.IS_NPC) and (IS_SET(GPlayer(conn.ch).flags, PLR_CLOAK)) then
      continue;

    if (conn.ch <> nil) then
      s := conn.ch.name
    else
      s := '-';

    act(AT_REPORT,'$7($B$7' + pad_integer_front(conn.socket.getDescriptor,3) + '$A$7) '+
        pad_string(con_states[conn.state], 16) + '   ' +
        pad_string(conn.socket.ip_string, 32) + '   ' +
        s,false,ch,nil,nil,TO_CHAR);
    end;
  
  iterator.Free();
end;

procedure do_bgset(ch:GCharacter;param:string);
var lo,hi,secs:integer;
    obj : GObject;
    buf:string;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage:  BGSET <lo range> <hi range> <seconds> [object]'#13#10#13#10);
    ch.sendBuffer('Initiates a battleground for players within the range.'#13#10);
    exit;
    end;

  try
    param:=one_argument(param,buf);
    lo:=strtoint(buf);
    param:=one_argument(param,buf);
    hi:=strtoint(buf);
    param:=one_argument(param,buf);
    secs:=strtoint(buf);
  except
    ch.sendBuffer('Invalid numeric format.');
    exit;
  end;

  obj := ch.findInventory(param);

  bg_info.count:=secs;
  bg_info.winner:=nil;
  bg_info.lo_range:=lo;
  bg_info.hi_range:=hi;

  if (obj <> nil) then
    begin
    obj.seperate;
    obj.fromChar;
    bg_info.prize:=obj;
    end
  else
    bg_info.prize:=nil;

  ch.sendBuffer('Started the battleground.'#13#10);
  battlegroundMessage;
end;

procedure do_snoop(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage:  SNOOP <character>'#13#10#13#10);
    ch.sendBuffer('Snoops/sniffs every byte that is sent to this character.'#13#10);
    ch.sendBuffer('When using this, your own output will be discarded to prevent'#13#10);
    ch.sendBuffer('your screen from overflowing. To stop, type SNOOP SELF.'#13#10);
    exit;
    end;

  vict := findCharWorld(ch, param);
  
  if (vict = nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end
  else
  if (vict = ch) then
    begin
    if (GPlayer(ch).snooping <> nil) then 
      begin
      GPlayer(ch).snooping.snooped_by := nil;
      GPlayer(ch).snooping := nil;
      ch.sendBuffer('No longer snooping.'#13#10);
      end
    else
      ch.sendBuffer('You aren''t snooping anyone.'#13#10);
      
    exit;
    end
  else
  if (vict.IS_IMMORT()) and (vict.level >= ch.level) then
    begin
    ch.sendBuffer('Cannot snoop a same or higher level immortal.'#13#10);
    exit;
    end
  else
  if (vict.snooped_by <> nil) then
    begin
    ch.sendBuffer('That character is already being snooped by somebody.'#13#10);
    exit;
    end;

  act(AT_YELLOW,'Started snooping $N.',false,ch,nil,vict,TO_CHAR);
  GPlayer(ch).snooping := vict;
  vict.snooped_by:=ch;
end;

procedure do_loadup(ch:GCharacter;param:string);
var vict : GPlayer;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Loadup whom?'#13#10);
    exit;
    end;

  if (not FileExists('players\' + param + '.usr')) then
    begin
    ch.sendBuffer('That player does not exist.'#13#10);
    exit;
    end
  else
  if (findCharWorld(ch, param) <> nil) then
    begin
    ch.sendBuffer('That player is already online.'#13#10);
    exit;
    end;

  act(AT_REPORT,'Loading '+param+'...',false,ch,nil,nil,TO_CHAR);

  vict := GPlayer.Create(nil);
  vict.load(param);
  SET_BIT(vict.flags,PLR_LOADED);
  SET_BIT(vict.flags,PLR_LINKLESS);

  vict.node_world := char_list.insertLast(vict);

  vict.toRoom(vict.room);
  act(AT_REPORT,'$N loaded.',false,ch,nil,vict,TO_CHAR);
  interpret(ch, 'goto '+vict.name);
end;

function yes_no(v:boolean):string;
begin
  if v then
    yes_no:='yes'
  else
    yes_no:='no';
end;

procedure do_sconfig(ch:GCharacter;param:string);
var sub : string;
    t : TInAddr;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage:  SCONFIG <field> <value>'#13#10#13#10);
    ch.sendBuffer('Field can be one of the following:'#13#10#13#10);
    ch.sendBuffer('  show - to view current settings'#13#10#13#10);
    ch.sendBuffer('  name email port ip forcepc log'#13#10);
    ch.sendBuffer('  lookup denyconns denyplayers noback'#13#10);
    exit;
    end;

  if (param = 'show') then
    begin
    ch.sendBuffer('Current server configuration:'#13#10#13#10);
    act(AT_REPORT,'Name:            '+system_info.mud_name,false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'E-Mail:          '+system_info.admin_email,false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Port:            '+inttostr(system_info.port),false,ch,nil,nil,TO_CHAR);
    t.s_addr:=system_info.bind_ip;
    act(AT_REPORT,'IP:              '+inet_ntoa(t),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Level_forcepc:   '+inttostr(system_info.level_forcepc),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Level_log:       '+inttostr(system_info.level_log),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Host lookup:     '+yes_no(system_info.lookup_hosts),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Deny conns:      '+yes_no(system_info.deny_newconns),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'Deny players:    '+yes_no(system_info.deny_newplayers),false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  param := one_argument(param,sub);

  if (length(param) = 0) then
  begin
    ch.sendBuffer('Please specify a new value for this option.'#13#10);
    exit;
  end;

  if (sub = 'name') then
    system_info.mud_name := param
  else
  if (sub = 'email') then
    system_info.admin_email := param
  else
  if (sub = 'port') then
    system_info.port := strtoint(param)
  else
  if (sub = 'ip') then
    system_info.bind_ip := inet_addr(pchar(param))
  else
  if (sub = 'forcepc') then
    system_info.level_forcepc := strtoint(param)
  else
  if (sub = 'log') then
    system_info.level_log := strtoint(param)
  else
  if (sub = 'lookup') then
    system_info.lookup_hosts := (param = '1') or (param = 'yes')
  else
  if (sub = 'denyconns') then
    system_info.deny_newconns := (param = '1') or (param = 'yes')
  else
  if (sub = 'denyplayers') then
    system_info.deny_newplayers := (param = '1') or (param = 'yes')
  else
    begin
    ch.sendBuffer('Invalid option.'#13#10);
    exit;
    end;

  save_system;

  ch.sendBuffer('Ok. New config saved.'#13#10);
end;

procedure do_ban(ch:GCharacter;param:string);
var
   a, count : integer;
   buf : string;
begin
  if (length(param) = 0) then
    begin
    if (banned_masks.count=0) then
      begin
      ch.sendBuffer('No sites are currently banned.'#13#10);
      exit;
      end;

    buf := #13#10 + ch.ansiColor(3) + ' ' + add_chars(78, '---- Banned sites ', '-') + ch.ansiColor(7) + #13#10#13#10;
    ch.sendPager(buf);

    count := 0;

    for a := 0 to banned_masks.count - 1 do
      begin
      ch.sendPager(pad_string(banned_masks[a], 19));
      inc(count);

      if (count = 4) then
        begin
        ch.sendPager(#13#10);
        count := 0;
        end;
      end;

    ch.sendPager(#13#10);
    exit;
    end;

  act(AT_REPORT, 'Banned mask ''' + param + ''' has been added.',false,ch,nil,nil,TO_CHAR);
  banned_masks.add(param);
  save_system;
end;

procedure do_allow(ch:GCharacter;param:string);
var a : integer;
begin
  if (length(param) = 0) then
    begin
    do_ban(ch, param);
    exit;
    end;

  a := banned_masks.indexOf(param);
  if (a >= 0) then
    begin
    ch.sendBuffer('Ok.'#13#10);
    banned_masks.delete(a);
    save_system;
    end
  else
    ch.sendBuffer('That mask is not in the ban list.'#13#10);
end;

procedure do_log(ch:GCharacter;param:string);
var victim:GCharacter;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage:  LOG <all/player>'#13#10#13#10);
    ch.sendBuffer('Either logs all player activity or sets the log flag'#13#10);
    ch.sendBuffer('on a single player.'#13#10);
    exit;
    end;

  if (param = 'all') then
    begin
    system_info.log_all:=(not system_info.log_all);
    if (system_info.log_all) then
      ch.sendBuffer('Log ALL has been enabled.'#13#10)
    else
      ch.sendBuffer('Log ALL has been disabled.'#13#10);
    exit;
    end;

  victim := findCharWorld(ch,param);
  if (victim = nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;

  if (victim.logging) then
    begin
    victim.logging := false;
    act(AT_REPORT,'No longer logging $N.',false,ch,nil,victim,TO_CHAR);
    end
  else
    begin
    victim.logging := true;
    act(AT_REPORT,'Started logging $N.',false,ch,nil,victim,TO_CHAR);
    end;
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
procedure do_uptime(ch:GCharacter;param:string);
var 
  i, total : integer;
  hv : GHashValue;
  room : GRoom;
  char : GCharacter;
  iterator : GIterator;
begin
  calculateonline;
  act(AT_REPORT,'[' + version_info + ', ' + version_number + '] '#13#10 + system_info.mud_name+#13#10,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'Online time:       ' + online_time,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'System time:       ' + DateTimeToStr(Now),false,ch,nil,nil,TO_CHAR);

{$IFDEF WIN32}
  status:=GetHeapStatus;
  act(AT_REPORT,'Heap allocated:    ' + inttostr(status.totalallocated)+' byte(s)',false,ch,nil,nil,TO_CHAR);
{$ENDIF}

  total := 0;
  iterator := room_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    room := GRoom(iterator.next());
    
    inc(total, room.InstanceSize());
    inc(total, room.exits.size() * GExit.InstanceSize());
    inc(total, room.tracks.size() * GTrack.InstanceSize());
    inc(total, room.extra.size() * GExtraDescription.InstanceSize());
    end;

  iterator.Free();
  ch.sendBuffer('Rooms: ' + IntToStr(total) + #13#10);
  ch.sendBuffer('NPC indices: ' + IntToStr(GNPCIndex.InstanceSize() * npc_list.size()) + #13#10);
  ch.sendBuffer('Object indices: ' + IntToStr(GObject.InstanceSize() * objectIndices.size()) + #13#10);
  ch.sendBuffer('Object instances: ' + IntToStr(GObject.InstanceSize() * objectList.size()) + #13#10);

  total := 0;
  iterator := char_list.iterator();
  
  while (iterator.hasNext()) do
    begin
    char := GCharacter(iterator.next());
    
    if (char is GPlayer) then
      inc(total, GPlayer.InstanceSize())
    else
    if (char is GNPC) then
      inc(total, GNPC.InstanceSize());
    end; 
  
  iterator.Free();
  ch.sendBuffer('Characters: ' + IntToStr(total) + #13#10);

  total := 0;

  for i := 0 to str_hash.bucketcount - 1 do
    begin
    iterator := str_hash.buckets[i].iterator();

    while (iterator.hasNext()) do
      begin
      hv := GHashValue(iterator.next());

      inc(total, hv.refcount * length(GString(hv.value).value));
      end;

    iterator.Free();
    end;
    
  ch.sendBuffer('String buffer: ' + IntToStr(total) + #13#10);
  ch.sendBuffer('Programs: ' + IntToStr(GCodeBlock.InstanceSize() * codeCache.size()) + #13#10);
end;

procedure do_switch(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  SWITCH <character>'#13#10);
    exit;
    end;

  vict := findCharWorld(ch,param);

  if (vict = nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;

  if (not vict.IS_NPC) then
    begin
    ch.sendBuffer('Can not switch into players.'#13#10);
    exit;
    end;

  if (vict.snooped_by <> nil) then
    begin
    act(AT_REPORT,'$N is already switched.',false,ch,nil,vict,TO_CHAR);
    exit;
    end;

  ch.sendBuffer('Ok.'#13#10);

  GPlayer(ch).switching := vict;
  vict.snooped_by := ch;
end;

procedure do_return(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  if (ch.snooped_by = nil) or (GPlayer(ch.snooped_by).switching <> ch) then
    begin
    act(AT_REPORT,'You aren''t switched.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  vict := ch.snooped_by;
  GPlayer(ch.snooped_by).switching := nil;
  ch.snooped_by := nil;
  
  vict.sendBuffer('Ok.'#13#10);

  vict.emptyBuffer();
end;

// All available immortal commands - Nemesis
procedure do_wizhelp(ch : GCharacter; param : string);
var
  iterator : GIterator;
  cmd : GCommand;
  cmdList : TStringList;
  i, lev : integer;
  buf : string;
begin
  cmdList := TStringList.Create();
  lev := ch.getTrust;
  
  iterator := commandList.iterator();
  
  while (iterator.hasNext()) do
    begin
    cmd := GCommand(iterator.next());
  
    // Show only immortal commands available at your level
    if (cmd.level > LEVEL_MAX) and (cmd.level <= lev) then
      cmdList.Add(lowercase(cmd.name));
    end;
    
  iterator.Free();
  
  // Sort the list
  cmdList.Sort();  
  
  buf := #13#10 + ch.ansiColor(3) + ' ' + add_chars(78, '---- Available immortal commands ', '-') + ch.ansiColor(7) + #13#10;
  
  for i := 0 to pred(cmdList.Count) do
    begin
    if (i mod 5 = 0) then
      buf := buf + #13#10 + pad_string(cmdList[i], 15)
    else
      buf := buf + pad_string(cmdList[i], 15);
    end;
  
  buf := buf + #13#10;
  
  cmdList.Free();
 
  ch.sendPager(buf);
end;

{Jago 5/Jan/01 : implemented do_restore to use GCharacter instead of CHAR_DATA, }
{             added restore all functionality}
procedure do_restore(ch:GCharacter;param:string);
var
  victim: GCharacter;
 vict_node: GListnode;
begin
  if (length(param)=0) then
  begin
    ch.sendBuffer('Usage:  RESTORE <[character]/ALL>'#13#10);
    exit;
  end;

  {restore ALL}
  if uppercase(param) = 'ALL' then
  begin
    vict_node := char_list.head;

    while vict_node <> nil do
      begin
      victim  := GCharacter(vict_node.element);
      if (victim <> ch) and (not victim.IS_NPC) then
        begin
        victim.hp := victim.max_hp;
        victim.mv := victim.max_mv;
        victim.mana := victim.max_mana;
        act(AT_REPORT,'$N has restored you.',false,victim,nil,ch,TO_CHAR);
        end;

      vict_node := vict_node.next;
      end; {while}
     ch.sendBuffer('Ok.'#13#10);
  end
  else // restore single char
  begin
    victim:=FindCharWorld(ch,param);

    if (victim=nil) then
    begin
      ch.sendBuffer('That character does not exist.'#13#10);
      exit;
    end;

    victim.hp := victim.max_hp;
    victim.mv := victim.max_mv;
    victim.mana := victim.max_mana;

    ch.sendBuffer('Ok.'#13#10);
    act(AT_REPORT,'$N has restored you.',false,victim,nil,ch,TO_CHAR);
  end;
end;

{ Xenon 12/Apr/2001: freeze now only works on players lowerlevel than you and you cannot freeze yourself anymore :P }
procedure do_freeze(ch:GCharacter;param:string);
var 
  victim : GPlayer;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage:  FREEZE <character>'#13#10#13#10);
    ch.sendBuffer('If the character is already frozen, this will unfreeze.'#13#10);
    exit;
    end;

  victim := GPlayer(findPlayerWorld(ch,param));
  if (victim = nil) then
    begin
    ch.sendBuffer('That character isn''t online.'#13#10);
    exit;
    end;

  if (victim = ch) then
    begin
    ch.sendBuffer('You cannot freeze yourself.'#13#10);
    exit;
    end;

  if (victim.level >= ch.level) then
    begin
    ch.sendBuffer('Can only freeze players lower level than you.'#13#10);
    exit;
    end;

  if (IS_SET(victim.flags,PLR_FROZEN)) then
    begin
    act(AT_REPORT,Format('You have defrosted $B$5%s$A$7.', [victim.name]),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'You have been un-frozen by $N.',false,victim,nil,ch,TO_CHAR);
    REMOVE_BIT(victim.flags,PLR_FROZEN);
    end
  else
    begin
    act(AT_REPORT,Format('You have frozen $B$5%s$A$7.', [victim.name]),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'You have been frozen by $N.',false,victim,nil,ch,TO_CHAR);
    SET_BIT(victim.flags,PLR_FROZEN);
    end;
end;

procedure do_silence(ch:GCharacter;param:string);
var 
  victim : GPlayer;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer( 'Usage:  SILENCE <character>'#13#10#13#10);
    ch.sendBuffer( 'If the character is already silenced, this will unsilence.'#13#10);
    exit;
    end;

  victim := GPlayer(findPlayerWorld(ch,param));
  if (victim=nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;

  if (victim = ch) then
    begin
    ch.sendBuffer('You cannot silence yourself.'#13#10);
    exit;
    end;

  if (victim.level >= ch.level) then
  begin
    ch.sendBuffer('Can only silence players lower level than you.'#13#10);
    exit;
  end;

//  ch.sendBuffer('Ok.'#13#10);
  if (IS_SET(victim.flags,PLR_SILENCED)) then
    begin
    act(AT_REPORT,Format('You have unsilenced $B$5%s$A$7.', [victim.name]),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'You have been un-silenced by $N.',false,victim,nil,ch,TO_CHAR);
    REMOVE_BIT(victim.flags,PLR_SILENCED);
    end
  else
    begin
    act(AT_REPORT,Format('You have silenced $B$5%s$A$7.', [victim.name]),false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'You have been silenced by $N.',false,victim,nil,ch,TO_CHAR);
    SET_BIT(victim.flags,PLR_SILENCED);
    end;
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
procedure do_peace(ch:GCharacter; param:string);
var
  rch:GCharacter;
 rch_node : GListNode;
begin
  act(AT_REPORT, '$n BOOOOMS: ''PEACE!!!''', false, ch, nil, nil, TO_ROOM);

  rch_node := ch.room.chars.head;
  while rch_node <> nil do
  begin
    rch := GCharacter(rch_node.element);
    if (rch.fighting <> nil) then
    begin
      stopfighting(rch);
    end;

    if rch <> ch then
      interpret(rch, 'sit');

    rch_node := rch_node.next;
  end;

  ch.sendBuffer( 'Ok.'#13#10);
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
{ Xenon 28/Apr/2001 : renamed do_areas() to do_vnums() }
procedure do_vnums(ch:GCharacter; param:string);
var
  area: GArea;
  iterator : GIterator;
begin
  act(AT_DCYAN, 'Area name                          Filename                  Author              VNum Range'#13#10, false, ch, nil, nil, TO_CHAR);

  iterator := area_list.iterator();

  while (iterator.hasNext()) do
    begin
    area := GArea(iterator.next());

    act(AT_REPORT, pad_string(area.name, 29) + pad_string(area.fname, 15) + ' ' + pad_string(area.author, 17) + ' ' + pad_integer(area.r_lo, 5) + ' - ' + pad_integer(area.r_hi, 5), false, ch, nil, nil, TO_CHAR);
    end;
end;

{Jago 6/Jan/2001 - repaired for v 0.3}
procedure do_disconnect(ch : GCharacter; param : string);
var
     sock : integer;
    conn : GPlayerConnection;
    conn_f : GPlayerConnection;
    iterator : GIterator;
begin
  if (length(param) = 0) then
  begin
    ch.sendBuffer( 'Usage:  DISCONNECT <socket number>'#13#10#13#10);
    ch.sendBuffer( 'Disconnects a socket on the server.'#13#10);
    exit;
  end;

  try
    sock := StrToInt(param);
  except
    ch.sendBuffer( 'Please use a valid number.'#13#10);
    exit;
  end;

  iterator := connection_list.iterator();
  conn_f := nil;
  while (iterator.hasNext()) do
  begin
    conn := GPlayerConnection(iterator.Next());

    if (conn.socket.getDescriptor = sock) then
    begin
      conn_f := conn;
      break;
    end;
  end;

  iterator.Free();

  if (conn_f = nil) then
  begin
    ch.sendBuffer( 'That socket number was not found.'#13#10);
    exit;
  end;

  ch.sendBuffer( 'Ok.'#13#10);

  conn_f.Terminate();
end;

procedure do_bamfin(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC) then
    exit;

  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  BAMFIN <line or NULL to reset>'#13#10);

    if (GPlayer(ch).bamfin <> '') then
      ch.sendBuffer('Currently: ' + GPlayer(ch).bamfin + #13#10);
    exit;
    end;

  if (uppercase(param) = 'NULL') then
    GPlayer(ch).bamfin := ''
  else
    GPlayer(ch).bamfin := param;

  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_bamfout(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC) then
    exit;

  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  BAMFOUT <line or NULL to reset>'#13#10);

    if (GPlayer(ch).bamfout <> '') then
      ch.sendBuffer('Currently: ' + GPlayer(ch).bamfout + #13#10);
    exit;
    end;

  if (uppercase(param) = 'NULL') then
    GPlayer(ch).bamfout := ''
  else
    GPlayer(ch).bamfout := param;

  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_sset(ch : GCharacter; param : string);
var vict : GCharacter;
    victim, skill : string;
    perc:integer;
    sn : GSkill;
    node : GListNode;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  SSET <character> <skill> <percentage>'#13#10);
    exit;
    end;

  param := one_argument(param, victim);
  param := one_argument(param, skill);

  try
    perc := strtoint(param);
  except
    ch.sendBuffer('Percentage must be a number.'#13#10);
    exit;
  end;

  vict := findCharWorld(ch, victim);

  if (vict=nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;

  if (ch.getTrust < LEVEL_GOD) and (not vict.IS_NPC) then
    begin
    ch.sendBuffer('You can only use this on mobiles.'#13#10);
    exit;
    end;

  if (skill = 'all') then
    begin
    node := skill_table.head;

    while (node <> nil) do
      begin
      vict.SET_LEARNED(perc, node.element);

      node := node.next;
      end;

    vict.sendBuffer('You feel a great power increasing your skills.'#13#10);
    end
  else
    begin
    sn := findSkill(skill);

    if (sn = nil) then
      begin
      ch.sendBuffer('That skill does not exist.'#13#10);
      exit;
      end;

    vict.SET_LEARNED(perc, sn);

    vict.sendBuffer('You feel a great power increasing your skills.'#13#10);
    end;

  ch.sendBuffer('Ok.'#13#10);
end;

{ Nourish - Nemesis }
procedure do_nourish(ch:GCharacter;param:string);
var victim: GPlayer;
    vict_node: GListnode;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  NOURISH <[character]/ALL>'#13#10);
    exit;
    end;

  { nourish ALL }
  if uppercase(param) = 'ALL' then
  begin
    vict_node := char_list.head;

    while (vict_node <> nil) do
      begin
      if (vict_node.element <> ch) and (TObject(vict_node.element) is GPlayer) then
        begin
        victim := GPlayer(vict_node.element);

        victim.condition[COND_FULL]:=100;
        victim.condition[COND_THIRST]:=100;
        victim.condition[COND_DRUNK]:=0;
        victim.condition[COND_HIGH]:=0;
        victim.condition[COND_CAFFEINE]:=0;

        act(AT_REPORT,'You have nourished $N.',false,ch,nil,victim,TO_CHAR);
        act(AT_REPORT,'$N has nourished you.',false,victim,nil,ch,TO_CHAR);
        end;

      vict_node := vict_node.next;
      end; {while}

    ch.sendBuffer('Ok.'#13#10);
  end
  else
    { Nourish single char }
    begin
    victim := GPlayer(findPlayerWorld(ch,param));

    if (victim = nil) then
      begin
      ch.sendBuffer('That player does not exist.'#13#10);
      exit;
      end;
    
    victim.condition[COND_FULL]:=100;
    victim.condition[COND_THIRST]:=100;
    victim.condition[COND_DRUNK]:=0;
    victim.condition[COND_HIGH]:=0;
    victim.condition[COND_CAFFEINE]:=0;

    act(AT_REPORT,'You have nourished $N.',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'$N has nourished you.',false,victim,nil,ch,TO_CHAR);
  end;
end;

{ Revive player when killed - Nemesis }
procedure do_revive(ch:GCharacter; param:string);
var 
  obj : GObject;
  corpseroom : GRoom;
  victim : GCharacter;
  number,count : integer;
  conn : GPlayerConnection;
  iterator : GIterator;
  buf : string;
begin
  // Without argument shows existing corpses, decay timer and VNUM.

  if (length(param) = 0) then
    begin
    act(AT_REPORT,'Timer - Existing corpses:' + #13#10,false,ch,nil,nil,TO_CHAR);

    count := 0;

    iterator := connection_list.iterator();

    while (iterator.hasNext()) do
      begin
      conn := GPlayerConnection(iterator.next());

      obj := findObjectWorld('the corpse of ' + conn.ch.name);

      if (obj <> nil) then
        begin
        inc(count);

        buf := buf + ' (' + ansiColor(7,0) + pad_integer_front(obj.timer,2) +
               ansiColor(2,0) + ') ' + obj.name + ' in room: ' + ansiColor(6,0) +
               inttostr(obj.room.vnum) + ansiColor(2,0) + '.' + #13#10;
        end;
      end;
      
    iterator.Free();

    if (count = 0) then
      buf := ' None.' + #13#10;

    ch.sendBuffer(buf);

    exit;
    end;

  number := findNumber(param);
  
  // You can use 2.<player> in case of multiple corpses of same player.

  obj := findObjectWorld(inttostr(number) + '.corpse of ' + param);

  victim := findCharWorld(ch, param);

  if (obj = nil) then
    begin
    ch.sendBuffer('That corpse does not exist.'#13#10);
    exit;
    end;

  if (victim = nil) then
    begin
    ch.sendBuffer('That player is not logged in anymore.'#13#10);
    exit;
    end;

  // You don't want to revive NPC's :)

  if (victim.IS_NPC) then
    begin
    ch.sendBuffer('You can''t revive NPC''s.'#13#10);
    exit;
    end;

  corpseroom := obj.room;
  victim.fromRoom;
  victim.toRoom(corpseroom);

  act(AT_REPORT,'$N has revived you!',false,victim,nil,ch,TO_CHAR);
  act(AT_REPORT,'You have revived ' + uppercase(param) + '.',true,ch,nil,nil,TO_CHAR);
  interpret(victim, 'look _AUTO');
end;

procedure do_hashstats(ch : GCharacter; param : string);
var
  node : GListNode;
  n, c : integer;
  g : GHashValue;
begin
  ch.sendPager('Allocated hash entries: '#13#10#13#10);
  c := 0;

  for n := 0 to str_hash.bucketcount - 1 do
    begin
    node := str_hash.buckets[n].head;
    while (node <> nil) do
      begin
      g := GHashValue(node.element);

      ch.sendPager('(' + pad_integer_front(c, 3) + ') ' + GString(g.value).value + ' [' + inttostr(g.refcount) + ']'#13#10);

      inc(c);

      node := node.next;
      end;
    end;
end;

procedure do_holywalk(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC) then
    exit;

  if (IS_SET(GPlayer(ch).flags, PLR_HOLYWALK)) then
    begin
    ch.sendBuffer('Holy walk off.'#13#10);
    REMOVE_BIT(GPlayer(ch).flags, PLR_HOLYWALK);
    end
  else
    begin
    ch.sendBuffer('Holy walk on.'#13#10);
    SET_BIT(GPlayer(ch).flags, PLR_HOLYWALK);
    end;
end;

procedure do_holylight(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC) then
    exit;

  if (IS_SET(GPlayer(ch).flags, PLR_HOLYLIGHT)) then
    begin
    ch.sendBuffer('Holy light off.'#13#10);
    REMOVE_BIT(GPlayer(ch).flags, PLR_HOLYLIGHT);
    end
  else
    begin
    ch.sendBuffer('Holy light on.'#13#10);
    SET_BIT(GPlayer(ch).flags, PLR_HOLYLIGHT);
    end;
end;

{ Xenon 20/Feb/2001: take an object from a player }
procedure do_take(ch : GCharacter; param : string);
var
   victstr,objstr : string;
   vict : GCharacter;
   obj : GObject;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  TAKE <object> <character>'#13#10);
    exit;
    end;

  param := one_argument(param, objstr);
  param := one_argument(param, victstr);

  // First search in room
  vict := ch.room.findChar(ch, victstr);

  // Then search global
  if (vict = nil) then
    vict := findCharWorld(ch, victstr);

  if (vict=nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;

  obj := vict.findEquipment(objstr);
  if (obj = nil) then
  obj := vict.findInventory(objstr);

  if (obj = nil) then
    begin
    ch.sendBuffer('That character does not have that object.'#13#10);
    exit;
    end;

  obj.worn := '';       // put it in inv no matter what

  obj.seperate;
  obj.fromChar;
  obj.toChar(ch);

  act(AT_REPORT,'$N takes $p from you.',false, vict, obj, ch, TO_CHAR);
  act(AT_REPORT,'$n takes $p from $N.',false, ch, obj, vict, TO_NOTVICT);
  act(AT_REPORT,'You take $p from $N.',false, ch, obj, vict, TO_CHAR);
end;

{ Xenon 21/Feb/2001: rename a player online }
procedure do_prename(ch : GCharacter; param : string);
var
   curr_name, new_name : string;
   vict : GPlayer;
   buf : string;
begin
  if (length(param) = 0) then
  begin
    ch.sendBuffer('Usage:  PRENAME <current_name> <new_name>'#13#10);
    exit;
  end;

  param := one_argument(param, curr_name);
  param := one_argument(param, new_name);

  curr_name := cap(curr_name);
  new_name := cap(new_name);

  vict := GPlayer(findPlayerWorld(ch, curr_name));

  if (vict = nil) then
  begin
    ch.sendBuffer('That character isn''t online.'#13#10);
    exit;
  end;
  
  if (length(new_name) < 3) or (length(new_name) > 15) then
  begin
    ch.sendBuffer('New name must be between 3 and 15 characters long.'#13#10);
    exit;
  end;

  if (vict.IS_NPC) then
  begin
    ch.sendBuffer('This command doesn''t work on mobs.'#13#10);
    exit;
  end;

  if (FileExists('players\' + new_name + '.usr')) then
  begin
    ch.sendBuffer('That name is already in use.'#13#10);
    exit;
  end;

  with vict do
  begin
    name := cap(new_name);
    short := cap(new_name) + ' is here';
    long := cap(new_name) + ' is standing here';
    vict.save(vict.name);
  end;

  deleteFile('players\' + curr_name + '.usr');

  writeConsole(ch.name + ' has renamed ' + curr_name + ' to ' + new_name);

  buf := Format('$B$5%s$A$7 has renamed you to $B$5%s$A$7.', [ch.name, new_name]);
  act(AT_REPORT,buf,false,vict,nil,nil,TO_CHAR);
  buf := Format('$B$5%s$A$7 has been renamed to $B$5%s$A$7.', [curr_name, new_name]);
  act(AT_REPORT,buf,false,vict,nil,nil,TO_NOTVICT);
end;

{ Xenon 12/Apr/2001: execute a command at a players location }
procedure do_at(ch : GCharacter; param : string);
var
   target : string;
   vict : GCharacter;
   saveroom : GRoom;
begin
  if (length(param) = 0) then
  begin
    ch.sendBuffer('Usage:  AT <player> <command>'#13#10);
    exit;
  end;

  param := one_argument(param, target);

  if (length(param) = 0) then
  begin
    ch.sendBuffer('Usage:  AT <player> <command>'#13#10);
    exit;
  end;

  vict := findCharWorld(ch, target);

  if (vict = nil) then
  begin
    ch.sendBuffer('That character isn''t online.'#13#10);
    exit;
  end;

  if (vict = ch) then
  begin
    ch.sendBuffer('You don''t need AT to do that!'#13#10); // with thanks to Nemesis for his suggestion :)
    exit;
  end;

  saveroom := ch.room;
  ch.fromRoom();
  ch.toRoom(vict.room);
  interpret(ch, param);
  ch.fromRoom();
  ch.toRoom(saveroom);
end;

{ Xenon 12/Apr/2001: execute a command at a players location }
procedure do_namegen(ch : GCharacter; param : string);
var
  i : integer;
  node : GListNode;
  nt : TNameTemplate;
  template_nr : integer;
  amount_str : string;
  amount, count : integer;
  arg1 : string;
begin
  nt := nil;
  count := 1;
  
  if (length(param) = 0) then
  begin
    ch.sendBuffer('Usage:  NAMEGEN list|reload|<template #> [amount to generate]'#13#10);
    exit;
  end;

  if (not namegenerator_enabled or (PhonemeList = nil) or (NameTemplateList = nil)) then
  begin
    ch.sendBuffer('Namegenerator is not enabled at this moment. (Error loading tables? File missing?)'#13#10);
    exit;
  end;

  param := one_argument(param, arg1);
  
  if (arg1 = 'list') then
  begin
    node := NameTemplateList.head;
    for i := 1 to (NameTemplateList.size()) do
    begin
      if (node = nil) then
        break;
      nt := TNameTemplate(node.element);
      act(AT_REPORT, Format('   $B$1[$7%2d$1]$A$7   %s', [i, nt.template_name]), false, ch, nil, nil, TO_CHAR);

      node := node.next;
    end;
    exit;
  end;

  if (arg1 = 'reload') then
  begin
    reloadNameTables();
    ch.sendBuffer('Done reloading nametables.'#13#10);
    exit;
  end;

  try
    template_nr := StrToInt(arg1);
  except
    on E: EConvertError do
    begin
      ch.sendBuffer(Format('Invalid argument ''%s''.'#13#10, [arg1]));
      exit;
    end;
  end;

  if ((template_nr > NameTemplateList.size()) or (template_nr < 1)) then
  begin
    ch.sendBuffer('Template number out of range.'#13#10);
    exit;
  end;
  
  param := one_argument(param, amount_str);
  if (amount_str <> '') then
  begin
    try
      amount := StrToInt(amount_str);
    except
      ch.sendBuffer('Please specify a number for amount to generate.'#13#10);
      exit;
    end;
    if ((amount > 20) or (amount < 1)) then
    begin
      ch.sendBuffer('Amount to generate out of range (1 < amount < 20).'#13#10);
      exit;
    end
    else
      count := amount;
  end;

  node := NameTemplateList.head;
  for i := 1 to template_nr do
  begin
    if (node = nil) then
      break;
    nt := TNameTemplate(node.element);
    node := node.next;
  end;
  
  act(AT_REPORT, Format('$B$1[$7Nametemplate ''%s''$1]$A$7', [nt.template_name]) + #13#10, false, ch, nil, nil, TO_CHAR);
  for i := 1 to count do
  begin
    act(AT_REPORT, Format('  $B$1[$7%2d$1]$A$7   %s', [i, generateName(nt.template_name)]), false, ch, nil, nil, TO_CHAR);
  end
end;

procedure createCoordinates(ch : GCharacter; startroom : GRoom);
var
  iterator : GIterator;
  room : GRoom;
  ex : GExit;
begin
  iterator := startroom.exits.iterator();

  while (iterator.hasNext()) do
    begin
    ex := GExit(iterator.next());
    
    room := ex.to_room;

    if (room.areacoords = nil) then
      begin
      room.areacoords := GCoords.Create(startroom.areacoords);
      case ex.direction of
        DIR_NORTH:
          begin
            inc(room.areacoords.y);
          end;
        DIR_EAST:
          begin
            inc(room.areacoords.x);
          end;
        DIR_SOUTH:
          begin
            dec(room.areacoords.y);
          end;
        DIR_WEST:
          begin
            dec(room.areacoords.x);
          end;
        DIR_DOWN:
          begin
            dec(room.areacoords.z);
          end;
        DIR_UP:
          begin
            inc(room.areacoords.z);
          end;
      end;
      ch.sendBuffer('Created coords (#' + IntToStr(room.vnum) + '): ' + room.areacoords.toString() + #13#10);
      createCoordinates(ch, room);
      end;
    end;
    
  iterator.Free();
end;

procedure do_coordgen(ch : GCharacter; param : string);
var
  room : GRoom;
begin
  ch.sendBuffer('NOTE: This command is still experimental and it''s use is discouraged.'#13#10);
  ch.sendBuffer('      It should only be used when you know what you''re doing. And even then... :P'#13#10#13#10);
  
  if (length(param) = 0) then
  begin
    ch.sendBuffer('Usage: COORDGEN <vnum>'#13#10#13#10);
    ch.sendBuffer('Generates coordinates with specifief vnum as (0,0,0).'#13#10);
    exit;
  end;

  try
    room := findRoom(StrToInt(param));
  except
    on E: EConvertError do
    begin
      ch.sendBuffer('That vnum doesn''t exit.');
      exit;
    end;
  end;

  if (room = nil) then
  begin
    ch.sendBuffer('A room with that vnum could not be found.'#13#10);
    exit;
  end;
  
  room.areacoords := GCoords.Create();
  room.areacoords.x := 0;
  room.areacoords.y := 0;
  room.areacoords.z := 0;
  createCoordinates(ch, room);
end;

{ this function *always* returns a positive value if it succeeds and a negative
  value if it doesn't }
function goalDistEstimate(currRoom : GRoom; destRoom : GRoom) : single;
begin
//  Assert(currRoom.areacoords <> nil, 'currRoom.areacoords = nil');
//  Assert(destRoom.areacoords <> nil, 'destRoom.areacoords = nil');
  if (currRoom.areacoords = nil) then
  begin
    bugreport('goalDistEstimate', 'cmd_imm.inc', 'currRoom.areacoords = nil; this probably means no areacoordinates have been created, see immcommand coordgen');
    raise Exception.Create('currRoom.areacoords = nil');
    Result := -1;
    exit;
  end;
  if (destRoom.areacoords = nil) then
  begin
    bugreport('goalDistEstimate', 'cmd_imm.inc', 'destRoom.areacoords = nil; this probably means no areacoordinates have been created, see immcommand coordgen');
    raise Exception.Create('destRoom.areacoords = nil');
    Result := -1;
    exit;
  end;

{$IFNDEF UseStraightLine}
// this is "Manhattan" distance, more appriopriate for A* and thus default
  Result := abs(destRoom.areacoords.x - currRoom.areacoords.x) +
            abs(destRoom.areacoords.y - currRoom.areacoords.y) +
            abs(destRoom.areacoords.z - currRoom.areacoords.z);
{$ELSE}            
// this is straight line distance
  if (currRoom.areacoords.z = destRoom.areacoords.z) then
    Result := power(
                power((destRoom.areacoords.x - currRoom.areacoords.x), 2) +
                power((destRoom.areacoords.y - currRoom.areacoords.y), 2),
                0.5)
  else
    Result := power(
                power((destRoom.areacoords.x - currRoom.areacoords.x), 2) +
                power((destRoom.areacoords.y - currRoom.areacoords.y), 2) +
                power((destRoom.areacoords.z - currRoom.areacoords.z), 2),
                1/3);
{$ENDIF}
end;

type
  TSearchNode =
    class
      f, g, h : single;
      room : GRoom;
      parent : TSearchNode;
      constructor Create(); overload;
      constructor Create(newg, newh : single; newroom : GRoom; newparent : TSearchNode); overload;
    end;

constructor TSearchNode.Create();
begin
  inherited Create();
  f := 0;
  g := 0;
  h := 0;
  room := nil;
  parent := nil;
end;

constructor TSearchNode.Create(newg, newh : single; newroom : GRoom; newparent : TSearchNode);
begin
  inherited Create();
  g := newg;
  h := newh;
  f := g + h;
  room := newroom;
  parent := newparent;
end;

procedure insertPriority(ll : GDLinkedList; snode : TSearchNode);
var
  node, ins : GListNode;
  n : TSearchNode;
begin
  ins := nil;
  node := ll.head;

  if (ll.head = nil) then
    begin
    ll.insertLast(snode);
    exit;
    end;

  while (node <> nil) do
    begin
    n := TSearchNode(node.element);

    if (snode.f > n.f) then
      begin
      ins := node;
      end
    else
      begin
      ll.insertBefore(node, snode);
      exit;
      end;
    
    node := node.next;
    end;

  ll.insertAfter(ins, snode);  
end;
    
function findRoomAStar(ll : GDLinkedList; froom : GRoom) : GListNode;
var
  node : GListNode;
  snode : TSearchNode;
begin
  Result := nil;
  
  node := ll.head;
  while (node <> nil) do
    begin
    snode := TSearchNode(node.element);
    if (snode.room = froom) then
      begin
      Result := node;
      exit;
      end;
    node := node.next;
    end;
end;

{ Implementation of A* search algorithm }
{ this piece of code is ugly ;) }
function mpFindPath(startroom, destroom : GRoom; var resultdirs : string) : boolean;
var
  room, droom : GRoom;
  snode : TSearchNode;
  olnode, clnode : GListNode;
  new_snode, found_node : TSearchNode;
  llopen : GDLinkedList;
  llclosed : GDLinkedList;
  i : integer;
  node : GListNode;
  newg : single;
  found : boolean;
  dirs : string;
begin
  Result := false;
  dirs := '';
  found_node := nil;

  if (startroom = destroom) then
  begin
    Result := true;
    resultdirs := '';
    exit;
  end;
  
  llopen := GDLinkedList.Create();
  llclosed := GDLinkedList.Create();
  
  snode := TSearchNode.Create(0, goalDistEstimate(startroom, destroom), startroom, nil);

  insertPriority(llopen, snode);

  found := false;
  
  while (llopen.size() > 0) do
  begin
    node := llopen.head;
    snode := TSearchNode(node.element);
    room := snode.room;

    if (room = destroom) then
    begin
      found := true;
      llopen.remove(node);
      found_node := snode;
      break;
    end;

    if (room = nil) then
    begin
      writeConsole('room = nil');
      continue;
    end;
    
    llopen.remove(node);

    insertPriority(llclosed, snode);
    
    for i := DIR_NORTH to DIR_UP do
    begin
      droom := room.isConnectedTo(i);
      if (droom <> nil) then
      begin
        newg := snode.g + 1; // cost
        olnode := findRoomAStar(llopen, droom);
        clnode := findRoomAStar(llclosed, droom);
        if (olnode <> nil) and (TSearchNode(olnode.element).g <= newg) then
          continue;
        if (clnode <> nil) and (TSearchNode(clnode.element).g <= newg) then
          continue;
        if (clnode <> nil) then
          llclosed.remove(clnode);
        if (olnode = nil) then
        begin
          if (goalDistEstimate(droom, destroom) < 0) then
          begin
            bugreport('do_findpath', 'cmd_imm.inc', 'goalDistEstimate return value < 0 (2)');
            exit;
          end;
          new_snode := TSearchNode.Create(newg, goalDistEstimate(droom, destroom), droom, snode);
          insertPriority(llopen, new_snode);
        end;
      end;
    end;
  end;

  if (found) then
  begin
    Result := true;
    
    dirs := '';
    snode := found_node;
    while (snode.parent <> nil) do
    begin
//      ch.sendBuffer(Format('- #%d'#13#10, [snode.room.vnum]));
      dirs := dirs + findDirectionShort(snode.room, snode.parent.room);
      snode := snode.parent;
    end;

    resultdirs := '';
    for i := length(dirs) downto 1 do
    begin
      resultdirs := resultdirs + headings_short_i[findHeading(dirs[i])];
    end;
  end
  else
  begin
    Result := false;
    resultdirs := '';
  end;

  llopen.Clean();
  llopen.Free();
  llclosed.Clean();
  llclosed.Free();
end;

procedure do_findpath(ch : GCharacter; param : string);
var
  goalroom : GRoom;
  dirs : string;
  found : boolean;
  arg1, arg2 : string;
  i : integer;
begin
  dirs := '';

  if (length(param) = 0) then
  begin
    ch.sendBuffer('Usage: FINDPATH <vnum> [GO]'#13#10#13#10);
    ch.sendBuffer('This is a command to test the pathfinding functions.'#13#10);
    ch.sendBuffer('Supply a vnum as destination, and to optional keyword GO to'#13#10);
    ch.sendBuffer('follow a path if one is found.'#13#10);
    ch.sendBuffer(#13#10'IMPORTANT: don''t forget you need to create areacoordinates first (using immcommand ''coordgen'').'#13#10);
    exit;
  end;
  
  param := one_argument(param, arg1);
  param := one_argument(param, arg2);
  try
    goalroom := findRoom(StrToInt(arg1));
  except
//    on E: EConvertError do
    begin
      ch.sendBuffer('That vnum doesn''t exit.'#13#10);
      exit;
    end;
  end;

  if (goalroom = nil) then
  begin
    ch.sendBuffer('A room with that vnum could not be found.'#13#10);
    exit;
  end;

  if (goalDistEstimate(ch.room, goalroom) < 0) then
  begin
    bugreport('do_findpath', 'cmd_imm.inc', 'goalDistEstimate return value < 0 (2)');
    exit;
  end;

  ch.sendBuffer(Format('Distance: %g'#13#10, [goalDistEstimate(ch.room, goalroom)]));

  found := mpFindPath(ch.room, goalroom, dirs);
  if (found) then
  begin
    ch.sendBuffer('A path was found: ' + dirs + #13#10);
  end
  else
  begin
    ch.sendBuffer('There was no valid path found.'#13#10);
  end;

  if (trim(uppercase(arg2)) = 'GO') then
  begin
    if (length(dirs) = 0) then
    begin
      ch.sendBuffer('mpFindPath returned true, but an empty direction string. Perhaps you''re already at the specified vnum?'#13#10);
      exit;
    end;
    
    ch.sendBuffer('Following the path... hold on tight!'#13#10#13#10);
    for i := 1 to length(dirs) do
    begin
      interpret(ch, dirs[i]);
    end;
  end;
end;

procedure do_reload(ch : GCharacter; param : string);
var
  cmd : string;
  iterator : GIterator;
  npc : GNPCIndex;
  vict : GCharacter;
  count1, count2 : integer;
begin
  count1 := 0; count2 := 0;
  
  if (ch.IS_NPC()) then
  begin
    ch.sendBuffer('This command is only available to imms.'#13#10);
    exit;
  end;

  if (length(param) = 0) then
  begin
    ch.sendBuffer('Usage: RELOAD progs|namegen [silent]'#13#10#13#10);
    ch.sendBuffer('This command will reload certain parts of the mud online. When the '#13#10 +
                  'argument progs is used together with the argument silent, mobs won''t'#13#10 +
                  'emote when their mobprog is being reloaded.'#13#10);
    exit;
  end;

  param := one_argument(param, cmd);
  cmd := uppercase(cmd);

  if (cmd = 'PROGS') then
    begin
    iterator := npc_list.iterator();
    while (iterator.hasNext()) do
      begin
      npc := GNPCIndex(iterator.next());
      
      if (length(npc.progfile) <> 0) then
        begin
        if (npc.prog <> nil) then
          begin
          codeCache.remove(npc.progfile);
          npc.prog.Free();
          npc.prog := nil;
          end;
        
        npc.prog := loadCode(npc.progfile);
        inc(count1);
        end;
      end;
    iterator.Free();

    iterator := char_list.iterator();
    while (iterator.hasNext()) do
      begin
      vict := GCharacter(iterator.next());
      
      if (vict.IS_NPC() and (GNPC(vict).npc_index <> nil)) then
        begin
        if (length(GNPC(vict).npc_index.progfile) = 0) then
          continue;
        
        if (GNPC(vict).context <> nil) then
          begin
          GNPC(vict).context.Free();
          GNPC(vict).context := nil;
          end;
        GNPC(vict).context := GContext.Create();
        GNPC(vict).context.load(GNPC(vict).npc_index.prog);
        GNPC(vict).context.owner := vict;
        if (uppercase(param) <> 'SILENT') then
          interpret(vict, 'emote receives new instructions and twitches violently.');
        inc(count2);
        end;
      end;
    iterator.Free();

    ch.sendBuffer(Format('Reloaded progs on %d NPC indices and reinitialised contexts on %d mobs.'#13#10, [count1, count2]));
  end
  else
  if (cmd = 'NAMEGEN') then
  begin
    interpret(ch, 'namegen reload');
  end
  else
  begin
    ch.sendBuffer('Unrecognized option.');
  end;
end;

{procedure do_thunder(ch:GCharacter;param:string);
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Thunder what?'#13#10);
    exit;
    end;

  talk_channel(ch,param,CHANNEL_THUNDER,'thunder',AT_THUNDER);
end;}

procedure do_cloak(ch : GCharacter; param : string);
begin
  if (ch.IS_NPC) then
    exit;

  if (IS_SET(GPlayer(ch).flags, PLR_CLOAK)) then
    begin
    ch.sendBuffer('Cloak off.'#13#10);
    REMOVE_BIT(GPlayer(ch).flags, PLR_CLOAK);
    end
  else
    begin
    ch.sendBuffer('Cloak on.'#13#10);
    SET_BIT(GPlayer(ch).flags, PLR_CLOAK);
    end;
end;

// Purge objects from char - Nemesis
procedure do_purge(ch : GCharacter; param : string);
var 
  obj : GObject;
  vict : GCharacter;
  objstr, victstr : string;
  iterator : GIterator;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage: PURGE <object>/ALL <target>'#13#10);
    ch.sendBuffer('       PURGE ROOM'#13#10);
    exit;
    end;

  if (uppercase(param) = 'ROOM') then
    begin
    iterator := ch.room.objects.iterator();

    while (iterator.hasNext()) do
      begin
      obj := GObject(iterator.Next());

      obj.Free();
      end;

    iterator.Free();

    ch.sendBuffer('Ok, room purged.'#13#10);
    exit;
    end;

  param := one_argument(param, objstr);
  param := one_argument(param, victstr);

  vict := ch.room.findChar(ch, victstr);

  if (vict = nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;

  if (uppercase(objstr) = 'ALL') then
    begin
    iterator := vict.inventory.iterator();

    while (iterator.hasNext()) do
      begin
      obj := GObject(iterator.Next());

      obj.fromChar();
      obj.Free();
      end;
      
    iterator.Free();

    iterator := vict.equipment.iterator();

    while (iterator.hasNext()) do
      begin
      obj := GObject(iterator.Next());

      vict.affectObject(obj, true);

      obj.fromChar();
      obj.Free();
      end;
      
    iterator.Free();

    act(AT_REPORT,'All your items have been purged by $N.',false, vict, nil, ch, TO_CHAR);
    act(AT_REPORT,'You have purged all items of $N.',false, ch, nil, vict, TO_CHAR);
    exit;
    end;

  obj := vict.findInventory(objstr);

  if (obj = nil) then
    obj := vict.findEquipment(objstr);

  if (obj = nil) then
    obj := vict.findInventory(objstr);

  if (obj = nil) then
    begin
    ch.sendBuffer('That character does not have that object.'#13#10);
    exit;
    end;

  if (obj.worn <> '') then
    vict.affectObject(obj, true);

  act(AT_REPORT,'$p has been purged by $N.',false, vict, obj, ch, TO_CHAR);
  act(AT_REPORT,'You have purged $p of $N.',false, ch, obj, vict, TO_CHAR);

  obj.fromChar();
  obj.Free();
end;
