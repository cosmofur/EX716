I common.mc
# This is an attempt to port the old z80 8K basic to EX716
#
# As we are porting a Z80 program, we'll define some registers, which are just memory addresses for us
:HL       # Combined 16 bit HL H is high, L is low
:LR b0
:HR b0
:DE       # Combined DE, D is High, E is Low
:ER b0
:DR b0
:BC       # Combined BC B is High C is low
:CR b0
:BR b0
:
#
# AR is the A register, in Z80 its 8bit but we'll use 16 for simplicity
:AR 0
# B
# Paramters that were in original code. Many not relevent
=ROMSTRT 0
=RAMSTRT 0
=RAMEND 0xf800
=LARGE 1
=CPM 0
=HUNTER 0
=MSTRCLK 1
=ACIA 0      # Enable MC6850 ACIA
=UART 0      # UART support
=PT_SUPP 0   # Paper Tape support
=IMSAI 0     # Cassette support
=MON85 0     # Not using ROM Monitor
=ACIANI 0    # Don't bother setting up serial port
=UARTINI 0   # No need for UART
=BOOT 0      # CPM Boot warm
=BDOS 5      # BDOS Entry? Probably not useful
=TBASE 0x100 # Load address for CPM
=CSTAT 3     # Offset of console statue, not very usefull
=RUBOUT 0x7f # RubOut Character old terminals
=FATAL 0xf7  # Used to indicate fatal call to inerupt (we don't have interupts)
#
# Begining of code parts
#
:BASIC
@MA2V RAM+1024 HL
@MA2V 0xae AR
@JMP INIT1
#
# Skip Character pointed at by HL until non-blank, Sub-Routine
#      As this is simple so no routine entry/exit overhead, stack unchanged.
:RST1
:SkipSpace   # SkipSpace(StingPtr)
    @PUSHRETURN
    @PUSHLOCALI HL
    @POPI HL
    @PUSHII HL @AND 0xff
    @WHILE_NE_A " \0"
       @POPNULL
       @INCI HL
       @PUSHII HL @AND 0xff       
    @ENDWHILE
    @POPNULL
    @PUSHI HL
    @POPLOCAL HL    
    @POPRETURN
    @RET
#
#
# RST2 Compare Strings, [HL] to [DE], ignore spaces, considers only up to 3 characters
:RST2
:Cmp3String   #Cmp3String(Str1Ptr,Str2Ptr)
    @PUSHRETURN
    @PUSHLOCALI CR       # We preserver C and B because old version did so.
    @PUSHLOCALI BR
    @POPI DE
    @POPI HL
    @MA2V 0 BR    
#
    @PUSHII DE @AND 0xff
    @MA2V 0 AR      # this will be our default return, if there is a match
    @WHILE_NOTZERO
      @PUSHI HL
      @CALL SkipSpace
      @POPI HL
      @PUSHII HL @AND 0xff
      @IF_EQ_S       # Both Characters are same.
         @POPNULL @POPNULL
         @INCI BR
         @INCI DE
         @INCI HL
         @PUSHII DE @AND 0xff  # Compare the next two letters
      @ELSE
         # Not equal, this is one of two possible exist points. Other is both strings are the same.
         @POPNULL @POPNULL
         @PUSHI BR
         @IF_GT_A 3
            # We have at least 3 characters match, return
            @MA2V 0 AR      #our return value is 0 if the is a match.
         @ELSE
            @MV2V BR AR     # Otherwise we return the B count of matching letters
         @ENDIF
         @PUSH 0            # this will stop the while loop         
      @ENDIF
    @ENDWHILE
    @POPNULL
    @PUSHI AR               # Result
    @POPLOCAL BR
    @POPLOCAL CR
    @POPRETURN
    @RET
#
# Store Floating Point Accumulator at HL
:RST3
:SFPA
:StoreFP      # StoreFP(ValuePtr) Stores 4 bytes FACC to ValuePtr
   @PUSHRETURN
   @PUSH FACC
   @SWP
   @PUSH 4   
   @CALL COPYD
   @POPRETURN
   @RET
