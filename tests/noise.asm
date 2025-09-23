I common.mc
L heapmgr.ld
L random.ld
# Create a 64x64 map of noise func
:MainHeap 0
:NWidth 0
:NoiseMap 0
:ANSICSI $$27 "[" $$0
######################################
# Function init
:init
   @PUSH ENDOFCODE @PUSH 0xf800 @SUB ENDOFCODE
   @CALL HeapDefineMemory
   @POPI MainHeap
   #
   # Define NxN word array
   @MA2V 64 NWidth
   @PUSHI NWidth @PUSHI NWidth
   @CALL MUL
   @PUSHI MainHeap @SWP
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 17" @END @ENDIF
   @POPI NoiseMap
 @RET

######################################
# Function FillMap
:FillMap
@PUSHRETURN
@LocalVar Index1 01
@LocalVar MapIndex 02
   @POPI NWidth
   @PUSHI NWidth @PUSHI NWidth @CALL MUL
   @PRT "Map Size:" @PRTTOP @PRTNL
   @ForIA2S Index1 0
      @PUSHI NoiseMap @PUSHI Index1 @SHL @ADDS
      @POPI MapIndex
      @CALL frnd16
      @AND 63
      @POPII MapIndex
   @Next Index1
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#####################################
# Function PrintMap
:PrintMap
@PUSHRETURN
@LocalVar Index1 01
@LocalVar Index2 02
@LocalVar AllIndex 03
   @MA2V 0 AllIndex
   @ForIA2V Index1 0 NWidth
      @PRTNL
      @ForIA2V Index2 0 NWidth
         @PUSHI NoiseMap @PUSHI AllIndex @SHL @ADDS
         @PUSHS
         @PRTS ANSICSI
         @PRT "38;5;" @PRTTOP @PRT "m"
         @SWITCH
         @CASE_RANGE 0 15
            @PRT "~"
            @CBREAK
         @CASE_RANGE 16 31
            @PRT "^"
            @CBREAK
         @CASE_RANGE 32 47
            @PRT "#"
            @CBREAK
         @CDEFAULT
            @PRT "!"
            @CBREAK
         @ENDCASE
         @POPNULL
         @INCI AllIndex         
      @Next Index2
   @Next Index1
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#
:Main . Main
@CALL init
@PUSH 64
@CALL FillMap
@CALL PrintMap
@PRTS ANSICSI
@PRT "0m"
@PRTNL
@END
:ENDOFCODE
