// $Id: dtypes.pas,v 1.11 2001/04/27 14:14:43 ***REMOVED*** Exp $

unit dtypes;

interface

uses
    SysUtils,
    SyncObjs;

type
    GString = class
      refcount : integer;
      value : string;

      constructor Create(s : string);
    end;

    GInteger = class
      value : integer;

      constructor Create(s : integer);
    end;
    
    GListNode = class
      prev, next : GListNode;
      element : pointer;
      refcount : integer;

      constructor Create(e : pointer; p, n : GListNode);
    end;

    GDLinkedList = class
      size : integer;
      head, tail : GListnode;
      lock : TCriticalSection;

      function insertLast(element : pointer) : GListNode;
      function insertAfter(tn : GListNode; element : pointer) : GListNode;
      function insertBefore(tn : GListNode; element : pointer) : GListNode;
      procedure remove(node : GListNode);
      procedure clean;
      procedure smallClean;

      function getSize : integer;

      constructor Create;
      destructor Destroy; override;
    end;

    GPrimes = array of integer;

    GHASH_FUNC = function(size, prime : cardinal; key : string) : integer;

    GHashValue = class
      key : string;
      refcount : integer;
      value : TObject;
    end;

    // loosely based on the Java2 hashing classes
    GHashTable = class
      hashsize : cardinal;
      hashprime : cardinal;

      bucketList : array of GDLinkedList;

      hashFunc : GHASH_FUNC;

      procedure clear();

//      function containsKey(key : string) : boolean;
//      function containsValue(value : TObject) : boolean;
      function isEmpty() : boolean;
      function size() : integer;

      function _get(key : string) : GHashValue;

      function get(key : string) : TObject;
      procedure put(key : string; value : TObject);
      procedure remove(key : string);

      function getHash(key : string) : integer;
      procedure setHashFunc(func : GHASH_FUNC);
      function findPrimes(n : integer) : GPrimes;

      procedure hashStats; virtual;

      constructor Create(size : integer);
      destructor Destroy; override;
    end;

    GException = class(Exception)
      e_location : string;

      constructor Create(location, msg : string);
      procedure show;
    end;

const STR_HASH_SIZE = 1024;

var
   str_hash : GHashTable;

function hash_string(src : string) : PString; overload;
function hash_string(src : PString) : PString; overload;

procedure unhash_string(var src : PString);

function defaultHash(size, prime : cardinal; key : string) : integer;
function firstHash(size, prime : cardinal; key : string) : integer;

implementation

{$IFDEF Grendel}
uses
    mudsystem;
{$ENDIF}

// GString
constructor GString.Create(s : string);
begin
  inherited Create;

  value := s;
end;

// GInteger
constructor GInteger.Create(s : integer);
begin
  inherited Create;

  value := s;
end;

// GListNode
constructor GListNode.Create(e : pointer; p, n : GListNode);
begin
  inherited Create;

  element := e;
  next := n;
  prev := p;
  refcount := 1;
end;


// GDLinkedList
constructor GDLinkedList.Create;
begin
  inherited Create;

  head := nil;
  tail := nil;
  size := 0;
  lock := TCriticalSection.Create;
end;

destructor GDLinkedList.Destroy;
begin
  lock.Free;

  inherited Destroy;
end;

function GDLinkedList.insertLast(element : pointer) : GListNode;
var
   node : GListNode;
begin
  try
    lock.Acquire;

    node := GListNode.Create(element, tail, nil);

    if (head = nil) then
      head := node
    else
      tail.next := node;

    tail := node;

    insertLast := node;

    inc(size);
  finally
    lock.Release;
  end;
end;

function GDLinkedList.insertAfter(tn : GListNode; element : pointer) : GListNode;
var
   node : GListNode;
begin
  try
    lock.Acquire;

    node := GListNode.Create(element, tn, tn.next);

    if (tn.next <> nil) then
      tn.next.prev := node;

    tn.next := node;

    if (tail = tn) then
      tail := node;

    insertAfter := node;

    inc(size);
  finally
    lock.Release;
  end;
end;

function GDLinkedList.insertBefore(tn : GListNode; element : pointer) : GListNode;
var
   node : GListNode;
