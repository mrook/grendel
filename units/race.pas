unit race;

interface

uses
    SysUtils,
    mudsystem,
    strip,
    util,
    dtypes;

type
    GRace = class
      node : GListNode;
      name, description : string;
      def_alignment : integer;
      convert : boolean;
      str_bonus, con_bonus, dex_bonus, int_bonus, wis_bonus : integer;
      save_poison, save_cold, save_para, save_breath, save_spell : integer;
    end;

var
   race_list : GDLinkedList;

procedure load_races;

function findRace(name : pchar) : GRace;

implementation

procedure load_races;
var t : TSearchRec;
    f : textfile;
    s : string;
    race : GRace;
begin
  if (FindFirst('races\*.race',faAnyFile,t) = 0) then
    repeat
      assignfile(f,'races\'+t.name);
      reset(f);

      race := GRace.Create;

      with race do
        begin
        readln(f, s);
        name := trim(stripr(s, ' '));
        write_console('   Race: ' + name);

        readln(f, s);
        def_alignment := strtoint(trim(stripr(s, ' ')));

        readln(f, s);
        convert := (strtoint(trim(stripr(s, ' '))) = 1);

        readln(f, s);                   { bonuses for rolling }
        s := trim(striprbeg(s, ' '));
        str_bonus := strtoint(stripl(s,' '));
        s := trim(striprbeg(s, ' '));
        con_bonus:=strtoint(stripl(s,' '));
        s := trim(striprbeg(s, ' '));
        dex_bonus:=strtoint(stripl(s,' '));
        s := trim(striprbeg(s, ' '));
        int_bonus:=strtoint(stripl(s,' '));
        s := trim(striprbeg(s, ' '));
        wis_bonus:=strtoint(stripl(s,' '));
        readln(f,s);                   { saving throws }
        s:=trim(striprbeg(s,' '));
        save_poison:=strtoint(stripl(s,' '));
        s:=trim(striprbeg(s,' '));
        save_cold:=strtoint(stripl(s,' '));
        s:=trim(striprbeg(s,' '));
        save_para:=strtoint(stripl(s,' '));
        s:=trim(striprbeg(s,' '));
        save_breath:=strtoint(stripl(s,' '));
        s:=trim(striprbeg(s,' '));
        save_spell:=strtoint(stripl(s,' '));

        description := '';
        repeat
          readln(f,s);

          if (s <> '~') then
            description := description + s + #13#10;
        until s='~';
        end;

      closefile(f);

      race.node := race_list.insertLast(race);
    until (FindNext(t) <> 0);
    
  FindClose(t);
end;

function findRace(name : pchar) : GRace;
var
   node : GListNode;
   race : GRace;
begin
  findRace := nil;

  node := race_list.head;

  while (node <> nil) do
    begin
    race := GRace(node.element);

    if (comparestr(name, race.name) = 0) then
      begin
      findRace := race;
      exit;
      end;

    node := node.next;
    end;
end;

begin
  race_list := GDLinkedList.Create;
end.
