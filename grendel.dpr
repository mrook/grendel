{
  The Grendel Project - Win32 MUD Server
  Copyright (c) 2000,2001 by Michiel Rook (Grimlord)

  Contact information:
  Webpage:            http://www.grendelproject.nl/
  E-Mail:             michiel@grendelproject.nl

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

  $Id: grendel.dpr,v 1.52 2001/08/11 22:05:19 ***REMOVED*** Exp $
}

program grendel;

{$DESCRIPTION 'The Grendel Project - Win32 MUD Server. Copyright (c) 2000,2001 by Michiel Rook.'}

{$IFDEF LINUX}
{$APPTYPE CONSOLE}
{$ENDIF}

{$DEFINE Grendel}

{$R grendel_icon.res}

{$W+}

uses
  SysUtils,
{$IFDEF WIN32}
  Windows,
  Winsock2,
  Forms,
  systray,
{$ENDIF}
{$IFDEF LINUX}
  Libc,
{$ENDIF}
  clan,
  mudsystem,
  constants,
  timers,
  update,
  fight,
  fsys,
  modules,
  mudthread,
  NameGen,
  mudhelp,
  conns,
  dtypes,
  socket,
  console,
  debug,
  skills,
  clean,
  chars,
  Channels,
  Bulletinboard,
  progs,
  area,
  race;

const pipeName : pchar = '\\.\pipe\grendel';


var
  listenv4 : GSocket = nil;
  listenv6 : GSocket = nil;

  old_exitproc : pointer;


procedure startup_tcpip;
begin
  if (isSupported(AF_INET)) then
    begin
    listenv4 := GSocket4.Create(); 
    listenv4.openPort(system_info.port);
    end;

  if (isSupported(AF_INET6)) then
    begin
    listenv6 := GSocket6.Create();
    listenv6.openPort(system_info.port6);
    end;
end;

procedure flushConnections;
var
   conn : GConnection;
   iterator : GIterator;
begin
  iterator := connection_list.iterator();

  while (iterator.hasNext()) do
    begin
    conn := GConnection(iterator.next());
    
    if (conn.state = CON_PLAYING) and (not conn.ch.IS_NPC) then
      GPlayer(conn.ch).quit
    else
      conn.sock.disconnect();
    end;
end;

procedure cleanupServer();
var
   node : GListNode;
begin
  try
    mud_booted := false;

    timer_thread.Terminate;
    clean_thread.Terminate;
    
    Sleep(250);

    saveMudState();
  
    unloadModules();

    writeConsole('Releasing allocated memory...');

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

    listenv4.Free();
    listenv4 := nil;
    listenv6.Free();
    listenv6 := nil;

{$IFDEF WIN32}      
    unregisterSysTray();
{$ENDIF}

    writeConsole('Cleanup complete.');
  except
    on E : EExternal do
      begin
      bugreport('cleanup', 'grendel.dpr', 'Cleanup procedure failed, terminating now.');
      outputError(E);
      end;
  
    on E : Exception do
      bugreport('cleanup', 'grendel.dpr', 'Exception in cleanup procedure: ' + E.Message);
  end;

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
  writeConsole('Server rebooting...');
  try

    if MUD_Booted then
      flushConnections;

    { wait for users to logout }
    Sleep(1000);
  except
    writeConsole('Exception caught while cleaning up memory');
  end;

  cleanupServer();

{$IFDEF WIN32}
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.wShowWindow := sw_show;

  if not CreateProcess('grendel.exe',Nil, Nil, Nil, False, NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, Nil, Nil, SI, PI) then
    bugreport('reboot_mud', 'grendel.dpr', 'Could not execute grendel.exe, reboot failed!');
{$ENDIF}
{$IFDEF LINUX}
  if (execv('grendel', nil) = -1) then
    bugreport('reboot_mud', 'grendel.dpr', 'Could not execute grendel, reboot failed!');
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
  writeConsole('Server starting copyover...');

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

    if (WSADuplicateSocket(conn.sock.getDescriptor, PI.dwProcessId, @prot) = -1) then
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
  writeConsole('Copyover not supported on this platform.');
end;
{$ENDIF}

