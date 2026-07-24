# Declare common Functions
#--------------------------------------
# ApplyOpt is helped with a calling macro to simplify the interface
# Call_ApplyOpt(OptCode, TypeCode, AVarLow, AVarHigh, BVarLow, BVarHigh, ResultType, ResultLow, ResultHigh)
#--------------------------------------
M Call_ApplyOpt \
   @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @PUSHI %5 @PUSHI %6 \
   @CALL ApplyOpt \
   @POPI %9 @POPI %8 @POPI %7
# Macro String Cleanup Helper @FreeIfString ( Type, Address )
M FreeIfString @IF_EQ_AV STRING_TYPE %1 \
    @Call(VV) HeapDeleteObjecct RunTimeHeap %2
#    
#-----------------------------
# Basic Run Loop.
#-----------------------------
:BasicRun
@PUSHRETURN
@Locals
   @Local Ptr
   
   @CALL RunTimeInit
   @MV2V LineTableBase BPC
   @MA2V 0 BreakFlag        # Reset Break Flag of start of all RUNs
   
   @WHILE_NEQ_AV 0 BPC
#       @CALL BasicCheckBreak
       @PUSH 1
       @IF_NOTZERO
         @POPNULL       
         @MV2V BPC LRL

         @Call(V) ExecuteLine BPC
         @IF_NEQ_AV RET_OK RET_CODE
           @MA2V 0 BPC
         @ELSE
           # GOTO's and GOSUBS will modify BPC so don't do NextLine if its been changed already.
           @IF_EQ_VV LRL BPC
              @Call(V) NextLine BPC
              @POPI BPC
           @ENDIF
         @ENDIF
       @ELSE
         @POPNULL
         @PRT "Break"
         @MA2V 0 BPC         
       @ENDIF         
   @ENDWHILE
   
@EndLocals
@POPRETURN
@RET

#----------------------------------
# NextLine(LinePtr):NewLine
#----------------------------------
:NextLine
@PUSHRETURN
@Locals
    @Local LinePtr
    @Local EndPtr
    
    @POPI LinePtr
    
    @IF_EQ_AV RET_OK RET_CODE
        @PUSHI LinePtr @ADD 4
        @POPI BPC
        @PUSHI ProgramLineCount
        @SHL2
        @ADDI LineTableBase
        @POPI EndPtr
        @PUSHI BPC
        @IF_UGE_V EndPtr
            @POPNULL
            @PUSH 0
        @ELSE
            @POPNULL
            @PUSHI BPC
        @ENDIF
    @ELSE
        @PUSH 0
    @ENDIF

    
@EndLocals
@POPRETURN
@RET

#-------------------------------
# ExecuteLine(LineTable Ptr)
#-------------------------------
:ExecuteLine
@PUSHRETURN
@Locals
    @Local Ptr
    @Local NewLineNum
    @Local NewBPC
    @Local NoVal
    @Local CondLow
    @Local CondHigh
    @Local ReturnBPC
    @Local FramePtr
    
    @ADD 2               # Tokenized Line starts at address at 2nd word
    @PUSHS
    @POPI Ptr

    @IF_EQ_AV RET_OK RET_CODE
#       @PUSHI Ptr @ADD 4 @POPI Ptr

       @PUSHII Ptr @AND 0xff

       @POPNULL
       @PUSHII Ptr @AND 0xff

       @WHILE_NEQ_A EOL_TOKEN                 
          @SWITCH
          @CASE PRINT_CODE
             @POPNULL
             @Call(V) PrintCommand Ptr
             @IF_ULT_A 100
                # Error state returnd, Systax issue
                @Call(AA) BasicRaiseError ERR_SYNTAX 0
             @ELSE
                @POPI Ptr
             @ENDIF
             @CBREAK
          @CASE END_CODE
             @POPNULL
             @MA2V RET_EOP RET_CODE
             @CBREAK
          @CASE DIM_CODE
             @POPNULL
             @INCI Ptr
             @Call(V) ParseDIM Ptr
             @IF_ULT_A 100
                @Call(AA) BasicRaiseError ERR_SYNTAX 0
             @ELSE
                @POPI Ptr
             @ENDIF
             @CBREAK
          @CASE LET_CODE
             # Let does nothing.
             @POPNULL
             @INCI Ptr
             @CBREAK
          @CASE VAR_TOKEN
             @POPNULL
             @Call(V) ParseLET Ptr
             @IF_ULT_A 100
                @Call(AA) BasicRaiseError ERR_SYNTAX 0
             @ELSE
                @POPI Ptr
             @ENDIF
             @CBREAK
          @CASE GOTO_CODE
             @POPNULL
             @INCI Ptr
             @Call(V) BasicEval Ptr
             @POPI4 Ptr NoVal NewLineNum NoVal
             @Call(V) FindLine NewLineNum
             @POPI NewBPC
             @IF_EQ_AV 0 NewBPC
                @PRT "Undefined Line Number: " @PRTI NewLineNum @PRTNL
                @Call(AA) BasicRaiseError ERR_UNDEF_LINE 0
             @ELSE
                @MV2V NewBPC BPC
             @ENDIF
             @CBREAK
          @CASE GOSUB_CODE
             @POPNULL
             @INCI Ptr
             @Call(V) BasicEval Ptr
             @POPI4 Ptr NoVal NewLineNum NoVal
             @Call(V) FindLine NewLineNum
             @POPI NewBPC
             @IF_EQ_AV 0 NewBPC
                @PRT "Undefined Line Number: " @PRTI NewLineNum @PRTNL
                @Call(AA) BasicRaiseError ERR_UNDEF_LINE 0
             @ELSE
                @Call(V) NextLine BPC
                @POPI ReturnBPC
                @Call(A) LogicStackPush LOGIC_FRAME_GOSUB
                @POPI FramePtr
                @IF_NEQ_AV 0 FramePtr
                   @FILL_AT_V FramePtr LOGIC_FRAME_OFF_RESUME_BPC ReturnBPC
                   @MV2V NewBPC BPC
                @ENDIF
             @ENDIF
             @CBREAK
          @CASE RETURN_CODE
             @POPNULL
             @INCI Ptr
             @Call(A) LogicStackPopType LOGIC_FRAME_GOSUB
             @POPI FramePtr
             @IF_EQ_AV 0 FramePtr
                @Call(AA) BasicRaiseError ERR_BAD_RETURN 0
             @ELSE
                @GET_FROM FramePtr LOGIC_FRAME_OFF_RESUME_BPC
                @POPI ReturnBPC
                @MV2V ReturnBPC BPC
             @ENDIF
             @CBREAK
          @CASE FOR_CODE
             @POPNULL
             @INCI Ptr
             @Call(V) ParseFOR Ptr
             @POPI Ptr
             @CBREAK
          @CASE NEXT_CODE
             @POPNULL
             @INCI Ptr
             @Call(V) HandleNEXT Ptr
             @POPI Ptr
             @CBREAK
          @CASE IF_CODE
             @POPNULL
             @INCI Ptr
             
             @Call(V) BasicEval Ptr
             @POPI4 Ptr CondHigh CondLow NoVal

             @PUSHII Ptr @AND 0xff
             @IF_NEQ_A THEN_CODE
                @Call(AA) BasicRaiseError ERR_SYNTAX 0
             @ENDIF
             @POPNULL
             @INCI Ptr             

             @PUSHI CondHigh
             @PUSHI CondLow
             @ORS
             @IF_ZERO
                @POPNULL   # False Case just goto next line. Later we'll deal with commands
                @Call(V) SkipToEOL Ptr
                @POPI Ptr
             @ELSE
                # True Case
                @POPNULL

                @Call(V) BasicEval Ptr
                @POPI4 Ptr NoVal NewLineNum NoVal
                
                @Call(V) FindLine NewLineNum
                @POPI NewBPC
                @IF_EQ_AV 0 NewBPC
                   @PRT "Undefined Line Number: " @PRTI NewLineNum @PRTNL
                   @Call(AA) BasicRaiseError ERR_UNDEF_LINE 0
                @ELSE
                   @MV2V NewBPC BPC
                   @Call(V) SkipToEOL Ptr
                   @POPI Ptr
                @ENDIF
             @ENDIF
             @CBREAK
          @CDEFAULT
             @POPNULL
             @Call(AA) BasicRaiseError ERR_SYNTAX 0
             @CBREAK
          @ENDCASE
          @IF_EQ_AV RET_OK RET_CODE
             @PUSHII Ptr @AND 0xff
          @ELSE
             @PUSH EOL_TOKEN
          @ENDIF
      @ENDWHILE
      @POPNULL
    @ENDIF
