# CPU24 regression for the shared string routines that scan individual bytes.
.DATA 1
I commonDS.mc
L softstack.ld
L heapmgr.ld
L string.ld
::HeapID 0
::Token 0
::Input "red,green,blue\0"
::Delim ",\0"

:Main . Main
@PUSH 1 @SSET SegDS @PUSH 1 @ADM
@PUSH 0xf000 @PUSH 0xe000 @CALL SetSSStack
@PUSH 0x1000 @PUSH 0xd000 @CALL HeapDefineMemory @POPI HeapID
@PUSH Input @CALL strlen
@PRT "length=" @PRTTOP @POPNULL @PRTNL
@PUSH Input @PUSH Delim @CALL strtok @POPI Token
@PRT "items=" @PRTSI Token
@PUSH 0 @PUSH Delim @CALL strtok @POPI Token
@PRT "/" @PRTSI Token
@PUSH 0 @PUSH Delim @CALL strtok @POPI Token
@PRT "/" @PRTSI Token @PRTNL
@PUSH 0 @ADM @END
