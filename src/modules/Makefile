#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Modules Makefile - Use GNU make!
#
# $Id: Makefile,v 1.6 2004/03/11 23:30:46 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

COMMANDS=core_commands.bpl
SPELLER=speller.bpl
STATUS=status.bpl
IMC3=imc3.bpl
WEBSERVICE=webservice.bpl

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

COMMANDS=bplcore_commands.so
SPELLER=bplspeller.so
STATUS=bplstatus.so
IMC3=bplimc3.so
WEBSERVICE=bplwebservice.so

CORE_SYM=../core
CORE_FILE=../bplcore.so

RM=rm -f
endif


DCC_FLAGS=-Q -D+ -V- -W- -O+ -GD

MODULES=$(COMMANDS) $(SPELLER) $(STATUS) $(IMC3) $(WEBSERVICE)


all:	$(MODULES)

clean:
	$(RM) $(COMMANDS)
	$(RM) $(SPELLER)
	$(RM) $(STATUS)
	$(RM) $(IMC3)
	$(RM) $(WEBSERVICE)
	$(RM) *.map
	$(RM) *.dcp
	$(RM) *.dcu
	$(RM) *.dpu
	$(RM) *.drc

$(COMMANDS):	core_commands.dpk commands/* $(CORE_FILE)
	$(DCC) core_commands.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE_SYM) -Ucommands

$(SPELLER):	speller.dpk speller/* $(CORE_FILE)
	$(DCC) speller.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE_SYM) -Uspeller

$(STATUS):	status.dpk status/* $(CORE_FILE)
	$(DCC) status.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE_SYM) -Ustatus

$(WEBSERVICE):	webservice.dpk webservice/* $(CORE_FILE)
	$(DCC) webservice.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE_SYM) -Uwebservice

$(IMC3):	imc3.dpk imc3/* $(CORE_FILE)
	$(DCC) imc3.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE_SYM) -Uimc3