@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# LogicStackPush(FrameType):FramePtr | 0
#----------------------------------------
:LogicStackPush
@PUSHRETURN
@Locals
    @Local FrameType
    @Local FramePtr

    @POPI FrameType

    @PUSHI LogicStackTop
    @IF_UGE_A LOGIC_STACK_DEPTH
       @POPNULL
       @MA2V 0 FramePtr
       @Call(AA) BasicRaiseError ERR_STACK_OVERFLOW 0
    @ELSE
       @POPNULL
       @INDEXV_PTR LogicStackBase LogicStackTop LOGIC_FRAME_SIZE
       @POPI FramePtr
       @FILL_AT_V FramePtr LOGIC_FRAME_OFF_TYPE FrameType
       @INCI LogicStackTop
    @ENDIF

    @PUSHI FramePtr

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# LogicStackTopFrame():FramePtr | 0
#----------------------------------------
:LogicStackTopFrame
@PUSHRETURN
@Locals
    @Local FramePtr
    @Local Index

    @IF_EQ_AV 0 LogicStackTop
       @MA2V 0 FramePtr
    @ELSE
       @PUSHI LogicStackTop
       @SUB 1
       @POPI Index
       @INDEXV_PTR LogicStackBase Index LOGIC_FRAME_SIZE
       @POPI FramePtr
    @ENDIF

    @PUSHI FramePtr

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# LogicStackPopType(FrameType):FramePtr | 0
#----------------------------------------
:LogicStackPopType
@PUSHRETURN
@Locals
    @Local FrameType
    @Local FramePtr
    @Local ActualType

    @POPI FrameType

    @CALL LogicStackTopFrame
    @POPI FramePtr
    @IF_EQ_AV 0 FramePtr
       @MA2V 0 FramePtr
    @ELSE
       @GET_FROM FramePtr LOGIC_FRAME_OFF_TYPE
       @POPI ActualType
       @IF_EQ_VV ActualType FrameType
          @DECI LogicStackTop
       @ELSE
          @MA2V 0 FramePtr
       @ENDIF
    @ENDIF

    @PUSHI FramePtr

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# SkipToEOL(Ptr):Ptr
#----------------------------------------
:SkipToEOL
@PUSHRETURN
@Locals
    @Local Ptr

    @POPI Ptr

    @PUSHII Ptr @AND 0xff
    @WHILE_NEQ_A EOL_TOKEN
        @POPNULL
        @INCI Ptr
        @PUSHII Ptr @AND 0xff
    @ENDWHILE
    @POPNULL

    @PUSHI Ptr

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# ParseFOR(Ptr):Ptr
#----------------------------------------
:ParseFOR
@PUSHRETURN
@Locals
    @Local PtrIn
    @Local VarPtr
    @Local VarType
    @Local EvalType
    @Local LowWord
    @Local HighWord
    @Local LimitLow
    @Local LimitHigh
    @Local StepLow
    @Local StepHigh
    @Local ResumeBPC
    @Local FramePtr

    @POPI PtrIn

    @Call(V) ParseVarName PtrIn
    @IF_ZERO
       @Call(AA) BasicRaiseError ERR_SYNTAX 0
    @ENDIF
    @POPI PtrIn
    @POPI VarPtr

    @PUSHI VarPtr @ADD VAROFF_TypeID
    @PUSHS
    @AND 0xf
    @POPI VarType
    @IF_EQ_AV STRING_TYPE VarType
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF
    @IF_EQ_AV FLOAT_TYPE VarType
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF

    @PUSHII PtrIn @AND 0xff
    @IF_NEQ_A "=\0"
       @Call(AA) BasicRaiseError ERR_SYNTAX 0
    @ENDIF
    @POPNULL
    @INCI PtrIn

    @Call(V) BasicEval PtrIn
    @POPI4 PtrIn HighWord LowWord EvalType
    @Call(VVVV) CoerceType VarType EvalType LowWord HighWord
    @POPI3 VarType HighWord LowWord
    @Call(VAVVV) SetVarVal VarPtr 0 LowWord HighWord VarType
    @POPNULL

    @PUSHII PtrIn @AND 0xff
    @IF_NEQ_A TO_CODE
       @Call(AA) BasicRaiseError ERR_SYNTAX 0
    @ENDIF
    @POPNULL
    @INCI PtrIn

    @Call(V) BasicEval PtrIn
    @POPI4 PtrIn HighWord LimitLow EvalType
    @Call(VVVV) CoerceType VarType EvalType LimitLow HighWord
    @POPI3 VarType LimitHigh LimitLow

    @MA2V 1 StepLow
    @MA2V 0 StepHigh
    @PUSHII PtrIn @AND 0xff
    @IF_EQ_A STEP_CODE
       @POPNULL
       @INCI PtrIn
       @Call(V) BasicEval PtrIn
       @POPI4 PtrIn HighWord LowWord EvalType
       @Call(VVVV) CoerceType VarType EvalType LowWord HighWord
       @POPI3 VarType StepHigh StepLow
    @ELSE
       @POPNULL
    @ENDIF

    @Call(V) NextLine BPC
    @POPI ResumeBPC
    @Call(A) LogicStackPush LOGIC_FRAME_FOR
    @POPI FramePtr
    @IF_NEQ_AV 0 FramePtr
       @FILL_AT_V FramePtr LOGIC_FRAME_OFF_RESUME_BPC ResumeBPC
       @FILL_AT_V FramePtr LOGIC_FRAME_OFF_VARPTR VarPtr
       @FILL_AT_V FramePtr LOGIC_FRAME_OFF_VARTYPE VarType
       @FILL_AT_V FramePtr LOGIC_FRAME_OFF_LIMIT_LOW LimitLow
       @FILL_AT_V FramePtr LOGIC_FRAME_OFF_LIMIT_HIGH LimitHigh
       @FILL_AT_V FramePtr LOGIC_FRAME_OFF_STEP_LOW StepLow
       @FILL_AT_V FramePtr LOGIC_FRAME_OFF_STEP_HIGH StepHigh
    @ENDIF

    @PUSHI PtrIn

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# HandleNEXT(Ptr):Ptr
#----------------------------------------
:HandleNEXT
@PUSHRETURN
@Locals
    @Local PtrIn
    @Local FramePtr
    @Local VarPtr
    @Local NextVarPtr
    @Local VarType
    @Local CurLow
    @Local CurHigh
    @Local StepLow
    @Local StepHigh
    @Local LimitLow
    @Local LimitHigh
    @Local NewLow
    @Local NewHigh
    @Local KeepLooping
    @Local ResumeBPC

    @POPI PtrIn

    @CALL LogicStackTopFrame
    @POPI FramePtr
    @IF_EQ_AV 0 FramePtr
       @Call(AA) BasicRaiseError ERR_BAD_NEXT 0
    @ELSE
       @GET_FROM FramePtr LOGIC_FRAME_OFF_TYPE
       @IF_NEQ_A LOGIC_FRAME_FOR
          @Call(AA) BasicRaiseError ERR_BAD_NEXT 0
       @ENDIF
       @POPNULL
    @ENDIF

    @IF_NEQ_AV 0 FramePtr
       @GET_FROM FramePtr LOGIC_FRAME_OFF_VARPTR
       @POPI VarPtr
       @PUSHII PtrIn @AND 0xff
       @IF_EQ_A VAR_TOKEN
          @POPNULL
          @Call(V) ParseVarName PtrIn
          @POPI PtrIn
          @POPI NextVarPtr
          @IF_NEQ_VV NextVarPtr VarPtr
             @Call(AA) BasicRaiseError ERR_SYNTAX 0
          @ENDIF
       @ELSE
          @POPNULL
       @ENDIF

       @GET_FROM FramePtr LOGIC_FRAME_OFF_VARTYPE
       @POPI VarType
       @GET_FROM FramePtr LOGIC_FRAME_OFF_STEP_LOW
       @POPI StepLow
       @GET_FROM FramePtr LOGIC_FRAME_OFF_STEP_HIGH
       @POPI StepHigh
       @GET_FROM FramePtr LOGIC_FRAME_OFF_LIMIT_LOW
       @POPI LimitLow
       @GET_FROM FramePtr LOGIC_FRAME_OFF_LIMIT_HIGH
       @POPI LimitHigh

       @Call(VA) GetVarVal VarPtr 0
       @POPI CurHigh
       @POPI CurLow
       @IF_EQ_AV INT_TYPE VarType
          @PUSHI CurLow
          @PUSHI StepLow
          @ADDS
          @POPI NewLow
          @MA2V 0 NewHigh
          @Call(VVVV) BasicForStillActive16 NewLow LimitLow StepLow StepHigh
          @POPI KeepLooping
       @ELSE
          @Call(VVVV) BasicAdd32 CurLow CurHigh StepLow StepHigh
          @POPI2 NewHigh NewLow
          @PUSHI6 NewLow NewHigh LimitLow LimitHigh StepLow StepHigh
          @CALL BasicForStillActive
          @POPI KeepLooping
       @ENDIF
       @Call(VAVVV) SetVarVal VarPtr 0 NewLow NewHigh VarType
       @POPNULL
       @IF_NEQ_AV 0 KeepLooping
          @GET_FROM FramePtr LOGIC_FRAME_OFF_RESUME_BPC
          @POPI ResumeBPC
          @MV2V ResumeBPC BPC
       @ELSE
          @Call(A) LogicStackPopType LOGIC_FRAME_FOR
          @POPNULL
       @ENDIF
    @ENDIF

    @PUSHI PtrIn

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# BasicAdd32(ALow,AHigh,BLow,BHigh):(Low,High)
#----------------------------------------
:BasicAdd32
@PUSHRETURN
@Locals
    @Local ALow
    @Local AHigh
    @Local BLow
    @Local BHigh

    @POPI4 BHigh BLow AHigh ALow
    @PUSH32I(V) ALow
    @PUSH32I(V) BLow
    @CALL ADD32S
    @POP32I(V) ALow
    @PUSHI ALow
    @PUSHI AHigh

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# BasicForStillActive16(ValueLow,LimitLow,StepLow,StepHigh):Bool
#----------------------------------------
:BasicForStillActive16
@PUSHRETURN
@Locals
    @Local ValueLow
    @Local LimitLow
    @Local StepLow
    @Local StepHigh

    @POPI4 StepHigh StepLow LimitLow ValueLow

    @PUSHI StepLow
    @AND 0x8000
    @IF_ZERO
       @POPNULL
       @PUSHI ValueLow
       @IF_LE_V LimitLow
          @POPNULL
          @PUSH 1
       @ELSE
          @POPNULL
          @PUSH 0
       @ENDIF
    @ELSE
       @POPNULL
       @PUSHI ValueLow
       @IF_GE_V LimitLow
          @POPNULL
          @PUSH 1
       @ELSE
          @POPNULL
          @PUSH 0
       @ENDIF
    @ENDIF

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# BasicForStillActive(ValueLow,ValueHigh,LimitLow,LimitHigh,StepLow,StepHigh):Bool
#----------------------------------------
:BasicForStillActive
@PUSHRETURN
@Locals
    @Local ValueLow
    @Local ValueHigh
    @Local LimitLow
    @Local LimitHigh
    @Local StepLow
    @Local StepHigh

    @POPI6 StepHigh StepLow LimitHigh LimitLow ValueHigh ValueLow

    # Compare Value - Limit. Positive steps continue while <= 0.
    # Negative steps continue while >= 0.
    @Call32(VV) CMP32S ValueLow LimitLow
    @PUSHI StepHigh
    @AND 0x8000
    @IF_ZERO
       @POPNULL
       @IF32_NEG
          @PUSH 1
       @ELSE
          @IF32_ZERO
             @PUSH 1
          @ELSE
             @PUSH 0
          @ENDIF
       @ENDIF
    @ELSE
       @POPNULL
       @IF32_NEG
          @PUSH 0
       @ELSE
          @PUSH 1
       @ENDIF
    @ENDIF

