{
	Delphi IMC3 Client - Mud type and support routines

	Based on client code by Samson of Alsherok.

	$Id: imc3_mud.pas,v 1.3 2004/03/11 23:32:59 ***REMOVED*** Exp $
}
unit imc3_mud;

interface


uses
	Classes,
	fsys,
	dtypes,
	LibXmlParser,
	imc3_const;
	

const
	IMC3_DRIVER_VERSION = '0.5';


type
	GRouter_I3 = class
	public
   	ipaddress : string;
   	name : string;
   	port : integer;
	end;

	GMud_I3 = class
	public
		status : integer;
		
		{ Stuff for the first mapping set }
		name : string;
		ipaddress : string;
		mudlib : string;
		base_mudlib : string;
		driver : string;
		mud_type : string;
		open_status : string;
		admin_email : string;
		telnet : string;
		web_wrong : string;			{ This tag shows up in the wrong location on several implementations, including previous AFKMud versions }
		
		player_port : integer;
		imud_tcp_port : integer;
		imud_udp_port : integer;
		
		tell : boolean;
		beep : boolean;
		emoteto : boolean;
		who : boolean;
		finger : boolean;
		locate : boolean;
		channel : boolean;
		news : boolean;
		mail : boolean;
		mfile : boolean;
		auth : boolean;
		ucache : boolean;
		
		smtp : integer;
		ftp : integer;
		nntp : integer;
		http : integer;
		pop3 : integer;
		rcp : integer;
		amrcp : integer;

  	{ Stuff for the second mapping set - can be added to as indicated by i3log messages for missing keys }
  	banner : string;
  	web : string;
  	time : string;
  	daemon : string;
  	jeamland : integer;

   	{ only used for this mud }
   	routers : TList;
    preferredRouter : GRouter_I3;
   	
   	autoconnect : boolean;
   	password : integer;
   	mudlist_id : integer;
   	chanlist_id : integer;
   	minlevel : integer;
   	immlevel : integer;
   	adminlevel : integer;
   	implevel : integer;
   	
  published 
  	constructor Create();
  	
  	procedure readConfig();
  	procedure load(parser : TXmlParser);
  	procedure save(writer : GFileWriter);
	end;


var
	mudList : GHashTable;
	
	
function findMud(name : string) : GMud_I3;

procedure saveMudList();


implementation

uses
	SysUtils,
	console,
	constants,
	mudsystem,
	util;
	
	
function findMud(name : string) : GMud_I3;
begin
	findMud := GMud_I3(mudList.get(name));
end;
	

constructor GMud_I3.Create();
begin
	inherited Create();
	
	status := 0;
	routers := TList.Create();
	player_port := 0;
	password := 0;
end;

procedure GMud_I3.load(parser : TXmlParser);
var
	router : GRouter_I3;
  i : integer;
