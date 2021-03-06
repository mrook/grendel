{
	Summary:
		Collection of common datastructures
		
	##	$Id: dtypes.pas,v 1.16 2004/06/10 19:30:42 ***REMOVED*** Exp $
}

unit dtypes;

interface


uses
	Variants,
	Classes,
	SysUtils;


{$M+}
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
		Base class for list nodes
	}
	GListNode = class
	private
		_prev : GListNode; 				{ Pointer to previous node in list }
		_next : GListNode;					{ Pointer to next node in list }
		_element : TObject;				{ Pointer to element }

	public
		property prev : GListNode read _prev write _prev;
		property next : GListNode read _next write _next;

	published
		constructor Create(e : pointer; p, n : GListNode);

		property element : TObject read _element write _element;
	end;

	{
		Abstract base class for iterators
	}
	GIterator = class
	published
		function getCurrent() : TObject; virtual; abstract;	{ Abstract getCurrent() }
		function hasNext() : boolean; virtual; abstract;		{ Abstract hasNext() }
		function next() : TObject; virtual; abstract;				{ Abstract next() }
		procedure remove(); virtual; abstract;
	end;

	{
		Doubled linked list
	}
	GDLinkedList = class
	private
		_size : integer;						
		_serial : integer;
		_head : GListNode;					{ Pointer to head of list }
		_tail : GListnode;					{ Pointer to tail of list }
		_owns : boolean;
		
	public
		procedure remove(node : GListNode); overload;

	published
		function insertLast(element : pointer) : GListNode;
		function insertFirst(element : pointer) : GListNode;
		function insertAfter(tn : GListNode; element : pointer) : GListNode;
		function insertBefore(tn : GListNode; element : pointer) : GListNode;

		procedure add(element : TObject);
		procedure remove(element : TObject); overload;
		procedure clear();

		function size() : integer;

		function iterator() : GIterator;

		constructor Create();
		destructor Destroy(); override;

		property head : GListNode read _head;
		property tail : GListNode read _tail;
		
		property ownsObjects : boolean read _owns write _owns;
		property serial : integer read _serial;
	end;

	{
		Array to store a set of prime numbers
	}
	GPrimes = array of integer;

	{
		Array to store a set of linked lists
	}
	GDLinkedListArray = array of GDLinkedList;

	{
		Definition of hash function
	}
	GHASH_FUNC = function(size, prime : integer; const key : string) : integer;

	{
		Container for hash elements
	}
	GHashValue = class
	private
		_key : variant;				{ Hash key }
		_refcount : integer;		{ Reference count }
		_value : TObject;			{ Element }

	published
		constructor Create(key : variant; value : TObject);

		procedure addRef();
		procedure release();

		property key : variant read _key;
		property refcount : integer read _refcount;
		property value : TObject read _value;
	end;

	{
		Hash table class, loosely based on the Java2 hashing classes
	}
	GHashTable = class
	private
		_owns : boolean;
		_serial : integer;

		hashprime : integer;
		hashsize : integer;										{ Size of hash table }
		bucketList : GDLinkedListArray;				{ Array of double linked lists }
		hashFunc : GHASH_FUNC;

		function getBucket(index : integer) : GDLinkedList;
		function _get(key : variant) : GHashValue;
		function findPrimes(n : integer) : GPrimes;

	published
		procedure clear();

		function isEmpty() : boolean;
		function size() : integer;

		function iterator() : GIterator;

		function get(key : variant) : TObject;
		procedure put(key : variant; value : TObject);
		procedure remove(key : variant);

		function getHash(key : variant) : integer;
		procedure setHashFunc(func : GHASH_FUNC);

		procedure hashStats(); virtual;

		constructor Create(size : integer);
		destructor Destroy(); override;

		property ownsObjects : boolean read _owns write _owns;

	public
		property item[key : variant] : TObject read get write put; default;		{ Provides overloaded access to hash table }  
		property buckets[index : integer] : GDLinkedList read getBucket;
		property bucketcount : integer read hashsize;
		property serial : integer read _serial;
	end;
	
	{
		Singleton class
	}
	GSingleton = class
	public
		class function NewInstance : TObject; override;
		procedure FreeInstance; override;
		
		{ Actual constructor, override this one instead of TObject.Create() }
		constructor actualCreate(); virtual;
		
		{	Actual destructor, override this one instead of TObject.Destroy() }
		destructor actualDestroy(); virtual;
	end;
{$M-}    


