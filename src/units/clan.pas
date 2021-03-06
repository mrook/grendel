{
  Summary:
  	Clan routines
  
  ##	$Id: clan.pas,v 1.4 2004/04/10 22:24:03 ***REMOVED*** Exp $
}

unit clan;

interface

uses
	dtypes;

type
	GClan = class
	private
		_name : string;          { clan name }
		_abbrev : string;        { abbreviation of clan name, 3-4 chars }
		_leader : string;        { leader of clan }
		_minlevel : integer;     { Minimum level to join }
		_clanobj : integer;      { VNum of clan obj (e.g. a ring) }
		_clanvnum : integer;     { Clan area starting VNum }

	public
		constructor Create();

		procedure load(const fname : string);
		
		property name : string read _name write _name;
		property abbrev : string read _abbrev write _abbrev;
		property leader : string read _leader write _leader;
		property minlevel : integer read _minlevel write _minlevel;
		property clanobj : integer read _clanobj write _clanobj;
		property clanvnum : integer read _clanvnum write _clanvnum;
	end;

var
   clan_list : GDLinkedList;

procedure load_clans();

function findClan(const s : string) : GClan;

procedure initClans();
procedure cleanupClans();

implementation

uses
    SysUtils,
	fsys,
    strip,
    console,
    mudsystem;

constructor GClan.Create();
begin
  inherited Create;

  _minlevel := 50;
  _clanvnum := 0;
  _clanobj := 0;
  _leader := '';
  _name := 'Untitled Clan';
  _abbrev := '';
end;

procedure GClan.load(const fname : string);
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

procedure load_clans();
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

function findClan(const s : string) : GClan;
var
	iterator : GIterator;
	clan : GClan;
begin
  Result := nil;
  iterator := clan_list.iterator();

  while (iterator.hasNext()) do
    begin
    clan := GClan(iterator.next());

    if (s = clan.name) then
      begin
      Result := clan;
      break;
      end;
    end;

	iterator.Free();
end;

procedure initClans();
begin
  clan_list := GDLinkedList.Create();
end;

procedure cleanupClans();
begin
  clan_list.clear();
  clan_list.Free();
end;


end.
