{
	Delphi IMC3 Client - Constants

	Based on client code by Samson of Alsherok.

	$Id: imc3_const.pas,v 1.4 2003/10/31 15:18:02 ***REMOVED*** Exp $
}
unit imc3_const;

interface


uses
	constants;

const
	MAX_I3HISTORY = 20;
	MAX_IPS = 8192 * 16;
	MAX_READ = 4096;

const
	I3_TELL 			= BV00;
	I3_DENYTELL 	= BV01;
	I3_BEEP				= BV02;
	I3_DENYBEEP 	= BV03;
	I3_INVIS			= BV04;
	I3_PRIVACY		= BV05;
	I3_DENYFINGER	= BV06;
	I3_AFK				= BV07;
	I3_COLOR			= BV08;

const
	I3_CHANLIST_FILE = ModulesDir + 'i3_chanlist.xml';
	I3_MUDLIST_FILE = ModulesDir + 'i3_mudlist.xml';
	I3_CONFIG_FILE = ModulesDir + 'i3_config.xml';
	
const
	I3MAX_ANSI = 50;
	I3_ANSI_CONVERSION : array[1..I3MAX_ANSI,1..3] of string = 
				(
					{
						Conversion Format Below:
					 
						( '<MUD TRANSLATION>', 'PINKFISH', 'ANSI TRANSLATION' )
					}
						
					{ Foreground Standard Colors }
					( '&x', '%^BLACK%^',   #27'[0;0;30m' ),	{ Black }
					( '&r', '%^RED%^',     #27'[0;0;31m' ),	{ Dark Red }
					( '&g', '%^GREEN%^',   #27'[0;0;32m' ),	{ Dark Green }
					( '&O', '%^ORANGE%^',  #27'[0;0;33m' ),	{ Orange/Brown }
					( '&b', '%^BLUE%^',    #27'[0;0;34m' ),	{ Dark Blue }
					( '&p', '%^MAGENTA%^', #27'[0;0;35m '),	{ Purple/Magenta }
					( '&c', '%^CYAN%^',    #27'[0;0;36m' ), { Cyan }
					( '&w', '%^WHITE%^',   #27'[0;0;37m' ), { Grey }

					{ Background colors }
					( '(x', '%^B_BLACK%^',   #27'[40m' ), { Black }
					( '(r', '%^B_RED%^',     #27'[41m' ), { Red }
					( '(g', '%^B_GREEN%^',   #27'[42m' ), { Green }
					( '(O', '%^B_ORANGE%^',  #27'[43m' ), { Orange }
					( '(Y', '%^B_YELLOW%^',  #27'[43m' ), { Yellow, which may as well be orange since ANSI doesn't do that }
					( '(B', '%^B_BLUE%^',    #27'[44m' ), { Blue }
					( '(p', '%^B_MAGENTA%^', #27'[45m' ), { Purple/Magenta }
					( '(c', '%^B_CYAN%^',    #27'[46m' ), { Cyan }
					( '(w', '%^B_WHITE%^',   #27'[47m' ), { White }

					{ Text Affects }
					( '&d', '%^RESET%^',     #27'[0m' ), { Reset Text }
					( '&D', '%^RESET%^',     #27'[0m' ), { Reset Text }
					( '&L', '%^BOLD%^',      #27'[1m' ), { Bolden Text(Brightens it) }
					( '&*', '%^EBOLD%^',	 #27'[0m' ), { Assumed to be a reset tag to stop bold }
					( '&u', '%^UNDERLINE%^', #27'[4m' ), { Underline Text }
					( '&$', '%^FLASH%^',     #27'[5m' ), { Blink Text }
					( '&i', '%^ITALIC%^',    #27'[3m' ), { Italic Text }
					( '&v', '%^REVERSE%^',   #27'[7m' ), { Reverse Background and Foreground Colors }
					( '&s', '%^STRIKEOUT%^', #27'[9m' ), { Strikeover }

					{ Foreground extended colors }
					( '&z', '%^BLACK%^%^BOLD%^',   #27'[0;1;30m' ), { Dark Grey }
					( '&R', '%^RED%^%^BOLD%^',     #27'[0;1;31m' ), { Red }
					( '&G', '%^GREEN%^%^BOLD%^',   #27'[0;1;32m' ), { Green }
					( '&Y', '%^YELLOW%^',          #27'[0;1;33m' ), { Yellow }
					( '&B', '%^BLUE%^%^BOLD%^',    #27'[0;1;34m' ), { Blue }
					( '&P', '%^MAGENTA%^%^BOLD%^', #27'[0;1;35m' ), { Pink }
					( '&C', '%^CYAN%^%^BOLD%^',    #27'[0;1;36m' ), { Light Blue }
					( '&W', '%^WHITE%^%^BOLD%^',   #27'[0;1;37m' ), { White }

					{ Blinking foreground standard color }
					( ')x', '%^BLACK%^%^FLASH%^',           #27'[0;5;30m' ), { Black }
					( ')r', '%^RED%^%^FLASH%^',             #27'[0;5;31m' ), { Dark Red }
					( ')g', '%^GREEN%^%^FLASH%^',           #27'[0;5;32m' ), { Dark Green }
					( ')O', '%^ORANGE%^%^FLASH%^',          #27'[0;5;33m' ), { Orange/Brown }
					( ')b', '%^BLUE%^%^FLASH%^',            #27'[0;5;34m' ), { Dark Blue }
					( ')p', '%^MAGENTA%^%^FLASH%^',         #27'[0;5;35m' ), { Magenta/Purple }
					( ')c', '%^CYAN%^%^FLASH%^',            #27'[0;5;36m' ), { Cyan }
					( ')w', '%^WHITE%^%^FLASH%^',           #27'[0;5;37m' ), { Grey }
					( ')z', '%^BLACK%^%^BOLD%^%^FLASH%^',   #27'[1;5;30m' ), { Dark Grey }
					( ')R', '%^RED%^%^BOLD%^%^FLASH%^',     #27'[1;5;31m' ), { Red }
					( ')G', '%^GREEN%^%^BOLD%^%^FLASH%^',   #27'[1;5;32m' ), { Green }
					( ')Y', '%^YELLOW%^%^FLASH%^',          #27'[1;5;33m' ), { Yellow }
					( ')B', '%^BLUE%^%^BOLD%^%^FLASH%^',    #27'[1;5;34m' ), { Blue }
					( ')P', '%^MAGENTA%^%^BOLD%^%^FLASH%^', #27'[1;5;35m' ), { Pink }
					( ')C', '%^CYAN%^%^BOLD%^%^FLASH%^',    #27'[1;5;36m' ), { Light Blue }
					( ')W', '%^WHITE%^%^BOLD%^%^FLASH%^',   #27'[1;5;37m' )  { White }
				);

	
implementation


end.