{
	Summary:
		Race routines

	## $Id: race.pas,v 1.3 2004/02/11 22:15:25 ***REMOVED*** Exp $
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

		_name, _description : string;
		_str_bonus, _con_bonus, _dex_bonus, _int_bonus, _wis_bonus : integer;
		_def_alignment : integer;
		_max_skills, _max_spells : integer;
		_save_poison, _save_cold, _save_para, _save_breath, _save_spell : integer;
		_abilities : GDLinkedList;
		_bodyparts : GHashTable;	
		_convert : boolean;
		
		str_max, con_max, dex_max, int_max, wis_max : integer;

	public
		constructor Create();
		
		property name : string read _name;
		property description : string read _description;
		
		property str_bonus : integer read _str_bonus;
		property con_bonus : integer read _con_bonus;
		property dex_bonus : integer read _dex_bonus;
		property int_bonus : integer read _wis_bonus;
		property wis_bonus : integer read _int_bonus;
		
		property max_skills : integer read _max_skills;
		property max_spells : integer read _max_spells;
		
		property save_poison : integer read _save_poison;
		property save_cold : integer read _save_cold;
		property save_para : integer read _save_para;
		property save_breath : integer read _save_breath;
		property save_spell : integer read _save_spell;
		
		property def_alignment : integer read _def_alignment;
		
		property abilities : GDLinkedList read _abilities;
		property bodyparts : GHashTable read _bodyparts;
		
		property convert : boolean read _convert;
	end;


var
	raceList : GDLinkedList;


procedure loadRaces();
procedure initRaces();
procedure cleanupRaces();

function findRace(name : string) : GRace;


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
  
  _convert := false;
  _name := '';
  _description := '';
  _def_alignment := 0;    // fill in default values
  _str_bonus := 0;
  _con_bonus := 0;
  _dex_bonus := 0;
  _int_bonus := 0;
  _wis_bonus := 0;
  _save_poison := 0;
  _save_cold := 0;
  _save_para := 0;
  _save_breath := 0;
  _save_spell := 0;
  _max_skills := 10;
  _max_spells := 10;
  _abilities := GDLinkedList.Create();
  _bodyparts := GHashTable.Create(32);
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
		      race._save_poison := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'COLD') then
		      race._save_cold := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'PARA') then
		      race._save_para := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'BREATH') then
		      race._save_breath := StrToInt(parser.CurContent)
		    else
		    if (prep(parser.CurName) = 'SPELL') then
		      race._save_spell := StrToInt(parser.CurContent);
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
			          race._name := cap(parser.CurContent);
                writeConsole('   Race: ' + race.name);
			          end
			        else
			        if (prep(parser.CurName) = 'DESCRIPTION') then
			          race._description := parser.CurContent;
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
