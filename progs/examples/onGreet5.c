require "glib.c"

void onGreet(external ch, external target)
{ 
  do("say Rest for a while and let me heal your wounds");

  if(target.hp < target.max_hp)
  {
    do("cast 'cure light' " + target.Pname);
  }
  
  sleep(5);

  if(target.mv < target.max_mv)
  {
    do("cast 'refresh' " + target.Pname);
  }
  
  sleep(5);
}
