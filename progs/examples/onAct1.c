require "glib.c"

void onAct(external ch, external target, string arg)
{
  arg = uppercase(arg);

  if(match(uppercase(arg), "*FREEDOM BACK*") == true)
  {
    do("say So you want your freedom back? Well, " + target.Pname + ", the only thing " +
       "you'll have to do is kill this ferocious beast. Good luck, you'll need it");

    sleep(2);

    do("unlock south");
    do("open south");

    sleep(10);

    do("close south");
    do("lock south");
  }
}