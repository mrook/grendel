DCC=dcc32
DCC_FLAGS=-Q -D+ -V- -W- -O+ -GD

MODULES=core_commands.bpl speller.bpl status.bpl

all:	$(MODULES)

clean:
	del $(MODULES)

core_commands.bpl:	core_commands.dpk commands/*
	$(DCC) core_commands.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU..\core

speller.bpl:	speller.dpk speller/*
	$(DCC) speller.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU..\core

status.bpl:	status.dpk status/*
	$(DCC) status.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -LU..\core
