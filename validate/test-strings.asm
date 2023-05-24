# test string functions
I common.mc
L softstack.ld
L string.ld

:Buffer1 b0 "                               " b0
:Buffer2 b0 "                               " b0
:Buffer3 b0 "                               " b0
:CatString "Cat" b0
:DogString "Dog" b0
:StrSpace " " b0
:StrHexID "0x" b0
:AA 0
:Index 0
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
@PUSH Buffer3 @PUSH StrSpace
@CALL strcat
@PUSH Buffer3 @PUSH DogString
@CALL strcat
@PRT "Result:" @PRTS Buffer3 @PRTNL
#
# Copy part of Buffer2 to Buffer1
#
@PRTLN "Copy range 2 to 5 from Buffer3 to Buffer1"
@PUSH Buffer1       # Dest
@PUSH Buffer3       # Head of SRC
@ADD 2              # Want Index 2
@PUSH 3             # to +3 or 5
@CALL strncpy
@PRT "Result: " @PRTS Buffer1
#
# Now to CMP tests
@PRTLN "Doing CMP tests"
@PUSH CatString
@PUSH DogString
@CALL strcmp
@PRT "'Cat' vs 'Dog':"
@PRTTOP @PRTNL
@POPNULL
@PUSH DogString
@PUSH CatString
@CALL strcmp
@PRT "'Dog' vs 'Cat':"
@PRTTOP @PRTNL
@POPNULL
@PUSH CatString
@PUSH CatString
@CALL strcmp
@PRT "'Cat' vs 'Cat':"
@PRTTOP @PRTNL
@POPNULL
@PUSH 0 @POPI Buffer1
@PUSH Buffer1
@PUSH CatString
@CALL strcmp
@PRT "'' vs 'Cat':"
@PRTTOP @PRTNL
@POPNULL
@PUSH CatString
@PUSH Buffer1
@CALL strcmp
@PRT "'Cat' vs '':"
@PRTTOP @PRTNL
@POPNULL
@PUSH Buffer1
@PUSH Buffer1
@CALL strcmp
@PRT "'' vs '':"
@PRTTOP @PRTNL
@POPNULL
#
# itos Integer to String
# itos(dest_string,Value, Base{10,2,8,16)
#
#@PUSH Buffer1 @PUSH 123 @PUSH 10 @CALL itos
#@PRT "Integer to String:" @PRTS Buffer1 @PRTNL
#@PUSH Buffer1 @CALL stoi
#@PRT "String to I: " @POPI AA @PRTSGNI AA @PRTNL


@PUSH Buffer1 @PUSH 22500 @PUSH 16 @CALL itos
@PRT "Integer to String:" @PRTS Buffer1	 @PRTNL
@PUSH 0 @POPI Buffer2
@PRT "B2(empty): " @PRTS Buffer2
@PUSH Buffer2 @PUSH StrHexID @CALL strcat
@PRT "B3(0x):" @PRTS Buffer2
@PUSH Buffer2 @PUSH Buffer1 @CALL strcat
@PRT "B4(0x57E4): " @PRTS Buffer2
@PRTNL
@PUSH Buffer2 @CALL stoi
:break1
@PRT "String to I: " @POPI AA @PRTSGNI AA @PRTNL
@PUSH Buffer1 @PUSH -321 @PUSH 10 @CALL itos
@PRT "Integer to String:" @PRTS Buffer1 @PRTNL
@PUSH Buffer1 @CALL stoi
@PRT "String to I: " @POPI AA @PRTSGNI AA @PRTNL
#############################################
@STRSET "Animals Dog Cat Cow" Buffer1
@STRSET "Cat" CatString
@PRT "Searching for '" @PRTS CatString @PRT "' In string '" @PRTS Buffer1 @PRTLN "'"
@PUSH Buffer1 @PUSH CatString @CALL strstr
@PRT "Address match from: " @PRTREF Buffer1 @PRT " - " @PRTTOP @PRTNL
@POPI AA
@PRT "Result:'" @PRTSI AA @PRTLN "'"
@PRTLN "--------------- Mem Copy tests-------"

@MA2V Buffer1 AA   #Set Buffer1 to A-Z
@ForIA2B Index 0x40 0x5A
  @PUSHI Index @POPII AA
  @INCI AA
@Next Index
@MA2V Buffer2 AA   #Set Buffer1 to A-Z
@ForIA2B Index 0x40 0x5A
  @PUSH 0 @POPII AA
  @INCI AA
@Next Index
@PRTLN "First 5 chars from B1 to B2"
@PUSH Buffer2 @PUSH Buffer1 @PUSH 5
@CALL memcpy
@PRTS Buffer2
@PRTLN "Now 5 from B2[0] to B2[3]"
@PUSH Buffer2 @ADD 3 @PUSH Buffer2 @PUSH 5
@CALL memcpy
@PRTS Buffer2
@END


@END
