// $Id: cmd_obj.inc,v 1.7 2003/06/24 21:41:29 ***REMOVED*** Exp $

procedure do_get(ch:GCharacter;param:string);
var obj, obj_in :GObject;
    arg,arg2:string;
    node, node_next : GListNode;
    d : integer;
    counter : integer;
begin
  param:=one_argument(param,arg);
  one_argument(param,arg2);

  if (length(arg)=0) and (length(arg2) = 0) then
    begin
    ch.sendBuffer('Get what?'#13#10);
    exit;
    end;

  if (ch.room.flags.isBitSet(ROOM_NOTRADE)) or (ch.room.vnum >= system_info.arena_start) and (ch.room.vnum <= system_info.arena_end) then
    begin
    ch.sendBuffer( 'That is not allowed here.'#13#10);
    exit;
    end;

  if (arg = 'all') and (length(arg2) = 0) then
    begin
    if (ch.room.objects.getSize = 0) then
      begin
      ch.sendBuffer('There is nothing here.'#13#10);
      exit;
      end;

    node := ch.room.objects.head;
    while (node <> nil) do
      begin
      node_next := node.next;
      obj := node.element;

      if (IS_SET(obj.flags,OBJ_NOPICKUP)) then
        begin
        ch.sendBuffer('You cannot pick that up.'#13#10);
        node := node_next;
        continue;
        end;

      for d := 1 to obj.count do
        begin
        act(AT_REPORT,'You get $p.',false,ch,obj,nil,TO_CHAR);
        act(AT_REPORT,'$n gets $p.',false,ch,obj,nil,TO_ROOM);
        end;

      if (obj.item_type=ITEM_MONEY) then
        begin
        ch.gold := ch.gold + obj.value[1];
        obj.Free();
        end
      else
        begin
        obj.fromRoom;
        obj.toChar(ch);
        end;

      node := node_next;
      end;
    exit;
    end;

  if (arg = 'all') and (length(arg2)<>0) then
    begin
    obj := ch.room.findObject(arg2);

    if (obj = nil) then
      begin
      ch.sendBuffer('That is not here.'#13#10);
      exit;
      end;

    if (obj.contents.getSize = 0) then
      begin
      act(AT_REPORT,'$p is empty.',false,ch,obj,nil,TO_CHAR);
      exit;
      end;

    repeat
      node := obj.contents.tail;

      obj_in := node.element;

      act(AT_REPORT,'You get $p from $P.',false,ch,obj_in,obj,TO_CHAR);
      act(AT_REPORT,'$n gets $p from $P.',false,ch,obj_in,obj,TO_ROOM);

      obj.seperate;

      if (obj_in.item_type=ITEM_MONEY) then
        begin
        ch.gold := ch.gold + obj_in.value[1];
        obj_in.Free();
        end
      else
        begin
        obj_in.fromObject;
        obj_in.toChar(ch);
        end;
    until (obj.contents.tail = nil);
    exit;
    end;

  { Get <item> <container> - Nemesis }
  if (length(arg) <> 0) and (length(arg2) <> 0) then
    begin

    obj := ch.room.findObject(arg2);

    if (obj = nil) then
      begin
      ch.sendBuffer('That is not here.'#13#10);
      exit;
      end;

    if (obj.contents.getSize = 0) then
      begin
      act(AT_REPORT,'$p is empty.',false,ch,obj,nil,TO_CHAR);
      exit;
      end;

    node := obj.contents.head;

    counter := 0;

    while (node <> nil) do
      begin
      node_next := node.next;
      obj_in := node.element;

      if (isName(obj_in.name, arg)) then
        begin
        inc(counter);

        act(AT_REPORT,'You get $p from $P.',false,ch,obj_in,obj,TO_CHAR);
        act(AT_REPORT,'$n gets $p from $P.',false,ch,obj_in,obj,TO_ROOM);
        obj_in.seperate;

        if (obj_in.item_type = ITEM_MONEY) then
          begin
          ch.gold := ch.gold + obj_in.value[1];
          obj_in.Free();
          end
        else
          begin
          obj_in.fromObject;
          obj_in.toChar(ch);
          end;
        exit;
        end;

      node := node_next;
      end;

    if (counter = 0) then
      begin
      ch.sendBuffer( 'That is not in there.'#13#10);
      exit;
      end;
    end;

  if (length(arg2)=0) then
    begin
    obj:= ch.room.findObject(arg);
    if (obj=nil) then
      begin
      ch.sendBuffer('That is not here.'#13#10);
      exit;
      end;

    if IS_SET(obj.flags,OBJ_NOPICKUP) then
      begin
      ch.sendBuffer('You cannot pick that up.'#13#10);
      exit;
      end;

    act(AT_REPORT,'You get $p.',false,ch,obj,nil,TO_CHAR);
    act(AT_REPORT,'$n gets $p.',false,ch,obj,nil,TO_ROOM);

    obj.seperate;

    if (obj.item_type=ITEM_MONEY) then
      begin
      ch.gold := ch.gold + obj.value[1];
      obj.Free();
      end
    else
      begin
      obj.fromRoom;
      obj.toChar(ch);
      end;
    exit;
    end;

  ch.sendBuffer('Get what?'#13#10);
end;

procedure do_drop(ch:GCharacter;param:string);
var 
  obj : GObject;
  iterator : GIterator;
  d : integer;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer( 'Drop what?'#13#10);
    end;

  if (ch.inventory.getSize() = 0) then
    begin
    ch.sendBuffer( 'You move your arms around wildly, but nothing happens.'#13#10);
    exit;
    end;

  // prevent trading in battlegrounds
  if (ch.room.flags.isBitSet(ROOM_NOTRADE)) or (ch.room.vnum >= system_info.arena_start) and (ch.room.vnum <= system_info.arena_end) then
    begin
    ch.sendBuffer( 'That is not allowed here.'#13#10);
    exit;
    end;

  if (param = 'all') then
    begin
    if (ch.room.flags.isBitSet(ROOM_NODROPALL)) then
      begin
      ch.sendBuffer( 'That is not allowed here.'#13#10);
      exit;
      end;
    
    iterator := ch.inventory.iterator();

    while (iterator.hasNext()) do
      begin
      obj := GObject(iterator.next());

			if IS_SET(obj.flags,OBJ_NODROP) then
				ch.sendBuffer('You cannot drop that.'#13#10)
			else
				begin
				for d := 1 to obj.count do
					begin
					act(AT_REPORT,'You drop $p$7.',false,ch,obj,nil,TO_CHAR);
					act(AT_REPORT,'$n drops $p$7.',false,ch,obj,nil,TO_ROOM);
					end;

				obj.fromChar;
				obj.toRoom(ch.room);
        end;
      end;
    end
  else
    begin
    obj := ch.findInventory(param);

    if (obj = nil) then
      ch.sendBuffer('You move your arms around wildly, but nothing happens.'#13#10)
    else
    if IS_SET(obj.flags,OBJ_NODROP) then
      ch.sendBuffer('You cannot drop that.'#13#10)
    else
      begin
      act(AT_REPORT,'You drop $p$7.',false,ch,obj,nil,TO_CHAR);
      act(AT_REPORT,'$n drops $p$7.',false,ch,obj,nil,TO_ROOM);

      obj.seperate;
      obj.fromChar;
      obj.toRoom(ch.room);
      end;
    end;
end;

procedure do_sacrifice(ch:GCharacter;param:string);
var
   obj, obj_in : GObject;
   node, node_next : GListNode;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Sacrifice what?'#13#10);
    exit;
    end;

  one_argument(param, param);

  obj := ch.room.findObject(param);

  if obj=nil then
    ch.sendBuffer('That is not here.'#13#10)
  else
  if (IS_SET(obj.flags,OBJ_NOSAC)) and (not ch.IS_IMMORT) then
    ch.sendBuffer('That is not a sacrificable object.'#13#10)
  else
    begin
    obj.seperate;

    act(AT_REPORT,'You nobly sacrifice $p$7 to the gods.',false,ch,obj,nil,TO_CHAR);
    act(AT_REPORT,'$n nobly sacrifices $p$7 to the gods.',true,ch,obj,nil,TO_ROOM);

    if (ch.level < 50) and (not ch.IS_NPC) then
      begin
      act(AT_REPORT,'You get 1 $6copper$7 coin on your bank for your donation.',false,ch,nil,nil,TO_CHAR);
      inc(GPlayer(ch).bankgold);
      end;

    node := obj.contents.head;
    while (node <> nil) do
      begin
      node_next := node.next;
      obj_in := node.element;

      obj_in.Free();

      node := node_next;
      end;

    obj.Free();
    end;
end;

procedure do_wear(ch:GCharacter;param:string);
var 
  obj : GObject;
  iterator : GIterator;
  cnt : integer;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Wear what?'#13#10);
    exit;
    end;

  if (param = 'all') then
    begin
    if (ch.inventory.getSize() = 0) then
      begin
      ch.sendBuffer('You are not carrying anything!'#13#10);
      exit;
      end;

    iterator := ch.inventory.iterator();
    cnt := 0;

    while (iterator.hasNext()) do
      begin
      obj := GObject(iterator.next());

	    if (obj.wear_location1 <> '') or (obj.wear_location2 <> '') then
        if (ch.equip(obj)) then
          begin
          obj.seperate;
          inc(cnt);
          end;
      end;

    if (cnt = 0) then
      ch.sendBuffer( 'You aren''t carrying anything that can be worn.'#13#10);
    end
  else
    begin
    obj := ch.findInventory(param);

    if (obj = nil) then
      begin
      ch.sendBuffer('You are not carrying that item.'#13#10);
      exit;
      end;

    if (obj.wear_location1 = '') and (obj.wear_location2 = '') then
      begin
      act(AT_REPORT, '$p cannot be worn.', false, ch, obj, nil, TO_CHAR);
      exit;
      end;

    if (ch.equip(obj)) then
      obj.seperate;
    end;
end;

procedure do_remove(ch:GCharacter;param:string);
var 
  iterator : GIterator;
  obj : GObject;
  found : boolean;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Remove what?'#13#10);
    exit;
    end;

  if (param = 'all') then
    begin
    iterator := ch.equipment.iterator();
    
    while (iterator.hasNext()) do
      begin
      obj := GObject(iterator.next());

			if IS_SET(obj.flags,OBJ_NOREMOVE) then
				act(AT_REPORT,'You cannot remove $p$7.',false,ch,obj,nil,TO_CHAR)
			else
				begin
				act(AT_REPORT,'You remove $p.',false,ch,obj,nil,TO_CHAR);
				act(AT_REPORT,'$n removes $p.',false,ch,obj,nil,TO_ROOM);

				obj.fromChar();
				obj.worn := '';			
				obj.toChar(ch);

				ch.affectObject(obj, true);
				end;
      end;
    end
  else
    begin
    obj := ch.findEquipment(param);

    if (obj = nil) then
      ch.sendBuffer('You are not wearing this object.'#13#10)
    else
    if (IS_SET(obj.flags, OBJ_NOREMOVE)) then
      act(AT_REPORT,'You cannot remove $p.',false,ch,obj,nil,TO_CHAR)
    else
      begin
      act(AT_REPORT,'You remove $p.',false,ch,obj,nil,TO_CHAR);
      act(AT_REPORT,'$n removes $p.',false,ch,obj,nil,TO_ROOM);

			obj.fromChar();
			obj.worn := '';			
			obj.toChar(ch);

      ch.affectObject(obj, true);
      end;
    end;

{  // fix the grouping
  node := ch.objects.head;
  while (node <> nil) do
    begin
    node_next := node.next;
    obj := node.element;
    found := false;

    // matches tend to be on the right side, so scan from the back
    node_back := ch.objects.tail;
    while (node_back <> nil) and (node_back <> node) do
      begin
      if (GObject(node_back.element).group(obj)) then
        begin
        found := true;
        break;
        end;

      node_back := node_back.prev;
      end;

    node := node_next;
    end; }
end;

procedure do_swap(ch:GCharacter;param:string);
var
   x, y : GObject;
begin
  x := ch.getEQ('lwield');
  y := ch.getEQ('rwield');

  if (x = nil) and (y = nil) then
    act(AT_REPORT,'Left hand, right hand, all hands!',false,ch,nil,nil,TO_CHAR)
  else
    begin
    ch.equipment.remove('rwield');
    ch.equipment.remove('lwield');

    if (y <> nil) then
      begin
      ch.equipment['lwield'] := y;
      y.worn := 'lwield';
      act(AT_REPORT,'You now hold $p in your left hand.',false,ch,y,nil,TO_CHAR);
      end;

    if (x <> nil) then
      begin
      ch.equipment['rwield'] := x;
      x.worn := 'rwield';
      act(AT_REPORT,'You now hold $p in your right hand.',false,ch,x,nil,TO_CHAR);
      end;
    end;
end;

(* procedure do_throw(ch:GCharacter;param:string);
var obj:GObject;
    vict:GCharacter;
    dest:GRoom;
    pexit:GExit;
    dir,range:integer;
    dam:integer;
    sub:string;
begin
  if (length(param)=0) then
    ch.sendBuffer('Throw <object> <direction> <range>'#13#10)
  else
  if ch.position=POS_BASHED then
    ch.sendBuffer('You are bashed!'#13#10)
  else
    begin
    param:=one_argument(param,sub);
    obj := ch.findInventory(sub);
    param:=one_argument(param,sub);
    dir := findHeading(sub);

    one_argument(param,sub);

    try
      range:=strtoint(sub);
    except
      ch.sendBuffer('You must type a valid number for the range.'#13#10);
      exit;
    end;

    if obj=nil then
      ch.sendBuffer('You are not carrying that!'#13#10)
    else
    if not IS_SET(obj.flags,OBJ_MISSILE) then
      ch.sendBuffer('You cannot throw that!'#13#10)
    else
    if dir=-1 then
      ch.sendBuffer('This direction does not exist.'#13#10)
    else
    if range>3 then
      ch.sendBuffer('You cannot possibly throw that far!'#13#10)
    else
      begin
      pexit := ch.room.findExit(dir);
      if (pexit=nil) or (IS_SET(pexit.flags, EX_SECRET)) then
        begin
        act(AT_REPORT,'You throw $p '+headings[dir]+
            ', but notice the wall too late!'#13#10'OUCH! That hurts!',false,ch,obj,nil,TO_CHAR);
        act(AT_REPORT,'$n attempts to throw something, but notices the wall too late.',false,ch,nil,nil,TO_ROOM);
        damage(ch,ch,25,TYPE_SILENT);
        end
      else
      if (IS_SET(pexit.flags, EX_CLOSED)) then
        begin
        act(AT_REPORT,'You throw $p '+headings[dir]+
            ', but it rebounds off the door!'#13#10'OUCH! That hurts!',false,ch,obj,nil,TO_CHAR);
        act(AT_REPORT,'$n attempts to throw something, but it rebounds off the door.',false,ch,nil,nil,TO_ROOM);
        damage(ch,ch,15,TYPE_SILENT);
        end
      else
        begin
        act(AT_REPORT,'You throw $p '+headings[dir]+'.',false,ch,obj,nil,TO_CHAR);
        act(AT_REPORT,'$n throws something '+headings[dir]+'.',false,ch,nil,nil,TO_ROOM);

        obj.fromChar();

        dest := findRoom(pexit.vnum);

        vict := dest.findRandomChar();

        obj.toRoom(dest);

        if vict=nil then
          act(AT_REPORT,'It doesn''t seem to have hit anything.',false,ch,nil,nil,TO_CHAR)
        else
          begin
          dam:=rolldice(4,obj.weight div 10);
          dam:=dam*UMin((range+1) div 3,1);
          if (dam<10) then
            begin
            act(AT_REPORT,'$p hits $N right in $S face.',false,ch,obj,vict,TO_CHAR);
            act(AT_REPORT,'$p hits you right in your face!',false,vict,obj,ch,TO_CHAR);
            act(AT_REPORT,'$p hits $n right in $s face.',false,vict,obj,ch,TO_ROOM);
            end
          else
          if (dam<30) then
            begin
            act(AT_REPORT,'$N grimaces in pain as $p cuts $M open.',false,ch,obj,vict,TO_CHAR);
            act(AT_REPORT,'You grimace in pain as $p cuts you open!',false,vict,obj,ch,TO_CHAR);
            act(AT_REPORT,'$n grimaces in pain as $p cuts $m open.',false,vict,obj,ch,TO_ROOM);
            end
          else
          if (dam<50) then
            begin
            act(AT_REPORT,'$N cries out in agony as $p rips $S head apart!',false,ch,obj,vict,TO_CHAR);
            act(AT_REPORT,'You cry out in agony as $p rips your head apart!',false,vict,obj,ch,TO_CHAR);
            act(AT_REPORT,'$n cries out in agony as $p rips $s head apart!',false,vict,obj,ch,TO_ROOM);
            end
          else
          if (dam<70) then
            begin
            act(AT_REPORT,'As $p hits $M, $N is knocked to the floor!',false,ch,obj,vict,TO_CHAR);
            act(AT_REPORT,'As $p hits you, you are knocked to the floor!',false,vict,obj,ch,TO_CHAR);
            act(AT_REPORT,'As $p hits $m, $n is knocked to the floor!',false,vict,obj,ch,TO_ROOM);
            end
          else
          if (dam<90) then
            begin
            act(AT_REPORT,'$p inflicts heavy wounds and $N screams in pain!',false,ch,obj,vict,TO_CHAR);
            act(AT_REPORT,'$p inflicts heavy wounds and you scream in pain!',false,vict,obj,ch,TO_CHAR);
            act(AT_REPORT,'$p inflicts heavy wounds and $n screams in pain!',false,vict,obj,ch,TO_ROOM);
            end
          else
          if (dam<110) then
            begin
            act(AT_REPORT,'$p trashes $N''s body and pools of blood form on the ground!',false,ch,obj,vict,TO_CHAR);
            act(AT_REPORT,'$p trashes your body and pools of blood form on the ground!',false,vict,obj,ch,TO_CHAR);
            act(AT_REPORT,'$p trashes $n''s body and pools of blood form on the ground!',false,vict,obj,ch,TO_ROOM);
            end
          else
            begin
            act(AT_REPORT,'$p smashes $N''s skull to little fragments!!',false,ch,obj,vict,TO_CHAR);
            act(AT_REPORT,'$p smashes your skull to little fragments!!',false,vict,obj,ch,TO_CHAR);
            act(AT_REPORT,'$p smashes $n''s skull to little fragments!',false,vict,obj,ch,TO_ROOM);
            end;
          damage(ch,vict,dam,TYPE_SILENT);
          end;
        end;
      end;
    end;
end; *)

{ Added drink without argument - Nemesis }
procedure do_drink(ch:GCharacter;param:string);
var obj : GObject;
    liq, counter : integer;
    node, node_next : GListNode;
begin
  counter := 0;
  if (length(param) = 0) then
    begin
    node := ch.room.objects.head;

    while (node <> nil) do
      begin
      node_next := node.next;
      obj := node.element;

      if (obj.item_type = ITEM_FOUNTAIN) then
        begin
        if (not ch.IS_NPC) and (GPlayer(ch).condition[COND_THIRST] > (MAX_COND - 15)) then
          begin
          act(AT_REPORT,'Ow yeah? And spill your ruptured bladder all over the clean floor?',false,ch,nil,nil,TO_CHAR);
          exit;
          end;

        inc(counter);

        liq := obj.value[3];

        act(AT_REPORT,'You drink ' + liq_types[liq].name + ' from $p.',false,ch,obj,nil,TO_CHAR);
        act(AT_REPORT,'$n drinks ' + liq_types[liq].name + ' from $p.',false,ch,obj,nil,TO_ROOM);

        gain_condition(ch,COND_DRUNK,liq_types[liq].affect[COND_DRUNK]);
        gain_condition(ch,COND_FULL,liq_types[liq].affect[COND_FULL]);
        gain_condition(ch,COND_THIRST,liq_types[liq].affect[COND_THIRST]);
        gain_condition(ch,COND_CAFFEINE,liq_types[liq].affect[COND_CAFFEINE]);

        if (not ch.IS_NPC) then
         if (GPlayer(ch).condition[COND_THIRST] > (MAX_COND - 15)) then
          ch.sendBuffer('You are no longer thirsty.'#13#10);

        exit;
        end;

      node := node_next;
      end;

    if (counter = 0) then
      begin
      ch.sendBuffer('Drink what?'#13#10);
      exit;
      end;
    end;

  obj := ch.findInventory(param);

  if (obj = nil) then
    obj := ch.room.findObject(param);

  if (obj = nil) then
    begin
    ch.sendBuffer('You cannot find that.'#13#10);
    exit;
    end;

  obj.seperate;

  if not (obj.item_type in [ITEM_DRINK,ITEM_FOUNTAIN]) then
    ch.sendBuffer('You cannot drink that.'#13#10)
  else
  if (obj.item_type=ITEM_DRINK) and (obj.value[2]=0) then
    act(AT_REPORT,'$p is empty.',false,ch,obj,nil,TO_CHAR)
  else
  if (not ch.IS_NPC) and (GPlayer(ch).condition[COND_THIRST] > (MAX_COND - 15)) then
    act(AT_REPORT,'Ow yeah? And spill your ruptured bladder all over the clean floor?',false,ch,nil,nil,TO_CHAR)
  else
   with obj do
    begin
    if item_type=ITEM_DRINK then
      dec(value[2]);
      
    liq := value[3];
    
    if (liq < LIQ_WATER) or (liq>=LIQ_MAX) then
      begin
      bugreport('do_drink', 'cmd_obj.inc', 'illegal liquid type ' + inttostr(liq) + ' in ' + obj.name);
      exit;
      end;

    act(AT_REPORT,'You drink ' + liq_types[liq].name + ' from $p.',false,ch,obj,nil,TO_CHAR);
    act(AT_REPORT,'$n drinks ' + liq_types[liq].name + ' from $p.',false,ch,obj,nil,TO_ROOM);

    gain_condition(ch,COND_DRUNK,liq_types[liq].affect[COND_DRUNK]);
    gain_condition(ch,COND_FULL,liq_types[liq].affect[COND_FULL]);
    gain_condition(ch,COND_THIRST,liq_types[liq].affect[COND_THIRST]);
    gain_condition(ch,COND_CAFFEINE,liq_types[liq].affect[COND_CAFFEINE]);

    if (not ch.IS_NPC) then
     if (GPlayer(ch).condition[COND_THIRST] > (MAX_COND - 15)) then
      ch.sendBuffer('You are no longer thirsty.'#13#10);
    end;
end;

procedure do_eat(ch:GCharacter;param:string);
var obj:GObject;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Eat what?'#13#10);
    exit;
    end;

  obj := ch.findInventory(param);

  if obj=nil then
    ch.sendBuffer('You aren''t carrying that.'#13#10)
  else
  if (obj.item_type<>ITEM_FOOD) and (not ch.IS_IMMORT) then
    ch.sendBuffer('You cannot eat that.'#13#10)
  else
  if (obj.item_type=ITEM_FOOD) and (obj.value[3]=0) then
    act(AT_REPORT,'$p is no longer edible.',false,ch,obj,nil,TO_CHAR)
  else
  if (not ch.IS_NPC) and (GPlayer(ch).condition[COND_FULL] > (MAX_COND - 15)) then
    act(AT_REPORT,'Your stomach would not respond nicely when eating this!',false,ch,nil,nil,TO_CHAR)
  else
    begin
    obj.seperate;

    act(AT_REPORT,'You eat $p.',false,ch,obj,nil,TO_CHAR);
    act(AT_REPORT,'$n eats $p.',false,ch,obj,nil,TO_ROOM);

    if (obj.item_type=ITEM_FOOD) then
      begin
      gain_condition(ch,COND_FULL,25);

      if (not ch.IS_NPC) then
       if (GPlayer(ch).condition[COND_FULL] > (MAX_COND - 15)) then
        ch.sendBuffer('You are full.'#13#10);
      end;

    obj.fromChar();
    obj.Free();
    end;
end;

procedure do_scalp(ch:GCharacter;param:string);
var corpse,scalp:GObject;
    s_name:string;
    h:integer;
begin
  if (length(param)=0) then
    begin
    ch.sendBuffer('Scalp what?'#13#10);
    exit;
    end;

  if (ch.getWield(ITEM_WEAPON) = nil) then
    begin
    ch.sendBuffer('You cannot scalp without wielding a weapon.'#13#10);
    exit;
    end;

  corpse := ch.room.findObject(param);

  if (corpse=nil) then
    begin
    ch.sendBuffer('That is not here.'#13#10);
    exit;
    end;

  if (corpse.item_type<>ITEM_CORPSE) then
    begin
    ch.sendBuffer('That is not a corpse.'#13#10);
    exit;
    end;

  h:=pos('of',corpse.short);
  if (h=0) then
    begin
    ch.sendBuffer('You cannot scalp that corpse.'#13#10);
    exit;
    end;

  s_name := copy(corpse.short, h,length(corpse.short) - cardinal(h) + 1);
  s_name := left(s_name,'$');

  scalp := GObject.Create;

  with scalp do
    begin
    name := 'the head ' + s_name;
    short := 'the head ' + s_name;
    long := 'the head of a once famous warrior lays here';
    item_type := ITEM_TRASH;
    node_world := objectList.insertLast(scalp);
    end;

  with corpse do
    begin
    short := '$4the mutilated corpse ' + s_name + '$7';
    long := '$4the mutilated corpse ' + s_name + ' is lying here$7';
    item_type := ITEM_TRASH;
    end;

  scalp.toChar(ch);
  act(AT_REPORT,'You draw your weapon and rip off $p.',false,ch,scalp,nil,TO_CHAR);
end;

{ Added give ALL and give <amount> COINS <char> - Nemesis }
{ Revised 13/Feb/2001 - Nemesis }
procedure do_give(ch:GCharacter;param:string);
var arg, arg2, arg3 : string;
    obj : GObject;
    vict : GCharacter;
    value, counter : integer;
    node : GListNode;
    p : integer;
begin
  param := one_argument(param,arg);
  param := one_argument(param,arg2);
  one_argument(param,arg3);

  counter := 0;

  if (length(arg) = 0) or (length(arg2) = 0) then
    begin
    ch.sendBuffer('Give what to whom?'#13#10);
    exit;
    end;

  if (length(arg) > 0) and (length(arg2) > 0) and (uppercase(arg2) <> 'COINS') and (length(arg3) > 0) then
    begin
    ch.sendBuffer('Give what to whom?'#13#10);
    exit;
    end;

  // prevent trading in battlegrounds
  if (ch.room.flags.isBitSet(ROOM_NOTRADE)) or (ch.room.vnum >= system_info.arena_start) and (ch.room.vnum <= system_info.arena_end) then
    begin
    ch.sendBuffer( 'That is not allowed here.'#13#10);
    exit;
    end;

  if (length(arg) > 0) and (uppercase(arg2) = 'COINS') and (length(arg3) > 0) then
    begin
    vict := ch.room.findChar(ch,arg3);

    if (vict = nil) then
      begin
      ch.sendBuffer('They are not here.'#13#10);
      exit;
      end;

    try
      value := strtoint(arg);
    except
      begin
      ch.sendBuffer('You must type a value.'#13#10);
      exit;
      end;
    end;

    if (value > ch.gold) then
      begin
      ch.sendBuffer('You don''t have that much money.'#13#10);
      exit;
      end;

    ch.gold := ch.gold - value;
    vict.gold := vict.gold + value;

    act(AT_REPORT,'You give ' + inttostr(value) + ' coins to $N.',false,ch,nil,vict,TO_CHAR);
    act(AT_REPORT,'$n gives you ' + inttostr(value) + ' coins.',false,ch,nil,vict,TO_VICT);
    act(AT_REPORT,'$N gives $n some coins.',false,vict,nil,ch,TO_NOTVICT);
    exit;
    end;

  if (uppercase(arg) = 'ALL') and (length(arg2) > 0) then
    begin
    vict := ch.room.findChar(ch,arg2);

    if (vict = nil) then
      begin
      ch.sendBuffer('They are not here.'#13#10);
      exit;
      end;

    node := ch.inventory.tail;
    
    while (node <> nil) do
      begin
      obj := node.element;

			act(AT_REPORT,'You give $p to $N.',false,ch,obj,vict,TO_CHAR);
			act(AT_REPORT,'$n gives $N $p.',false,ch,obj,vict,TO_ROOM);

			inc(counter);

			obj.seperate;
			obj.fromChar;
			obj.toChar(vict);

      node := node.next;
      end;

    if (counter = 0) then
      begin
      ch.sendBuffer('You have nothing to give.'#13#10);
      exit;
      end;

    exit;
    end;

  obj := ch.findInventory(arg);
  vict := ch.room.findChar(ch,arg2);

  if (obj = nil) then
    begin
    ch.sendBuffer('You are not carrying that.'#13#10);
    exit;
    end;

  if (vict = nil) then
    begin
    ch.sendBuffer('They are not here.'#13#10);
    exit;
    end;

  obj.seperate;
  obj.fromChar;
  obj.toChar(vict);

  act(AT_REPORT,'You give $N $p.',false, ch, obj, vict, TO_CHAR);
  act(AT_REPORT,'$n gives $N $p.',false, ch, obj, vict, TO_ROOM);

  if (vict.IS_NPC) then
    begin
    p := GNPC(vict).context.findSymbol('onGive');

    if (p <> -1) then
      begin
      GNPC(vict).context.push(integer(obj));
      GNPC(vict).context.push(integer(ch));
      GNPC(vict).context.push(integer(vict));
      GNPC(vict).context.setEntryPoint(p);
      GNPC(vict).context.Execute;
      end;
    end;
end;

{ Put objects into container - Nemesis }
{ Revised 13/Feb/2001 - Nemesis }
procedure do_put(ch:GCharacter;param:string);
var obj, obj_in : GObject;
    arg, arg2 : string;
    node : GListNode;
    counter : integer;
begin
  param:=one_argument(param,arg);
  one_argument(param,arg2);
  
  counter := 0;

  if (length(arg) = 0) and (length(arg2) = 0) then
    begin
    ch.sendBuffer('Put what where?'#13#10);
    exit;
    end;

  if (arg = 'all') and (length(arg2) <> 0) then
    begin
    obj_in := ch.room.findObject(arg2);

    if (obj_in = nil) then
      begin
      ch.sendBuffer('That is not here.'#13#10);
      exit;
      end;

    if (obj_in.item_type <> ITEM_CONTAINER) then
      begin
      ch.sendBuffer('That is not a container.'#13#10);
      exit;
      end;

    node := ch.inventory.head;

    while (node <> nil) do
      begin
      obj := node.element;

      if IS_SET(obj.flags,OBJ_NODROP) then
        ch.sendBuffer('You can''t put that anywhere.'#13#10)
      else
        begin
        act(AT_REPORT,'You put $p in $P.',false,ch,obj,obj_in,TO_CHAR);
        act(AT_REPORT,'$n puts $p in $P.',false,ch,obj,obj_in,TO_ROOM);

        inc(counter);

        obj.seperate;
        obj.fromChar;
        obj.toObject(obj_in);
        end;

      node := node.next;
      end;

    if (counter = 0) then
      begin
      ch.sendBuffer('You cannot put anything anywhere.'#13#10);
      exit;
      end;

    exit;
    end
  else
    begin
    obj_in := ch.room.findObject(arg2);
    obj := ch.findInventory(arg);

    if (obj = nil) then
      begin
      ch.sendBuffer('You don''t have that.'#13#10);
      exit;
      end;
    
    if (obj_in = nil) then
      begin
      ch.sendBuffer('That is not here.'#13#10);
      exit;
      end;

    if (obj_in.item_type <> ITEM_CONTAINER) then
      begin
      ch.sendBuffer('That is not a container.'#13#10);
      exit;
      end;

    if IS_SET(obj.flags,OBJ_NODROP) then
      begin
      ch.sendBuffer('You can''t put that anywhere.'#13#10);
      exit;
      end
    else
      begin
      act(AT_REPORT,'You put $p in $P.',false,ch,obj,obj_in,TO_CHAR);
      act(AT_REPORT,'$n puts $p in $P.',false,ch,obj,obj_in,TO_ROOM);

      obj.seperate;
      obj.fromChar;
      obj.toObject(obj_in);
      end;
    end;
end;

{ Refill ITEM_DRINK with liquid type of fountain - Nemesis }
procedure do_fill(ch:GCharacter;param:string);
var obj, objsource : GObject;
    counter, liq : integer;
    node : GListNode;
begin
  counter := 0;
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Fill what?'#13#10);
    exit;
    end;

  obj := ch.FindInventory(param);

  if (obj = nil) then
    begin
    ch.sendBuffer('You don''t have that.'#13#10);
    exit;
    end;

  if (obj.item_type <> ITEM_DRINK) then
    begin
    ch.sendBuffer('You cannot fill that.');
    exit;
    end;

  if (ch.room.objects.getSize = 0) then
    begin
    ch.sendBuffer('You cannot fill that here.'#13#10);
    exit;
    end;

  node := ch.room.objects.head;

  while (node <> nil) do
    begin

    objsource := node.element;

    if (objsource.item_type = ITEM_FOUNTAIN) then
      begin
      inc(counter);

      liq := objsource.value[3];

      obj.value[2] := obj.value[1];
      obj.value[3] := objsource.value[3];

      act(AT_REPORT,'You fill $p with ' + liq_types[liq].name + '.',false,ch,obj,nil,TO_CHAR);
      act(AT_REPORT,'$n fills $p with ' + liq_types[liq].name + '.',false,ch,obj,nil,TO_ROOM);

      exit;
      end;

    node := node.next;
    end;

  if (counter = 0) then
    begin
    ch.sendBuffer('You cannot fill that here.');
    exit;
    end;
end;

{ Unlock doors - Nemesis }
procedure do_unlock(ch:GCharacter;param:string);
var pexit : GExit;
    room_pos : GRoom;
    dir : integer;
    lastobj : GObject;
    node : GListNode;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Unlock what?'#13#10);
    exit;
    end;

  room_pos := ch.room;
  dir := FindHeading(param);

  if (dir = -1) then
    begin
    ch.sendBuffer('Use direction instead!'#13#10);
    exit;
    end;

  pexit := room_pos.findExit(dir);

  if (pexit = nil) then
    begin
    ch.sendBuffer('You don''t see a door there.'#13#10);
    exit;
    end;

  if (not IS_SET(pexit.flags, EX_ISDOOR)) then
    begin
    ch.sendBuffer('That is not a door.'#13#10);
    exit;
    end;

  if (not IS_SET(pexit.flags, EX_LOCKED)) then
    begin
    ch.sendBuffer('That door is not locked.'#13#10);
    exit;
    end;

  if IS_SET(pexit.flags, EX_LOCKED) then
    begin

    if (ch.inventory.getSize() = 0) then
      begin
      ch.sendBuffer('You don''t have a key.'#13#10);
      exit;
      end;

    node := ch.inventory.head;

    while (node <> nil) do
      begin

      lastobj := node.element;

      if (lastobj.item_type = ITEM_KEY) and (pexit.key = lastobj.value[1]) then
        begin
        act(AT_REPORT,'You unlock $t.',false,ch,pexit.keywords,nil,TO_CHAR);
        act(AT_REPORT,'$n unlocks $t.',false,ch,pexit.keywords,nil,TO_ROOM);

        REMOVE_BIT(pexit.flags, EX_LOCKED);

        room_pos := findRoom(pexit.vnum);
        pexit := room_pos.findExit(dir_inv[dir]);
        REMOVE_BIT(pexit.flags, EX_LOCKED);

        exit;
        end;

      if (node = ch.inventory.tail) then
        begin
        ch.sendBuffer('You lack the key.'#13#10);
        exit;
        end;

      node := node.next;
      end;
    end;
end;

{ Lock doors - Nemesis }
procedure do_lock(ch:GCharacter;param:string);
var pexit : GExit;
    room_pos : GRoom;
    dir : integer;
    lastobj : GObject;
    node : GListNode;
begin
  if (length(param) = 0) then
    begin
    ch.sendBuffer('Lock what?'#13#10);
    exit;
    end;

  room_pos := ch.room;
  dir := FindHeading(param);

  if (dir = -1) then
    begin
    ch.sendBuffer('Use direction instead!'#13#10);
    exit;
    end;

  pexit := room_pos.findExit(dir);

  if (pexit = nil) then
    begin
    ch.sendBuffer('You don''t see a door there.'#13#10);
    exit;
    end;

  if (not IS_SET(pexit.flags, EX_ISDOOR)) then
    begin
    ch.sendBuffer('That is not a door.'#13#10);
    exit;
    end;

  if (IS_SET(pexit.flags, EX_LOCKED)) then
    begin
    ch.sendBuffer('That door is already locked.'#13#10);
    exit;
    end;

  if (not IS_SET(pexit.flags, EX_CLOSED)) then
    begin
    ch.sendBuffer('That door should be closed first'#13#10);
    exit;
    end
  else
    begin
    if (pexit.key > 0) then
      begin
      if (ch.inventory.getSize() = 0) then
        begin
        ch.sendBuffer('You don''t have a key.'#13#10);
        exit;
        end;

      node := ch.inventory.head;

      while (node <> nil) do
        begin

        lastobj := node.element;

        if (lastobj.item_type = ITEM_KEY) and (pexit.key = lastobj.value[1]) then
          begin
          act(AT_REPORT,'You lock $t.',false,ch,pexit.keywords,nil,TO_CHAR);
          act(AT_REPORT,'$n locks $t.',false,ch,pexit.keywords,nil,TO_ROOM);

          SET_BIT(pexit.flags, EX_LOCKED);

          room_pos := findRoom(pexit.vnum);
          pexit := room_pos.findExit(dir_inv[dir]);
          SET_BIT(pexit.flags, EX_LOCKED);

          exit;
          end;

        if (node = ch.inventory.tail) then
          begin
          ch.sendBuffer('You lack the key.'#13#10);
          exit;
          end;

        node := node.next;
        end;
      end;
    end;
end;
