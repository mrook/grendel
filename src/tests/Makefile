#
# The Grendel Project - A Windows/Linux MUD Server
# Copyright (c) 2000-2004 by Michiel Rook
#
# Tests Makefile - Use GNU make!
#
# $Id: Makefile,v 1.2 2004/02/21 17:47:28 ***REMOVED*** Exp $
#


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

TESTS=tests.exe

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

TESTS=./tests
RM=rm -f
endif


DCC_FLAGS=-Q -D+ -V- -W+ -O+

TESTS_SOURCES=tests.dpr test_socket.pas


all:	$(TESTS)

clean:
	$(RM) $(TESTS) 
	$(RM) *.map
	$(RM) *.dcu
	$(RM) *.dpu
	$(RM) *.drc
	$(RM) *.dcp

test:	$(TESTS)
	$(TESTS)
	      
$(TESTS): $(TESTS_SOURCES)
	$(DCC) tests.dpr $(DCC_FLAGS) -D$(DCC_DEFS) -Udunit -U../units -U../contrib -U../gmc -GD -U../contrib/jcl
