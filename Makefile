#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2003 by Michiel Rook
#
# Main Makefile - Use GNU make!
#
# $Id: Makefile,v 1.9 2003/11/03 20:56:35 ***REMOVED*** Exp $
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
CONVERT=convert.exe
CORE=core.bpl

MAKE=$(CURDIR)/make

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
CONVERT=convert
CORE=bplcore.so
RM=rm
endif


DCC_FLAGS=-Q -D+ -V- -W+ -O+

GRENDEL_SOURCES=grendel.dpr
COPYOVER_SOURCES=copyover.dpr
CONVERT_SOURCES=convert.dpr
CORE_SOURCES=core.dpk units/*.pas gmc/*.pas contrib/*.pas


all:	$(GRENDEL) $(COPYOVER)
	$(MAKE) -C gmc
	$(MAKE) -C modules
      
clean:
	$(RM) $(GRENDEL) 
	$(RM) $(COPYOVER) 
	$(RM) $(CORE)
	$(MAKE) -C gmc clean
	$(MAKE) -C modules clean

$(GRENDEL):	$(GRENDEL_SOURCES) $(CORE)
	$(DCC) $(GRENDEL_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore -Ujcl
	
$(COPYOVER):	$(COPYOVER_SOURCES)
	$(DCC) $(COPYOVER_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -Uunits

#$(CONVERT):	$(CONVERT_SOURCES) $(CORE)
#	$(DCC) $(CONVERT_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -LUcore

$(CORE): $(CORE_SOURCES)
	$(DCC) core.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -Uunits -Ucontrib -Ugmc -GD
