.AUTODEPEND

DCC=dcc32
DCC_FLAGS=-CC -Q -D- -W- -O+

GMCC=gmcc.exe
GMCC_SOURCES=gmcc.dpr 
GMCC_LEXFILES=gmcc.y gmclex.l

GASM=gasm.exe
GASM_SOURCES=gasm.dpr 

all:	$(GMCC) $(GASM)
      
clean:
	del $(GMCC) $(GASM)
	
$(GMCC_SOURCES): $(GMCC_LEXFILES)
  yacc gmcc gmcc.dpr
  lex gmclex

$(GMCC):	$(GMCC_SOURCES) $(CORE)
	$(DCC) $(GMCC_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -U..\units -U..\contrib
	
$(GASM):	$(GASM_SOURCES) $(CORE)
	$(DCC) $(GASM_SOURCES) -D$(DCC_DEFS) $(DCC_FLAGS) -U..\units -U..\contrib

