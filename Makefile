#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2003 by Michiel Rook
#
# Main Makefile - Use GNU make!
#
# $Id: Makefile,v 1.11 2003/12/12 13:31:50 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
else
	WIN32=1
endif


all:	
	$(MAKE) -C src
ifdef WIN32
	copy src\grendel.exe
	copy src\grendel.map
	copy src\core.bpl
	copy src\core.map
	copy src\gmc\gmcc.exe
	copy src\gmc\gasm.exe
	copy src\modules\*.bpl modules
	copy src\modules\*.map modules
endif
ifdef LINUX
	cp src/grendel
	cp src/grendel.map
	cp src/bplcore.so
	cp src/core.map
	cp src/gmc/gmcc
	cp src/gmc/gasm
	cp src/modules/bpl*.so modules
	cp src/modules/*.map modules
endif
	

clean:
	$(MAKE) -C src clean
ifdef WIN32	
	del *.bpl
	del *.exe
	del *.map
	del modules\*.bpl
	del modules\*.map
endif
ifdef LINUX
	rm bpl*.so
	rm grendel
	rm *.map
	rm modules/bpl*.so
	rm modules/*.map
endif