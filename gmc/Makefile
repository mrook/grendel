# Grendel Makefile
#
# Use GNU make!


ifeq ($(OSTYPE),linux-gnu)
	LINUX=1
else
	WIN32=1
endif


ifdef WIN32
DCC=dcc32

GMCC=gmcc.exe
GASM=gasm.exe

CORE=..\\core.bpl
endif

ifdef LINUX
DCC=dcc

GMCC=gmcc
GASM=gasm

CORE=../bplcore.so
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

$(GMCC):	$(GMCC_SOURCES) $(CORE)
	$(DCC) $(GMCC_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -LU$(CORE)
	
$(GASM):	$(GASM_SOURCES) $(CORE)
	$(DCC) $(GASM_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -LU$(CORE)

