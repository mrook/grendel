{
	Summary:
		Object classes
  
	## $Id: objects.pas,v 1.1 2004/08/24 20:00:56 ***REMOVED*** Exp $
}

unit objects;


interface


uses
	dtypes,
	area,
	base;
	

{$M+}
type
    GObjectValues = array[1..4] of integer;

    GObject = class(GEntity)
    private
      _vnum : integer;
      _area : GArea;
      
    public
      affects : GDLinkedList;
      contents : GDLinkedList;
      carried_by : pointer;
      value : GObjectValues;
      
      worn : string;
      wear_location1, wear_location2 : string;

      flags : cardinal;
      item_type : integer;
      weight : integer;
      cost : integer;
      count : integer;
      timer : integer;
      
      child_count : integer; { how many of me were cloned }

  	published
      function getWeight() : integer;

      function clone() : GObject;

      constructor Create();
      destructor Destroy(); override;

      property vnum : integer read _vnum write _vnum;
      property area : GArea read _area write _area;
    end;
    

var    
   objectList : GDLinkedList;  
   objectIndices : GHashTable;


function findObjectWorld(s : string) : GObject;


implementation


uses
	util;
	

// GObject
constructor GObject.Create();
begin
	inherited Create;

	worn := '';
	wear_location1 := '';
	wear_location2 := '';
	contents := GDLinkedList.Create();
	affects := GDLinkedList.Create();
	child_count := 0;
	count := 1;
end;

destructor GObject.Destroy();
var 
  obj_in : GObject;
begin
  while (contents.tail <> nil) do
    begin
    obj_in := GObject(contents.tail.element);

    obj_in.Free();
    end;

  obj_in := GObject(objectIndices[vnum]);
  
  if (obj_in <> nil) then
    dec(obj_in.child_count);

  if (_name <> nil) then
    unhash_string(_name);
    
  if (_short <> nil) then
    unhash_string(_short);

  if (_long <> nil) then
    unhash_string(_long);

	affects.Free();
  contents.Free();
  
  inherited Destroy();
end;

// Get object weight
function GObject.getWeight() : integer;
var 
	we : integer;
	iterator : GIterator;
	obj : GObject;
begin
  we := count * weight;

  iterator := contents.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());
    inc(we, obj.getWeight);
    end;
    
	iterator.Free();

  Result := we;
end;

// Clone object
function GObject.clone() : GObject;
var
  obj : GObject;
  obj_in : GObject;
  iterator : GIterator;
begin
  obj := GObject.Create();

  obj.name := name;
  obj.short := short;
  obj.long := long;
  obj.item_type := item_type;
  obj.wear_location1 := wear_location1;
  obj.wear_location2 := wear_location2;
  obj.flags := flags;
  obj.value[1] := value[1];
  obj.value[2] := value[2];
  obj.value[3] := value[3];
  obj.value[4] := value[4];
  obj.weight := weight;
  obj.cost := cost;
  obj.count := 1;
  obj.vnum := vnum;
  obj.timer := timer;
   
  iterator := affects.iterator();
  
  while (iterator.hasNext()) do
  	begin
  	obj.affects.insertLast(iterator.next());
  	end;
  
  iterator.Free();
  
  obj_in := GObject(objectIndices[vnum]);

  if (obj_in <> nil) then
    inc(obj_in.child_count);

  objectList.add(obj);

  Result := obj;
end;

{Jago 10/Jan/2001 - utility function }
{ Revised 28/Jan/2001 - Nemesis }
function findObjectWorld(s : string) : GObject;
var 
  obj : GObject;
  iterator : GIterator;
  number, count : integer;
begin
  Result := nil;
  
  if (s = '') then
  	exit;
  	
  number := findNumber(s); // eg 2.sword

  count := 0;

  iterator := objectList.iterator();

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (isName(obj.name,s)) then
      begin
      inc(count);

      if (count = number) then
        begin
        Result := obj;
        exit;
        end;
      end;
    end;
end;


initialization
	objectList := GDLinkedList.Create();
	objectList.ownsObjects := false;

	objectIndices := GHashTable.Create(32768);
	objectIndices.ownsObjects := false;

finalization
	objectList.clear();
	objectList.Free();

	objectIndices.clear();
	objectIndices.Free();
	

end.