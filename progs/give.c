require "glib.c"

void onAct(external ch, external target, string arg)
{
  if (match(arg, "* bows*") == true)
  {
    do("say Good day, " + target.name);
  }
}

void onGive(external ch, external target, external obj)
{
  if (obj.vnum == 104)
  {
    do("say Thank you!");
  }
}
