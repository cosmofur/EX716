# Basic Simple Disk IO
# Acts as 'boot' loader, reads in first 512 byte block of virual disk
# Validates that first Word is 'BO' then starts execution at word 128, words 2-127 are available as data
# Bytes 128-256 are overwritten by the first read block, but can be re-read leter for additional data
# Block 1 is then read starting at address 0x100, Entry point for any executable code should be 0x100
#
I common.mc
:Start
@DISKSEL 0           # Seek Disk block 0
@PUSH 22
@DISKREAD IHeader    # Read it into memory
@PUSH "BO"
@CMPI Header
@POPNULL
@JMPZ ContinueBoot
@PRTLN "Missing BOOT Header"
@END
:IHeader Header
:ContinueBoot
# Following constants are the fixed location of these value with offset of 0x80 
@PRTS Header       # Print the smaller Disk ID string followed by NL (Start of file + 0x80 offset)
@PRTNL
@PRTS LongHeader      # Now print the 'longer' string that maybe at 0xC0 + (offset 0x80)
@PUSH 0 @CMPI OptionVal @POPNULL
@JMPZ OptionPrompt        # If this field is zero, then read 16b number from keyboard. Use the 0x80 text as prompt.
@JMP LoadBlocks
:OptionPrompt
@READI OptionVal
:LoadBlocks
@DISKSEEKI BlockStart    # Move Disk to Block BlockStart
:LoadLoop
@DISKREAD ReadAddr       # Read block to memory
@PUSHI ReadAddr @ADD 0xFF @POPI ReadAddr     # Move memory ptr to next page
@DECI BlockCNT
@JNZ LoadLoop
@JMPI EntryAddr
. 0x100
:Header
. 0x110
:BlockCNT 0
:BlockStart 0
:ReadAddr 0
:EntryAddr 0
:OptionVal 0
. 0x1C0
:LongHeader
. 0x0

