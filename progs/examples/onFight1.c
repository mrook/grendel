require "glib.c"

void onGreet(external ch, external target)
{
   if(target.alignment == -1000)
   {
     do("say We don't want you people here!");
     do("kill " + target.name);
   }
   else
   {
     do("Welcome traveller, can I offer you my services?"); 
   }
}

void onFight(external ch, external target)
{
   int x;
   x = random(100);

   if(x =< 75)
   {
      do("cast 'magic missile' " + target.name);

      sleep(1);

      if(x =< 15)
      {
         do("cast 'vortex' " + target.name);
      }
   }
}
