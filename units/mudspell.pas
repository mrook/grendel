unit mudspell;

interface

uses
  SysUtils,
  Classes;


Const
   MaxWordLength = 30;
   WordDelimiters: set of Char = [#0..#255] - ['a'..'z','A'..'Z','1'..'9','0'];

type
  TDictWords = string[MaxWordLength];


  TNZCSSpellCheck = class
  private
    FileOpen: Boolean;
    FSoundexLength: Integer;
    fdictfile: file of TDictWords;
    FDictionary: TFileName;
    FCustomDictionary: TFileName;
    FIgnoreAll: TStringList;
    FCustomDicList: TStringList;
    FWordCount: Integer;
    procedure SetDictionary(Value: TFileName);
    procedure SetCustomDictionary(Value: TFileName);
    procedure SetIgnoreAll(Value: TStringList);
    procedure CloseDict;
    function StripWord(const Key: String): String;
  protected
    DictIndex: array[1..26] of Integer;
  public
     Cancelled: Boolean;
     function FindCustomDic: String;
     function SetCase(WrongWord, Word: String): String;
     procedure CustomDictAdd(Key: String);
     Procedure ClearIgnoreAll;
     Procedure IgnoreAllAdd(Key: String);
     procedure CompileFile(const Fn: array of String);
     function FindByIndex(Idx: Integer): TDictWords;
     function OpenFile : boolean;
     function Soundex(Str: string): String;
     constructor Create;
     destructor Destroy; override;
     function CheckWord(key:string):boolean;
     property WordCount: Integer read FWordCount write FWordCount;
  published
    property Dictionary: TFileName read FDictionary write SetDictionary;
    property CustomDictionary: TFileName read FCustomDictionary write SetCustomDictionary;
    property SoundexLength: Integer read FSoundexLength write FSoundexLength default 6;
  end;

function StripDelimiter(const Delimiters, xString: STRING): string;

function checkWords(s : string) : boolean;

var
   misspelled_words : string;

implementation

uses
    mudsystem,
    util;

// Utility //
function GetChar(Value: String; index: smallint): Char;
begin
   if Length(Value) < index then result := #0 else Result := Value[index];
end;

function AsChar(Value: String): Char;
begin
  result := GetChar(Value,1);
end;

Function Same(xString1, xString2: String): Boolean;
begin
   result := (CompareText(xString1, xString2) = 0);
end;

function PropperCase (strInt: STRING): string;
var
   strOut: string;
   iPos: Integer;
begin
   strInt := LowerCase(strInt);
   strOut := UpperCase(Copy(strInt, 1, 1));
   for iPos := 2 to Length(strInt) do begin
      if ((Copy(strInt, iPos - 1, 1) = ' ') and
      (UpperCase(copy(strInt, iPos, 1)) <> copy(strInt, iPos, 1)))
      then
         strOut := strOut + UpperCase(copy(strInt, iPos, 1))
      else
         strOut := strOut + Copy(strInt, iPos, 1);
   end;
   result :=  strOut;
end;

function AppPath: string; {Appliction Exe Path}
var
   TmpPath: string;
begin
   TmpPath := ExtractFilePath(paramstr(0));
   if (TmpPath <> '') and (TmpPath[Length(TmpPath)] <> '\') then
      TmpPath := TmpPath + '\';
   Result := TmpPath;
end;

function StripDelimiter(const Delimiters, xString: STRING): string;
var
   i: Integer;
begin
   Result := xString;
   i := 1;
   While i <= length(Result) do begin
      If IsDelimiter(Delimiters,Result,i) then
         Delete(Result,i,1)
      else
         inc(i);
   end;
end;

{ TNZCSSpellCheck }

constructor TNZCSSpellCheck.Create;
begin
   Inherited Create;
   FIgnoreAll := TStringList.Create;
   Cancelled := False;
   FCustomDicList := TStringList.Create;
   FSoundExLength := 6;
end;

destructor TNZCSSpellCheck.Destroy;
begin
   CloseDict;
   FIgnoreAll.Free;
   FIgnoreAll := nil;
   FCustomDicList.Free;
   FCustomDicList := nil;

   Inherited Destroy;
end;

Function TNZCSSpellCheck.StripWord(const Key: String): String;
var
   TmpKey: String;

Function LeftHardTrim(S: String): String;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and ((S[I] <= ' ') or (IsDelimiter(':;()-_=+=\|/.,~`[]{}!?''"<>',S,I))) do Inc(I);
  Result := Copy(S, I, Maxint);
end;

Function RightHardTrim(S: String): String;
var
  I: Integer;
begin
  I := Length(S);
  while (I > 0) and ((S[I] <= ' ') or (IsDelimiter(':;()-_=+=\|/.,~`[]{}"''!?<>',S,I))) do Dec(I);
  Result := Copy(S,1, I);
end;

Function StripComments(Str, StartChar, FinishChar: String): String;
var
   st,en: longint;
begin
   While Pos(StartChar, Str) > 0 do begin
      St := Pos(StartChar, Str);
      en := Pos(FinishChar, Str);
      If st > en then begin // If no closing brack then exit //
         Result := Str;
         break;
      end;
      Str := Copy(Str,1, st-1) + Copy(Str,en + length(FinishChar), length(str));
   end;
   Result := Str;
end;


begin
   Result := Key;

      Result := StripComments(Result, '{', '}');
      Result := StripComments(Result, '(', ')');
      Result := StripComments(Result, '[', ']');

   Result := LeftHardTrim(RightHardTrim(Result));

      TmpKey := StripDelimiter('0123456789-.' + DateSeparator,Key);
      If (TmpKey = '') or ((Lowercase(TmpKey) = 'st') and (key <> TmpKey)) or
         ((Lowercase(TmpKey) = 'nd') and (key <> TmpKey)) or
         ((Lowercase(TmpKey) = 'rd') and (key <> TmpKey)) or
         ((Lowercase(TmpKey) = 'th') and (key <> TmpKey)) then
         result := '';
      If (Uppercase(TmpKey) = 'II') or (Uppercase(TmpKey) = 'III') or (Uppercase(TmpKey) = 'IV') or
         (Uppercase(TmpKey) = 'V') or (Uppercase(TmpKey) = 'VI') or (Uppercase(TmpKey) = 'VII') or
         (Uppercase(TmpKey) = 'VIII') or (Uppercase(TmpKey) = 'IX') or (Uppercase(TmpKey) = 'X') or
         (Uppercase(TmpKey) = 'XI') then
         result := '';

   //Result := StripLastIfDelimter(
   If result <> '' then
      Result := Uppercase(StripDelimiter('.',result));
end;


function TNZCSSpellCheck.CheckWord(key: string): boolean;
Var
   DictWord: TDictWords;
   DIndx, StartIdx, HighIdx, Mid: Integer;
begin
   result := True;
   Key := StripWord(Trim(Key));
   If (Key = '') or (FIgnoreAll.IndexOf(Key) <> -1) then begin
      Exit;
   end;
   // Get the upper case ascii value of the first letter
   DIndx := Ord(AsChar(Key)) - 64;
   If (DIndx > 0) and (DIndx < 27) then begin
      result := False;
      OpenFile;
      // First check the custom dictionary //
      If FCustomDicList.IndexOf(Key) <> -1 then begin
         result := True;
         Exit;
      end;
      HighIdx := WordCount;
      // Get the position of the first word in our distionary starting with the words first letter //
      StartIdx := DictIndex[DIndx];
      // Unless the word starts with Z get the next letters starting position //
      If Dindx < 26 then
         HighIdx := DictIndex[DIndx+1];
      // Divide into two to make the search 50% fast if the word is at either end //
      If (StartIdx > WordCount) or (StartIdx < 0) then
         StartIdx := WordCount div 2;
      // Go up or down the file until we get to the end or find the word //
      while (StartIdx <= HighIdx) do begin
         Mid := (HighIdx+StartIdx) div 2;
         Seek(fdictfile, mid);
         Read(fdictfile, DictWord);
         If Key = DictWord then begin
            result := True;
            Break;
         end;
         if (DictWord > key) then
            HighIdx := mid-1
         else
            StartIdx := mid+1;
      end;
   end;
end;

Function TNZCSSpellCheck.SetCase(WrongWord, Word: String): String;
begin
   If WrongWord = Lowercase(WrongWord) then
      result := Lowercase(Word)
   else begin
      If WrongWord = Uppercase(WrongWord) then
         result := uppercase(Word)
      else begin
         result := PropperCase(Word);
      end;
   end;
end;

function TNZCSSpellCheck.OpenFile : boolean;
var
   i: Integer;
   FLoadIdx: TStringList;
begin
   Result := false;
   If FileOpen then Exit;
   FileOpen := False;
   If FDictionary = '' then
      FDictionary := AppPath + 'english.dic';

   AssignFile(fdictfile, FDictionary);
   {Set FileMode for Read/Write};
   FileMode := 2;
   try
     Reset(fdictfile);
   except
     exit;
   end;

   FWordCount := FILESIZE(fdictfile);
   FLoadIdx := TStringList.Create;
   If FileExists(ChangeFileExt(FDictionary,'.idx')) then
      FLoadIdx.LoadFromFile(ChangeFileExt(FDictionary,'.idx'));
   For i := 0 to 25 do begin
      If i > FLoadIdx.Count - 1 then
         DictIndex[i+1] := (FILESIZE(fdictfile) div 26) * i
      else
         DictIndex[i+1] := StrToIntDef(Copy(FLoadIdx[i],3,MaxInt),0);
   end;
   FLoadIdx.Free;
   FCustomDicList.Clear;
   If (FCustomDictionary <> '') and FileExists(FCustomDictionary) then
      FCustomDicList.LoadFromFile(FCustomDictionary);

   Result := true;
   FileOpen := True;
end;

Procedure TNZCSSpellCheck.CloseDict;
begin
   If FileOpen then begin
      {$i-}
      CloseFile(fdictfile);
      {$i+}
      if ioresult <> 0 then;
         FileOpen := False;
   end;
end;

Function TNZCSSpellCheck.FindByIndex(Idx: Integer): TDictWords;
begin
   result := '';
   //result.Soundex := '';
   OpenFile;
   If not FileOpen then Exit;
   If (Idx <= FWordCount) and (idx >= 0) then begin
      Seek(fdictfile, Idx);
      If not EOF(fdictfile) then
         Read(fdictfile, result);
   end;
end;

// Create a dictionary file and an index file //

{NZCSSpellCheck := TNZCSSpellCheck.Create(Application);
   NZCSSpellCheck.CompileFile(['f:\spell\Compile\Words1.lst', 'f:\spell\Compile\Words2.lst',
   'f:\spell\Compile\Words2.lst','f:\spell\Compile\Words4.lst']);
   NZCSSpellCheck.Free;}

Procedure TNZCSSpellCheck.CompileFile(const Fn: array of String);
var
   WordList: TStringList;
   TmpList: TStringList;
   DictWords: TDictWords;
   LastLetter: String[1];
   i: Integer;
begin
   CloseDict;
   If FDictionary = '' then
      FDictionary := AppPath + 'english.dic';
   AssignFile(fdictfile, FDictionary);
   {Set FileMode for Read/Write};
   FileMode := 2;
   Rewrite(fdictfile);
   FileOpen := True;
   WordList := TStringList.Create;
   TmpList := TStringList.Create;
   For i := 0 to High(Fn) do begin
      TmpList.LoadFromFile(Fn[i]);
      WordList.AddStrings(TmpList);
      TmpList.Clear;
   end;
   TmpList.Clear;
   //WordList.Sort;
   Seek(fdictfile, 0);
   For i := 0 to WordList.Count - 1 do begin
      DictWords := Uppercase(WordList[i]);
      //DictWords.Soundex := Soundex(WordList[i]);
      Seek(fdictfile, FileSize(fdictfile));
      Write(fdictfile, DictWords);
      If LastLetter <> Copy(DictWords,1,1) then begin
         LastLetter := Copy(DictWords,1,1);
         TmpList.Add(LastLetter + '=' + IntToStr(i));
      end;
   end;
   TmpList.SaveToFile(ChangeFileExt(FDictionary,'.idx'));
   CloseDict;
   WordList.Clear;
   WordList.Free;
   TmpList.Free;
end;

// Find words like //
function TNZCSSpellCheck.Soundex(Str: string): String;
var  temp : string;              {temporary adjusted target token}
        i : integer;             {index counter}
   digraph: String;

{This function inspects a two character string and encodes digraphs }
function checkdigraph(pair:string):string;
var   index : integer;
begin
   {dig string looks like: /aa=b/cc=d/ee=f}
   index := pos('/'+uppercase(pair),digraph);
   if index = 0 then
      checkdigraph := pair
   else
      checkdigraph := digraph[index+4];
end;

{This procedure checks for special cases for the first two characters}
procedure checkfirst;
begin
   i := 2;
   temp := checkdigraph(copy(Str,1,2));
   if length(temp) = 2 then         {i.e. it wasn't a digraph}
      temp := Copy(temp,1,1)  {just keep the first char}
   else
      i := 3;       {skip second char for encode}
end;

{This procedure checks for special cases for the last two characters}
procedure checklast;
var
   twochar : string[2];
begin
   twochar := copy(Str,length(Str)-1,2);
   if length(Str) > i+2 then
      temp := temp + checkdigraph(twochar)
   else
      temp := temp + twochar;
end;

 {This function returns the soundex code for a given character}
function encodechar(aChar:char):char;
begin
   case upCase(aChar) of
   'A','E','H','I','O','U','W','Y' : encodechar := '0';
   'B','F','P','V'                 : encodechar := '1';
   'C','G','J','K','Q','S','X','Z' : encodechar := '2';
   'D','T'                         : encodechar := '3';
   'L'                             : encodechar := '4';
   'M','N'                         : encodechar := '5';
   'R'                             : encodechar := '6';
   end;
end;

{This procedure sets up the temp version of the target token]}
procedure InitializeTemp;
begin;
   CheckFirst;     {checks for leading digraph; inits temp and i}
   temp := temp + copy(Str,i,length(Str)-(i+1));
   CheckLast;      {checks for trailing digraph; completes temp}
end;

{--------------------------------------------------------------------------}
{Soundexer Function Main Code                                                }
{--------------------------------------------------------------------------}
begin
   digraph  := '/GH=F/LD=D/PH=F';
   InitializeTemp;  {initialzes temp string and starting point}
   {convert temp string to soundex string}
   for i := 2 to length(temp) do
      temp[i] := encodechar(temp[i]);
   {remove doublecodes and vowels; truncate at codemax}
   Result := UpperCase(copy(temp,1,1)); {first character is always kept}
   i    := 2;
   while (length(Result) <  SoundExLength) and (i <= length(temp)) do begin
      if (temp[i] <> '0') and (temp[i] <> temp[i-1]) then
         Result := Result + temp[i];
      inc(i);
   end;
   Result := Result + '000000000000000000000000000000000000';
   Result := Copy(Result,1,SoundExLength);
end;


procedure TNZCSSpellCheck.SetDictionary(Value: TFileName);
begin
   If FDictionary <> Value then begin
      CloseDict;
      FDictionary := Value;
   end;
end;

procedure TNZCSSpellCheck.SetIgnoreAll(Value: TStringList);
begin
   FIgnoreAll.Assign(Value);
end;

//To do //
{Find Uncapitalized Start of Sentence
Find Repeated Words}

{
Ignore Numbers: e.g., 1-800-266-5626
Ignore Ordinals: e.g., 1st, 2nd, 3rd
Ignore Roman Numerals, e.g., IV, VII - Needs work but who uses Roman Numerals anyway
Ignore Parentheses in Words: e.g., sales(wo)man, shoe(s)
}

procedure TNZCSSpellCheck.SetCustomDictionary(Value: TFileName);
begin
   If FCustomDictionary <> Value then begin
      CloseDict;
      FCustomDictionary := value;
   end;
end;

procedure TNZCSSpellCheck.ClearIgnoreAll;
begin
   FIgnoreAll.Clear;
end;

procedure TNZCSSpellCheck.IgnoreAllAdd(Key: String);
begin
   If FIgnoreAll.IndexOf(Key) = -1 then begin
      FIgnoreAll.Add(Key);
   end;
end;

procedure TNZCSSpellCheck.CustomDictAdd(Key: String);
begin
   If FCustomDicList.IndexOf(key) = -1 then begin
      FCustomDicList.Add(Key);
      FCustomDicList.Sort;
      If FCustomDictionary = '' then
         CustomDictionary := FindCustomDic;
      FCustomDicList.SaveToFile(FCustomDictionary);
   end;
end;

function TNZCSSpellCheck.FindCustomDic: String;
const
   AppDataPath = 'Microsoft\Proof\Custom.Dic';
   AppDataKey = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders';
   Win95Cust = 'SOFTWARE\Microsoft\Shared Tools\Proofing Tools\Custom Dictionaries';
   Win95Def = 'C:\Program Files\Common Files\Microsoft Shared\Proof\';
var
   AddDataDir: String;
begin
   // If Win98 / NT / 2000 then get the AppData directory

   If (AddDataDir <> '') and FileExists(AddDataDir + AppDataPath) then
      result := AddDataDir + AppDataPath;
end;

var
   spell : TNZCSSpellCheck;
   enabled : boolean;

function checkWords(s : string) : boolean;
var
   temp, sub : string;
begin
  Result := true;
  misspelled_words := '';

  if (not enabled) then
    exit;

  temp := s;

  while (length(temp) > 0) do
    begin
    temp := one_argument(temp, sub);

    if (sub <> '') then
      begin
      if (not spell.checkWord(sub)) then
        begin
        if (pos(sub, misspelled_words) = 0) then
          misspelled_words := misspelled_words + sub + ' ';

        Result := false;
        end;
      end;
    end;
end;

begin
  spell := TNZCSSpellCheck.Create;
  enabled := spell.OpenFile;

  if (not enabled) then
    write_console('Could not open dictionary, spell checking is disabled.')
  else
    spell.CustomDictionary := 'custom.dic';

  spell.CustomDictAdd('Southaven');
end.
