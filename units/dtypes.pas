{
	Summary:
		Collection of common datastructures
		
  ##	$Id: dtypes.pas,v 1.31 2003/10/15 13:46:53 ***REMOVED*** Exp $
}

unit dtypes;

interface

uses
    Variants,
    SysUtils,
    SyncObjs;

type
		{
			Container class for strings
		}
    GString = class
    private    
      _value : string;

    published
      constructor Create(const value : string);
      
      property value : string read _value write _value;		{ The string value }
    end;

		{
			Container class for integers
		}
    GInteger = class
    private
      _value : integer;

    published
      constructor Create(const value : integer);

      property value : integer read _value write _value;	{ The integer value }
    end;
    
    {
			Container class for bitvectors
		}
    GBitVector = class
    private
      _value : cardinal;
      
    published
      constructor Create(const value : cardinal);

      function isBitSet(const bit : cardinal) : boolean;
      procedure setBit(const bit : cardinal);
      procedure removeBit(const bit : cardinal);

      property value : cardinal read _value write _value;	{ The integer value (bitvector) }
		end;

		{
			Abstract base class for iterators
		}
    GIterator = class
    	function getCurrent() : TObject; virtual; abstract;	{ Abstract getCurrent() }
      function hasNext() : boolean; virtual; abstract;		{ Abstract hasNext() }
      function next() : TObject; virtual; abstract;				{ Abstract next() }
    end;

		{
			Base class for list nodes
		}
    GListNode = class
      prev : GListNode; 				{ Pointer to previous node in list }
      next : GListNode;					{ Pointer to next node in list }
      element : pointer;				{ Pointer to element }

      constructor Create(e : pointer; p, n : GListNode);
    end;

		{
			Doubled linked list
		}
    GDLinkedList = class
   	private
      size : integer;						
      serial : integer;

		published
      head : GListNode;					{ Pointer to head of list }
      tail : GListnode;					{ Pointer to tail of list }

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

		{
			Array to store a set of prime numbers
		}
    GPrimes = array of integer;

		{
			Definition of hash function
		}
    GHASH_FUNC = function(size, prime : cardinal; key : string) : cardinal;

		{
			Container for hash elements
		}
    GHashValue = class
      key : variant;				{ Hash key }
      value : TObject;			{ Element }
      refcount : integer;		{ Reference count }
    end;

    {
			Hash table class, loosely based on the Java2 hashing classes
		}
    GHashTable = class
    private
      hashprime : cardinal;

      hashFunc : GHASH_FUNC;
      
    public
      hashsize : cardinal;										{ Size of hash table }
      bucketList : array of GDLinkedList;			{ Array of double linked lists }

		published
      procedure clear();

      function isEmpty() : boolean;
      function getSize() : integer;

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
      
    public
      property item[key : variant] : TObject read get write put; default;		{ Provides overloaded access to hash table }  
    end;


{
	Size of global string hash table
}
const STR_HASH_SIZE = 1024;

var
	{
		Global string hash table
	}
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


type
		{
			Iterator class for double linked lists
		}
    GDLinkedListIterator = class(GIterator)
    private
      current : GListNode;

    published
      constructor Create(list : GDLinkedList);

			function getCurrent() : TObject; override;
      function hasNext() : boolean; override;
      function next() : TObject; override;
    end;

		{
			Iterator class for hash tables
		}
    GHashTableIterator = class(GIterator)
    private
      tbl : GHashTable;
      cursor : integer;
      current : GListNode;

    published
      constructor Create(table : GHashTable);

			function getCurrent() : TObject; override;
      function hasNext() : boolean; override;
      function next() : TObject; override;
    end;


{
	Summary:
		GString constructor
}
constructor GString.Create(const value : string);
begin
  inherited Create();

  _value := value;
end;


{
	Summary:
		GInteger constructor
}
constructor GInteger.Create(const value : integer);
begin
  inherited Create();

  _value := value;
end;


{
	Summary:
		GBitVector constructor
}
constructor GBitVector.Create(const value : cardinal);
begin
  inherited Create();

  _value := value;
end;

{
	Summary:
		Check wether bit is set
}
function GBitVector.isBitSet(const bit : cardinal) : boolean;
begin
  Result := ((_value and bit) = bit);
end;

{
	Summary:
		Set bit
}
procedure GBitVector.setBit(const bit : cardinal);
begin
  _value := _value or bit;
end;

{
	Summary:
		Un-set (remove) bit
}
procedure GBitVector.removeBit(const bit : cardinal);
begin
  if (isBitSet(bit)) then
    dec(_value, bit);
end;


{
	Summary:
		GListNode constructor
}
constructor GListNode.Create(e : pointer; p, n : GListNode);
begin
  inherited Create;

  element := e;
  next := n;
  prev := p;
end;

{
	Summary:
		GDLinkedListIterator constructor
}
constructor GDLinkedListIterator.Create(list : GDLinkedList);
begin
  inherited Create;

  current := list.head;
end;

{
	Summary:
		Get current element in list
}
function GDLinkedListIterator.getCurrent() : TObject;
begin
	Result := current.element;
end;

{
	Summary:
		Check availability of next element
}
function GDLinkedListIterator.hasNext() : boolean;
begin
  Result := (current <> nil);
end;

{
	Summary:
		Get next element in list (if available)	
}
function GDLinkedListIterator.next() : TObject;
begin
  Result := nil;

  if (hasNext()) then
    begin
    Result := current.element;

    current := current.next;
    end;
end;


