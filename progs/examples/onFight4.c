require "glib.c"

void onFight(external ch, external target)
{
  int x;
  
  x = random(6);

  if(x == 3)
  {
    do("cast summon 'orcish daemon'");
  }
  else
  if(x == 2)
  {
    do("cast 'magic missile' " + target.name);
  }
  else
  if(x == 4)
  {
    do("cast 'blindness' " + target.name);
  }
}