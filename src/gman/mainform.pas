unit mainform;

interface

uses
	WSDLIGrendelWebService,
	WSDLISOAPAuthenticator,
  SysUtils, Types, Classes, Variants, QTypes, QGraphics, QControls, QForms,
  QDialogs, QStdCtrls, QGrids, QComCtrls, QMenus,
  area, InvokeRegistry, Rio, SOAPHTTPClient, QExtCtrls;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    DrawGrid1: TDrawGrid;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Edit2: TEdit;
    Label3: TLabel;
    Edit3: TEdit;
    Edit4: TEdit;
    Button1: TButton;
    Label4: TLabel;
    Label5: TLabel;
    Edit5: TEdit;
    Label6: TLabel;
    Edit6: TEdit;
    Label7: TLabel;
    Edit7: TEdit;
    GroupBox3: TGroupBox;
    Edit8: TEdit;
    Button2: TButton;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Button3: TButton;
    Button4: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    GroupBox4: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    GroupBox5: TGroupBox;
    Edit9: TEdit;
    Label11: TLabel;
    Memo1: TMemo;
    GroupBox6: TGroupBox;
    DebugMemo: TMemo;
    Label8: TLabel;
    Label12: TLabel;
    Edit10: TEdit;
    Edit11: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    Edit12: TEdit;
    Timer1: TTimer;
    GroupBox7: TGroupBox;
    Button5: TButton;
    TrackBar1: TTrackBar;
    Label15: TLabel;
    CheckBox1: TCheckBox;
    procedure Exit1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DrawGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure DrawGrid1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Button2Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    
    procedure connect();
    procedure disconnect();

    function getSOAPAuthenticator() : ISOAPAuthenticator;
    function getGrendelWebService() : IGrendelWebService;

    procedure updateConsole();
    procedure updateFromArea(area : GArea);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.xfm}

uses
	skills,
  console,
  conns,
  chars,
	constants,
	dtypes,
  progs,
	race;

var
	extents_lo, extents_hi : GCoords;
  cells : array[0..100,0..100] of GRoom;

procedure createCoordinates(startroom : GRoom);
var
  iterator : GIterator;
  room : GRoom;
  ex : GExit;
begin
	if (startroom.areacoords.x < extents_lo.x) then
  	extents_lo.x := startroom.areacoords.x;
	if (startroom.areacoords.y < extents_lo.y) then
  	extents_lo.y := startroom.areacoords.y;
	if (startroom.areacoords.z < extents_lo.z) then
  	extents_lo.z := startroom.areacoords.z;

 	if (startroom.areacoords.x > extents_hi.x) then
  	extents_hi.x := startroom.areacoords.x;
	if (startroom.areacoords.y > extents_hi.y) then
  	extents_hi.y := startroom.areacoords.y;
	if (startroom.areacoords.z > extents_hi.z) then
  	extents_hi.z := startroom.areacoords.z;

  cells[startroom.areacoords.x,startroom.areacoords.y] := startroom;

  iterator := startroom.exits.iterator();

  while (iterator.hasNext()) do
    begin
    ex := GExit(iterator.next());

    room := GRoom(room_list[ex.vnum]);

    if (room = nil) then
    	continue;

    if (room.areacoords = nil) then
      begin
      room.areacoords := GCoords.Create(startroom.areacoords);
      case ex.direction of
        DIR_NORTH:
          begin
            dec(room.areacoords.y);
          end;
        DIR_EAST:
          begin
            dec(room.areacoords.x);
          end;
        DIR_SOUTH:
          begin
            inc(room.areacoords.y);
          end;
        DIR_WEST:
          begin
            inc(room.areacoords.x);
          end;
        DIR_DOWN:
          begin
            inc(room.areacoords.z);
          end;
        DIR_UP:
          begin
            dec(room.areacoords.z);
          end;
      end;

      createCoordinates(room);
      end;
    end;

  iterator.Free();
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Close();
end;

procedure TForm1.updateFromArea(area : GArea);
var
	room : GRoom;
begin
	Edit1.Text := area.name;
  Edit2.Text := area.author;
  Edit3.Text := area.resetmsg;
  Edit4.Text := IntToStr(area.flags.value);
  Edit5.Text := IntToStr(area.maxage);
  Edit6.Text := IntToStr(area.weather.temp_avg);
  Edit7.Text := IntToStr(area.weather.temp_mult);

  room := GRoom(area.rooms.head.element);

  room.areacoords := GCoords.Create();
  room.areacoords.x := 15;
  room.areacoords.y := 15;
  room.areacoords.z := 0;

  extents_lo := GCoords.Create(room.areacoords);
  extents_hi := GCoords.Create(room.areacoords);

  createCoordinates(room);

	Label10.Caption := IntToStr(extents_lo.x) + ',' + IntToStr(extents_lo.y) + ',' + IntToStr(extents_lo.z) + ' - ' +
  										IntToStr(extents_hi.x) + ',' + IntToStr(extents_hi.y) + ',' + IntToStr(extents_hi.z);

  DrawGrid1.Col := (extents_lo.x + extents_hi.x) div 2;
  DrawGrid1.Row := (extents_lo.y + extents_hi.y) div 2;
  DrawGrid1.Invalidate();
