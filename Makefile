DCC=/home/***REMOVED***/dcc


all:	grendel

clean:
	rm -f grendel

grendel:	grendel.dpr
	$(DCC) -Q -Iinclude -Uunits grendel.dpr -D+ -V+ -W+
