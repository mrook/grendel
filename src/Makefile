#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2003 by Michiel Rook
#
# Sources Makefile - Use GNU make!
#
# $Id: Makefile,v 1.2 2003/12/12 13:48:39 ***REMOVED*** Exp $
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
RM=rm -f
endif


DCC_FLAGS=-Q -D+ -V- -W+ -O+

GRENDEL_SOURCES=grendel.dpr
COPYOVER_SOURCES=copyover.dpr
CORE_SOURCES=core.dpk units/*.pas gmc/*.pas contrib/*.pas


all:	$(GRENDEL) $(COPYOVER)
	$(MAKE) -C gmc
	$(MAKE) -C modules
      
clean:
	$(RM) $(GRENDEL) 
	$(RM) $(COPYOVER) 
	$(RM) $(CORE)
	$(RM) *.map
	$(RM) *.dpu
	$(RM) *.dcp
	$(MAKE) -C gmc clean
	$(MAKE) -C modules clean

$(GRENDEL):	$(GRENDEL_SOURCES) $(CORE)
	$(DCC) $(GRENDEL_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore -Ucontrib\jcl
	
$(COPYOVER):	$(COPYOVER_SOURCES)
	$(DCC) $(COPYOVER_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -Uunits

$(CORE): $(CORE_SOURCES)
	$(DCC) core.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -Uunits -Ucontrib -Ugmc -GD
