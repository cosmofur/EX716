#
# Example program that acts as a mininal boot loader target.
#
# The first 256 byte block is the BootLoader info.
# Structure is byte 0-0xe is Ascii string begining with "BO" (for BOOT) rest is free form ID
# 16 bit words starting at 0x10 define how large the initial program is, where on it is
# Where in Memory it should start being loaded, and what the entry point of the program is.
# Word 0x18 is an optional 'parameter' value that is used to modify the behavior of the
# program. If its any constant other than zero, then that means no special parameters are needed.
# But if it is zero then they keyboard will wait for a 16b decimal number to be entered.
# No automait prompt is printer, but that can be part of what the free form text starting at 0xc0
# can be used for.
#
. 0    # We are going to use multiple dot '.' commands to control the Header formating
#      While this data is stoared at location 0 on block zero, the load memory will be 0x100
"BOOT Loader\n" b0
. 0xf b0        # Always null
. 0x10 1        # Number of blocks
. 0x12 2        # Block Number to start reading from.
. 0x14 CompileEntry           # Where to start loading
. 0x16 CompileEntry           # Entry Point
. 0x18 0		# If this was zero, it would prompt for numeric option.
. 0xc0 			# This string is limited to what will fit between 0xc0 and 0xff
"This is optional Text\nEnter a Number:\n" b0	
#
# We reserve Disk Block 1 as a data block, but not available for programdata.
# So program data needs to start at block 2 (0x200 in memory)
# It is also not possible for the imported binary program to started execution at any location under 0x200
# because some of that space is used as part of the boot loader's own buffer.
#  
. 0x100
:DestEntryAddr
. 0x200
:CompileEntry
I common.mc
@PRT "Test Aval:"
@PRTS DestEntryAddr
@PRT " Entered number is: "
@PRTI 0x118      # 0x18 + 0x100

@END
. CompileEntry

