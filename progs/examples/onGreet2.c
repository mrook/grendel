void onGreet(external ch, external target)
{ 
  string title;

  if(target.sex == 0)
  {
    title = "Sir";
  }
  else
  if(target.sex == 1)
  {
    title = "my Lady";
  }
  else
  {
    title = "";
  }

  do("say Welcome " + title);
}