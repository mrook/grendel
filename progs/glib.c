void terminate()
{
  asm
	{
		"HALT"
	}
}

float sin(float x);
float cos(float x);
float tan(float x);

int random(int x);

string left(string src, string delim);
string right(string src, string delim);
bool match(string src, string pattern);
string IntToStr(int x);
int StrToInt(string s);
string uppercase(string s);

bool is_npc(external target);
