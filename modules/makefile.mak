DCC=dcc32
DCC_FLAGS=-Q -D+ -V- -W- -O+ -GD

MODULES=core_commands.bpl speller.bpl status.bpl

all:	$(MODULES)

clean:
	del $(MODULES)

core_commands.bpl:	core_commands.dpk commands/*
	$(DCC) core_commands.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU..\core -Ucommands

speller.bpl:	speller.dpk speller/*
	$(DCC) speller.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU..\core -Uspeller

status.bpl:	status.dpk status/*
	$(DCC) status.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU..\core -Ustatus

webservice.bpl:	webservice.dpk webservice/*
	$(DCC) webservice.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU..\core -Uwebservice