@EndLocals
@POPRETURN
@RET
#-----------------------------------------
# PrintCommand(Ptr)
#-----------------------------------------
:PrintCommand
@PUSHRETURN
@Locals
    @Local Ptr
    @Local EvalLow
    @Local EvalHigh
    @Local EvalType
    @Local NoNewLine

    @ADD 1
    @POPI Ptr
    @MA2V 0 NoNewLine

    @PUSHII Ptr @AND 0xff
    @WHILE_NEQ_A EOL_TOKEN
       @IF_EQ_A ",\0"
          # Comma's turn into spaces.
          @PRT "\t"
          @POPNULL
          @INCI Ptr
       @ELSE
          @IF_EQ_A ";\0"
             @POPNULL
             @MA2V 1 NoNewLine # If Line Ends before we do anything more printing, suppress linefeed
             @INCI Ptr
          @ELSE
             @POPNULL         
             @Call(V) BasicEval Ptr
             @POPI Ptr
             @POPI EvalHigh
             @POPI EvalLow
             @POPI EvalType

             @PUSHI EvalType
             @SWITCH
             @CASE INT_TYPE
                @PRTSGNI EvalLow
                @MA2V 0 NoNewLine
                @CBREAK
             @CASE LONG_TYPE
                @PUSHI EvalHigh
                @PRT32SignI EvalLow                
                @POPNULL
                @MA2V 0 NoNewLine
                @CBREAK
             @CASE STRING_TYPE
                @PRTSI EvalLow
                @Call(VV) HeapDeleteObject RunTimeHeap EvalLow @IF_NOTZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
                @POPNULL
                @MA2V 0 NoNewLine
                @CBREAK
             @CDEFAULT
                @Call(AA) BasicRaiseError ERR_SYNTAX 0
                @INCI Ptr
                @CBREAK
             @ENDCASE
             @POPNULL
          @ENDIF
       @ENDIF
       @PUSHII Ptr @AND 0xff
   @ENDWHILE
   @POPNULL
   @IF_EQ_AV 0 NoNewLine
      @PRTNL
   @ENDIF
   @PUSHI Ptr
   
   
   
   
   
@EndLocals
@POPRETURN
@RET

#----------------------------------------
# VarTypeCharCheck(Chr)
# Returns the Type code for Ptr->Character
#----------------------------------------
:VarTypeCharCheck
@PUSHRETURN
@Locals
    @Local Chr

    @POPI Chr

    @PUSHI Chr @AND 0xff
    @SWITCH
    @CASE "%\0"
       @POPNULL
       @PUSH INT_TYPE
       @CBREAK
    @CASE "#\0"
       @POPNULL
       @PUSH LONG_TYPE
       @CBREAK
    @CASE "$\0"
       @POPNULL
       @PUSH STRING_TYPE
       @CBREAK
    @CASE "!\0"
       @POPNULL
       @PUSH FLOAT_TYPE
       @CBREAK
    @CDEFAULT
       @POPNULL
       @PUSH INT_TYPE
       @CBREAK
    @ENDCASE

    
@EndLocals
@POPRETURN
 @RET
 
       
    

#----------------------------------------
# ParseVarName(Ptr):((VarPtr,Updated_Ptr)|(0 0))
#----------------------------------------
:ParseVarName
@PUSHRETURN
@Locals
   @Local PtrIn
   @Local StrLen
   @Local VarType

   @POPI PtrIn

   @PUSHII PtrIn @AND 0xff
   @IF_EQ_A VAR_TOKEN
      @POPNULL

      @INCI PtrIn                    # skip token

      @PUSHII PtrIn @AND 0xff
      @POPI StrLen

      @INCI PtrIn                    # <-- CRITICAL FIX (skip length byte)

      # PtrIn now points to string

      @IF_EQ_AV 0 StrLen
         # Varialble failed to parse
         # Treat as syntax error
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @PUSHI PtrIn @ADDI StrLen @SUB 1
      @PUSHS @AND 0xff
      @CALL VarTypeCharCheck
      @POPI VarType

      # Lookup variable
      @Call(VV) VarFindByStr PtrIn StrLen

      @IF_ZERO
         @POPNULL
         @Call(VVVA) NewVar PtrIn StrLen  VarType 0
      @ENDIF

   @ELSE
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
   @ENDIF

   @IF_ZERO
      # error → leave double 0
      @PUSH 0
   @ELSE
      # advance pointer past name
      @PUSHI PtrIn @ADDI StrLen
   @ENDIF

   
@EndLocals
@POPRETURN
@RET
#----------------------------------------
# PromteType uses too many arguments for @Call(V..) so create
# special purpose macro.
# Call_PromoteType( LeftType,A-Low,A-High, RightType, B-Low,B-High, ResultType)
#
# Updates: A-Low, A-High and ResultType
# (RestultType, A-Low, A-High)
#----------------------------------------
M Call_PromoteType \
   @PUSHI6 %1 %2 %3 %4 %5 %6 \
   @CALL PromoteType \
   @POPI5 %6 %5 %3 %2 %7


#----------------------------------------
# PromoteType(A_Type, A_Low, A_High, B_Type, B_Low, B_High)
# Return:(ResultType, A_Low, A_High, B_Low, B_High)
#----------------------------------------
:PromoteType
@PUSHRETURN
@Locals
   @Local A_Type
   @Local B_Type
   @Local A_Low
   @Local A_High
   @Local B_Low
   @Local B_High
   @Local ResultType

   @POPI6 B_High B_Low B_Type A_High A_Low A_Type

   # No auto conversion of strings, reject for assignments without VAL function
   @IF_EQ_AV STRING_TYPE A_Type
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
   @ENDIF
   
   @IF_EQ_AV STRING_TYPE B_Type
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
   @ENDIF
   
   # IF either side is Long Result is Long
   @MV2V A_Type ResultType
   
   @IF_NEQ_VV A_Type B_Type
      @MA2V LONG_TYPE ResultType
   @ENDIF

   # If Result is long widen INT Operands
   @IF_EQ_AV LONG_TYPE ResultType
      @IF_EQ_AV INT_TYPE A_Type
         @MA2V 0 A_High
      @ENDIF
      @IF_EQ_AV INT_TYPE B_Type
         @MA2V 0 B_High
      @ENDIF
   @ENDIF

   @PUSHI5 ResultType  A_Low A_High B_Low B_High

   
   
   
   
   
   
   
   
@EndLocals
@POPRETURN
@RET


