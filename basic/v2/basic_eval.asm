# Declare common Functions
#-----------------------------
# Basic Run Loop.
#-----------------------------
:BasicRun
@PUSHRETURN
   @LocalVar Ptr 01
   
   @CALL RunTimeInit
   @MV2V LineTableBase BPC

   @WHILE_NEQ_AV 0 BPC
       @MV2V BPC LRL
       @IF_NEQ_AV 0 Debug_Mode @PRT "Before ExecuteLine: " @PUSHII BPC @PRTTOP @POPNULL @StackDump @PRTNL @ENDIF
       @Call(V) ExecuteLine BPC
       @IF_NEQ_AV RET_OK RET_CODE
           @WHILEBREAK
       @ENDIF
       # GOTO's and GOSUBS will modify BPC so don't do NextLine if its been changed already.
        @IF_NEQ_AV 0 Debug_Mode @PRT "After ExeuteLine: Cmp LRL:" @PRTHEXI LRL @PRT " and BPC:" @PRTHEXI BPC @PRTNL @ENDIF
       @IF_EQ_VV LRL BPC
          @Call(V) NextLine BPC
          @POPI BPC
       @ENDIF
       @IF_NEQ_AV 0 Debug_Mode          @PRT "Post BPC: " @PRTHEXI BPC @PRTNL  @ENDIF
         
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
    @ADD 2               # Tokenized Line starts at address at 2nd word
    @PUSHS
    @POPI Ptr

    @IF_EQ_AV RET_OK RET_CODE
#       @PUSHI Ptr @ADD 4 @POPI Ptr

       @PUSHII Ptr @AND 0xff
       @IF_NEQ_AV 0 Debug_Mode
          @PRT "Eval Code: " @PRTHEXTOP
          @CALL CodeToString
          @PRT " "          
       @ENDIF
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
          @PRT " "
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

