unit progs;

interface

uses
    chars,
    fsys,
    dtypes,
    area;

const MAX_IFCHECKS=20;
      IN_IF=0;
      IN_ELSE=1;
      DO_IF=2;
      DO_ELSE=3;

const COMMANDOK=0;
      IFTRUE=1;
      IFFALSE=2;
      ORTRUE=3;
      ORFALSE=4;
      FOUNDELSE=5;
      FOUNDENDIF=6;
      IFIGNORED=7;
      ORIGNORED=8;
      BERR=9;

type
    GProgram = class
      prog_type, perc : integer;
      code : string;
      args : string;
      return : boolean;

      procedure load(var fp : GFileReader; trigger : string; npc : GNPCIndex);
      function seval(lhs, opr, rhs : string; npc : GCharacter) : boolean;
      function veval(lhs : integer; opr : string; rhs : integer; npc : GCharacter) : boolean;
      function ifcheck(ifcheck : string; npc, actor : GCharacter; obj : GObject; vo : pointer; rand : GCharacter) : integer;
      function command(cmd : string; npc,actor : GCharacter; obj : GObject; ignore, ignore_ors : boolean) : integer;
      procedure driver(npc, actor : GCharacter; obj : GObject);
    end;

procedure percentCheck(npc, actor : GCharacter; obj : GObject; prog_type : integer);
procedure greetTrigger(ch : GCharacter);
procedure fightTrigger(ch, victim : GCharacter);
procedure randTrigger(ch : GCharacter);
procedure deathTrigger(ch, victim : GCharacter);
procedure resetTrigger(ch : GCharacter);
procedure actTrigger(npc, actor : GCharacter; s : string);
function blockTrigger(ch, victim : GCharacter; vnum : integer) : boolean;

implementation

uses
    SysUtils,
    strip,
    util,
    mudsystem,
    mudthread,
    constants;


procedure GProgram.load(var fp : GFileReader; trigger : string; npc : GNPCIndex);
var
   g : string;
begin
  g := striprbeg(uppercase(trigger),' ');
  args := striprbeg(g,' ');

  g:=stripl(g,' ');
  perc := strtointdef(args, 0);

  if (g = 'ON_ACT') then
    begin
    prog_type := MPROG_ACT;
    SET_BIT(npc.mpflags, MPROG_ACT);
    end
  else
  if (g = 'ON_GREET') then
    begin
    prog_type := MPROG_GREET;
    SET_BIT(npc.mpflags, MPROG_GREET);
    end
  else
  if (g = 'ON_ALLGREET') then
    begin
    prog_type := MPROG_ALLGREET;
    SET_BIT(npc.mpflags, MPROG_ALLGREET);
    end
  else
  if g='ON_ENTER' then
    begin
    prog_type := MPROG_ENTER;
    SET_BIT(npc.mpflags, MPROG_ENTER);
    end
  else
  if g='ON_DEATH' then
    begin
    prog_type:=MPROG_DEATH;
    SET_BIT(npc.mpflags,MPROG_DEATH);
    end
  else
  if g='ON_BRIBE' then
    begin
    prog_type:=MPROG_BRIBE;
    SET_BIT(npc.mpflags,MPROG_BRIBE);
    end
  else
  if g='ON_FIGHT' then
    begin
    prog_type:=MPROG_FIGHT;
    SET_BIT(npc.mpflags,MPROG_FIGHT);
    end
  else
  if g='ON_RAND' then
    begin
    prog_type:=MPROG_RAND;
    SET_BIT(npc.mpflags,MPROG_RAND);
    end
  else
  if g='ON_BLOCK' then
    begin
    prog_type:=MPROG_BLOCK;
    SET_BIT(npc.mpflags,MPROG_BLOCK);
    end
  else
  if g='ON_RESET' then
    begin
    prog_type:=MPROG_RESET;
    SET_BIT(npc.mpflags,MPROG_RESET);
    end
  else
    bugreport('GProgram.load', 'progs.pas', 'illegal trigger type', '');

  code := '';

  repeat
    g := fp.readLine;

    if (g <> '~') then
      code := code + g + #13#10;
  until (g = '~');

  npc.programs.insertLast(Self);
end;

function parseCode(prog : string; npc, actor : GCharacter; obj : GObject) : string;
var c : char;
    prog_c, buf_c : integer;
    dest : string;