#-----------------------------------------
# CoerceType(TargeType, SourceType, LowWord, HighWord)
# For Assignment, makes sure Word is comptable with TargetTyp
#-----------------------------------------
:CoerceType
@PUSHRETURN
@Locals
   @Local TargetType
   @Local SourceType
   @Local LowWord
   @Local HighWord

   @POPI4 HighWord LowWord SourceType TargetType
   
   @PUSHI TargetType
   @SWITCH
   @CASE INT_TYPE
      @PUSHI SourceType
      @SWITCH
      @CASE INT_TYPE
         @CBREAK     # Do nothing INT<->INT
      @CASE LONG_TYPE
         @IF_NEQ_AV 0 HighWord
            @Call(AA) BasicRaiseError ERR_OUT_RANGE 0
         @ENDIF
         @MA2V 0 HighWord   # truncate
         @CBREAK
      @CASE STRING_TYPE     # At this time need fucnction to convert string to int.
         @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
         @CBREAK
      @CDEFAULT
         @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
         @CBREAK
      @ENDCASE
      @POPNULL
      @CBREAK
   @CASE LONG_TYPE
      @PUSHI SourceType
      @SWITCH
      @CASE INT_TYPE
         @MA2V 0 HighWord     # Widen
         @CBREAK
      @CASE LONG_TYPE
         @CBREAK   # Do nothing.
      @CASE STRING_TYPE     # At this time need fucnction to convert string to int.
         @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
         @CBREAK
      @CDEFAULT
         @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
         @CBREAK
      @ENDCASE
      @POPNULL
      @CBREAK
   @CASE STRING_TYPE
      @IF_NEQ_AV STRING_TYPE SourceType
         @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
      @ENDIF
      @CBREAK
   @CDEFAULT
      @CBREAK
   @ENDCASE
   @POPNULL
#
   @PUSHI3 LowWord HighWord TargetType
   
@EndLocals
@POPRETURN
@RET
         
  

# ParseLET(Ptr):(Ptr)
#-----------------------------------------
:ParseLET
@PUSHRETURN
@Locals
   @Local PtrIn
   @Local VarPtr
   @Local IndexVal
   @Local HasIndex
   @Local EvalLow
   @Local EvalHigh
   @Local EvalType
   @Local VarType
   @Local FinalType

   @POPI PtrIn
   
   @MA2V 0 HasIndex
   #-------------------------
   # Parse Variable
   #-------------------------
   @Call(V) ParseVarName PtrIn
   @IF_ZERO
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
   @ENDIF

   @POPI PtrIn
   @POPI VarPtr

   @IF_EQ_AV 0 VarPtr
      @Call(AA) BasicRaiseError ERR_UNDEF_VAR 0
   @ENDIF

   #-------------------------
   # Optional Array Index
   #-------------------------
   @PUSHII PtrIn @AND 0xff
   @IF_EQ_A "(\0"
      @POPNULL

      @INCI PtrIn
      @Call(V) BasicEval PtrIn
      @POPI4 PtrIn EvalHigh EvalLow EvalType

      @IF_NEQ_AV INT_TYPE EvalType
         @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
      @ENDIF

      @MV2V EvalLow IndexVal
      @MA2V 1 HasIndex

      @PUSHII PtrIn @AND 0xff
      @IF_NEQ_A ")\0"
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @POPNULL

      @INCI PtrIn
      @PUSHII PtrIn @AND 0xff
   @ENDIF

   #-------------------------
   # Expect "="
   #-------------------------
   @IF_NEQ_A "=\0"
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
   @ENDIF
   @POPNULL
   @INCI PtrIn

   #-------------------------
   # Evaluate RHS
   #-------------------------
   @Call(V) BasicEval PtrIn
   @POPI4 PtrIn EvalHigh EvalLow EvalType


   #-------------------------
   # Get Variable Type
   #-------------------------
   @PUSHI VarPtr @ADD VAROFF_TypeID
   @PUSHS
   @AND 0xf
   @POPI VarType

   #-------------------------
   # Type Checking
   #-------------------------   
   @Call(VVVV) CoerceType VarType EvalType EvalLow EvalHigh
   @POPI3 FinalType EvalHigh EvalLow


   #-------------------------
   # Assign Value
   #-------------------------
   @IF_NEQ_AV 0 HasIndex
      @Call(VVVVV) SetVarVal VarPtr IndexVal EvalLow EvalHigh FinalType
   @ELSE
      @Call(VAVVV) SetVarVal VarPtr 0 EvalLow EvalHigh FinalType
   @ENDIF
   @IF_EQ_AV STRING_TYPE FinalType
      @Call(VV) HeapDeleteObject RunTimeHeap EvalLow @IF_NOTZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
      @POPNULL
   @ENDIF
   @POPNULL          # future error return code, now all errors to to raiseerrror

   #-------------------------
   # Return updated pointer
   #-------------------------
   @PUSHI PtrIn
   
@EndLocals
@POPRETURN
@RET

# Format of token stream for DIM is
# DIM_CODE VAR_TOKEN Length_Byte String "("_TOKEN INTEGER ")"_TOKEN EOL
    
#-----------------------------------------
# ParseDIM(Ptr):(Ptr|0)
# ----------------------------------------
:ParseDIM
@PUSHRETURN
@Locals
   @Local PtrIn
   @Local DimSize
   @Local VarPtr
   @Local VarType
   @Local VarName
   @Local EvalType
   @Local HighWord
   @Local StrLen

   @POPI PtrIn

   #-------------------------
   # Parse Variable
   #-------------------------
   @Call(V) ParseVarName PtrIn
   @IF_ZERO
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
   @ENDIF

   @POPI PtrIn
   @POPI VarPtr
   #-------------------------
   # Expect "("
   #-------------------------
   @PUSHII PtrIn @AND 0xff
   @IF_NEQ_A "(\0"
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
   @ENDIF
   @POPNULL

   @INCI PtrIn

   #-------------------------
   # Evaluate size expression
   #-------------------------
   @Call(V) BasicEval PtrIn

   @POPI PtrIn
   @POPI HighWord
   @POPI DimSize
   @POPI EvalType

   @IF_NEQ_AV INT_TYPE EvalType
      @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
   @ENDIF

   #-------------------------
   # Expect ")"
   #-------------------------
   @PUSHII PtrIn @AND 0xff
   @IF_NEQ_A ")\0"
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
   @ENDIF
   @POPNULL
   @INCI PtrIn

   #-------------------------
   # Fetch existing type + name
   #-------------------------
   @PUSHI VarPtr @ADD VAROFF_TypeID
   @PUSHS
   @POPI VarType

   @PUSHI VarPtr @ADD VAROFF_Name
   @PUSHS
   @POPI VarName

   #-------------------------
   # Delete old variable
   #-------------------------
   @Call(V) DelVar VarPtr
   @POPNULL

   #-------------------------
   # Create new array
   #-------------------------
   @MA2V 2 StrLen
   @Call(AVVV) NewVar VarName StrLen VarType DimSize
   @POPI VarPtr

   # Return updated pointer
   @PUSHI PtrIn
   
@EndLocals
@POPRETURN
@RET
#------------------------------------------------
# BasicEval(Ptr):(type, Low, High, Ptr)
#------------------------------------------------
:BasicEval
@PUSHRETURN
@Locals
   @Local InPtr
   @Local TypeVal
   @Local CurrentType
   @Local LowWord
   @Local HighWord

    
   @POPI InPtr
   
   @Call(V) ParseLogical InPtr
   @POPI InPtr
   @POPI HighWord
   @POPI LowWord
   @POPI CurrentType

   @PUSHI CurrentType
   @PUSHI LowWord
   @PUSHI HighWord
   @PUSHI InPtr

@EndLocals
@POPRETURN
@RET
   
             

