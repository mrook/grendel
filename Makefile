#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Main Makefile - Use GNU make!
#
# $Id: Makefile,v 1.25 2004/06/25 14:53:09 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CP=cp
	RM=rm
	MD=mkdir
else
	WIN32=1
ifeq ($(OS), Windows_NT)
	RM=cmd /c del
	RMDIR=cmd /c rmdir
	CP=cmd /c copy
	MD=cmd /c mkdir
else
	RM=del
	RMDIR=rmdir
	CP=copy
	MD=mkdir
endif
endif


all:	
ifdef WIN32
	$(MD) 'build\bin'
	$(MD) 'build\modules'
	$(MD) 'build\units'
endif
ifdef LINUX
	$(MD) -p build/bin
	$(MD) -p build/modules
	$(MD) -p build/units
endif
	$(MAKE) -C src
ifdef WIN32
	makejcldbg -J 'build\bin\*.map'
	makejcldbg -J 'build\modules\*.map'
	$(CP) 'build\bin\*'
	$(CP) 'build\modules\*' modules
endif
ifdef LINUX
	$(CP) -r build/bin/* .
	$(CP) -r build/modules/* modules
endif
	

clean:
	$(MAKE) -C src clean

test:
	$(MAKE) -C src/tests test
