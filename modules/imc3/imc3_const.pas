{
	Delphi IMC3 Client - Constants

	Based on client code by Samson of Alsherok.

	$Id: imc3_const.pas,v 1.1 2003/10/03 21:00:28 ***REMOVED*** Exp $
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
	I3_CHANLIST_FILE = ModulesDir + 'i3_chanlist.xml';
	I3_MUDLIST_FILE = ModulesDir + 'i3_mudlist.xml';
	I3_CONFIG_FILE = ModulesDir + 'i3_config.xml';
	
	
implementation


end.