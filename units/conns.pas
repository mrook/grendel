unit conns;

interface

uses
    Winsock2,
    Windows,
    Classes,
    SysUtils,
    constants,
    chars,
    dtypes,
    util,
    area,
    mudsystem;


type
    GConnection = class
      node : GListNode;
      socket : TSocket;
      thread : TThread;
      idle : integer;

      ch, original : GCharacter;
      keylock, afk : boolean;
      state : integer;

      ip_string : string;
      host_string : string;

      input_buf, comm_buf, last_line : string;
      sendbuffer : string;

      empty_busy : boolean;

      pagebuf : string;
      pagepoint : cardinal;
      pagecmd : char;

      fcommand : boolean;

      read_set, ex_set : TFDSet;
      tel_val : PTimeVal;

      procedure checkReceive;
      procedure read;
      procedure readBuffer;
      function send(s : string) : integer;

      procedure writePager(txt : string);
      procedure setPagerInput(argument : string);
      procedure outputPager;

      constructor Create(sock : TSocket; addr : TSockAddr_Storage; thr : TThread);
      destructor Destroy; override;
    end;

var
   connection_list : GDLinkedList;

function act_string(acts : string; to_ch, ch : GCharacter; arg1, arg2 : pointer) : string;

procedure act(atype : integer; acts : string; hideinvis : boolean; ch : GCharacter;
              arg1, arg2 : pointer; typ : integer);

function playername(from_ch, to_ch : GCharacter) : string;

procedure to_channel(ch : GCharacter; arg : string; channel : integer; color : integer);
procedure talk_channel(ch : GCharacter; arg : string; channel : integer; verb : string; color : integer);

procedure to_group(ch : GCharacter; arg : string);

implementation

uses
    progs;