begin
  try
    lock.Acquire;

    node := GListNode.Create(element, tn.prev, tn);

    if (tn.prev <> nil) then
      tn.prev.next := node;
      
    tn.prev := node;

    if (head = tn) then
      head := node;

    insertBefore := node;

    inc(size);
  finally
    lock.Release;
  end;
end;

procedure GDLinkedList.remove(node : GListNode);
begin
  try
    lock.Acquire;

    if (node.prev = nil) then
      head := node.next
    else
      node.prev.next := node.next;

    if (node.next = nil) then
      tail := node.prev
    else
      node.next.prev := node.prev;

    dec(size);
    node.Free;
  finally
    lock.Release;
  end;
end;

function GDLinkedList.getSize : integer;
begin
  getSize := size;
end;

procedure GDLinkedList.clean;
var
   node : GListNode;
begin
  while (true) do
    begin
    node := tail;

    if (node = nil) then
      exit;

    TObject(node.element).Free;

    remove(node);
    end;
end;

// doesn't free elements
procedure GDLinkedList.smallClean;
var
   node : GListNode;
begin
  while (true) do
    begin
    node := head;

    if (node = nil) then
      exit;

    remove(node);
    end;
end;


// GHashTable
function defaultHash(size, prime : cardinal; key : string) : integer;
var
   i : integer;
   val : cardinal;
begin
  val := 0;

  for i := 1 to length(key) do
    val := val * prime + byte(key[i]);

  defaultHash := val mod size;
end;

function firstHash(size, prime : cardinal; key : string) : integer;
begin
  if (length(key) >= 1) then
    Result := (byte(key[1]) * prime) mod size
  else
    Result := 0;
end;


function GHashTable.findPrimes(n : integer) : GPrimes;
var
   i, j : integer;
   limit : double;
   numbers : GPrimes;
   numberpool : array of boolean;
begin
  setlength(numberpool, n);

  for i := 2 to n - 1 do
    numberpool[i] := true;

  limit := sqrt(n);

  j := 2;

  i := j + j;

  while (i < n) do
    begin
    numberpool[i] := false;
    i := i + j;
    end;

  j := 3;

  while (j <= limit) do
    begin
    if (numberpool[j] = true) then
      begin
      i := j + j;

      while (i < n) do
        begin
        numberpool[i] := false;

        i := i + j;
        end;
      end;

    j := j + 2;
    end;

  j := 0;

  for i := 0 to n - 1 do
    begin
    if (numberpool[i]) then
      begin
      setLength(numbers, j + 1);
      numbers[j] := i;
      j := j + 1;
      end;
    end;

  findPrimes := numbers;
end;

function GHashTable.getHash(key : string) : integer;
begin
  Result := hashFunc(hashsize, hashprime, key);
end;

procedure GHashTable.setHashFunc(func : GHASH_FUNC);
begin
  hashFunc := func;
end;

function GHashTable._get(key : string) : GHashValue;
var
  hash : integer;
  node : GListNode;
begin
  Result := nil;

  hash := getHash(key);

  node := bucketList[hash].head;

  while (node <> nil) do
    begin
    if (GHashValue(node.element).key = key) then
      begin
      Result := node.element;
      break;
      end;

    node := node.next;
    end;
end;

function GHashTable.get(key : string) : TObject;
var
  hv : GHashValue;
begin
  Result := nil;

  hv := _get(key);

  if (hv <> nil) then
    Result := hv.value;
end;

procedure GHashTable.put(key : string; value : TObject);
var
   hash : integer;
   hv : GHashValue;
begin
  hv := _get(key);

  if (hv <> nil) then
    begin
    inc(hv.refcount);
    end
  else
    begin
    hash := getHash(key);

    hv := GHashValue.Create;
    hv.refcount := 1;
    hv.key := key;
    hv.value := value;

    bucketList[hash].insertLast(hv);
    end;
end;

procedure GHashTable.remove(key : string);
var
  hash : integer;
  fnode, node : GListNode;
begin
  fnode := nil;
  hash := getHash(key);

  node := bucketList[hash].head;

  while (node <> nil) do
    begin
    if (GHashValue(node.element).key = key) then
      begin
      fnode := node.element;
      break;
      end;

    node := node.next;
    end;
end;

function GHashTable.size() : integer;
var
   i : integer;
   total : integer;
begin
  total := 0;

  for i := 0 to hashsize - 1 do
    begin
    total := total + bucketList[i].getSize;
    end;

  Result := total;
