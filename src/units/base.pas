{
	Summary:
		Various base classes
  
	## $Id: base.pas,v 1.1 2004/08/24 20:00:56 ***REMOVED*** Exp $
}

unit base;


interface


uses
	rooms;


type
	{$M+}
	GEntity = class
	protected
		_room : GRoom;
		_name, _short, _long : PString;
		
	public
		constructor Create();
		
		procedure setName(const name : string);
		procedure setShortName(const name : string);
		procedure setLongName(const name : string);
		function getName() : string;
		function getShortName() : string;
		function getLongName() : string;
		
	published
		property room : GRoom read _room write _room;
		property name : string read getName write setName;
		property short : string read getShortName write setShortName;
		property long : string read getLongName write setLongName;
	end;
	
	
implementation


uses
	dtypes;


constructor GEntity.Create();
begin
	inherited Create();
	
	_room := nil;
	_name := nil;
	_short := nil;
	_long := nil;
end;

procedure GEntity.setName(const name : string);
begin
  _name := hash_string(name);
end;

procedure GEntity.setShortName(const name : string);
begin
  _short := hash_string(name);
end;

procedure GEntity.setLongName(const name : string);
begin
  _long := hash_string(name);
end;

function GEntity.getName() : string;
begin
  if (_name <> nil) then
    Result := _name^
  else
    Result := '';
end;

function GEntity.getShortName() : string;
begin
  if (_short <> nil) then
    Result := _short^
  else
    Result := '';
end;

function GEntity.getLongName() : string;
begin
  if (_long <> nil) then
    Result := _long^
  else
    Result := '';
end;



end.
	
