require "glib.c"

void onFight(external ch, external target)
{
   int x;
   x = random(100);
	
   if(x =< 75)
   {
      do("throw " + target.Pname);

      if(x =< 60)
      {
         do("disarm " + target.Pname);
      }
   }
}
