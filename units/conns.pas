{
  @abstract(Connection manager)
  @lastmod($Id: conns.pas,v 1.45 2003/10/15 22:38:00 ***REMOVED*** Exp $)
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

const
		IAC_COMPRESS = 85;		// MCCP v1
		IAC_COMPRESS2 = 86;		// MCCP v2
		IAC_SE = 240;
		IAC_SB = 250;
		IAC_WILL = 251;
		IAC_WONT = 252;
		IAC_DO = 253;
		IAC_DONT = 254;
		IAC_IAC = 255;

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
      procedure read();
      procedure sendIAC(option : byte; params : array of byte);
      procedure processIAC();
      procedure readBuffer();

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
function act_color(to_ch : GCharacter; acts : string; sep : char) : string;

procedure act(atype : integer; acts : string; hideinvis : boolean; ch : GCharacter;
              arg1, arg2 : pointer; typ : integer);

function playername(from_ch, to_ch : GCharacter) : string;

procedure gameLoop();

procedure initConns();
procedure cleanupConns();

implementation

uses
  FastStrings,
  FastStringFuncs,
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
  
  sendIAC(IAC_WILL, [IAC_COMPRESS2]);
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
  	while (not sock.canWrite()) do;
  	
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
			writeConsole('(' + IntToStr(sock.getDescriptor) + ') could not terminate thread');
    end;
  end;
  
  idle := 0;

  repeat
    read := recv(sock.getDescriptor, buf, MAX_RECEIVE - 10, 0);

    if (read > 0) then
      begin
      buf[read] := #0;
      input_buf := input_buf + buf;

			processIAC();
      end
    else
    if (read = 0) then
      begin
      try
        thread.terminate;
      except
          writeConsole('(' + IntToStr(sock.getDescriptor) + ') could not terminate thread');
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
          writeConsole('(' + IntToStr(sock.getDescriptor) + ') could not terminate thread');
        end;

        exit;
        end;
{$ELSE}
      break;
{$ENDIF}      
      end;
  until false;
end;

procedure GConnection.sendIAC(option : byte; params : array of byte);
var
	buf : array[0..255] of char;
	i : integer;
begin
	buf[0] := chr(IAC_IAC);
	buf[1] := chr(option);
	
	for i := 0 to length(params) - 1 do
		buf[2 + i] := chr(params[i]);
  	
	while (not sock.canWrite()) do;
  	
  sock.send(buf, 2 + length(params));
end;

procedure GConnection.processIAC();
var 
	i : integer;
	iac : boolean;
	new_buf : string;
begin
	iac := false;
	new_buf := '';
	i := 1;
	
	while (i <= length(input_buf)) do
		begin
    if (iac) then
    	begin
    	case byte(input_buf[i]) of
    		IAC_WILL: 	begin
										inc(i);
    								writeConsole('(' + IntToStr(sock.getDescriptor) + ') IAC WILL ' + IntToStr(byte(input_buf[i])));
			    					end;
    		IAC_WONT: 	begin
										inc(i);
    								writeConsole('(' + IntToStr(sock.getDescriptor) + ') IAC WON''T ' + IntToStr(byte(input_buf[i])));
										end;
    		IAC_DO: 		begin
										inc(i);
    								case byte(input_buf[i]) of
    									IAC_COMPRESS2:	begin
    																	writeConsole('(' + IntToStr(sock.getDescriptor) + ') Client has MCCPv2');
    																	end;
    								end;
    								
    								writeConsole('(' + IntToStr(sock.getDescriptor) + ') IAC DO ' + IntToStr(byte(input_buf[i])));
										end;
    		IAC_DONT: 	begin
										inc(i);
    								writeConsole('(' + IntToStr(sock.getDescriptor) + ') IAC DON''T ' + IntToStr(byte(input_buf[i])));
										end;
			else
	    	writeConsole('(' + IntToStr(sock.getDescriptor) + ') IAC ' + IntToStr(byte(input_buf[i])));
    	end;     	
    	
    	iac := false;
    	end    	
    else
    if (byte(input_buf[i]) = IAC_IAC) then		// IAC
    	begin
    	iac := true;
    	end
    else
    	new_buf := new_buf + input_buf[i];
    	
   	inc(i);
    end;
    
  input_buf := new_buf;
end;

procedure GConnection.readBuffer();
var 
	i : integer;
begin
  if (length(comm_buf) <> 0) or ((pos(#10, input_buf) = 0) and (pos(#13, input_buf) = 0))  then
    exit;

  i := 1;

  while (i <= length(input_buf)) and (input_buf[i] <> #13) and (input_buf[i] <> #10) do
    begin
    if ((input_buf[i] = #8) or (input_buf[i] = #127)) then
      delete(comm_buf, length(comm_buf), 1)
    else
    //if (byte(input_buf[i]) > 31) and (byte(input_buf[i]) < 127) then
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
      playername := from_ch.name
    else
    if (not to_ch.IS_SAME_ALIGN(from_ch)) then
      begin
      if (from_ch.race.name[1] in ['A','E','O','I','U']) then
        playername := '+* An ' + from_ch.race.name + ' *+'
      else
        playername := '+* A ' + from_ch.race.name + ' *+';
      end
    else
      playername := from_ch.name;
    end
  else
    playername := from_ch.name;

  if (from_ch = to_ch) then
    playername := 'you';
end;

function act_color(to_ch : GCharacter; acts : string; sep : char) : string;
var
  last, current : integer;
  boldflag : boolean;
  res : string;
begin
  last := 1;
  current := FastCharPos(acts, sep, last);
  res := '';
  
  while (current <> 0) do
    begin
    if (current - last > 0) then
      res := res + CopyStr(acts, last, current - last);

    last := current + 2;
       
    case acts[current + 1] of
        'B': boldflag := true;
        'A': boldflag := false;
   '0'..'9': begin
             if (boldflag) then
               res := res + to_ch.ansiColor(strtoint(acts[current + 1]) + 8)
             else
               res := res + to_ch.ansiColor(strtoint(acts[current + 1])); 
             end;
    end;
    
    current := FastCharPos(acts, sep, last);
    end;
    
  Result := res + CopyStr(acts, last, length(acts) - last + 1)
end;

function act_string(acts : string; to_ch, ch : GCharacter; arg1, arg2 : pointer) : string;
var
  last, current : integer;
  res, temp : string;
  vch : GCharacter;
  obj1, obj2 : TObject;
  ex : GExit;
begin
  last := 1;
  current := FastCharPos(acts, '$', last);
  res := '';
  vch := arg2;
  obj1 := arg1; obj2 := arg2;

  while (current <> 0) do
    begin
    if (current - last > 0) then
      res := res + CopyStr(acts, last, current - last);

    last := current + 2;
       
		case acts[current + 1] of
			'n': res := res + playername(ch, to_ch);
			'N': begin
					 if (vch = nil) then
						 writeConsole('[BUG]: act() -> vch null')
					 else
						 res := res + playername(vch, to_ch);
					 end;
			'm': res := res + sex_nm[ch.sex];
			'M': begin
					 if (vch = nil) then
						 writeConsole('[BUG]: act() -> vch null')
					 else
						 res := res + sex_nm[vch.sex];
					 end;
			's': res := res + sex_bm[ch.sex];
			'S': begin
					 if (vch = nil) then
						 writeConsole('[BUG]: act() -> vch null')
					 else
						 res := res + sex_bm[vch.sex];
					 end;
			'e': res := res + sex_pm[ch.sex];
			'E': begin
					 if (vch = nil) then
						 writeConsole('[BUG]: act() -> vch null')
					 else
						 res := res + sex_pm[vch.sex];
					 end;
		 'o': begin
					 if (obj1 = nil) then
						 writeConsole('[BUG]: act() -> obj1 null')
					 else
						 res := res + GObject(obj1).name;
					 end;
			'O': begin
					 if (obj2 = nil) then
						 writeConsole('[BUG]: act() -> obj2 null')
					 else
						 res := res + GObject(obj2).name;
					 end;
			'p': begin
					 if (obj1 = nil) then
						 writeConsole('[BUG]: act() -> obj1 null')
					 else
						 res := res + GObject(obj1).short;
					 end;
			'P': begin
					 if (obj2 = nil) then
						 writeConsole('[BUG]: act() -> obj2 null')
					 else
						 res := res + GObject(obj2).short;
					 end;
			't': begin
					 if (arg1 = nil) then
						 writeConsole('[BUG]: act() -> pchar(arg1) null')
					 else
						 res := res + (PString(arg1))^;
					 end;
			'T': begin
					 if (arg2 = nil) then
						 writeConsole('[BUG]: act() -> pchar(arg2) null')
					 else
						 res := res + (PString(arg2))^;
					 end;
			'd': begin
						 if (arg2 = nil) then
							 writeConsole('[BUG]: act() -> arg2 is nil')
						 else
						 begin
							 ex := GExit(arg2);

							 if ((ex.keywords <> nil) and (length(ex.keywords^) = 0)) then
								 res := res + 'door'
							 else
							   begin
								 one_argument(ex.keywords^, temp);
								 res := res + temp;
								 end;
						 end;
					 end;
			else
			  res := res + '$' + acts[current + 1];
		end;
    
    current := FastCharPos(acts, '$', last);
    end;
    
  res := cap(res + CopyStr(acts, last, length(acts) - last + 1));

  Result := act_color(to_ch, res, '$');
 end;

{var 
  i : ShortString;
  x : string;
  s : array[0..1023] of char;
  t, c : integer;
  vch : GCharacter;
  obj1, obj2 : TObject;
  ex : GExit;
begin
  vch := arg2;
  obj1 := arg1; obj2 := arg2;
  t := 1;
  c := 0;

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
               i := GObject(obj1).name;
             end;
        'O': begin
             if (obj2 = nil) then
               writeConsole('[BUG]: act() -> obj2 null')
             else
               i := GObject(obj2).name;
             end;
        'p': begin
             if (obj1 = nil) then
               writeConsole('[BUG]: act() -> obj1 null')
             else
               i := GObject(obj1).short;
             end;
        'P': begin
             if (obj2 = nil) then
               writeConsole('[BUG]: act() -> obj2 null')
             else
               i := GObject(obj2).short;
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
                   one_argument(ex.keywords^, x);
               end;
             end;
   '0'..'9','A','B':begin
                    i:='$'+acts[t];
                    end;
      else
        writeConsole('[BUG]: act() -> bad format code');
      end;

      Move(i[1], s[c], length(i));
      c := c + length(i);
      end
    else 
      begin
      s[c] := acts[t];
      inc(c);
      end;

    inc(t);
    end;

  s[c] := #0;
  s[0] := UpCase(s[0]);

  act_string := act_color(to_ch, s, '$');
end; }

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
  ac := list_sock.acceptConnection(system_info.lookup_hosts);
  
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
  while (not system_info.terminated) and (not Application.Terminated) do
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

		pollConsole();
    
    sleep(25);
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