begin
	while (parser.Scan()) do
		case parser.CurPartType of // Here the parser tells you what it has found
			ptStartTag:
				begin
				if (prep(parser.CurName) = 'INFO') then
					begin
          for i := 0 to parser.CurAttr.Count-1 do
          	begin
            if (prep(parser.CurAttr.Name(i)) = 'AUTOCONNECT') then
            	autoconnect := (StrToIntDef(parser.CurAttr.Value(i), 0) = 1)
            else
            if (prep(parser.CurAttr.Name(i)) = 'MINLEVEL') then
            	minlevel := StrToIntDef(parser.CurAttr.Value(i), 0)
            else
            if (prep(parser.CurAttr.Name(i)) = 'IMMLEVEL') then
            	immlevel := StrToIntDef(parser.CurAttr.Value(i), 0)
            else
            if (prep(parser.CurAttr.Name(i)) = 'ADMINLEVEL') then
            	adminlevel := StrToIntDef(parser.CurAttr.Value(i), 0)
            else
            if (prep(parser.CurAttr.Name(i)) = 'IMPLEVEL') then
            	implevel := StrToIntDef(parser.CurAttr.Value(i), 0);
            end;
					end
				else
				if (prep(parser.CurName) = 'ROUTER') then
					begin
					router := GRouter_I3.Create();

          for i := 0 to parser.CurAttr.Count-1 do
          	begin
            if (prep(parser.CurAttr.Name(i)) = 'HOST') then
							router.ipaddress := parser.CurAttr.Value(i)
            else
            if (prep(parser.CurAttr.Name(i)) = 'PORT') then
							router.port := StrToIntDef(parser.CurAttr.Value(i), 0)
            else
            if (prep(parser.CurAttr.Name(i)) = 'PREFERRED') then
							preferredRouter := router;
            end;

          routers.Add(router);
					end
				end;
			ptContent:
				begin
				if (prep(parser.CurName) = 'NAME') then
					name := parser.CurContent
				else
				if (prep(parser.CurName) = 'TELNET') then
					telnet := parser.CurContent
				else
				if (prep(parser.CurName) = 'WEB') then
					web := parser.CurContent
				else
				if (prep(parser.CurName) = 'ADMINEMAIL') then
					admin_email := parser.CurContent
				else
				if (prep(parser.CurName) = 'OPENSTATUS') then
					open_status := parser.CurContent
				else
				if (prep(parser.CurName) = 'MUDTYPE') then
					mud_type := parser.CurContent
				else
				if (prep(parser.CurName) = 'BASEMUDLIB') then
					base_mudlib := parser.CurContent
				else
				if (prep(parser.CurName) = 'MUDLIB') then
					mudlib := parser.CurContent
				else
				if (prep(parser.CurName) = 'DRIVER') then
					driver := parser.CurContent
				else
				if (prep(parser.CurName) = 'PLAYER_PORT') then
					player_port := StrToIntDef(parser.CurContent, 0)
				else
				if (prep(parser.CurName) = 'ROUTER') then
					router.name := parser.CurContent
				else
				if (prep(parser.CurName) = 'SMTP') then
					smtp := StrToIntDef(parser.CurContent, 0)
				else
				if (prep(parser.CurName) = 'FTP') then
					ftp := StrToIntDef(parser.CurContent, 0)
				else
				if (prep(parser.CurName) = 'HTTP') then
					ftp := StrToIntDef(parser.CurContent, 0)
				else
				if (prep(parser.CurName) = 'NNTP') then
					nntp := StrToIntDef(parser.CurContent, 0)
				else
				if (prep(parser.CurName) = 'POP3') then
					pop3 := StrToIntDef(parser.CurContent, 0)
				else
				if (prep(parser.CurName) = 'RCP') then
					rcp := StrToIntDef(parser.CurContent, 0)
				else
				if (prep(parser.CurName) = 'AMRCP') then
					amrcp := StrToIntDef(parser.CurContent, 0);
				end;
			ptEmptyTag:
				begin
				if (prep(parser.CurName) = 'TELL') then
					tell := true
				else
				if (prep(parser.CurName) = 'BEEP') then
					beep := true
				else
				if (prep(parser.CurName) = 'EMOTETO') then
					emoteto := true
				else
				if (prep(parser.CurName) = 'WHO') then
					who := true
				else
				if (prep(parser.CurName) = 'FINGER') then
					finger := true
				else
				if (prep(parser.CurName) = 'LOCATE') then
					locate := true
				else
				if (prep(parser.CurName) = 'CHANNEL') then
					channel := true
				else
				if (prep(parser.CurName) = 'NEWS') then
					news := true
				else
				if (prep(parser.CurName) = 'MAIL') then
					mail := true
				else
				if (prep(parser.CurName) = 'FILE') then
					mfile := true
				else
				if (prep(parser.CurName) = 'AUTH') then
					auth := true
				else
				if (prep(parser.CurName) = 'UCACHE') then
					ucache := true;
				end;
			ptEndTag: // Process End-Tag here (Parser.CurName)
				begin
				if (prep(parser.CurName) = 'MUD') then
					exit;
				end;
		end;
end;