{
	Summary:
		GHashTableIterator constructor
}
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

{
	Summary:
		Get current element in list
}
function GHashTableIterator.getCurrent() : TObject;
begin
	Result := GHashValue(current.element).value;
end;

{
	Summary:
		Check availability of next element
}
function GHashTableIterator.hasNext() : boolean;
begin
  Result := (current <> nil);
end;

{
	Summary:
		Get next element in list (if available)	
}
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


{
	Summary:
		GDLinkedList constructor
}
constructor GDLinkedList.Create;
begin
  inherited Create;

  head := nil;
  tail := nil;
  size := 0;
  serial := 1;
end;

{
	Summary:
		GDLinkedList destructor
}
destructor GDLinkedList.Destroy;
begin
  inherited Destroy;
end;

{
	Summary:
		Add element to tail of list
}
function GDLinkedList.insertLast(element : pointer) : GListNode;
var
   node : GListNode;
begin
	node := GListNode.Create(element, tail, nil);

	if (head = nil) then
		head := node
	else
		tail.next := node;

	tail := node;

	insertLast := node;

	inc(size);
	inc(serial);
end;

{
	Summary:
		Add element after another element
}
function GDLinkedList.insertAfter(tn : GListNode; element : pointer) : GListNode;
var
   node : GListNode;
begin
	node := GListNode.Create(element, tn, tn.next);

	if (tn.next <> nil) then
		tn.next.prev := node;

	tn.next := node;

	if (tail = tn) then
		tail := node;

	insertAfter := node;

	inc(serial);
	inc(size);
end;

{
	Summary:
		Add element before another element
}
function GDLinkedList.insertBefore(tn : GListNode; element : pointer) : GListNode;
var
   node : GListNode;
begin
	node := GListNode.Create(element, tn.prev, tn);

	if (tn.prev <> nil) then
		tn.prev.next := node;

	tn.prev := node;

	if (head = tn) then
		head := node;

	insertBefore := node;

	inc(serial);
	inc(size);
end;

{
	Summary:
		Remove node from list
}
procedure GDLinkedList.remove(node : GListNode);
begin
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
	node.Free();
end;

{
	Summary:
		Get size of list
}
function GDLinkedList.getSize() : integer;
begin
  Result := size;
end;

{
	Summary:
		Clean up list (remove/free elements, remove nodes)
}
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

{
	Summary:
		Clean up list (remove elements, remove nodes)
}
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

{
	Summary:
		Get iterator for the list
}
function GDLinkedList.iterator() : GIterator;
begin
  Result := GDLinkedListIterator.Create(Self);
end;


{ 
	Summary:
		MD5 hashing function
}
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

{ 
	Summary:
		Default (string) hashing function
}
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

{ 
	Summary:
		Alternative string hashing function, only uses first character in string
}
function firstHash(size, prime : cardinal; key : string) : cardinal;
begin
  if (length(key) >= 1) then
    Result := (byte(key[1]) * prime) mod size
  else
    Result := 0;
end;

{
	Summary:
		Get an array of prime numbers
}
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

{
	Summary:
		Get hash-value for a key
	
	Remarks:
		Uses static hash function for integers
}
function GHashTable.getHash(key : variant) : cardinal;
{$O-}
begin
  Result := 0;
  if (varType(key) = varString) then
    Result := hashFunc(hashsize, hashprime, key)
  else
  if (varType(key) in [varSmallint,varInteger,varShortInt,varByte,varWord,varLongWord]) then
    Result := (cardinal(key) * hashprime) mod hashsize
  else
  { shouldn't be here }
  	raise Exception.Create('Impossible to determine hashkey for unknown variant type ' + VarTypeAsText(VarType(key)));
end;

{
	Summary:
		Set hash function
}
procedure GHashTable.setHashFunc(func : GHASH_FUNC);
begin
  hashFunc := func;
end;

{
	Summary:
		Get hash object corresponding with key
}
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

{
	Summary:
		Get element corresponding with key
}
function GHashTable.get(key : variant) : TObject;
var
  hv : GHashValue;
begin
  Result := nil;

  hv := _get(key);

  if (hv <> nil) then
    Result := hv.value;
end;

{
	Summary:
		Put element in hash table
}
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

{
	Summary:
		Remove key from hash table
}
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

{
	Summary:
		Get size of hash table
}
function GHashTable.getSize() : integer;
var
   i : integer;
   total : integer;
begin
  total := 0;

  for i := 0 to hashsize - 1 do
    begin
    total := total + bucketList[i].getSize();
    end;

  Result := total;
end;

{
	Summary:
		Check if hash table is empty
}
function GHashTable.isEmpty() : boolean;
begin
  Result := getSize() = 0;
end;

{
	Summary:
		Display hash table statistics
}
procedure GHashTable.hashStats();
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

{
	Summary:
		Clear hash table (See GDLinkedList.clean())
}
procedure GHashTable.clear();
var
   i : integer;
begin
  for i := 0 to hashsize - 1 do
    begin
    bucketList[i].clean;
    end;
end;

{
	Summary:
		GHashTable constructor
}
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

{
	Summary:
		GHashTable destructor
}
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

{
	Summary:
		Get iterator for the hash table
}		
function GHashTable.iterator() : GIterator;
begin
  Result := GHashTableIterator.Create(Self);
end;


{
	Summary:
		Add string to global string hash table
}
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

{
	Summary:
		Add string to global string hash table
}
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

{
	Summary:
		Remove string from global string hash table
}
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