#
#
# Copy memory from Src to DST of length
:COPYD
:CopyMemN   # (SrcPtr, DstPtr, Size)  Destructive to HL DE BR and AR
   @PUSHRETURN
   @POPI BR
   @POPI HL
   @POPI DE
   @PUSH 0
   @WHILE_NEQ_V BR      # Loop until BR==0
      @PUSHII DE @AND 0xff
      @PUSHII HL @AND 0xff00
      @XORS
      @POPII HL
      @INCI HL
      @INCI DE
      @DECI BR
   @ENDWHILE
   @POPNULL
   @POPRETURN
   @RET
#
#
# This 'subroutine' is not normal stack order. Return addess is not at TOS on entry.
:RST4
:INCPC
:Add2HLReturn  # Add TOS to HL and return
    @ADDI HL @POPI HL
    @RETS
#
#
# Load Floating Point Accumulator to address
:RST5
:LDFPA
:LoadFP       # LoadFP(ValuePtr) Stores [ValuePtr] to FACC
   @PUSHRETURN
   @PUSH FACC
   @PUSH 4
   @CALL COPYD
   @POPRETURN
   @RET
#
#
#
:PRERR
:ERROR
# List of error codes
=ZMERR 1 =STERR ZMERR+1 =SNERR STERR+1 =RTERR SNERR+1 =DAERR RTERR+1 =NXERR DAERR+1
=CVERR NXERR+1 =CKERR CVERR+1 =ZMERR CKERR+1 =STERR ZMERR+1 =SNERR STERR+1 =RTERR SNERR+1
=DAERR RTERR+1 =NXERR DAERR+1 =CVERR NXERR+1 =CKERR CVERR+1 =OVERR CKERR+1 =UNERR OVERR+1
:PrintError   # PrintError(ErrorCode)
# This is going to be diffrent from the original, as well call this than than jump it.
   @PUSHRETURN
   @SWITCH
   @CASE ZMERR
      @PRTLN "Math Error: LOG(X<=0),SQR(-X) or Divide zero"
      @END
      @JMP FATAL
   @CASE STERR
      @PRTLN "Error in Expression Stack"
      @JMP FATAL
      @CBREAK
   @CASE SNERR
      @PRTLN "Delimiter Error"
      @JMP FATAL
      @CBREAK
   @CASE RTERR
      @PRTLN "Return,with No Gosub"
      @JMP FATAL
      @CBREAK
   @CASE DAERR
      @PRTLN "Out of DATA"
      @JMP FATAL
      @CBREAK
   @CASE NXERR
      @PRTLN "NEXT with no FOR"
      @JMP FATAL
      @CBREAK
   @CASE CVERR
      @PRTLN "Conversion Error"
      @JMP FATAL
      @CBREAK
   @CASE CKERR
      @PRTLN "CheckSum Error."
      @JMP FATAL
      @CBREAK
   @CASE OVERR     # Non-Fatal errors start here.
      @PRTLN "OverFlow."
      @CBREAK
   @CDEFAULT
      @PRTLN "Unknown Error: " @PRTTOP
      @CBREAK
 @ENDCASE
 @POPRETURN
 @RET
#
# Initialization
:INIT1
#
# Some of the original 8k basic spent time setting up UART hardware here.
# We'll skip that part.
   @MA2V 0xf800 RAMEND  # Set RAMEND 
#
   @PUSH 
   @CALL IRAM
   # Setup Random Table
   @PUSH NRNDX
   @PUSH RNDX
   @PUSH 8
   @CALL COPYD
   @PRTS TERMM
   @PRTS READY
#
# Command input routine
:GETCM
:InputLine        # InputLine(BufferPtr, Max Lenth, Uses HL and BC
   # The original 8K handled a full featured input mode. For our use we'll just use the macro library
   @PUSHRETURN
   @POPI BC
   @POPI HL
   @READSI HL
   @POPRETURN
   @RET
#
#
# Zeros out the variables that are initilzied by NEW
:IRAM
   @ForIA2B HL BZERO EZERO
      @PUSH 0 @POPII HL
   @Next HL
   @PUSH NRNDX   # Reset the original RND tables
   @PUSH RNDX
   @CALL COPYD
   @MA2V TRND HL # For some reason 8K basic goes straigh to setting initial Rand here.
   @RET
