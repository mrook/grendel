#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2003 by Michiel Rook
#
# GMC Makefile - Use GNU make!
#
# $Id: Makefile,v 1.1 2003/12/12 13:19:48 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

GMCC=gmcc.exe
GASM=gasm.exe

CORE_SYM=..\\core
CORE_FILE=..\\core.bpl

ifeq ($(OS), Windows_NT)
	RM=cmd /c del
else
	RM=del
endif
endif

ifdef LINUX
DCC=dcc
DCC_DEFS=CONSOLEBUILD

GMCC=gmcc
GASM=gasm

CORE_SYM=../core
CORE_FILE=../bplcore.so

RM=rm
endif


DCC_FLAGS=-CC -Q -D- -W- -O+

GMCC_SOURCES=gmcc.dpr 
GMCC_LEXFILES=gmcc.y gmclex.l
GASM_SOURCES=gasm.dpr 


all:	$(GMCC) $(GASM)
      
clean:
	$(RM) $(GMCC)
	$(RM) $(GASM)
	
$(GMCC_SOURCES): $(GMCC_LEXFILES)
	yacc gmcc gmcc.dpr
	lex gmclex

$(GMCC):	$(GMCC_SOURCES) $(CORE_FILE)
	$(DCC) $(GMCC_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -LU$(CORE_SYM)
	
$(GASM):	$(GASM_SOURCES) $(CORE_FILE)
	$(DCC) $(GASM_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -LU$(CORE_SYM)

