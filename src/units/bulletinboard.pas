{
  Summary:
  	Abstract(Bulletinboard (noteboard) interface
  	
	## $Id: bulletinboard.pas,v 1.4 2004/02/28 15:53:24 hemko Exp $
}

unit bulletinboard;

interface

uses
    fsys,
    dtypes;

type
    GNote = class
    public
      board, number : integer;
      date, author, subject : string;
      text : string;
    end;

var
   notes : GDLinkedList;

procedure load_notes(const fname : string);
procedure save_notes();
function findNote(board, number : integer) : GNote;
function noteNumber(board : integer) : integer;
procedure postNote(c : pointer; const text : string);

procedure initNotes();
procedure cleanupNotes();

implementation

uses
    SysUtils,
    constants,
    strip,
    chars,
    player,
    mudsystem;

procedure load_notes(const fname : string);
var
  af : GFileReader;
  note : GNote;
  s, g : string;
  board, number : integer;
  date, author, subject, text : string;
begin
	board := 0;
	number := 0;
	
  try
    af := GFileReader.Create('boards\' + fname);
  except
    exit;
  end;

  repeat
    s := af.readLine();

    if (pos('#',s) = 1) then
      begin
      g := uppercase(left(s,'='));

      if (g = '#BOARD') then
        board := StrToIntDef(rightr(s,'='), 0)
      else
      if (g = '#NUMBER') then
        number := StrToIntDef(rightr(s,'='), 0)
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
          s := af.readLine();

          if (s <> '~') then
            text := text + s + #13#10;
        until (s = '~');
        end
      else
      if (g = '#END') then
        begin
        note := GNote.Create();

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

  until (af.eof());

  af.Free();
end;

procedure save_notes();
var 
	iterator : GIterator;
	f : textfile;
	note : GNote;
	i : integer;
begin
  for i:=1 to BOARD_MAX-1 do
    begin
    assignfile(f, translateFileName('boards\' + board_names[i] + '.brd'));
    rewrite(f);

    iterator := notes.iterator();

    while (iterator.hasNext()) do
      begin
			note := GNote(iterator.next());

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
			end;
			
		iterator.Free();

    closefile(f);
    end;
end;

function findNote(board, number : integer) : GNote;
var 
	iterator : GIterator;
	note : GNote;
begin
  Result := nil;

	iterator := notes.iterator();

	while (iterator.hasNext()) do
		begin
		note := GNote(iterator.next());

    if (note.board = board) and (note.number = number) then
      begin
      Result := note;
      exit;
      end;
    end;
    
	iterator.Free();
end;

function noteNumber(board : integer) : integer;
var
	iterator : GIterator;
	note : GNote;
	number : integer;
begin
  number := 0;
	iterator := notes.iterator();

	while (iterator.hasNext()) do
		begin
		note := GNote(iterator.next());

    if (note.board = board) and (note.number > number) then
      number := note.number;
    end;
    
	iterator.Free();

  Result := number + 1;
end;

procedure postNote(c : pointer; const text : string);
var
	note : GNote;
  ch : GPlayer;
begin
  ch := c;

  note := GNote.Create();

  note.board := ch.active_board;
  note.number := noteNumber(ch.active_board);
  note.date := DateTimeToStr(Now);
  note.author := ch.name;
  note.subject := ch.subject;
  note.text := text;

  notes.insertLast(note);
  save_notes;
end;

procedure initNotes();
begin
  notes := GDLinkedList.Create();
end;

procedure cleanupNotes();
begin
  notes.clean();
  notes.Free();
end;

end.