procedure shutdown_mud;
begin
  try
    writeConsole('Server shutting down...');

    if MUD_Booted then
      flushConnections;

    Sleep(1000);
  except
    on E : EExternal do
    begin
      bugreport('shutdown_mud', 'grendel.dpr', 'Error while shutting down');
      outputError(E);
    end;
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

    writeConsole('---- CRASH TERMINATE. REBOOTING SERVER ----');

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
    writeConsole('NOTE: Could not open logfile. Messages are not being logged.');

  writeDirect(version_info + ', ' + version_number + '.');
  writeDirect(version_copyright + '.');
  writeDirect('This is free software, with ABSOLUTELY NO WARRANTY; view LICENSE.TXT.'#13#10);
  writeConsole('Booting server...');

  try
    load_system;

    s := FormatDateTime('ddddd', Now);
    writeConsole('Booting "' + system_info.mud_name + '" database, ' + s + '.');

    writeConsole('Initializing GMC contexts...');
    init_progs;
    writeConsole('Loading skills...');
    load_skills;
    writeConsole('Loading races...');
    load_races;
    writeConsole('Loading clans...');
    load_clans;
    writeConsole('Loading channels...');
    load_channels();
    writeConsole('Loading areas...');
    load_areas;
    writeConsole('Loading help...');
    load_help('help.dat');
    writeConsole('Loading namegenerator data...');
    loadNameTables(NameTablesDataFile);
    writeConsole('Loading noteboards...');
    load_notes('boards.dat');
    writeConsole('Loading modules...');
    loadModules();
    writeConsole('Loading texts...');
    load_commands;
    load_socials;
    load_damage;
    writeConsole('Loading mud state...');
    loadMudState();

{    writeConsole('String hash stats: ');
    str_hash.hashStats; }

    randomize;

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
      writeConsole('Fatal error while booting: ' + E.Message);
      halt;
      end;
  end;
end;

procedure accept_connection(list_sock : GSocket);
var
  ac : GSocket;
begin
  ac := list_sock.acceptConnection();
  
  ac.setNonBlocking();

  if (boot_info.timer >= 0) then
    begin
    ac.send(system_info.mud_name+#13#10#13#10);
    ac.send('Currently, this server is in the process of a reboot.'#13#10);
    ac.send('Please try again later.'#13#10);
    ac.send('For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

    ac.Free();
    end
  else
  if system_info.deny_newconns then
    begin
    ac.send(system_info.mud_name+#13#10#13#10);
    ac.send('Currently, this server is refusing new connections.'#13#10);
    ac.send('Please try again later.'#13#10);
    ac.send('For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

    ac.Free();
    end
  else
  if (connection_list.getSize >= system_info.max_conns) then
    begin
    ac.send(system_info.mud_name+#13#10#13#10);
    ac.send('Currently, this server is too busy to accept new connections.'#13#10);
    ac.send('Please try again later.'#13#10);
    ac.send('For more information, mail the administration, '+system_info.admin_email+'.'#13#10);

    ac.Free();
    end
  else
    GGameThread.Create(ac, false, '');
end;

procedure game_loop;
begin
{$IFDEF WIN32}
  while (not Application.Terminated) do
{$ELSE}
  while (true) do
{$ENDIF}
    begin
    if (listenv4 <> nil) then
      begin
      if (listenv4.canRead()) then
        accept_connection(listenv4);
      end;

    if (listenv6 <> nil) then
      begin
      if (listenv6.canRead()) then
        accept_connection(listenv6);
      end;

    {$IFDEF WIN32}
    Application.ProcessMessages();
    {$ENDIF}
    
    sleep(500);
    end;
end;

procedure from_copyover;
{$IFDEF WIN32}
var
   pipe : THandle;
   w, len : cardinal;
   prot : TWSAProtocol_Info;
   g : array[0..1023] of char;
   suc : boolean;
   sock : TSocket;
   sk : GSocket;
   client_addr : TSockAddr_Storage;
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
      
      sk := createSocket(prot.iAddressFamily, sock);
      sk.setNonBlocking();     
      sk.socketAddress := client_addr;
      sk.resolve();

      GGameThread.Create(sk, true, g);
      end;
  until (not suc);

  CloseHandle(pipe);
end;
{$ELSE}
begin
  writeConsole('Copyover not supported on this platform.');
end;
{$ENDIF}

begin
  old_exitproc := ExitProc;

{$IFDEF __DEBUG}
  MemChk;
{$ENDIF}

  bootServer();
   
{$IFDEF WIN32}
  if (GetCommandLine() = 'copyover') or (paramstr(1) = 'copyover') then
    from_copyover;
{$ENDIF}

  writeConsole('Grendel ' + version_number + {$IFDEF __DEBUG} ' (__DEBUG compile)' + {$ENDIF} ' ready...');

{$IFDEF WIN32}
  registerSysTray();
{$ENDIF}

  try
    game_loop();
  except
    on E: EControlC do begin
                    grace_exit := true;
                    halt;
                    end;
    on E: Exception do 
                    writeConsole('Exception in main game loop: ' + E.Message)
    else
      writeConsole('Unknown exception in main game loop');
  end;
end.