#------------------------------------------------
# ParseFactor(Inptr):(Type, Low, High, InPtr)
# Returns: LowWord, HighWord, Type, NewPtr
#------------------------------------------------
:ParseFactor
@PUSHRETURN
@Locals
   @Local InPtr
   @Local FieldLen
   @Local LowWord
   @Local HighWord
   @Local OutType
   @Local VarPtr
   @Local NewIndex
   @Local StoreEnd
   @Local EndPtr
   @Local NullSpot
   @Local Selected
   @Local ArgCount

   @POPI InPtr

   @MA2V INT_TYPE OutType   # default

   @PUSHII InPtr @AND 0xff
   @SWITCH

   #-------------------------
   # Unary Minus
   #-------------------------
   @CASE "-\0"
      @INCI InPtr
      @Call(V) ParseFactor InPtr
      @POPI InPtr
      @POPI HighWord
      @POPI LowWord
      @PUSHI OutType
      @POPI OutType
      @SWITCH
      @CASE INT_TYPE
          @PUSHI LowWord
          @COMP2
          @POPI LowWord
          @MA2V 0 HighWord
          @CBREAK
      @CASE LONG_TYPE
          @Call32(V) COMP232 LowWord
          @POP32I(V) LowWord
          @CBREAK          
      @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
      @ENDCASE
      @POPNULL
      @CBREAK
   @CASE_RANGE FIRST_FUNC_CODE LAST_FUNC_CODE
      @POPI Selected
      @INCI InPtr
      @Call(V) ParseFunctionArgs InPtr
      @POPI ArgCount
      @POPI InPtr
      @Call(VV) EvalFunctionCall ArgCount Selected
      @POPI3 HighWord LowWord OutType
      @PUSH 0                 # Fill for POPNULL
      @CBREAK      
   @CASE NOT_TOKEN
      @INCI InPtr
      @Call(V) ParseFactor InPtr
      @POPI InPtr
      @POPI HighWord
      @POPI LowWord
      @MA2V INT_TYPE OutType
      @SWITCH
      @CASE INT_TYPE
          @IF_EQ_AV 0 LowWord
             @MA2V 1 LowWord
          @ELSE
             @MA2V 0 LowWord
          @ENDIF
          @MA2V 0 HighWord
          @CBREAK
      @CASE LONG_TYPE
          @Call32(VA) CMP32S LowWord $$$0
          @IF32_ZERO
             @M32A2V $$$1 LowWord
          @ELSE
             @M32A2V $$$0 LowWord
          @ENDIF
          @CBREAK          
      @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
      @ENDCASE
      @POPNULL
      @CBREAK      

   #-------------------------
   # Parenthese
   #-------------------------
   @CASE "(\0"
      @INCI InPtr
      
      @Call(V) BasicEval InPtr
      @POPI InPtr
      @POPI HighWord
      @POPI LowWord
      @POPI OutType      
      # Expect ')'
      @PUSHII InPtr @AND 0xff
      @IF_NEQ_A ")\0"
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @POPNULL
      @INCI InPtr
      @CBREAK
   #-------------------------
   # INTEGER TOKEN
   #-------------------------
   @CASE INT_TOKEN
      @INCI InPtr

      # Read Digit field Length
      @PUSHII InPtr @AND 0xff
      @POPI FieldLen
      @INCI InPtr

      # EndPtr = First byte after numeric digit field.
      @PUSHI InPtr
      @ADDI FieldLen
      @POPI EndPtr

      # Temporarly Null Terminate the numeric text for stoi32
      @PUSHII EndPtr
      @POPI StoreEnd
      @PUSH 0
      @POPII EndPtr

      @Call(V) stoi32 InPtr

      # Restore original token stream word
      @PUSHI StoreEnd
      @POPII EndPtr

      # stoi32 returned Low/High word as normal
      @POPI HighWord
      @POPI LowWord

      #Default type is INT unless value or suffix forces LONG
      @MA2V INT_TYPE OutType

      @IF_NEQ_AV 0 HighWord
         @MA2V LONG_TYPE OutType
      @ENDIF

      @MV2V EndPtr InPtr
      # Optional long literal suffice 123#
      @PUSHII InPtr @AND 0xff
      @IF_EQ_A "#\0"
         @MA2V LONG_TYPE OutType
         @INCI InPtr
      @ENDIF
      @POPNULL
      @CBREAK
   #-------------------------
   # FLOAT TOKEN
   #-------------------------
   @CASE FLOAT_TOKEN
      @INCI InPtr
      @PUSHII InPtr @AND 0xff
      @POPI FieldLen
      @INCI InPtr
      # FLOAT decode not implemented yet
      @MA2V 0 LowWord
      @MA2V 0 HighWord
      @PUSHI InPtr
      @ADDI FieldLen
      @POPI InPtr
      @MA2V FLOAT_TYPE OutType
      @CBREAK

   #-------------------------
   # STRING TOKEN
   #-------------------------
   @CASE STRING_TOKEN
      @INCI InPtr

      @Call(V) StrBasicToC InPtr

      @POPI2 StrLen LowWord

      @MA2V 0 HighWord
      
      @PUSHI InPtr
      @ADDI StrLen
      @ADD 1
      @POPI InPtr

      @MA2V STRING_TYPE OutType
      @CBREAK

   #-------------------------
   # VARIABLE TOKEN
   #-------------------------
   @CASE VAR_TOKEN
      @INCI InPtr
      @PUSHII InPtr @AND 0xff
      @POPI FieldLen
      @INCI InPtr

      @Call(VV) VarFindByStr InPtr FieldLen
      @POPI VarPtr

      @IF_EQ_AV 0 VarPtr
         @Call(AA) BasicRaiseError ERR_UNDEF_VAR 0
      @ENDIF

      @PUSHI InPtr
      @ADDI FieldLen
      @POPI InPtr

      #---------------------------------
      # Check for array indexing
      #---------------------------------
      @PUSHII InPtr @AND 0xff
      @IF_EQ_A "(\0"
         @POPNULL
         @INCI InPtr

         # Recursive indenx evaluation
         @Call(V) BasicEval InPtr

         # Pop in correct order
         @POPI4 InPtr HighWord LowWord OutType

         # Index must be INT
         @IF_NEQ_AV INT_TYPE OutType
            @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
         @ENDIF

         @MV2V LowWord NewIndex

         # Now fetch value from array
         @Call(VV) GetVarVal VarPtr NewIndex
         @POPI HighWord
         @POPI LowWord

         # Update OutType from variable
         @PUSHI VarPtr @ADD VAROFF_TypeID
         @PUSHS
         @AND 0xf
         @POPI OutType

         # Handle the String Case
         @IF_EQ_AV STRING_TYPE OutType
            @Call(V) StrDupHeap LowWord
            @POPI LowWord
            @MA2V 0 HighWord
         @ENDIF
            

         # Expect closing ')'
         @PUSHII InPtr @AND 0xff
         @IF_NEQ_A ")\0"
            @Call(AA) BasicRaiseError ERR_SYNTAX 0
         @ENDIF
         @POPNULL

         @INCI InPtr

      @ELSE

         @POPNULL
         # Scalar variable
         @Call(VV) GetVarVal VarPtr 0
         @POPI HighWord
         @POPI LowWord

         @PUSHI VarPtr @ADD VAROFF_TypeID
         @PUSHS
         @AND 0xf
         @POPI OutType        
         @IF_EQ_AV STRING_TYPE OutType
            @Call(V) StrDupHeap LowWord
            @POPI LowWord
            @MA2V 0 HighWord         
         @ENDIF
         
      @ENDIF

      @CBREAK

   #-------------------------
   # DEFAULT
   #-------------------------
   @CDEFAULT
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @CBREAK

   @ENDCASE
   @POPNULL
   #---------------------------------
   # Return stack: Low, High, Type, Ptr
   #---------------------------------
   @PUSHI4 OutType LowWord HighWord InPtr

       @IF_NEQ_AV 0 Debug_Mode   @PRT "Return ParseFactor: " @StackDump @ENDIF
@EndLocals
@POPRETURN
@RET

#------------------------------
# ParseTerm(InPtr):(Type, Low, High,Ptr)
#------------------------------
:ParseTerm
@PUSHRETURN
@Locals
   @Local LeftLow
   @Local LeftHigh
   @Local LeftType
   @Local RightLow
   @Local RightHigh
   @Local RightType
   @Local InPtr
   @Local Operation
   @Local ResultType

   @POPI InPtr
   @Call(V) ParseFactor InPtr
   @POPI4  InPtr LeftHigh LeftLow LeftType

   @MV2V LeftType ResultType
   

   @WHEN
      @PUSHII InPtr @AND 0xff
      @SWITCH
         @CASE "*\0"
            @CBREAK
         @CASE "/\0"
            @CBREAK
         @CDEFAULT
            @POPNULL
            @PUSH 0
            @CBREAK
         @ENDCASE
      @DO_NOTZERO
         @POPI Operation
         @INCI InPtr
         @Call(V) ParseFactor InPtr
         @POPI4 InPtr RightHigh RightLow RightType

         @Call_PromoteType LeftType LeftLow LeftHigh RightType RightLow RightHigh ResultType
         @Call_ApplyOpt Operation ResultType LeftLow LeftHigh RightLow RightHigh LeftType LeftLow LeftHigh
                  
   @ENDWHEN
   @POPNULL
   @PUSHI4  LeftType LeftLow LeftHigh InPtr
   
