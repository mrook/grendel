procedure do_shutdown(ch:GCharacter;param:string);
var
   haltparam : string;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage: SHUTDOWN <stop/halt/reboot/copyover> [time]'#13#10#13#10);
    ch.sendBuffer('If time is not given, a default of 30 seconds is assumed.'#13#10);
    ch.sendBuffer('Using "stop" as a parameter halts the shutdown.'#13#10);
    ch.sendBuffer('Using "now" as time value enables immediate shutdown.'#13#10);
    exit;
    end;

  param:=one_argument(param, haltparam);

  if (length(param) > 0) then
    begin
    if (param = 'now') then
      boot_info.timer:=0
    else
      try
        boot_info.timer:=strtoint(param);
      except
        ch.sendBuffer('Boot timer must be a valid numeric value!'#13#10);
        exit;
      end
    end
  else
    boot_info.timer := 30;

  boot_info.started_by := ch;

  if (haltparam = 'stop') then
    begin
    act(AT_REPORT, 'Timer stopped.',false,ch,nil,nil,TO_CHAR);
    boot_info.boot_type := 0;
    boot_info.started_by := nil;
    boot_info.timer := -1;
    end
  else
  if (haltparam = 'reboot') then
    begin
    act(AT_REPORT,'REBOOT started.',false,ch,nil,nil,TO_CHAR);

    boot_info.boot_type:=BOOTTYPE_REBOOT;

    if (boot_info.timer = 0) then
      clean_thread.SetMessage(CLEAN_MUD_STOP)
    else
      clean_thread.SetMessage(CLEAN_BOOT_MSG);
    end
  else
  if (haltparam = 'halt') then
    begin
    act(AT_REPORT,'SHUTDOWN started.',false,ch,nil,nil,TO_CHAR);

    boot_info.boot_type:=BOOTTYPE_SHUTDOWN;

    if (boot_info.timer = 0) then
      clean_thread.SetMessage(CLEAN_MUD_STOP)
    else
      clean_thread.SetMessage(CLEAN_BOOT_MSG);
    end
  else
  if (haltparam = 'copyover') then
    begin
    act(AT_REPORT, 'COPYOVER started.',false,ch,nil,nil,TO_CHAR);

    boot_info.boot_type := BOOTTYPE_COPYOVER;

    if (boot_info.timer = 0) then
      clean_thread.SetMessage(CLEAN_MUD_STOP)
    else
      clean_thread.SetMessage(CLEAN_BOOT_MSG);
    end
  else
    begin
    ch.sendBuffer('Illegal parameter: use "stop", "halt", "reboot" or "copyover".'#13#10);
    exit;
    end;
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

procedure do_thunder(ch:GCharacter;param:string);
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Thunder what?'#13#10);
    exit;
    end;

  talk_channel(ch,param,CHANNEL_THUNDER,'thunder',AT_THUNDER);
end;

procedure do_wizinvis(ch:GCharacter;param:string);
var level:integer;
begin
  if (ch.IS_WIZINVIS) then
    begin
    act(AT_REPORT,'You feel yourself brightening.',false,ch,nil,nil,TO_CHAR);
    act(AT_REPORT,'A light shines and $n appears.',false,ch,nil,nil,TO_ROOM);
    REMOVE_BIT(ch.player^.flags,PLR_WIZINVIS);
    ch.player^.wiz_level:=0;
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
    SET_BIT(ch.player^.flags,PLR_WIZINVIS);
    ch.player^.wiz_level:=level;
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
      dam:=UMin(t.point.max_hp,800);
      damage(ch,t,dam,TYPE_SLAY);
      end;
    end;
end;

procedure do_advance(ch:GCharacter;param:string);
var vict:GCharacter;
    lvl,num,a:integer;
    vict_nm:string;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Advance whom?'#13#10);
    exit;
    end;
  param:=one_argument(param,vict_nm);
  vict:=findcharworld(ch,vict_nm);
  try
    lvl:=strtoint(param);
  except
    ch.sendBuffer('Invalid numeric format.'#13#10);
    exit;
  end;
  if (lvl>LEVEL_MAX) then
    ch.sendBuffer('Use GRACE to give a character immortal status.'#13#10)
  else
  if vict=nil then
    ch.sendBuffer('That character is not online right now.'#13#10)
  else
    begin
    num:=lvl-vict.level;
    vict.in_command:=true;
    for a:=1 to num do
      gain_xp(vict,vict.player^.xptogo);
    act(AT_REPORT,'You have advanced $N to level '+inttostr(vict.level)+'.',false,ch,nil,vict,TO_CHAR);
    act(AT_REPORT,'$N has advanced you to level '+inttostr(vict.level)+'!',false,vict,nil,ch,TO_CHAR);
    vict.in_command:=false;
    end;
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
procedure do_grace(ch:GCharacter;param:string);
var vict:GCharacter;
    //obj: OBJECT_DATA;
    obj : GObject;
    obj_node : GListnode;

    lev:integer;
    //vict_nm:array[0..63] of char;
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

    if (vict.level = 500) then
      begin
      { Set hps etc. to immortal level }
      vict.point.max_hp:=15000;
      vict.point.max_mv:=15000;
      vict.point.max_mana:=15000;
      vict.point.hp:=15000;
      vict.point.mv:=15000;
      vict.point.mana:=15000;
      vict.ability.str:=100;
      vict.ability.con:=100;
      vict.ability.dex:=100;
      vict.ability.int:=100;
      vict.ability.wis:=100;
      vict.sendBuffer(findHelp('M_IMMORTALIZE_').text);
      end
    else
      act(AT_REPORT,'You feel yourself growing... to a higher level of understanding.',false,vict,nil,nil,TO_CHAR);

    obj_node := vict.objects.head;

    while obj_node <> nil do
    begin
    	 vict.objects.remove(obj_node);
      obj_node := vict.objects.head;
    end;

    {if (vict.carried_first<>nil) then
      repeat
        obj:=vict.carried_last;
        extract_obj(obj);
      until (vict.carried_last=nil);}

    vict.level:=lev;
    act(AT_REPORT,#13#10'As you wake up... you find that all your possesions are... gone.',false,vict,nil,nil,TO_CHAR);
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
      vict.quit;

      ch.sendBuffer('Ok.'#13#10);
      write_console(vict.name + ' has been destroyed.');

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

      g := uppercase(stripl(s, ':'));

      if (g = 'LEVEL') then
        begin
        level := strtoint(striprbeg(s, ' '));

        if (level >= 990) then
          begin
          ch.sendBuffer('That player cannot be purged.'#13#10);
          exit;
          end;
        end;
    until (eof(f));

    closefile(f);

    write_console(param + ' has been destroyed.');
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
      act(AT_WHITE,'You force $N to "'+param+'".',false,ch,nil,vict,TO_CHAR);
    	 act(AT_WHITE,'$n forces you to "' + param + '"',false,ch,nil,vict,TO_VICT);
      interpret(vict,param);

      end;
    end;
end;

{Jago 5/Jan/01 : implemented do_transfer as done in MERC
									(implementation not quite identical to MERC)}
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
 victim : GCharacter;
 locn_name : string;
begin

 param := one_argument(param, locn_name);

	if length(locn_name) = 0 then
	begin
   ch.sendBuffer('Goto where?' + #13#10);
   exit;
 end;

 location := findLocation(ch, locn_name);

 if location = nil then
 begin
   ch.sendBuffer('No such location!' + #13#10);
   exit;
 end;

 if (IS_SET(location.flags, ROOM_PRIVATE)) then
   begin
   ch.sendBuffer('That room is private right now.' + #13#10);
   exit;
 end;

 if ch.fighting <> nil then
 begin
 	stopFighting(ch);
 end;

 {goto while hunting not tested! - result may be unpredictable!!}
 {if ch.hunting <> nil then
 begin
  ch.hunting := nil;
  REMOVE_BIT(ch.act_flags, ACT_HUNTING);
 end;}

  if not ch.IS_WIZINVIS then
  begin
    if (ch.player^.bamfout <> '') then
      act(AT_WHITE, ch.player^.bamfout,false,ch,nil,nil,TO_ROOM)
    else
      act(AT_WHITE,'$n leaves in a swirling mist.',false,ch,nil,nil,TO_ROOM);
  end;

  ch.fromRoom;
  ch.toRoom(location);

  if not ch.IS_WIZINVIS then
  begin
    if (ch.player^.bamfin <> '') then
      act(AT_WHITE, ch.player^.bamfin,false,ch,nil,nil,TO_ROOM)
    else
      act(AT_WHITE,'$n appears in a swirling mist.',false,ch,nil,nil,TO_ROOM);
  end;

  interpret(ch, 'look _AUTO');
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
procedure do_connections(ch:GCharacter;param:string);
var a:integer;
    s:string;
    conn: GConnection;
    conn_node : GListNode;
begin
  act(AT_REPORT, '$8[$B$1Nr.$A$8] [$B$1State           $A$8] [$B$1' + pad_string('IP', 32) + '$A$8] [$B$1Name$A$8]'#13#10,false,ch,nil,nil,TO_CHAR);

  a:=0;
  conn_node := connection_list.head;
  while conn_node <> nil do
  begin
  	 conn := GConnection(conn_node.element);

    if (conn.ch<>nil) then
      s := conn.ch.name
    else
      s := '-';

    act(AT_REPORT,'$7($B$7' + pad_integer_front(a,3) + '$A$7) '+
        pad_string(con_states[conn.state], 16) + '   ' +
        pad_string(conn.ip_string, 32) + '   ' +
        s,false,ch,nil,nil,TO_CHAR);
    inc(a);

    conn_node := conn_node.next;
  end;
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
  if (vict=nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end
  else
  if (vict = ch) then
    begin
    ch.player^.snooping.snooped_by := nil;
    ch.player^.snooping := nil;
    ch.sendBuffer('No longer snooping.'#13#10);
    exit;
    end;

  act(AT_YELLOW,'Started snooping $N.',false,ch,nil,vict,TO_CHAR);
  ch.player^.snooping := vict;
  vict.snooped_by:=ch;
end;

procedure do_loadup(ch:GCharacter;param:string);
var vict : GCharacter;
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

  vict := GCharacter.Create;
  vict.load(param);
  SET_BIT(vict.player^.flags,PLR_LOADED);
  SET_BIT(vict.player^.flags,PLR_LINKLESS);

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
  victim:=FindCharWorld(ch,param);
  if (victim=nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;
  if (IS_SET(victim.act_flags,ACT_LOG)) then
    begin
    REMOVE_BIT(victim.act_flags,ACT_LOG);
    act(AT_REPORT,'No longer logging $N.',false,ch,nil,victim,TO_CHAR);
    end
  else
    begin
    SET_BIT(victim.act_flags,ACT_LOG);
    act(AT_REPORT,'Started logging $N.',false,ch,nil,victim,TO_CHAR);
    end;
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
procedure do_uptime(ch:GCharacter;param:string);
var f:file;
begin
  calculateonline;
  act(AT_REPORT,'[' + version_info + ', ' + version_number + '] '#13#10 + system_info.mud_name+#13#10,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'Online time:       ' + online_time,false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'System time:       ' + DateTimeToStr(Now),false,ch,nil,nil,TO_CHAR);

  status:=GetHeapStatus;
  act(AT_REPORT,'Heap allocated:    ' + inttostr(status.totalallocated)+' byte(s)',false,ch,nil,nil,TO_CHAR);
  assignfile(f,'grendel.exe');
  {$I-}
  filemode:=0;
  reset(f,1);
  {$I+}
  if IOResult<>0 then
    begin
    act(AT_REPORT,'Could not find grendel.exe in active directory!',false,ch,nil,nil,TO_CHAR);
    exit;
    end;
  act(AT_REPORT, 'Executable size:   '+inttostr(filesize(f)),false,ch,nil,nil,TO_CHAR);
  close(f);
end;

procedure do_switch(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  if (length(param)=0) then
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

  if (vict.conn <> nil) then
    begin
    act(AT_REPORT,'$N is already switched.',false,ch,nil,vict,TO_CHAR);
    exit;
    end;

  ch.sendBuffer('Ok.'#13#10);
  GConnection(ch.conn).ch := vict;
  GConnection(ch.conn).original := ch;
  vict.conn := ch.conn;
  ch.conn := nil;
  ch.player^.switched := vict;
end;

procedure do_return(ch:GCharacter;param:string);
var vict:GCharacter;
begin
  if (GConnection(ch.conn).original = nil) then
    begin
    act(AT_REPORT,'You aren''t switched.',false,ch,nil,nil,TO_CHAR);
    exit;
    end;

  vict := GConnection(ch.conn).original;
  vict.conn := ch.conn;
  GConnection(ch.conn).original := nil;
  GConnection(ch.conn).ch := vict;
  vict.player^.switched := nil;
  ch.conn := nil;

  ch.sendBuffer('Ok.'#13#10);

  if (param = 'sub') then
    vict.emptyBuffer;
end;

procedure do_wizhelp(ch:GCharacter;param:string);
var
  lev, a : integer;
  node : GListNode;
  cmd : GCommand;
  buf : string;
  count : integer;
begin
  buf := #13#10 + ch.ansiColor(3) + ' ' + add_chars(78, '---- Available immortal commands ', '-') + ch.ansiColor(7) + #13#10#13#10;
  ch.sendPager(buf);

  lev := ch.getTrust;

  count := 0;

  for a := 0 to commands.hashsize - 1 do
    begin
    node := commands.bucketList[a].head;

    while (node <> nil) do
      begin
      cmd := node.element;

      if (cmd.level > LEVEL_MAX) and (cmd.level <= lev) then
        begin
        ch.sendPager(pad_string(lowercase(cmd.name), 14));

        inc(count);

        if (count = 5) then
          begin
          ch.sendPager(#13#10);
          count := 0;
          end;
        end;

      node := node.next;
      end;
    end;

  ch.sendPager(#13#10);
end;

{Jago 5/Jan/01 : implemented do_restore to use GCharacter instead of CHAR_DATA, }
{							added restore all functionality}
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

    while vict_node <> nil do begin
      victim  := GCharacter(vict_node.element);
      if (victim <> ch) and (not victim.IS_NPC) then
      begin
        victim.point.hp:=victim.point.max_hp;
        victim.point.mv:=victim.point.max_mv;
        victim.point.mana:=victim.point.max_mana;
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

    victim.point.hp:=victim.point.max_hp;
    victim.point.mv:=victim.point.max_mv;
    victim.point.mana:=victim.point.max_mana;

    ch.sendBuffer('Ok.'#13#10);
    act(AT_REPORT,'$N has restored you.',false,victim,nil,ch,TO_CHAR);
  end;
end;

procedure do_freeze(ch:GCharacter;param:string);
var victim:GCharacter;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Usage:  FREEZE <character>'#13#10#13#10);
    ch.sendBuffer('If the character is already frozen, this will unfreeze.'#13#10);
    exit;
    end;

  victim := findCharWorld(ch,param);
  if (victim=nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;

  if (victim.IS_NPC) then
    begin
    ch.sendBuffer('Can only freeze players.'#13#10);
    exit;
    end;

  ch.sendBuffer('Ok.'#13#10);
  if (IS_SET(victim.player^.flags,PLR_FROZEN)) then
    begin
    act(AT_REPORT,'You have been un-frozen by $N.',false,victim,nil,ch,TO_CHAR);
    REMOVE_BIT(victim.player^.flags,PLR_FROZEN);
    end
  else
    begin
    act(AT_REPORT,'You have been frozen by $N.',false,victim,nil,ch,TO_CHAR);
    SET_BIT(victim.player^.flags,PLR_FROZEN);
    end;
end;

procedure do_silence(ch:GCharacter;param:string);
var victim:GCharacter;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer( 'Usage:  SILENCE <character>'#13#10#13#10);
    ch.sendBuffer( 'If the character is already silenced, this will unsilence.'#13#10);
    exit;
    end;

  victim := findCharWorld(ch,param);
  if (victim=nil) then
    begin
    ch.sendBuffer('That character does not exist.'#13#10);
    exit;
    end;

  if (victim.IS_NPC) then
    begin
    ch.sendBuffer('Can only silence players.'#13#10);
    exit;
    end;

  ch.sendBuffer('Ok.'#13#10);
  if (IS_SET(victim.player^.flags,PLR_SILENCED)) then
    begin
    act(AT_REPORT,'You have been un-silenced by $N.',false,victim,nil,ch,TO_CHAR);
    REMOVE_BIT(victim.player^.flags,PLR_SILENCED);
    end
  else
    begin
    act(AT_REPORT,'You have been silenced by $N.',false,victim,nil,ch,TO_CHAR);
    SET_BIT(victim.player^.flags,PLR_SILENCED);
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
      if rch <> ch then
      	interpret(rch, 'sit');
    end;
  	 rch_node := rch_node.next;
  end;

  ch.sendBuffer( 'Ok.'#13#10);
end;

{Jago 5/Jan/2001 : repaired to work with v 0.3.0}
procedure do_areas(ch:GCharacter; param:string);
var
	//area:AREA_DATA;
	area: GArea;
 area_node : GListNode;
begin
  act(AT_DCYAN, 'Area name                          Author                   VNum Range'#13#10, false, ch, nil, nil, TO_CHAR);

  area_node := area_list.head;
  while area_node <> nil do
  begin
   area := GArea(area_node.element);
		act(AT_REPORT, pad_string(area.name, 35) + pad_string(area.author, 25) + pad_integer(area.r_lo, 5) + ' - ' + pad_integer(area.r_hi, 5), false, ch, nil, nil, TO_CHAR);
		area_node := area_node.next;
  end;
end;

{Jago 6/Jan/2001 - repaired for v 0.3}
procedure do_disconnect(ch : GCharacter; param : string);
var
		 sock : integer;
    conn : GConnection;
    conn_f : GConnection;
    conn_node : GListNode;
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

  conn_node := connection_list.head;
  conn_f := nil;
  while conn_node <> nil do
  begin
    conn := GConnection(conn_node.element);

    if (conn.socket = sock) then
    begin
      conn_f := conn;
      break;
    end;

    conn_node := conn_node.next;
  end;

  if (conn_f = nil) then
  begin
    ch.sendBuffer( 'That socket number was not found.'#13#10);
    exit;
  end;

  closesocket(sock);
  ch.sendBuffer( 'Ok.'#13#10);
end;

procedure do_bamfin(ch : GCharacter; param : string);
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  BAMFIN <line or NULL to reset>'#13#10);
    if (ch.player^.bamfin <> '') then
      ch.sendBuffer('Currently: ' + ch.player^.bamfin + #13#10);
    exit;
    end;

  if (uppercase(param) = 'NULL') then
    ch.player^.bamfin := ''
  else
    ch.player^.bamfin := param;

  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_bamfout(ch : GCharacter; param : string);
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Usage:  BAMFOUT <line or NULL to reset>'#13#10);
    if (ch.player^.bamfout <> '') then
      ch.sendBuffer('Currently: ' + ch.player^.bamfout + #13#10);
    exit;
    end;

  if (uppercase(param) = 'NULL') then
    ch.player^.bamfout := ''
  else
    ch.player^.bamfout := param;

  ch.sendBuffer('Ok.'#13#10);
end;

procedure do_sset(ch : GCharacter; param : string);
var vict : GCharacter;
    victim, skill : string;
    sn,perc:integer;
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
    for sn := 0 to num_skills -1 do
      vict.learned[sn] := perc;

    vict.sendBuffer('You feel a great power increasing your skills.'#13#10);
    end
  else
    begin
    sn := findSkill(skill);

    if (sn=-1) then
      begin
      ch.sendBuffer('That skill does not exist.'#13#10);
      exit;
      end;

    vict.learned[sn] := perc;
    vict.sendBuffer('You feel a great power increasing your skills.'#13#10);
    end;

  ch.sendBuffer('Ok.'#13#10);
end;

{ Nourish - Nemesis }
procedure do_nourish(ch:GCharacter;param:string);
var victim: GCharacter;
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

    while vict_node <> nil do
      begin
      victim  := GCharacter(vict_node.element);
      if (victim <> ch) and (not victim.IS_NPC) then
        begin
        victim.player^.condition[COND_FULL]:=100;
        victim.player^.condition[COND_THIRST]:=100;
        victim.player^.condition[COND_DRUNK]:=0;
        victim.player^.condition[COND_HIGH]:=0;
        victim.player^.condition[COND_CAFFEINE]:=0;
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
    victim := findCharWorld(ch,param);

    if (victim = nil) or (victim.IS_NPC) then
      begin
      ch.sendBuffer('That player does not exist.'#13#10);
      exit;
      end;
    
    victim.player^.condition[COND_FULL]:=100;
    victim.player^.condition[COND_THIRST]:=100;
    victim.player^.condition[COND_DRUNK]:=0;
    victim.player^.condition[COND_HIGH]:=0;
    victim.player^.condition[COND_CAFFEINE]:=0;

    act(AT_REPORT,'You have nourished $N.',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'$N has nourished you.',false,victim,nil,ch,TO_CHAR);
  end;
end;

{ Revive player when killed - Nemesis }
procedure do_revive(ch:GCharacter; param:string);
var obj : GObject;
    corpseroom : GRoom;
    victim : GCharacter;
    number,count : integer;
    conn : GConnection;
    conn_node : GListNode;
    buf : string;
begin
  // Without argument shows existing corpses, decay timer and VNUM.

  if (length(param) = 0) then
    begin
    act(AT_REPORT,'Timer - Existing corpses:' + #13#10,false,ch,nil,nil,TO_CHAR);

    count := 0;

    conn_node := connection_list.head;

    while (conn_node <> nil) do
      begin

      conn := GConnection(conn_node.element);

      obj := findObjectWorld('the corpse of ' + conn.ch.name);

      if (obj <> nil) then
        begin
        inc(count);

        buf := buf + ' (' + ansiColor(7,0) + pad_integer_front(obj.timer,2) +
               ansiColor(2,0) + ') ' + obj.name + ' in room: ' + ansiColor(6,0) +
               inttostr(obj.room.vnum) + ansiColor(2,0) + '.' + #13#10;
        end;

      conn_node := conn_node.next;
      end;

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
