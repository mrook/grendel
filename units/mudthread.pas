unit mudthread;

interface

uses
    Classes,
    Windows,
    Winsock2,
    SysUtils,
    ansiio,
    constants,
    conns,
    chars,
    race,
    clan,
    area,
    dtypes,
    skills,
    strip,
    util,
    mudhelp,
    mudsystem;

type
    GThread = class(TThread)
    private
      socket : TSocket;
      client_addr : TSockAddr_Storage;
      copyover : boolean;
      copyover_name : string;

    protected
      procedure Execute; override;

    public
      constructor Create(s : TSocket; a : TSockAddr_Storage; copy : boolean; name : string);
    end;

    COMMAND_FUNC = procedure(ch : GCharacter; param : string);

    GCommand = class
      name : string;
      func_name : string;
      ptr : COMMAND_FUNC;
      level : integer;             { minimum level }
      position : integer;          { minimum position }
    end;

var
   commands : GHashObject;

procedure load_commands;
procedure interpret(ch : GCharacter; line : string);

implementation

uses
    magic,
    md5,
    update,
    progs,
    fight;

constructor GThread.Create(s : TSocket; a : TSockAddr_Storage; copy : boolean; name : string);
begin
  inherited Create(False);

  socket := s;
  client_addr := a;
  copyover := copy;
  copyover_name := name;
end;

{$I include\command.inc}