@EndLocals
@POPRETURN
@RET
#---------------------------------------
# ApplyOpt(OptCode, TypeCode, AVarLow,AVarHigh, BVarLow, BVarHigh):(Type,Low,High)
#---------------------------------------
:ApplyOpt
@PUSHRETURN
@Locals
    @Local OptCode
    @Local TypeCode
    @Local AVarLow
    @Local AVarHigh
    @Local BVarLow
    @Local BVarHigh

    @POPI6 BVarHigh BVarLow AVarHigh AVarLow TypeCode OptCode

    @PUSHI OptCode
    @SWITCH
    @CASE "+\0"
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow @ADDI BVarLow
          @POPI AVarLow
          @MA2V 0 AVarHigh
          @CBREAK
       @CASE LONG_TYPE
          @Call32(VV) ADD32S AVarLow BVarLow
          @POP32I(V) AVarLow
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE "-\0"
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow @SUBI BVarLow
          @POPI AVarLow
          @MA2V 0 AVarHigh
          @CBREAK
       @CASE LONG_TYPE
          @Call32(VV) SUB32S AVarLow BVarLow
          @POP32I(V) AVarLow
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK      
    @CASE "*\0"
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @Call(VV) MUL AVarLow BVarLow
          @POPI AVarLow
          @MA2V 0 AVarHigh
          @CBREAK
       @CASE LONG_TYPE
          @Call32(VV) MUL32S AVarLow BVarLow
          @POP32I(V) AVarLow
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE "/\0"
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @IF_EQ_AV 0 BVarLow
              @Call(AA) BasicRaiseError ERR_DIV_ZERO 0
          @ENDIF
          @Call(VV) DIV AVarLow BVarLow
          @POPI AVarLow
          @POPNULL
          @MA2V 0 AVarHigh
          @CBREAK
       @CASE LONG_TYPE
          @Call32(AV) CMP32U $$$0 BVarLow
          @IF32_ZERO           # 32 bit library cms use 32 flag register not stack.
              @Call(AA) BasicRaiseError ERR_DIV_ZERO 0
          @ENDIF
          @Call32(VV) DIV32S AVarLow BVarLow
          @POP32I(V) AVarLow
          @POP32I(V) BVarLow
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE AND_TOKEN
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow @ANDI BVarLow
          @POPI AVarLow
          @MA2V 0 AVarHigh
          @CBREAK
       @CASE LONG_TYPE
          @Call32(VV) AND32 AVarLow BVarLow
          @POP32I(V) AVarLow
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE OR_TOKEN
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow @ORI BVarLow
          @POPI AVarLow
          @MA2V 0 AVarHigh
          @CBREAK
       @CASE LONG_TYPE
          @Call32(VV) OR32 AVarLow BVarLow
          @POP32I(V) AVarLow
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE ">\0"
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow
          @IF_GT_V BVarLow
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @POPNULL
          @MA2V 0 AVarHigh
          # TypeCode must already be INT_TYPE to reach here.
          @CBREAK
       @CASE LONG_TYPE          
          @Call32(VV) CMP32S AVarLow BVarLow
          @IF32_GT
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @MA2V 0 AVarHigh
          @MA2V INT_TYPE TypeCode
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE GE_TOKEN
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow
          @IF_GE_V BVarLow
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @POPNULL
          @MA2V 0 AVarHigh
          # TypeCode must already be INT_TYPE to reach here.
          @CBREAK
       @CASE LONG_TYPE          
          @Call32(VV) CMP32S AVarLow BVarLow
          @IF32_GE
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @MA2V 0 AVarHigh
          @MA2V INT_TYPE TypeCode
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE "<\0"
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow
          @IF_LT_V BVarLow
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @POPNULL
          @MA2V 0 AVarHigh
          # TypeCode must already be INT_TYPE to reach here.
          @CBREAK
       @CASE LONG_TYPE          
          @Call32(VV) CMP32S AVarLow BVarLow
          @IF32_LT
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @MA2V 0 AVarHigh
          @MA2V INT_TYPE TypeCode
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE LE_TOKEN
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow
          @IF_LE_V BVarLow
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @POPNULL
          @MA2V 0 AVarHigh
          # TypeCode must already be INT_TYPE to reach here.
          @CBREAK
       @CASE LONG_TYPE          
          @Call32(VV) CMP32S AVarLow BVarLow
          @IF32_LE
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @MA2V 0 AVarHigh
          @MA2V INT_TYPE TypeCode
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
    @CASE NE_TOKEN
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow
          @IF_NEQ_V BVarLow
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @POPNULL
          @MA2V 0 AVarHigh
          @CBREAK
       @CASE LONG_TYPE
          @Call32(VV) CMP32S AVarLow BVarLow
          @IF32_EQ
             @MA2V 0 AVarLow
          @ELSE
             @MA2V 1 AVarLow
          @ENDIF
          @MA2V 0 AVarHigh
          @MA2V INT_TYPE TypeCode
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK
          
    @CASE "=\0"
       @PUSHI TypeCode
       @SWITCH
       @CASE INT_TYPE
          @PUSHI AVarLow
          @IF_EQ_V BVarLow
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @POPNULL
          @MA2V 0 AVarHigh
          # TypeCode must already be INT_TYPE to reach here.
          @CBREAK        
       @CASE LONG_TYPE
          @Call32(VV) CMP32S AVarLow BVarLow
          @IF32_EQ
             @MA2V 1 AVarLow
          @ELSE
             @MA2V 0 AVarLow
          @ENDIF
          @MA2V 0 AVarHigh
          @MA2V INT_TYPE TypeCode
          @CBREAK
       @CDEFAULT
          @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
          @CBREAK
       @ENDCASE
       @POPNULL
       @CBREAK    
    @CDEFAULT
       @Call(AA) BasicRaiseError ERR_SYNTAX 0
       @CBREAK
    @ENDCASE
    @POPNULL

    @PUSHI3 TypeCode AVarLow AVarHigh

    
@EndLocals
@POPRETURN
@RET
#-----------------------------------------------
# ParseExpr(InPtr):(Type,LowWord,HighWord,InPtr)
#-----------------------------------------------
:ParseExpr
@PUSHRETURN
@Locals
    @Local InPtr
    @Local LeftLow
    @Local LeftHigh
    @Local LeftType
    @Local RightLow
    @Local RightHigh
    @Local RightType
    @Local ResultType
    @Local Operation
    @Local NewStrVal
    @Local LeftStrLen
    @Local RightStrLen
    @Local ReusultType
    @Local ResultLow
    @Local ResultHigh

    @POPI InPtr

    @Call(V) ParseTerm InPtr
    @POPI4 InPtr LeftHigh LeftLow LeftType

    @MV2V LeftType ResultType    
    @WHEN
       @PUSHII InPtr @AND 0xff
       @SWITCH
       @CASE "+\0"
          @CBREAK
       @CASE "-\0"
          @CBREAK
       @CASE AND_TOKEN
          @CBREAK
       @CASE OR_TOKEN
          @CBREAK
       @CDEFAULT
          @POPNULL
          @PUSH 0
          @CBREAK
       @ENDCASE
    @DO_NOTZERO
       @POPI Operation
       @INCI InPtr
       @Call(V) ParseTerm InPtr
       @POPI4 InPtr RightHigh RightLow RightType
       @IF_EQ_AV STRING_TYPE LeftType
           @IF_NEQ_AV "+\0" Operation
              # Not valid operation for string.
              @Call(AA) BasicRaiseError  ERR_SYNTAX 0
           @ENDIF              
           @IF_NEQ_AV STRING_TYPE RightType 
               # No Auto conversion of int to string, so type must match
               @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
           @ENDIF
           # Create a new Heap Object = the LEN of Left and Right +1
           @Call(V) strlen LeftLow
           @POPI LeftStrLen
           @Call(V) strlen RightLow
           @POPI RightStrLen
           @PUSHI RightStrLen
           @ADDI LeftStrLen
           @ADD 1
           @POPI NewStrVal
           @Call(VV) HeapNewObject RunTimeHeap NewStrVal
           @POPI ResultLow
           @MA2V 0 ResultHigh
           @MA2V STRING_TYPE ResultType
           @Call(VVV) memcpy ResultLow LeftLow LeftStrLen
           @PUSHI ResultLow @ADDI LeftStrLen @POPI NewStrVal  # Ptr to where RightStr Starts in result
           @Call(VVV) memcpy NewStrVal RightLow RightStrLen
           @PUSHI ResultLow @ADDI LeftStrLen @ADDI RightStrLen @POPI NewStrVal
           @Call(VAA) EmitByte NewStrVal  0 1
           @POPNULL @POPNULL
           #
           # Now clean up both Right and Left strings
           @Call(VV) HeapDeleteObject RunTimeHeap RightLow @IF_NOTZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
           @POPNULL
           @Call(VV) HeapDeleteObject RunTimeHeap LeftLow @IF_NOTZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
           @POPNULL
           # Now move all result to LEFT which is what the common return block uses.
           @MA2V 0 LeftHigh
           @MV2V ResultLow LeftLow
           @MA2V STRING_TYPE LeftType
       @ELSE
           @Call_PromoteType LeftType LeftLow LeftHigh RightType RightLow RightHigh ResultType
           @Call_ApplyOpt Operation ResultType LeftLow LeftHigh RightLow RightHigh LeftType LeftLow LeftHigh
           @MV2V LeftType ResultType
       @ENDIF
       @ENDWHEN
   @POPNULL
   @PUSHI4 LeftType LeftLow LeftHigh InPtr

   
   
@EndLocals
@POPRETURN
@RET

