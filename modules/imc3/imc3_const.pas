{
	Delphi IMC3 Client - Constants

	Based on client code by Samson of Alsherok.

	$Id: imc3_const.pas,v 1.2 2003/10/29 12:58:09 ***REMOVED*** Exp $
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
	
	
implementation


end.