# test string functions
I common.mc
L softstack.ld
L string2.ld

:Buffer1 b0 "                               " b0
:Buffer2 b0 "                               " b0
:Buffer3 b0 "                               " b0
:CatString "Cat" b0
:DogString "Dog" b0
:StrSpace " " b0

:Main . Main

@PRTLN "String Tests"
@PRT "StrLen Cat == "
@PUSH CatString
@CALL strlen
@PRTTOP @PRTNL
@POPNULL
#
@PRTLN "CatString 'CAT' 'SP' 'DOG'"
@PUSH Buffer3 @PUSH CatString
@CALL strcat
@PRT "Result -1 :" @PRTS Buffer3 @PRTNL
@PUSH Buffer3 @PUSH StrSpace
@CALL strcat
@PUSH Buffer3 @PUSH DogString
@CALL strcat
@PRT "Result -2 :" @PRTS Buffer3 @PRTNL
#
@PRTLN "Midstr, copy 'T D' from middle of buffer to new buffer"
@PUSH Buffer3 @PUSH Buffer1 @PUSH 3 @PUSH 5
@PRT "Result: " @PRTS Buffer1


@END