begin
  prog_c := 1;
  dest := '';
  Result := '';

  while (prog_c <= length(prog)) do
    begin
    c := prog[prog_c];

    if (c = '$') then
      begin
      inc(prog_c);

      case prog[prog_c] of
          'i' : dest := dest + npc.name^;
          'n' : dest := dest + actor.name^;
         else
           bugreport('parseCode', 'progs.pas', 'unknown format ' + prog[prog_c],
                     'Bad format code in this mobprog. Please check your settings.');
      end;
      end
    else
      dest := dest + c;

    inc(prog_c);
    end;

  Result := dest;
end;

{ much of the code has been taken from the mudprogs in Smaug 1.02 }
{ adapted quite a lot and removed even more, which I don't need or }
{ which is not for Grendel - Grimlord. }

function GProgram.seval(lhs, opr, rhs : string; npc : GCharacter) : boolean;
begin
  Result := false;

  if (opr = '==') then
    Result := (lhs = rhs)
  else
  if (opr='!=') then
    Result := (lhs <> rhs)
  else
    bugreport('GProgram.seval', 'progs.pas', 'invalid operator ' + opr,
              'An invalid operator was found in this mobprog. Please check your settings.');
  exit;
end;

function GProgram.veval(lhs : integer; opr : string; rhs : integer; npc : GCharacter) : boolean;
begin
  Result := false;

  if (opr='==') then
    Result := (lhs = rhs)
  else
  if (opr='!=') then
    Result := (lhs <> rhs)
  else
  if (opr='>') then
    Result := (lhs > rhs)
  else
  if (opr='<') then
    Result := (lhs < rhs)
  else
  if (opr='>=') then
    Result := (lhs >= rhs)
  else
  if (opr='<=') then
    Result := (lhs <= rhs)
  else
  if (opr='&') then
    Result := (lhs and rhs) = rhs
  else
  if (opr='|') then
    Result := (lhs or rhs) = rhs
  else
    bugreport('GProgram.veval', 'progs.pas', 'invalid operator ' + opr,
              'An invalid operator was found in this mobprog. Please check your settings.');
  exit;
end;

function GProgram.ifcheck(ifcheck : string; npc, actor : GCharacter; obj : GObject; vo : pointer; rand : GCharacter) : integer;
var cvar,chck,opr,rval : string;
    chkchar : GCharacter;
    chkobj : GObject;
    lhsvl,rhsvl:integer;
begin
  ifcheck := trim(ifcheck);

  if (length(ifcheck) = 0) then
    begin
    bugreport('GProgram.ifcheck', 'mobprogs.pas', 'null ifcheck, ' + npc.name^,
              'This ifcheck does not have any parameters.');

    Result := BERR;
    exit;
    end;

  chkchar := nil;
  chkobj := nil;

  if (pos('(', ifcheck) > 0) then
    begin
    chck := stripl(ifcheck, '(');
    ifcheck := striprbeg(ifcheck, '(');
    end
  else
    begin
    bugreport('GProgram.ifcheck', 'mobprogs.pas', 'syntax error, ' + npc.name^,
              'Encountered a syntax error in this mobprog. Please check your settings.');
    Result := BERR;
    exit;
    end;


  if (pos(')', ifcheck) > 0) then
    begin
    cvar := stripl(ifcheck, ')');
    ifcheck := striprbeg(ifcheck, ')');
    end
  else
    begin
    bugreport('GProgram.ifcheck', 'mobprogs.pas', 'syntax error, ' + npc.name^,
              'Encountered a syntax error in this mobprog. Please check your settings.');

    Result := BERR;
    exit;
    end;

  ifcheck := trim(ifcheck);

  if (length(ifcheck) = 0) then
    begin
    opr := '';
    rval := '';
    end
  else
    begin
    if (pos(' ', ifcheck) > 0) then
      begin
      opr := stripl(ifcheck, ' ');
      ifcheck := striprbeg(ifcheck, ' ');
      end
    else
      begin
      bugreport('GProgram.ifcheck', 'mobprogs.pas', 'operator without value, ' + npc.name^,
                'Encountered a syntax error in this mobprog. Please check your settings.');
      Result := BERR;
      exit;
      end;

    rval := ifcheck;
    end;

  if (pos('$', cvar) > 0) then
    begin
    case cvar[2] of
      'i':chkchar:=npc;
      'n':chkchar:=actor;
      't':chkchar:=GCharacter(vo);
      'r':chkchar:=rand;
      'o':chkobj:=obj;
      'p':chkobj:=GObject(vo);
    else
      begin
        bugreport('GProgram.ifcheck', 'mobprogs.pas', 'bad argument, ' + npc.name^,
                  'Encountered a syntax error in this mobprog. Please check your settings.');
      Result := BERR;
      exit;
      end;
    end;
    if ((chkchar=nil) and (chkobj=nil)) then
      begin
      Result := BERR;
      exit;
      end;
  end;

  if (chck='rand') then
    begin
    Result := integer(number_percent <= strtoint(cvar));
    exit;
    end;

  if (chkchar<>nil) then
    begin
    if (chck='isimmort') then
      begin
      Result := integer(chkchar.IS_IMMORT);
      exit;
      end
    else
    if (chck='isevil') then
      begin
      Result := integer(chkchar.IS_EVIL);
      exit;
      end
    else
    if (chck='isgood') then
      begin
      Result := integer(chkchar.IS_GOOD);
      exit;
      end
    else
    if (chck='isinvis') then
      begin
      Result := integer(chkchar.IS_INVIS);
      exit;
      end
    else
    if (chck='isnpc') then
      begin
      Result := integer(chkchar.IS_NPC);
      exit;
      end
    else
    if (chck='ispc') then
      begin
      Result := integer(not chkchar.IS_NPC);
      exit;
      end
    else
    if (chck='race') then
      begin
      Result := integer(seval(chkchar.race.name,opr,rval,npc));
      exit;
      end;
    end;

  bugreport('GProgram.ifcheck', 'mobprogs.pas', 'illegal ifcheck, '+npc.name^,
            'An unknown ifcheck was found in this mobprog.');
  Result := BERR;
end;

function GProgram.command(cmd : string; npc,actor : GCharacter; obj : GObject;
                       ignore, ignore_ors : boolean) : integer;
var
    firstword, rest : string;
    tmp : string;
    validif : integer;
begin
  cmd := trim(cmd);

  firstword := stripl(cmd, ' ');
  rest := striprbeg(cmd, ' ');

  if (firstword = 'if') then
    begin
    if (ignore) then
      begin
      Result := IFIGNORED;
      exit;
      end
    else
      validif := ifcheck(rest, npc, actor, obj, nil, nil);

    if (validif = 1) then
      Result := IFTRUE
    else
    if (validif = 0) then
      Result := IFFALSE
    else
      Result := BERR;
    exit;
    end;

  if (firstword = 'or') then
    begin
    if (ignore_ors) then
      begin
      Result := ORIGNORED;
      exit;
      end;

    Result := BERR;
    exit;
    end;

  if (firstword = 'else') then
    begin
    Result := FOUNDELSE;
    exit;
    end;

  if (firstword ='endif') then
    begin
    Result := FOUNDENDIF;
    exit;
    end;

  if (ignore) then
    begin
    Result := COMMANDOK;
    exit;
    end;

  if (cmd = 'mpreturntrue') then
    return := true
  else
  if (cmd = 'mpreturnfalse') then
    return := false
  else
  if (cmd = 'aggrogood') then
    npc.hunting := npc.room.findRandomGood
  else
  if (cmd = 'aggroevil') then
    npc.hunting := npc.room.findRandomEvil
  else
    interpret(npc, parseCode(cmd, npc, actor, obj));

  Result := COMMANDOK;
end;

procedure GProgram.driver(npc, actor : GCharacter; obj : GObject);
var cmd, line : string;
    ifstate:array[0..MAX_IFCHECKS-1,IN_IF..DO_ELSE] of boolean;
    i, iflevel, presult, ignorelevel : integer;
    s : integer;
begin
  for iflevel:=0 to MAX_IFCHECKS-1 do
   for i:=IN_IF to DO_ELSE do
    ifstate[iflevel,i]:=false;

  return := false;
  iflevel := 0;
  ignorelevel := 0;
  cmd := code;

  repeat
    s := pos(#13#10, cmd);

    if (s > 0) then
      begin
      line := copy(cmd, 1, s - 1);
      cmd := copy(cmd, s + 2, length(cmd) - s - 2 + 1);

      presult := command(line, npc, actor, obj,
              (ifstate[iflevel,IN_IF] and (not ifstate[iflevel,DO_IF]))
              or (ifstate[iflevel,IN_ELSE] and (not ifstate[iflevel,DO_ELSE])),
              ignorelevel > 0);

      case presult of
        { command is okay, do nothing }
        COMMANDOK:;
        { encountered an ifcheck which returned true }
           IFTRUE:begin
                  inc(iflevel);
                  if iflevel>=MAX_IFCHECKS then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'max number of ifs, ' + npc.name^,
                              'The maximum number of ifchecks was reached.');
                    exit;
                    end;
                  ifstate[iflevel,IN_IF]:=true;
                  ifstate[iflevel,DO_IF]:=true;
                  end;
        { encountered an ifcheck which returned false }
          IFFALSE:begin
                  inc(iflevel);
                  if iflevel>=MAX_IFCHECKS then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'max number of ifs, ' + npc.name^,
                              'The maximum number of ifchecks was reached.');
                    exit;
                    end;
                  ifstate[iflevel,IN_IF]:=true;
                  ifstate[iflevel,DO_IF]:=false;
                  end;
        { encountered an or check which returned true }
           ORTRUE:begin
                  if not (ifstate[iflevel,IN_IF]) then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'unmatched or - ' + npc.name^,
                              'Syntax error in this mobprog.');
                    exit;
                    end;
                  ifstate[iflevel,DO_IF]:=true;
                  end;
        { encountered an or check which returned false }
          ORFALSE:begin
                  if not (ifstate[iflevel,IN_IF]) then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'unmatched or - ' + npc.name^,
                              'Syntax error in this mobprog.');
                    exit;
                    end;
                  end;
        { encountered an else block }
        FOUNDELSE:begin
                  if (ignorelevel>0) then
                    break;
                  if (ifstate[iflevel,IN_ELSE]) then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'else in else block - ' + npc.name^,
                              'Syntax error in this mobprog.');
                    exit;
                    end;
                  if not (ifstate[iflevel,IN_IF]) then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'unmatched else - ' + npc.name^,
                              'Syntax error in this mobprog.');
                    exit;
                    end;
                  ifstate[iflevel,IN_ELSE]:=true;
                  ifstate[iflevel,DO_ELSE]:=not ifstate[iflevel,DO_IF];
                  ifstate[iflevel,IN_IF]:=false;
                  ifstate[iflevel,DO_IF]:=false;
                  end;
        { encountered an endif block }
       FOUNDENDIF:begin
                  if not (ifstate[iflevel,IN_IF] or ifstate[iflevel,IN_ELSE]) then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'unmatched endif - ' + npc.name^,
                              'Syntax error in this mobprog.');
                    exit;
                    end;
                  if (ignorelevel>0) then
                    begin
                    dec(ignorelevel);
                    break;
                    end;
                  ifstate[iflevel,IN_IF]:=false;
                  ifstate[iflevel,DO_IF]:=false;
                  ifstate[iflevel,IN_ELSE]:=false;
                  ifstate[iflevel,DO_ELSE]:=false;
                  dec(iflevel);
                  end;
        { this if block should be ignored }
        IFIGNORED:begin
                  if not (ifstate[iflevel,IN_IF] or ifstate[iflevel,IN_ELSE]) then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'ignoring non-if non-else block - ' + npc.name^,
                              'Syntax error in this mobprog.');
                    exit;
                    end;
                  inc(ignorelevel);
                  end;
        { this or block should be ignored }
        ORIGNORED:begin
                  if not (ifstate[iflevel,IN_IF] or ifstate[iflevel,IN_ELSE]) then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'unmatched or - ' + npc.name^,
                              'Syntax error in this mobprog.');
                    exit;
                    end;
                  if (ignorelevel=0) then
                    begin
                    bugreport('mprog_driver', 'mobprogs.pas', 'ignoring or falsely - ' + npc.name^,
                              'Syntax error in this mobprog.');
                    exit;
                    end;
                  end;
        { other error while executing }
             BERR:begin
                  bugreport('mprog_driver', 'mobprogs.pas', 'unknown error - ' + npc.name^,
                              'Syntax error in this mobprog.');
                  exit;
                  end;
      end;
      end
    else
    if (ifstate[iflevel,IN_IF]) or (ifstate[iflevel,IN_ELSE]) then
      begin
      bugreport('mprog_driver', 'mobprogs.pas', 'missing endif ' + npc.name^,
                'The ifcheck was not ended properly.');
      exit;
      end;
  until (s = 0);
