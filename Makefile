#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Main Makefile - Use GNU make!
#
# $Id: Makefile,v 1.22 2004/05/06 20:43:34 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CP=cp
	RM=rm
else
	WIN32=1
ifeq ($(OS), Windows_NT)
	RM=cmd /c del
	CP=cmd /c copy
else
	RM=del
	CP=copy
endif
endif


all:	
	$(MAKE) -C src
ifdef WIN32
	makejcldbg -J 'src\*.map'
	makejcldbg -J 'src\modules\*.map'
	$(CP) 'src\grendel.exe'
	$(CP) 'src\convert.exe'
	$(CP) 'src\helper.exe'
	$(CP) 'src\grendelservice.exe'
	$(CP) 'src\core.bpl'
	$(CP) 'src\*.jdbg'
	$(CP) 'src\copyover.exe'
	$(CP) 'src\gmc\gmcc.exe'
	$(CP) 'src\gmc\gasm.exe'
	$(CP) 'src\modules\*.bpl' modules
	$(CP) 'src\modules\*.jdbg' modules
endif
ifdef LINUX
	$(CP) src/grendel .
	$(CP) src/convert .
	$(CP) src/bplcore.so .
	$(CP) src/*.map .
	$(CP) src/gmc/gmcc .
	$(CP) src/gmc/gasm .
	$(CP) src/modules/bpl*.so modules
endif
	

clean:
	$(MAKE) -C src clean
ifdef WIN32	
	$(RM) *.bpl
	$(RM) grendel.exe
	$(RM) copyover.exe
	$(RM) helper.exe
	$(RM) gmcc.exe
	$(RM) gasm.exe
	$(RM) *.jdbg
	$(RM) 'modules\*.bpl'
	$(RM) 'modules\*.jdbg'
endif
ifdef LINUX
	$(RM) -f bpl*.so
	$(RM) -f grendel
	$(RM) -f gmcc
	$(RM) -f gasm
	$(RM) -f modules/bpl*.so
endif

test:
	$(MAKE) -C src/tests test