var
	{	Global string hash table }
	str_hash : GHashTable;
  

function hash_string(const src : string) : PString; overload;
function hash_string(src : PString) : PString; overload;

procedure unhash_string(var src : PString);

function md5Hash(size, prime : integer; const key : string) : integer;
function defaultHash(size, prime : integer; const key : string) : integer;
function firstHash(size, prime : integer; const key : string) : integer;
function sortedHash(size, prime : integer; const key : string) : integer;


implementation


uses
	md5;


type
	{
		Iterator class for double linked lists
	}
	GDLinkedListIterator = class(GIterator)
	private
		current, last : GListNode;
		list : GDLinkedList;
		serial : integer;

	published
		constructor Create(list : GDLinkedList);

		function getCurrent() : TObject; override;
		function hasNext() : boolean; override;
		function next() : TObject; override;
		procedure remove(); override;
	end;

	{
		Iterator class for hash tables
	}
	GHashTableIterator = class(GIterator)
	private
		tbl : GHashTable;
		cursor, lastcursor : integer;
		current, last : GListNode;
		serial : integer;

	published
		constructor Create(table : GHashTable);

		function getCurrent() : TObject; override;
		function hasNext() : boolean; override;
		function next() : TObject; override;
		procedure remove(); override;
	end;
    
	{
		Singleton info class
	}
	GSingletonInfo = class
	private
		_instanceType : TClass;
		_instance : TObject;
		_refcount : integer;

	published
		property instanceType : TClass read _instanceType write _instanceType;
		property instance : TObject read _instance write _instance;
		property refcount : integer read _refcount write _refcount;	
	end;
    	
	{
		Singleton manager class
	}
	GSingletonManager = class
	private
		infoList : TList;
			
	public
		constructor Create();
		destructor Destroy(); override;
		
	published
		procedure addInstance(instance : TObject);
		function findInstance(classType : TClass) : TObject;
		function removeInstance(classType : TClass) : boolean;
	end;
				


{
	Size of global string hash table
}
const STR_HASH_SIZE = 1024;

var
	{ Instance of singleton manager }
	singletonManager : GSingletonManager;


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
	inherited Create();

	Self.list := list;
	serial := list.serial;
	current := list.head;
	last := nil;
end;

{
	Summary:
		Get current element in list
}
function GDLinkedListIterator.getCurrent() : TObject;
begin
	if (serial <> list.serial) then	
		raise Exception.Create('Concurrent modification');
		
	if (current <> nil) then
		Result := current.element
	else
		Result := nil;
end;

{
	Summary:
		Check availability of next element
}
function GDLinkedListIterator.hasNext() : boolean;
begin
	if (serial <> list.serial) then	
		raise Exception.Create('Concurrent modification');
		
	Result := (current <> nil);
end;

{
	Summary:
		Get next element in list (if available)	
}
function GDLinkedListIterator.next() : TObject;
begin
	if (serial <> list.serial) then	
		raise Exception.Create('Concurrent modification');
		
	Result := nil;

	if (hasNext()) then
		begin
		last := current;
		
		Result := current.element;

		current := current.next;
		end;
end;

{
}
procedure GDLinkedListIterator.remove();
begin
	if (last <> nil) then
		begin
		list.remove(last);
		serial := list.serial;
		last := nil;
		end;
end;


{
	Summary:
		GHashTableIterator constructor
}
constructor GHashTableIterator.Create(table : GHashTable);
begin
  inherited Create();

  tbl := table;

  serial := tbl.serial;
  current := nil;
  cursor := 0;
	last := nil;

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
	if (serial <> tbl.serial) then	
		raise Exception.Create('Concurrent modification');
		
	Result := GHashValue(current.element).value;
end;

{
	Summary:
		Check availability of next element
}
function GHashTableIterator.hasNext() : boolean;
begin
	if (serial <> tbl.serial) then	
		raise Exception.Create('Concurrent modification');
		
  Result := (current <> nil);
end;

