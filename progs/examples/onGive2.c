require "glib.c"

void onGive(external ch, external target, external obj)
{
  int x;
  int value;
  string objname;

  x = random(4);
  value = obj.Ocost;
  objname = obj.Oname;

  if(x == 1)
  {
    sleep(1);

    do("say most interesting...");
  }
  else
  {
    sleep(1);
   
    do("hmm");
  }

  sleep(1);

  do("say I would give " + value + " coins for it.");

  sleep(1);

  do("give '" + objname + "' " + target.Pname);
}