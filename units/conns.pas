{
  @abstract(Connection manager)
  @lastmod($Id: conns.pas,v 1.36 2002/08/03 19:13:55 ***REMOVED*** Exp $)
}

unit conns;

interface

uses
{$IFDEF WIN32}
    Winsock2,
    Windows,
    Forms,
{$ENDIF}
{$IFDEF LINUX}
    Libc,
{$ENDIF}
    Classes,
    SysUtils,
    constants,
    chars,
    dtypes,
    util,
    area,
    socket,
    console,
    mudsystem;


type
    GConnection = class
      node : GListNode;
      sock : GSocket;
      thread : TThread;
      idle : integer;

      ch : GPlayer;                 // only players can be connected
      keylock, afk : boolean;
      state : integer;

      input_buf, comm_buf, last_line : string;
      sendbuffer : string;

      empty_busy : boolean;

      pagebuf : string;
      pagepoint : cardinal;
      pagecmd : char;

      fcommand : boolean;

      procedure send(s : string);
      procedure read;
      procedure readBuffer;

      procedure writePager(txt : string);
      procedure setPagerInput(argument : string);
      procedure outputPager;

      constructor Create(sk : GSocket; thr : TThread);
      destructor Destroy; override;
    end;

var
  connection_list : GDLinkedList;
  listenv4 : GSocket = nil;
  listenv6 : GSocket = nil;


function act_string(acts : string; to_ch, ch : GCharacter; arg1, arg2 : pointer) : string;
function act_color(to_ch : GCharacter; acts, sep : string) : string;

procedure act(atype : integer; acts : string; hideinvis : boolean; ch : GCharacter;
              arg1, arg2 : pointer; typ : integer);

function playername(from_ch, to_ch : GCharacter) : string;

procedure gameLoop();

procedure initConns();
procedure cleanupConns();

implementation

uses
  mudthread;


// GConnection
constructor GConnection.Create(sk : GSocket; thr : TThread);
begin
  inherited Create;

  sock := sk;
  state := CON_ACCEPTED;
  ch := nil;
  idle := 0;
  thread := thr;
  keylock := false;
  afk := false;

  node := connection_list.insertLast(Self);
end;

destructor GConnection.Destroy;
begin
  connection_list.remove(node);
  
  sock.Free();

  inherited Destroy;
end;

procedure GConnection.send(s : string);
begin
  try
    sock.send(s);
  except
    thread.terminate();
  end;
end;

procedure GConnection.read;
var s, read : integer;
    buf : array[0..MAX_RECEIVE-1] of char;
begin
  if (length(comm_buf) > 0) then
    exit;

  try
    if (not sock.canRead()) then
      exit;
  except
    try
      thread.terminate;
    except
      writeConsole('could not terminate thread');
    end;
  end;
  
  idle := 0;

  repeat
    read := recv(sock.getDescriptor, buf, MAX_RECEIVE - 10, 0);

    if (read > 0) then
      begin
      buf[read] := #0;
      input_buf := input_buf + buf;
      end
    else
    if (read = 0) then
      begin
      try
        thread.terminate;
      except
        writeConsole('could not terminate thread');
      end;

      exit;
      end
    else
    if (read = SOCKET_ERROR) then
      begin
{$IFDEF WIN32}
      s := WSAGetLastError;

      if (s = WSAEWOULDBLOCK) then
        break
      else
        begin
        try
          thread.terminate;
        except
          writeConsole('could not terminate thread');
        end;

        exit;
        end;
{$ELSE}
      break;
{$ENDIF}      
      end;
  until false;
end;

