unit mudhelp;

interface

uses
    dtypes;

type
    GHelp = class
      keywords, helptype, syntax, related : string;
      text : string;
      level : integer;
    end;

var
   help_files : GDLinkedList;

procedure load_help(fname:string);

function findHelp(text : string) : GHelp;

implementation

uses
    SysUtils,
    constants,
    strip,
    util,
    mudsystem;

procedure load_help(fname:string);
var f:textfile;
    s, g, key : string;
    keyword : boolean;
    keys, text, helptype, related, syntax : string;
    help : GHelp;
    a, b : integer;
begin
  assignfile(f,'help\'+fname);
  {$I-}
  reset(f);
  {$I+}
  if IOResult<>0 then
    begin
    bugreport('load_help', 'mudhelp.pas', 'could not open help\' + fname,
              'The specified helpfile could not be opened. Please check your settings.');
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
  help_files.insertLast(help);

  keyword := false;

  repeat
    readln(f,s);
    if pos('#',s)=1 then
      begin
      g := uppercase(stripl(s,'='));

      if (g = '#KEYWORD') then
        begin
        keys:=stripr(s,'=');
        keyword:=true;
        text:='';
        end
      else
      if (g = '#TYPE') then
        begin
        helptype := stripr(s,'=');
        end
      else
      if (g = '#SYNTAX') then
        begin
        syntax := stripr(s,'=');
        end
      else
      if (g = '#RELATED') then
        begin
        related := stripr(s,'=');
        end
      else
      if g='#END' then
        begin
        keyword:=false;
        help:=GHelp.Create;
        help.level:=StrToInt(stripr(s,'='));

        help.keywords := hash_string(keys);
        help.helptype := helptype;
        help.syntax := syntax;
        help.related := related;
        help.text := text;

        help_files.insertLast(help);
        end
      else
      if g='#INCLUDE' then
        load_help(stripr(s,'='));
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
            bugreport('load_help', 'mudhelp.pas', 'illegal "%" character use in ' + fname,
                      'Use of the character "%" is prohibited in helpfiles.');
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
            bugreport('load_help', 'mudhelp.pas', 'illegal key "' + key + '" in ' + fname,
                      'This helpfile uses an unknown key.');
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

function findHelp(text : string) : GHelp;
var
   node : GListNode;
   help : GHelp;
   key, arg : string;
begin
  Result := help_files.head.element;

  text := uppercase(text);

  node := help_files.head;

  while (node <> nil) do
    begin
    help := node.element;

    key := help.keywords;

    while (length(key) > 0) do
      begin
      key := one_argument(key, arg);

      if (pos(text, arg) > 0) then
        begin
        Result := help;
        exit;
        end;
      end;

    node := node.next;
    end;
end;


begin
  help_files := GDLinkedList.Create;
end.
