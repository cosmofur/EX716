! MemmngDef
M MemmngDef 1
#
# Just to be Clear, this set of tools is NOT to provide the direct equivilent as C's malloc 
# memory managment. But rather provide some low level tools to manage a block of memory in such
# a way that an applcation can request and free a limited block of memory for efficent reuse.
# 
# The work flow on this is:
#
#  1) Call MemInit(Low, High, BlockSize) 
#         Low and High are a range of memory that will be managed, and BlockSize 
#         is used to split that range into reservable blocks. All requests for memory
#         will always round up to the nearset blocksize and the maximume total blocks
#         is hardwired to 64 blocks. If you were manageing the entire 64K memory
#         You would use a Block size of 1024 or 1K. 
#  2) Call MemAlloc(Bytes) will reuturn the address somewhere between Low and High that is 
#          at least Bytes long. The acutual space reserveed will be rounded up to the next
#          block boundry. 
#  3) Call MemFree(Address) will mark a block or group of blocks, of memory as availabe for reuse.
#          It does not erase the memory or zero it. THe Address given MUST be the address returned
#          by a previous MemAlloc and as long as there no error, it will know the right number of
#          blocks to relase, based on the original Alloc call. 
#
#  4) The MemSetBit and MemResetBit are available to mark 'protected' blocks of memory.
#          Going back to an earlier example. If you MemInit the whole 64K memory, you 
#          want to also use MemSetBit to mark the Killobytes where program code is to 
#          protect them from being overwritten. Of Course it would be simpler to just make
#          sure code does't fall in the Low to High range, which is something you can do
#          with the assemblers normal lable and memory operations. See testmem.asm for example.
#
# Note there is no 'resize' call, but as long as your carefull AND there is sufficent storage available
# you can possible resize an existing block. You can get away with this because there no interupts so
# you can be confident that no other process is going to start using the 'Free'ed memory before you
# resize it. 
# So to resize.
#      1) Keep a record of the origina address and size of the memory you were using.
#      2) Do a MemFree, Followed by a MemAlloc for the new size you want.
#      3) IF the new returned address is the same as the original, your golden. Your data is already there.
#      4) If the new address is diffrent, do a block copy from othe old address to the new address right away.
#      Make sure you check for a return of zero from the MemAlloc which means there not enough storage left
#      to have both copies in memory at the same time. Basicly you'de have to build a 'defrager' 
L div.ld
L mul.ld
#
# This is a very basic Memory Manager, it provides
#
# MemAlloc
G MemInit
G MemAlloc
G MemFree
G MemSetBit
G MemResetBit
# Local Storage
:MemReturn 0
:MemBlockSize 0
:MemHigh 0
:MemLow 0
:MemBlockMax 0
:MemTable      # 64 bits mask table
 0 0 0 0
# MemUsedTable records how many blocks a given Alloc reserved.
# So when we call MemFree we know how many to release.
:MemUsedTable
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
:Index1 0
:Index2 0
:Index3 0
:R1 0
:R2 0
:LargeEnough 0
:Match 0
:MASK 0
#
# MemGetBit(BitNum) return 0 or 1 if bit in table is set
:MemGetBit
@POPI MGReturn
@DUP
@RTR @RTR @RTR @RTR      # Div BitNum/16 to get which Word
@POPI MGWord
@AND 0x000f              # Mask BitNum to get 0-15 bit in word
@POPI MGBitIn
@MA2V 1 MGMASK
@PUSHI MGMASK
:Break1
@ForIA2V MGIndex1 0 MGBitIn
   @RTL
@Next MGIndex1
@POPI MGMASK 
@PUSHI MGWord
@ADD MemTable
@PUSHS                   # This gets the word with the bit in it.
@ANDI MGMASK
@IF_NOTZERO      # Answer on stack, but it not zero, normalize it to one.
   @POPNULL
   @PUSH 1
@ENDIF
@PUSHI MGReturn
@RET
:MGReturn 0
:MGIndex1 0
:MGWord 0
:MGBitIn 0
:MGMASK 0
#
# MemSetBit(BitIn)    Sets the Bit in MemTable, preserving the original word values
:MemSetBit
@POPI MSReturn
@POPI MSBitIn
@PUSHI MSBitIn
@RTR @RTR @RTR @RTR     # BinIn/16 gets which Word
@POPI MSWord
@PUSHI MSBitIn @AND 0x000f       # Bit in word 0-15
@POPI MSBitPos
@MA2V 1 MSMASK
@PUSHI MSMASK
@ForIA2V MSIndex 0 MSBitPos
   @RTL                          # Shift Mask over MSBitPos number of bits
@Next MSIndex
@POPI MSMASK
@PUSHI MSWord
@ADD MemTable
@DUP                             # Will need it twice
@PUSHS                           # Gets value that currently there.
@ORI MSMASK
@SWP
@POPS
@PUSHI MSReturn
@RET
#
# MemResetBit, reverse of SetBit

