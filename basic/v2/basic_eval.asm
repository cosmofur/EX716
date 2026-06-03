# Declare common Functions
#--------------------------------------
# ApplyOpt is helped with a calling macro to simplify the interface
# Call_ApplyOpt(OptCode, TypeCode, AVarLow, AVarHigh, BVarLow, BVarHigh, ResultType, ResultLow, ResultHigh)
#--------------------------------------
M Call_ApplyOpt \
   @PUSHI %1 @PUSHI %2 @PUSHI %3 @PUSHI %4 @PUSHI %5 @PUSHI %6 \
   @CALL ApplyOpt \
   @POPI %9 @POPI %8 @POPI %7
#-----------------------------
# Basic Run Loop.
#-----------------------------
:BasicRun
@PUSHRETURN
   @LocalVar Ptr 01
   
   @CALL RunTimeInit
   @MV2V LineTableBase BPC
   @MA2V 0 BreakFlag        # Reset Break Flag of start of all RUNs
   
   @WHILE_NEQ_AV 0 BPC
       @CALL BasicCheckBreak
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
   @RestoreVar 01
@POPRETURN
@RET

#----------------------------------
# NextLine(LinePtr):NewLine
#----------------------------------
:NextLine
@PUSHRETURN
    @LocalVar LinePtr 01
    
    @POPI LinePtr
    
    @IF_EQ_AV RET_OK RET_CODE
        @PUSHI LinePtr @ADD 4
        @POPI BPC
        @PUSHI BPC
    @ELSE
        @PUSH 0
    @ENDIF

    @RestoreVar 01
@POPRETURN
@RET

#-------------------------------
# ExecuteLine(LineTable Ptr)
#-------------------------------
:ExecuteLine
@PUSHRETURN
    @LocalVar Ptr 01
    @LocalVar NewLineNum 02
    @LocalVar NewBPC 03
    @LocalVar NoVal 04
    
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
    @RestoreVar 04    
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#-----------------------------------------
# PrintCommand(Ptr)
#-----------------------------------------
:PrintCommand
@PUSHRETURN
    @LocalVar Ptr 01
    @LocalVar EvalLow 02
    @LocalVar EvalHigh 03
    @LocalVar EvalType 04
    @LocalVar NoNewLine 05

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
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

#----------------------------------------
# VarTypeCharCheck(Chr)
# Returns the Type code for Ptr->Character
#----------------------------------------
:VarTypeCharCheck
@PUSHRETURN
    @LocalVar Chr 01

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

    @RestoreVar 01
 @POPRETURN
 @RET
 
       
    

#----------------------------------------
# ParseVal(Ptr):((VarPtr,Updated_Ptr)|(0 0))
#----------------------------------------
:ParseVal
@PUSHRETURN
   @LocalVar PtrIn 01
   @LocalVar StrLen 02
   @LocalVar VarType 03

   @POPI PtrIn

       @IF_NEQ_AV 0 Debug_Mode   @PRT "ParseVal(" @PRTHEXI PtrIn @PRT ")\n" @ENDIF

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

       @IF_NEQ_AV 0 Debug_Mode   @PRT "Return ParseVal: " @StackDump @ENDIF
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
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
   @LocalVar A_Type      01
   @LocalVar B_Type      02
   @LocalVar A_Low       03
   @LocalVar A_High      04
   @LocalVar B_Low       05
   @LocalVar B_High      06
   @LocalVar ResultType  07

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

   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
   
@POPRETURN
@RET


#-----------------------------------------
# CoerceType(TargeType, SourceType, LowWord, HighWord)
# For Assignment, makes sure Word is comptable with TargetTyp
#-----------------------------------------
:CoerceType
@PUSHRETURN
   @LocalVar TargetType 01
   @LocalVar SourceType 02
   @LocalVar LowWord    03
   @LocalVar HighWord   04

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

   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
         
  

#-----------------------------------------
# ParseLET(Ptr):(Ptr)
#-----------------------------------------
:ParseLET
@PUSHRETURN
   @LocalVar PtrIn      01
   @LocalVar VarPtr     02
   @LocalVar IndexVal   03
   @LocalVar HasIndex   04
   @LocalVar EvalLow    05
   @LocalVar EvalHigh   06
   @LocalVar EvalType   07
   @LocalVar VarType    08
   @LocalVar FinalType  09

   @POPI PtrIn
       @IF_NEQ_AV 0 Debug_Mode   @PRT "Top ParseLet PtrIn:" @PUSHI PtrIn @AND 0xff @PRTHEXTOP @POPNULL @PUSHI PtrIn @SHRN 8 @PRTHEXTOP @POPNULL @PRTNL @ENDIF
   
   @MA2V 0 HasIndex
   #-------------------------
   # Parse Variable
   #-------------------------
   @Call(V) ParseVal PtrIn
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
       @IF_NEQ_AV 0 Debug_Mode      @PRT "Inbound PtrIn:" @PUSHI PtrIn @AND 0xff @PRTHEXTOP @POPNULL @PUSHI PtrIn @SHRN 8 @PRTHEXTOP @POPNULL @PRTNL @ENDIF
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
   @POPNULL          # future error return code, now all errors to to raiseerrror

   #-------------------------
   # Return updated pointer
   #-------------------------
   @PUSHI PtrIn
   @RestoreVar 09
   @RestoreVar 08
   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET

