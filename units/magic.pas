// $Id: magic.pas,v 1.6 2001/04/20 20:09:30 ***REMOVED*** Exp $

unit magic;

interface

uses
    skills,
    chars;

function findFunc(s:string) : SPEC_FUNC;

procedure magic_timer(ch, victim : GCharacter; sn : GSkill);

implementation

uses
    SysUtils,
    constants,
    area,
    dtypes,
    mudthread,
    mudsystem,
    conns,
    util,
    fight;

function saving_throw(level,save:integer; vict: GCharacter):boolean;
var chance:integer;
begin
  chance:=50+(vict.level-level-save)*5;
  chance:=URANGE(5,chance,5);
  saving_throw:=number_percent<=chance;
end;

procedure spell_acid_arrow(ch, victim : GCharacter; sn : GSkill);
var af : GAffect;
begin
  af := nil;
  if (saving_throw(ch.level,victim.point.save_poison,victim)) then
    begin
    act(AT_REPORT,'$N resisted the effects of your spell!',false,ch,nil,victim,TO_CHAR);
    damage(ch,victim,40, cardinal(sn));
    end
  else
    begin
    af.skill := sn;
    af.duration := (ch.level div 8);
    af.apply_type := APPLY_AFFECT;
    af.modifier := AFF_POISON;

    af.applyTo(victim);

    damage(ch,victim,55, cardinal(sn));
    end;
end;

procedure spell_burning_hands(ch,victim:GCharacter; sn : GSkill);
begin
  damage(ch,victim,45, cardinal(sn));
end;

procedure spell_lightning(ch,victim:GCharacter;sn:GSkill);
begin
  act(AT_SPELL,'Your hands burst into lightning!', false,ch,nil,nil,TO_CHAR);
  act(AT_SPELL,'Your ears pop as $n releases $s lightning!', false,ch,nil,nil,TO_ROOM);
  damage(ch,victim,110,cardinal(sn));
end;

procedure spell_magic_missile(ch,victim:GCharacter;sn:GSkill);
begin
  damage(ch,victim,35,cardinal(sn));
end;

procedure spell_poison(ch,victim:GCharacter; sn : GSkill);
var af:GAffect;
begin
  af := nil;
  if saving_throw(ch.level,victim.point.save_poison,victim) then
    begin
    act(AT_REPORT,'Your spell failed!',false,ch,nil,victim,TO_CHAR);
    act(AT_REPORT,'You resisted the effects of $n''s poison!',false,ch,nil,victim,TO_VICT);
    end
  else
    begin
    af.skill := sn;
    af.duration := (ch.level div 8);
    af.apply_type := APPLY_AFFECT;
    af.modifier := AFF_POISON;

    af.applyTo(victim);

    act(AT_SPELL,'You have succesfully poisoned $N!',false,ch,nil,victim,TO_CHAR);
    act(AT_SPELL,'You are poisoned!',false,ch,nil,victim,TO_VICT);
    act(AT_SPELL,'$N has been poisoned!',false,ch,nil,victim,TO_NOTVICT);
    end;
end;

procedure spell_vortex(ch,victim:GCharacter;sn:GSkill);
var dam:integer;
begin
  dam:=rolldice(4,6);
  inc(dam,ch.ability.int div 4);
  damage(ch,victim,dam,cardinal(sn));
end;

procedure spell_winds(ch,victim:GCharacter;sn:GSkill);
var dam:integer;
begin
  dam:=rolldice(4,10);
  inc(dam,ch.ability.int div 3);
  act(AT_SPELL,'You call upon the elements and release your fury!',false,ch,nil,nil,TO_CHAR);
  act(AT_SPELL,'$n calls upon the elements and releases $s fury!',false,ch,nil,nil,TO_ROOM);
  damage(ch,victim,dam,cardinal(sn));
end;

procedure spell_recall(ch,victim:GCharacter;sn:GSkill);
begin
  ch.fromRoom;

  if (ch.IS_EVIL) then
    ch.toRoom(findRoom(ROOM_VNUM_EVIL_PORTAL))
  else
    ch.toRoom(findRoom(ROOM_VNUM_GOOD_PORTAL));

  act(AT_REPORT,'You $B$7implore$A$7 the gods for safety.',false,ch,nil,nil,TO_CHAR);
  act(AT_REPORT,'$n $B$7implores$A$7 the gods for a safe haven.',false,ch,nil,nil,TO_ROOM);
