require "glib.c"

void onTick(external ch)
{
  String move;
  String invert_move;
  int x;
  int y;
  y = random(4);
  x = random(10);

  if(y == 0)
  {
    move = "north";
    invert_move = "south";
  }
  if(y == 1)
  {
    move = "east";
    invert_move = "west";
  }
  if(y == 2)
  {
    move = "south";
    invert_move = "north";
  }
  if(y == 3)
  {
    move = "west";
    invert_move = "east";
  }
  if(x < 2)
  {
    do("say I have no time to waste!");
    do("open " + move);
    do(move);
    do("close " + invert_move);
  }
  else
  {
    do("emote hurries himself");
    do("open " + move);
    do(move);
    do("close " + invert_move);
  }
}