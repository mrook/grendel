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

COMMANDS=core_commands.bpl
SPELLER=speller.bpl
STATUS=status.bpl
IMC3=imc3.bpl
WEBSERVICE=webservice.bpl

CORE=..\\core.bpl
endif


ifdef LINUX
DCC=dcc

COMMANDS=bplcore_commands.so
SPELLER=bplspeller.so
STATUS=bplstatus.so
IMC3=bplimc3.so
WEBSERVICE=bplwebservice.so

CORE=../bplcore.so
endif


DCC_FLAGS=-Q -D+ -V- -W- -O+ -GD

MODULES=$(COMMANDS) $(SPELLER) $(STATUS)


all:	$(MODULES)

clean:
	rm $(MODULES)

$(COMMANDS):	core_commands.dpk commands/* $(CORE)
	$(DCC) core_commands.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE) -Ucommands

$(SPELLER):	speller.dpk speller/* $(CORE)
	$(DCC) speller.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE) -Uspeller

$(STATUS):	status.dpk status/* ..\core.bpl
	$(DCC) status.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE) -Ustatus

$(WEBSREVICE):	webservice.dpk webservice/* $(CORE)
	$(DCC) webservice.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE) -Uwebservice

$(IMC3):	imc3.dpk imc3/* $(CORE)
	$(DCC) imc3.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU$(CORE) -Uimc3

