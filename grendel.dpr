{
  The Grendel Project - Win32 MUD Server
  Copyright (c) 2000,2001 by Michiel Rook (Grimlord)

  Contact information:
  Webpage:            http://grendel.mudcenter.com/
  E-Mail:             ***REMOVED***@takeover.nl

  Please observe LICENSE.TXT prior to using this software.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License, Version 2,
  as published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details (LICENSE.TXT).

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  $Id: grendel.dpr,v 1.42 2001/07/28 22:18:18 ***REMOVED*** Exp $
}

program grendel;

{$DESCRIPTION 'The Grendel Project - Win32 MUD Server. Copyright (c) 2000,2001 by Michiel Rook.'}
{$APPTYPE CONSOLE}

{$DEFINE Grendel}

{$W+}

{%File 'include\command.inc'}
{%File 'include\cmd_comm.inc'}
{%File 'include\cmd_fight.inc'}
{%File 'include\cmd_imm.inc'}
{%File 'include\cmd_info.inc'}
{%File 'include\cmd_magic.inc'}
{%File 'include\cmd_move.inc'}
{%File 'include\cmd_obj.inc'}
{%File 'include\cmd_shops.inc'}
{%File 'include\cmd_skill.inc'}
{%File 'include\cmd_build.inc'}

uses
  SysUtils,
{$IFDEF WIN32}
  Windows,
  mudsystem in 'units\mudsystem.pas',
  constants in 'units\constants.pas',
  dtypes in 'units\dtypes.pas',
  conns in 'units\conns.pas',
  util in 'units\util.pas',
  Strip in 'units\strip.pas',
  area in 'units\area.pas',
  fsys in 'units\fsys.pas',
  mudthread in 'units\mudthread.pas',
  AnsiIO in 'units\ansiio.pas',
  chars in 'units\chars.pas',
  race in 'units\race.pas',
  fight in 'units\fight.pas',
  skills in 'units\skills.pas',
  mudhelp in 'units\mudhelp.pas',
  magic in 'units\magic.pas',
  update in 'units\update.pas',
  clan in 'units\clan.pas',
  clean in 'units\clean.pas',
  Winsock2 in 'units\winsock2.pas',
  md5 in 'units\md5.pas',
  MemCheck in 'units\MemCheck.pas',
  timers in 'units\timers.pas',
  debug in 'units\debug.pas',
  mudspell in 'units\mudspell.pas',
  LibXmlParser in 'units\LibXmlParser.pas',
  NameGen in 'units\NameGen.pas',
  bulletinboard in 'units\bulletinboard.pas',
  Channels in 'units\Channels.pas',
  progs in 'units\progs.pas',
  gasmdef in 'gmc\gasmdef.pas',
  gvm in 'gmc\gvm.pas',
  modules in 'units\modules.pas';
{$ENDIF}
{$IFDEF LINUX}
  Libc,
  mudsystem in 'units/mudsystem.pas',
  constants in 'units/constants.pas',
  dtypes in 'units/dtypes.pas',
  conns in 'units/conns.pas',
  util in 'units/util.pas',
  Strip in 'units/strip.pas',
  area in 'units/area.pas',
  fsys in 'units/fsys.pas',
  mudthread in 'units/mudthread.pas',
  AnsiIO in 'units/ansiio.pas',
  chars in 'units/chars.pas',
  race in 'units/race.pas',
  fight in 'units/fight.pas',
  skills in 'units/skills.pas',
  mudhelp in 'units/mudhelp.pas',
  magic in 'units/magic.pas',
  update in 'units/update.pas',
  clan in 'units/clan.pas',
  clean in 'units/clean.pas',
  md5 in 'units/md5.pas',
  timers in 'units/timers.pas',
  debug in 'units/debug.pas',
  mudspell in 'units/mudspell.pas',
  LibXmlParser in 'units/LibXmlParser.pas',
  NameGen in 'units/NameGen.pas',
  bulletinboard in 'units/bulletinboard.pas',
  Channels in 'units/Channels.pas',
  progs in 'units/progs.pas',
  gasmdef in 'gmc/gasmdef.pas',
  gvm in 'gmc/gvm.pas',
  modules in 'units/modules.pas';
{$ENDIF}

const pipeName : pchar = '\\.\pipe\grendel';


