#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Modules Makefile - Use GNU make!
#
# $Id: Makefile,v 1.12 2004/06/25 13:19:55 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
	CONSOLEBUILD=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

COMMANDS=..\..\build\modules\core_commands.bpl
SPELLER=..\..\build\modules\speller.bpl
STATUS=..\..\build\modules\status.bpl
IMC3=..\..\build\modules\imc3.bpl
WEBSERVICE=..\..\build\modules\webservice.bpl

MODULES=$(COMMANDS) $(SPELLER) $(STATUS) $(IMC3)

CORE_FILE=..\..\build\core.bpl

ifeq ($(OS), Windows_NT)
	RM=cmd /c del
else
	RM=del
endif
endif


ifdef LINUX
DCC=dcc

COMMANDS=bplcore_commands.so
SPELLER=bplspeller.so
STATUS=bplstatus.so
IMC3=bplimc3.so
WEBSERVICE=bplwebservice.so

MODULES=$(COMMANDS) $(SPELLER) $(IMC3)

CORE_SYM=../core
CORE_FILE=../bplcore.so

RM=rm -f
endif


ifdef CONSOLEBUILD
DCC_DEFS=CONSOLEBUILD
endif


ifdef DEBUG
DCC_FLAGS=-Q -GD -V
else
DCC_FLAGS=-Q -GD
endif


all:	$(MODULES)

clean:

$(COMMANDS):	commands/* $(CORE_FILE)
	cd commands && $(DCC) core_commands.dpk $(DCC_FLAGS) -D$(DCC_DEFS)

$(SPELLER):	speller/* $(CORE_FILE)
	cd speller && $(DCC) speller.dpk $(DCC_FLAGS) -D$(DCC_DEFS)

$(STATUS):	status/* $(CORE_FILE)
	cd status && $(DCC) status.dpk $(DCC_FLAGS) -D$(DCC_DEFS)

$(WEBSERVICE):	webservice/* $(CORE_FILE)
	cd webservice && $(DCC) webservice.dpk $(DCC_FLAGS) -D$(DCC_DEFS)

$(IMC3):	imc3/* $(CORE_FILE)
	cd imc3 && $(DCC) imc3.dpk $(DCC_FLAGS) -D$(DCC_DEFS)

