DCC=/usr/local/kylix/bin/dcc
SOURCES=grendel.dpr units/*.pas include/*.inc


all:	grendel

clean:
	rm -f grendel

grendel:	$(SOURCES)
	$(DCC) -Q -Iinclude -Uunits grendel.dpr -D+ -V- -W+ -O+ -GD

grendel-debug:	$(SOURCES)
	$(DCC) -Q -Iinclude -Uunits grendel.dpr -D+ -V+ -W+ -O- -GD
