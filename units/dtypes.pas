unit dtypes;

interface

uses
    SysUtils,
    SyncObjs;

type
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

    GString = class
      refcount : integer;
      value : string;

      constructor Create(s : string);
    end;

    GHASH_FUNC = function(size, prime : cardinal; key : string) : integer;

    GHashTable = class
      hashsize : cardinal;
      hashprime : cardinal;

      bucketList : array of GDLinkedList;

      hashFunc : GHASH_FUNC;

      function getUsed : integer;
      function getHash(key : string) : integer;
      procedure setHashFunc(func : GHASH_FUNC);
      function findPrimes(n : integer) : GPrimes;

      procedure hashStats; virtual;
      procedure hashPointer(ptr : pointer; key : string);

      constructor Create(size : integer);
      destructor Destroy; override;
    end;

    GHashObject = class(GHashTable)
      procedure hashObject(obj : TObject; key : string);
    end;

    GHashString = class(GHashTable)
      procedure hashString(str : GString; key : string);
      procedure hashStats; override;
    end;

    GException = class(Exception)
      e_location : string;

      constructor Create(location, msg : string);
      procedure show;
    end;

const STR_HASH_SIZE = 1024;

var
   str_hash : GHashString;

function hash_string(src : string) : PString; overload;
function hash_string(src : PString) : PString; overload;

procedure unhash_string(var src : PString);


function defaultHash(size, prime : cardinal; key : string) : integer;
function firstHash(size, prime : cardinal; key : string) : integer;

implementation

uses
    mudsystem;

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


// GString
constructor GString.Create(s : string);
begin
  inherited Create;

  value := s;
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

procedure GHashTable.hashPointer(ptr : pointer; key : string);
var
   hash : integer;
begin
  hash := getHash(key);

  bucketList[hash].insertLast(ptr);
end;

function GHashTable.getUsed : integer;
var
   i : integer;
   total : integer;
begin
  total := 0;

  for i := 0 to hashsize - 1 do
    begin
    total := total + bucketList[i].getSize;
    end;

  getUsed := total;
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


// GHashObject
procedure GHashObject.hashObject(obj : TObject; key : string);
begin
  hashPointer(obj, key);
end;


// GHashString
procedure GHashString.hashString(str : GString; key : string);
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
end;

function hash_string(src : string) : PString;
var
   hash : integer;
   node, fnode : GListNode;
   g : GString;
begin
  hash := str_hash.getHash(src);

  node := str_hash.bucketList[hash].head;
  fnode := nil;

  while (node <> nil) do
    begin
    if (comparestr(GString(node.element).value, src) = 0) then
      begin
      fnode := node;
      break;
      end;

    node := node.next;
    end;

  if (fnode <> nil) then
    begin
    g := fnode.element;
    hash_string := @g.value;
    fnode.refcount := fnode.refcount + 1;
    end
  else
    begin
    g := GString.Create(src);
    str_hash.bucketList[hash].insertLast(g);
    hash_string := @g.value;
    end;
end;

function hash_string(src : PString) : PString;
var
   hash : integer;
   node, fnode : GListNode;
   g : GString;
begin
  hash := str_hash.getHash(src^);

  node := str_hash.bucketList[hash].head;
  fnode := nil;

  while (node <> nil) do
    begin
    if (comparestr(GString(node.element).value, src^) = 0) then
      begin
      fnode := node;
      break;
      end;

    node := node.next;
    end;

  if (fnode <> nil) then
    begin
    g := fnode.element;
    hash_string := @g.value;
    fnode.refcount := fnode.refcount + 1;
    end
  else
    begin
    g := GString.Create(src^);
    str_hash.bucketList[hash].insertLast(g);
    hash_string := @g.value;
    end;
end;

procedure unhash_string(var src : PString);
var
   hash : integer;
   node, fnode : GListNode;
   g : GString;
begin
  if (src = nil) then
    exit;

  hash := str_hash.getHash(src^);
    
  node := str_hash.bucketList[hash].head;
  fnode := nil;

  while (node <> nil) do
    begin
    if (comparestr(GString(node.element).value, src^) = 0) then
      begin
      fnode := node;
      break;
      end;

    node := node.next;
    end;

  if (fnode <> nil) then
    begin
    dec(fnode.refcount);

    if (fnode.refcount <= 0) then
      begin
      GString(fnode.element).Free;
      str_hash.bucketList[hash].remove(fnode);
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
  write_console('Exception ' + Message + ' @ ' + e_location);
end;


begin
  str_hash := GHashString.Create(STR_HASH_SIZE);
end.