procedure do_dummy(ch : GCharacter; param : string);
begin
  ch.sendBuffer('This is a DUMMY command. Please contact the ADMINISTRATION.'#13#10);
end;

function commandHash(size, prime : cardinal; key : string) : integer;
begin
  if (length(key) >= 1) then
    Result := (byte(key[1]) * prime) mod size
  else
    Result := 0;
end;

function findCommand(s : string) : COMMAND_FUNC;
var
   g : COMMAND_FUNC;
begin
  if (comparestr(s, 'do_quit') = 0) then
    g := do_quit
  else
  if (comparestr(s, 'do_save') = 0) then
    g := do_save
  else
  if (comparestr(s, 'do_afk') = 0) then
    g := do_afk
  else
  if (comparestr(s, 'do_help') = 0) then
    g := do_help
  else
  if (comparestr(s, 'do_remort') = 0) then
    g := do_remort
  else
  if (comparestr(s, 'do_delete') = 0) then
    g := do_delete
  else
  if (comparestr(s, 'do_wimpy') = 0) then
    g := do_wimpy
  else
  if (comparestr(s, 'do_time') = 0) then
    g := do_time
  else
  if (comparestr(s, 'do_weather') = 0) then
    g := do_weather
  else
  if (comparestr(s, 'do_look') = 0) then
    g := do_look
  else
  if (comparestr(s, 'do_inventory') = 0) then
    g := do_inventory
  else
  if (comparestr(s, 'do_equipment') = 0) then
    g := do_equipment
  else
  if (comparestr(s, 'do_score') = 0) then
    g := do_score
  else
  if (comparestr(s, 'do_stats') = 0) then
    g := do_stats
  else
  if (comparestr(s, 'do_who') = 0) then
    g := do_who
  else
  if (comparestr(s, 'do_title') = 0) then
    g := do_title
  else
  if (comparestr(s, 'do_group') = 0) then
    g := do_group
  else
  if (comparestr(s, 'do_follow') = 0) then
    g := do_follow
  else
  if (comparestr(s, 'do_armor') = 0) then
    g := do_armor
  else
  if (comparestr(s, 'do_config') = 0) then
    g := do_config
  else
  if (comparestr(s, 'do_visible') = 0) then
    g := do_visible
  else
  if (comparestr(s, 'do_trophy') = 0) then
    g := do_trophy
  else
  if (comparestr(s, 'do_ditch') = 0) then
    g := do_ditch
  else
  if (comparestr(s, 'do_world') = 0) then
    g := do_world
  else
  if (comparestr(s, 'do_where') = 0) then
    g := do_where
  else
  if (comparestr(s, 'do_kill') = 0) then
    g := do_kill
  else
  if (comparestr(s, 'do_north') = 0) then
    g := do_north
  else
  if (comparestr(s, 'do_south') = 0) then
    g := do_south
  else
  if (comparestr(s, 'do_east') = 0) then
    g := do_east
  else
  if (comparestr(s, 'do_west') = 0) then
    g := do_west
  else
  if (comparestr(s, 'do_up') = 0) then
    g := do_up
  else
  if (comparestr(s, 'do_down') = 0) then
    g := do_down
  else
  if (comparestr(s, 'do_sleep') = 0) then
    g := do_sleep
  else
  if (comparestr(s, 'do_wake') = 0) then
    g := do_wake
  else
  if (comparestr(s, 'do_meditate') = 0) then
    g := do_meditate
  else
  if (comparestr(s, 'do_rest') = 0) then
    g := do_rest
  else
  if (comparestr(s, 'do_sit') = 0) then
    g := do_sit
  else
  if (comparestr(s, 'do_stand') = 0) then
    g := do_stand
  else
  if (comparestr(s, 'do_flee') = 0) then
    g := do_flee
  else
  if (comparestr(s, 'do_flurry') = 0) then
    g := do_flurry
  else
  if (comparestr(s, 'do_assist') = 0) then
    g := do_assist
  else
  if (comparestr(s, 'do_disengage') = 0) then
    g := do_disengage
  else
  if (comparestr(s, 'do_cast') = 0) then
    g := do_cast
  else
  if (comparestr(s, 'do_bash') = 0) then
    g := do_bash
  else
  if (comparestr(s, 'do_kick') = 0) then
    g := do_kick
  else
  if (comparestr(s, 'do_fly') = 0) then
    g := do_fly
  else
  if (comparestr(s, 'do_sneak') = 0) then
    g := do_sneak
  else
  if (comparestr(s, 'do_spells') = 0) then
    g := do_spells
  else
  if (comparestr(s, 'do_skills') = 0) then
    g := do_skills
  else
  if (comparestr(s, 'do_learn') = 0) then
    g := do_learn
  else
  if (comparestr(s, 'do_practice') = 0) then
    g := do_practice
  else
  if (comparestr(s, 'do_enter') = 0) then
    g := do_enter
  else
  if (comparestr(s, 'do_search') = 0) then
    g := do_search
  else
  if (comparestr(s, 'do_backstab') = 0) then
    g := do_backstab
  else
  if (comparestr(s, 'do_circle') = 0) then
    g := do_circle
  else
  if (comparestr(s, 'do_chat') = 0) then
    g := do_chat
  else
  if (comparestr(s, 'do_raid') = 0) then
    g := do_raid
  else
  if (comparestr(s, 'do_immtalk') = 0) then
    g := do_immtalk
  else
  if (comparestr(s, 'do_say') = 0) then
    g := do_say
  else
  if (comparestr(s, 'do_tell') = 0) then
    g := do_tell
  else
  if (comparestr(s, 'do_reply') = 0) then
    g := do_reply
  else
  if (comparestr(s, 'do_yell') = 0) then
    g := do_yell
  else
  if (comparestr(s, 'do_suggest') = 0) then
    g := do_suggest
  else
  if (comparestr(s, 'do_pray') = 0) then
    g := do_pray
  else
  if (comparestr(s, 'do_emote') = 0) then
    g := do_emote
  else
  if (comparestr(s, 'do_auctalk') = 0) then
    g := do_auctalk
  else
  if (comparestr(s, 'do_babbel') = 0) then
    g := do_babbel
  else
  if (comparestr(s, 'do_shutdown') = 0) then
    g := do_shutdown
  else
  if (comparestr(s, 'do_echo') = 0) then
    g := do_echo
  else
  if (comparestr(s, 'do_thunder') = 0) then
    g := do_thunder
  else
  if (comparestr(s, 'do_wizinvis') = 0) then
    g := do_wizinvis
  else
  if (comparestr(s, 'do_sla') = 0) then
    g := do_sla
  else
  if (comparestr(s, 'do_slay') = 0) then
    g := do_slay
  else
  if (comparestr(s, 'do_affects') = 0) then
    g := do_affects
  else
  if (comparestr(s, 'do_socials') = 0) then
    g := do_socials
  else
  if (comparestr(s, 'do_advance') = 0) then
    g := do_advance
  else
  if (comparestr(s, 'do_get') = 0) then
    g := do_get
  else
  if (comparestr(s, 'do_wear') = 0) then
    g := do_wear
  else
  if (comparestr(s, 'do_remove') = 0) then
    g := do_remove
  else
  if (comparestr(s, 'do_drop') = 0) then
    g := do_drop
  else
  if (comparestr(s, 'do_sacrificee') = 0) then
    g := do_sacrifice
  else
  if (comparestr(s, 'do_swap') = 0) then
    g := do_swap
  else
  if (comparestr(s, 'do_drink') = 0) then
    g := do_drink
  else
  if (comparestr(s, 'do_eat') = 0) then
    g := do_eat
  else
  if (comparestr(s, 'do_scalp') = 0) then
    g := do_scalp
  else
  if (comparestr(s, 'do_give') = 0) then
    g := do_give
  else
  if (comparestr(s, 'do_throw') = 0) then
    g := do_throw
  else
  if (comparestr(s, 'do_alias') = 0) then
    g := do_alias
  else
  if (comparestr(s, 'do_clanadd') = 0) then
    g := do_clanadd
  else
  if (comparestr(s, 'do_clanremove') = 0) then
    g := do_clanremove
  else
  if (comparestr(s, 'do_clantalk') = 0) then
    g := do_clantalk
  else
  if (comparestr(s, 'do_clan') = 0) then
    g := do_clan
  else
  if (comparestr(s, 'do_brag') = 0) then
    g := do_brag
  else
  if (comparestr(s, 'do_force') = 0) then
    g := do_force
  else
  if (comparestr(s, 'do_restore') = 0) then
    g := do_restore
  else
  if (comparestr(s, 'do_goto') = 0) then
    g := do_goto
  else
  if (comparestr(s, 'do_transfer') = 0) then
    g := do_transfer
  else
  if (comparestr(s, 'do_peace') = 0) then
    g := do_peace
  else
  if (comparestr(s, 'do_areas') = 0) then
    g := do_areas
  else
  if (comparestr(s, 'do_connections') = 0) then
    g := do_connections
  else
  if (comparestr(s, 'do_uptime') = 0) then
    g := do_uptime
  else
  if (comparestr(s, 'do_grace') = 0) then
    g := do_grace
  else
  if (comparestr(s, 'do_open') = 0) then
    g := do_open
  else
  if (comparestr(s, 'do_close') = 0) then
    g := do_close
  else
  if (comparestr(s, 'do_consider') = 0) then
    g := do_consider
  else
  if (comparestr(s, 'do_scan') = 0) then
    g := do_scan
  else
  if (comparestr(s, 'do_sacrifice') = 0) then
    g := do_sacrifice
  else
  if (comparestr(s, 'do_bgset') = 0) then
    g := do_bgset
  else
  if (comparestr(s, 'do_battle') = 0) then
    g := do_battle
  else
  if (comparestr(s, 'do_auction') = 0) then
    g := do_auction
  else
  if (comparestr(s, 'do_bid') = 0) then
    g := do_bid
  else
  if (comparestr(s, 'do_balance') = 0) then
    g := do_balance
  else
  if (comparestr(s, 'do_withdraw') = 0) then
    g := do_withdraw
  else
  if (comparestr(s, 'do_deposit') = 0) then
    g := do_deposit
  else
  if (comparestr(s, 'do_list') = 0) then
    g := do_list
  else
  if (comparestr(s, 'do_buy') = 0) then
    g := do_buy
  else
  if (comparestr(s, 'do_sell') = 0) then
    g := do_sell
  else
  if (comparestr(s, 'do_rescue') = 0) then
    g := do_rescue
  else
  if (comparestr(s, 'do_disconnect') = 0) then
    g := do_disconnect
  else
  if (comparestr(s, 'do_wizhelp') = 0) then
    g := do_wizhelp
  else
  if (comparestr(s, 'do_rstat') = 0) then
    g := do_rstat
  else
  if (comparestr(s, 'do_mstat') = 0) then
    g := do_mstat
  else
  if (comparestr(s, 'do_ostat') = 0) then
    g := do_ostat
  else
  if (comparestr(s, 'do_report') = 0) then
    g := do_report
  else
  if (comparestr(s, 'do_destroy') = 0) then
    g := do_destroy
  else
  if (comparestr(s, 'do_loadup') = 0) then
    g := do_loadup
  else
  if (comparestr(s, 'do_freeze') = 0) then
    g := do_freeze
  else
  if (comparestr(s, 'do_silence') = 0) then
    g := do_silence
  else
  if (comparestr(s, 'do_log') = 0) then
    g := do_log
  else
  if (comparestr(s, 'do_snoop') = 0) then
    g := do_snoop
  else
  if (comparestr(s, 'do_switch') = 0) then
    g := do_switch
  else
  if (comparestr(s, 'do_return') = 0) then
    g := do_return
  else
  if (comparestr(s, 'do_sconfig') = 0) then
    g := do_sconfig
  else
  if (comparestr(s, 'do_track') = 0) then
    g := do_track
  else
  if (comparestr(s, 'do_bamfin') = 0) then
    g := do_bamfin
  else
  if (comparestr(s, 'do_bamfout') = 0) then
    g := do_bamfout
  else
  if (comparestr(s, 'do_mload') = 0) then
    g := do_mload
  else
  if (comparestr(s, 'do_oload') = 0) then
    g := do_oload
  else
  if (comparestr(s, 'do_mfind') = 0) then
    g := do_mfind
  else
  if (comparestr(s, 'do_ofind') = 0) then
    g := do_ofind
  else
  if (comparestr(s, 'do_put') = 0) then
    g := do_put
  else
  if (comparestr(s, 'do_sset') = 0) then
    g := do_sset
  else
  if (comparestr(s, 'do_taunt') = 0) then
    g := do_taunt
  else
  if (comparestr(s, 'do_nourish') = 0) then
    g := do_nourish
  else
  if (comparestr(s, 'do_mana') = 0) then
    g := do_mana
  else
  if (comparestr(s, 'do_fill') = 0) then
    g := do_fill
  else
  if (comparestr(s, 'do_unlock') = 0) then
    g := do_unlock
  else
  if (comparestr(s, 'do_lock') = 0) then
    g := do_lock
  else
  if (comparestr(s, 'do_ascore') = 0) then
    g := do_ascore
  else
  if (comparestr(s, 'do_revive') = 0) then
    g := do_revive
  else
  if (comparestr(s, 'do_setpager') = 0) then
    g := do_setpager
  else
  if (comparestr(s, 'do_autoloot') = 0) then
    g := do_autoloot
  else
  if (comparestr(s, 'do_autosac') = 0) then
    g := do_autosac
  else
  if (comparestr(s, 'do_password') = 0) then
    g := do_password
  else
  if (comparestr(s, 'do_ban') = 0) then
    g := do_ban
  else
  if (comparestr(s, 'do_allow') = 0) then
    g := do_allow
  else
  if (comparestr(s, 'do_last') = 0) then
    g := do_last
  else
  if (comparestr(s, 'do_unlearn') = 0) then
    g := do_unlearn
  else
  if (comparestr(s, 'do_hashstats') = 0) then
    g := do_hashstats
  else
    begin
    g := nil;

    //bugreport('findCommand', 'mudthread.pas', s + ' unknown',
    //          'This command has not been found. Please check your settings.');
    end;

  findCommand := g;
end;

procedure load_commands;
var f:textfile;
    s,g:string;
    cmd, alias : GCommand;
begin
  assignfile(f, 'system\commands.dat');
  {$I-}
  reset(f);
  {$I+}
  if IOResult<>0 then
    begin
    bugreport('load_commands', 'mudthread.pas', 'could not open system\commands.dat',
              'The system file commands.dat could not be opened.');
    exit;
    end;

  commands := GHashObject.Create(32);
  commands.setHashFunc(commandHash);

  repeat
    repeat
      readln(f,s);
    until (uppercase(s) = '#COMMAND') or eof(f);

    if (eof(f)) then
      break;

    alias := nil;
    cmd := GCommand.Create;
    cmd.position := POS_MEDITATE;

    with cmd do
      repeat
      readln(f,s);
      g:=uppercase(stripl(s,':'));

      if g='NAME' then
        name := uppercase(striprbeg(s,' '))
      else
      if g='ALIAS' then
        begin
        // create an alias
        alias := GCommand.Create;
        alias.name := uppercase(striprbeg(s,' '));
        end
      else
      if g='LEVEL' then
        level:=strtoint(striprbeg(s,' '))
      else
      if g='POSITION' then
        position:=strtoint(striprbeg(s,' '))
      else
      if g='FUNCTION' then
        begin
        func_name := striprbeg(s,' ');
        ptr := findCommand(func_name);
        end;
      until (uppercase(s)='#END') or eof(f);

    if (assigned(cmd.ptr)) then
      begin
      commands.hashObject(cmd, cmd.name);

      if (alias <> nil) then
        begin
        // update settings
        alias.level := cmd.level;
        alias.ptr := cmd.ptr;
        alias.func_name := cmd.func_name;
        alias.position := cmd.position;

        commands.hashObject(alias, alias.name);
        end;
      end
    else
      begin
      cmd.Free;

      if (alias <> nil) then
        alias.Free;
      end;
  until eof(f);

  closefile(f);
end;

procedure clean_cmdline(var line : string);
var
   d : integer;
begin
  d := pos('$', line);

  while (d > 0) do
    begin
    delete(line, d, 1);

    d := pos('$', line);
    end;
end;

procedure interpret(ch : GCharacter; line : string);
var
    a, g : longint;
    cmd : GCommand;
    node : GListNode;
    cmdline, param : string;
    hash, time : cardinal;
    al : GAlias;
begin
  with ch do
    begin
    if (conn <> nil) and (GConnection(conn).afk) and (not IS_NPC) then
      begin
      GConnection(conn).afk := false;
      act(AT_REPORT,'You are now back at your keyboard.',false,ch,nil,nil,to_char);
      act(AT_REPORT,'$n has returned to &s keyboard.',false,ch,nil,nil,to_room);
    end;

    if (ch.position = POS_CASTING) then
      begin
      act(AT_REPORT, 'You stop casting.', false, ch, nil, nil, TO_CHAR);
      removeTimer(ch,TIMER_CAST);
      ch.position := POS_STANDING;
      end;

    if (length(line) = 0) then
      begin
      ch.sendBuffer(' ');
      exit;
      end;

    if (snooped_by <> nil) then
      GConnection(snooped_by.conn).send(line + #13#10);

    clean_cmdline(line);

    param := one_argument(line, cmdline);
    cmdline := uppercase(cmdline);

    // check for aliases first
    if (not ch.IS_NPC) then
      begin
      node := ch.player^.aliases.head;

      while (node <> nil) do
        begin
        al := node.element;

        if (uppercase(al.alias) = cmdline) then
          begin
          line := al.expand + ' ' + param;
          param := one_argument(line, cmdline);
          cmdline := uppercase(cmdline);

          break;
          end;

        node := node.next;
        end;
      end;

    cmd := nil;

    hash := commands.getHash(cmdline);
    node := commands.bucketList[hash].head;

    while (node <> nil) do
      begin
      if (pos(cmdline, GCommand(node.element).name) = 1) then
        begin
        cmd := GCommand(node.element);
        break;
        end;

      node := node.next;
      end;

    if (cmd <> nil) then
      begin
      a := ch.getTrust;

      if (a >= cmd.level) then
        begin
        if (cmd.position > position) then
          case position of
            POS_SLEEPING: ch.sendBuffer('You are off to dreamland.'#13#10);
            POS_MEDITATE: ch.sendBuffer('You must break out of your trance first.'#13#10);
             POS_RESTING: ch.sendBuffer('You feel too relaxed to do this.'#13#10);
             POS_SITTING: ch.sendBuffer('You must get on your feet first.'#13#10);
            POS_FIGHTING: ch.sendBuffer('You are fighting!'#13#10);
          end
        else
          begin
          if (system_info.log_all) or (IS_SET(ch.act_flags, ACT_LOG)) then
            write_log(ch.name^ + ': ' + line);

          if (cmd.level >= LEVEL_IMMORTAL) then
            write_console('[LOG] ' + ch.name^ + ': ' + cmd.name + ' (' + inttostr(cmd.level) + ')');

          try
            time := GetTickCount;

            cmd.ptr(ch, param);
            // ch.last_cmd := cmd.ptr;

            { Disabled this, this is too computer specific, e.g. on a 486
              some commands could lag while on a Pentium they would not.
              Uncomment if CPU leaks are to be traced. - Grimlord }

            time := GetTickCount - time;

            if (time > 1500) and (not ch.CHAR_DIED) then
              bugreport('interpret','mudthread.pas', cmd.func_name + ', ch ' + ch.name^ + ' lagged', 'The command took over 1.5 sec to complete.');
          except
            if (ch.CHAR_DIED) then
              bugreport('interpret', 'mudthread.pas', cmd.func_name + ', ch ' + ch.name^ + ' bugged',
                        'The specified command caused an error and has been terminated.');
          end;
          end;
        end
      else
        cmd := nil;
      end;

    if (cmd = nil) and (not checkSocial(ch, cmdline, param)) then
      begin
      a:=random(8);
      if a<1 then
        cmdline := 'Sorry, that command doesn''t exist in my vocabulaire!'
      else
      if a<2 then
        cmdline := 'I don''t understand you.'
      else
      if a<3 then
        cmdline := 'What are you saying?'
      else
      if a<4 then
        cmdline := 'Learn some english!'
      else
      if a<5 then
        cmdline := 'Hey, I don''t know that command. Try again.'
      else
      if a<6 then
        cmdline := 'What??'
      else
      if a<7 then
        cmdline := 'Huh?'
      else
      if a<8 then
        cmdline := 'Yeah, right!';

      act(AT_DGREEN, cmdline, false, ch, nil, nil, TO_CHAR);
      end;
  end;
end;

procedure nanny(conn : GConnection; argument : string);
var ch, vict : GCharacter;
    node : GListNode;
    race : GRace;
    digest : MD5Digest;
    h,top,x,temp:integer;
    buf, pwd : string;
begin
  ch := conn.ch;

  case conn.state of
        CON_NAME: begin
                  pwd := one_argument(argument, argument);
                  
                  if (length(argument) = 0) then
                    begin
                    conn.send('Please enter your name: ');
                    exit;
                    end;

                  if (uppercase(argument) = 'CREATE') then
                    begin
                    conn.send(#13#10'By what name do you wish to be known? ');
                    conn.state := CON_NEW_NAME;
                    exit;
                    end;

                  vict := findCharWorld(nil, argument);

                  if (vict <> nil) and (not vict.IS_NPC) and (vict.conn <> nil) then
                    begin
                    if (not MD5Match(MD5String(pwd), vict.player^.md5_password)) then
                      begin
                      conn.send(#13#10'You are already logged in under that name! Type your name and password on one line to break in.'#13#10);
                      closesocket(conn.socket);
                      conn.thread.Terminate;
                      end
                    else
                      begin
                      GConnection(vict.conn).thread.Terminate;

                      while (not IS_SET(vict.player^.flags, PLR_LINKLESS)) do;

                      vict.conn := conn;
                      conn.ch := vict;
                      ch := vict;
                      REMOVE_BIT(conn.ch.player^.flags,PLR_LINKLESS);
                      conn.state := CON_PLAYING;
                      conn.ch.sendPrompt;
                      end;

                    exit;
                    end;

                  if (not ch.load(argument)) then
                    begin
                    conn.send(#13#10'Are you sure about that name?'#13#10'Name: ');
                    exit;
                    end;

                  conn.state:=CON_PASSWORD;
                  conn.send('Password: ');
                  end;
    CON_PASSWORD: begin
                  if (length(argument) = 0) then
                    begin
                    conn.send('Password: ');
                    exit;
                    end;

                  if (not MD5Match(MD5String(argument), ch.player^.md5_password)) then
                    begin
                    write_console('(' + inttostr(conn.socket) + ') Failed password');
                    conn.send('Wrong password.'#13#10);
                    closesocket(conn.socket);
                    exit;
                    end;

                  vict := findCharWorld(nil, ch.name^);

                  if (vict <> nil) and (vict.conn = nil) then
                    begin
                    ch.Free;

                    conn.ch := vict;
                    ch := vict;
                    vict.conn := conn;

                    ch.player^.ld_timer := 0;

                    act(AT_REPORT, 'You have reconnected.', false, ch, nil, nil, TO_CHAR);
                    act(AT_REPORT, '$n has reconnected.', false, ch, nil, nil, TO_ROOM);
                    REMOVE_BIT(ch.player^.flags, PLR_LINKLESS);
                    write_console('(' + inttostr(conn.socket) + ') ' + ch.name^ + ' has reconnected');

                    ch.sendPrompt;
                    conn.state := CON_PLAYING;
                    exit;
                    end;

                  if (ch.IS_IMMORT) then
                    conn.send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                  else
                    conn.send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                  conn.send('Press Enter.'#13#10);
                  conn.state := CON_MOTD;
                  end;
        CON_MOTD: begin
                  conn.send(ch.ansiColor(6) + #13#10#13#10'Welcome, ' + ch.name^ + ', to this MUD. May your stay be pleasant.'#13#10);

                  with system_info do
                    begin
                    user_cur := connection_list.getSize;
                    if (user_cur > user_high) then
                      user_high := user_cur;
                    end;

                  ch.toRoom(ch.room);

                  act(AT_WHITE, '$n enters through a magic portal.', true, ch, nil, nil, TO_ROOM);
                  write_console('(' + inttostr(conn.socket) + ') '+ ch.name^ +' has logged in');

                  ch.node_world := char_list.insertLast(ch);
                  ch.player^.logon_now := Now;

                  if (ch.level = LEVEL_RULER) then
                    do_uptime(ch, '')
                  else
                    ch.sendPrompt;

                  conn.state := CON_PLAYING;
                  conn.fcommand := true;
                  end;
    CON_NEW_NAME: begin
                  if (length(argument) = 0) then
                    begin
                    conn.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  if (FileExists('players\' + argument + '.usr')) then
                    begin
                    conn.send('That name is already used.'#13#10);
                    conn.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  vict := findCharWorld(nil, argument);
                  (* if ((banned_names.indexof(uppercase(argument)) <> -1) or ((vict <> nil) and (uppercase(vict.name) = uppercase(argument)))) then
                    begin
                    send_to_conn(conn,'That name cannot be used.'#13#10);
                     send_to_conn(conn,'By what name do you wish to be known? ');
                    exit;
                    end; *)

                  if (length(argument) < 3) or (length(argument) > 15) then
                    begin
                    conn.send('Your name must be between 3 and 15 characters long.'#13#10);
                    conn.send('By what name do you wish to be known? ');
                    exit;
                    end;

                  ch.name := hash_string(cap(argument));
                  conn.state := CON_NEW_PASSWORD;
                  conn.send(#13#10'Allright, '+ch.name^+', choose a password: ');
                  end;
CON_NEW_PASSWORD: begin
                  if (length(argument)=0) then
                    begin
                    conn.send('Choose a password: ');
                    exit;
                    end;

                  new(ch.player);
                  ch.player^.md5_password := MD5String(argument);
                  conn.state := CON_CHECK_PASSWORD;
                  conn.send(#13#10'Please retype your password: ');
                  end;
CON_CHECK_PASSWORD: begin
                    if (length(argument) = 0) then
                      begin
                      conn.send('Please retype your password: ');
                      exit;
                      end;

                    if (not MD5Match(MD5String(argument), ch.player^.md5_password)) then
                      begin
                      conn.send(#13#10'Password did not match!'#13#10'Choose a password: ');
                      conn.state := CON_NEW_PASSWORD;
                      exit;
                      end
                    else
                      begin
                      conn.state := CON_NEW_SEX;
                      conn.send(#13#10'What sex do you wish to be (M/F/N): ');
                      exit;
                      end;
                    end;
     CON_NEW_SEX: begin
                  if (length(argument) = 0) then
                    begin
                    conn.send('Choose a sex (M/F/N): ');
                    exit;
                    end;

                  case upcase(argument[1]) of
                    'M':ch.sex:=0;
                    'F':ch.sex:=1;
                    'N':ch.sex:=2;
                  else
                    begin
                    conn.send('That is not a valid sex.'#13#10);
                    conn.send('Choose a sex (M/F/N): ');
                    exit;
                    end;
                  end;

                  conn.state:=CON_NEW_RACE;
                  conn.send(#13#10'Available races: '#13#10#13#10);

                  h:=1;
                  node := race_list.head;
                  while (node <> nil) do
                    begin
                    race := node.element;

                    buf := '  ['+inttostr(h)+']  '+pad_string(race.name,15);

                    if (race.def_alignment < 0) then
                      buf := buf + ANSIColor(12,0) + '<- EVIL'+ANSIColor(7,0);

                    buf := buf + #13#10;

                    conn.send(buf);

                    inc(h);
                    node := node.next;
                    end;

                  conn.send(#13#10'Choose a race: ');
                  end;
    CON_NEW_RACE: begin
                  if (length(argument)=0) then
                    begin
                    conn.send(#13#10'Choose a race: ');
                    exit;
                    end;

                  try
                    x:=strtoint(argument);
                  except
                    x:=-1;
                  end;

                  race := nil;
                  node := race_list.head;
                  h := 1;

                  while (node <> nil) do
                    begin
                    if (h = x) then
                      begin
                      race := node.element;
                      break;
                      end;

                    inc(h);
                    node := node.next;
                    end;

                  if (race = nil) then
                    begin
                    conn.send('Not a valid race.'#13#10);

                    h:=1;
                    node := race_list.head;
                    while (node <> nil) do
                      begin
                      race := node.element;

                      buf := '  ['+inttostr(h)+']  '+pad_string(race.name,15);

                      if (race.def_alignment < 0) then
                        buf := buf + ANSIColor(12,0) + '<- EVIL'+ANSIColor(7,0);

                      buf := buf + #13#10;

                      conn.send(buf);

                      inc(h);
                      node := node.next;
                      end;

                    conn.send(#13#10'Choose a race: ');
                    exit;
                    end;

                  ch.race:=race;
                  conn.send(race.description);
                  conn.send('250 stat points will be randomly distributed over your five attributes.'#13#10);
                  conn.send('It is impossible to get a lower or a higher total of stat points.'#13#10);

                  with ch.ability do
                    begin
                    top:=250;

                    str:=URange(25,random(UMax(top,75))+ch.race.str_bonus,75);
                    dec(top,str);

                    con:=URange(25,random(UMax(top,75))+ch.race.con_bonus,75);
                    dec(top,con);

                    dex:=URange(25,random(UMax(top,75))+ch.race.dex_bonus,75);
                    dec(top,dex);

                    int:=URange(25,random(UMax(top,75))+ch.race.int_bonus,75);
                    dec(top,int);

                    wis:=URange(25,random(UMax(top,75))+ch.race.wis_bonus,75);
                    dec(top,wis);

                    while (top>0) do
                      begin
                      x:=random(5);

                      case x of
                        0:begin
                          temp:=UMax(75-str,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            inc(str,temp);
                            end;
                          end;
                        1:begin
                          temp:=UMax(75-con,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            inc(con,temp);
                            end;
                          end;
                        2:begin
                          temp:=UMax(75-dex,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            inc(dex,temp);
                            end;
                          end;
                        3:begin
                          temp:=UMax(75-int,top);
                          if (temp>0) then
                            begin
                            dec(top,temp);
                            inc(int,temp);
                            end;
                          end;
                        4:begin
                          temp:=UMax(75-wis,top);
                          if (temp>0) then
                           begin
                            dec(top,temp);
                            inc(wis,temp);
                            end;
                          end;
                      end;
                    end;

                    top:=str+con+dex+int+wis;

                    // temporarily disabled this one - Grimlord [31/01/2000]
                    { if (top<250) then
                      bugreport('roll_char','total stats lower than 250')
                    else
                    if (top>250) then
                      bugreport('roll_char','total stats more than 250'); }

                    conn.send(#13#10'Your character statistics are: '#13#10#13#10);

                    buf := 'Strength:     '+ANSIColor(10,0)+inttostr(str)+ANSIColor(7,0)+#13#10 +
                           'Constitution: '+ANSIColor(10,0)+inttostr(con)+ANSIColor(7,0)+#13#10 +
                           'Dexterity:    '+ANSIColor(10,0)+inttostr(dex)+ANSIColor(7,0)+#13#10 +
                           'Intelligence: '+ANSIColor(10,0)+inttostr(int)+ANSIColor(7,0)+#13#10 +
                           'Wisdom:       '+ANSIColor(10,0)+inttostr(wis)+ANSIColor(7,0)+#13#10;
                    conn.send(buf);
                    end;

                  conn.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                  conn.state:=CON_NEW_STATS;
                  end;
   CON_NEW_STATS: begin
                  if (length(argument) =0) then
                    begin
                    conn.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                    exit;
                    end;

                  case (upcase(argument[1])) of
                    'C':begin
                        digest := ch.player^.md5_password;

                        ch.load(ch.name^);
                        ch.player^.md5_password := digest;
                        ch.save(ch.name^);

                        conn.send(#13#10'Thank you. You have completed your entry.'#13#10);

                        conn.send(ch.ansiColor(2) + #13#10);

                        if (ch.IS_IMMORT) then
                          conn.send(ch.ansiColor(2) + #13#10 + findHelp('IMOTD').text)
                        else
                          conn.send(ch.ansiColor(2) + #13#10 + findHelp('MOTD').text);

                        conn.send('Press Enter.'#13#10);
                        conn.state:=CON_MOTD;
                        end;
                    'R':begin
                        with ch.ability do
                          begin
                          top:=250;

                          str:=URange(25,random(UMax(top,75))+ch.race.str_bonus,75);
                          dec(top,str);

                          con:=URange(25,random(UMax(top,75))+ch.race.con_bonus,75);
                          dec(top,con);

                          dex:=URange(25,random(UMax(top,75))+ch.race.dex_bonus,75);
                          dec(top,dex);

                          int:=URange(25,random(UMax(top,75))+ch.race.int_bonus,75);
                          dec(top,int);

                          wis:=URange(25,random(UMax(top,75))+ch.race.wis_bonus,75);
                          dec(top,wis);

                          while (top>0) do
                            begin
                            x:=random(5);

                            case x of
                              0:begin
                                temp:=UMax(75-str,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  inc(str,temp);
                                  end;
                                end;
                              1:begin
                                temp:=UMax(75-con,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  inc(con,temp);
                                  end;
                                end;
                              2:begin
                                temp:=UMax(75-dex,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  inc(dex,temp);
                                  end;
                                end;
                              3:begin
                                temp:=UMax(75-int,top);
                                if (temp>0) then
                                  begin
                                  dec(top,temp);
                                  inc(int,temp);
                                  end;
                                end;
                              4:begin
                                temp:=UMax(75-wis,top);
                                if (temp>0) then
                                 begin
                                  dec(top,temp);
                                  inc(wis,temp);
                                  end;
                                end;
                            end;
                          end;

                          top:=str+con+dex+int+wis;

                          // temporarily disabled this one - Grimlord [31/01/2000]
                          { if (top<250) then
                            bugreport('roll_char','total stats lower than 250')
                          else
                          if (top>250) then
                            bugreport('roll_char','total stats more than 250'); }

                          conn.send(#13#10'Your character statistics are: '#13#10#13#10);

                          buf := 'Strength:     '+ANSIColor(10,0)+inttostr(str)+ANSIColor(7,0)+#13#10 +
                                 'Constitution: '+ANSIColor(10,0)+inttostr(con)+ANSIColor(7,0)+#13#10 +
                                 'Dexterity:    '+ANSIColor(10,0)+inttostr(dex)+ANSIColor(7,0)+#13#10 +
                                 'Intelligence: '+ANSIColor(10,0)+inttostr(int)+ANSIColor(7,0)+#13#10 +
                                 'Wisdom:       '+ANSIColor(10,0)+inttostr(wis)+ANSIColor(7,0)+#13#10;
                          conn.send(buf);
                          end;

                        conn.send(#13#10'Do you wish to (C)ontinue, (R)eroll or (S)tart over? ');
                        end;
                    'S':begin
                        conn.send(#13#10'Very well, restarting.'#13#10);
                        conn.send('By what name do you wish to be known?');
                        conn.state:=CON_NEW_NAME;
                        end;
                  else
                    conn.send('Do you wish to (C)ontinue, (R)eroll or (S)art over? ');
                    exit;
                 end;
                 end;
    else
      bugreport('nanny', 'mudthread.pas', 'illegal state ' + inttostr(conn.state),
                'The specified connection state is unknown. Someone may be hacking.');
  end;
end;

procedure GThread.Execute;
var conn : GConnection;
    cmdline : string;
    temp_buf : string;
    ch : GCharacter;
    i : integer;

label nameinput,stopthread;
begin
  freeonterminate := true;

  conn := GConnection.Create(socket, client_addr, Self);

  write_console('(' + inttostr(socket) + ') New connection (' + conn.ip_string + ')');

  if (isMaskBanned(conn.host_string)) then
    begin
    write_console('('+inttostr(socket)+') Closed banned IP ('+conn.host_string+')');

    conn.send(system_info.mud_name+#13#10#13#10);
    conn.send('Your site has been banned from this server.'#13#10);
    conn.send('For more information, please mail the administration, '+system_info.admin_email+'.'#13#10);
    closesocket(socket);
    conn.Free;
    exit;
    end;

  ch := GCharacter.Create;
  conn.ch := ch;
  ch.conn := conn;

  if (not copyover) then
    begin
    conn.state := CON_NAME;

    conn.send(AnsiColor(2,0) + findHelp('M_DESCRIPTION_').text);

    temp_buf := AnsiColor(6,0) + #13#10;

    temp_buf := temp_buf + version_info + ', ' + version_number + '.'#13#10;
    temp_buf := temp_buf + version_copyright + '.';
    temp_buf := temp_buf + #13#10'This is free software, with ABSOLUTELY NO WARRANTY; view LICENSE.TXT.';
    temp_buf := temp_buf + AnsiColor(7,0) + #13#10;

    conn.send(temp_buf);

    conn.send(#13#10#13#10'Enter your name or CREATE to create a new character.'#13#10'Please enter your name: ');
    end
  else
    begin
    conn.state := CON_MOTD;

    conn.ch.name := hash_string(copyover_name);
    conn.ch.load(copyover_name);
    conn.send(#13#10#13#10'Gradually, the clouds form real images again, recreating the world...'#13#10);
    conn.send('Copyover complete!'#13#10);

    nanny(conn, '');
    end;

  repeat
    if (conn.fcommand) then
      begin
      if (conn.pagepoint <> 0) then
        conn.outputPager
      else
        conn.ch.emptyBuffer;
      end;

    conn.fcommand:=false;
    sleep(100);

    conn.checkReceive;

    if (not Terminated) then
      conn.read;

    if (not Terminated) and (conn.ch.wait > 0) then
      continue;

    if (not Terminated) then
      conn.readBuffer;

    if (length(conn.comm_buf) > 0) then
      begin
      cmdline := trim(conn.comm_buf);

      i := pos(#13, cmdline);
      if (i <> 0) then
        delete(cmdline, i, 1);

      i := pos(#10, cmdline);
      if (i <> 0) then
        delete(cmdline, i, 1);

      conn.comm_buf := '';
      conn.fcommand := true;

      if (conn.pagepoint <> 0) then
        conn.setPagerInput(cmdline)
      else
        case conn.state of
          CON_PLAYING: begin
                       if (not conn.ch.IS_NPC) and (IS_SET(conn.ch.player^.flags,PLR_FROZEN)) and (cmdline <> 'quit') then
                         begin
                         conn.ch.sendBuffer('You have been frozen by the gods and cannot do anything.'#13#10);
                         conn.ch.sendBuffer('To be unfrozen, send an e-mail to the administration, '+system_info.admin_email+'.'#13#10);
                         continue;
                         end;

                       conn.ch.in_command:=true;
                       interpret(conn.ch, cmdline);

                       if (not conn.ch.CHAR_DIED) then
                         conn.ch.in_command := false;
                       end;
          // CON_EDITING: edit_buffer(conn.ch,cmdline);
          else
            nanny(conn, cmdline);
        end;
      end;
  until Terminated;

  if (not conn.ch.CHAR_DIED) and ((conn.state=CON_PLAYING) or (conn.state=CON_EDITING)) then
    begin
    write_console('(' + inttostr(conn.socket) + ') '+conn.ch.name^+' has lost the link');

    conn.ch.conn := nil;

    act(AT_REPORT,'$n has lost $s link.',false,conn.ch,nil,nil,TO_ROOM);
    SET_BIT(conn.ch.player^.flags,PLR_LINKLESS);
    end
  else
  if (conn.state = CON_LOGGED_OUT) then
    dec(system_info.user_cur)
  else
    begin
    write_console('('+inttostr(conn.socket)+') Connection reset by peer');
    conn.ch.Free;
    end;

  closesocket(socket);

  conn.Free;
end;

end.

