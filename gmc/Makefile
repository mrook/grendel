#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2003 by Michiel Rook
#
# GMC Makefile - Use GNU make!
#
# $Id: Makefile,v 1.3 2003/10/30 17:19:00 ***REMOVED*** Exp $
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
endif

ifdef LINUX
DCC=dcc

GMCC=gmcc
GASM=gasm

CORE_SYM=../core
CORE_FILE=../bplcore.so
endif


DCC_FLAGS=-CC -Q -D- -W- -O+

GMCC_SOURCES=gmcc.dpr 
GMCC_LEXFILES=gmcc.y gmclex.l
GASM_SOURCES=gasm.dpr 


all:	$(GMCC) $(GASM)
      
clean:
	rm $(GMCC) $(GASM)
	
$(GMCC_SOURCES): $(GMCC_LEXFILES)
	yacc gmcc gmcc.dpr
	lex gmclex

$(GMCC):	$(GMCC_SOURCES) $(CORE_FILE)
	$(DCC) $(GMCC_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -LU$(CORE_SYM)
	
$(GASM):	$(GASM_SOURCES) $(CORE_FILE)
	$(DCC) $(GASM_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -LU$(CORE_SYM)

