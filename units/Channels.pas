// $Id: Channels.pas,v 1.7 2001/07/17 15:24:10 ***REMOVED*** Exp $

{
TODO:

Have channelignores save in pfile?
}

unit Channels;

interface

uses
  dtypes,
  chars,
  constants;

const
  channelDataFile = SystemDir + 'channels.xml';

  CHANNEL_FLAG_LOG = BV00;
  CHANNEL_FLAG_HISTORY = BV01;
  CHANNEL_FLAG_ROOM = BV02;
  CHANNEL_FLAG_AREA = BV03;
  CHANNEL_FLAG_ALIGN = BV04;
  CHANNEL_FLAG_GLOBAL = BV05;
  CHANNEL_FLAG_CLAN = BV06;
  CHANNEL_FLAG_GROUP = BV07;

type
  GChannel =
    class
      channelname : string;
      command : string;
      alias : string;
      minleveluse : integer; // minimum level to *use* channel
      minlevelsee : integer; // minimum level to *see* channel
      comment : string;
      channelcolor : integer;
      verbyou : string;
      verbother : string;
{ <!-- Flags: 1: log this channel; 2: channel has history; 4: room; 8: area;
  16: align; 32: global/interalign; 64: clan; 128: group --> }
      channel_flags : cardinal;
      cost : integer;
      constructor Create(chname : string);
      function LOG() : boolean;
      function HISTORY() : boolean;
      function ROOM() : boolean;
      function AREA() : boolean;
      function ALIGN() : boolean;
      function GLOBAL() : boolean;
      function CLAN() : boolean;
      function GROUP() : boolean;
    end;

  EBooleanConvertError = class(GException);

  ChannelFieldEnum = (FieldNone,
                      FieldCommand,
                      FieldAlias,
                      FieldMinimumleveluse,
                      FieldMinimumlevelsee,
                      FieldComment,
                      FieldChannelcolor,
                      FieldVerbyou,
                      FieldVerbother,
                      FieldFlags,
                      FieldCost);

var
  channellist : GDLinkedList;
  channels_loaded : boolean;

procedure load_channels();
procedure channelCommunicate(ch : GCharacter; param : string);
function lookupChannel(chname : string) : GChannel;
procedure to_channel(ch : GCharacter; arg : string; chanstr : string; color : integer); overload;
procedure to_channel(ch : GCharacter; arg : string; channel : GChannel; color : integer; localecho : boolean); overload;
procedure do_channel(ch : GCharacter; param : string);

implementation

uses
  SysUtils,
  mudsystem,
  mudthread,
  LibXmlParser,
  util,
  conns;

var
  errprefix : string;

constructor GChannel.Create(chname : string);
begin
  inherited Create();

  channelname := chname;
  command := '';
  alias := '';
  minleveluse := 1;
  minlevelsee := -1;
  comment := '';
  channelcolor := 15;
  verbyou := '%s';
  verbother := '%s';
  channel_flags := 0;
  cost := 0;
end;

function GChannel.LOG() : boolean;
begin
  Result := IS_SET(channel_flags, CHANNEL_FLAG_LOG);
end;

function GChannel.HISTORY() : boolean;
begin
  Result := IS_SET(channel_flags, CHANNEL_FLAG_HISTORY);
end;

function GChannel.ROOM() : boolean;
begin
  Result := IS_SET(channel_flags, CHANNEL_FLAG_ROOM);
end;

function GChannel.AREA() : boolean;
begin
  Result := IS_SET(channel_flags, CHANNEL_FLAG_AREA);
end;

function GChannel.ALIGN() : boolean;
begin
  Result := IS_SET(channel_flags, CHANNEL_FLAG_ALIGN);
end;

function GChannel.GLOBAL() : boolean;
begin
  Result := IS_SET(channel_flags, CHANNEL_FLAG_GLOBAL);
end;

function GChannel.CLAN() : boolean;
begin
  Result := IS_SET(channel_flags, CHANNEL_FLAG_CLAN);
end;

function GChannel.GROUP() : boolean;
begin
  Result := IS_SET(channel_flags, CHANNEL_FLAG_GROUP);