#-----------------------------------------
# CoerceType(TargeType, SourceType, LowWord, HighWord)
# Determins what types can be copied to/over others
#-----------------------------------------
:CoerceType
@PUSHRETURN
   @LocalVar TargetType 01
   @LocalVar SourceType 02
   @LocalVar LowWord    03
   @LocalVar HighWord   04

   @POPI HighWord
   @POPI LowWord
   @POPI SourceType
   @POPI TargetType
   
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
   @PUSHI LowWord
   @PUSHI HighWord
   @PUSHI TargetType

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
      @POPI PtrIn
      @POPI EvalHigh
      @POPI EvalLow
      @POPI EvalType

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
   @POPI PtrIn
   @POPI EvalHigh
   @POPI EvalLow
   @POPI EvalType

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
   @POPI FinalType
   @POPI EvalHigh
   @POPI EvalLow


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
      @PUSHII InPtr @AND 0xff
      @POPI FieldLen
      @INCI InPtr
      @PUSHI InPtr @ADDI FieldLen
      @POPI EndPtr
      @PUSHII EndPtr
      @POPI StoreEnd
      @PUSH 0
      @POPII EndPtr
      @Call(V) stoi32 InPtr
      @PUSHI StoreEnd
      @POPII EndPtr
      @POPI HighWord
      @POPI LowWord
      @PUSHI InPtr
      @ADDI FieldLen
      @POPI InPtr
      @IF_NEQ_AV 0 HighWord
         @MA2V LONG_TYPE OutType
      @ELSE
         @MA2V INT_TYPE OutType
      @ENDIF
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
   @PUSHI OutType
   @PUSHI LowWord
   @PUSHI HighWord
   @PUSHI InPtr

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
   @POPI InPtr
   @POPI LeftHigh
   @POPI LeftLow
   @POPI LeftType
   

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
         @POPI InPtr
         @POPI RightHigh
         @POPI RightLow
         @POPI RightType
         
         # We'll need to rewrite for Floats, but until then
         # If LeftType and RightType are not same, then one has to be LONG_TYPE
         @MV2V LeftType ResultType
         @IF_NEQ_VV LeftType RightType
            @MA2V LONG_TYPE ResultType
         @ENDIF
         @IF_NEQ_VV ResultType LeftType
            @Call(VVVV) CoerceType ResultType LeftType LeftLow LeftHigh
            @POPI LeftType @POPI LeftHigh @POPI LeftLow
         @ENDIF
         @IF_NEQ_VV ResultType RightType         
            @Call(VVVV) CoerceType ResultType RightType RightLow RightHigh
            @POPI RightType @POPI RightHigh @POPI RightLow
         @ENDIF
         @PUSHI Operation @PUSHI ResultType @PUSHI LeftLow @PUSHI LeftHigh @PUSHI RightLow @PUSHI RightHigh
         @CALL ApplyOpt
         @POPI LeftHigh
         @POPI LeftLow
         @POPI LeftType
   @ENDWHEN
   @POPNULL
   @PUSHI LeftType
   @PUSHI LeftLow
   @PUSHI LeftHigh
   @PUSHI InPtr

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
    
    @POPI BVarHigh
    @POPI BVarLow
    @POPI AVarHigh
    @POPI AVarLow
    @POPI TypeCode
    @POPI OptCode

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

    @PUSHI TypeCode
    @PUSHI AVarLow
    @PUSHI AVarHigh

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
    @POPI InPtr
    @POPI LeftHigh
    @POPI LeftLow
    @POPI LeftType
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
       @POPI InPtr
       @POPI RightHigh
       @POPI RightLow
       @POPI RightType       
       # We'll need to rewrite for Floats, but until then
       # If LeftType and RightType are not same, then one has to be LONG_TYPE
       @MV2V LeftType ResultType
       @IF_NEQ_VV LeftType RightType
          @MA2V LONG_TYPE ResultType
       @ENDIF
       @IF_NEQ_VV ResultType LeftType
       @POPI Operation
       @INCI InPtr
       @Call(V) ParseTerm InPtr
       @POPI InPtr
       @POPI RightHigh
       @POPI RightLow
       @POPI RightType
       # We'll need to rewrite for Floats, but until then
       # If Le          @Call(VVVV) CoerceType ResultType LeftType LeftLow LeftHigh
          @POPI LeftType @POPI LeftHigh @POPI LeftLow
       @ENDIF
       @IF_NEQ_VV ResultType RightType         
          @Call(VVVV) CoerceType ResultType RightType RightLow RightHigh
          @POPI RightType @POPI RightHigh @POPI RightLow
       @ENDIF
       @PUSHI Operation @PUSHI ResultType @PUSHI LeftLow @PUSHI LeftHigh @PUSHI RightLow @PUSHI RightHigh
       @CALL ApplyOpt
       @POPI LeftHigh
       @POPI LeftLow
       @POPI LeftType
   @ENDWHEN
   @POPNULL
   @PUSHI LeftType
   @PUSHI LeftLow
   @PUSHI LeftHigh
   @PUSHI InPtr

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
   @POPI InPtr
   @POPI LeftHigh
   @POPI LeftLow
   @POPI LeftType
   

   @WHEN
      @PUSHII InPtr @AND 0xff
      @SWITCH
         @CASE NE_TOKEN
            @CBREAK
         @CASE LE_TOKEN
            @CBREAK
         @CASE LE_TOKEN
            @CBREAK
         @CASE GE_TOKEN
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
         @POPI InPtr
         @POPI RightHigh
         @POPI RightLow
         @POPI RightType
         
         # We'll need to rewrite for Floats, but until then
         # If LeftType and RightType are not same, then one has to be LONG_TYPE
         @MV2V LeftType ResultType
         @IF_NEQ_VV LeftType RightType
            @MA2V LONG_TYPE ResultType
         @ENDIF
         @IF_NEQ_VV ResultType LeftType
            @Call(VVVV) CoerceType ResultType LeftType LeftLow LeftHigh
            @POPI LeftType @POPI LeftHigh @POPI LeftLow
         @ENDIF
         @IF_NEQ_VV ResultType RightType         
            @Call(VVVV) CoerceType ResultType RightType RightLow RightHigh
            @POPI RightType @POPI RightHigh @POPI RightLow
         @ENDIF
         @PUSHI Operation @PUSHI ResultType @PUSHI LeftLow @PUSHI LeftHigh @PUSHI RightLow @PUSHI RightHigh
         @CALL ApplyOpt
         @POPI LeftHigh
         @POPI LeftLow
         @POPI LeftType
   @ENDWHEN
   @POPNULL
   @PUSHI LeftType
   @PUSHI LeftLow
   @PUSHI LeftHigh
   @PUSHI InPtr

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
   @POPI InPtr
   @POPI LeftHigh
   @POPI LeftLow
   @POPI LeftType
   

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
         @POPI InPtr
         @POPI RightHigh
         @POPI RightLow
         @POPI RightType
         
         # We'll need to rewrite for Floats, but until then
         # If LeftType and RightType are not same, then one has to be LONG_TYPE
         @MV2V LeftType ResultType
         @IF_NEQ_VV LeftType RightType
            @MA2V LONG_TYPE ResultType
         @ENDIF
         @IF_NEQ_VV ResultType LeftType
            @Call(VVVV) CoerceType ResultType LeftType LeftLow LeftHigh
            @POPI LeftType @POPI LeftHigh @POPI LeftLow
         @ENDIF
         @IF_NEQ_VV ResultType RightType         
            @Call(VVVV) CoerceType ResultType RightType RightLow RightHigh
            @POPI RightType @POPI RightHigh @POPI RightLow
         @ENDIF
         @PUSHI Operation @PUSHI ResultType @PUSHI LeftLow @PUSHI LeftHigh @PUSHI RightLow @PUSHI RightHigh
         @CALL ApplyOpt
         @POPI LeftHigh
         @POPI LeftLow
         @POPI LeftType
   @ENDWHEN
   @POPNULL
   @PUSHI LeftType
   @PUSHI LeftLow
   @PUSHI LeftHigh
   @PUSHI InPtr

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

