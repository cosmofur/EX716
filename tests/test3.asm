I common.mc
L mul.ld
:Main . Main
@PRT "-*- | 0000,0001,0002,0003,0004,0005,0006,0007,0008,0009,000A,000B,000C,000D,000E,000F\n"
:CodeTop
@ForIA2B Index1 0 16
  @PRTI Index1 @PRTSP  @StackDump
  @PRTHEXI Index1 @PRTS Bar1
  @ForIA2B Index2 0 16
     @IF_EQ_AV 0 Index2
        @PRTS Space1
     @ELSE
        @PRTS Comma1
     @ENDIF
     @PUSHI Index1 @PUSHI Index2 @CALL MUL
     @PRTHEXTOP
     @POPNULL
  @Next Index2
  :Break01
  @PRTNL
@Next Index1
@END
:CodeBottom
:Index1 0
:Index2 0

  

:Bar1 "|\0"
:Space1 " \0"
:Comma1 ",\0"