procedure GConnection.readBuffer;
var i : integer;
begin
  if (length(comm_buf) <> 0) or ((pos(#10, input_buf) = 0) and (pos(#13, input_buf) = 0))  then
    exit;

  i := 1;

  while (i <= length(input_buf)) and (input_buf[i] <> #13) and (input_buf[i] <> #10) do
    begin
    if ((input_buf[i] = #8) or (input_buf[i] = #127)) then
      delete(comm_buf, length(comm_buf), 1)
    else
    if (byte(input_buf[i]) > 31) and (byte(input_buf[i]) < 127) then
      begin
      comm_buf := comm_buf + input_buf[i];
      end;

    inc(i);
    end;

  while (i <= length(input_buf)) and ((input_buf[i] = #13) or (input_buf[i] = #10)) do
    begin
    comm_buf := comm_buf + input_buf[i];

    inc(i);
    end;

  if (comm_buf = '!'#13#10) then
    comm_buf := last_line
  else
    last_line := comm_buf;

  delete(input_buf, 1, i - 1);
end;

procedure GConnection.writePager(txt : string);
begin
  if (pagepoint = 0) then
    begin
    pagepoint := 1;
    pagecmd:=#0;
    end;

  pagebuf := pagebuf + txt;
end;

procedure GConnection.setPagerInput(argument : string);
begin
  argument := trim(argument);

  if (length(argument) > 0) then
    pagecmd := argument[1];
end;

procedure GConnection.outputPager;
var last : cardinal;
    c : GPlayer;
    pclines,lines:integer;
    buf:string;
begin
  if (pagepoint = 0) then
    exit;

{  if (original <> nil) then
    c := original
  else
    c := ch; }
  c := ch;

  pclines := UMax(c.pagerlen, 5) - 2;

  c.emptyBuffer;

  if (pagecmd <> #0) then
    send(#13#10);
    
  case pagecmd of
    'b':lines:=-1-(pclines*2);
    'r':lines:=-1-pclines;
    'q':begin
        c.sendPrompt;
        pagepoint := 0;
        pagebuf := '';
        exit;
        end;
  else
    lines:=0;
  end;

  while (lines<0) and (pagepoint >= 1) do
    begin
    if (pagebuf[pagepoint] = #13) then
      inc(lines);

    dec(pagepoint);
    end;

  if (pagepoint < 1) then
    pagepoint := 1;

  lines:=0;
  last:=pagepoint;

  while (lines < pclines) and (last <= length(pagebuf)) do
    begin
    if (pagebuf[last] = #0) then
      break
    else
    if (pagebuf[last] = #13) then
      inc(lines);

    inc(last);
    end;

  if (last <= length(pagebuf)) and (pagebuf[last] = #10) then
    inc(last);

  if (last <> pagepoint) then
    begin
    buf := copy(pagebuf, pagepoint, last - pagepoint);
    send(buf);
    pagepoint := last;
    end;

  while (last <= length(pagebuf)) and (pagebuf[last] = ' ') do
    inc(last);

  if (last >= length(pagebuf)) then
    begin
    pagepoint := 0;
    c.sendPrompt;
    pagebuf := '';
    exit;
    end;

  pagecmd:=#0;

  send(#13#10'(C)ontinue, (R)efresh, (B)ack, (Q)uit: ');
end;

function playername(from_ch, to_ch : GCharacter) : string;
begin
  if (not to_ch.CAN_SEE(from_ch)) then
    playername := 'someone'
  else
  if (not to_ch.IS_NPC) and (not from_ch.IS_NPC) then
    begin
    if (from_ch.IS_IMMORT) then
      playername := from_ch.name^
    else
    if (not to_ch.IS_SAME_ALIGN(from_ch)) then
      begin
      if (from_ch.race.name[1] in ['A','E','O','I','U']) then
        playername := '+* An ' + from_ch.race.name + ' *+'
      else
        playername := '+* A ' + from_ch.race.name + ' *+';
      end
    else
      playername := from_ch.name^;
    end
  else
    playername := from_ch.name^;

  if (from_ch = to_ch) then
    playername := 'you';
end;

function act_color(to_ch : GCharacter; acts, sep : string) : string;
var
   t : integer;
   boldflag:boolean;
   s, i : string;
begin
  t := 1;
  s := '';
  boldflag := false;

  while (t <= length(acts)) do
    begin
    if (acts[t] = sep) then
      begin
      inc(t);
      i := '';

      case acts[t] of
        'B': boldflag := true;
        'A': boldflag := false;
   '0'..'9': begin
             if (boldflag) then
               i := to_ch.ansiColor(strtoint(acts[t]) + 8)
             else
               i := to_ch.ansiColor(strtoint(acts[t]));
             end;
      end;

      s := s + i;
      end
    else
      s := s + acts[t];

    inc(t);
    end;

  Result := s;
end;

function act_string(acts : string; to_ch, ch : GCharacter; arg1, arg2 : pointer) : string;
var s, i : string;
    t : integer;
    vch : GCharacter;
    obj1, obj2 : TObject;
    ex : GExit;
begin
  vch := arg2;
  obj1 := arg1; obj2 := arg2;
  s := '';
  t := 1;

  while (t <= length(acts)) do
    begin
    if (acts[t] = '$') then
      begin
      inc(t);
      i:='';
      case acts[t] of
        'n': i := playername(ch, to_ch);
        'N': begin
             if (vch = nil) then
               writeConsole('[BUG]: act() -> vch null')
             else
               i := playername(vch, to_ch);
             end;
        'm': i := sex_nm[ch.sex];
        'M': begin
             if (vch = nil) then
               writeConsole('[BUG]: act() -> vch null')
             else
               i := sex_nm[vch.sex];
             end;
        's': i := sex_bm[ch.sex];
        'S': begin
             if (vch = nil) then
               writeConsole('[BUG]: act() -> vch null')
             else
               i := sex_bm[vch.sex];
             end;
        'e': i := sex_pm[ch.sex];
        'E': begin
             if (vch = nil) then
               writeConsole('[BUG]: act() -> vch null')
             else
               i := sex_pm[vch.sex];
             end;
       'o': begin
             if (obj1 = nil) then
               writeConsole('[BUG]: act() -> obj1 null')
             else
               begin
               if (obj1 is GObjectIndex) then
                 i := GObjectIndex(obj1).name^
               else
                 i := GObject(obj1).name^;
               end;
             end;
        'O': begin
             if (obj2 = nil) then
               writeConsole('[BUG]: act() -> obj2 null')
             else
               begin
               if (obj1 is GObjectIndex) then
                 i := GObjectIndex(obj2).name^
               else
                 i := GObject(obj2).name^;
               end;
             end;
        'p': begin
             if (obj1 = nil) then
               writeConsole('[BUG]: act() -> obj1 null')
             else
               begin
               if (obj1 is GObjectIndex) then
                 i := GObjectIndex(obj1).short^
               else
                 i := GObject(obj1).short^;
               end;
             end;
        'P': begin
             if (obj2 = nil) then
               writeConsole('[BUG]: act() -> obj2 null')
             else
               begin
               if (obj2 is GObjectIndex) then
                 i := GObjectIndex(obj2).short^
               else
                 i := GObject(obj2).short^;
               end;
             end;
        't': begin
             if (arg1 = nil) then
               writeConsole('[BUG]: act() -> pchar(arg1) null')
             else
               i := (PString(arg1))^;
             end;
        'T': begin
             if (arg2 = nil) then
               writeConsole('[BUG]: act() -> pchar(arg2) null')
             else
               i := (PString(arg2))^;
             end;
        'd': begin
               if (arg2 = nil) then
                 writeConsole('[BUG]: act() -> arg2 is nil')
               else
               begin
                 ex := GExit(arg2);

                 if ((ex.keywords <> nil) and (length(ex.keywords^) = 0)) then
                   i := 'door'
                 else
                   one_argument(ex.keywords^, i);
               end;
             end;
   '0'..'9','A','B':begin
                    i:='$'+acts[t];
                    end;
      else
        writeConsole('[BUG]: act() -> bad format code');
      end;
      s := s + i;
      end
    else
      s := s + acts[t];

    inc(t);
    end;

  acts := cap(s);

  act_string := act_color(to_ch, acts, '$');
end;

procedure act(atype : integer; acts : string; hideinvis : boolean; ch : GCharacter;
              arg1, arg2 : pointer; typ : integer);
{ Documentation of act routine:

  atype         - Ansi color to start with
  acts          - A string to send
  hideinvis     - Hide action when ch is invisible?
  ch            - Number of character
  arg1, arg2    - Respectively object or character
  type          - Who gets the resulting string:
                      TO_ROOM     = everybody in the room, except ch
                      TO_VICT     = character in vict
                      TO_NOTVICT  = everybody in the room, except ch and vict
                      TO_CHAR     = to ch
                      TO_ALL      = to everyone, except ch
  prompt        - Do we need to send a prompt after the string?
}

function HIDE_VIS(ch, vict : GCharacter) : boolean;
begin
  if (ch = nil) then
    HIDE_VIS := false
  else
    HIDE_VIS := (not ch.CAN_SEE(vict)) and (hideinvis);
end;

var txt : string;
    vch : GCharacter;
    to_ch : GCharacter;
    t : integer;

    node : GListNode;

label wind;
begin
  if (length(acts) = 0) then
    exit;

  vch := GCharacter(arg2);

  if (ch = nil) and (typ <> TO_ALL) then
    begin
    writeConsole('[BUG]: act() -> ch null');
    exit;
    end;

  if (typ = TO_CHAR) then
    node := ch.node_world
  else
  if (typ = TO_VICT) then
    begin
    if (vch = nil) then
      begin
      writeConsole('[BUG]: act() -> vch null');
      exit;
      end;

    node := vch.node_world;
    end
  else
  if (typ = TO_ALL) then
    node := char_list.head
  else
  if (typ = TO_ROOM) or (typ = TO_NOTVICT) then
    node := ch.room.chars.head
  else
    node := nil;

  while (node <> nil) do
    begin
    to_ch := GCharacter(node.element);

    if ((not to_ch.IS_AWAKE) and (to_ch <> ch)) then goto wind;

    if (typ = TO_CHAR) and (to_ch <> ch) then
      goto wind;
    if (typ = TO_VICT) and ((to_ch <> vch) or (to_ch = ch) or (HIDE_VIS(to_ch, ch))) then
      goto wind;
    if (typ = TO_ROOM) and ((to_ch = ch) or (HIDE_VIS(to_ch, ch))) then
      goto wind;
    if (typ = TO_ALL) and (to_ch = ch) then
      goto wind;
    if (typ = TO_NOTVICT) and ((to_ch = ch) or (to_ch = vch)) then
      goto wind;
    if (typ = TO_IMM) and ((to_ch = ch) or (not to_ch.IS_IMMORT)) then
     goto wind;

    txt := act_string(acts, to_ch, ch, arg1, arg2);

    to_ch.sendBuffer(to_ch.ansiColor(atype) + txt + #13#10);

    if (to_ch.IS_NPC) and (to_ch <> ch) then
      begin
      t := GNPC(to_ch).context.findSymbol('onAct');

      if (t <> -1) then
        begin
        GNPC(to_ch).context.push(txt);
        GNPC(to_ch).context.push(integer(ch));
        GNPC(to_ch).context.push(integer(to_ch));
        GNPC(to_ch).context.setEntryPoint(t);
        GNPC(to_ch).context.Execute;
        end;
      end;

wind:
     if (typ = TO_CHAR) or (typ = TO_VICT) or (typ = TO_IMM) then
       node := nil
     else
     if (typ = TO_ROOM) or (typ = TO_NOTVICT) or (typ = TO_ALL) then
       node := node.next;
     end;
end;

procedure acceptConnection(list_sock : GSocket);
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

procedure gameLoop();
begin
{$IFDEF WIN32}
  {$IFNDEF CONSOLEBUILD}
  while (not Application.Terminated) do
  {$ELSE}
  while (true) do
  {$ENDIF}
{$ELSE}
  while (true) do
{$ENDIF}
    begin
    if (listenv4 <> nil) then
      begin
      if (listenv4.canRead()) then
        acceptConnection(listenv4);
      end;

    if (listenv6 <> nil) then
      begin
      if (listenv6.canRead()) then
        acceptConnection(listenv6);
      end;

    {$IFDEF WIN32}
      Application.ProcessMessages();
    {$ENDIF}
    
    sleep(5);
    end;
end;

procedure initConns();
begin
  connection_list := GDLinkedList.Create;
end;

procedure cleanupConns();
begin
  connection_list.clean();
  connection_list.Free();
end;

end.
