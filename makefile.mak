.AUTODEPEND

DCC=dcc32
DCC_FLAGS=-Q -D+ -V- -W+ -O+

GRENDEL=grendel.exe
GRENDEL_SOURCES=grendel.dpr

COPYOVER=copyover.exe
COPYOVER_SOURCES=copyover.dpr

CONVERT=convert.exe
CONVERT_SOURCES=convert.dpr

CORE=core.bpl
CORE_SOURCES=core.dpk units/*.pas gmc/*.pas contrib/*.pas

all:	$(GRENDEL) $(COPYOVER)
	cd gmc 
  	make -DDCC_DEFS=$(DCC_DEFS)
	cd ..
	cd modules
	make -DDCC_DEFS=$(DCC_DEFS)
	
      
clean:
	del $(GRENDEL) $(COPYOVER) $(CONVERT) $(CORE)
	cd gmc
	make clean
  	cd ..
	cd modules
	make clean

$(GRENDEL):	$(GRENDEL_SOURCES) $(CORE) jcl\*.pas
	$(DCC) $(GRENDEL_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -GD -LUcore -Ujcl
	
$(COPYOVER):	$(COPYOVER_SOURCES)
	$(DCC) $(COPYOVER_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -Uunits

#$(CONVERT):	$(CONVERT_SOURCES) $(CORE)
#	$(DCC) $(CONVERT_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -LUcore

$(CORE): $(CORE_SOURCES)
	$(DCC) core.dpk $(DCC_FLAGS) -D$(DCC_DEFS) -Uunits -Ucontrib -GD