end;

procedure TForm1.Button3Click(Sender: TObject);
var
	area : GArea;
begin
  if (OpenDialog1.Execute()) then
  	begin
    area := GArea.Create();
    area.load(OpenDialog1.FileName);

    processAreas();
    
    updateFromArea(area);
    end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  initAreas();
  initRaces();
  initSkills();
  initConns();
  initChars();
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  cleanupSkills();
	cleanupRaces();
	cleanupAreas();
{	cleanupChars(); }
	cleanupConns();
end;

procedure TForm1.DrawGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
	room : GRoom;
begin
	room := cells[ACol, ARow];

  if (room <> nil) then
  	begin
    case room.sector of
    	SECT_INSIDE: DrawGrid1.Canvas.Brush.Color := clBlack;
      SECT_CITY:	DrawGrid1.Canvas.Brush.Color := clMaroon;
      SECT_FIELD: DrawGrid1.Canvas.Brush.Color := clGreen;
      SECT_WATER_NOSWIM,
      SECT_WATER_SWIM: DrawGrid1.Canvas.Brush.Color := clNavy;
    else
    	DrawGrid1.Canvas.Brush.Color := clRed;
    end;

	  DrawGrid1.Canvas.FillRect(Rect);
    end;

{  if (State.Contains(gdFocused))
    DrawGrid1->Canvas->DrawFocusRect(Rect); }
end;

procedure TForm1.DrawGrid1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  Column, Row: Longint;
  room : GRoom;
begin
	DrawGrid1.MouseToCell(X, Y, Column, Row);

  room := cells[Column, Row];

  if (room <> nil) then
  	begin
    Edit9.Text := IntToStr(room.vnum);
    Memo1.Lines.Clear;
    Memo1.Lines.Add(room.description);
    GroupBox5.Visible := true;
    end
  else
  	begin
    GroupBox5.Visible := false;
    end;
end;

var
  connected : boolean = false;
  sessionHandle : WideString;
  timestamp : integer;

function TForm1.getSOAPAuthenticator() : ISOAPAuthenticator;
begin
  Result := getISOAPAuthenticator(False, 'http://' + Edit8.Text + ':' + Edit12.Text + '/soap/ISOAPAuthenticator')
end;

function TForm1.getGrendelWebService() : IGrendelWebService;
begin
  Result := getIGrendelWebService(False, 'http://' + Edit8.Text + ':' + Edit12.Text + '/soap/IGrendelWebService')
end;

procedure TForm1.connect();
var
	svc : ISOAPAuthenticator;
begin
	try
		if (not connected) then
			begin
			svc := getSOAPAuthenticator();;

   		connected := svc.login(Edit10.Text, Edit11.Text, sessionHandle);

			if (connected) then
				begin
				Button2.Caption := 'Disconnect';
				DebugMemo.Lines.Add('Login succesful (' + sessionHandle + '), connected');
				end
			else
				DebugMemo.Lines.Add('Login unsuccesful');
			end;
	except
		on E : Exception do
			DebugMemo.Lines.Add(E.Message);
	end;
end;

procedure TForm1.disconnect();
var
	svc : ISOAPAuthenticator;
begin
	try
		svc := getSOAPAuthenticator();
		
		if (connected) then
    	begin
			svc.logout(sessionHandle);
	    connected := false;
      end;
			
		Button2.Caption := 'Connect';
	except
		on E : Exception do
			DebugMemo.Lines.Add(E.Message);
	end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
	if (connected) then
		disconnect()
	else
		connect();
end;

procedure TForm1.updateConsole();
var
	svc : IGrendelWebService;
  strings : TStringArray;
  idx : integer;
begin
	try
		svc := getGrendelWebService();

		strings := svc.getConsoleHistory(sessionHandle, timestamp);

		for idx := Low(strings) to High(strings) do
		DebugMemo.Lines.Add(strings[idx]);
	except
  		on E : Exception do
  			begin
  			disconnect();
		  	DebugMemo.Lines.Add(E.Message);
		  	end;
	end;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
	if (connected) then
		updateConsole();
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  Timer1.Enabled := CheckBox1.Checked;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
	if (connected) then
		updateConsole();
end;

end.