var
{$IFDEF WIN32}
   hWSAData : TWSAData;
{$ENDIF}

   use_ipv4, use_ipv6 : boolean;

   listenv4, listenv6 : TSocket;

   addrv4 : TSockAddrIn;
   addrv6 : TSockAddr6;
   ssv6 : TSockAddr_Storage;
   addrv6p : PSockAddr;

   client_addr : TSockAddr_Storage;

   old_exitproc : pointer;


procedure detect_protocols;
{$IFDEF WIN32}
var
   a, t : DWORD;
   lp : array[0..1] of integer;
   prot : pointer;
   pprot : LPWSAProtocol_Info;
   buf : string;
begin
  t := 0;
  lp[0] := IPPROTO_TCP;
  lp[1] := 0;

  WSAEnumProtocols(@lp, nil, t);

  getmem(prot, t);
  pprot := prot;

  t := WSAEnumProtocols(@lp, pprot, t);

  for a := 0 to t - 1 do
    begin
    pprot := pointer(integer(prot) + (a * sizeof(TWSAProtocol_Info)));

    if (pprot^.iAddressFamily = AF_INET) then
      use_ipv4 := true
    else
    if (pprot^.iAddressFamily = AF_INET6) then
      use_ipv6 := true;
    end;

  buf := 'Supported address families:';

  if (use_ipv4) then
    buf := buf + ' IPv4';

  if (use_ipv6) then
    buf := buf + ' IPv6';

  write_console(buf);

  freemem(prot, t);
end;
{$ELSE}
begin
  use_ipv4 := true;
  use_ipv6 := true;
end;
{$ENDIF}

procedure startup_tcpip;
var rc : integer;
    ver : integer;
begin
{$IFDEF WIN32}
  ver := WINSOCK_VERSION;

  if (WSAStartup(ver, hWSAData) <> 0) then
    write_console('ERROR: WSAStartup failed.');
{$ENDIF}

  detect_protocols;

  { IPv4 }
  if (use_ipv4) then
    begin
    listenv4 := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

    if (listenv4 = INVALID_SOCKET) then
      write_console('ERROR: Could not create IPv4 socket.');

    addrv4.sin_family := AF_INET;
    addrv4.sin_port := htons(system_info.port);
    addrv4.sin_addr.s_addr := system_info.bind_ip;

    if (bind(listenv4, TSockaddr(addrv4), sizeof(addrv4)) = -1) then
      begin
{$IFDEF LINUX}
      __close(listenv4);
{$ELSE}
      closesocket(listenv4);
{$ENDIF}

      raise GException.Create('startup_tcpip', 'Could not bind to IPv4, port ' + inttostr(system_info.port));
      end;

    rc := listen(listenv4, 15);

    if (rc > 0) then
      raise GException.Create('startup_tcpip', 'Could not listen on IPv4 socket')
    else
      write_console('IPv4 bound on port ' + inttostr(system_info.port) + '.');
    end;

  { IPv6 }
  if (use_ipv6) then
    begin
    listenv6 := socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);

    if (listenv6 = INVALID_SOCKET) then
      write_console('ERROR: Could not create IPv6 socket.');

    fillchar(addrv6, sizeof(TSockAddr6), 0);

    addrv6.sin6_family := AF_INET6;
    addrv6.sin6_port := htons(system_info.port6);

    move(addrv6, ssv6, sizeof(addrv6));

    addrv6p := @ssv6;

    if (bind(listenv6, addrv6p^, 128) = -1) then
      begin
{$IFDEF LINUX}
      __close(listenv6);
{$ELSE}
      closesocket(listenv6);
{$ENDIF}

      write_console('ERROR: Could not bind to IPv6, port ' + inttostr(system_info.port));
      end
    else
      begin
      rc := listen(listenv6, 15);

      if (rc > 0) then
        write_console('ERROR: Could not listen on IPv6 socket.')
      else
        write_console('IPv6 bound on port ' + inttostr(system_info.port6) + '.');
      end;
    end;
end;

procedure flushConnections;
var
   ch : GCharacter;
   node : GListNode;
begin
  node := char_list.head;

  while (node <> nil) do
    begin
    ch := node.element;
    node := node.next;

    if (not ch.IS_NPC) then
      GPlayer(ch).quit;
    end;