end;

procedure spell_summon(ch,victim:GCharacter;sn:GSkill);
begin
  if victim.position<>POS_FIGHTING then
    begin
    act(AT_SPELL,'You summon $N into the room.',false,ch,nil,victim,TO_CHAR);
    act(AT_SPELL,'$n is summoned out of here!',false,victim,nil,nil,TO_ROOM);

    victim.fromRoom;
    victim.toRoom(ch.room);

    act(AT_SPELL,'$n has summoned $N!',false,ch,nil,victim,TO_ROOM);
    if (victim.position <> POS_STANDING) then
      interpret(victim,'stand');
    end
  else
    act(AT_REPORT,'$N is not in a normal position to be summoned.',false,ch,nil,victim,TO_CHAR);
end;

procedure spell_refresh(ch,victim:GCharacter;sn:GSkill);
var ref:integer;
begin
  ref:=(ch.ability.wis div 2) + 20 + rolldice(5,10);
  victim.point.mv:=UMax(victim.point.mv + ref, victim.point.max_mv);
  act(AT_SPELL,'You feel refreshed.',false,victim,nil,nil,TO_CHAR);
  act(AT_SPELL,'$n looks refreshed.',false,victim,nil,nil,TO_ROOM);
end;

procedure spell_identify(ch,victim:GCharacter;sn:GSkill);
var obj : GObject;
    s:string;
    liq:integer;
const wearpos:array[WEAR_RFINGER..WEAR_EYES] of string=
      ('FINGER','FINGER','NECK','NECK','BODY','HEAD','LEGS',
       'FEET','HANDS','ARMS','SHIELD','ABOUT','WAIST',
       'WRIST','WRIST','FLOATING','HAND','HAND','SHOULDER',
       'SHOULDER','FACE','EAR','EAR','ANKLE','ANKLE','EYES');
const ac_types:array[ARMOR_HAC..ARMOR_LAC] of string=
      ('HAC','BAC','AAC','LAC');