{
	Summary:
		Get next element in list (if available)	
}
function GHashTableIterator.next() : TObject;
begin
	if (serial <> tbl.serial) then	
		raise Exception.Create('Concurrent modification');
		
  Result := nil;

  if (hasNext()) then
    begin
    Result := GHashValue(current.element).value;

	lastcursor := cursor;
	last := current;
	
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
}
procedure GHashTableIterator.remove();
begin
	if (last <> nil) then
		begin
		tbl.bucketlist[lastcursor].remove(last);
		serial := tbl.serial;
		last := nil;
		end;
end;


{
	Summary:
		GDLinkedList constructor
}
constructor GDLinkedList.Create();
begin
  inherited Create();

	_owns := true;
	
  _head := nil;
  _tail := nil;
  _size := 0;
  _serial := 1;
end;

{
	Summary:
		GDLinkedList destructor
}
destructor GDLinkedList.Destroy();
begin
  inherited Destroy();
end;

{
	Summary:
		Add element to tail of list
}
function GDLinkedList.insertLast(element : pointer) : GListNode;
var
	node : GListNode;
begin
	inc(_serial);
	
	node := GListNode.Create(element, _tail, nil);

	if (_head = nil) then
		_head := node
	else
		_tail.next := node;

	_tail := node;

	Result := node;

	inc(_size);
end;

{
	Summary:
		Add element to tail of list
}
function GDLinkedList.insertFirst(element : pointer) : GListNode;
var
	node : GListNode;
begin
	inc(_serial);
	
	node := GListNode.Create(element, nil, _head);
	
	if (_head <> nil) then
		_head.prev := node;

	_head := node;

	Result := node;

	inc(_size);
end;

{
	Summary:
		Short for insertLast()
}
procedure GDLinkedList.add(element : TObject);
begin
	insertLast(element);
end;

{
	Summary:
		Add element after another element
}
function GDLinkedList.insertAfter(tn : GListNode; element : pointer) : GListNode;
var
   node : GListNode;
begin
	inc(_serial);
	
	node := GListNode.Create(element, tn, tn.next);

	if (tn.next <> nil) then
		tn.next.prev := node;

	tn.next := node;

	if (_tail = tn) then
		_tail := node;

	Result := node;

	inc(_size);
end;

{
	Summary:
		Add element before another element
}
function GDLinkedList.insertBefore(tn : GListNode; element : pointer) : GListNode;
var
   node : GListNode;
begin
	inc(_serial);
	
	node := GListNode.Create(element, tn.prev, tn);

	if (tn.prev <> nil) then
		tn.prev.next := node;

	tn.prev := node;

	if (_head = tn) then
		_head := node;

	Result := node;

	inc(_size);
end;

{
	Summary:
		Find and remove element from list
}
procedure GDLinkedList.remove(element : TObject);
var
  node : GListNode;
begin
  node := head;
  
  while (node <> nil) do
    begin
    if (node.element = element) then
      begin
      remove(node);
      exit;
      end;
      
    node := node.next;
    end;
end;

{
	Summary:
		Remove node from list
}
procedure GDLinkedList.remove(node : GListNode);
begin
	inc(_serial);
	
	if (node.prev = nil) then
		_head := node.next
	else
		node.prev.next := node.next;

	if (node.next = nil) then
		_tail := node.prev
	else
		node.next.prev := node.prev;

	dec(_size);
	node.Free();
end;

{
	Summary:
		Get size of list
}
function GDLinkedList.size() : integer;
begin
  Result := _size;
end;

{
	Summary:
		Remove all items from list, if ownsObject is true items are freed as well
}
procedure GDLinkedList.clear();
var
   node : GListNode;
begin
  while (true) do
    begin
    node := _tail;

    if (node = nil) then
      exit;

		if (ownsObjects) then
    	TObject(node.element).Free;

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
function md5Hash(size, prime : integer; const key : string) : integer;
var
  md : MD5Digest;
  val : integer;
  i : integer;
begin
  md := MD5String(key);
  
  val := 0;
  
  for i := 0 to 7 do
    val := val + (md[i] shl i);
  
  Result := abs(val) mod size;
end;

{ 
	Summary:
		Default (string) hashing function
}
function defaultHash(size, prime : integer; const key : string) : integer;
var
   i : integer;
   val : integer;
begin
  val := 0;

  {$Q-}
  for i := 1 to length(key) do
    val := val * prime + byte(key[i]);

  Result := abs(val) mod size;
end;

