#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Sources Makefile - Use GNU make!
#
# $Id: Makefile,v 1.7 2004/03/22 14:55:49 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

GRENDEL=grendel.exe
COPYOVER=copyover.exe
CORE=core.bpl
SERVICE=grendelservice.exe

ALL=$(GRENDEL) $(SERVICE) $(COPYOVER) $(CORE)

MAKE=$(CURDIR)/../make

ifeq ($(OS), Windows_NT)
	RM=cmd /c del
else
	RM=del
endif
endif


ifdef LINUX
DCC=dcc
DCC_DEFS=CONSOLEBUILD

GRENDEL=grendel
COPYOVER=copyover
CORE=bplcore.so

ALL=$(GRENDEL) $(COPYOVER) $(CORE)

RM=rm -f
endif


DCC_FLAGS=-Q '-$$W+' -GD


all:	$(ALL)
	$(MAKE) -C gmc
	$(MAKE) -C modules
      
clean:
	$(RM) $(GRENDEL) 
	$(RM) $(SERVICE)
	$(RM) $(COPYOVER) 
	$(RM) $(CORE)
	$(RM) *.map
	$(RM) *.dcu
	$(RM) *.dpu
	$(RM) *.drc
	$(RM) *.dcp
	$(MAKE) -C gmc clean
	$(MAKE) -C modules clean

$(GRENDEL):	grendel.dpr $(CORE)
	$(DCC) grendel.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore
	
$(COPYOVER):	copyover.dpr $(CORE)
	$(DCC) copyover.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore

$(SERVICE):	grendelservice.dpr servicemain.pas $(CORE)
	$(DCC) grendelservice.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore

$(CORE): core.dpk units/*.pas gmc/*.pas contrib/*.pas
	$(DCC) core.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -Uunits -Ucontrib -Ugmc -GD -Ucontrib/jcl
