require "grendel.c"

void onTick(external ch)
{ 
  do("say tick!");
}

void onAct(external ch, external target, string arg)
{
  sleep(2);
  do("yell hey he said " + arg);
}

