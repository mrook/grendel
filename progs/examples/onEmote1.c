require "glib.c"

void onEmoteTarget(external victim, external actor, string arg)
{
  int x;
  x = random(3);
  arg = uppercase(arg);

  if (arg == "SNOWBALL" && x == 1)
  {
    sleep(1);

    do("say How dare you!");
    do("slap " + target.actor);    
  }
}