end;

procedure cleanupServer();
var
   node : GListNode;
begin
  mud_booted := false;

  timer_thread.Terminate;
  clean_thread.Terminate;

  saveMudState();

  write_console('Releasing allocated memory...');

  try
    node := char_list.tail;
    while (node <> nil) do
      begin
      GCharacter(node.element).extract(true);
      node := char_list.tail;
      end;

    node := object_list.tail;
    while (node <> nil) do
      begin
      GObject(node.element).extract;
      node := object_list.tail;
      end;

    cleanChars;
    cleanObjects;

    char_list.Free;
    object_list.Free;

    // clean up rooms and all
    area_list.clean;
    room_list.clear;
    shop_list.clean;
    teleport_list.clean;
    extracted_object_list.clean;
    extracted_chars.clean;
    npc_list.clean;
    obj_list.Clean;
    race_list.clean;
    clan_list.clean;
    help_files.clean;
    dm_msg.clean;
    notes.clean;

    notes.Free;
    area_list.Free;
    room_list.Free;
    shop_list.Free;
    teleport_list.Free;
    extracted_object_list.Free;
    extracted_chars.Free;
    npc_list.Free;
    obj_list.Free;
    race_list.Free;
    clan_list.Free;
    help_files.Free;
    dm_msg.Free;

    skill_table.Free;

    socials.Free;
    str_hash.Free;
    auction_good.Free;
    auction_evil.Free;
    banned_masks.Free;

    if (namegenerator_enabled) then
    begin
      PhonemeList.Clean();
      PhonemeList.Free();
      NameTemplateList.Clean();
      NameTemplateList.Free();
    end;
    
    connection_list.clean;
    connection_list.Free;
    commands.Free;
  except
    on E : EExternal do
    begin
      bugreport('cleanup', 'grendel.dpr', 'Cleanup procedure failed, terminating now.');
      outputError(E);
    end;
  end;

  if (use_ipv4) then
    begin
{$IFDEF LINUX}
    __close(listenv4);
{$ELSE}
    closesocket(listenv4);
{$ENDIF}
    listenv4 := -1;
    end;

  if (use_ipv6) then
    begin
{$IFDEF LINUX}
    __close(listenv6);
{$ELSE}
    closesocket(listenv6);
{$ENDIF}
    listenv6 := -1;
    end;

{$IFDEF WIN32}
  WSACleanup;
{$ENDIF}

  write_console('Cleanup complete.');
  if (TTextRec(logfile).mode = fmOutput) then
    CloseFile(LogFile);
end;

procedure reboot_mud;
{$IFDEF WIN32}
var
  SI: TStartupInfo;
  PI: TProcessInformation;
{$ENDIF}
begin
  write_console('Server rebooting...');
  try

    if MUD_Booted then
      flushConnections;

    { wait for users to logout }
    Sleep(1000);
  except
    write_console('Exception caught while cleaning up memory');
  end;

  cleanupServer();

{$IFDEF WIN32}
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.wShowWindow := sw_show;

  if not CreateProcess('grendel.exe',Nil, Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI) then
    bugreport('reboot_mud', 'grendel.dpr', 'Could not execute grendel.exe, reboot failed!');
{$ENDIF}
end;

procedure copyover_mud;
{$IFDEF WIN32}
var
   SI: TStartupInfo;
   PI: TProcessInformation;
   pipe : THandle;
   node, node_next : GListNode;
   conn : GConnection;
   w, len : cardinal;
   prot : TWSAProtocol_Info;
   name : array[0..1023] of char;
