// $Id: cmd_comm.inc,v 1.7 2004/06/10 18:10:56 ***REMOVED*** Exp $

procedure do_say(ch : GCharacter; param : string);
begin
	if (length(param) = 0) then
		begin
		ch.sendBuffer('Say what?'#13#10);
		exit;
		end;
		
	param := cleanCommandLine(param);
		
	case param[length(param)] of
	'!':	begin
			act(AT_SAY,'You exclaim, ''' + param + '''',false,ch,nil,nil,TO_CHAR);
			act(AT_SAY,'$n exclaims, ''' + param + '''',false,ch,nil,nil,TO_ROOM);
			end;
	'?':	begin
			act(AT_SAY,'You ask, ''' + param + '''',false,ch,nil,nil,TO_CHAR);
			act(AT_SAY,'$n asks, ''' + param + '''',false,ch,nil,nil,TO_ROOM);
			end;
	')':	if (param[length(param)-1]=':') or (param[length(param)-2]=':') then
				begin
				act(AT_SAY,'You grin, ''' + param + '''',false,ch,nil,nil,TO_CHAR);
				act(AT_SAY,'$n grins, ''' + param + '''',false,ch,nil,nil,TO_ROOM);
				end
			else
			if (param[length(param)-2]=';') or (param[length(param)-2]='3') then
				begin
				act(AT_SAY,'You wink, ''' + param + '''',false,ch,nil,nil,TO_CHAR);
				act(AT_SAY,'$n wink, ''' + param + '''',false,ch,nil,nil,TO_ROOM);
				end
			else
				begin
				act(AT_SAY,'You say, ''' + param + '''',false,ch,nil,nil,TO_CHAR);
				act(AT_SAY,'$n says, ''' + param + '''',false,ch,nil,nil,TO_ROOM);
			end;
	else
		begin
		act(AT_SAY,'You say, ''' + param + '''',false,ch,nil,nil,TO_CHAR);
		act(AT_SAY,'$n says, ''' + param + '''',false,ch,nil,nil,TO_ROOM);
		end;
	end;
end;

procedure do_tell(ch:GCharacter;param:string);
var 
	vict : GPlayer;
	sub : string;
begin
	if (length(param)=0) then
		begin
		ch.sendBuffer('Talk what to whom?'#13#10);
		exit;
		end;

	param := cleanCommandLine(one_argument(param, sub));
	vict := GPlayer(findPlayerWorld(ch, sub));

	if (vict = nil) then
		begin
		ch.sendBuffer('They are not here.'#13#10);
		exit;
		end;

	if (vict = ch) then
		begin
		ch.sendBuffer('You talk to yourself and are surprised that you receive no answer.'#13#10);
		exit;
		end;

	if (vict.afk) then
		begin
		ch.sendBuffer('That player is away from the keyboard right now.'#13#10);
		exit;
		end;

	vict.reply := GPlayer(ch);
	act(AT_TELL,'You tell $N, ''' + param + '''',false,ch,nil,vict,TO_CHAR);
	act(AT_TELL,'>> $n tells you, ''' + param + '''',false,ch,nil,vict,TO_VICT);
end;

procedure do_reply(ch : GCharacter;param:string);
begin
	if (ch.IS_NPC) or (length(param)=0) then
		begin
		ch.sendBuffer('Reply what?'#13#10);
		exit;
		end;

	if (GPlayer(ch).reply.CHAR_DIED) then
		begin
		GPlayer(ch).reply := nil;
		ch.sendBuffer('They are not here.'#13#10);
		exit;
		end;

	if (GPlayer(ch).reply.afk) then
		begin
		ch.sendBuffer('That player is away from the keyboard right now.'#13#10);
		exit;
		end;
		
	param := cleanCommandLine(param);

	GPlayer(ch).reply.reply := GPlayer(ch);

	act(AT_TELL,'You tell $N, ''' + param + '''',false,ch,nil,GPlayer(ch).reply,TO_CHAR);
	act(AT_TELL,'>> $n tells you, ''' + param + '''',false,ch,nil,GPlayer(ch).reply,TO_VICT);
end;

procedure do_suggest(ch:GCharacter;param:string);
var 
	f : textfile;
	he : GHistoryElement;
	iterator : GIterator; 
begin
	if (length(param) = 0) then
		begin
		if (ch.IS_IMMORT()) then
			begin
			iterator := suggestHistory.iterator();

			while (iterator.hasNext()) do
				begin
				he := GHistoryElement(iterator.next());

				ch.sendBuffer(he.contents^ + #13#10);
				end;
				
			iterator.Free();
			end
		else
			begin
			ch.sendBuffer('Suggest what?'#13#10);
			exit;
			end;
		end;
		
	param := cleanCommandLine(param);

	act(AT_SUGGEST,'You suggest, '''+param+'''.',false,ch,nil,nil,TO_CHAR);
	writeConsole(ch.name+' suggested '''+param+'''');

	assignfile(f, 'system\suggest.dat');
	append(f);
	writeln(f, DateTimeToStr(Now),'> ', 'Suggestion by ',ch.name,': ',param);
	closefile(f);

	he := GHistoryElement.Create(ch.name+' suggested '''+param+'''');

	suggestHistory.insertLast(he);

	if (suggestHistory.size() > CHANNEL_HISTORY_MAX) then
	suggestHistory.remove(suggestHistory.head);
end;

procedure do_pray(ch:GCharacter;param:string);
var
	he : GHistoryElement;
	iterator : GIterator;
begin
	if (length(param) = 0) then
		begin
		if (ch.IS_IMMORT()) then
			begin
			iterator := prayHistory.iterator();

			while (iterator.hasNext()) do
				begin
				he := GHistoryElement(iterator.next());

				ch.sendBuffer(he.contents^ + #13#10);
				end;
				
			iterator.Free();
			end
		else
			begin
			ch.sendBuffer('Pray what?'#13#10);
			exit;
			end;
		end;
		
	param := cleanCommandLine(param);

	act(AT_PRAY, 'You =PRAY= '''+param+'''.',false,ch,nil,nil,TO_CHAR);
	writeConsole(ch.name + ' prays ''' + param + '''');

	he := GHistoryElement.Create(ch.name + ' prays ''' + param + '''');

	prayHistory.insertLast(he);

	if (prayHistory.size() > CHANNEL_HISTORY_MAX) then
	prayHistory.remove(prayHistory.head);
end;

procedure do_emote(ch:GCharacter;param:string);
begin
	if (length(param)=0) then
		begin
		ch.sendBuffer('EMOTE <string>'#13#10);
		exit;
		end;
		
	param := cleanCommandLine(param);

	if (not (param[length(param)] in ['.','!','?'])) then
		param := param + '.';

	act(AT_REPORT,ch.name+' '+param,false,ch,nil,nil,TO_CHAR);
	act(AT_REPORT,ch.name+' '+param,false,ch,nil,nil,TO_ROOM);
end;

procedure do_clanadd(ch:GCharacter;param:string);
var vict : GPlayer;
    obj : GObject;
    index : GObject;
begin
  if (ch.IS_NPC) then
    exit;

  if (not GPlayer(ch).clanleader) then
    ch.sendBuffer('You are not a clanleader!'#13#10)
  else
  if (length(param) = 0) then
    ch.sendBuffer('Add who to the clan?'#13#10)
  else
    begin
    vict := GPlayer(findPlayerWorld(ch,param));

    if (vict=nil) or (vict.IS_NPC) then
      ch.sendBuffer('That character does not exist.'#13#10)
    else
    if vict=ch then
      ch.sendBuffer('You''re clanleader, you don''t want to be member!'#13#10)
    else
    if vict.clan=ch.clan then
      ch.sendBuffer('That character is already member of this clan!'#13#10)
    else
    if vict.clan<>nil then
      ch.sendBuffer('That character is already member of a clan.'#13#10)
    else
      begin
      vict.clan := ch.clan;
      GPlayer(vict).clanleader := false;

      to_channel(ch, '*CLAN NOTIFY*: ' + vict.name+' is now a member of the clan!',CHANNEL_CLAN,AT_WHITE);

			index := GObject(objectIndices[ch.clan.clanobj]);

			if (index <> nil) then
        begin
        obj := index.clone();
        vict.addInventory(obj);
        act(AT_REPORT,'You have received $p.',false,vict,obj,nil,TO_CHAR);
				end;
      end;
    end;
end;

procedure do_clanremove(ch:GCharacter;param:string);
var vict : GPlayer;
begin
  if (ch.IS_NPC) then
    exit;

  if (not GPlayer(ch).clanleader) then
    ch.sendBuffer('You are not a clanleader!'#13#10)
  else
  if (length(param)=0) then
    ch.sendBuffer('Remove who from the clan?'#13#10)
  else
    begin
    vict := GPlayer(findPlayerWorld(ch,param));

    if (vict=nil) or (vict.IS_NPC) then
      ch.sendBuffer('That character is not online.'#13#10)
    else
    if vict=ch then
      ch.sendBuffer('You''re clanleader, you don''t want to remove yourself!'#13#10)
    else
    if vict.clan<>ch.clan then
      ch.sendBuffer('That character is not a member of this clan!'#13#10)
    else
      begin
      to_channel(ch, '*CLAN NOTIFY*: ' + vict.name+' is no longer a member of the clan!',CHANNEL_CLAN,AT_WHITE);
      vict.clan:=nil;
      vict.clanleader:=false;
      end;
    end;
end;

procedure do_clan(ch:GCharacter;param:string);
var
  str : string;
  obj : GObject;
begin
  if (ch.clan=nil) then
    ch.sendBuffer('But you aren''t in a clan!'#13#10)
  else
    with ch.clan do
      begin
      obj := GObject(objectIndices[clanobj]);
      
      str := obj.short;

      act(AT_REPORT,#13#10'$B$3'+name,false,ch,nil,nil,TO_CHAR);
      act(AT_REPORT,#13#10'$B$1[$7Leader$1]$A$7:        $B$2'+leader,false,ch,nil,nil,TO_CHAR);
      act(AT_REPORT,'$B$1[$7Clanbase VNum$1]$A$7: $B$2' + inttostr(clanvnum),false,ch,nil,nil,TO_CHAR);
      act(AT_REPORT,'$B$1[$7Clan object$1]$A$7:   $B$2' + str,false,ch,nil,nil,TO_CHAR);
      act(AT_REPORT,'$B$1[$7Minimum level$1]$A$7: $B$2' + inttostr(minlevel),false,ch,nil,nil,TO_CHAR);
      end;
end;

procedure do_auction(ch:GCharacter;param:string);
var price:integer;
    obj : GObject;
    buf : string;
    auc : GAuction;
begin
  if (ch.IS_EVIL) then
    auc := auction_evil
  else
    auc := auction_good;

  if (param = 'halt') then
    begin
    if (auc.item = nil) then
      ch.sendBuffer('No auction is currently going on.'#13#10)
    else
    if (auc.seller <> ch) then
      ch.sendBuffer('But that is not your auction!'#13#10)
    else
      begin
      ch.addInventory(GObject(auc.item));

      buf := '$B$2<Auction> $1[$7' + ch.name + '$1] Auction of $7' + GObject(auc.item).name + '$1 has been halted.';
      to_channel(ch,buf,CHANNEL_AUCTION,AT_REPORT);
      auc.item:=nil;
      auc.seller:=nil;
      end;
    exit;
    end;

  if (length(param)=0) then
    begin
    ch.sendBuffer('Auction what at what price?'#13#10);
    exit;
    end;

  if (auc.item<>nil) then
    begin
    ch.sendBuffer('Another auction is already going on.'#13#10);
    exit;
    end;

  param := one_argument(param,buf);
  obj := ch.findInventory(buf);

  if obj=nil then
    begin
    ch.sendBuffer('That object is not in your inventory.'#13#10);
    exit;
    end;

  one_argument(param,buf);

  try
    price:=strtoint(buf);
  except
    ch.sendBuffer('The price is invalid.'#13#10);
    exit;
  end;

  if (price < 100) then
    begin
    ch.sendBuffer('Why auction it at such a low price anyway?'#13#10);
    exit;
    end;

  act(AT_REPORT,'Auctioned $p at the price of '+inttostr(price)+'.',false,ch,obj,nil,TO_CHAR);

  ch.removeInventory(obj);

  auc.pulse := CPULSE_AUCTION;
  auc.item:=obj;
  auc.start:=price;
  auc.bid:=0;
  auc.seller:=ch;
  auc.going:=0;

  buf := '$B$2<Auction> $1[$7' + ch.name + '$1] $7' + cap(GObject(auc.item).name) + '$1, minimum bid ' + inttostr(auc.start) + ' coins.';

  to_channel(ch,buf,CHANNEL_AUCTION,AT_REPORT);
end;

procedure do_bid(ch:GCharacter;param:string);
var bid:integer;
    buf:string;
    auc : GAuction;
begin
  if (ch.IS_NPC) then
    begin
    ch.sendBuffer('NPCs cannot bid.'#13#10);
    exit;
    end;

  if (ch.IS_EVIL) then
    auc := auction_evil
  else
    auc := auction_good;

  if (auc.item=nil) then
    begin
    ch.sendBuffer('Nothing is currently up for auction.'#13#10);
    exit;
    end;

  if (length(param)=0) then
    begin
    buf := 'Currently up for auction: ' + cap(GObject(auc.item).name) + ' by ' + GCharacter(auc.seller).name + '.'#13#10;
    ch.sendBuffer(buf);

    buf := 'Startprice: ' + inttostr(auc.start);

    if (auc.bid=0) then
      buf := buf + '   No bids made yet.'#13#10
    else
      buf := buf + '  Current bid: ' + inttostr(auc.bid) + ' (' + GCharacter(auc.buyer).name + ')'#13#10;

    ch.sendBuffer(buf);
    exit;
    end;

  if (auc.seller=ch) then
    begin
    ch.sendBuffer('You cannot bid on your own auction.'#13#10);
    exit;
    end;

  if (auc.buyer=ch) then
    begin
    ch.sendBuffer('The last bid on this item is already yours.'#13#10);
    exit;
    end;

  try
    bid:=strtoint(param);
  except
    ch.sendBuffer('The bid is invalid.'#13#10);
    exit;
  end;

  if (bid > GPlayer(ch).bankgold) then
    begin
    ch.sendBuffer('You do not have enough money in the bank.'#13#10);
    exit;
    end;

  if (bid < auc.start) then
    begin
    act(AT_REPORT,'Minimum bid is '+inttostr(auc.start)+'.',false,ch,nil,nil,TO_CHAR);

    exit;
    end;

  if (bid < auc.bid+20) then
    begin
    ch.sendBuffer('Minimum bid increase is 20 coins.'#13#10);
    exit;
    end;

  auc.buyer:=ch;
  auc.bid:=bid;
  auc.going:=0;

  buf := '$B$2<Auction> $1[$7' + GCharacter(auc.seller).name + '$1] $7' + GCharacter(auc.buyer).name + '$1 bids ' + inttostr(auc.bid) + ' coins.';

  to_channel(ch,buf,CHANNEL_AUCTION,AT_REPORT);
end;

procedure do_battle(ch:GCharacter;param:string);
begin
  if (ch.IS_NPC) then
    begin
    ch.sendBuffer('NPCs cannot battle.'#13#10);
    exit;
    end;

  if (GPlayer(ch).bg_status=BG_PARTICIPATE) then
    begin
    ch.sendBuffer('You are already participating in a battleground!'#13#10);
    exit;
    end;

  if (GPlayer(ch).bg_status=BG_NOJOIN) then
    begin
    GPlayer(ch).bg_status:=BG_JOIN;
    ch.sendBuffer('You will join a battleground when it starts.'#13#10);
    exit;
    end;
    
  if (GPlayer(ch).bg_status=BG_JOIN) then
    begin
    GPlayer(ch).bg_status:=BG_NOJOIN;
    ch.sendBuffer('You will no longer join a battleground when it starts.'#13#10);
    exit;
    end;
end;

// Enable/Disable MCCP compression
procedure do_compress(ch : GCharacter; param : string);
begin
	if (ch.IS_NPC) then
		begin
		ch.sendBuffer('NPCs don''t use MCCP.'#13#10);
		exit;
		end;

	if (prep(param) = 'ON') then
 		begin
 		if (GPlayer(ch).conn.useCompress) then
 			begin
 			ch.sendBuffer('MCCP is already enabled.'#13#10);
 			exit;
 			end;
 		
	  ch.sendBuffer('Enabling MCCP (will only work on supporting clients).'#13#10);
		GPlayer(ch).conn.negotiateCompression();
	  ch.sendBuffer('Ok.'#13#10);
 		end
	else
	if (prep(param) = 'OFF') then
 		begin
 		if (not GPlayer(ch).conn.useCompress) then
 			begin
 			ch.sendBuffer('MCCP is already disabled.'#13#10);
 			exit;
 			end;
 			
  	ch.sendBuffer('Disabling MCCP.'#13#10);
 		GPlayer(ch).conn.disableCompression();
  	ch.sendBuffer('Ok.'#13#10);
 		end
	else
		begin
		ch.sendBuffer('Usage: COMPRESS <on/off>'#13#10);
		exit;
		end;
end;