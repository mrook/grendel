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
}

program grendel;

{$DESCRIPTION 'The Grendel Project - Win32 MUD Server. Copyright (c) 2000,2001 by Michiel Rook.'}
{$APPTYPE CONSOLE}

// set suitable options when using debugging and mem checking
{$IFDEF __DEBUG}
{$W+}
{$O-}
{$ENDIF}

uses
  SysUtils,
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
  progs in 'units\progs.pas',
  md5 in 'units\md5.pas' {$IFDEF __DEBUG},
  MemCheck in 'units\MemCheck.pas' {$ENDIF},
  timers in 'units\timers.pas';

const pipeName : pchar = '\\.\pipe\grendel';
const use_ipv4 : boolean = false;
      use_ipv6 : boolean = false;


var
   hWSAData : TWSAData;

   listenv4, listenv6 : TSocket;

   addrv4 : TSockAddrIn;
   addrv6 : TSockAddr6;
   ssv6 : TSockAddr_Storage;
   addrv6p : PSockAddr;

   client_addr : TSockAddr_Storage;

   old_exitproc : pointer;


procedure detect_protocols;
var
   a, t : dword;
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

procedure startup_winsock;
var rc : integer;
    ver : integer;
begin
  ver := WINSOCK_VERSION;

  if (WSAStartup(ver, hWSAData) <> 0) then
    write_console('ERROR: WSAStartup failed.');

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
      closesocket(listenv4);
      write_console('ERROR: Could not bind to IPv4, port ' + inttostr(system_info.port));
      halt;
      end;

    rc := listen(listenv4, 15);

    if (rc > 0) then
      write_console('ERROR: Could not listen on IPv4 socket.')
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
    addrv6.sin6_port := htons(system_info.port);

    move(addrv6, ssv6, sizeof(addrv6));

    addrv6p := @ssv6;

    if (bind(listenv6, addrv6p^, 128) = -1) then
      begin
      rc := WSAGetLastError;

      writeln(rc);

      closesocket(listenv6);
      write_console('ERROR: Could not bind to IPv6, port ' + inttostr(system_info.port));
      end;

    rc := listen(listenv6, 15);

    if (rc > 0) then
      write_console('ERROR: Could not listen on IPv6 socket.')
    else
      write_console('IPv6 bound on port ' + inttostr(system_info.port) + '.');
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
      ch.quit;
    end;
end;

procedure cleanup_mud;
var
   n : integer;
   node : GListNode;
begin
  mud_booted := false;

  timer_thread.Terminate;
  clean_thread.Terminate;

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
    room_list.clean;
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

    for n := 0 to MAX_SKILLS - 1 do
     if (skill_table[n] <> nil) then
      begin
      skill_table[n].prereqs.smallClean;
      skill_table[n].prereqs.Free;
      skill_table[n].affect.Free;
      skill_table[n].Free;
      end;

    socials.Free;
    str_hash.Free;
    auction_good.Free;
    auction_evil.Free;
    banned_masks.Free;

    connection_list.clean;
    connection_list.Free;
    commands.Free;
  except
    bugreport('cleanup', 'grendel.dpr', 'something went wrong',
              'A procedure in the cleanup cycle failed. Contact Grimlord.');
  end;

  if (use_ipv4) then
    begin
    closesocket(listenv4);
    listenv4 := -1;
    end;

  if (use_ipv6) then
    begin
    closesocket(listenv6);
    listenv6 := -1;
    end;

  WSACleanup;
  write_console('Cleanup complete.');
  if (TTextRec(logfile).mode = fmOutput) then
    CloseFile(LogFile);
end;

procedure reboot_mud;
var SI: TStartupInfo;
    PI: TProcessInformation;
    s : TDateTime;
    msg:TMsg;
