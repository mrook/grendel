@echo off
yacc gmcc gmcc.dpr
lex gmclex
dcc32 -cc -U..\units gmcc.dpr
dcc32 -cc -U..\units gasm.dpr