(* procedure parse_line(p : string);
var a : word;
    s1, s2 : string;
begin
  if (length(p) = 0) then
    exit;

  a := 1;

  repeat
    case p[a] of
     #10: begin
          if (p[a + 1] = #0) then
            p[a] := #0
          else
            delete(p, a, 1);

          dec(a);
          end;
 #127,#8: begin
          { if (a + 1 > (length(p) - 1)) then
            s1 := ' '
          else
            s1 := @p[a + 1]; }

          if (integer(a) - 1 >= 1) then
            delete(p, a - 1, 1);

          dec(a, 2);
          end;
    #255: begin { Telnet control character }
          delete(p, a, 3);

          dec(a);
          end;
    end;

    inc(a);
  until (a > length(p));
end; *)

// GConnection
constructor GConnection.Create(sock : TSocket; addr : TSockAddr_Storage; thr : TThread);
var
   h : PHostEnt;
   l, p : integer;
   v6 : TSockAddr6;
   v4 : TSockAddr;
begin
  inherited Create;

  socket := sock;
  state := CON_ACCEPTED;
  ch := nil;
  idle := 0;
  thread := thr;
  ip_string := '';
  keylock := false;
  afk := false;

  if (addr.ss_family = AF_INET) then
    begin
    move(addr, v4, sizeof(v4));

    ip_string := inet_ntoa(v4.sin_addr);
    end
  else
  if (addr.ss_family = AF_INET6) then
    begin
    move(addr, v6, sizeof(v6));

    l := 0;

    while (l < 16) do
      begin
      p := (byte(v6.sin6_addr.s6_addr[l]) shl 8) + byte(v6.sin6_addr.s6_addr[l + 1]);

      if (p = 0) then
        begin
        ip_string := ip_string + ':';

        while (p = 0) do
          begin
          p := (byte(v6.sin6_addr.s6_addr[l]) shl 8) + byte(v6.sin6_addr.s6_addr[l + 1]);

          inc(l, 2);
          end;
        end
      else
        inc(l, 2);

      if (ip_string <> '') then
        ip_string := ip_string + ':';

      ip_string := ip_string + lowercase(inttohex(p, 4));
      end;
    end;

  if (system_info.lookup_hosts) then
    begin
    { h := gethostbyaddr(@a.sin_addr.s_addr, 4, PF_INET);

    if (h <> nil) then
      host_string := h.h_name
    else
      host_string := inet_ntoa(a.sin_addr); }
    host_string := '';
    end
  else
    host_string := ip_string;

  new(tel_val);

  node := connection_list.insertLast(Self);
end;

destructor GConnection.Destroy;
begin
  dispose(tel_val);
  connection_list.remove(node);

  inherited Destroy;
end;

procedure GConnection.checkReceive;
var
   msg : TMsg;
begin
  FD_ZERO(read_set);
  FD_SET(socket, read_set);
  FD_ZERO(ex_set);
  FD_SET(socket, ex_set);

  tel_val^.tv_sec:=0;
  tel_val^.tv_usec:=0;

  if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then
    begin
    TranslateMessage(msg);
    DispatchMessage(msg);
    end;

  if (select(0,@read_set,nil,@ex_set,tel_val) = SOCKET_ERROR) then
    try
      thread.terminate;
    except
      write_console('could not terminate thread');
    end;

  if (FD_ISSET(socket, read_set)) then
    idle:=0;

  if (FD_ISSET(socket, ex_set)) then
    try
      thread.terminate;
    except
      write_console('could not terminate thread');
    end;
end;

procedure GConnection.read;
var s, read : integer;
    buf : array[0..MAX_RECEIVE-1] of char;
begin
  if (length(comm_buf) > 0) then
    exit;

  if (not FD_ISSET(socket, read_set)) then
    exit;

  repeat
    read := recv(socket, buf, MAX_RECEIVE - 10, 0);

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
        write_console('could not terminate thread');
      end;

      exit;
      end
    else
    if (read = SOCKET_ERROR) then
      begin
      s := WSAGetLastError;

      if (s = WSAEWOULDBLOCK) then
        break
      else
        begin
        try
          thread.terminate;
        except
          write_console('could not terminate thread');
        end;

        exit;
        end;
      end
    else
      begin
      bugreport('GConnection.read', 'conns.pas', 'weird!',
                'This part should NOT be reached. Contact Grimlord.');
      exit;
      end;
  until false;
end;

procedure GConnection.readBuffer;
var i, j : integer;
begin
  if (length(comm_buf) <> 0) or (pos(#10, input_buf) = 0) then
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

  delete(input_buf, 1, i);
end;

function GConnection.send(s : string) : integer;
var
   res : integer;
begin
  res := Winsock2.send(socket, s[1], length(s), 0);

  Result := res;

  if (res = SOCKET_ERROR) then
    begin
    try
      thread.terminate;
    except
      write_console('could not terminate thread');
    end;
    end;
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
    c : GCharacter;
    pclines,lines:integer;
    buf:string;
begin
  if (pagepoint = 0) then
    exit;

  if (original <> nil) then
    c := original
  else
    c := ch;

  pclines:=UMin(ch.player^.pagerlen,5) - 2;

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

function act_string(acts : string; to_ch, ch : GCharacter; arg1, arg2 : pointer) : string;
var s, i : string;
    t : integer;
    vch : GCharacter;
    obj1, obj2 : GObject;
    boldflag:boolean;
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
               write_console('[BUG]: act() -> vch null')
             else
               i := playername(vch, to_ch);
             end;
        'm': i := sex_nm[ch.sex];
        'M': begin
             if (vch = nil) then
               write_console('[BUG]: act() -> vch null')
             else
               i := sex_nm[vch.sex];
             end;
        's': i := sex_bm[ch.sex];
        'S': begin
             if (vch = nil) then
               write_console('[BUG]: act() -> vch null')
             else
               i := sex_bm[vch.sex];
             end;
        'e': i := sex_pm[ch.sex];
        'E': begin
             if (vch = nil) then
               write_console('[BUG]: act() -> vch null')
             else
               i := sex_pm[vch.sex];
             end;
        'o': begin
             if (obj1 = nil) then
               write_console('[BUG]: act() -> obj1 null')
             else
               i := obj1.name^;
             end;
        'O': begin
             if (obj2 = nil) then
               write_console('[BUG]: act() -> obj2 null')
             else
               i := obj2.name^;
             end;
        'p': begin
             if (obj1 = nil) then
               write_console('[BUG]: act() -> obj1 null')
             else
               i := obj1.short^;
             end;
        'P': begin
             if (obj2 = nil) then
               write_console('[BUG]: act() -> obj2 null')
             else
               i := obj2.short^;
             end;
        't': begin
             if (arg1 = nil) then
               write_console('[BUG]: act() -> pchar(arg1) null')
             else
               i := (PString(arg1))^;
             end;
        'T': begin
             if (arg2 = nil) then
               write_console('[BUG]: act() -> pchar(arg2) null')
             else
               i := (PString(arg2))^;
             end;
        'd': begin
             ex := GExit(arg2);

             if (length(ex.keywords^) = 0) then
               i := 'door'
             else
               one_argument(ex.keywords^, i);
             end;
   '0'..'9','A','B':begin
                    i:='$'+acts[t];
                    end;
      else
        write_console('[BUG]: act() -> bad format code');
      end;
      s := s + i;
      end
    else
      s := s + acts[t];

    inc(t);
    end;

  acts := cap(s);

  s := '';
  t := 1;

  boldflag := false;

  while (t <= length(acts)) do
    begin
    if (acts[t] = '$') then
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

  act_string := s;
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

var buf1 : string;
    txt : string;
    vch : GCharacter;
    to_ch : GCharacter;

    node : GListNode;

label wind;
begin
  if (length(acts) = 0) then
    exit;

  vch := GCharacter(arg2);

  if (ch = nil) and (typ <> TO_ALL) then
    begin
    write_console('[BUG]: act() -> ch null');
    exit;
    end;

  if (typ = TO_CHAR) then
    node := ch.node_world
  else
  if (typ = TO_VICT) then
    begin
    if (vch = nil) then
      begin
      write_console('[BUG]: act() -> vch null');
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

    if (to_ch.IS_NPC) and (not IS_SET(to_ch.npc_index.mpflags,MPROG_ACT)) and (ch.conn = nil)// and (ch.snooped_by=nil))
      or ((not to_ch.IS_AWAKE) and (to_ch <> ch)) then goto wind;

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

    txt := act_string(acts, to_ch, ch, arg1, arg2);

    to_ch.sendBuffer(to_ch.ansiColor(atype) + txt + #13#10);

    if (to_ch.IS_NPC) and (IS_SET(to_ch.npc_index.mpflags, MPROG_ACT)) then
       actTrigger(to_ch, ch, txt);

wind:
     if (typ = TO_CHAR) or (typ = TO_VICT) then
       node := nil
     else
     if (typ = TO_ROOM) or (typ = TO_NOTVICT) or (typ = TO_ALL) then
       node := node.next;
     end;
end;

procedure to_channel(ch : GCharacter; arg : string; channel : integer; color : integer);
var
   vict : GCharacter;
   node, node_next : GListNode;
begin
  node_next := char_list.head;

  while (node_next <> nil) do
    begin
    node := node_next;
    node_next := node_next.next;

    vict := node.element;

    if (channel <> CHANNEL_AUCTION) and (channel <> CHANNEL_CLAN) and (vict=ch) then continue;
    if (channel = CHANNEL_CHAT) and (not ch.IS_SAME_ALIGN(vict)) then continue;
    if (channel = CHANNEL_BABBEL) and (not ch.IS_SAME_ALIGN(vict)) then continue;
    if (channel = CHANNEL_RAID) and ((vict.level < 100) or (not ch.IS_SAME_ALIGN(vict))) then continue;
    if (channel = CHANNEL_AUCTION) and (not ch.IS_SAME_ALIGN(vict)) then continue;
    if (channel = CHANNEL_IMMTALK) and (not vict.IS_IMMORT) then continue;
    if (channel = CHANNEL_CLAN) and (vict.clan<>ch.clan) then continue;
    if (channel = CHANNEL_YELL) and (vict.room.area <> ch.room.area) then continue;
    if (channel = CHANNEL_LOG) and (not vict.IS_NPC) and (vict.level<system_info.level_log) then continue;

    act(color,arg,false,vict,nil,ch,TO_CHAR);
    end;
end;

procedure talk_channel(ch : GCharacter; arg : string; channel : integer; verb : string; color : integer);
var
   buf : string;
begin
  act(color,'You ' + verb + ', ''' + arg + '''',false,ch,nil,nil,TO_CHAR);

  buf := '$N ' + verb + 's, ''' + arg + '''';

  to_channel(ch, buf, channel, color);
end;

procedure to_group(ch : GCharacter; arg : string);
var
   node : GListNode;
   vict : GCharacter;
begin
  node := char_list.head;

  while (node <> nil) do
    begin
    vict := node.element;

    if (vict.leader = ch) then
      act(AT_REPORT, arg, false, vict, nil, nil, TO_CHAR);

    node := node.next;
    end;
end;


begin
  connection_list := GDLinkedList.Create;
end.
