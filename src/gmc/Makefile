#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# GMC Makefile - Use GNU make!
#
# $Id: Makefile,v 1.5 2004/06/25 13:19:55 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CONSOLEBUILD=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

GMCC=..\..\build\gmcc.exe
GASM=..\..\build\gasm.exe

CORE_FILE=..\..\build\core.bpl

ifeq ($(OS), Windows_NT)
	RM=cmd /c del
else
	RM=del
endif
endif

ifdef LINUX
DCC=dcc

GMCC=../../build/gmcc
GASM=../../build/gasm

CORE_FILE=../../build/bplcore.so

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
	yacc gmcc gmcc.dpr
	lex gmclex

$(GMCC):	$(GMCC_SOURCES) $(CORE_FILE)
	$(DCC) $(GMCC_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS)
	
$(GASM):	$(GASM_SOURCES) $(CORE_FILE)
	$(DCC) $(GASM_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS)

