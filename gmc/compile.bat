@echo off
yacc gmcc gmcc.dpr
lex gmclex
dcc32 -cc -I..\ -U..\units gmcc.dpr
dcc32 -cc -I..\ -U..\units gasm.dpr
