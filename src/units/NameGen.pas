{
	Summary:
		Phonetic namegenerator

	## $Id: NameGen.pas,v 1.3 2004/03/13 15:45:21 ***REMOVED*** Exp $
}

unit NameGen;


interface


uses
	constants,
	dtypes;


const
  NameTablesDataFile = SystemDir + 'NameData.xml';


type
  TPhonemePart = class
  private
		part_value : string;
		
	public
		constructor Create(const name : string); // name: part_value
	end;
	
  TPhoneme = class
  private
		phoneme_name : string;
		phoneme_parts : GDLinkedList;

	public
		constructor Create(const name : string); // name: phoneme_name
		destructor Destroy(); override;
		function getNthPhonemePart(nth : integer) : TPhonemePart; // returns nth phoneme_part from linked list
  end;

  TNameTemplatePart = class
  private
  	part_type : string;
  	part_value : string;
  end;

  TNameTemplate = class
  private
  	template_name : string;
  	template_parts : GDLinkedList;
  	
  public
		constructor Create(const name : string);
		destructor Destroy(); override;
		
		property name : string read template_name;
	end;


procedure loadNameTables(dfile : string);
procedure reloadNameTables();
function generateName(const nametemplate : string) : string;

var
  PhonemeList : GDLinkedList = nil;
  NameTemplateList : GDLinkedList = nil;
  namegenerator_enabled : boolean = false;

implementation

uses
  SysUtils,
  mudsystem,
  console,
  util,
  LibXmlParser;
  
constructor TPhoneme.Create(const name : string);
begin
  inherited Create;

  phoneme_parts := GDLinkedList.Create();
  phoneme_name := name;
end;

destructor TPhoneme.Destroy();
begin
  phoneme_parts.Clear();
  phoneme_parts.Free();
  
  inherited Destroy;
end;

// gets nth phonemepart from linked list
function TPhoneme.getNthPhonemePart(nth : integer) : TPhonemePart;
var
  i : integer;
  node : GListNode;
begin
  result := nil;
  i := 0;
  node := phoneme_parts.head;
  while (node <> nil) do
  begin
    if (i = nth) then
    begin
      result := TPhonemePart(node.element);
      break;
    end;
    inc(i);
    node := node.next;
  end;
end;

constructor TPhonemePart.Create(const name : string);
begin
  inherited Create();

  part_value := name;
end;

constructor TNameTemplate.Create(const name : string);
begin
  inherited Create();

  template_parts := GDLinkedList.Create();
  template_name := name;
end;

destructor TNameTemplate.Destroy();
begin
  template_parts.Clear();
  template_parts.Free();
  
  inherited Destroy;
end;

procedure loadNameTables(dfile : string);
var
  parser : TXmlParser;
  attr : TNvplist;
  i : integer;
  phoneme : TPhoneme;
  nametemplate : TNameTemplate;
  phpart : TPhonemePart;
  ntpart : TNameTemplatePart;
  str : string;
  current_tag : string;
  currtype : string;
