require "glib.c"

void onEmoteTarget(external ch, external target, string name)
{
	if ((name == "BOW") && (ch.name == "Syra"))
	{
		do("say Good day, " + target.name + "!");
	}
}

void onAct(external ch, external target, string arg)
{
}


export onEmoteTarget
export onAct
