I common.mc
L mul.ld
:Main . Main
@PRTLN "-*- | 0000,0001,0002,0003,0004,0005,0006,0007,0008,0009,000A,000B,000C,000D,000E,000F"
@ForIA2B Index1 0 16
  @PRTHEXI Index1 @PRT "|"
  @ForIA2B Index2 0 16
     @IF_EQ_AV 0 Index2
        @PRT " "
     @ELSE
        @PRT ","
     @ENDIF
     @PUSHI Index1 @PUSHI Index2 @CALL MUL
     @PRTHEXTOP
     @POPNULL
  @Next Index2
  @PRTNL
@Next Index1
@END
:Index1 0
:Index2 0

  