begin
  write_console('Server starting copyover...');

  node := connection_list.head;

  while (node <> nil) do
    begin
    conn := node.element;
    node_next := node.next;

    if (conn.state = CON_PLAYING) then
      begin
      stopfighting(conn.ch);
  		conn.ch.emptyBuffer;
      conn.send(#13#10'Slowly, you feel the world as you know it fading away in wisps of steam...'#13#10#13#10);
      end
    else
      begin
      conn.send(#13#10'This server is rebooting, please continue in a few minutes.'#13#10#13#10);
      conn.thread.terminate;
      end;

    node := node_next;
    end;

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.wShowWindow := sw_show;

  if (not CreateProcess('copyover.exe', nil, Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI)) then
    begin
    bugreport('copyover_mud', 'grendel.dpr', 'Could not execute copyover.exe, copyover failed!');
    reboot_mud;
    end;

  pipe := CreateNamedPipe(pipeName, PIPE_ACCESS_DUPLEX, PIPE_WAIT or PIPE_TYPE_BYTE or PIPE_READMODE_BYTE, 10, 0, 0, 1000, nil);

  if (pipe = INVALID_HANDLE_VALUE) then
    begin
    writeln('Could not create pipe: ', GetLastError);
    exit;
    end;

  if (not ConnectNamedPipe(pipe, nil)) then
    begin
    bugreport('copyover_mud', 'grendel.dpr', 'Pipe did not initialize correctly!');
    reboot_mud;
    end;

  node := connection_list.head;

  while (node <> nil) do
    begin
    conn := node.element;
    node_next := node.next;

    if (WSADuplicateSocket(conn.socket, PI.dwProcessId, @prot) = -1) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'WSADuplicateSocket failed');
      reboot_mud;
      end;

    if (not WriteFile(pipe, prot, sizeof(prot), w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
      reboot_mud;
      end;

    strpcopy(name, conn.ch.name^);
    len := strlen(name);

    if (not WriteFile(pipe, len, 4, w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
      reboot_mud;
      end;

    if (not WriteFile(pipe, name, len, w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe');
      reboot_mud;
      end;

    conn.ch.save(conn.ch.name^);
    conn.thread.terminate;

    node := node_next;
    end;

  Sleep(500);

  CloseHandle(pipe);

  cleanupServer();
end;
{$ELSE}
begin
  write_console('Copyover not supported on this platform.');
end;
{$ENDIF}

procedure shutdown_mud;
begin
  write_console('Server shutting down...');

  try
    if MUD_Booted then
      flushConnections;

    Sleep(1000);
  except
    write_console('Could not flush connections while shutting down server');
  end;

  cleanupServer();
end;

procedure sendtoall(s : string);
var
   node : GListNode;
   conn : GConnection;
begin
  node := connection_list.head;

  while (node <> nil) do
    begin
    conn := node.element;

    conn.send(s);

    node := node.next;
    end;
end;

{ our exit procedure, catches the server when unstable }
{ This is one of the most important pieces of code: the exit handler.
  These lines make sure that if the server crashes (due to illegal memory
  access, file operations, overload, etc.) the players are logged out
  and their data is saved properly. Also, this routine makes sure the
  server reboots automatically, no script needed! - Grimlord }
procedure reboot_exitproc;far;
begin
  { okay, so we crashed :) }
  if (not grace_exit) then
    begin
    sendtoall('------ GAME CRASH DETECTED! ---- Saving all players.'#13#10#13#10);
    sendtoall('The server should be back online in less than a minute.'#13#10);
    sendtoall('If the server doesn''t auto-reboot, please notify'#13#10);
    sendtoall(pchar('the administration, '+system_info.admin_email+'.'#13#10));

    { save all characters and try to unlog before quitting }
    flushConnections;

    Sleep(1000);

    { give operator/logfile a message }
    bugreport('CRASH', 'grendel.dpr', 'CRASH WARNING -- SERVER IS UNSTABLE, WILL TRY TO REBOOT');

    write_console('---- CRASH TERMINATE. REBOOTING SERVER ----');

    { close logfile }
    if TTextRec(logfile).mode=fmOutput then
      CloseFile(LogFile);
    boot_type := BOOTTYPE_REBOOT;
    end;

  exitproc:=old_exitproc;

  { reboot }
  if (boot_type = BOOTTYPE_REBOOT) then
    reboot_mud
  else
  { copyover }
  if (boot_type = BOOTTYPE_COPYOVER) then
    begin
    if (connection_list.getSize > 0) then
      copyover_mud
    else
      reboot_mud;
    end
  else
    shutdown_mud;
end;

procedure bootServer();
var
  s : string;
begin
  { open a standard log file, filename is given by current system time }
  AssignFile(LogFile, translateFileName('logs\' + FormatDateTime('yyyymmdd-hhnnss', Now) + '.log'));

  {$I-}
  rewrite(LogFile);
  {$I+}

  if (IOResult <> 0) then
    write_console('NOTE: Could not open logfile. Messages are not being logged.');

{$IFDEF WIN32}
  SetConsoleTitle(version_info + ', ' + version_number + '(Booting)');
{$ENDIF}

  write_direct(version_info + ', ' + version_number + '.');
  write_direct(version_copyright + '.');
  write_direct('This is free software, with ABSOLUTELY NO WARRANTY; view LICENSE.TXT.'#13#10);
  write_console('Booting server...');

  try
    load_system;

    s := FormatDateTime('ddddd', Now);
    write_console('Booting "' + system_info.mud_name + '" database, ' + s + '.');

    write_console('Initializing GMC contexts...');
    init_progs;
    write_console('Loading skills...');
    load_skills;
    write_console('Loading races...');
    load_races;
    write_console('Loading clans...');
    load_clans;
    write_console('Loading channels...');
    load_channels();
    write_console('Loading areas...');
    load_areas;
    write_console('Loading help...');
    load_help('help.dat');
    write_console('Loading namegenerator data...');
    loadNameTables(NameTablesDataFile);
    write_console('Loading noteboards...');
    load_notes('boards.dat');
    write_console('Loading modules...');
    loadModules();
    write_console('Loading texts...');
    load_commands;
    load_socials;
    load_damage;
    write_console('Loading mud state...');
    loadMudState();

    write_console('String hash stats: ');
    str_hash.hashStats;

    randomize;

    use_ipv4 := false;
    use_ipv6 := false;
    startup_tcpip;

    ExitProc := @reboot_exitproc;

    BootTime := Now;

    update_time;

    time_info.day := 1;
    time_info.month := 1;
    time_info.year := 1;

    boot_type := 0;
    bg_info.count := -1;
    boot_info.timer := -1;
    mud_booted:=true;

    registerTimer('teleports', update_teleports, 1, true);
    registerTimer('fighting', update_fighting, CPULSE_VIOLENCE, true);
    registerTimer('battleground', update_battleground, CPULSE_VIOLENCE, true);
    registerTimer('objects', update_objects, CPULSE_TICK, true);
    registerTimer('characters', update_chars, CPULSE_TICK, true);
    registerTimer('gametime', update_time, CPULSE_GAMETIME, true);

    timer_thread := GTimerThread.Create;
    clean_thread := GCleanThread.Create;

    calculateonline;
  except
    on E: GException do
      begin
      write_console('Fatal error while booting: ' + E.Message);
      halt;
      end;
  end;
end;

function send_to_socket(sock : TSocket; s : string) : integer;
begin
  send_to_socket := send(sock, s[1], length(s), 0);
end;

procedure accept_connection(list_sock : TSocket);
var
   ac : TSocket;
   cl : PSockAddr;
   len : integer;
begin
  cl := @client_addr;
  len := 128;

{$IFDEF VER130}
  ac := accept(list_sock, cl^, len);
{$ELSE}
  ac := accept(list_sock, cl, @len);
{$ENDIF}

  // set non-blocking mode

{$IFDEF WIN32}
  len := 1;
  len := ioctlsocket(ac, FIONBIO, len);
{$ELSE}
  len := fcntl(ac, F_GETFL, 0);

  if (len <> -1) then
    fcntl(ac, F_SETFL, len or O_NONBLOCK);
{$ENDIF}

  if (boot_info.timer >= 0) then
    begin
    send_to_socket(ac, system_info.mud_name+#13#10#13#10);
    send_to_socket(ac, 'Currently, this server is in the process of a reboot.'#13#10);
    send_to_socket(ac, 'Please try again later.'#13#10);
    send_to_socket(ac, 'For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

{$IFDEF LINUX}
    __close(ac);
{$ELSE}
    closesocket(ac);
{$ENDIF}
    end
  else
  if system_info.deny_newconns then
    begin
    send_to_socket(ac, system_info.mud_name+#13#10#13#10);
    send_to_socket(ac, 'Currently, this server is refusing new connections.'#13#10);
    send_to_socket(ac, 'Please try again later.'#13#10);
    send_to_socket(ac, 'For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

{$IFDEF LINUX}
    __close(ac);
{$ELSE}
    closesocket(ac);
{$ENDIF}
    end
  else
  if (connection_list.getSize >= system_info.max_conns) then
    begin
    send_to_socket(ac, system_info.mud_name+#13#10#13#10);
    send_to_socket(ac, 'Currently, this server is too busy to accept new connections.'#13#10);
    send_to_socket(ac, 'Please try again later.'#13#10);
    send_to_socket(ac, 'For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

{$IFDEF LINUX}
    __close(ac);
{$ELSE}
    closesocket(ac);
{$ENDIF}
    end
  else
    GGameThread.Create(ac, client_addr, false, '');
end;

procedure game_loop;
var
  accept_set : TFDSet;
  accept_val : TTimeVal;
begin
  while (true) do
    begin
    if (use_ipv4) and (listenv4 >= 0) then
      begin
      FD_ZERO(accept_set);
      FD_SET(listenv4, accept_set);

      accept_val.tv_sec:=0;
      accept_val.tv_usec:=0;

      if (select(listenv4 + 1, @accept_set, nil, nil, @accept_val) <> 0) then
        accept_connection(listenv4);
      end;

    if (use_ipv6) and (listenv6 >= 0) then
      begin
      FD_ZERO(accept_set);
      FD_SET(listenv6, accept_set);

      accept_val.tv_sec:=0;
      accept_val.tv_usec:=0;

      if (select(listenv6 + 1, @accept_set, nil, nil, @accept_val) <> 0) then
        accept_connection(listenv6);
      end;

//    usleep(500000);
    sleep(500);
    end;
end;

{$IFDEF WIN32}
function ctrl_handler(event:dword):boolean;
begin
  ctrl_handler:=true;
  grace_exit:=true;
  SetConsoleCtrlHandler(@ctrl_handler, false);
  halt;
end;
{$ENDIF}

procedure from_copyover;
{$IFDEF WIN32}
var
   pipe : THandle;
   w, len : cardinal;
   prot : TWSAProtocol_Info;
   g : array[0..1023] of char;
   suc : boolean;
   sock : TSocket;
   cl : PSockAddr;
   l : integer;
begin
  pipe := INVALID_HANDLE_VALUE;

  while (true) do
    begin
    pipe := CreateFile(pipeName, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);

    if (pipe <> INVALID_HANDLE_VALUE) then
      break;

    if (GetLastError() <> ERROR_PIPE_BUSY) then
      begin
      bugreport('from_copyover', 'grendel.dpr', 'Could not restart from copyover');
			exit;
      end;

    // All pipe instances are busy, so wait a second

    if (not WaitNamedPipe(pipeName, 1000)) then
      begin
      bugreport('from_copyover', 'grendel.dpr', 'Could not restart from copyover');
			exit;
      end;
  end;

  sock := -1;

  repeat
    suc := ReadFile(pipe, prot, sizeof(prot), w, nil);

    if (suc) then
      sock := WSASocket(prot.iAddressFamily, SOCK_STREAM, IPPROTO_IP, @prot, 0, 0);

    suc := ReadFile(pipe, len, 4, w, nil);
    suc := ReadFile(pipe, g, len, w, nil);

    if (suc) and (sock <> -1) then
      begin
      g[len] := #0;

      cl := @client_addr;
      l := 128;
      getpeername(sock, cl^, l);

      GGameThread.Create(sock, client_addr, true, g);
      end;
  until (not suc);

  CloseHandle(pipe);
end;
{$ELSE}
begin
  write_console('Copyover not supported on this platform.');
end;
{$ENDIF}

begin
  old_exitproc := ExitProc;

{$IFDEF __DEBUG}
  MemChk;
{$ENDIF}

  bootServer();

  if (CmdLine = 'copyover') then
    from_copyover;

{$IFDEF WIN32}
  SetConsoleCtrlHandler(@ctrl_handler, true);
{$ENDIF}

  write_console('Grendel ' + version_number + {$IFDEF __DEBUG} ' (__DEBUG compile)' + {$ENDIF} ' ready...');

{$IFDEF WIN32}
  SetConsoleTitle(version_info + ', ' + version_number + '. ' + version_copyright + '.');
{$ENDIF}

  try
    game_loop();
  except
    on EControlC do begin
                    grace_exit := true;
                    halt;
                    end;
  end;
end.