# Format of token stream for DIM is
# DIM_CODE VAR_TOKEN Length_Byte String "("_TOKEN INTEGER ")"_TOKEN EOL
    
#-----------------------------------------
# ParseDIM(Ptr):(Ptr|0)
# ----------------------------------------
:ParseDIM
@PUSHRETURN
   @LocalVar PtrIn     01
   @LocalVar DimSize   02
   @LocalVar VarPtr    03
   @LocalVar VarType   04
   @LocalVar VarName   05
   @LocalVar EvalType  06
   @LocalVar HighWord  07
   @LocalVar StrLen    08

   @POPI PtrIn

   #-------------------------
   # Parse Variable
   #-------------------------
   @Call(V) ParseVal PtrIn
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
   @RestoreVar 08   
   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
#------------------------------------------------
# BasicEval(Ptr):(type, Low, High, Ptr)
#------------------------------------------------
:BasicEval
@PUSHRETURN
   @LocalVar InPtr       01
   @LocalVar TypeVal     02
   @LocalVar CurrentType 03
   @LocalVar LowWord     04
   @LocalVar HighWord    05

    
   @POPI InPtr
       @IF_NEQ_AV 0 Debug_Mode   @PRT "BasicEval(" @PRTHEXI InPtr @PRT ")\n" @ENDIF
   
   @Call(V) ParseLogical InPtr
   @POPI InPtr
   @POPI HighWord
   @POPI LowWord
   @POPI CurrentType

   @PUSHI CurrentType
   @PUSHI LowWord
   @PUSHI HighWord
   @PUSHI InPtr

       @IF_NEQ_AV 0 Debug_Mode   @PRT "Return BasicEval: " @StackDump @ENDIF
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01
@POPRETURN
@RET
   
             

#------------------------------------------------
# ParseFactor(Inptr):(Type, Low, High, InPtr)
# Returns: LowWord, HighWord, Type, NewPtr
#------------------------------------------------
:ParseFactor
@PUSHRETURN
   @LocalVar InPtr     01
   @LocalVar FieldLen  02
   @LocalVar LowWord   03
   @LocalVar HighWord  04
   @LocalVar OutType   05
   @LocalVar VarPtr    06
   @LocalVar NewIndex  07
   @LocalVar StoreEnd  08
   @LocalVar EndPtr    09

   @POPI InPtr

       @IF_NEQ_AV 0 Debug_Mode   @PRT "ParseFactor("@PRTHEXI InPtr @PRT ")\n" @ENDIF

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
#      @PRT "Open (: Before INCI:" @PRTHEXI InPtr @PRTNL
      @INCI InPtr
#      @PRT "In ( InPtr:" @PUSHI InPtr @AND 0xff @PRTHEXTOP @POPNULL @PUSHI InPtr @SHRN 8 @PRTHEXTOP @POPNULL @PRTNL
      
      @Call(V) BasicEval InPtr
#      @PRT "Returned from Recursive Basic Eval with results: " @StackDump
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
      @PUSHII InPtr @AND 0xff
      @POPI FieldLen
      @INCI InPtr

      @Call(VV) HeapNewObject RunTimeHeap FieldLen
      @IF_ULT_A 100
         @Call(AA) BasicRaiseError ERR_MEMORY 0
      @ENDIF

      @POPI LowWord
      @MA2V 0 HighWord
      @Call(VVV) memcpy LowWord InPtr FieldLen

      @PUSHI InPtr
      @ADDI FieldLen
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
         @POPI InPtr
         @POPI OutType
         @POPI HighWord
         @POPI LowWord

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

   @RestoreVar 09
   @RestoreVar 08
   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01

       @IF_NEQ_AV 0 Debug_Mode   @PRT "Return ParseFactor: " @StackDump @ENDIF
@POPRETURN
@RET

#------------------------------
# ParseTerm(InPtr):(Type, Low, High,Ptr)
#------------------------------
:ParseTerm
@PUSHRETURN
   @LocalVar LeftLow    01
   @LocalVar LeftHigh   02
   @LocalVar LeftType   03
   @LocalVar RightLow   04
   @LocalVar RightHigh  05
   @LocalVar RightType  06
   @LocalVar InPtr      07
   @LocalVar Operation  08
   @LocalVar ResultType 09

   @POPI InPtr
       @IF_NEQ_AV 0 Debug_Mode   @PRT "ParseTerm(" @PRTHEXI InPtr @PRT ")\n" @ENDIF

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

   @RestoreVar 09
   @RestoreVar 08
   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01

       @IF_NEQ_AV 0 Debug_Mode   @PRT "Return ParseTerm: " @StackDump @ENDIF
