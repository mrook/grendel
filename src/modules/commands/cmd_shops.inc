// $Id: cmd_shops.inc,v 1.2 2004/05/12 20:53:23 ***REMOVED*** Exp $

procedure do_balance(ch:GCharacter;param:string);
var
	iterator : GIterator;
	banker, vict : GCharacter;
begin
  banker := nil;
  iterator := ch.room.chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_NPC) and (vict.IS_BANKER) then
      begin
      banker := vict;
      break;
      end;
    end;
    
  iterator.Free();

  if (banker = nil) then
    ch.sendBuffer('If only there was a banker in sight!'#13#10)
  else
    ch.sendBuffer('You currently have '+inttostr(GPlayer(ch).bankgold)+
                 ' coins stored at a bank.'#13#10);
end;

procedure do_withdraw(ch:GCharacter;param:string);
var 
	s:integer;
	iterator : GIterator;
	banker, vict : GCharacter;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Withdraw how much?'#13#10);
    exit;
    end;

  banker := nil;
  iterator := ch.room.chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_NPC) and (vict.IS_BANKER) then
      begin
      banker := vict;
      break;
      end;
    end;
    
  iterator.Free();

  if (banker = nil) then
    ch.sendBuffer('If only there was a banker in sight!'#13#10)
  else
    begin
    if (param[1] in ['0'..'9']) then
      begin
      try
        s := strtoint(param);
      except
        ch.sendBuffer('You must type a number.'#13#10);
        exit;
      end;
      
      if (s > GPlayer(ch).bankgold) then
        begin
        ch.sendBuffer('You don''t have that much money!'#13#10);
        exit;
        end;
        
      dec(GPlayer(ch).bankgold, s);
      ch.gold := ch.gold + s;

      ch.sendBuffer('You get ' + inttostr(s) + ' coins from your account.'#13#10);
      end
    else
    if (param = 'all') then
      begin
      s := GPlayer(ch).bankgold;
      
      if (s = 0) then
        begin
        ch.sendBuffer('You don''t have anything in your account!'#13#10);
        exit;
        end;
        
      GPlayer(ch).bankgold := 0;
      ch.gold := ch.gold + s;
      ch.sendBuffer('You get ' + inttostr(s) + ' coins from your account.'#13#10);
      end
    else
      ch.sendBuffer('Withdraw what?'#13#10);
    end;
end;

procedure do_deposit(ch:GCharacter;param:string);
var 
	s:integer;
	iterator : GIterator;
	banker, vict : GCharacter;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Deposit what?'#13#10);
    exit;
    end;

  banker := nil;
  iterator := ch.room.chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_NPC) and (vict.IS_BANKER) then
      begin
      banker := vict;
      break;
      end;
    end;
    
  iterator.Free();

  if (banker = nil) then
    ch.sendBuffer('If only there was a banker in sight!'#13#10)
  else
    begin
    if (param[1] in ['0'..'9']) then
      begin
      try
        s := strtoint(param);
      except
        ch.sendBuffer('You must type a number.'#13#10);
        exit;
      end;
      
      if (s = 0) then
        begin
        ch.sendBuffer('The bank doesn''t accept 0 coins!'#13#10);
        exit;
        end;
        
      if (ch.gold = 0) or (ch.gold < s) then
        begin
        ch.sendBuffer('You are not carrying any money!'#13#10);
        exit;
        end;
        
      ch.gold := ch.gold - s;
      inc(GPlayer(ch).bankgold, s);
      ch.sendBuffer('You store ' + inttostr(s) + ' coins at the bank.'#13#10);
      end
    else
    if (param = 'all') then
      begin
      if (ch.gold = 0) then
        begin
        ch.sendBuffer('You are not carrying any money!'#13#10);
        exit;
        end;
        
      inc(GPlayer(ch).bankgold, ch.gold);
      ch.sendBuffer('You store ' + inttostr(ch.gold) + ' coins at the bank.'#13#10);
      ch.gold:=0;
      end
    else
      ch.sendBuffer('Deposit what?'#13#10);
    end;
end;

function getCost(keeper,ch:GCharacter; obj : GObject):integer;
begin
  Result := (obj.cost*(100+ch.level)) div 500;
end;

procedure do_list(ch:GCharacter;param:string);
var 
	i:integer;
	iterator : GIterator;
	obj : GObject;
	keeper,vict:GCharacter;
begin
  keeper := nil;
  iterator := ch.room.chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_NPC) and (vict.IS_SHOPKEEPER) then
      begin
      keeper := vict;
      break;
      end;
    end;
    
  iterator.Free();  

  if (keeper = nil) then
    begin
    ch.sendBuffer('You cannot do that here.'#13#10);
    exit;
    end;

  if (keeper.inventory.size() = 0) then
    begin
    interpret(keeper, 'say I am not selling anything today, '+ch.name+'.');
    exit;
    end;

  iterator := keeper.inventory.iterator();
  i:=0;

  while (iterator.hasNext()) do
    begin
    obj := GObject(iterator.next());

    if (obj.item_type <> ITEM_MONEY) then
      act(AT_REPORT,'$6[$7'+pad_integer(i,2)+'$6]$7 $p, for $6'+inttostr(getCost(keeper,ch,obj))+'$7 coins',false,ch,obj,nil,TO_CHAR);

    inc(i);
    end;
  iterator.Free();
end;

procedure do_buy(ch:GCharacter;param:string);
var 
	obj,newobj : GObject;
	iterator : GIterator;
	keeper,vict:GCharacter;
	cost:integer;
begin
  keeper := nil;
  iterator := ch.room.chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_NPC) and (vict.IS_SHOPKEEPER) then
      begin
      keeper := vict;
      break;
      end;
    end;
    
  iterator.Free();  

  if (keeper = nil) then
    begin
    ch.sendBuffer('You cannot do that here.'#13#10);
    exit;
    end;

  if (length(param)=0) then
    begin
    ch.sendBuffer('Buy what?'#13#10);
    exit;
    end;

  if (keeper.inventory.size() = 0) then
    begin
    interpret(keeper, 'say I am not selling anything today, '+ch.name+'.');
    exit;
    end;

  obj := keeper.findInventory(param);

  if obj=nil then
    interpret(keeper,'say I do not sell that object.')
  else
    begin
    cost := getCost(keeper,ch,obj);

    if (cost > ch.gold) then
      ch.sendBuffer('You cannot afford that.'#13#10)
    else
      begin     
      newobj := obj.clone();

      act(AT_REPORT,'You buy $p for '+inttostr(cost)+' coins.',false,ch,newobj,nil,TO_CHAR);

      newobj.toChar(ch);
      ch.gold := ch.gold - cost;
      end;
    end;
end;

procedure do_sell(ch : GCharacter; param : string);
var 
	i,sell,cost:integer;
	keeper,vict:GCharacter;
	iterator : GIterator;
	shop : GShop;
	obj : GObject;
begin
  keeper := nil;
 	iterator := ch.room.chars.iterator();

  while (iterator.hasNext()) do
    begin
    vict := GCharacter(iterator.next());

    if (vict.IS_NPC) and (vict.IS_SHOPKEEPER) then
      begin
      keeper := vict;
      break;
      end;
    end;
    
  iterator.Free();  

  if (keeper = nil) or (GNPC(keeper).npc_index.shop = nil) then
    begin
    ch.sendBuffer('You cannot do that here.'#13#10);
    exit;
    end;

  if (length(param)=0) then
    begin
    ch.sendBuffer('Sell what?'#13#10);
    exit;
    end;

  shop := GNPC(keeper).npc_index.shop;

  if (time_info.hour < shop.open_hour) or (time_info.hour > shop.close_hour) then
    begin
    interpret(keeper,'say I am closed!');
    exit;
    end;

  obj := ch.findInventory(param);

  if (obj=nil) then
    begin
    interpret(keeper,'say You are not carrying that object!');
    exit;
    end;

  sell:=0;
  for i:=1 to 5 do
   if (shop.item_buy[i]=obj.item_type) then
    sell:=i;

  cost := getCost(ch, keeper, obj);
  if (sell = 0) or (cost <= 0) then
    begin
    act(AT_REPORT,'$N looks at $p and shakes $S head.',false,ch,obj,keeper,TO_CHAR);
    exit;
    end;

  if (obj.count > 1) then 
    obj.separate();
    
  obj.fromChar();
  obj.toChar(keeper);
  ch.gold := ch.gold + cost;
  act(AT_REPORT,'You sold $p for ' + inttostr(cost) + ' coins.', false, ch, obj, nil, TO_CHAR);
end;
