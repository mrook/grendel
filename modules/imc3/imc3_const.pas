{
	Delphi IMC3 Client - Constants

	Based on client code by Samson of Alsherok.

	$Id: imc3_const.pas,v 1.3 2003/10/31 11:29:29 ***REMOVED*** Exp $
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
					 
						( "<MUD TRANSLATION>", "PINKFISH", "ANSI TRANSLATION" )
					}
						
					{ Foreground Standard Colors }
					('&x', '%^BLACK%^',   '\033[0;0;30m'),		{ Black }
					('&r', '%^RED%^',     '\033[0;0;31m'),		{ Dark Red }
					('&g', '%^GREEN%^',   '\033[0;0;32m'),		{ Dark Green }
					('&O', '%^ORANGE%^',  '\033[0;0;33m'),		{ Orange/Brown }
					('&b', '%^BLUE%^',    '\033[0;0;34m'),		{ Dark Blue }
					('&p', '%^MAGENTA%^', '\033[0;0;35m'),		{ Purple/Magenta }
					( '&c', '%^CYAN%^',    '\033[0;0;36m' ), { Cyan }
					( '&w', '%^WHITE%^',   '\033[0;0;37m' ), { Grey }

					{ Background colors }
					( '(x', '%^B_BLACK%^',   '\033[40m' ), { Black }
					( '(r', '%^B_RED%^',     '\033[41m' ), { Red }
					( '(g', '%^B_GREEN%^',   '\033[42m' ), { Green }
					( '(O', '%^B_ORANGE%^',  '\033[43m' ), { Orange }
					( '(Y', '%^B_YELLOW%^',  '\033[43m' ), { Yellow, which may as well be orange since ANSI doesn't do that }
					( '(B', '%^B_BLUE%^',    '\033[44m' ), { Blue }
					( '(p', '%^B_MAGENTA%^', '\033[45m' ), { Purple/Magenta }
					( '(c', '%^B_CYAN%^',    '\033[46m' ), { Cyan }
					( '(w', '%^B_WHITE%^',   '\033[47m' ), { White }

					{ Text Affects }
					( '&d', '%^RESET%^',     '\033[0m' ), { Reset Text }
					( '&D', '%^RESET%^',     '\033[0m' ), { Reset Text }
					( '&L', '%^BOLD%^',      '\033[1m' ), { Bolden Text(Brightens it) }
					( '&*', '%^EBOLD%^',	 '\033[0m' ), { Assumed to be a reset tag to stop bold }
					( '&u', '%^UNDERLINE%^', '\033[4m' ), { Underline Text }
					( '&$', '%^FLASH%^',     '\033[5m' ), { Blink Text }
					( '&i', '%^ITALIC%^',    '\033[3m' ), { Italic Text }
					( '&v', '%^REVERSE%^',   '\033[7m' ), { Reverse Background and Foreground Colors }
					( '&s', '%^STRIKEOUT%^', '\033[9m' ), { Strikeover }

					{ Foreground extended colors }
					( '&z', '%^BLACK%^%^BOLD%^',   '\033[0;1;30m' ), { Dark Grey }
					( '&R', '%^RED%^%^BOLD%^',     '\033[0;1;31m' ), { Red }
					( '&G', '%^GREEN%^%^BOLD%^',   '\033[0;1;32m' ), { Green }
					( '&Y', '%^YELLOW%^',          '\033[0;1;33m' ), { Yellow }
					( '&B', '%^BLUE%^%^BOLD%^',    '\033[0;1;34m' ), { Blue }
					( '&P', '%^MAGENTA%^%^BOLD%^', '\033[0;1;35m' ), { Pink }
					( '&C', '%^CYAN%^%^BOLD%^',    '\033[0;1;36m' ), { Light Blue }
					( '&W', '%^WHITE%^%^BOLD%^',   '\033[0;1;37m' ), { White }

					{ Blinking foreground standard color }
					( ')x', '%^BLACK%^%^FLASH%^',           '\033[0;5;30m' ), { Black }
					( ')r', '%^RED%^%^FLASH%^',             '\033[0;5;31m' ), { Dark Red }
					( ')g', '%^GREEN%^%^FLASH%^',           '\033[0;5;32m' ), { Dark Green }
					( ')O', '%^ORANGE%^%^FLASH%^',          '\033[0;5;33m' ), { Orange/Brown }
					( ')b', '%^BLUE%^%^FLASH%^',            '\033[0;5;34m' ), { Dark Blue }
					( ')p', '%^MAGENTA%^%^FLASH%^',         '\033[0;5;35m' ), { Magenta/Purple }
					( ')c', '%^CYAN%^%^FLASH%^',            '\033[0;5;36m' ), { Cyan }
					( ')w', '%^WHITE%^%^FLASH%^',           '\033[0;5;37m' ), { Grey }
					( ')z', '%^BLACK%^%^BOLD%^%^FLASH%^',   '\033[1;5;30m' ), { Dark Grey }
					( ')R', '%^RED%^%^BOLD%^%^FLASH%^',     '\033[1;5;31m' ), { Red }
					( ')G', '%^GREEN%^%^BOLD%^%^FLASH%^',   '\033[1;5;32m' ), { Green }
					( ')Y', '%^YELLOW%^%^FLASH%^',          '\033[1;5;33m' ), { Yellow }
					( ')B', '%^BLUE%^%^BOLD%^%^FLASH%^',    '\033[1;5;34m' ), { Blue }
					( ')P', '%^MAGENTA%^%^BOLD%^%^FLASH%^', '\033[1;5;35m' ), { Pink }
					( ')C', '%^CYAN%^%^BOLD%^%^FLASH%^',    '\033[1;5;36m' ), { Light Blue }
					( ')W', '%^WHITE%^%^BOLD%^%^FLASH%^',   '\033[1;5;37m' )  { White }
				);

	
implementation


end.