@POPRETURN
@RET
#---------------------------------------
# ApplyOpt(OptCode, TypeCode, AVarLow,AVarHigh, BVarLow, BVarHigh):(Type,Low,High)
#---------------------------------------
:ApplyOpt
@PUSHRETURN
    @LocalVar OptCode    01
    @LocalVar TypeCode   02
    @LocalVar AVarLow    03
    @LocalVar AVarHigh   04
    @LocalVar BVarLow    05
    @LocalVar BVarHigh   06

    @POPI6 BVarHigh BVarLow AVarHigh AVarLow TypeCode OptCode

       @IF_NEQ_AV 0 Debug_Mode    @PRT "ApplyOpt(" @PRTHEXI OptCode @PRT ", " @PRTHEXI TypeCode @PRT ", " @PRTHEXI AVarLow
           @PRT ", " @PRTHEXI AVarHigh @PRT ", " @PRTHEXI BVarLow @PRT ", " @PRTHEXI BVarHigh @PRT ")\n" @ENDIF

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

       @IF_NEQ_AV 0 Debug_Mode    @PRT "Return ApplyOpt: " @StackDump @ENDIF

    @RestoreVar 06
    @RestoreVar 05
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
@POPRETURN
@RET
#-----------------------------------------------
# ParseExpr(InPtr):(Type,LowWord,HighWord,InPtr)
#-----------------------------------------------
:ParseExpr
@PUSHRETURN
    @LocalVar InPtr     01
    @LocalVar LeftLow   02
    @LocalVar LeftHigh  03
    @LocalVar LeftType  04
    @LocalVar RightLow  05
    @LocalVar RightHigh 06
    @LocalVar RightType 07
    @LocalVar ResultType 08
    @LocalVar Operation 09

    
    @POPI InPtr

       @IF_NEQ_AV 0 Debug_Mode    @PRT "ParseExpr(" @PRTHEXI InPtr @PRT ")\n" @ENDIF

    @Call(V) ParseTerm (InPtr)
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
       
       @Call_PromoteType LeftType LeftLow LeftHigh RightType RightLow RightHigh ResultType
       @Call_ApplyOpt Operation ResultType LeftLow LeftHigh RightLow RightHigh LeftType LeftLow LeftHigh
       @MV2V LeftType ResultType
   @ENDWHEN
   @POPNULL

   @PUSHI4 LeftType LeftLow LeftHigh InPtr

   @RestoreVar 09
   @RestoreVar 08
   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01

       @IF_NEQ_AV 0 Debug_Mode   @PRT "Return ParseExpr: " @StackDump @ENDIF

@POPRETURN
@RET

#------------------------------
# ParseRelation(InPtr):(Type, Low, High,Ptr)
#------------------------------
:ParseRelation
@PUSHRETURN
   @LocalVar LeftLow    01
   @LocalVar LeftHigh   02
   @LocalVar LeftType   03
   @LocalVar RightLow   04
   @LocalVar RightHigh  05
   @LocalVar RightType  06
   @LocalVar InPtr      07
   @LocalVar Operation  08
   @LocalVar ResultType 09

   @POPI InPtr
       @IF_NEQ_AV 0 Debug_Mode   @PRT "ParseReleation(" @PRTHEXI InPtr @PRT ")\n" @ENDIF

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

   @RestoreVar 09
   @RestoreVar 08
   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01

       @IF_NEQ_AV 0 Debug_Mode   @PRT "Return ParseTerm: " @StackDump @ENDIF
@POPRETURN
@RET

#------------------------------
# ParseLogical(InPtr):(Type, Low, High,Ptr)
#------------------------------
:ParseLogical
@PUSHRETURN
   @LocalVar LeftLow    01
   @LocalVar LeftHigh   02
   @LocalVar LeftType   03
   @LocalVar RightLow   04
   @LocalVar RightHigh  05
   @LocalVar RightType  06
   @LocalVar InPtr      07
   @LocalVar Operation  08
   @LocalVar ResultType 09

   @POPI InPtr
       @IF_NEQ_AV 0 Debug_Mode   @PRT "ParseLogical(" @PRTHEXI InPtr @PRT ")\n" @ENDIF

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

   @RestoreVar 09
   @RestoreVar 08
   @RestoreVar 07
   @RestoreVar 06
   @RestoreVar 05
   @RestoreVar 04
   @RestoreVar 03
   @RestoreVar 02
   @RestoreVar 01

       @IF_NEQ_AV 0 Debug_Mode   @PRT "Return ParseTerm: " @StackDump @ENDIF
@POPRETURN
@RET

M SIZESINCECOMMENT basic_eval.h
@SIZESINCE  

