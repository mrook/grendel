{
	Delphi IMC3 Client - Interface with core

	Based on client code by Samson of Alsherok.

	$Id: imc3_main.pas,v 1.1 2003/10/01 14:55:19 ***REMOVED*** Exp $
}

unit imc3_main;

interface

implementation

uses
	SysUtils,
	imc3_core;

var
 	i3: GInterMud;


initialization
	i3 := GInterMud.Create(true);

finalization
	i3.shutdown();
	i3.Terminate();
	i3.Free();

end.