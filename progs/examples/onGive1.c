void onGive(external ch, external target, string obj)
{
  if(obj.Ovnum == 121)
  {
    do("gasp");
    dO("say You found the soul of that nasty lumberjack who betrayed me long time ago! " +
       "Let me give you this precious ornament as a reward for what you've done!");
    do("oload 1003");
    do("give thievery " + target.Pname);
  } 
}