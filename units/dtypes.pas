// $Id: dtypes.pas,v 1.24 2001/09/02 21:53:02 ***REMOVED*** Exp $

unit dtypes;

interface

uses
    SysUtils,
    SyncObjs;

type
    GString = class
      value : string;

      constructor Create(s : string);
    end;

    GInteger = class
      value : integer;

      constructor Create(s : integer);
    end;

    GIterator = class
      function hasNext() : boolean; virtual; abstract;
      function next() : TObject; virtual; abstract;
    end;

    GListNode = class
      prev, next : GListNode;
      element : pointer;

      constructor Create(e : pointer; p, n : GListNode);
    end;

    GDLinkedList = class
      size : integer;
      head, tail : GListnode;
      lock : TCriticalSection;
      serial : integer;

      function insertLast(element : pointer) : GListNode;
      function insertAfter(tn : GListNode; element : pointer) : GListNode;
      function insertBefore(tn : GListNode; element : pointer) : GListNode;
      procedure remove(node : GListNode);
      procedure clean();
      procedure smallClean();

      function getSize() : integer;

      function iterator() : GIterator;

      constructor Create;
      destructor Destroy; override;
    end;

    GPrimes = array of integer;

    GHASH_FUNC = function(size, prime : cardinal; key : string) : cardinal;

    GHashValue = class
      key : variant;
      value : TObject;
      refcount : integer;
    end;

    // loosely based on the Java2 hashing classes
    GHashTable = class
      hashsize : cardinal;
      hashprime : cardinal;

      bucketList : array of GDLinkedList;

      hashFunc : GHASH_FUNC;

      procedure clear();

      function isEmpty() : boolean;
      function size() : integer;

      function iterator() : GIterator;

      function _get(key : variant) : GHashValue;

      function get(key : variant) : TObject;
      procedure put(key : variant; value : TObject);
      procedure remove(key : variant);

      function getHash(key : variant) : cardinal;
      procedure setHashFunc(func : GHASH_FUNC);
      function findPrimes(n : integer) : GPrimes;

      procedure hashStats(); virtual;

      constructor Create(size : integer);
      destructor Destroy; override;
    end;

const STR_HASH_SIZE = 1024;

var
   str_hash : GHashTable;

function hash_string(src : string) : PString; overload;
function hash_string(src : PString) : PString; overload;

procedure unhash_string(var src : PString);

function md5Hash(size, prime : cardinal; key : string) : cardinal;
function defaultHash(size, prime : cardinal; key : string) : cardinal;
function firstHash(size, prime : cardinal; key : string) : cardinal;

implementation

uses
{$IFDEF LINUX}
    Variants,
{$ENDIF}
    md5;


// GDLinkedListIterator
type
    GDLinkedListIterator = class(GIterator)
    private
      current : GListNode;

    published
      constructor Create(list : GDLinkedList);

      function hasNext() : boolean; override;
      function next() : TObject; override;
    end;

    GHashTableIterator = class(GIterator)
    private
      tbl : GHashTable;
      cursor : integer;
      current : GListNode;

    published
      constructor Create(table : GHashTable);

      function hasNext() : boolean; override;
      function next() : TObject; override;
    end;


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
end;

// GDLinkedListIterator
constructor GDLinkedListIterator.Create(list : GDLinkedList);
begin
  inherited Create;

  current := list.head;
end;

function GDLinkedListIterator.hasNext() : boolean;
begin
  Result := (current <> nil);
end;

function GDLinkedListIterator.next() : TObject;
begin
  Result := nil;

  if (hasNext()) then
    begin
    Result := current.element;

    current := current.next;
    end;
end;

// GHashTableIterator
constructor GHashTableIterator.Create(table : GHashTable);
begin
  inherited Create;

  tbl := table;

  current := nil;
  cursor := 0;

  while (current = nil) and (cursor < tbl.hashSize) do
    begin
    if (tbl.bucketlist[cursor].head <> nil) then
      begin
      current := tbl.bucketList[cursor].head;
      break;
      end;
      
    inc(cursor);
    end;
end;

function GHashTableIterator.hasNext() : boolean;
begin
  Result := (current <> nil);
end;

function GHashTableIterator.next() : TObject;
begin
  Result := nil;

  if (hasNext()) then
    begin
    Result := GHashValue(current.element).value;

    current := current.next;

    if (current = nil) then
      begin
      inc(cursor);

      while (current = nil) and (cursor < tbl.hashSize) do
        begin
        if (tbl.bucketlist[cursor].head <> nil) then
          begin
          current := tbl.bucketList[cursor].head;
          break;
          end;
      
        inc(cursor);
        end;
      end;
    end;
end;

// GDLinkedList
constructor GDLinkedList.Create;
begin
  inherited Create;

  head := nil;
  tail := nil;
  size := 0;
  serial := 1;
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
    inc(serial);
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

    inc(serial);
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

    inc(serial);
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
    inc(serial);
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

function GDLinkedList.iterator() : GIterator;
begin
  Result := GDLinkedListIterator.Create(Self);
end;


// GHashTable
function md5Hash(size, prime : cardinal; key : string) : cardinal;
var
  md : MD5Digest;
  val : cardinal;
  i : integer;
begin
  md := MD5String(key);
  
  val := 0;
  
  for i := 0 to 7 do
    val := val + (md[i] shl i);
  
  Result := val mod size;
end;

function defaultHash(size, prime : cardinal; key : string) : cardinal;
var
   i : integer;
   val : cardinal;
begin
  val := 0;

  {$Q-}
  for i := 1 to length(key) do
    val := val * prime + byte(key[i]);

  defaultHash := val mod size;
end;

function firstHash(size, prime : cardinal; key : string) : cardinal;
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

function GHashTable.getHash(key : variant) : cardinal;
{$O-}
begin
  Result := 0;
  if (varType(key) = varString) then
    Result := hashFunc(hashsize, hashprime, key)
  else
  if (varType(key) = varInteger) then
    Result := (cardinal(key) * hashprime) mod hashsize;
end;

procedure GHashTable.setHashFunc(func : GHASH_FUNC);
begin
  hashFunc := func;
end;

function GHashTable._get(key : variant) : GHashValue;
var
  hash : cardinal;
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

function GHashTable.get(key : variant) : TObject;
var
  hv : GHashValue;
begin
  Result := nil;

  hv := _get(key);

  if (hv <> nil) then
    Result := hv.value;
end;

procedure GHashTable.put(key : variant; value : TObject);
var
   hash : cardinal;
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

procedure GHashTable.remove(key : variant);
var
  hash : cardinal;
  fnode, node : GListNode;
begin
  fnode := nil;
  hash := getHash(key);

  node := bucketList[hash].head;

  while (node <> nil) do
    begin
    if (GHashValue(node.element).key = key) then
      begin
      fnode := node;
      break;
      end;

    node := node.next;
    end;

  if (fnode <> nil) then
    bucketList[hash].remove(fnode);
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

function GHashTable.iterator() : GIterator;
begin
  Result := GHashTableIterator.Create(Self);
end;


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
begin
  if (src = nil) then
    exit;

  hv := str_hash._get(src^);

  if (hv <> nil) then
    begin
    dec(hv.refcount);

    if (hv.refcount <= 0) then
      begin
      str_hash.remove(src^);
      hv.value.Free();
      hv.Free();
      end;
    end;

  src := nil;
end;


begin
  str_hash := GHashTable.Create(STR_HASH_SIZE);
end.

