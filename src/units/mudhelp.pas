{
  @abstract(Online help interface)
  @lastmod($Id: mudhelp.pas,v 1.3 2004/02/15 18:51:05 hemko Exp $)
}

unit mudhelp;

interface

uses
    fsys,
    dtypes;

type
    GHelp = class
      keywords, helptype, syntax, related : string;
      text : string;
      level : integer;
    end;

var
   helpFiles : GDLinkedList;

procedure loadHelp(fname:string);
function findHelp(text : string) : GHelp;

procedure initHelp();
procedure cleanupHelp();

implementation

uses
    SysUtils,
    constants,
    strip,
    util,
    mudsystem,
    skills,
    AnsiIO;


type
  ASkill = class
             min_lvl : integer;
             name : string;
             constructor Create(lvl : integer; str : string);
           end;

constructor ASkill.Create(lvl : integer; str : string);
begin
  min_lvl := lvl;
  name := str;
end;

function getSkillSpellList(sktype : integer) : string;
  procedure insertLevelSorted(var ll : GDLinkedList; ask : ASkill);
  var
    node,ins : GListNode;
    sk : ASkill;
  begin
    ins := nil;
  
    if (ll.head = nil) then
    begin
      ll.insertLast(ask);
      exit;
    end;
    
    node := ll.head;
    while (node <> nil) do
    begin
      sk := ASkill(node.element);

      if (ask.min_lvl > sk.min_lvl) then
      begin
        ins := node;
      end
      else
      begin
        ll.insertBefore(node, ask);
        exit;
      end;

      node := node.next;
    end;

    ll.insertAfter(ins, ask)
  end;

var
  buf : string;
  iterator : GIterator;
  gsk : GSkill;
  ask : ASkill;
  ll : GDLinkedList;
begin
  buf := '';
  ll := GDLinkedList.Create();

	iterator := skill_table.iterator();
  while (iterator.hasNext()) do
  	begin
    gsk := GSkill(iterator.next());
    if (gsk.skill_type = sktype) then
    	begin
      ask := ASkill.Create(gsk.min_lvl, gsk.name);
      insertLevelSorted(ll, ask);
    	end;    
	  end;
	iterator.Free();
  
	iterator := ll.iterator();
  while (iterator.hasNext()) do
  	begin
    ask := ASkill(iterator.next());
    buf := buf + Format('[$B$4%3d$A$7]  %s', [ask.min_lvl, ask.name]);
    if (iterator.hasNext()) then
      buf := buf + #13#10;
  	end;

  Result := buf;
end;
    
{ Xenon 16/Apr/2001: added keywords %SKILL_LIST% and %SPELL_LIST% and their functionality }
procedure loadHelp(fname:string);
var
	f : textfile;
  s, g, key : string;
  keyword : boolean;
  keys, text, helptype, related, syntax : string;
  help : GHelp;
  a, b : integer;
begin
  assignfile(f, translateFileName('help\'+fname));
  {$I-}
  reset(f);
  {$I+}
  if IOResult<>0 then
    begin
    bugreport('load_help', 'mudhelp.pas', 'could not open help\' + fname);
    exit;
    end;

  // first, add a default help
  help := GHelp.Create;
  help.level := 0;
  help.keywords := 'DEFAULT_';
  help.helptype := '';
  help.syntax := '';
  help.related := '';
  help.text := 'This is dummy help.';
  helpFiles.insertLast(help);

  keyword := false;

  repeat
    readln(f,s);
    if pos('#',s)=1 then
      begin
      g := uppercase(left(s, '='));

      if (g = '#KEYWORD') then
        begin
        keys := right(s, '=');
        keyword:=true;
        text:='';

        // jago .. clear all variables
        related := '';
        syntax := '';
        helptype := '';
        end
      else
      if (g = '#TYPE') then
        begin
        helptype := right(s, '=');
        end
      else
      if (g = '#SYNTAX') then
        begin
        syntax := right(s, '=');
        end
      else
      if (g = '#RELATED') then
        begin
        related := right(s, '=');
        end
      else
      if g='#END' then
        begin
        keyword:=false;
        help := GHelp.Create;
        help.level := StrToInt(right(s, '='));

        help.keywords := keys;
        help.helptype := helptype;
        help.syntax := syntax;
        help.related := related;
        help.text := text;

        helpFiles.insertLast(help);
        end
      else
      if g='#INCLUDE' then
        loadHelp(right(s, '='));
      end
    else
    if keyword then
      begin
      a := 1;
      while (a <= length(s)) do
        begin
        if (s[a] = '%') then
          begin
          if (a = length(s)) then
            begin
            bugreport('load_help', 'mudhelp.pas', 'illegal "%" character use in ' + fname);
            exit;
            end;
          if (s[a + 1] = '%') then
            begin
            g := '%';
            a := a + 2;
            continue;
            end;
          key := '';
          b := a + 1;
          while (s[b] <> '%') do
            begin
            key := key + s[b];
            inc(b);
            end;
          if (key = 'VERSION') then
            g := version_number
          else
          if (key = 'INFO') then
            g := version_info
          else
          if (key = 'COPYRIGHT') then
            g := version_copyright
          else
          if (key = 'SKILL_LIST') then
            g := getSkillSpellList(SKILL_SKILL)
          else
          if (key = 'SPELL_LIST') then
            g := getSkillSpellList(SKILL_SPELL)
          else
            bugreport('load_help', 'mudhelp.pas', 'illegal key "' + key + '" in ' + fname);
          text := text + g;
          a := b;
          end
        else
          text := text + s[a];
        inc(a);
        end;
      text := text + #13#10;
      end;
  until eof(f);
  closefile(f);
end;

// Find help by keyword
function findHelp(text : string) : GHelp;
var
	help : GHelp;
	key, arg : string;
	s, p : integer;
	iterator : GIterator;
begin
  Result := GHelp(helpFiles.head.element);
  p := high(integer);

  text := uppercase(text);

  iterator := helpFiles.iterator();

  while (iterator.hasNext()) do
    begin
    help := GHelp(iterator.next());

    key := help.keywords;

    while (length(key) > 0) do
      begin
      key := one_argument(key, arg);
      s := pos(text, arg);

      if (s > 0) and (s < p) then
        begin
        p := s;
        Result := help;
        end;
      end;
    end;
    
  iterator.Free();
end;

procedure initHelp();
begin
  helpFiles := GDLinkedList.Create;
end;

procedure cleanupHelp();
begin
  helpFiles.clean();
  helpFiles.Free();
end;

end.

