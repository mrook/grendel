{
  Summary:
  	Main test runner
  	
  ## $Id: tests.dpr,v 1.1 2004/02/21 17:44:05 ***REMOVED*** Exp $
}

program tests;

{$APPTYPE CONSOLE}


uses
	TextTestRunner,
	TestFramework,
	test_socket;


begin
	TextTestRunner.RunRegisteredTests(rxbHaltOnFailures);
end.