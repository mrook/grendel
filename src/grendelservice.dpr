{
	Summary:
		NT Service Application
	
	## $Id: grendelservice.dpr,v 1.1 2004/03/22 14:55:49 ***REMOVED*** Exp $
}

program grendelservice;

uses
  SvcMgr,
  servicemain in 'servicemain.pas' {ServiceGrendel: TService};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TServiceGrendel, ServiceGrendel);
  Application.Run;
end.
