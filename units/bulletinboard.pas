unit bulletinboard;

interface

uses
    fsys,
    dtypes;

type
    GNote = class
      board, number : integer;
      date, author, subject : string;
      text : string;
    end;

var
   notes : GDLinkedList;

procedure load_notes(fname : string);
procedure save_notes;
function findNote(board, number : integer) : GNote;
function noteNumber(board : integer) : integer;
procedure postNote(c : pointer; text : string);

implementation

uses
    SysUtils,
    constants,
    strip,
    chars,
    mudsystem;

procedure load_notes(fname : string);
var f : textfile;
    note : GNote;
    s, g : string;
    board, number : integer;
    date, author, subject, text : string;
begin
  assignfile(f, translateFileName('boards\' + fname));
  {$I-}
  reset(f);
  {$I+}
  if (IOResult <> 0) then
    begin
    bugreport('load_notes', 'bulletinboard.pas', 'could not open boards\' + fname);
    exit;
    end;

  repeat
    readln(f,s);
    if (pos('#',s) = 1) then
      begin
      g := uppercase(left(s,'='));

      if (g = '#BOARD') then
        board := strtoint(rightr(s,'='))
      else
      if (g = '#NUMBER') then
        number := strtoint(rightr(s,'='))
      else
      if (g = '#DATE') then
        date := rightr(s,'=')
      else
      if (g = '#AUTHOR') then
        author := rightr(s,'=')
      else
      if (g = '#SUBJECT') then
        subject := rightr(s,'=')
      else
      if (g = '#TEXT') then
        begin
        text := '';

        repeat
          readln(f,s);

          if (s <> '~') then
            text := text + s + #13#10;
        until (s = '~');
        end
      else
      if (g = '#END') then
        begin
        note := GNote.Create;

        note.board := board;
        note.number := number;
        note.date := date;
        note.author := author;
        note.subject := subject;
        note.text := text;

        notes.insertLast(note);
        end
      else
      if (g = '#INCLUDE') then
        load_notes(rightr(s,'='));
      end;

  until eof(f);
  closefile(f);
end;

procedure save_notes;
var node : GListNode;
    f : textfile;
    note : GNote;
    i : integer;
begin
  for i:=1 to BOARD_MAX-1 do
    begin
    assignfile(f, translateFileName('boards\' + board_names[i] + '.brd'));
    rewrite(f);

    node := notes.head;

    while (node <> nil) do
      begin

      note := node.element;

      if (note.board = i) then
        begin
        writeln(f, '#BOARD=' + inttostr(note.board));
        writeln(f, '#NUMBER=' + inttostr(note.number));
        writeln(f, '#DATE=' + note.date);
        writeln(f, '#AUTHOR=' + note.author);
        writeln(f, '#SUBJECT=' + note.subject);
        writeln(f, '#TEXT');
        writeln(f, note.text);
        writeln(f, '~');
        writeln(f, '#END');
        writeln(f);
        end;

      node := node.next;
      end;

    closefile(f);
    end;
end;

function findNote(board, number : integer) : GNote;
var node : GListNode;
    note : GNote;
begin
  Result := nil;

  node := notes.head;

  while (node <> nil) do
    begin
    note := node.element;

    if (note.board = board) and (note.number = number) then
      begin
      Result := note;
      exit;
      end;

    node := node.next;
    end;
end;

function noteNumber(board : integer) : integer;
var node : GListNode;
    note : GNote;
    number : integer;
begin
  number := 0;
  node := notes.head;

  while (node <> nil) do
    begin
    note := node.element;

    if (note.board = board) and (note.number > number) then
      number := note.number;

    node := node.next;
    end;

  Result := number + 1;
end;

procedure postNote(c : pointer; text : string);
var note : GNote;
    ch : GPlayer;
begin
  ch := c;

  note := GNote.Create;

  note.board := ch.active_board;
  note.number := noteNumber(ch.active_board);
  note.date := DateTimeToStr(Now);
  note.author := ch.name^;
  note.subject := ch.subject;
  note.text := text;

  notes.insertLast(note);
  save_notes;
end;

begin
  notes := GDLinkedList.Create;
end.
