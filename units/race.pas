unit race;

interface

uses
    SysUtils,
    mudsystem,
    strip,
    util,
    dtypes,
    fsys;

type
    GRace = class
      node : GListNode;
      name, description : string;
      def_alignment : integer;
      convert : boolean;
      str_bonus, con_bonus, dex_bonus, int_bonus, wis_bonus : integer;
      save_poison, save_cold, save_para, save_breath, save_spell : integer;
      max_skills, max_spells : integer;

      constructor Create;
    end;

var
   race_list : GDLinkedList;

procedure load_races;

function findRace(name : string) : GRace;

implementation

constructor GRace.Create;
begin
  inherited Create;
  name := '';
  description := '';
  def_alignment := 0;    // fill in default values
  convert := false;
  str_bonus := 0;
  con_bonus := 0;
  dex_bonus := 0;
  int_bonus := 0;
  wis_bonus := 0;
  save_poison := 0;
  save_cold := 0;
  save_para := 0;
  save_breath := 0;
  save_spell := 0;
  max_skills := 0;
  max_spells := 0;
end;

{ Xenon 21/Feb/2001: revamped racefile format; made load_races() less error prone }
procedure load_races;
var t : TSearchRec;
    race : GRace;
    rf : GFileReader;
    full, lab, arg, str : string;  // lab short for label
begin
  if (FindFirst('races\*.race',faAnyFile,t) = 0) then
    repeat
      race := GRace.Create;

      with race do
      begin
        try
          try
            rf := GFileReader.Create('races\' + t.name);
          except
            on E: Exception do
            begin
              bugreport('load_races()', 'race.pas', 'error opening race file ' + t.name, 'Some unexpected error while opening ' + t.name + ': ''' + E.Message + '''.');
              exit;
            end;
          end;

          try
            repeat
              full := rf.readLine;
              lab := uppercase(stripl(full, ':'));
              arg := trim(striprbeg(full, ':'));

              if (lab = 'NAME') then
              begin
                name := arg;
                write_console('   Race: ' + name);
              end
              else
              if (lab = 'ALIGN') then
                def_alignment := strtoint(arg)
              else
              if (lab = 'CONVERT') then
              begin
                if not(arg[1] in ['0', '1']) then
                begin
                  bugreport('load_races()', 'race.pas', 'boolean conversion error', 'Error converting string to boolean value. Possible cause: ' + full + '.');
                  exit;
                end;
                convert := (strtoint(arg) = 1);
              end
              else
              if (lab = 'BONUS_STR') then
                str_bonus := strtoint(arg)
              else
              if (lab = 'BONUS_CON') then
                con_bonus := strtoint(arg)
              else
              if (lab = 'BONUS_DEX') then
                dex_bonus := strtoint(arg)
              else
              if (lab = 'BONUS_INT') then
                int_bonus := strtoint(arg)
              else
              if (lab = 'BONUS_WIS') then
                wis_bonus := strtoint(arg)
              else
              if (lab = 'SAVE_POISON') then
                save_poison := strtoint(arg)
              else
              if (lab = 'SAVE_COLD') then
                save_cold := strtoint(arg)
              else
              if (lab = 'SAVE_PARA') then
                save_para := strtoint(arg)
              else
              if (lab = 'SAVE_BREATH') then
                save_breath := strtoint(arg)
              else
              if (lab = 'SAVE_SPELL') then
                save_spell := strtoint(arg)
              else
              if (lab = 'SKILLSLOTS') then
                max_skills := strtoint(arg)
              else
              if (lab = 'SPELLSLOTS') then
                max_spells := strtoint(arg)
              else
              if (lab = 'DESCRIPTION') then
              begin
                description := '';
                repeat
                  str := rf.readLine;
                  if (str <> '~') then
                    description := description + str + #13#10;
                until (str = '~');
              end

            until (rf.eof);
          except
            on EConvertError do
            begin
              bugreport('load_races()', 'race.pas', 'conversion error', 'Error converting string to numeric value. Possible cause: ' + full + '.');
              exit;
            end;
            on E: Exception do
            begin
              bugreport('load_races()', 'race.pas', 'unknown exception', 'Caught unkown exception: ''' + E.Message + '''.');
              exit;
            end;
          end;
        finally
          begin
            rf.Free;
          end;
        end;
      end;  

      race.node := race_list.insertLast(race);
    until (FindNext(t) <> 0);
    
  FindClose(t);
end;

function findRace(name : string) : GRace;
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
