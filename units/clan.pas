{
  @abstract(Clan routines)
  @lastmod($Id: clan.pas,v 1.10 2002/08/03 19:17:47 ***REMOVED*** Exp $)
}

unit clan;

interface

uses
    fsys,
    dtypes;

type
    GClan = class
       name : string;          { clan name }
       abbrev : string;        { abbreviation of clan name, 3-4 chars }
       leader : string;        { leader of clan }
       minlevel : integer;     { Minimum level to join }
       clanobj : integer;      { VNum of clan obj (e.g. a ring) }
       clanvnum : integer;     { Clan area starting VNum }

       procedure load(fname : string);

       constructor Create;
    end;

var
   clan_list : GDLinkedList;

procedure load_clans;

function findClan(s : string) : GClan;

procedure initClans();
procedure cleanupClans();

implementation

uses
    SysUtils,
    Strip,
    console,
    mudsystem;

constructor GClan.Create;
begin
  inherited Create;

  minlevel := 50;
  clanvnum := 0;
  clanobj := 0;
  leader := '';
  name := 'Untitled Clan';
  abbrev := '';
end;

procedure GClan.load(fname : string);
var 
  cf : textfile;
  d, r : string;
  i : integer;
begin
  assignfile(cf, translateFileName('clans\'+fname));
  {$I-}
  reset(cf);
  {$I+}

  if (IOResult <> 0) then
    begin
    bugreport('GClan.load', 'clan.pas', 'could not open clans\' + fname);
    exit;
    end;

  repeat
    readln(cf,d);
  until uppercase(d)='#CLAN';

  repeat
    readln(cf,d);

    r:=uppercase(left(d,':'));

    if r='NAME' then
      begin
      name := right(d,' ');
      writeConsole('   '+name);
      end
    else
    if r='LEADER' then
      leader := right(d,' ')
    else
    if r='MINLEVEL' then
      try
        minlevel := strtointdef(right(d,' '), 0)
      except
        minlevel:=0;
        bugreport('load_clan', 'area.pas', 'illegal character in MINLEVEL parameter');
      end
    else
    if r='CLANOBJ' then
      try
        clanobj := strtoint(right(d,' '))
      except
        clanobj:=0;
        bugreport('load_clan', 'area.pas', 'illegal character in CLANOBJ parameter');
      end
    else
    if r='CLANVNUM' then
      try
        clanvnum:=strtoint(right(d,' '));
      except
        clanvnum:=0;
        bugreport('load_clan', 'area.pas', 'illegal character in CLANVNUM parameter');
      end
    else
    if (r = 'ABBREV') then
      abbrev := right(d, ' ');
  until uppercase(d)='#END';
  
  // simple heuristics to convert a clan name to an abbreviation when none is specified
  if (abbrev = '') then
    begin
    for i := 1 to length(name) do
      if (name[i] in ['A'..'Z']) then
        abbrev := abbrev + name[i];
        
    if (length(abbrev) > 3) then
      abbrev := copy(abbrev, 1, 3);
    end;

  close(cf);
end;

procedure load_clans;
var clan : GClan;
    s:string;
    f:textfile;
begin
  assign(f, translateFileName('clans\clan.list'));
  {$I-}
  reset(f);
  {$I+}
  if IOResult<>0 then
    begin
    bugreport('load_clans', 'area.pas', 'could not open clans\clan.list');
    exit;
    end;
  repeat
    readln(f,s);

    if (s <> '$') then
      begin
      clan := GClan.Create;

      clan.load(s);

      clan_list.insertLast(clan);
      end;
  until s='$';

  close(f);
end;

function findClan(s : string) : GClan;
var
   node : GListNode;
   clan : GClan;
begin
  findClan := nil;
  node := clan_list.head;

  while (node <> nil) do
    begin
    clan := node.element;

    if (s = clan.name) then
      begin
      findClan := clan;
      exit;
      end;

    node := node.next;
    end;
end;

procedure initClans();
begin
  clan_list := GDLinkedList.Create;
end;

procedure cleanupClans();
begin
  clan_list.clean();
  clan_list.Free();
end;


end.
