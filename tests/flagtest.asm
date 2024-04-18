I common.mc
# Tests the basic flags for the edge cases.
#
:DataTable
=Add 1
=Sub 2
#0-1    2-3     4-5     6-7      8-13
# A     B       Func    Result    ZNCO
32767   1       Add     -32768   "0101\0"
32767   -1      Add     32766    "0000\0"
32767   32767   Add     -2       "0101\0"
32767   -32767  Add     0        "1000\0"
32767   0       Add     32767    "0000\0"
0       0       Add     0        "1000\0"
0       1       Add     1        "0000\0"
0       -1      Add     -1       "0100\0"
0       32767   Add     32767    "0000\0"
0       -32767  Add     -32767   "0100\0"
-32767  1       Add     -32766   "0100\0"
-32767  -1      Add     -32768   "0100\0"
-32767  32767   Add     0        "1000\0"
-32767  -32767  Add     2        "0001\0"
1       1       Sub     0        "1000\0"
1       -1      Sub     2        "0000\0"
1       32767   Sub     -32766   "0101\0"
1       -32767  Sub     32768    "0010\0"
-1      1       Sub     -2       "0101\0"
-1      -1      Sub     0        "1000\0"

:Aval 0
:Bval 0
:Rval 0
:MyVal 0
:FuncVal 0
:DBIndex 0
:ColIndex 0
:ICounter 0
:StrPtr 0

:Main . Main
@PUSH -32767 @PUSH -1 @ADDS

@MA2V DataTable DBIndex
@PRTLN "                           ZNCO flags"
@ForIA2B ICounter 0 20
   @PUSHI DBIndex
   @PUSHS
   @POPI Aval
   @PUSHI DBIndex @ADD 2
   @PUSHS
   @POPI Bval
   @PUSHI DBIndex @ADD 4
   @PUSHS
   @POPI FuncVal
   @PUSHI DBIndex @ADD 6
   @PUSHS
   @POPI Rval
   @PUSHI DBIndex @ADD 8
   @POPI StrPtr
   @PUSHI DBIndex @ADD 13  @POPI DBIndex  # Length of one row of data
   @IF_EQ_AV Add FuncVal
      @FCLR
      @PRTSGNI Aval @PRT " + " @PRTSGNI Bval @PRT " = " 
      @PUSHI Aval @PUSHI Bval
      @ADDS
      @POPI MyVal
      @FSAV
   @ELSE
      @FCLR
      @PRTSGNI Aval @PRT " - " @PRTSGNI Bval @PRT " = " 
      @PUSHI Aval @PUSHI Bval
      @SUBS
      @POPI MyVal
      @FSAV
   @ENDIF
   @PRTSGNI MyVal @PRT "(" @PRTSGNI Rval @PRT ") "
   @DUP
   @FLOD
   @IF_ZFLAG
      @PRT "1"
   @ELSE
      @PRT "0"
   @ENDIF
   @DUP
   @FLOD      
   @IF_NEG
      @PRT "1"
   @ELSE
      @PRT "0"
   @ENDIF
   @DUP
   @FLOD      
   @IF_CARRY
      @PRT "1"
   @ELSE
      @PRT "0"
   @ENDIF
   @FLOD      
   @IF_OVERFLOW
      @PRT "1"
   @ELSE
      @PRT "0"
   @ENDIF
   @PRT " [" @PRTSI StrPtr @PRT "]\n" 
@Next ICounter
@END