#
#
#
# EXEC is the first major Worker procedure
#      it decodes command in IOBUFF and then goes to next command.
:EXEC
   @MV2V AR MULTI         # Reset MULTI SW to A register value.
   @MV2V AR FNMOD         # (I think AR will always be zero, but this is what 8K did)
   @INCI AR
   @MV2V AR RUNSW         # Set Run Switch to Immediate Mode
   @MA2V IOBUF+1 HL
   @MA2V IMMED DE
   @PUSHII HL @AND 0xff   # Copy String until 0
   @WHILE_NOTZERO
      @POPII DE
      @INCI DE
      @INCI HL
      @PUSHII HL @AND 0xff
   @ENDWHILE
   @MA2V NULLI HL         # Point HLto the 'no line' number
   @PUSHI HL
   @POPI LINE             # save the address
   @JMP RUN3              # Interesting that it skips past 'RUN' and RUN1/2 first time.
#
# NEW COMMAND
# NEW ==> Clear program and data
# NEW* ==> Clear Program only
# One thing to note, on entry HL is expecd to be pointing at the input buffer still
:NEW
   @PUSHRTURN
   @PUSHI HL              # Skip any spaces and see if the next character
   @CALL RST1             # after NEW is not '*'
   @POPI HL
   @PUSHII HL @AND 0xff     
   @IF_NEQ_A "*\0"
      @MA2V 0 DATAB       # Put a zero at DATA Area to initilize it.
   @ENDIF
   @MV2V BEGPR PROGE      # Make Program End same as begining.
   @POPRETURN
   @RET
#
#
# FREE COMMAND
# Computr amount of available storage (Exclude Data area)
#
:FREE
   @PUSHI DATAB    # Beging address
   @SUBI PROGE     # End Address
   @CALL BINFL     # Bin to Float. (Original used DE, I'll use stack)
   @PUSH IOBUF
   @CALL FOUT      # Convert to Output
   @PUSH 0
   @POPII HL       # Mark it as end of string
   @CALL TERMO     # Write output
   @JMP GETCM
#
# TAPE Command
:TAPE
   # At this time we don't have a tape device, so we'll just print a warning
   @PRTLN "Warning Not Tape Device"
   @JMP GETCM
#
#
# RUN PROCESSOR GET NEXT STATEMENT AND EXECUTE IT.
# If in Immediate mode, return to GETCMMD
:RUNCM
   @PUSH 0
   @POPI DATAB   # Set DATAB to Zero
:XEQ
   @CALL IRAM    # Initiaize start of RAM
   @PUSH BEGPR-1
   @POPI HL      # Move HL to one infront of begining
   @MV2V HL DATAP   # Data Stmt pointer should now be equal to BEGPR-1
   @PUSH 0
   @POPII HL        # Zero out that bytes stored there.
   @INCI HL
   @MV2V HL STMT    # Save the BEGPR value to STMT
   @JMP RUN2        #Skip over Run1 because its for continuing not inital runs.
#
#
# Statements return here to Continue processing. 
:RUN
   @PUSHI MULTI
   IF_NOTZERO
      @POPNULL
      @MA2V 0 MULTI
      @MV2V ENDLI HL      # Next part will be RUN3
   @ELSE
      @POPNULL
      # Originally 8K Basic labled this part RUN1 and RUN2
      @MV2V STMT HL
      # In original 8K they invoked the DE register and added zero to HL...why?
   @ENDIF
:RUN2                # Strangely this is another entrance point to this RUN processing
   @PUSHI RUNSW
   @IF_NOTZERO
      @POPNULL
      @JMP GETCM
   @ENDIF
   @POPNULL
   @PUSHII HL @AND 0xff       # Is HL pointing to end of command string?
   @IF_NOTZERO
      # No contine
      @INCI HL
      @MV2V HL LINE
      @INC2I HL              # point to 2nd byte past addres
   @ELSE
      @JMP ENDIT             # Brif command
   @ENDIF
#
# We've seen RUN3 much earlier, its where immediate commands are processed.
#
# HL still points to the current spot of the command line
:RUN3
   @PUSH HL
   @CALL RST1      # Skip white Space
   @POPI HL
:RUN4
   @MV2V HL ADDR1     # Save HL for later
   @CALL TSTCC        # Test for ^C or O
   @PUSH JMPTB        # Point to Search Command Table
   @CALL SEEK1
   @IF_ZERO           # No command Found
      @PUSH WHATL     # Point to Literal
      @CALL TERMM     # Print it.
      @JMP GETCM
   @ENDIF
   @PUSHI HL          # Push value HL pointing to to stack, original 8K code took 7 statments to do this.
   @RETS              # Hmm artifct from 8K using a RET to act as a JMP to a command code.