end;

procedure percentCheck(npc, actor : GCharacter; obj : GObject; prog_type : integer);
var
   prg : GProgram;
   node : GListNode;
begin
  node := npc.npc_index.programs.head;

  while (node <> nil) do
    begin
    prg := node.element;

    if (prg.prog_type = prog_type) then
      begin
      if (number_percent <= prg.perc) then
        begin
        prg.driver(npc, actor, obj);

        if (prog_type <> MPROG_GREET) then
          break;
        end;
      end;

    node := node.next;
    end;
end;

procedure greetTrigger(ch : GCharacter);
var
   vmob : GCharacter;
   node : GListNode;
begin
  if (ch.IS_NPC) then
    exit;

  ch.in_command := false;

  node := ch.room.chars.head;
  while (node <> nil) do
    begin
    vmob := node.element;

    vmob.emptyBuffer;

    node := node.next;
    end;

  node := ch.room.chars.head;
  while (node <> nil) do
    begin
    vmob := node.element;

    if (not vmob.IS_NPC) or (vmob.fighting <> nil) or
     (not vmob.IS_AWAKE) or (not vmob.CAN_SEE(ch)) then
       begin
       node := node.next;
       continue;
       end;

    if (IS_SET(vmob.npc_index.mpflags, MPROG_GREET)) then
      percentCheck(vmob, ch, nil, MPROG_GREET);

    if IS_SET(vmob.act_flags,ACT_AGGRESSIVE) then
      interpret(vmob, 'growl ' + ch.name^);

    node := node.next;
    end;