#------------------------------
# ParseRelation(InPtr):(Type, Low, High,Ptr)
#------------------------------
:ParseRelation
@PUSHRETURN
@Locals
   @Local LeftLow
   @Local LeftHigh
   @Local LeftType
   @Local RightLow
   @Local RightHigh
   @Local RightType
   @Local InPtr
   @Local Operation
   @Local ResultType

   @POPI InPtr

   @Call(V) ParseExpr InPtr
   @POPI4 InPtr LeftHigh LeftLow LeftType

   @MV2V LeftType ResultType

   @WHEN
      @PUSHII InPtr @AND 0xff
      @SWITCH
         @CASE NE_TOKEN
            @CBREAK
         @CASE LE_TOKEN
            @CBREAK
         @CASE GE_TOKEN
            @CBREAK
         @CASE NE_TOKEN
            @CBREAK
         @CASE "=\0"
            @CBREAK
         @CASE ">\0"
            @CBREAK
         @CASE "<\0"
            @CBREAK
         @CDEFAULT
            @POPNULL
            @PUSH 0
            @CBREAK
         @ENDCASE
      @DO_NOTZERO
         @POPI Operation
         @INCI InPtr
         @Call(V) ParseExpr InPtr
         @POPI4 InPtr RightHigh RightLow RightType

         @Call_PromoteType  LeftType LeftLow LeftHigh RightType RightLow RightHigh ResultType
         @Call_ApplyOpt Operation ResultType LeftLow LeftHigh RightLow RightHigh LeftType LeftLow LeftHigh
         
   @ENDWHEN
   @POPNULL
   @PUSHI4 LeftType LeftLow LeftHigh InPtr

   
@EndLocals
@POPRETURN
@RET

#------------------------------
# ParseLogical(InPtr):(Type, Low, High,Ptr)
#------------------------------
:ParseLogical
@PUSHRETURN
@Locals
   @Local LeftLow
   @Local LeftHigh
   @Local LeftType
   @Local RightLow
   @Local RightHigh
   @Local RightType
   @Local InPtr
   @Local Operation
   @Local ResultType


   @POPI InPtr

   @Call(V) ParseRelation InPtr
   @POPI4 InPtr LeftHigh LeftLow LeftType
   
   @MV2V LeftType ResultType

   @WHEN
      @PUSHII InPtr @AND 0xff
      @SWITCH
         @CASE AND_TOKEN
            @CBREAK
         @CASE OR_TOKEN
            @CBREAK
         @CDEFAULT
            @POPNULL
            @PUSH 0
            @CBREAK
         @ENDCASE
      @DO_NOTZERO
         @POPI Operation
         @INCI InPtr
         @Call(V) ParseExpr InPtr
         @POPI4 InPtr RightHigh RightLow RightType

         @Call_PromoteType LeftType LeftLow LeftHigh RightType RightLow RightHigh ResultType
         @Call_ApplyOpt Operation ResultType LeftLow LeftHigh RightLow RightHigh LeftType LeftLow LeftHigh
         
   @ENDWHEN
   @POPNULL
   @PUSHI4 LeftType LeftLow LeftHigh InPtr

@EndLocals
@POPRETURN
@RET

#---------------------------------
# ParseFunctionArgs(InPtr):[Type Low High Flag [Type Low High Flag .. ] InPtr Count ]
:ParseFunctionArgs
@PUSHRETURN
@Locals
   @Local Count
   @Local HighVal
   @Local LowVal
   @Local Flag
   @Local TypeVal
   @Local InPtr
   @Local Index

   @POPI InPtr

   # Expect "("
   @PUSHII InPtr @AND 0xff
   @IF_NEQ_A "(\0"
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
   @ENDIF
   @POPNULL
   @INCI InPtr

   @MA2V 0 Count
   @PUSHII InPtr @AND 0xff
   @WHILE_NEQ_A ")\0"
      @POPNULL
      @INCI Count
      @Call(V) BasicEval InPtr
      @POPI4 InPtr HighVal LowVal TypeVal
      @PUSHI TypeVal @PUSHI LowVal @PUSHI HighVal
      @IF_EQ_AV STRING_TYPE TypeVal
         @PUSH FLAG_HEAP
      @ELSE
         @PUSH FLAG_VAL
      @ENDIF
      @PUSHII InPtr @AND 0xff
      @IF_EQ_A ",\0"
         @POPNULL
         @INCI InPtr
         @PUSHI InPtr
      @ELSE
         @IF_NEQ_A ")\0"
            @Call(AA) BasicRaiseError ERR_SYNTAX 0
        @ENDIF
      @ENDIF
   @ENDWHILE
@POPNULL
@INCI InPtr
@PUSHI InPtr
@PUSHI Count
@EndLocals
@POPRETURN
@RET
#---------------------------------
# EvalFunctionCall(ArgCount Selected .. [ arg values ]):()
#---------------------------------
:EvalFunctionCall
@PUSHRETURN
@Locals
   @Local Count
   @Local Selected
   @Local TypeCode
   @Local HighWord
   @Local LowWord
   @Local FlagVal
   @Local TempStr
   @Local Position
   @Local LengthStr
   @Local NewPosition
   @Local OrigTempStr

   @POPI2 Selected Count

   @PUSHI Selected
   @SWITCH
   @CASE ABS_CODE
      @POPNULL
      @IF_NEQ_AV 1 Count
         # Not valid number arguments for ABS
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
     JMP EFC_ABS_CODE
     @CBREAK
   @CASE STR_LEFT
     @POPNULL
     @IF_NEQ_AV 2 Count
         # Not valid number arguments for LEFT
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @JMP EFC_LEFT_CODE
      @CBREAK
   @CASE STR_RIGHT
      @POPNULL
      @IF_NEQ_AV 2 Count
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @JMP EFC_RIGHT_CODE
      @CBREAK
   @CASE STR_MID
      @POPNULL
      @IF_NEQ_AV 3 Count
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @JMP EFC_MID_CODE
      @CBREAK
   @CASE LEN_CODE
      @POPNULL
      @IF_NEQ_AV 1 Count
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @JMP EFC_LEN_CODE
      @CBREAK      
   @CASE VAL_CODE
      @POPNULL
      @IF_NEQ_AV 1 Count
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @JMP EFC_VAL_CODE
      @CBREAK
   @CASE STR_STR
      @POPNULL
      @IF_NEQ_AV 1 Count
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @JMP EFC_STR_CODE
      @CBREAK
   @CASE STR_CHR
      @POPNULL
      @IF_NEQ_AV 1 Count
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @JMP EFC_CHR_CODE
      @CBREAK
   @CASE STR_ASC
      @POPNULL
      @IF_NEQ_AV 1 Count
         @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @ENDIF
      @JMP EFC_ASC_CODE
      @CBREAK   
   @CDEFAULT
      # Unknown Function
      @POPNULL
      @Call(AA) BasicRaiseError ERR_SYNTAX 0
      @CBREAK
   @ENDCASE
   :EFCReturn
@EndLocals
@POPRETURN
@RET
#-------------------------------
# Child Blocks for Function dispatch
#-------------------------------
         
######### ABS
:EFC_ABS_CODE
    @POPI4 FlagVal HighWord LowWord TypeCode
    @PUSHI TypeCode
    @SWITCH
    @CASE INT_TYPE
       @POPNULL
       @PUSHI LowWord
       @AND 0x8000
       @IF_NOTZERO
          @POPNULL
          @PUSHI LowWord
          @COMP2
          @POPI LowWord
       @ELSE
          @POPNULL
       @ENDIF
       @MA2V 0 HighWord
       @PUSH INT_TYPE
       @PUSHI LowWord
       @PUSHI HighWord
       @CBREAK
    @CASE LONG_TYPE
       @POPNULL
       @PUSHI HighWord
       @AND 0x8000            
       @IF_NOTZERO
          @POPNULL
          @Call(VV) COMP232 LowWord HighWord
          @POPI2 HighWord LowWord
       @ELSE
          @POPNULL
       @ENDIF
       @PUSH LONG_TYPE
       @PUSHI LowWord
       @PUSHI HighWord
       @CBREAK
    @CDEFAULT
       # Not a valid type fo ABS
       @POPNULL
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
       @CBREAK
    @ENDCASE
@JMP EFCReturn
########### LEFT

:EFC_LEFT_CODE
    # Pop length argument
    @POPI4 FlagVal HighWord Position TypeCode
    @IF_NEQ_AV INT_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF

    # Pop string argument
    @POPI4 FlagVal HighWord TempStr TypeCode
    @IF_NEQ_AV STRING_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF

    # Reject negative lengths
    @PUSHI Position
    @AND 0x8000
    @IF_NOTZERO
       @POPNULL
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ELSE
       @POPNULL
    @ENDIF

    # Alloc length = Position + 1
    @PUSHI Position
    @ADD 1
    @POPI LowWord        # reuse LowWord as AllocLen temporarily
    @PUSHI LowWord
    @IF_INRANGE_AB 1 254
       @POPNULL
       @Call(VV) HeapNewObject RunTimeHeap LowWord @IF_ULT_A 100 @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
       @POPI LowWord     # LowWord = new string ptr

       @Call(VVV) memcpy LowWord TempStr Position

       @PUSHI LowWord
       @ADDI Position
       @POPI HighWord    # temp address for terminator

       @Call(VAA) EmitByte HighWord 0 1

       @POPNULL @POPNULL
          
       @Call(VV) HeapDeleteObject RunTimeHeap TempStr @IF_NOTZERO @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
       @POPNULL

       @MA2V 0 HighWord
       @PUSH STRING_TYPE
       @PUSHI LowWord
       @PUSHI HighWord
    @ELSE
       @POPNULL
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF

