#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Main Makefile - Use GNU make!
#
# $Id: Makefile,v 1.16 2004/02/21 17:47:28 ***REMOVED*** Exp $
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
	$(CP) 'src\grendel.exe'
	$(CP) 'src\grendel.map'
	$(CP) 'src\core.bpl'
	$(CP) 'src\core.map'
	$(CP) 'src\copyover.exe'
	$(CP) 'src\gmc\gmcc.exe'
	$(CP) 'src\gmc\gasm.exe'
	$(CP) 'src\modules\*.bpl' modules
	$(CP) 'src\modules\*.map' modules
endif
ifdef LINUX
	$(CP) src/grendel .
	$(CP) src/grendel.map .
	$(CP) src/bplcore.so .
	$(CP) src/bplcore.map .
	$(CP) src/gmc/gmcc .
	$(CP) src/gmc/gasm .
	$(CP) src/modules/bpl*.so modules
	$(CP) src/modules/*.map modules
endif
	

clean:
	$(MAKE) -C src clean
ifdef WIN32	
	$(RM) *.bpl
	$(RM) grendel.exe
	$(RM) copyover.exe
	$(RM) gmcc.exe
	$(RM) gasm.exe
	$(RM) *.map
	$(RM) 'modules\*.bpl'
	$(RM) 'modules\*.map'
endif
ifdef LINUX
	$(RM) -f bpl*.so
	$(RM) -f grendel
	$(RM) -f gmcc
	$(RM) -f gasm
	$(RM) -f *.map
	$(RM) -f modules/bpl*.so
	$(RM) -f modules/*.map
endif

test:
	$(MAKE) -C src/tests test
