$DATA 0
$SYMBOL onEmoteTarget L13
$SYMBOL onAct L16
L13:
PUSHBP
MSPBP
PUSHDISP -4
PUSHS BOW
EQ
PUSHDISP -2
PUSHS name
GET
PUSHS Syra
EQ
AND
JZ L15
L14:
PUSHS say Good day, 
PUSHDISP -3
PUSHS name
GET
ADD
PUSHS !
ADD
TRAP
L15:
MBPSP
POPBP
MTSD 3
SUBSP 3
RET
L16:
PUSHBP
MSPBP
MBPSP
POPBP
MTSD 3
SUBSP 3
RET