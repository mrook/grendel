unit server;

interface


uses
	dtypes;
	

type
	GServer = class(GSingleton)
	private
		listenSockets : GDLinkedList;
		running : boolean;
	
	public
		constructor actualCreate(); override;
		destructor actualDestroy(); override;
	
	published
		function isRunning() : boolean;
		
		procedure gameLoop();
	end;
	
	
implementation


uses
	SysUtils,
	conns,
	console,
	player,
	socket;
	

{ GServer constructor }
constructor GServer.actualCreate();
begin
	inherited actualCreate();

	listenSockets := GDLinkedList.Create();
	running := false;
end;

{ GServer destructor }
destructor GServer.actualDestroy();
begin
	listenSockets.clear();
	listenSockets.Free();
	
	inherited actualDestroy();
end;

{ Gameloop, call this from main program or TService.Execute }
procedure GServer.gameLoop();
var
	iterator : GIterator;
	socket : GSocket;
begin
	running := true;
	
  	while (running) do
		begin
		iterator := listenSockets.iterator();

		while (iterator.hasNext()) do
			begin
			socket := GSocket(iterator.next());

			if (socket.canRead()) then
				acceptConnection(socket);
			end;

		iterator.Free();

		pollConsole();

		Sleep(25);
		end;
end;

{ Returns true if server is running }
function GServer.isRunning() : boolean;
begin
	Result := running;
end;

end.