begin
  phoneme := nil; nametemplate := nil;
  dfile := trim(dfile);
  
  parser := TXmlParser.Create();
  parser.Normalize := false;
  parser.LoadFromFile(dfile);

  if (parser.Source <> dfile) then
  begin
    namegenerator_enabled := false;
    writeConsole('Could not open ' + dfile + ' (automatic namegenerator), disabled.');
    exit;
  end;
  
  PhonemeList := GDLinkedList.Create();
  NameTemplateList := GDLinkedList.Create();
  
  parser.StartScan();
  while parser.Scan do
    case parser.CurPartType of          // Here the parser tells you what it has found
{      ptDtdc:
        begin
          writeln('ptDtdc: ' + StrSFPas (Parser.CurStart, Parser.CurFinal));
        end;}
      ptStartTag, // Process Parser.CurName and Parser.CurAttr (see below) fields here
      ptEmptyTag:
        begin
          if (parser.CurName = 'Phoneme') then
          begin
            attr := parser.CurAttr;
            for i := 0 to (attr.Count - 1) do
            begin
              if (TNvpNode(attr[i]).Name = 'Name') then
                str := TNvpNode(attr[i]).Value;
            end;
            phoneme := TPhoneme.Create(str);
            PhonemeList.insertLast(phoneme);
          end;

          if ((parser.CurName = 'Part') and (parser.CurAttr.Count = 0)) then
            current_tag := 'PhonemePart';
            
          if (parser.CurName = 'NameTemplate') then
          begin
            attr := parser.CurAttr;
            for i := 0 to (attr.Count - 1) do
            begin
              if (TNvpNode(attr[i]).Name = 'Name') then
                str := TNvpNode(attr[i]).Value;
            end;
            nametemplate := TNameTemplate.Create(str);
            NameTemplateList.insertLast(nametemplate);
          end;

          if ((parser.CurName = 'Part') and (parser.CurAttr.Count > 0)) then
          begin
            attr := parser.CurAttr;
            if (TNvpNode(attr[0]).Name = 'Type') then
            begin
              currtype := TNvpNode(attr[0]).Value;
              current_tag := 'NameTemplatePart';
            end;
          end;
        end;
      ptContent:
        begin
          if (current_tag = 'PhonemePart') then
          begin
            if (parser.CurContent = '+') then
              phpart := TPhonemePart.Create(' ')
            else
              phpart := TPhonemePart.Create(parser.CurContent);
            phoneme.phoneme_parts.insertLast(phpart);
          end;

          if (current_tag = 'NameTemplatePart') then
          begin
            ntpart := TNameTemplatePart.Create();
            ntpart.part_type := currtype;
            ntpart.part_value := parser.CurContent;
            nametemplate.template_parts.insertLast(ntpart);
          end;
        end;
{      ptCData    : // Process Parser.CurContent field here
        begin
          writeln('ptCData: CurContent: ' + parser.CurContent);
        end;}
      ptEndTag   : // Process End-Tag here (Parser.CurName)
        begin
          current_tag := '';
        end;
{      ptPI       : // Process PI here (Parser.CurName is the target, Parser.CurContent)
        begin
          writeln('ptPI: CurName: ' + parser.CurName + ' CurContent: ' + parser.CurContent);
        end;}
    end;

  parser.Free();

  namegenerator_enabled := true;
  writeConsole('Loaded ' + inttostr(PhonemeList.size()) + ' phoneme classes and ' + inttostr(NameTemplateList.size()) + ' name templates from ' + dfile + '.');
end;

function findPhoneme(const str : string) : TPhoneme;
var
  node : GListNode;
begin
  result := nil;
  node := PhonemeList.head;
  while (node <> nil) do
  begin
    if (TPhoneme(node.element).phoneme_name = str) then
    begin
      result := TPhoneme(node.element);
      break;
    end;
    node := node.next;
  end;
end;

function findNameTemplate(const str : string) : TNameTemplate;
var
  node : GListNode;
begin
  result := nil;
  node := NameTemplateList.head;
  while (node <> nil) do
  begin
    if (TNameTemplate(node.element).template_name = str) then
    begin
      result := TNameTemplate(node.element);
      break;
    end;
    node := node.next;
  end;
end;

function generateName(const nametemplate : string) : string;
var
  iterator : GIterator;
  ph : TPhoneme;
  phpart : TPhonemePart;
  ntpart : TNameTemplatePart;
  nt : TNameTemplate;
begin
  result := '';
  if (not namegenerator_enabled) then
    exit;

  nt := findNameTemplate(nametemplate);
  assert(nt <> nil, 'findNameTemplate() returned nil');
  if (nt = nil) then
  begin
    exit;
  end;
  
  iterator := nt.template_parts.iterator();
  while (iterator.hasNext()) do
  	begin
    ntpart := TNameTemplatePart(iterator.next());
    ph := findPhoneme(ntpart.part_value);
    assert(ph <> nil, 'findPhoneme() returned nil');
    phpart := ph.getNthPhonemePart(random(ph.phoneme_parts.size()));
    assert(phpart <> nil, 'getNthPhonemePart() returned nil');
    if (ntpart.part_type = 'Cap') then
      result := result + cap(phpart.part_value)
    else
      result := result + phpart.part_value;
  end;  
  iterator.Free();
end;

procedure reloadNameTables();
begin
  PhonemeList.Clear();
  PhonemeList.Free();
  NameTemplateList.Clear();
  NameTemplateList.Free();
  namegenerator_enabled := false;
  writeConsole('Reloading ' + NameTablesDataFile + '.');
  loadNameTables(NameTablesDataFile);
end;

begin
  randomize();
end.

