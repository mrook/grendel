require "glib.c"

void onGreet(external ch, external target)
{
   int x;
   x = random(100);

   if (x =< 80)
   {
      do("tell " + target.Pname + " Do you want a drink?");

      if (x =< 10)
      {
         do("tell " + target.Pname + " Well... ok, this one is on the house");
         do("give beer " + target.Pname);
      }
   }
}
