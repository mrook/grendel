#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Sources Makefile - Use GNU make!
#
# $Id: Makefile,v 1.15 2004/06/25 14:53:09 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CONSOLEBUILD=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

GRENDEL=..\build\bin\grendel.exe
COPYOVER=..\build\bin\copyover.exe
CONVERT=..\build\bin\convert.exe
CORE=..\build\bin\core.bpl
HELPER=..\build\bin\helper.exe
SERVICE=..\build\bin\grendelservice.exe

ALL=$(GRENDEL) $(CONVERT) $(CORE) $(HELPER) $(SERVICE)

MAKE=$(CURDIR)/../make

ifeq ($(OS), Windows_NT)
	RM=cmd /c del
else
	RM=del
endif
endif


ifdef LINUX
DCC=dcc

GRENDEL=../build/bin/grendel
CONVERT=../build/bin/convert
CORE=../build/bin/bplcore.so

ALL=$(GRENDEL) $(CONVERT) $(CORE)

RM=rm -f
endif


ifdef CONSOLEBUILD
DCC_DEFS=CONSOLEBUILD
endif


ifdef DEBUG
DCC_FLAGS=-Q '-$$W+' -GD -V
else
DCC_FLAGS=-Q '-$$W+' -GD
endif


all:	$(ALL)
	$(MAKE) -C gmc
	$(MAKE) -C modules
      
clean:
	$(RM) *.dcu
	$(RM) *.dpu
	$(RM) *.drc
	$(MAKE) -C gmc clean
	$(MAKE) -C modules clean

$(CONVERT):	convert.dpr $(CORE)
	$(DCC) convert.dpr -D$(DCC_DEFS) $(DCC_FLAGS)

$(CORE): core.dpk units/*.pas gmc/*.pas contrib/*.pas
	$(DCC) core.dpk $(DCC_FLAGS) -D$(DCC_DEFS)

$(COPYOVER):	copyover.dpr $(CORE)
	$(DCC) copyover.dpr -D$(DCC_DEFS) $(DCC_FLAGS)

$(GRENDEL):	grendel.dpr $(CORE)
	$(DCC) grendel.dpr -D$(DCC_DEFS) $(DCC_FLAGS)
	
$(HELPER):	helper.dpr $(CORE)
	$(DCC) helper.dpr -D$(DCC_DEFS) $(DCC_FLAGS)
	
$(SERVICE):	grendelservice.dpr servicemain.pas $(CORE)
	$(DCC) grendelservice.dpr -D$(DCC_DEFS) $(DCC_FLAGS)

