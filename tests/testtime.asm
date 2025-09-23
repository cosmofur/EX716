I common.mc
L timetool.ld
:LVar01 0
:LVar01a 0

:Main . Main
=Year Var01
=Month Var02
=Day Var03
=Hour Var04
=Minute Var05
=Second Var06
=Calibrate Var07
@ForIA2B Var01 1 10
   @PRT "Sleep: " @PRTI Var01 @PRTNL
   @GETTIME @POPI LVar01+2
   @POPI LVar01
   @PRT "Time Stamp: " @PRT32 LVar01 @PRTNL
   @PUSHI Var01
   @CALL Sleep
@Next Var01
@GETTIME @POPI LVar01+2
@POPI LVar01
@PRT "End Stamp: " @PRT32 LVar01 @PRTNL

@PRTNL
@GETTIME
@POPI LVar01a @POPI LVar01
@PUSH LVar01
@CALL Time2Units
@POPI Second
@POPI Minute
@POPI Hour
@POPI Day
@POPI Month
@POPI Year
@PRT "Date: " @PRTI Month @PRT "/" @PRTI Day @PRT "/" @PRTI Year @PRT " - " @PRTI Hour @PRT ":" @PRTI Minute @PRT "." @PRTI Second
@PRTNL
@END
