{
	Summary:
		Race routines

	## $Id: race.pas,v 1.2 2003/12/12 23:01:19 ***REMOVED*** Exp $
}

unit race;

interface

uses
    SysUtils,
    mudsystem,
    constants,
    strip,
    util,
    dtypes,
    fsys;

type   
    GBodyPart = class
    private
      _name : string;
      _description : string;
      _char_message, _room_message : string;
      
    public
      constructor Create();
      
    published
      property name : string read _name write _name;
      property description : string read _description write _description;
      property char_message : string read _char_message write _char_message;
      property room_message : string read _room_message write _room_message;
    end;
    
    GRace = class
   	private
      node : GListNode;
      
    public
      name, description : string;
      def_alignment : integer;
      convert : boolean;
      saves : GHashTable;
      str_bonus, con_bonus, dex_bonus, int_bonus, wis_bonus : integer;
      str_max, con_max, dex_max, int_max, wis_max : integer;
      save_poison, save_cold, save_para, save_breath, save_spell : integer;
      max_skills, max_spells : integer;
      abilities : GDLinkedList;
      bodyparts : GHashTable;

      constructor Create();
    end;

var
   raceList : GDLinkedList;

procedure loadRaces();

function findRace(name : string) : GRace;

procedure initRaces();
procedure cleanupRaces();

implementation

uses
  LibXmlParser,
  console,
  skills;
  
constructor GBodyPart.Create();
begin
  inherited Create;
  
  name := 'bodypart';
  description := 'bodypart';
  char_message := 'You wear $p on your bodypart,';
  room_message := '$n wears $p on $s bodypart,';
end;

constructor GRace.Create();
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
  max_skills := 10;
  max_spells := 10;
  abilities := GDLinkedList.Create();
  bodyparts := GHashTable.Create(32);
end;

procedure loadBodyParts(parser : TXmlParser; race : GRace);
var
  bodypart : GBodyPart;
begin
	bodypart := GBodyPart.Create();
	
  while (parser.Scan()) do
		case parser.CurPartType of // Here the parser tells you what it has found
		  ptContent:
		    begin
		    if (prep(parser.CurName) = 'NAME') then
		      bodypart.name := parser.CurContent
		    else
		    if (prep(parser.CurName) = 'DESCRIPTION') then
		      bodypart.description := parser.CurContent
		    else
		    if (prep(parser.CurName) = 'CHAR_MESSAGE') then
		      bodypart.char_message := parser.CurContent
		    else
		    if (prep(parser.CurName) = 'ROOM_MESSAGE') then
		      bodypart.room_message := parser.CurContent;
		    end;
			ptEndTag:
			  begin
				if (prep(parser.CurName) = 'BODYPART') then
				  begin
					race.bodyparts[bodypart.name] := bodypart;
					exit;
					end;
				end;
    end;
end;

procedure loadStatMax(parser : TXmlParser; race : GRace);
begin
  while (parser.Scan()) do
		case parser.CurPartType of // Here the parser tells you what it has found
		  ptContent:
		    begin
		    if (prep(parser.CurName) = 'INT') then
		    	race.int_max := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'WIS') then
		    	race.wis_max := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'DEX') then
		    	race.dex_max := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'STR') then
		    	race.str_max := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'CON') then
		    	race.con_max := StrToInt(parser.CurContent);
		    end;
			ptEndTag:
			  begin
				if (prep(parser.CurName) = 'STATMAX') then
					exit;
				end;
    end;
end;

procedure loadSaves(parser : TXmlParser; race : GRace);
begin
  while (parser.Scan()) do
		case parser.CurPartType of // Here the parser tells you what it has found
		  ptContent:
		    begin
		    if (prep(parser.CurName) = 'POISON') then
		      race.save_poison := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'COLD') then
		      race.save_cold := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'PARA') then
		      race.save_para := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'BREATH') then
		      race.save_breath := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'SPELL') then
		      race.save_spell := StrToInt(parser.CurContent);
		    end;
			ptEndTag:
			  begin
				if (prep(parser.CurName) = 'SAVES') then
					exit;
				end;
    end;
end;

{
	Summary:
		Loads all .xml racefiles
}
procedure loadRaces();
var
  t : TSearchRec;
  parser : TXmlParser;
  race : GRace;
begin
	race := nil;
	
  parser := TXmlParser.Create();
  parser.Normalize := true;

  if (FindFirst('races' + PathDelimiter + '*.xml', faAnyFile, t) = 0) then
    repeat
		  parser.LoadFromFile('races' + PathDelimiter + t.name);
  
  		if (parser.Source <> 'races' + PathDelimiter + t.name) then
    		writeConsole('Could not load ' + t.name)
    	else
    	  begin
			  parser.StartScan();

			  while (parser.Scan()) do
    			case parser.CurPartType of // Here the parser tells you what it has found
      			ptStartTag:
        			begin
			        if (prep(parser.CurName) = 'RACE') then
			          race := GRace.Create()
			        else
			        if (prep(parser.CurName) = 'BODYPART') then
			          loadBodyParts(parser, race)
			        else
			        if (prep(parser.CurName) = 'STATMAX') then
			          loadStatMax(parser, race);
			        end;
			      ptContent:
			        begin
			        if (prep(parser.CurName) = 'NAME') then
			        	begin
			          race.name := cap(parser.CurContent);
                writeConsole('   Race: ' + race.name);
			          end
			        else
			        if (prep(parser.CurName) = 'DESCRIPTION') then
			          race.description := parser.CurContent;
			        end;
      			ptEndTag   : // Process End-Tag here (Parser.CurName)
							begin
							if (prep(parser.CurName) = 'RACE') then
								race.node := raceList.insertLast(race);
							end;
    			end;
    	  end;
    until (FindNext(t) <> 0);

  FindClose(t);

	parser.Free();
end;

function findRace(name : string) : GRace;
var
   iterator : GIterator;
   race : GRace;
begin
  Result := nil;

  iterator := raceList.iterator();

  while (iterator.hasNext()) do
    begin
    race := GRace(iterator.next);

    if (comparestr(name, race.name) = 0) then
      begin
      Result := race;
      break;
      end;
    end;
  
  iterator.Free();
end;

procedure initRaces();
begin
  raceList := GDLinkedList.Create;
end;

procedure cleanupRaces();
begin
  raceList.clean();
  raceList.Free();
end;

end.
