#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Sources Makefile - Use GNU make!
#
# $Id: Makefile,v 1.14 2004/06/25 13:19:55 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CONSOLEBUILD=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

GRENDEL=..\build\grendel.exe
COPYOVER=..\build\copyover.exe
CONVERT=..\build\convert.exe
CORE=..\build\core.bpl
HELPER=..\build\helper.exe
SERVICE=..\build\grendelservice.exe

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

GRENDEL=../build/grendel
CONVERT=../build/convert
CORE=../build/bplcore.so

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
	$(DCC) convert.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -LUcore

$(CORE): core.dpk units/*.pas gmc/*.pas contrib/*.pas
	$(DCC) core.dpk $(DCC_FLAGS) -D$(DCC_DEFS)

$(COPYOVER):	copyover.dpr $(CORE)
	$(DCC) copyover.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -LUcore

$(GRENDEL):	grendel.dpr $(CORE)
	$(DCC) grendel.dpr -D$(DCC_DEFS) $(DCC_FLAGS)
	
$(HELPER):	helper.dpr $(CORE)
	$(DCC) helper.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -LUcore
	
$(SERVICE):	grendelservice.dpr servicemain.pas $(CORE)
	$(DCC) grendelservice.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -LUcore -LUvcl

