I common.mc
L softstack.ld
L timetool.ld
:Index01 0

:Main .Org Main

   @CALL TimeCalabrate
   @CALL TimeCalabrate
   @CALL TimeCalabrate

   @GETTIME
   @POPNULL
   @PRT "Start(50 seconds):" @PRTTOP @PRTNL
   @ForIA2B Index1 0 5
     @Call(A) SleepMilli 10000
     @PRT "."
   @Next Index1
   @GETTIME
   @POPNULL
   @PRTNL
   @PRT "Stop:" @PRTTOP @PRTNL
   @POPNULL

   @END
   
