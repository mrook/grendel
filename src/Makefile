#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Sources Makefile - Use GNU make!
#
# $Id: Makefile,v 1.12 2004/05/06 20:43:34 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CONSOLEBUILD=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

GRENDEL=grendel.exe
COPYOVER=copyover.exe
CONVERT=convert.exe
CORE=core.bpl
HELPER=helper.exe
SERVICE=grendelservice.exe

ALL=$(GRENDEL) $(CONVERT) $(COPYOVER) $(CORE) $(HELPER) $(SERVICE)

MAKE=$(CURDIR)/../make

ifeq ($(OS), Windows_NT)
	RM=cmd /c del
else
	RM=del
endif
endif


ifdef LINUX
DCC=dcc

GRENDEL=grendel
CONVERT=convert
CORE=bplcore.so

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
	$(RM) $(GRENDEL) 
	$(RM) $(SERVICE)
	$(RM) $(HELPER)
	$(RM) $(COPYOVER) 
	$(RM) $(CONVERT)
	$(RM) $(CORE)
	$(RM) *.map
	$(RM) *.jdbg
	$(RM) *.dcu
	$(RM) *.dpu
	$(RM) *.drc
	$(RM) *.dcp
	$(MAKE) -C gmc clean
	$(MAKE) -C modules clean

$(CONVERT):	convert.dpr $(CORE)
	$(DCC) convert.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore

$(CORE): core.dpk units/*.pas gmc/*.pas contrib/*.pas
	$(DCC) core.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -Uunits -Ucontrib -Ugmc -GD -Ucontrib/jcl

$(COPYOVER):	copyover.dpr $(CORE)
	$(DCC) copyover.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore

$(GRENDEL):	grendel.dpr $(CORE)
	$(DCC) grendel.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore
	
$(HELPER):	helper.dpr $(CORE)
	$(DCC) helper.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore
	
$(SERVICE):	grendelservice.dpr servicemain.pas $(CORE)
	$(DCC) grendelservice.dpr -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore -LUvcl