end;

function prep(str : string) : string;
begin
  Result := trim(uppercase(str));
end;

function StrToBoolean(str : string) : boolean;
begin
  if (prep(str) = 'TRUE') then
    Result := true
  else
  if (prep(str) = 'FALSE') then
    Result := false
  else
  if (prep(str) = 'YES') then
    Result := true
  else
  if (prep(str) = 'NO') then
    Result := false
  else
  if (prep(str) = 'ON') then
    Result := true
  else
  if (prep(str) = 'OFF') then
    Result := false
  else
  begin
    Result := false;
    raise EBooleanConvertError.CreateFmt('''%s'' invalid value for boolean; expected one of: true/false, yes/no, on/off', [str]);
  end;
end;

function BooleanToStr(b : boolean) : string;
begin
  if b then
    Result := 'true'
  else
    Result := 'false';
end;

function parseCardinal(str : string) : cardinal;
var
  i : integer;
  s : string;
begin
  Result := 0;
  repeat
    i := AnsiPos('|', str);
    s := copy(str, 1, i-1);
    if (s = '') then
      s := str
    else
      delete(str, 1, i);
    Result := Result + Cardinal(StrToInt(s)); // possible exceptions should be handled outside
  until (i = 0);
end;

function chan_ignored(ch : GPlayer; chanstr : string) : boolean;
var
  node : GListNode;
  tc : TChannel;
begin
  Result := false;
  
  node := ch.channels.head;
  while (node <> nil) do
  begin
    tc := node.element;
    if ((pos(prep(chanstr), prep(tc.channelname)) = 1)) then
    begin
      Result := tc.ignored;
      break;
    end;
    node := node.next;
  end;
end;

procedure channelAddHistory(vict, actor : GPlayer; channel : GChannel; str : string);
var
  node : GListNode;
  he : THistoryElement;
  tc : TChannel;
begin
  node := vict.channels.head;
  while (node <> nil) do
  begin
    tc := node.element;
    if (tc.channelname = channel.channelname) then
    begin
      he := THistoryElement.Create(vict.ansiColor(channel.channelcolor) + act_string(str, vict, nil, nil, actor));
      tc.history.insertLast(he);
      if (tc.history.getSize() > CHANNEL_HISTORY_MAX) then
      begin
        tc.history.remove(tc.history.head);
      end;
      break;
    end;
    node := node.next;
  end;
end;

procedure to_channel(ch : GCharacter; arg : string; chanstr : string; color : integer); overload;
var
  channel : GChannel;
begin
  channel := lookupChannel(chanstr);
  to_channel(ch, arg, channel, color, true);
end;

procedure to_channel(ch : GCharacter; arg : string; channel : GChannel; color : integer; localecho : boolean); overload;
var
   vict : GCharacter;
   node, node_next : GListNode;
begin
  if (not channels_loaded) then
  begin
    write_console('to_channel(): channels not loaded! Perhaps error loading/parsing ' + channelDataFile + '? Please correct this error.');
    exit;
  end;
  
  if (channel = nil) then
  begin
    bugreport('to_channel', 'Channels.pas', 'channel = nil');
    exit;
  end;
    
  if localecho and (ch <> nil) then // this is for clannotifies/groupnotifies
    act(color, arg, false, ch, nil, nil, TO_CHAR);

  node_next := char_list.head;
  while (node_next <> nil) do
  begin
    node := node_next;
    node_next := node_next.next;

    vict := node.element;

{    if (channel <> CHANNEL_AUCTION) and (channel <> CHANNEL_CLAN) and (vict=ch) then continue;
    if (channel = CHANNEL_CHAT) and (not ch.IS_SAME_ALIGN(vict)) then continue;
    if (channel = CHANNEL_BABBEL) and (not ch.IS_SAME_ALIGN(vict)) then continue;
    if (channel = CHANNEL_RAID) and ((vict.level < 100) or (not ch.IS_SAME_ALIGN(vict))) then continue;
    if (channel = CHANNEL_AUCTION) and (not ch.IS_SAME_ALIGN(vict)) then continue;
    if (channel = CHANNEL_IMMTALK) and (not vict.IS_IMMORT) then continue;
    if (channel = CHANNEL_CLAN) and (vict.clan<>ch.clan) then continue;
    if (channel = CHANNEL_YELL) and (vict.room.area <> ch.room.area) then continue;
    if (channel = CHANNEL_LOG) and (not vict.IS_NPC) and (vict.level<system_info.level_log) then continue;}

    with channel do
    begin
      if (ch <> nil) then
      begin
        if (vict = ch) then continue;
        if (vict.level < minlevelsee) then continue;
        if (ROOM() and (vict.room <> ch.room)) then continue;
        if (AREA() and (vict.room.area <> ch.room.area)) then continue;
        if (ALIGN() or not GLOBAL()) and (not ch.IS_SAME_ALIGN(vict)) then continue;
        if (CLAN() and (vict.clan <> ch.clan)) then continue;
        if (GROUP() and (vict.leader <> ch.leader)) then continue;
      end
      else // ch = nil
      begin
        if (not vict.IS_NPC()) and (vict.level < minlevelsee) then continue;
      end;
    end;

    if (vict <> nil) and (not vict.IS_NPC()) and channel.HISTORY() then
    begin
      channelAddHistory(GPlayer(vict), GPlayer(ch), channel, arg);
    end;

    if (vict <> nil) and (not vict.IS_NPC()) then
    begin
      if (not chan_ignored(GPlayer(vict), channel.channelname)) or (ch.IS_IMMORT()) then
        act(color, arg, false, vict, nil, ch, TO_CHAR)
    end
    else
      act(color, arg, false, vict, nil, ch, TO_CHAR);
  end;
end;

function lookupChannel(chname : string) : GChannel;
var
  node : GListNode;
  chan : GChannel;
begin
  Result := nil;
  node := channellist.head;
  while (node <> nil) do
  begin
    chan := node.element;
    if (chname = chan.channelname) or
       (pos(chname, chan.command) = 1) or
       ((chan.alias <> '') and (copy(chname, 1, length(chan.alias)) = chan.alias)) then
    begin
      Result := chan;
      exit;
    end;
    node := node.next;
  end;
end;

procedure channelCommunicate(ch : GCharacter; param : string);
var
  arg0, buf : string;
  chan : GChannel;
  node, node2 : GListNode;
  tc : TChannel;
  he : THistoryElement;
begin
  if (not channels_loaded) then
    begin
    write_console('channelCommunicate(): channels not loaded! Perhaps error loading/parsing ' + channelDataFile + '? Please correct this error.');
    exit;
    end;
    
  param := one_argument(param, arg0);
  chan := lookupChannel(arg0);

  if (ch = nil) then
    begin
    bugreport('channelCommunicate', 'Channels.pas', 'ch = nil');
    exit;
    end;

  if (chan = nil) then
    begin
    bugreport('channelCommunicate', 'Channels.pas', 'chan = nil');
    exit;
    end;

  if (chan.CLAN() and (ch.clan = nil)) then
    begin
    ch.sendBuffer('But you aren''t in a clan!'#13#10);
    exit;
    end;
  
  if ((length(param) = 0) and chan.HISTORY()) then
  begin
    if (ch.IS_NPC()) then
    begin
      ch.sendBuffer('Channel histories not available for NPCs.'#13#10);
      exit;
    end;
    if chan.HISTORY() then
    begin
      node := GPlayer(ch).channels.head;
      while (node <> nil) do
      begin
        tc := node.element;
        if (tc.channelname = chan.channelname) then
        begin
          node2 := tc.history.head;
          while (node2 <> nil) do
          begin
            he := node2.element;
            ch.sendBuffer(he.contents^ + #13#10);
            node2 := node2.next;
          end;
          break;
        end;
        node := node.next;
      end;
    end;
  end
  else
  begin
    if (chan.LOG()) then
    begin
      write_console(Format('Logged channel [%s]: %s ' + chan.verbother, [chan.channelname, ch.name^, param]));
    end;
    
    if (not ch.IS_IMMORT()) then
      ch.mv := ch.mv - chan.cost;
    
    buf := Format('You ' + chan.verbyou, [param]);
    act(chan.channelcolor, buf, false, ch, nil, nil, TO_CHAR);

    if (not ch.IS_NPC() and chan.HISTORY()) then // add text to own history
      channelAddHistory(GPlayer(ch), nil, chan, buf);

    buf := Format('$N ' + chan.verbother, [param]);
    to_channel(ch, buf, chan, chan.channelcolor, false);
  end;
end;

procedure processChannels(parser : TXmlParser; errprefix : string; Field : ChannelFieldEnum; ptr : pointer);
var
  attr : TNvpList;
  i : integer;
  chan : GChannel;
  chanparam : GChannel;
  str : string;
begin
  chanparam := GChannel(ptr);

  while (parser.Scan()) do
    case parser.CurPartType of // Here the parser tells you what it has found
{      ptDtdc:
        begin
          writeln('ptDtdc: ' + StrSFPas (Parser.CurStart, Parser.CurFinal));
        end;}
{      ptEmptyTag:
        begin
          writeln('ptEmptyTag');
        end;}
{      ptCData    : // Process Parser.CurContent field here
        begin
          writeln('ptCData: CurContent: ' + parser.CurContent);
        end;}
{        ptPI       : // Process PI here (Parser.CurName is the target, Parser.CurContent)
        begin
          writeln('ptPI: CurName: ' + parser.CurName + ' CurContent: ' + parser.CurContent);
        end;}
      ptStartTag: // Process Parser.CurName and Parser.CurAttr (see below) fields here
        begin
          if (prep(parser.CurName) = 'CHANNELS') then
            // this is ok
          else
          if (prep(parser.CurName) = 'CHANNELDATA') then
          begin
            if (parser.CurAttr.Count > 0) then
            begin
              attr := Parser.CurAttr;
              str := '';
              for i := 0 to (attr.Count - 1) do
              begin
                if (prep(TNvpNode(attr[i]).Name) = 'NAME') then
                  str := TNvpNode(attr[i]).Value;
              end;
              if (str = '') then
              begin
                write_console(errprefix + 'found channeldata tag with fields but no name field (error in channelfile).');
              end
              else
              begin
                chan := GChannel.Create(uppercase(str));
                processChannels(parser, errprefix, FieldNone, chan);
              end;
            end
            else
            begin
              write_console(errprefix + 'found channeldata tag without a name field (error in channelfile).');
            end;
          end
          else
          if (prep(parser.CurName) = 'COMMAND') then
            processChannels(parser, errprefix, FieldCommand, ptr)
          else
          if (prep(parser.CurName) = 'ALIAS') then
            processChannels(parser, errprefix, FieldAlias, ptr)
          else
          if (prep(parser.CurName) = 'MINIMUMLEVELUSE') then
            processChannels(parser, errprefix, FieldMinimumleveluse, ptr)
          else
          if (prep(parser.CurName) = 'MINIMUMLEVELSEE') then
            processChannels(parser, errprefix, FieldMinimumlevelsee, ptr)
          else
          if (prep(parser.CurName) = 'COMMENT') then
            processChannels(parser, errprefix, FieldComment, ptr)
          else
          if (prep(parser.CurName) = 'CHANNELCOLOR') then
            processChannels(parser, errprefix, FieldChannelcolor, ptr)
          else
          if (prep(parser.CurName) = 'VERBYOU') then
            processChannels(parser, errprefix, FieldVerbyou, ptr)
          else
          if (prep(parser.CurName) = 'VERBOTHER') then
            processChannels(parser, errprefix, FieldVerbother, ptr)
          else
          if (prep(parser.CurName) = 'FLAGS') then
            processChannels(parser, errprefix, FieldFlags, ptr)
          else
          if (prep(parser.CurName) = 'COST') then
            processChannels(parser, errprefix, FieldCost, ptr);
          // if unknown tag found, silently ignore, it'll be handled in ptContent (FieldNone)
        end;
      ptContent:
        begin
          if (chanparam = nil) then
            write_console(errprefix + '(ptContent) chanparam = nil (error in code).')
          else
            case Field of
              FieldNone:
                begin
                  write_console(errprefix + 'found unrecognized tag ''' + parser.CurName + ''' with content ''' + parser.CurContent + ''' (error in channelfile).');
                end;
              FieldCommand:
                begin
                  chanparam.command := uppercase(parser.CurContent);
                  exit;
                end;
              FieldAlias:
                begin
                  chanparam.alias := uppercase(parser.CurContent);
                  exit;
                end;
              FieldMinimumleveluse:
                begin
                  try
                    chanparam.minleveluse := StrToInt(parser.CurContent);
                    if ((chanparam.minleveluse < LEVEL_START) or (chanparam.minleveluse > LEVEL_MAX_IMMORTAL)) then
                    begin
                      write_console(errprefix + Format('found invalid value for Minimumleveluse tag (%d), value supposed to be >= %d and =< %d.', [chanparam.minleveluse, LEVEL_START, LEVEL_MAX_IMMORTAL]));
                    end;
                  except
                    on EConvertError do
                    begin
                      write_console(errprefix + Format('found invalid value for Minimumleveluse tag (''%s''), setting to %d.', [parser.CurContent, LEVEL_MAX_IMMORTAL]));
                      chanparam.minleveluse := LEVEL_MAX_IMMORTAL;
                    end;
                  end;
                  exit;
                end;
              FieldMinimumlevelsee:
                begin
                  try
                    chanparam.minlevelsee := StrToInt(parser.CurContent);
                    if ((chanparam.minlevelsee < LEVEL_START) or (chanparam.minlevelsee > LEVEL_MAX_IMMORTAL)) then
                    begin
                      write_console(errprefix + Format('found invalid value for Minimumlevelsee tag (%d), value supposed to be >= %d and =< %d.', [chanparam.minlevelsee, LEVEL_START, LEVEL_MAX_IMMORTAL]));
                    end;
                  except
                    on EConvertError do
                    begin
                      write_console(errprefix + Format('found invalid value for Minimumlevelsee tag (''%s''), setting to %d.', [parser.CurContent, LEVEL_MAX_IMMORTAL]));
                      chanparam.minlevelsee := LEVEL_MAX_IMMORTAL;
                    end;
                  end;
                  exit;
                end;
              FieldComment:
                begin
                  chanparam.comment := parser.CurContent;
                  exit;
                end;
              FieldChannelcolor:
                begin
                  try
                    chanparam.channelcolor := StrToInt(parser.CurContent);
                    if (chanparam.channelcolor < 0) then
                    begin
                      write_console(errprefix + Format('found invalid value for Channelcolor tag (%d), value supposed to be >= %d.', [chanparam.channelcolor, 0]));
                    end;
                  except
                    on EConvertError do
                    begin
                      write_console(errprefix + Format('found invalid value for Channelcolor tag (''%s''), setting to %d.', [parser.CurContent, LEVEL_MAX_IMMORTAL]));
                      chanparam.channelcolor := LEVEL_MAX_IMMORTAL;
                    end;
                  end;
                  exit;
                end;
              FieldVerbyou:
                begin
                  chanparam.verbyou := parser.CurContent;
                  exit;
                end;
              FieldVerbother:
                begin
                  chanparam.verbother := parser.CurContent;
                  exit;
                end;
              FieldFlags:
                begin
                  try
                    chanparam.channel_flags := parseCardinal(parser.CurContent);
                  except
                    on E: EConvertError do
                    begin
                      write_console(errprefix + Format('error parsing value for Flags tag (''%s''): %s.', [parser.CurContent, e.Message]));
                    end;
                  end;
                  exit;
                end;
              FieldCost:
                begin
                  try
                    chanparam.cost := StrToInt(parser.CurContent);
                  except
                    on EConvertError do
                    begin
                      write_console(errprefix + Format('found invalid value for Cost tag (''%s''), setting to %d.', [parser.CurContent, 0]));
                      chanparam.cost := 0;
                    end;
                  end;
                  exit;
                end;
            else
              write_console(errprefix + '(ptContent) found unrecognized Field enum (possible error in code).');
            end;
        end;
      ptEndTag   : // Process End-Tag here (Parser.CurName)
        begin
          if (prep(parser.CurName) = 'CHANNELS') then
            // this is ok
          else
          if (prep(parser.CurName) = 'CHANNELDATA') then
          begin
            channellist.insertLast(chanparam);
            exit;
          end
          else
          begin
//            write_console(errprefix + 'found unrecognized EndTag ''' + parser.CurName + ''' (error in channelfile).');
          end;
        end;
    end;
end;

procedure registerChannels(list : GDLinkedList);
var
  node : GListNode;
  chan : GChannel;
  cmd : GCommand;
  alias : GCommand;
begin
  node := list.head;
  while (node <> nil) do
  begin
    chan := node.element;
    
    if (chan.command <> '') then
    begin
      cmd := GCommand.Create();
      cmd.position := POS_SLEEPING;
      cmd.name := chan.command;
      cmd.func_name := 'channelCommunicate';
      cmd.level := chan.minleveluse;
      cmd.ptr := @channelCommunicate;
      cmd.addArg0 := true;

      commands.put(cmd.name, cmd);

      if (chan.alias <> '') then
      begin
        alias := GCommand.Create();
        alias.position := cmd.position;
        alias.name := chan.alias;
        alias.func_name := cmd.func_name;
        alias.level := chan.minleveluse;
        alias.ptr := cmd.ptr;
        alias.addArg0 := cmd.addArg0;

        commands.put(alias.name, alias);
      end;
    end;
    
    node := node.next;
  end;
end;

procedure writeChannelsToConsole();
var
  node : GListNode;
  chan : GChannel;
begin
  node := channellist.head;
  while (node <> nil) do
  begin
    chan := node.element;

    with chan do
    begin
      writeln('channelname: ' + channelname);
      writeln('  command:       ' + command);
      writeln('  alias:         ' + alias);
      writeln('  minleveluse:   ' + IntToStr(minleveluse));
      writeln('  minlevelsee:   ' + IntToStr(minlevelsee));
      writeln('  comment:       ' + comment);
      writeln('  channelcolor:  ' + IntToStr(channelcolor));
      writeln('  verbyou:       ' + verbyou);
      writeln('  verbother:     ' + verbother);
      writeln('  flags:         ' + IntToStr(integer(channel_flags)));
    end;
    writeln;

    node := node.next;
  end;
end;

procedure load_channels();
var
  parser : TXmlParser;
  node : GListNode;
  chan : GChannel;
begin
  parser := TXmlParser.Create();
  parser.Normalize := true;
  parser.LoadFromFile(channelDataFile);
  
  if (parser.Source <> channelDataFile) then
  begin
    write_console('Could not open ' + channelDataFile + ', channels disabled.');
    exit;
  end;

  errprefix := 'Error processing ' + channelDataFile + ': ';
  
  parser.StartScan();
  processChannels(parser, errprefix, FieldNone, nil);
  parser.Free();

  node := channellist.head;
  while (node <> nil) do // cpl sanity checks
  begin
    chan := node.element;
    with chan do
    begin
      if (verbyou = '') then
        verbyou := command;
      if (verbother = '') then
        verbother := verbyou + 's';
      if (minlevelsee = -1) then
        minlevelsee := minleveluse;
    end;
    node := node.next;
  end;

  chan := lookupChannel(CHANNEL_LOG);
  if (chan = nil) then
  begin
    write_console('PANIC: no LOG channel found while loading channels from ' + channelDatafile + '.');
    write_console('PANIC: this channel is *ESSENTIAL* to this mud.');
    write_console('PANIC: Please add the following to ' + channelDataFile + ':');
    write_console('         <ChannelData Name="log">');
    write_console('           <Flags>1|32</Flags>');
    write_console('         </ChannelData>');
    halt;
  end
  else
  begin
    if (chan.minlevelsee <> system_info.level_log) then
    begin
      write_console(Format('Warning: value of minimumlevelsee field of channel ''log'' (%d) doesn''t equal LevelLog value in system\sysdata.dat ().', [chan.minlevelsee, system_info.level_log]));
      write_console('Warning: setting minimumlevelsee to value in system\sysdata.dat.');
      chan.minlevelsee := system_info.level_log;
    end;
  end;

  registerChannels(channellist);

  if (channellist.getSize() < 1) then
    write_console('no channels loaded from ' + channelDataFile + ', please check that file. Channels disabled for now.')
  else
    write_console(Format('%d channels loaded from file %s and registered.', [channellist.getSize(), channelDataFile]));

//  writeChannelsToConsole();
  channels_loaded := true;
end;

procedure do_channel(ch : GCharacter; param : string);
var
  node : GListNode;
  chan : GChannel;
  buf : string;
  arg1, arg2 : string;
  tc : TChannel;
begin
  param := one_argument(param, arg1);
  param := one_argument(param, arg2);
  if (length(arg1) = 0) then
  begin
    ch.sendBuffer('Usage: CHANNEL <list>|[<channelname> <on/off>] '#13#10);
    ch.sendBuffer('Note: on/off feature not implemented yet.'#13#10);
    exit;
  end
  else
  if (prep(arg1) = 'LIST') then
  begin
    node := channellist.head;
    while (node <> nil) do
    begin
      chan := node.element;
      if (ch.level >= chan.minleveluse) then
      begin
        buf := '';

        if (not ch.IS_NPC()) then
          if (chan_ignored(GPlayer(ch), chan.channelname)) then
            buf := '$B$7ignored$A$7'
          else
            buf := '$B$7not ignored$A$7';

        with chan do
        begin
          if (ch.IS_IMMORT()) then
          begin
            buf := Format('%s%s$A$7: (%s) command: %s; alias: %s; minleveluse: %d; minlevelsee: %d.$A$7'#13#10, [ch.ansiColor(channelcolor), channelname, buf, command, alias, minleveluse, minlevelsee]);
            buf := buf + '  verbyou: "' + verbyou + '" verbother: "' + verbother + '"'#13#10;
          end
          else
          begin
            buf := Format('%s%s$A$7: (%s) command: %s; alias: %s; minimumlevel: %d.$A$7'#13#10, [ch.ansiColor(channelcolor), channelname, buf, command, alias, minleveluse]);
          end;
          buf := buf + Format('  %s'#13#10, [comment]);
        end;
        ch.sendPager(act_string(buf, ch, nil, nil, nil));
      end;
      node := node.next;
    end;
  end
  else
  begin
    if (ch.IS_NPC()) then
    begin
      ch.sendBuffer('This command is not available for NPCs.'#13#10);
      exit;
    end;

    node := GPlayer(ch).channels.head;
    while (node <> nil) do
    begin
      tc := node.element;
      if ((pos(prep(arg1), prep(tc.channelname)) = 1)) then
      begin
        if (length(arg2) = 0) then
        begin
          if (tc.ignored) then
            buf := '$B$7ignored$A$7'
          else
            buf := '$B$7not ignored$A$7';
          ch.sendBuffer(act_string(Format('%s is currently %s.'#13#10, [tc.channelname, buf]), ch, nil, nil, nil));
        end
        else
        begin
          try
            tc.ignored := not StrToBoolean(arg2);
          except
            on E: EBooleanConvertError do
            begin
              ch.sendBuffer(Format('Invalid argument ''%s''.'#13#10, [arg2]));
            end;
          end;
          
          if (tc.ignored) then
            buf := '$B$7ignored$A$7'
          else
            buf := '$B$7not ignored$A$7';
          ch.sendBuffer(act_string(Format('%s is now %s.'#13#10, [tc.channelname, buf]), ch, nil, nil, nil));
        end;
      end;
      node := node.next;
    end;
  end;
end;

begin
  channellist := GDLinkedList.Create();
  channels_loaded := false;
end.