begin
  write_console('Server rebooting...');
  try

    if MUD_Booted then
      flushConnections;

    { wait for users to logout }
    s := Time+StrToTime('0:0:01');
    repeat
      PeekMessage(msg,0,0,0,PM_NOREMOVE);
    until Time>=s;
  except
    write_console('... wrong');
  end;

  cleanup_mud;

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.wShowWindow := sw_show;

  if not CreateProcess('grendel.exe',Nil, Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI) then
    bugreport('reboot_mud', 'grendel.dpr', 'could not execute grendel.exe',
              'The server could not be rebooted! Please check your settings!');
end;

procedure copyover_mud;
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
    bugreport('copyover_mud', 'grendel.dpr', 'Could not execute copyover.exe',
              'The copyover could not be started! Please check your settings!');
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
    bugreport('copyover_mud', 'grendel.dpr', 'Pipe did not initialize correctly!', 'The IPC pipe for copyover could not be created.');
    reboot_mud;
    end;

  node := connection_list.head;

  while (node <> nil) do
    begin
    conn := node.element;
    node_next := node.next;

    if (WSADuplicateSocket(conn.socket, PI.dwProcessId, @prot) = -1) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'WSADuplicateSocket failed', 'Error code: ' + IntToStr(WSAGetLastError));
      reboot_mud;
      end;

    if (not WriteFile(pipe, prot, sizeof(prot), w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe', 'Could not send socket info through IPC pipe');
      reboot_mud;
      end;

		strpcopy(name, conn.ch.name^);
    len := strlen(name);

    if (not WriteFile(pipe, len, 4, w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe', 'Could not send socket info through IPC pipe');
      reboot_mud;
      end;

    if (not WriteFile(pipe, name, len, w, nil)) then
      begin
      bugreport('copyover_mud', 'grendel.dpr', 'Broken pipe', 'Could not send socket info through IPC pipe');
      reboot_mud;
      end;

    conn.ch.save(conn.ch.name^);
    conn.thread.terminate;

    node := node_next;
    end;

  Sleep(500);

  CloseHandle(pipe);

  cleanup_mud;
end;

procedure shutdown_mud;
var
    s : TDateTime;
    msg:TMsg;
begin
  write_console('Server shutting down...');
  try

    if MUD_Booted then
      flushConnections;

    { wait for users to logout }
    s := Time+StrToTime('0:0:01');
    repeat
      PeekMessage(msg,0,0,0,PM_NOREMOVE);
    until Time>=s;
  except
    write_console('... wrong');
  end;

  cleanup_mud;
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
var msg:TMsg;
    s:single;
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

    { wait for users to logout }
    s:=Time+StrToTime('0:0:01');

    repeat
      PeekMessage(msg,0,0,0,PM_NOREMOVE);
    until Time>=s;

    { give operator/logfile a message }
    bugreport('CRASH', 'grendel.dpr', 'CRASH WARNING',
              'The system encountered a fatal error and will reboot.');

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


procedure boot_mud;
var s : string;
    t : TInAddr;
begin
  { open a standard log file, filename is given by current system time }
  TimeSeparator := '_';
  AssignFile(LogFile, 'log\' + TimeToStr(time) + '_' + DateToStr(date) + '.log');
  TimeSeparator := ':';

  {$I-}
  rewrite(LogFile);
  {$I+}

  if (IOResult <> 0) then
    write_console('NOTE: Could not open logfile. Messages are not being logged.');

  SetConsoleTitle(version_info + ', ' + version_number + '(Booting)');

  write_direct(version_info + ', ' + version_number + '.');
  write_direct(version_copyright + '.');
  write_direct('This is free software, with ABSOLUTELY NO WARRANTY; view LICENSE.TXT.'#13#10);
  write_console('Booting server...');

  load_system;

  s := FormatDateTime('ddddd', Now);
  write_console('Booting "' + system_info.mud_name + '" database, ' + s + '.');

  clean_thread := GCleanThread.Create;

  write_console('Loading races...');
  load_races;
  // write_console('Loading professions...');
  // load_profs;
  write_console('Loading clans...');
  load_clans;
  write_console('Loading skills...');
  load_skills;
  write_console('Loading texts...');
  load_commands;
  load_socials;
  load_damage;
  write_console('Loading areas...');
  load_areas;
  write_console('Loading help...');
  load_help('help.dat');

  write_console('String hash stats: ');
  str_hash.hashStats;

  randomize;

  startup_winsock;

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

  calculateonline;
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
  ac := accept(list_sock, cl^, len);

  // set non-blocking mode

  len := 1;
  len := ioctlsocket(ac, FIONBIO, len);

  if (boot_info.timer >= 0) then
    begin
    send_to_socket(ac, system_info.mud_name+#13#10#13#10);
    send_to_socket(ac, 'Currently, this server is in the process of a reboot.'#13#10);
    send_to_socket(ac, 'Please try again later.'#13#10);
    send_to_socket(ac, 'For more information, mail the administration, '+system_info.admin_email+'.'#13#10);
    closesocket(ac);
    end
  else
  if system_info.deny_newconns then
    begin
    send_to_socket(ac, system_info.mud_name+#13#10#13#10);
    send_to_socket(ac, 'Currently, this server is refusing new connections.'#13#10);
    send_to_socket(ac, 'Please try again later.'#13#10);
    send_to_socket(ac, 'For more information, mail the administration, '+system_info.admin_email+'.'#13#10);
    closesocket(ac);
    end
  else
  if (connection_list.getSize >= MAX_CONNS) then
    begin
    send_to_socket(ac, system_info.mud_name+#13#10#13#10);
    send_to_socket(ac, 'Currently, this server is too busy to accept new connections.'#13#10);
    send_to_socket(ac, 'Please try again later.'#13#10);
    send_to_socket(ac, 'For more information, mail the administration, '+system_info.admin_email+'.'#13#10);
    closesocket(ac);
    end
  else
    GGameThread.Create(ac, client_addr, false, '');
end;

procedure game_loop;
var msg : TMsg;
    accept_set : PFDSet;
    accept_val : PTimeVal;
begin
  new(accept_set);
  new(accept_val);

  while (true) do
    begin
    if (PeekMessage(msg,0,0,0,PM_REMOVE)) then
      begin
      TranslateMessage(msg);
      DispatchMessage(msg);
      end;

    if (use_ipv4) and (listenv4 > 0) then
      begin
      accept_set^.fd_array[0] := listenv4;
      accept_set^.fd_count:=1;
      accept_val^.tv_sec:=0;
      accept_val^.tv_usec:=0;

      if (select(1,accept_set,nil,nil,accept_val) <> 0) then
        accept_connection(listenv4);
      end;

    if (use_ipv6) and (listenv6 > 0) then
      begin
      accept_set^.fd_array[0] := listenv6;
      accept_set^.fd_count:=1;
      accept_val^.tv_sec:=0;
      accept_val^.tv_usec:=0;

      if (select(1,accept_set,nil,nil,accept_val) <> 0) then
        accept_connection(listenv6);
      end;

    sleep(500);
    end;

  dispose(accept_set);
  dispose(accept_val);
end;

function ctrl_handler(event:dword):boolean;
begin
  ctrl_handler:=true;
  grace_exit:=true;
  SetConsoleCtrlHandler(@ctrl_handler, false);
  halt;
end;

procedure from_copyover;
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
      bugreport('from_copyover', 'grendel.dpr', 'Could not restart from copyover',
              'The copyover could not be completed succesfully.');
			exit;
      end;

    // All pipe instances are busy, so wait a second

    if (not WaitNamedPipe(pipeName, 1000)) then
      begin
      bugreport('from_copyover', 'grendel.dpr', 'Could not restart from copyover',
              'The copyover could not be completed succesfully.');
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

begin
  old_exitproc := ExitProc;

{$IFDEF __DEBUG}
  MemChk;
{$ENDIF}

  boot_mud;

  if (CmdLine = 'copyover') then
    from_copyover;

  SetConsoleCtrlHandler(@ctrl_handler, true);
  write_console('Grendel ' + version_number + ' ready...');
  SetConsoleTitle(version_info + ', ' + version_number + '. ' + version_copyright + '.');

  game_loop;
end.
