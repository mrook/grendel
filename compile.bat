@echo off
dcc32 -Iinclude -Uunits -Ebin -Q grendel.dpr
dcc32 -Uunits -Q copyover.dpr
dcc32 -Uunits -Q convert.dpr