@JMP EFCReturn


############ RIGHT$
:EFC_RIGHT_CODE
    # Pop length argument: Type, Low, High, Flag
    @POPI4 FlagVal HighWord LengthStr TypeCode
    @IF_NEQ_AV INT_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF

    # Pop string argument: Type, Low, High, Flag
    @POPI4 FlagVal HighWord TempStr TypeCode
    @IF_NEQ_AV STRING_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF

    # Preserve original source pointer for possible deletion.
    @MV2V TempStr OrigTempStr

    # Reject negative lengths.
    @PUSHI LengthStr
    @AND 0x8000
    @IF_NOTZERO
       @POPNULL
       @Call(AA) BasicRaiseError ERR_OUT_RANGE 0
    @ELSE
       @POPNULL
    @ENDIF

    # Position = strlen(source)
    @Call(V) strlen TempStr
    @POPI Position

    # LengthStr = min(requested length, source length)
    @PUSHI LengthStr
    @IF_GT_V Position
       @MV2V Position LengthStr
    @ENDIF
    @POPNULL    

    # NewPosition = source length - copy length
    @PUSHI Position
    @SUBI LengthStr
    @POPI NewPosition

    # Allocate result: copy length + null
    @PUSHI LengthStr
    @ADD 1
    @POPI LowWord              # LowWord temporarily holds allocation size

    @PUSHI LowWord
    @IF_INRANGE_AB 1 255
       @POPNULL
    @ELSE
       @POPNULL
       @Call(AA) BasicRaiseError ERR_OUT_RANGE 0
    @ENDIF

    @Call(VV) HeapNewObject RunTimeHeap LowWord
    @IF_ULT_A 100
       @Call(AA) BasicRaiseError ERR_MEMORY 0
    @ENDIF
    @POPI LowWord              # LowWord now holds destination pointer

    # TempStr = source + NewPosition
    @PUSHI TempStr
    @ADDI NewPosition
    @POPI TempStr

    # Copy LengthStr bytes.
    @Call(VVV) memcpy LowWord TempStr LengthStr

    # Null terminate at LowWord + LengthStr.
    @PUSHI LowWord
    @ADDI LengthStr
    @POPI HighWord             # HighWord temporarily holds null address
    @Call(VAA) EmitByte HighWord 0 1
    @POPNULL @POPNULL

    @Call(VV) HeapDeleteObject RunTimeHeap OrigTempStr
    @IF_NOTZERO
        @Call(AA) BasicRaiseError ERR_MEMORY 0
    @ENDIF
    @POPNULL
    # Return STRING_TYPE, result ptr, high=0, flag=temp heap
    @MA2V 0 HighWord
    @PUSH STRING_TYPE
    @PUSHI LowWord
    @PUSHI HighWord

@JMP EFCReturn
################# MID$
:EFC_MID_CODE
    # Pop length argument: Type, Low, High, Flag
    @POPI4 FlagVal HighWord LengthStr TypeCode
    @IF_NEQ_AV INT_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF
    # Pop Postion argument: Type, Low, High, Flag
    @POPI4 FlagVal HighWord Position TypeCode
    @IF_NEQ_AV INT_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF
    # Pop string argument: Type, Low, High, Flag
    @POPI4 FlagVal HighWord TempStr TypeCode
    @IF_NEQ_AV STRING_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF

    @MV2V TempStr OrigTempStr

    # Neigther postion or length can be negative.
    @PUSHI LengthStr
    @AND 0x8000
    @IF_NOTZERO
       @POPNULL
       @Call(AA) BasicRaiseError ERR_OUT_RANGE 0
    @ELSE
       @POPNULL
    @ENDIF
    @PUSH Position
    @AND 0x8000
    @IF_NOTZERO
       @POPNULL
       @Call(AA) BasicRaiseError ERR_OUT_RANGE 0
    @ELSE
       @POPNULL
    @ENDIF    
#
    # Now test if ranges makes sense.
    @Call(V) strlen TempStr
    @POPI HighWord                 # High Word will be input string length

    # First is Position larger than string length?
    @PUSHI Position
    @IF_GT_V HighWord
         @Call(AA) BasicRaiseError ERR_OUT_RANGE 0
    @ENDIF
    # Next handle case if Postion+LengthStr > String_Length
    @ADDI LengthStr
    @IF_GT_V HighWord
        # Don't error just truncate LengthStr to real length
        @POPNULL
        @PUSHI HighWord
        @SUBI LengthStr
        @POPI LengthStr
    @ELSE
        @POPNULL
    @ENDIF
    #
    # Now Create new string LengthStr+1
    @PUSHI LengthStr
    @ADD 1
    @POPI LowWord              # LowWord temp hold size+null bytes
    @Call(VV) HeapNewObject RunTimeHeap LowWord
    @IF_ULT_A 100
       @Call(AA) BasicRaiseError ERR_MEMORY 0
    @ENDIF
    @POPI LowWord

    # TempStr = Source + Position
    @PUSHI TempStr
    @ADDI Position
    @SUB 1
    @POPI TempStr
    #
    # Copy LengthStr bytes
    @Call(VVV) memcpy LowWord TempStr LengthStr
    #
    # Null end byte
    @PUSHI LowWord
    @ADDI LengthStr
    @POPI HighWord           # Temp holds null address
    @Call(VAA) EmitByte HighWord 0 1
    @POPNULL @POPNULL
    @Call(VV) HeapDeleteObject RunTimeHeap OrigTempStr
    @IF_NOTZERO
        @Call(AA) BasicRaiseError ERR_MEMORY 0
    @ENDIF
    @POPNULL
    @MA2V 0 HighWord
    @PUSH STRING_TYPE
    @PUSHI LowWord
    @PUSHI HighWord
@JMP EFCReturn
########################### LEN
:EFC_LEN_CODE
    # Pop String argument: Type
    @POPI4 FlagVal HighWord LowWord TypeCode
    @IF_NEQ_AV STRING_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF
    @Call(V) strlen LowWord
    @POPI LowWord
    @MA2V 0 HighWord
    @PUSH INT_TYPE
    @PUSHI LowWord
    @PUSHI HighWord
@JMP EFCReturn
############################ VAL  (INT only for now)
:EFC_VAL_CODE
    # Pop String argument: Type
    @POPI4 FlagVal HighWord LowWord TypeCode
    @IF_NEQ_AV STRING_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF
    @Call(V) stoi32 LowWord
    @Call(VV) HeapDeleteObject RunTimeHeap LowVal
    @IF_NOTZERO  @Call(AA) BasicRaiseError ERR_MEMORY 0 @ELSE POPNULL @ENDIF
    @POP32I(V) LowWord
    @PUSH LONG_TYPE
    @PUSHI LowWord
    @PUSHI HighWord
@JMP EFCReturn
############################ CHR$
:EFC_CHR_CODE
    # Pop String argument: Type
    @POPI4 FlagVal HighWord LowWord TypeCode
    @IF_NEQ_AV INT_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF
    # Char is 2 character long string, ascii code + null
    @Call(VA) HeapNewObject RunTimeHeap 2 @IF_ULT_A 100 @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
    @POPI TempStr
    @PUSHI LowWord @AND 0xff # We only support 8 bit ascii, this will be equal to char and null
    @POPII TempStr
    @PUSH STRING_TYPE
    @PUSHI TempStr
    @PUSH 0    
@JMP EFCReturn
############################ STR$
:EFC_STR_CODE
    # Pop String argument: Type
    @POPI4 FlagVal HighWord LowWord TypeCode
    @IF_NEQ_AV INT_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF    
    # Max length of Numeric string will be 12 characters (with null)
    @Call(VA) HeapNewObject RunTimeHeap 12 @IF_ULT_A 100 @Call(AA) BasicRaiseError ERR_MEMORY 0 @ENDIF
    @POPI TempStr
    # Only support base 10
    @PUSHI TempStr
    @PUSH32I(V) LowWord
    @PUSH 10
    @CALL i32tos # Do to mixed types need to use older call style
    @PUSH STRING_TYPE
    @PUSHI TempStr
    @PUSH  0    
@JMP EFCReturn
############################# ASC
:EFC_ASC_CODE
    # Pop String argument: Type
    @POPI4 FlagVal HighWord LowWord TypeCode
    @IF_NEQ_AV STRING_TYPE TypeCode
       @Call(AA) BasicRaiseError ERR_TYPE_MISMATCH 0
    @ENDIF
    @PUSHII LowWord @AND 0xff
    @Call(VV) HeapDeleteObject RunTimeHeap LowWord
    @IF_NOTZERO  @Call(AA) BasicRaiseError ERR_MEMORY 0 @ELSE POPNULL @ENDIF
    @POPI LowWord
    @PUSH INT_TYPE
    @PUSHI LowWord
    @PUSH 0
@JMP EFCReturn
    
    

    
    


M SIZESINCECOMMENT basic_eval.h
@SIZESINCE  
