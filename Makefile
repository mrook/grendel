#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Main Makefile - Use GNU make!
#
# $Id: Makefile,v 1.24 2004/06/25 13:19:55 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CP=cp
	RM=rm
	MD=md
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
	$(MD) build
	$(MD) 'build\modules'
	$(MD) 'build\units'
endif
ifdef LINUX
	$(MD) build
	$(MD) build/modules
	$(MD) build/units
endif
	$(MAKE) -C src
ifdef WIN32
	makejcldbg -J 'build\*.map'
	makejcldbg -J 'build\modules\*.map'
	$(CP) 'build\*'
	$(CP) 'build\modules\*' modules
	$(RMDIR) /Q /S build
endif
ifdef LINUX
	$(CP) build/*
	$(CP) build/* modules
	$(RM) -rf build
endif
	

clean:
	$(MAKE) -C src clean

test:
	$(MAKE) -C src/tests test