{ 
	Summary:
		Alternative string hashing function, only uses first character in string
}
function firstHash(size, prime : integer; const key : string) : integer;
begin
  if (length(key) >= 1) then
    Result := (byte(key[1]) * prime) mod size
  else
    Result := 0;
end;

{ 
	Summary:
		Alternative string hashing function, sorts linearly on first character in string
}
function sortedHash(size, prime : integer; const key : string) : integer;
begin
  if (length(key) >= 1) then
    Result := (byte(key[1]) * size) div 256
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

  Result := numbers;
end;

{
	Summary:
		GHashValue constructor
}
constructor GHashValue.Create(key : variant; value : TObject);
begin
	inherited Create();
	
	_key := key;
	_value := value;
	_refcount := 1;
end;

{
	Summary:
		Increases the reference count by one
}
procedure GHashValue.addRef();
begin
	inc(_refcount);
end;

{
	Summary:
		Decreases the reference count by one
}
procedure GHashValue.release();
begin
	dec(_refcount);
end;

{
	Summary:
		Get hash-value for a key
	
	Remarks:
		Uses static hash function for integers
}
function GHashTable.getHash(key : variant) : integer;
{$O-}
begin
  if (varType(key) = varString) then
    Result := hashFunc(hashsize, hashprime, key)
  else
  if (varType(key) in [varSmallint,varInteger,varShortInt,varByte,varWord,varLongWord]) then
    Result := (integer(key) * hashprime) mod hashsize
  else
  { shouldn't be here }
  	raise Exception.Create('Impossible to determine hashkey for unknown variant type ' + VarTypeAsText(VarType(key)));
  
  // final safeguard against indices < 0
  Result := abs(Result);
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
		Retrieves bucket at given index
}
function GHashTable.getBucket(index : integer) : GDLinkedList;
begin
	if (index < 0) or (index >= length(bucketList)) then
		begin
		raise Exception.Create('Index (' + IntToStr(index) + ') out of bounds');
		end
	else	
		Result := bucketList[index];
end;

{
	Summary:
		Get hash object corresponding with key
}
function GHashTable._get(key : variant) : GHashValue;
var
  hash : integer;
  node : GListNode;
begin
  Result := nil;
  hash := getHash(key);
  
	try
  	node := bucketList[hash].head;
  except
  	node := nil;
  end;

  while (node <> nil) do
    begin
    if (GHashValue(node.element).key = key) then
      begin
      Result := GHashValue(node.element);
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
   hash : integer;
   hv : GHashValue;
begin
	if (value = nil) then
		begin
		remove(key);
		end
	else
		begin
		inc(_serial);
		
		hv := _get(key);

		if (hv <> nil) then
			begin
			hv.addRef();
			end
		else
			begin
			hash := getHash(key);

			hv := GHashValue.Create(key, value);

			bucketList[hash].insertLast(hv);
			end;
		end;
end;

{
	Summary:
		Remove key from hash table
}
procedure GHashTable.remove(key : variant);
var
  hash : integer;
  fnode, node : GListNode;
begin
	inc(_serial);
	
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
function GHashTable.size() : integer;
var
   i : integer;
   total : integer;
begin
  total := 0;

  for i := 0 to hashsize - 1 do
    begin
    total := total + bucketList[i].size();
    end;

  Result := total;
end;

{
	Summary:
		Check if hash table is empty
}
function GHashTable.isEmpty() : boolean;
begin
  Result := size() = 0;
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
    total := total + bucketList[i].size();

    if (bucketList[i].size() < min) then
      min := bucketList[i].size();
    if (bucketList[i].size() > max) then
      max := bucketList[i].size();
    end;

  load := total / hashsize;

  writeln('Hash size ' + inttostr(hashsize) + ' with key ' + inttostr(hashprime));
  writeln('Total hash items : ' + inttostr(total));
  writeln('Load factor : ' + floattostrf(load, ffFixed, 7, 4));
end;

{
	Summary:
		Remove all items from hash table (See GDLinkedList.clear())
}
procedure GHashTable.clear();
var
   i : integer;
begin
	inc(_serial);
	
  for i := 0 to hashsize - 1 do
    begin
    bucketList[i].ownsObjects := ownsObjects;
    bucketList[i].clear();
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
  inherited Create();

  primes := findPrimes(size + 32);

  randomize;
  hashsize := primes[length(primes) - 1];
  hashprime := primes[random(length(primes))];

  setlength(bucketList, hashsize);

  for n := 0 to hashsize - 1 do
    bucketList[n] := GDLinkedList.Create;

  hashFunc := defaultHash;

	_owns := true;
	_serial := 1;
