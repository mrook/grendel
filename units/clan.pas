unit clan;

interface

uses
    dtypes;

type
    GClan = class
       name : string;
       leader : string;
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

implementation

uses
    SysUtils,
    strip,
    mudsystem;

constructor GClan.Create;
begin
  inherited Create;

  minlevel := 50;
  clanvnum := 0;
  clanobj := 0;
  leader := '';
  name := 'Untitled Clan';
end;

procedure GClan.load(fname : string);
var cf : textfile;
    d,r:string;
begin
  assignfile(cf,'clans\'+fname);
  {$I-}
  reset(cf);
  {$I+}

  if (IOResult <> 0) then
    begin
    bugreport('GClan.load', 'clan.pas', 'could not open clans\' + fname,
              'Could not open the specified clan file.');
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
      write_console('   '+name);
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
        bugreport('load_clan', 'area.pas', 'illegal character in MINLEVEL parameter',
                  'The string was not a valid numeric value.');
      end
    else
    if r='CLANOBJ' then
      try
        clanobj := strtoint(right(d,' '))
      except
        clanobj:=0;
        bugreport('load_clan', 'area.pas', 'illegal character in CLANOBJ parameter',
                  'The string was not a valid numeric value.');
      end
    else
    if r='CLANVNUM' then
      try
        clanvnum:=strtoint(right(d,' '));
      except
        clanvnum:=0;
        bugreport('load_clan', 'area.pas', 'illegal character in CLANVNUM parameter',
                  'The string was not a valid numeric value.');
      end;
  until uppercase(d)='#END';

  close(cf);
end;

procedure load_clans;
var clan : GClan;
    s:string;
    f:textfile;
begin
  assign(f,'clans\clan.list');
  {$I-}
  reset(f);
  {$I+}
  if IOResult<>0 then
    begin
    bugreport('load_clans', 'area.pas', 'could not open clans\clan.list',
              'The specified clan list could not be found.');
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

begin
  clan_list := GDLinkedList.Create;
end.