#
#  SAVE Command
#
# This will be an important one to redo for my CPU but for now just report we don't support it
# In a basic way this is acting as a stdout redirect to the tape device.
:SAVE
   @MA2V 2 TAPES
   @PRT "Attept to save listing to Paper Tape. Not supported."
#
# LIST PROCESSOR
# DUMP the Source Program to TTY to output device.
# List many commands, HL still points to the command line to look for arguments.
:LIST
   @PUSHI HL
   @CALL RST1
   @POPI HL
   # First we need to see in the string HP pointing to has arguments
   # Set the default values if we don't find any.
   @MV2V BEGPR LINEL
   @MA2V 9999 LINEH
   # if we don't have any arguments, then we're done here.
   @PUSHII HL   
   @IF_NOTZERO
      @POPNULL
      @PUSHI HL
      @CALL PACK
      @POPI HL
      @POPI LINEL
      @MV2V LINEL LINEH # If we only have one line number argument we'll only print one line.
      #
      # Now check to see if there is a second argument
      @PUSHI HL
      @CALL RST1
      @POPI HL
      @PUSHII HL
      @IF_EQ_A ",\0"    # Check for Comma
         @INCI HL
         @PUSHI HL
         @CALL PACK
         @POPI HL
         @POPI LINEH    # Now has both LINEL and LINEH with unique numbers.
      @ENDIF
   @ENDIF
   #
   # Because the original 8K had to deal with a lot of 8 bit numbers the way it handled
   # this loop was a bit long winded. We're going to simplify it a bit
   # HL will point to the memory addresses where lines of code will be stored.
   # We'll compaire the line number part of each line to LINEL and LINEH
   # This means we'll be process every line number, just not printing the ones < LINEL or > LINEH
   @MV2V BEGPR HL
   @PUSHII HL @AND 0xff   # Look at first byte, zero is the end condition of loop
   @WHILE_NOTZERO
      @MV2V HL DE    # Save it so we can know what to add to HL later to get to next line.
      @INCI HL
      @PUSHII HL     # Value of Line Number
      @IF_GE_V LINEL
         @IF_LE_V LINEH
            @PRTTOP @PRTSP    #Print the line number
            @POPNULL
            @INC2I HL    # Set HL to point to string part
            @SUB 3       # String part is 3 bytes less than data structure size
            # Print Loop one char at a time.
            # We could make this faster with a PRTSI but lines may not be null terminated.
            @WHILE_NOTZERO
                @PUSHII HL @AND 0xff
                @POPI CHARPRT      # Our print libary can only print ASCIIZ strings.
                @PRTSI CHARPTR     # So we convert the 1 ch to a 2 byte string.
                @INCI HL
                @SUB 1
            @ENDWHILE
            @PRTNL
            @POPNULL
         @ELSE
            @POPNULL   # Case when HL is above LINEH
      @ELSE
         @POPNULL     # Case when HL is bellow LINEL
      @ENDIF
      # Top Of stack should hold Length of current line or zero
      @ADDI DE        # holding original value of HL before string print loop.
      @POPI HL        # HL should now point to begining of next lines data header.
      @PUSHII HL @AND 0xff
   @ENDWHILE
   @POPNULL
   @JMP ENDIT
#
#
# CONTINUE Exec after a STOP or ^C
#
:CONTI
   @PUSHII LINEN @AND 0xff
   @IF_ZERO
      @POPNULL
      @JMP LET
   @ENDIF
   @POPNULL
   # Drop down to GOTO
#
# Statment GOTO NNNN
:GOTO
    @MA2V 0 EDSW     # Reset IMMED Mode
    @MA2V 0 RUNSW    # Reset Run Mode
    @CALL NOTEO      # Error if at EOL
    @PUSHI HL
    @CALL PACK       # Get the required line number after GOTO
    @POPI HL
    @CALL EOL        # Error if not at EOL
:GOTO2
    @CALL LOCAT
    @JMPC ULERR      # Not Found
    @MV2V HL MULTI
    @JMP RUN2
