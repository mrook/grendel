program convertxml;
{$APPTYPE CONSOLE}

uses
	Windows,
	ActiveX,
	xmldoc,
	xmldom,
	xmlintf,
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
  Count, Loop: Integer;
  List: PPropList;
  prop : PPropInfo;
  iterator : GIterator;
  
  doc : TXMLDocument;
  child1, child2, node : IXMLNode;

begin
	CoInitialize(nil);
	
	try
		doc := TXMLDocument.Create(nil);
		doc.DOMVendor := DOMVendors[0];
		doc.Active := true;
		doc.Options := [doNodeAutoIndent];
		
		doc.Encoding := 'iso-8859-1';
		doc.Version := '1.0';
		doc.NSPrefixBase := 'grendel';
		
		node := doc.AddChild('area');

		initRaces();
		initSkills();
		initAreas();
		initConsole();

		loadRaces();

		are := GArea.Create();

		are.load('roads.area');

		Count := GetPropList(TypeInfo(GArea), tkAny, nil);
		GetMem(List, Count * SizeOf(PPropInfo));
		GetPropList(TypeInfo(GArea), tkAny, List);

		for Loop := 0 to Pred(Count) do
			begin
			prop := List^[Loop];

			child1 := node.addChild(prop^.Name);

		 	case (prop.PropType^.Kind) of
				tkInteger: child1.Text := IntToStr(GetOrdProp(are, prop));
				tkFloat: child1.Text := FloatToStr(GetFloatProp(are, prop));
				tkLString: child1.Text := GetStrProp(are, prop);
				tkChar: child1.Text := char(GetOrdProp(are, prop));
			end;
			end;

		FreeMem(List, Count * SizeOf(PPropInfo));

		Count := GetPropList(TypeInfo(GRoom), tkAny, nil);
		GetMem(List, Count * SizeOf(PPropInfo));
		GetPropList(TypeInfo(GRoom), tkAny, List);

		iterator := room_list.iterator();

		while (iterator.hasNext()) do
			begin
			room := GRoom(iterator.next());

			child1 := node.addChild('room');

			for Loop := 0 to Pred(Count) do
				begin
				prop := List^[Loop];

				child2 := child1.addChild(prop^.Name);

				case (prop.PropType^.Kind) of
					tkInteger: child2.Text := IntToStr(GetOrdProp(are, prop));
					tkFloat: child2.Text := FloatToStr(GetFloatProp(are, prop));
					tkLString: child2.Text := GetStrProp(are, prop);
					tkChar: child2.Text := char(GetOrdProp(are, prop));
				end;
				end;
			end;

		FreeMem(List, Count * SizeOf(PPropInfo));

		doc.SaveToFile('test.xml');

	finally
		CoUninitialize();
	end;
	
end.
