unit speller_main;

interface

implementation


uses
  SysUtils,
  chars,
  player,
  area,
  dtypes,
  modules,
  commands,
  mudspell;


type
  GSpellerModule = class(TInterfacedObject, IModuleInterface)
  	procedure registerModule();
  	procedure unregisterModule();
  end;
  
  
procedure do_spellcheck(ch : GCharacter; param : string);
var
   room : GRoom;
   area : GArea;
   node : GListNode;
   h : integer;
begin
  if (GPlayer(ch).area_fname='') then
    begin
    ch.sendBuffer('You have not yet been assigned an area.'#13#10);
    exit;
    end;

  area := GPlayer(ch).area;
  if (area=nil) then
    begin
    ch.sendBuffer('Use LOADAREA first to loadup your assigned area.'#13#10);
    exit;
    end;

  ch.sendBuffer('Spellchecking area '+area.fname+'...'#13#10#13#10);

  for h := 0 to room_list.hashsize - 1 do
    begin
    node := room_list.bucketList[h].head;

    while (node <> nil) do
      begin
      room := GRoom(GHashValue(node.element).value);

      if (room.area = area) then
        begin
        if (not checkWords(room.description)) then
          ch.sendBuffer('('+inttostr(room.vnum)+') possibly misspelled word(s), [' + trim(misspelled_words) + ']'#13#10);
        end;

      node := node.next;
      end;
    end;
end;

procedure do_addcustom(ch : GCharacter; param : string);
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('ADDCUSTOM <word to add to custom dictionary'#13#10);
    exit;
    end;
    
  addToCustom(param);
  
  ch.sendBuffer('Ok.'#13#10);
end;

function returnModuleInterface() : IModuleInterface;
begin
	Result := GSpellerModule.Create();
end;

procedure GSpellerModule.registerModule();
begin
  registerCommand('do_spellcheck', do_spellcheck);
  registerCommand('do_addcustom', do_addcustom);
end;

procedure GSpellerModule.unregisterModule();
begin
  unregisterCommand('do_spellcheck');
  unregisterCommand('do_addcustom');
end;


exports
	returnModuleInterface;


end.

