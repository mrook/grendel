#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# GMC Makefile - Use GNU make!
#
# $Id$
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CONSOLEBUILD=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

GMCC=..\..\build\bin\gmcc.exe
GASM=..\..\build\bin\gasm.exe

CORE_FILE=..\..\build\bin\core.bpl

ifeq ($(OS), Windows_NT)
	RM=cmd /c del
else
	RM=del
endif
endif

ifdef LINUX
DCC=dcc

GMCC=../../build/bin/gmcc
GASM=../../build/bin/gasm

CORE_FILE=../../build/bin/bplcore.so

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


GMCC_SOURCES=gmcc.dpr 
GMCC_LEXFILES=gmcc.y gmclex.l
GASM_SOURCES=gasm.dpr 


all:	$(GMCC) $(GASM)
      
clean:

$(GMCC_SOURCES): $(GMCC_LEXFILES)
	dyacc gmcc gmcc.dpr
	dlex -o gmclex

$(GMCC):	$(GMCC_SOURCES) $(CORE_FILE)
	$(DCC) $(GMCC_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS)
	
$(GASM):	$(GASM_SOURCES) $(CORE_FILE)
	$(DCC) $(GASM_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS)