#
# Statment RESTORE
# Statement RESTORE
#    Just as reminder RESTORE resets the internal DATA statements used to load constant data
#    embeded in the source code of Basic programs.
:RESTO
    @CALL EOL        # Error if not at EOL
    @MA2V BEGPR-1 HL # Point HL to 1 before start of program
    @MV2V HL DATAP   # Set next Data to be at HL
    @JMP RUN
#
# Statment RETURN
# do a return after a gosub
# 
:RETUR
   @CALL EOL         # Error if not at EOL
   @FLOD             # Restore a previous saved Flag stage
   @PUSHI AR
   @IF_NE_A 0xff     # If AR doesn't not equal 0xff then something is wrong
      @POPNULL
      @JMP RTERR
   @ENDIF
   @POPNULL
   @POPI STMT
   @POPI ENDLI
   @FLOD             # Restore flag state
   @MV2V AR MULTI
   @JMP RUN
#
# Statment GOSUB NNNN
# Setup a gosub for a subroutine
:GOSUB
   @CALL NOTEO       # Error if it is at EOL
   @PUSH HL
   @CALL PACK
   @POPI HL
:GOSU1
   @MV2V MULTI AR    # Save in A MULTI Switch setting
   @FSAV             # Save current flags
   @PUSHI ENDLI      # Save EndofLine value to stack
   @PUSHI STMT       # Save Statement Address
   @PUSH 0xff        # Mark on stack a gusub in effect
   @FSAV             # Preserve flag status
   @JMP GOTO2        # Branch to lookup line.
#
# Statment PRINT ...
:PRINT
   @MA2V 0 AR
:PRIN4                # Alternative entry when AR determins LF status
   @MV2V AR PRSW      # Sets switch for LF at end of line
   @MA2V IOBUF DE     # DE will be the pointer to IOBUF
   @PUSHI HL
   CALL RST1          # Skip WhileSpace
   @POPI HL
   @PUSHII HL @AND 0xff
   @CALL TSTEL        # Retun zero if end of statement
   @WHILE_NOTZERO
      @POPNULL
      @PUSHII HL @AND 0xff
      @SWITCH
      @CASE ",\0"
          @CALL TABST       # Print a tab
          @INCI HL
          @MA2V 1 AR          
          @CBREAK
      @CASE ";\0"
          @INCI HL
          @MA2V 1 AR
          @CBREAK
      @CDEFAULT
          @PUSHI HL @DUP
          @MA2V TABLI DE
          @PUSHI DE
          @CALL RST2
          @IF_ZERO
             @POPNULL
             @POPNULL
             @CALL EXPR       # Evaluate expressions at this point in print
             @PUSHI HL
             @CALL FBIN       # Turn float to binary
             @PUSHI PSW
             @SUBI COLUM
             
             
      


      @PUSHII HL @AND 0xff
      @CALL TSTEL        # Retun zero if end of statement
   @ENDWHILE
   @IF_EQ_VA AR 0
      @PRTNL
   @ENDIF
   
   
   
   
      
#
# Program Constants
:NRNDX
    b0x1b b0xec
:PCHOF      b19 b20 b0
:RNDP 0x3F0FD
      0x3F0EB
      0x3F0DD
NRNDX:
        0x1BEC
        0x33D3
        0x1A85
        0x2B1E
:WHATL  "WHAT\0"
:VERS   0x0d0a "BASIC EX716 V0.1\nBased on Z80 8K Basic\n\0"
:RBOUT  b0x8 b0x20 b0x8 b0xfe
:LLINE "LINE\0"
:TABLI "TAB\0"
:STEPL "STEP\0"
:THENL "THEN\0"
:PILIT "PI\0"
:TWO   0x8020 0x0        # 2
:TEN   0xa002 0xd70f     # 10
:PI    0xc902 0xd70f     # 3.141593
:QTRPI 0xc900 0xd70f     # 0.7853892
:NEGON 0xff80 0xffff     # -0.99999999
:LN2C  0xb100 0x1672     # 0.6931472
:SQC1  0x9700 0xeb14     # 0.59016206
:SQC2  0xd57f 0x56a9     # 0.41730759
#
#     Constants with Exponent of 1
#     Coefficient of first term ... Coefficent of Nth TERM
#     If all are < 1 constant 1 used to terminate
#

