require "glib.c"

void onGreet(external ch, external target)
{
   int x;
   string king;
   fugking = "Nemesis";
   x = random(100);

   do("say You can rest safely here. Can I help you perhaps?");

   if(target.Pname == king)
   {
      do("kneel " + king);
      do("say Welcome back, my friend. Allow me to heal you");
      do("emote stands up");
      do("cast 'heal' " + king);

      sleep(3);

      do("say That must feel better");
   }

   if (x =< 60)
   {
      do("cast 'cure light' " + king);

      if(x =< 1)
      {
         if(target.Pname == king)
         {
            do("say I asume you can use this on your travels, Mighty One");
            do("remove robe");
            do("give robe " + king);
            do("say Take good care of it, " + king);
            do("pat " + king);
         }
      }
   }
}
