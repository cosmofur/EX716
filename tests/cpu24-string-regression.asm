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
::MultiDelim ",;\0"
::EmptyDelim "\0"
::Single "one\0"
::Trailing "one,two,\0"
::Empty "\0"
::Multi "one;two\0"
::Whole "one,two\0"

M PrintToken \
 @IF_ZERO @POPNULL @PRT "<end>" @ELSE @POPI Token @PRTSI Token @ENDIF

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
@PRT "after=" @PUSH 0 @PUSH Delim @CALL strtok @PrintToken @PRT "/"
@PUSH 0 @PUSH Delim @CALL strtok @PrintToken @PRTNL
@PRT "single=" @PUSH Single @PUSH Delim @CALL strtok @PrintToken @PRT "/"
@PUSH 0 @PUSH Delim @CALL strtok @PrintToken @PRTNL
@PRT "trailing=" @PUSH Trailing @PUSH Delim @CALL strtok @PrintToken @PRT "/"
@PUSH 0 @PUSH Delim @CALL strtok @PrintToken @PRT "/"
@PUSH 0 @PUSH Delim @CALL strtok @PrintToken @PRTNL
@PRT "empty=" @PUSH Empty @PUSH Delim @CALL strtok @PrintToken @PRTNL
@PRT "multi=" @PUSH Multi @PUSH MultiDelim @CALL strtok @PrintToken @PRT "/"
@PUSH 0 @PUSH MultiDelim @CALL strtok @PrintToken @PRT "/"
@PUSH 0 @PUSH MultiDelim @CALL strtok @PrintToken @PRTNL
@PRT "no delimiters=" @PUSH Whole @PUSH EmptyDelim @CALL strtok @PrintToken @PRT "/"
@PUSH 0 @PUSH EmptyDelim @CALL strtok @PrintToken @PRTNL
@PUSH 0 @ADM @END