:SQC3   0x01 0x0B5 0x04 0x0F3    #CONSTANT:  1.41421356
        0x0FF 0x0AA 0x95 0x0BC   #CONSTANT: -0.3331738
        0x7E 0x0CA 0x0D5 0x20    #CONSTANT:  0.1980787
        0x0FE 0x87 0x82 0x0D6    #CONSTANT: -0.1323351
        0x7D 0x0A3 0x13 0x1C     #CONSTANT:  0.07962632
        0x0FC 0x89 0x0A6 0x0B8   #CONSTANT: -0.03360627
:ATNCO  0x79 0x0DF 0x3A 0x9E     #CONSTANT:  0.006812411
#
:ALFP  0x01 0x0C9 0x0F 0x0D7    #CONSTANT:  1.570796
        0x80 0x0A5 0x5D 0x0DE    #CONSTANT: -0.64596371
        0x7D 0x0A3 0x34 0x55     #CONSTANT:  0.076589679
        0x0F9 0x99 0x38 0x60     #CONSTANT: -0.0046737656
:SINCO  0x74 0x9E 0x0D7 0x0B6    #CONSTANT:  0.00015148419
#
:ONE    0x001 0x080
:NULLI  0x00 0x00              #CONSTANT:  1.0
        0x00 0x0FF 0x0FE 0x0C1   #CONSTANT:  0.99998103
        0x0FF 0x0FF 0x0BA 0x0B0  #CONSTANT: -0.4994712
        0x7F 0x0A8 0x0E 0x2B     #CONSTANT:  0.3282331
        0x0FE 0x0E7 0x4B 0x55    #CONSTANT: -0.2258733
        0x7E 0x89 0x0DE 0x0E3    #CONSTANT:  0.134693
        0x0FC 0x0E1 0x0C5 0x078  #CONSTANT: -0.05511996
:LNCO   0x7A 0x0B0 0x3F 0x0AE    #CONSTANT:  0.01075737
#
:LN2E   0x001 0x0B8 0x0AA 0x03B  #CONSTANT:  1.44269504
        0x000 0x0B1 0x06F 0x0E6  #C=.69311397
        0x07E 0x0F6 0x02F 0x070  #C=.24041548
        0x07C 0x0E1 0x0C2 0x0AE  #C=.05511732
        0x07A 0x0A0 0x0BB 0x07E  #C=.00981033
:EXPCO  0x077 0x0CA 0x009 0x0CB  #C=.00154143
#
:LNC    0x07F 0x0DE 0x05B 0x0D0     #C=LOG BASE 10 OF E
:READY
        0x0FD
        "READY\0"
:STOPM
        0x0FD
        "STOP AT LINE " b0x0FE
ERRMS:  " ERROR IN LINE " b0x0FE
#
# Jump Tables for Commands.

:JMPTB
              "LIST\0"
              LIST
              "RUN\0"
              RUNCM
              "XEQ\0"
              XEQ
              "NEW\0"
              NEW
              "CON\0"
              CONTI
              "TAPE\0"
              TAPE
              "SAVE\0"
              SAVE
:KEYL         "KEY\0"
              KEY
              "FRE\0"
              FREE
              "IF\0"
              IFSTM
              "READ\0"
              READ
              "RESTORE\0"
              RESTO
:DATAL        "DATA\0"
              RUN
              "FOR\0"
              FOR
:NEXTL        "NEXT\0"
              NEXT
:GOSB:        "GOSUB\0"
              GOSUB
              "RETURN\0"
              RETUR
              "INPUT\0"
              INPUT
              "PRINT\0"
              PRINT
:GOTOL        "GO"
:TOLIT        "TO\0"
              GOTO
              "LET\0"
              LET
              "STOP\0"
              STOP
              "END\0"
              ENDIT
              "REM\0"
              RUN
              "!\0"
              RUN
              "?\0"
              PRINT
              "RANDOMIZE\0"
              RANDO
              "ON\0"
              ON
              "OUT\0"
              OUTP
              "DIM\0"
              DIM
              "CHANGE\0"
              CHANG
:DEFLI        "DEF"
:FNLIT        "FN\0"
              RUN
              "BYE\0"
              BOOT
              "POKE\0"
              POKE
              "CALL\0"
              JUMP
              "EDIT\0"
              FIX
              "CLOAD\0"
              CLOAD
              "CSAVE\0"
              CSAVE
              "BAUD\0"
              BAUD
              0       ;END OF TABLE