end;

procedure fightTrigger(ch, victim : GCharacter);
begin
  if (not ch.IS_NPC) then
    exit;

  if (IS_SET(ch.npc_index.mpflags, MPROG_FIGHT)) then
    percentCheck(ch, victim, nil, MPROG_FIGHT);
end;

procedure randTrigger(ch : GCharacter);
var
   vict : GCharacter;
begin
  if (not ch.IS_NPC) or (ch.fighting <> nil) then
    exit;

  if (IS_SET(ch.npc_index.mpflags, MPROG_RAND)) then
    begin
    vict := ch.room.findRandomChar;

    if (vict <> nil) then
      percentCheck(ch, vict, nil, MPROG_RAND);
    end;
end;

procedure actTrigger(npc, actor : GCharacter; s : string);
var
   prg : GProgram;
   node : GListNode;
begin
  if (not npc.IS_NPC) or (npc.fighting <> nil) then
    exit;

  s := uppercase(s);

  node := npc.npc_index.programs.head;

  while (node <> nil) do
    begin
    prg := node.element;

    if (prg.prog_type = MPROG_ACT) then
      begin
      if (pos(prg.args, s) > 0) then
        prg.driver(npc, actor, nil);
      end;

    node := node.next;
    end;
end;

function blockTrigger(ch, victim : GCharacter; vnum : integer) : boolean;
var
   prg : GProgram;
   node : GListNode;
begin
  Result := false;

  if (not ch.IS_NPC) then
    exit;

  node := ch.npc_index.programs.head;

  while (node <> nil) do
    begin
    prg := node.element;

    if (prg.prog_type = MPROG_BLOCK) then
      begin
      if (strtoint(prg.args) = vnum) then
        begin
        prg.driver(ch, victim, nil);

        Result := prg.return;
        end;
      end;

    node := node.next;
    end;
end;

procedure deathTrigger(ch, victim : GCharacter);
begin
  if (not ch.IS_NPC) then
    exit;

  if (IS_SET(ch.npc_index.mpflags, MPROG_DEATH)) then
    percentCheck(ch, victim, nil, MPROG_DEATH);
end;

procedure resetTrigger(ch : GCharacter);
begin
  if (not ch.IS_NPC) then
    exit;

  if (IS_SET(ch.npc_index.mpflags, MPROG_RESET)) then
    percentCheck(ch, nil, nil, MPROG_RESET);
end;

begin
end.