end;

function GHashTable.isEmpty() : boolean;
begin
  Result := size() = 0;
end;

procedure GHashTable.hashStats;
var
   i : integer;
   total : integer;
   load : single;
   min, max : integer;
begin
  total := 0;
  min := 65536;
  max := 0;

  for i := 0 to hashsize - 1 do
    begin
    total := total + bucketList[i].getSize;

    if (bucketList[i].getSize < min) then
      min := bucketList[i].getSize;
    if (bucketList[i].getSize > max) then
      max := bucketList[i].getSize;
    end;

  load := total / hashsize;

  writeln('Hash size ' + inttostr(hashsize) + ' with key ' + inttostr(hashprime));
  writeln('Total hash items : ' + inttostr(total));
  writeln('Load factor : ' + floattostrf(load, ffFixed, 7, 4));
end;

procedure GHashTable.clear();
var
   i : integer;
begin
  for i := 0 to hashsize - 1 do
    begin
    bucketList[i].clean;
    end;
end;

constructor GHashTable.Create(size : integer);
var
   n : integer;
   primes : GPrimes;
begin
  inherited Create;

  primes := findPrimes(size + 32);

  randomize;
  hashsize := primes[length(primes) - 1];
  hashprime := primes[random(length(primes))];

  setlength(bucketList, hashsize);

  for n := 0 to hashsize - 1 do
    bucketList[n] := GDLinkedList.Create;

  hashFunc := defaultHash;
end;

destructor GHashTable.Destroy;
var
   n : integer;
begin
  for n := 0 to hashsize - 1 do
    begin
    bucketList[n].clean;
    bucketList[n].Free;
    end;

  setlength(bucketList, 0);

  inherited Destroy;
end;

// GHashString
{ procedure GHashString.hashString(str : GString; key : string);
begin
  hashPointer(str, key);
end;

procedure GHashString.hashStats;
var
   bytesused, wouldhave : integer;
   i, s : cardinal;
   node : GListNode;
begin
  inherited hashStats;

  bytesused := 0;
  wouldhave := 0;

  for i := 0 to hashsize - 1 do
    begin
    node := bucketList[i].head;

    while (node <> nil) do
      begin
      s := length(GString(node.element).value);

      bytesused := bytesused + (s + 1);
      wouldhave := wouldhave + (node.refcount * (s + 1));

      node := node.next;
      end;
    end;

  writeln('Byte savings (used/saved): ', inttostr(bytesused), '/', inttostr(wouldhave - bytesused), ' (', (bytesused * 100) div wouldhave, '%/', ((wouldhave - bytesused) * 100) div wouldhave, '%)');
end; }

function hash_string(src : string) : PString;
var
  hv : GHashValue;
  g : GString;
begin
  hv := str_hash._get(src);

  if (hv <> nil) then
    begin
    hash_string := @GString(hv.value).value;
    inc(hv.refcount);
    end
  else
    begin
    g := GString.Create(src);

    str_hash.put(src, g);

    hash_string := @g.value;
    end;
end;

function hash_string(src : PString) : PString;
var
  hv : GHashValue;
  g : GString;
begin
  hv := str_hash._get(src^);

  if (hv <> nil) then
    begin
    hash_string := @GString(hv.value).value;
    inc(hv.refcount);
    end
  else
    begin
    g := GString.Create(src^);

    str_hash.put(src^, g);

    hash_string := @g.value;
    end;
end;

procedure unhash_string(var src : PString);
var
  hv : GHashValue;
  g : GString;
begin
  if (src = nil) then
    exit;

  hv := str_hash._get(src^);

  if (hv <> nil) then
    begin
    dec(hv.refcount);

    if (hv.refcount <= 0) then
      begin
      hv.value.Free;
      str_hash.remove(src^);
      end;

    src := nil;
    end;
end;

// GException
constructor GException.Create(location, msg : string);
begin
  inherited Create(msg);
end;

procedure GException.show;
begin
{$IFDEF Grendel}
  write_console('Exception ' + Message + ' @ ' + e_location);
{$ELSE}
  writeln('Exception ' + Message + ' @ ' + e_location);
{$ENDIF}
end;

begin
  str_hash := GHashTable.Create(STR_HASH_SIZE);
end.

