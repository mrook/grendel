program convertxml;

uses
  SysUtils,
  TypInfo,
  skills,
  console,
  dtypes,
  fsys,
  race,
  area;

var
  are : GArea;
  room : GRoom;
  fw : GFileWriter;
  Count, Loop: Integer;
  List: PPropList;
  prop : PPropInfo;
  iterator : GIterator;

begin
  initRaces();
  initSkills();
  initAreas();
  initConsole();

  loadRaces();

  are := GArea.Create();

  are.load('limbo.area');

  try
    fw := GFileWriter.Create('roads.xml');
  except
    exit;
  end;

  fw.writeLine('<?xml version="1.0"?>');
  fw.writeLine('<area>');

  try
    Count := GetPropList(TypeInfo(GArea), tkAny, nil);
    GetMem(List, Count * SizeOf(PPropInfo));
    GetPropList(TypeInfo(GArea), tkAny, List);

    for Loop := 0 to Pred(Count) do
      begin
      prop := List^[Loop];

      fw.writeString('  <' + prop^.Name + '>');

      case (prop.PropType^.Kind) of
        tkInteger: fw.writeString(IntToStr(GetOrdProp(are, prop)));
        tkFloat: fw.writeString(FloatToStr(GetFloatProp(are, prop)));
        tkLString: fw.writeString(GetStrProp(are, prop));
        tkChar: fw.writeString(char(GetOrdProp(are, prop)));
      end;

      fw.writeLine('</' + prop^.Name + '>');
      end;

    FreeMem(List, Count * SizeOf(PPropInfo));

    Count := GetPropList(TypeInfo(GRoom), tkAny, nil);
    GetMem(List, Count * SizeOf(PPropInfo));
    GetPropList(TypeInfo(GRoom), tkAny, List);

    iterator := room_list.iterator();

    while (iterator.hasNext()) do
      begin
      room := GRoom(iterator.next());

      fw.writeLine('  <room>');

      for Loop := 0 to Pred(Count) do
        begin
        prop := List^[Loop];

        fw.writeString('    <' + prop^.Name + '>');

        case (prop.PropType^.Kind) of
          tkInteger: fw.writeString(IntToStr(GetOrdProp(room, prop)));
          tkFloat: fw.writeString(FloatToStr(GetFloatProp(room, prop)));
          tkLString: fw.writeString(GetStrProp(room, prop));
          tkChar: fw.writeString(char(GetOrdProp(room, prop)));
        end;

        fw.writeLine('</' + prop^.Name + '>');
        end;

      fw.writeLine('  </room>');
      end;

    fw.writeLine('</area>');
  finally
    FreeMem(List, Count * SizeOf(PPropInfo));
    fw.Free();
  end;

end.
