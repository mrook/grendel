{
  @abstract(Race routines)
  @lastmod($Id: race.pas,v 1.13 2003/06/24 21:41:35 ***REMOVED*** Exp $)
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
      node : GListNode;
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

function prep(str : string) : string;
begin
  Result := trim(uppercase(str));
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
//		    if (prep(parser.CurName) = 'POISON') then
//		      race.save_poison :=
		    end;
			ptEndTag:
			  begin
				if (prep(parser.CurName) = 'SAVES') then
					exit;
				end;
    end;
end;

{ xml version of loadRacesOld() }
procedure loadRaces();
var
  t : TSearchRec;
  parser : TXmlParser;
  race : GRace;
  bodypart : GBodyPart;
begin
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
			          race.name := cap(parser.CurContent)
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

{ Xenon 21/Feb/2001: revamped racefile format; made loadRaces() less error prone }
procedure loadRacesOld();
var t : TSearchRec;
    race : GRace;
    rf : GFileReader;
    full, lab, arg, str : string;  // lab short for label
    sk : GSkill;
begin
  rf := nil;
  
  if (FindFirst('races' + PathDelimiter + '*.race', faAnyFile, t) = 0) then
    repeat
      race := GRace.Create;

      with race do
      begin
        try
          try
            rf := GFileReader.Create('races' + PathDelimiter + t.name);
          except
            on E: Exception do
            begin
              bugreport('loadRaces()', 'race.pas', 'error opening race file ' + t.name);
              exit;
            end;
          end;

          try
            repeat
              full := rf.readLine;
              lab := uppercase(left(full, ':'));
              arg := trim(right(full, ':'));

              if (lab = 'NAME') then
              begin
                name := arg;
                writeConsole('   Race: ' + name);
              end
              else
              if (lab = 'ALIGN') then
                def_alignment := strtoint(arg)
              else
              if (lab = 'CONVERT') then
              begin
                if not(arg[1] in ['0', '1']) then
                begin
                  bugreport('loadRaces()', 'race.pas', 'boolean conversion error');
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
              else
              if (lab = 'ABILITY') then
                begin
                sk := findSkill(arg);
                
                if (sk = nil) then
                  bugreport('loadRaces()', 'race.pas', 'Could not find racial ability ' + arg)
                else
                  abilities.insertLast(sk);
                end;

            until (rf.eof);
          except
            on EConvertError do
            begin
              bugreport('loadRaces()', 'race.pas', 'conversion error');
              exit;
            end;
            on E: Exception do
            begin
              bugreport('loadRaaces()', 'race.pas', 'unknown exception');
              exit;
            end;
          end;
        finally
          begin
            rf.Free;
          end;
        end;
      end;  

      race.node := raceList.insertLast(race);
    until (FindNext(t) <> 0);

  FindClose(t);

  // fall-through rule: if no races are loaded, we must create a dummy one

  if (raceList.getSize() = 0) then
    begin
    bugreport('loadRaces()', 'race.pas', 'No races loaded, adding default one');
    
    race := GRace.Create;
    race.name := 'Creature';
    race.node := raceList.insertLast(race);
    end;
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