#
# Here are the main Basic Variabls
#
:BZERO      # Most of these originally are Byte storage, but words or more natural for ex716
:FORNE      # For Loop Entries up to 8 nested For's
      0
      $$$0 $$$0 $$$0 $$$0 $$$0 $$$0 $$$0 $$$0  # 32 bytes
      $$$0 $$$0 $$$0 $$$0 $$$0 $$$0 $$$0 $$$0  # 64
      $$$0 $$$0 $$$0 $$$0 $$$0 $$$0 $$$0 $$$0  # 96
      $$$0 $$$0 $$$0 $$$0                      # 112
:TAPES 0          # Tape, DIM and Out Switches
:DIMSW 0
:OUTSW 0          # Output Switch
:ILSW  0          # Input Line Switch
:RUNSW 0          # RUN Switch
:EDSW  0          # Mode Switch
:EZERO            # Marks end of initilizable varaibles
#
# More variables, these a preserved from one run to the next in a session.
# Unlize Z80 we have some extra work to define storage by 'byte' size. So filling the space with junk data.
:LINEN:  0 0 b0   # 5 Bytes
# IMMEDIATE COMMAND STORAGE AREA 82 bytes
:IMMED  "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF00"
# INPUT/OUTPUT Buffer 82 bytes
:IOBUF "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF00"
# String Buffer Area 256 bytes
:STRIN "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
       "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
       "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"
       "0123456789ABCDEF"
:OUTA   0 b0        # 3 bytes *** FILLED IN AT RUN TIME
:INDX   0           # HOLDS VARIABLE NAME OF FOR/NEXT
:REL    0           # HOLDS THE RELATION IN AN IF STMT
:IFTYP  0           # HOLDS TYPE CODE OF LEFT SIDE
:TVAR:1 0 0         # TEMP STORAGE
:TVAR2  0 0         # DITTO
:TEMP1  0 0         # TEMP STORAGE FOR FUNCTIONS
:TEMP2  0 0 
:TEMP3  0 0 
:TEMP4  0 0 
:TEMP5  0 0 
:TEMP6  0 0 
:TEMP7  0 0
:LINEL  0           # HOLDS MIN LINE NUMBER IN LIST
:LINEH  0           # HOLDS MAX LINE NUMBER IN LIST
:PROMP  0           # HOLDS PROMPT CHAR
:EXPRS  0           # HOLDS ADDR OF EXPRESSION
:ADDR1  0           # HOLDS TEMP ADDRESS
:ADDR2  0           # HOLDS TEMP ADDRESS
:ADDR3  0           # HOLDS STMT ADD DURING EXPR EVAL
:FACC   0 0
:FTEMP  0 0 0 0 0 0
:PARCT: 0
:SPCTR: 0
:CMACT  0
:FNARG  0 0         # SYMBOLIC ARG & ADDRESS
:STMT   0           # HOLDS ADDR OF CURRENT STATEMENT
:ENDLI  0           # HOLDS ADDR OF MULTI STMT PTR
:MULTI  0           # SWITCH 0=NO, 1=MULTI STMT LINE
:DEXP   0
:COLUM  0           # CURRENT TTY COLUMN
:RNDX  0           # RANDOM VARIABLE STORAGE
:RNDY  0           # THE RND<X>,TRND<X>,AND RNDSW
:RNDZ  0           # MUST BE KEPT IN ORDER
:RNDS  0
:TRNDX 0
:TRNDY 0
:TRNDZ 0
:TRNDS 0
:RNDSW 0
:FNMOD  0           # SWITCH, 0=NOT, <>0 = IN DEF FN
:LINE  0           # HOLD ADD OF PREV LINE NUM
:STACK  0           # HOLDS ADDR OF START OF RETURN STACK
:PRSW  0           # ON=PRINT ENDED WITH , OR ;
:NS  0           # HOLDS LAST TYPE (NUMERIC/STRING)
:DATAP  0           # ADDRESS OF CURRENT DATA STMT
:DATAB  0           # ADDRESS OF DATA POOL
:PROGE  0           # ADDRESS OF PROGRAM END
:CHARPRT 0          # Space for a single character printout
