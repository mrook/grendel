require "glib.c"

void onGreet(external ch, external target)
{
  do("say Me welcome " + target.Pname);
  do("say You buy something from me?"); 
}

void onFight(external ch, external target)
{
  int x;
  x = random(100);

  if(x =< 20)
  {
    do("say Please, Scralemon want live");
    do("say Stop fight, me afraid to die!");
  }
}