begin
  obj := GObject(victim);

  with obj do
    begin
    case item_type of
        ITEM_WEAPON:s:='weapon';
         ITEM_ARMOR:s:='armor';
          ITEM_FOOD:s:='food';
         ITEM_DRINK:s:='drink';
         ITEM_LIGHT:s:='light';
         ITEM_TRASH:s:='trash';
         ITEM_MONEY:s:='money';
           ITEM_GEM:s:='gem';
        ITEM_CORPSE:s:='corpse';
      ITEM_FOUNTAIN:s:='fountain';
     ITEM_CONTAINER:s:='container';
         ITEM_BLOOD:s:='blood';
        ITEM_PORTAL:s:='portal';
        ITEM_KEY:s:='key'
    else
       s:='unknown object';
    end;
    act(AT_REPORT,'$p$7 is some sort of $B$4'+s+'$A$7.'#13#10,false,ch,obj,nil,TO_CHAR);
    s:='';
    if wear1<>0 then
      s:=wearpos[wear1];
    if wear2<>0 then
      begin
      if s<>'' then
        s:=s+' '+wearpos[wear2]
      else
        s:=wearpos[wear2];
      end;
    if (wear1=0) and (wear2=0) then
      s:='NONE';
    act(AT_REPORT,'Wearing positions $B$7'+s+'$A$7, weight $B$2'+inttostr(weight)+'$A$7 ounce(s).',false,ch,obj,nil,TO_CHAR);
    s:='';
    if IS_SET(flags,OBJ_GLOW) then
      s:=s+'GLOWING ';
    if IS_SET(flags,OBJ_HUM) then
      s:=s+'HUMMING ';
    if IS_SET(flags,OBJ_ANTI_GOOD) then
      s:=s+'ANTI_GOOD ';
    if IS_SET(flags,OBJ_ANTI_EVIL) then
      s:=s+'ANTI_EVIL ';
    if IS_SET(flags,OBJ_LOYAL) then
      s:=s+'LOYAL ';
    if IS_SET(flags,OBJ_NOREMOVE) then
      s:=s+'NOREMOVE ';
    if IS_SET(flags,OBJ_NODROP) then
      s:=s+'NODROP ';
    if IS_SET(flags,OBJ_CLANOBJECT) then
      s:=s+'CLANOBJECT ';
    if IS_SET(flags,OBJ_MISSILE) then
      s:=s+'MISSILE ';
    if IS_SET(flags,OBJ_NOSAC) then
      s:=s+'NOSAC ';
    if length(s)>1 then
      begin
      delete(s,length(s),1);
      act(AT_REPORT,'Flags: [$B$7'+s+'$A$7]',false,ch,obj,nil,TO_CHAR);
      end;
    case item_type of
      ITEM_WEAPON:act(AT_REPORT,'Damage roll $B$3'+inttostr(value[2])+'d'+
                                inttostr(value[3])+'$A$7, type $B$7'+attack_table[value[4],1]+'$A$7.',false,ch,obj,nil,TO_CHAR);
       ITEM_ARMOR:act(AT_REPORT,'Armor $B$7'+ac_types[value[2]]+'$A$7, $B$3'+
                                inttostr(value[3])+'$A$7 AC.',false,ch,obj,nil,TO_CHAR);
       ITEM_DRINK,
    ITEM_FOUNTAIN:begin
                  liq:=value[3];
                  act(AT_REPORT,'Liquid "'+liq_types[liq].name+'", affects '+
                      inttostr(liq_types[liq].affect[1])+' '+inttostr(liq_types[liq].affect[2])+
                      ' '+inttostr(liq_types[liq].affect[3])+' '+inttostr(liq_types[liq].affect[4])+
                      '.',false,ch,obj,nil,TO_CHAR);
                  end;
         ITEM_GEM:act(AT_REPORT,'Spell level: '+inttostr(value[2])+', charged '+
                      'mana: '+inttostr(value[3])+'.',false,ch,obj,nil,TO_CHAR);
    end;
    end;
end;

procedure spell_affect(ch,caster:GCharacter; sn : GSkill);
var
   node : GListNode;
   aff : GAffect;
begin
  removeAffectSkill(ch, sn);
  
  node := sn.affects.head;

  while (node <> nil) do
    begin
    aff := node.element;

    aff.applyTo(ch);

    node := node.next;
    end;
end;

procedure spell_generic(ch,victim:GCharacter; sn : GSkill);
var vict,check:GCharacter;
    node : GListNode;
    dam:integer;
begin
  with sn do
    begin
    check := nil;
    vict := nil;

    case target of
      TARGET_OFF_ATTACK,
      TARGET_DEF_SINGLE,
       TARGET_DEF_WORLD:begin
                        node := victim.node_world;
                        vict := victim;
                        end;
        TARGET_OFF_AREA:begin
                        { check fighting }
                        if (ch.fighting <> nil) then
                          check := ch.fighting
                        else
                          check := victim;

                        node := ch.room.chars.head;

                        while (node <> nil) do
                          begin
                          vict := node.element;

                          if (vict <> ch) then
                            begin
                            if (vict.IS_NPC or vict.IS_SAME_ALIGN(check)) then
                              break;
                            end;

                          node := node.next;
                          end;
                        end;
        TARGET_DEF_SELF:begin
                        node := ch.node_room;
                        vict := ch;
                        end;
        TARGET_DEF_AREA:begin
                        node := ch.room.chars.head;

                        while (node <> nil) do
                          begin
                          vict := node.element;

                          if (ch.IS_SAME_ALIGN(vict)) and (not vict.IS_NPC) then
                             break;

                          node := node.next;
                          end;
                        end;
      else
        begin
        bugreport('spell generic', 'magic.pas', 'illegal target ' + inttostr(target),
                  'The specified target is unknown.');
        exit;
        end;
    end;

    if (vict = nil) then
      begin
      ch.sendBuffer('They are not here.'#13#10);
      
      exit;
      end;

    if (length(start_char) > 0) then
      act(AT_SPELL,start_char,false,ch,nil,vict,TO_CHAR);
    if (length(start_vict) > 0) then
      act(AT_SPELL,start_vict,false,ch,nil,vict,TO_VICT);
    if (length(start_room) > 0) then
      act(AT_SPELL,start_room,false,ch,nil,vict,TO_ROOM);

    repeat
      if (length(hit_vict) > 0) and (ch <> vict) and (not vict.CHAR_DIED) then
        begin
        act(AT_SPELL,hit_vict,false,ch,nil,vict,TO_VICT);

        if (length(hit_room)>0) then
          begin
          act(AT_SPELL,hit_room,false,ch,nil,vict,TO_NOTVICT);
          act(AT_SPELL,hit_room,false,ch,nil,vict,TO_CHAR);
          end;
        end
      else
      if (length(hit_room)>0) then
        act(AT_SPELL,hit_room,false,ch,nil,vict,TO_ROOM);

      if (ch = vict) and (not ch.CHAR_DIED) then
        begin
        if (length(hit_vict) > 0) then
          act(AT_SPELL,hit_vict,false,ch,nil,ch,TO_CHAR)
        else
        if (length(hit_char) > 0) then
          act(AT_SPELL,hit_char,false,ch,nil,ch,TO_CHAR);
        end
      else
      if (length(hit_char) > 0) then
        act(AT_SPELL,hit_char,false,ch,nil,vict,TO_CHAR);

      if (target <= TARGET_OFF_AREA) then
       if (dicenum>0) and (dicesize>0) then
        begin
        dam:=rolldice(dicenum,dicesize)+diceadd;
        damage(ch,vict,dam, cardinal(sn));
        end;

      if (not vict.CHAR_DIED) and (affects.getSize() > 0) then
        spell_affect(vict,ch,sn);

      case target of
        TARGET_OFF_ATTACK,
        TARGET_DEF_SINGLE,
         TARGET_DEF_WORLD: vict := nil;
          TARGET_OFF_AREA:begin
                          while (node <> nil) do
                            begin
                            node := node.next;

                            if (node = nil) then
                              begin
                              vict := nil;
                              break;
                              end;

                            vict := node.element;

                            if (vict <> ch) then
                              begin
                              if (vict.IS_NPC or vict.IS_SAME_ALIGN(check)) then
                                break;
                              end;
                            end;
                          end;
          TARGET_DEF_SELF: vict := nil;
          TARGET_DEF_AREA:begin
                          while (node <> nil) do
                            begin
                            node := node.next;

                            if (node = nil) then
                              begin
                              vict := nil;
                              break;
                              end;

                            vict := node.element;

                            if (ch.IS_SAME_ALIGN(vict)) and (not vict.IS_NPC) then
                               break;
                            end;
                          end;
        else
          begin
          bugreport('spell generic', 'magic.pas', 'illegal target ' + inttostr(target),
                    'The specified target is unknown.');
          exit;
          end;
      end;

    until (vict = nil);
    end;
end;

procedure spell_dummy(ch,victim:GCharacter; sn : GSkill);
begin
end;

function findFunc(s : string) : SPEC_FUNC;
begin
  findFunc := spell_dummy;

  if (s = 'spell_acid_arrow') then
    Result := spell_acid_arrow
  else
  if s='spell_burning_hands' then
    findFunc:=spell_burning_hands
  else
  if s='spell_generic' then
    findFunc:=spell_generic
  else
  if s='spell_identify' then
    findFunc:=spell_identify
  else
  if s='spell_lightning' then
    findFunc:=spell_lightning
  else
  if s='spell_magic_missile' then
    findFunc:=spell_magic_missile
  else
  if s='spell_poison' then
    findFunc:=spell_poison
  else
  if s='spell_summon' then
    findFunc:=spell_summon
  else
  if s='spell_vortex' then
    findFunc:=spell_vortex
  else
  if s='spell_winds' then
    findFunc:=spell_winds
  else
  if s='spell_recall' then
    findFunc:=spell_recall
  else
  if s='spell_refresh' then
    findFunc:=spell_refresh
  else
    bugreport('spell', 'magic.pas', 'spell ' + s + ' not found',
              'The specified spell could not be found.');
end;

procedure say_spell(ch:GCharacter; name : string);
const syl_table:array[1..49,1..2] of string=(
        (' ',' '),
        ('ar','abra'),
        ('au','kada'),
        ('bless','fido'),
        ('blind','nose'),
        ('bur','mosa'),
        ('cu','judi'),
        ('de','oculo'),
        ('en','unso'),
        ('light','dies'),
        ('lo','hi'),
        ('mor','zak'),
        ('move','sido'),
        ('ness','lacri'),
        ('ning','illa'),
        ('per','duda'),
        ('ra','gru'),
        ('re','candus'),
        ('son','sabru'),
        ('tect','infra'),
        ('tri','cula'),
        ('ven','nofo'),
        ('a','a'), ('b','b'), ( 'c', 'q' ), ( 'd', 'e' ),
        ( 'e', 'z' ), ( 'f', 'y' ), ( 'g', 'o' ), ( 'h', 'p' ),
        ( 'i', 'u' ), ( 'j', 'y' ), ( 'k', 't' ), ( 'l', 'r' ),
        ( 'm', 'w' ), ( 'n', 'i' ), ( 'o', 'a' ), ( 'p', 's' ),
        ( 'q', 'd' ), ( 'r', 'f' ), ( 's', 'g' ), ( 't', 'h' ),
        ( 'u', 'j' ), ( 'v', 'z' ), ( 'w', 'x' ), ( 'x', 'n' ),
        ( 'y', 'l' ), ( 'z', 'k' ),
        ( '', '' ));
var buf, s : string;
    p : integer;
    a, len, syl : integer;
begin
  buf := '';
  a := 1;
  p := 1;

  repeat
    len := 1;
    s := copy(name, p, length(name) - p + 1);

    for syl := 1 to 49 do
      begin
      if (pos(syl_table[syl,1], s) = 1) then
        begin
        len := length(syl_table[syl,1]);
        buf := buf + syl_table[syl,2];
        break;
        end;
      end;

    inc(p, len);
  until (p > length(name));

  act(AT_PURPLE,'You utter the words '''+buf+'''',false,ch,nil,nil,TO_CHAR);
  act(AT_PURPLE,'$n utter the words '''+buf+'''',false,ch,nil,nil,TO_ROOM);
end;

procedure magic_timer(ch,victim:GCharacter;sn:GSkill);
var func : SPEC_FUNC;
begin
  if (sn = nil) then
    exit;

  func := sn.func;

  if ((sn.target in [TARGET_DEF_WORLD,TARGET_OBJECT]) or
   (victim.room=ch.room)) and (not victim.CHAR_DIED) then
     begin
     if skill_success(ch,sn) or (ch.IS_IMMORT) or (ch.IS_NPC) then      { immo's don't fail :) }
       begin
       if (sn.target <= TARGET_OFF_AREA) then
        if (not victim.CHAR_DIED) then
         begin
         ch.position := POS_FIGHTING;
         ch.fighting := victim;

         if (victim.position < POS_FIGHTING) then
           begin
           victim.fighting := ch;
           victim.position := POS_FIGHTING;
           end;
         end
       else
         ch.position := POS_STANDING;

       say_spell(ch, sn.name);

       improve_skill(ch, sn);

       if (assigned(func)) then
         func(ch, victim, sn);

       if (not ch.IS_IMMORT) and (not ch.IS_NPC) then
         begin
         ch.cast_timer := 1;
         dec(ch.point.mana, sn.min_mana);
         end;

       if (ch.fighting <> nil) then
         ch.position := POS_FIGHTING
       else
         ch.position := POS_STANDING;
       end
     else
       begin
       dec(ch.point.mana, sn.min_mana div 2);

       if (sn.target < TARGET_OFF_AREA) then
         begin
         ch.position := POS_FIGHTING;
         ch.fighting := victim;

         if (victim.position < POS_FIGHTING) then
           begin
           victim.fighting := ch;
           victim.position := POS_FIGHTING;
           end;
         end
       else
         ch.position := POS_STANDING;

       act(AT_REPORT, 'You have lost your concentration.',false,ch,nil,nil,TO_CHAR);

       if (ch.fighting <> nil) then
         ch.position := POS_FIGHTING
       else
         ch.position := POS_STANDING;
       end;
     end
   else
     begin
     act(AT_REPORT,'They are not here.',false,ch,nil,nil,TO_CHAR);
     
     ch.position := POS_STANDING;
     end;

  ch.emptyBuffer;
end;

end.
