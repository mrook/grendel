require "glib.c"

void onTick(external ch)
{
  int x;
  
  x = random(5);

  if(x == 0)
  {
    do("mutter self");
  }
  else
  if(x == 1)
  {
    do("horse self");
  }
  else
  if(x == 2)
  {
    do("dance self");
  }
  else
  if(x == 3)
  {
    do("scream");
  }
  else
  {
    do("spin");
  }
}