end;

{
	Summary:
		GHashTable destructor
}
destructor GHashTable.Destroy();
var
	n : integer;
begin
	clear();
	
  for n := 0 to hashsize - 1 do
    bucketList[n].Free;

  setlength(bucketList, 0);

  inherited Destroy();
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
function hash_string(const src : string) : PString;
var
  hv : GHashValue;
  g : GString;
begin
  hv := str_hash._get(src);

  if (hv <> nil) then
    begin
    Result := @GString(hv.value).value;
    hv.addRef();
    end
  else
    begin
    g := GString.Create(src);

    str_hash.put(src, g);

    Result := @g.value;
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
    Result := @GString(hv.value).value;
    hv.addRef();
    end
  else
    begin
    g := GString.Create(src^);

    str_hash.put(src^, g);

    Result := @g.value;
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
    hv.release();

    if (hv.refcount <= 0) then
      begin
      str_hash.remove(src^);
      hv.value.Free();
      hv.Free();
      end;
    end;

  src := nil;
end;

{ 
	Summary:
		GSingletonManager constructor
}
constructor GSingletonManager.Create();
begin
	inherited Create();
	
	infoList := TList.Create();
end;

{ 
	Summary:
		GSingletonManager destructor
}
destructor GSingletonManager.Destroy();
var
	x : integer;
begin
	if (infoList.Count > 0) then
		begin
		for x := 0 to infoList.Count - 1 do
			GSingletonInfo(infoList[x]).Free();
		end;
		
	FreeAndNil(infoList);
	
	inherited Destroy();
end;

{ 
	Summary:
		Adds instance to manager
}
procedure GSingletonManager.addInstance(instance : TObject);
var
	info : GSingletonInfo;
begin
	info := GSingletonInfo.Create();
	
	info.instance := instance;
	info.instanceType := instance.ClassType;
	info.refcount := 1;

	infoList.add(info);
end;

{
	Summary:
		Finds instance of classtype, or nil if unsuccessful
}
function GSingletonManager.findInstance(classType : TClass) : TObject;
var
	index : integer;
	info : GSingletonInfo;
begin
	Result := nil;

	for index := 0 to infoList.Count - 1 do
		begin
		info := GSingletonInfo(infoList[index]);
		
		if (info.instanceType = classType) then
			begin
			Result := info.instance;
			info.refcount := info.refcount + 1;
			exit;
			end;
		end;
end;

{
	Summary:
		Lowers refcount of classtype, removes if 0
}
function GSingletonManager.removeInstance(classType : TClass) : boolean;
var
	index : integer;
	info : GSingletonInfo;
begin
	Result := false;

	for index := 0 to infoList.Count - 1 do
		begin
		info := GSingletonInfo(infoList[index]);
		
		if (info.instanceType = classType) and (info.refcount > 0) then
			begin
			info.refcount := info.refcount - 1;
			
			if (info.refcount = 0) then
				Result := true;

			exit;
			end;
		end;
end;

{
	Summary:
		Returns (if it exists) a previous instance or a new instance
}
class function GSingleton.NewInstance : TObject;
begin
	Result := singletonManager.findInstance(Self);
	
	if (not Assigned(Result)) then
		begin
		Result := inherited NewInstance;
		GSingleton(Result).actualCreate();
		singletonManager.addInstance(Result);
		end;
end;

{
	Summary:
		Frees the instance
}
procedure GSingleton.FreeInstance;
begin
	if (singletonManager.removeInstance(Self.ClassType)) then
		begin
		GSingleton(Self).actualDestroy();

		inherited FreeInstance;
		end;	
end;

{
	Summary:
		Default GSingleton constructor 
}
constructor GSingleton.actualCreate();
begin
end;

{
	Summary:
		Default GSingleton destructor 
}
destructor GSingleton.actualDestroy();
begin
end;


initialization
	str_hash := GHashTable.Create(STR_HASH_SIZE);
	singletonManager := GSingletonManager.Create();

finalization
	FreeAndNil(singletonManager);
	FreeAndNil(str_hash);

end.

