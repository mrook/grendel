#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Main Makefile - Use GNU make!
#
# $Id: Makefile,v 1.26 2004/06/25 15:10:21 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
else
	WIN32=1
ifeq ($(OS), Windows_NT)
	RMDIR=cmd /c rmdir
	CP=cmd /c copy
	IF=cmd /c if
else
	RMDIR=rmdir
	CP=copy
	IF=if
endif
endif


all:	
ifdef WIN32
	$(IF) not exist 'build\bin' mkdir 'build\bin'
	$(IF) not exist 'build\modules' mkdir 'build\modules'
	$(IF) not exist 'build\units' mkdir 'build\units'
endif
ifdef LINUX
	mkdir -p build/bin
	mkdir -p build/modules
	mkdir -p build/units
endif
	$(MAKE) -C src
ifdef WIN32
	makejcldbg -J 'build\bin\*.map'
	makejcldbg -J 'build\modules\*.map'
	$(CP) 'build\bin\*'
	$(CP) 'build\modules\*' modules
endif
ifdef LINUX
	cp -r build/bin/* .
	cp -r build/modules/* modules
endif
	

clean:
	$(MAKE) -C src clean
ifdef WIN32
	$(IF) exist build rmdir /Q /S build
endif
ifdef LINUX
	rm -rf build
endif

test:
	$(MAKE) -C src/tests test
