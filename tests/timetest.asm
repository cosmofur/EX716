.DATA 1
.ORG 0x0100
I commonDS.mc
L softstackDS.ld
L timetool.ld
:Index 0

:Main .Entry Main

@DSSInitQuick
@PRTLN "Time Test"
@ForIA2B Index 0 5
  @GETTIME
  @PRTHEXTOP
  @POPNULL
  @PRTHEXTOP
  @POPNULL
  @PRTNL
  @Call(A) Sleep 1
@Next Index
@END