#
# MemResetBit(BitIn)    Un-Sets the Bit in MemTable, preserving the original word values
:MemResetBit
@POPI MSReturn
@POPI MSBitIn
@PUSHI MSBitIn
@RTR @RTR @RTR @RTR     # BinIn/16 gets which Word
@POPI MSWord
@PUSHI MSBitIn @AND 0x000f       # Bit in word 0-15
@POPI MSBitPos
@MA2V 1 MSMASK
@PUSHI MSMASK
@ForIA2V MSIndex 0 MSBitPos
   @RTL                          # Shift Mask over MSBitPos number of bits
@Next MSIndex
@INV                             # We reverse the bits (and make sure we have 16)
@POPI MSMASK
@PUSHI MSWord
@ADD MemTable
@DUP                             # Will need it twice
@PUSHS                           # Gets value that currently there.
@ANDI MSMASK                     # Mask erases the selected bit.
@SWP
@POPS
@PUSHI MSReturn
@RET
#
# Common storage for set/reset bits
:MSReturn 0
:MSBitIn 0
:MSBitPos 0
:MSWord 0
:MSIndex 0
:MSMASK 0



#
# MemInit specifies the Low, High and Units storage limits of the Memory to be managed.
:MemInit
@POPI MemReturn
@POPI MemBlockSize
@POPI MemHigh
@POPI MemLow
# Zero out the current MemTable
@PUSHI MemHigh
@SUBI MemLow
@PUSHI MemBlockSize
@CALL DIV
@POPI MemBlockMax
@POPI R2
@PUSH 64
@IF_LT_V MemBlockMax
   @PRT "Error: Memory Limits will not allow that much memory to be divided into more than 64 blocks.\nUse larger blocks, or smaller memory range\n"
   @END
@ENDIF
@POPNULL
@ForIA2B Index1 0 4  # Zero out the 64 bits of the MemTable
   @PUSH 0
   @PUSHI Index1 @RTL   # Words not bytes. 
   @ADD MemTable
   @POPS
@Next Index1
@PUSHI MemReturn
@RET
#
# MemAlloc(Byte_Count) Will allocate 1 full block for each Byte_Count/MemBlockSize
:MemAlloc
@POPI MemReturn
@POPI R1
@PRTLN "Mask Table" @PRTBINI MemTable @PRTNL
@PUSHI R1 @PUSHI MemBlockSize
@CALL DIV
@ADD 1
@POPI R2    # R2 is the number of Blocks will this take up.
@POPNULL  # We don't care about remainder for this purpose.
@MA2V 0 Index1
@PUSHI Index1              #1
@WHILE_LT_V MemBlockMax    #1
    @CALL MemGetBit       # gets the Index1'th bit in the memory block starting at MemTable 1
    @IF_ZERO
       @MA2V 1 LargeEnough   # If we need multiple blocks they need to be adjacent.
       @MV2V Index1 Match
       @ForIA2V Index2 0 R2     # if Number of blocked needed is already zero then no need to test furter
          @INCI Index1
          @PUSHI Index1         # 2
          @CALL MemGetBit       # 1
          @IF_NOTZERO
             @POPNULL
             @MA2V 0 LargeEnough
             @JMP BreakFor
          @ENDIF
          @POPNULL
       @Next Index2
       :BreakFor
       @PUSHI LargeEnough       # 2
       @IF_NOTZERO              # Means we found our match.
            @POPNULL @POPNULL        # Pop off IF, IF and While
            @ForIV2V Index2 Match Index1
                @PUSHI Index2
                @CALL MemSetBit
            @Next Index2
            # Update MemUsedTable to number of blocks used
            @PUSHI Match       # Get the address in the MemUsedTable
            @ADD MemUsedTable
            @DUP               # Fetch, Modify, POP same address
            @PUSHS
            @AND 0xff00        # R2 <= 64 so just use lower byte
            @ADDI R2
            @SWP               # Put value behind address
            @POPS              
            # Now return the address where the new block starts.            
            @PUSHI Match
            @PUSHI MemBlockSize
            @CALL MUL
            @ADDI MemLow
            @PUSHI MemReturn
            @RET                                  # Here is 'good' exit.
       @ENDIF
       @POPNULL
    @ELSE
       @INCI Index1
    @ENDIF
    @POPNULL
    @PUSHI Index1
@ENDWHILE
# If we get here, then we never found enough memory. Return 0 for insufficent memory
@POPNULL
@PUSH 0
@PUSHI MemReturn
@RET
#
# The Counter of the Alloc functino is the Free Function.
# This will free the block(s) of memory used by a previous call to Alloc
# and make it available again for reuse.
# MemFree(address) Address is the value returned by previous Alloc
:MemFree
@POPI MemReturn
@POPI R1             # R1 is address where alloced memory started
@PUSHI R1
@SUBI MemLow
@PUSHI MemBlockSize
@CALL DIV            # This should return the offset in the arrays where meta data is stored.
@POPI R2             # R2 is the index in the MemStoreage arrays
@PUSHI R2
@ADD MemUsedTable
@PUSHS
@AND 0x00ff          # We only care about the lower byte.
@POPI Match          # This is number of blocks allocated
@ForIA2V Index1 0 Match
   @PUSHI R2
   @CALL MemResetBit
   @INCI R2
@Next Index1
@PUSHI MemReturn
@RET

ENDBLOCK
