{
	Delphi IMC3 Client - Interface with core

	Based on client code by Samson of Alsherok.

	$Id: imc3_main.pas,v 1.2 2003/10/02 08:23:21 ***REMOVED*** Exp $
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
	i3.Terminate();

	{ Give thread a chance to stop }
	Sleep(10);

	i3.Free();

end.