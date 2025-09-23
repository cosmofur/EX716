I common.mc
L string.ld

:Main . Main

@STRSET "/Word/Word2/Word3/Foo/\0" StrA
@PUSH StrA
@CALL strlen
@PRT "Length: " @PRTTOP
@PUSH StrA
@PUSH StrB
@CALL strtok
@POPI CurrentWord
@PUSHI CurrentWord
@WHILE_NOTZERO
   @POPNULL
   @PRT "(" @PRTSI CurrentWord @PRT ")" @StackDump
   @PUSH 0 @PUSH StrB
   :Break1
   @CALL strtok
   @IF_NOTZERO
      @POPI CurrentWord
      @PUSHI CurrentWord
   @ENDIF
@ENDWHILE


@END





:CurrentWord 0
:StrB "/-\0"
:StrA "                                                                        "



