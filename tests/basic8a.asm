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
:TSTC
    @PUSHII HL @AND 0xff
    @WHILE_NE_A " \0"
       @POPNULL
       @INCI HL
       @PUSHII HL @AND 0xff       
    @ENDWHILE
    @POPNULL
    @RET
#
#
# RST2 Compare Strings, [HL] to [DE], ignore spaces
:RST2
    @CALL RST1   # Skip spaces at head of string at HL
    