procedure GMud_I3.save(writer : GFileWriter);
begin
	writer.writeLine('	<mud>');
	
	writer.writeLine('		<info>');
	writer.writeLine('			<name>' + name + '</name>');
	writer.writeLine('			<ipaddress>' + ipaddress + '</ipaddress>');
	writer.writeLine('			<web>' + web + '</web>');
	writer.writeLine('			<adminemail>' + admin_email + '</adminemail>');
	writer.writeLine('			<openstatus>' + open_status + '</openstatus>');
	writer.writeLine('			<mudtype>' + mud_type + '</mudtype>');
	writer.writeLine('			<basemudlib>' + base_mudlib + '</basemudlib>');
	writer.writeLine('			<mudlib>' + mudlib + '</mudlib>');
	writer.writeLine('			<driver>' + driver + '</driver>');
	writer.writeLine('			<player_port>' + IntToStr(player_port) + '</player_port>');
	writer.writeLine('		</info>');
	
	writer.writeLine('		<services>');

	if (tell) then
		writer.writeLine('			<tell/>');
	if (beep) then
		writer.writeLine('			<beep/>');
	if (emoteto) then
		writer.writeLine('			<emoteto/>');
	if (who) then
		writer.writeLine('			<who/>');
	if (finger) then
		writer.writeLine('			<finger/>');
	if (locate) then
		writer.writeLine('			<locate/>');
	if (channel) then
		writer.writeLine('			<channel/>');
	if (news) then
		writer.writeLine('			<news/>');
	if (mail) then
		writer.writeLine('			<mail/>');
	if (mfile) then
		writer.writeLine('			<file/>');
	if (auth) then
		writer.writeLine('			<auth/>');
	if (ucache) then
		writer.writeLine('			<ucache/>');
		
	writer.writeLine('		</services>');
	
	writer.writeLine('		<ports>');

	if (smtp > 0) then
		writer.writeLine('			<smtp port="' + IntToStr(smtp) + '"/>');
	if (ftp > 0) then
		writer.writeLine('			<ftp port="' + IntToStr(ftp) + '"/>');
	if (nntp > 0) then
		writer.writeLine('			<nntp port="' + IntToStr(nntp) + '"/>');
	if (http > 0) then
		writer.writeLine('			<http port="' + IntToStr(http) + '"/>');
	if (pop3 > 0) then
		writer.writeLine('			<pop3 port="' + IntToStr(pop3) + '"/>');
	if (rcp > 0) then
		writer.writeLine('			<rcp port="' + IntToStr(rcp) + '"/>');
	if (amrcp > 0) then
		writer.writeLine('			<amrcp port="' + IntToStr(amrcp) + '"/>');

	writer.writeLine('		</ports>');
	
	writer.writeLine('	</mud>');
end;

procedure GMud_I3.readConfig();
var
	parser : TXmlParser;
begin
	parser := TXmlParser.Create();
	parser.Normalize := true;
	parser.LoadFromFile(I3_CONFIG_FILE);

	if (parser.Source <> I3_CONFIG_FILE) then
		begin
		writeConsole('Could not load ' + I3_CONFIG_FILE);
		exit;
		end;

	parser.StartScan();

	while (parser.Scan()) do
		case parser.CurPartType of // Here the parser tells you what it has found
			ptStartTag:
				begin
				if (prep(parser.CurName) = 'MUD') then
					load(parser);
				end;
		end;

	parser.Free();
	
	// Fill in a few fields using running server
	player_port := system_info.port;
	mudlib := version_program + ' ' + version_number;
	driver := 'Grendel I3 Driver ' + IMC3_DRIVER_VERSION;
end;

procedure loadMudList();
var
	parser : TXmlParser;
	mud : GMud_I3;
begin
	if (not FileExists(I3_MUDLIST_FILE)) then
		exit;
		
  parser := TXmlParser.Create();
	parser.Normalize := true;
  parser.LoadFromFile(I3_MUDLIST_FILE);

	parser.StartScan();

	while (parser.Scan()) do
		case parser.CurPartType of // Here the parser tells you what it has found
			ptStartTag:
				begin
				if (prep(parser.CurName) = 'MUD') then
					begin
					mud := GMud_I3.Create();
					mud.load(parser);
					mudList.put(mud.name, mud);
					end;
				end;
		end;

	parser.Free();
end;

procedure saveMudList();
var
	iterator : GIterator;
	mud : GMud_I3;
	writer : GFileWriter;
begin
	iterator := mudList.iterator();
	
	writer := GFileWriter.Create(I3_MUDLIST_FILE);
	
	writer.writeLine('<?xml version="1.0"?>');
	writer.writeLine('<!-- InterMud 3 MudList -->');
	writer.writeLine('<!-- Autogenerated, do not manually edit -->');
	writer.writeLine('<mudlist>');
	
	while (iterator.hasNext()) do
		begin
		mud := GMud_I3(iterator.next());
		
		mud.save(writer);
		end;

	writer.writeLine('</mudlist>');
	
	writer.Free();
		
	iterator.Free();
end;

begin
	mudList := GHashTable.Create(256);
	
	loadMudList();
end.