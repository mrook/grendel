require "glib.c"

void onAct(external ch, external target, string arg)
{
  if(match(uppercase(arg), "*HELLO*") == true)
  {
    sleep(1);

    do("say Hello " + target.name + ", how are you today?");
  }

  if(match(uppercase(arg), "*FINE*") == true)
  {
    sleep(1);

    do("say Very well, good luck on your travels");
    do("tip " + target.name);
  }
}
