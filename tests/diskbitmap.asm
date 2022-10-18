# Bitmap is a required database for managing the usable blocks of the Disk OS
#
# Our target is a disk with 256 byte blocks, and addressd by a 16b word, allowing a total of 16MB of storage
#
# The Bitmap markes for each bit in the mask maps to a 256 byte block on the disk.
#
# The required bitmap tools are to address which bit in the mask corrosponds to which block, both ways.
# We also need a way to find groups of unused bits for when we copy files of known length.
# Files of unknown length will have to deal with extents and some luck to find suffience space to grow.
#
# We also need to consider compute cost to find these blocks of unused bitmap blocks.
# If we make our search for the perfect fit too deep, then the ability to copy mediam sized files
# might spend more time anaylizing the bitmap than makes sense.
#
#
# There are 32 'blocks' at a fixed locaton of the disk to store the full 8K of the BitMap.
# 8K is too much memory to sacrafice, so we will not be keeping more than 1 block of the BM
# in memory at a time. But as we will be distinusing from general purpose Disk Space Blocks and
# BM blocks, we'll use some more distinct terminology to identify what we want.
#
# BMSector or BMS is an b16 interger between 0 and 31 that corresponds to the index in blocks the BitMap takes up.
# To read a BMSector into memory, we need to add 3 to the BMSector (as first 3 (0-2) blocks are reserved)
#
# DiskBlock or DKB is an integer betweek 35 and 0xfff which identify a given 256 but block on the disk
#
# BMBit is the b16 integer between 0 and 255 that identifies the exact bit in a given DMS that maps to an exact DKB
#
# So the Block number DKB = BMS * 2048 + BMBit
#
# Also another bit of math we should remember, multiplication and division by factors of 2 can be done with
# shifts, and multiplicaiton and division by 256 can be done by moving LSB and MSB in 16b right or left + zero padding

# So Services needed.
#
# GetBMbit(16b: DKB)   : Returns just the bit offsent in the BMS
# GetBMS(16b: DKB)      : Returns just the BMS sector for give
# SetBMS(DKB,value)     : Sets BMS for DKB to value
# FindFreeBit(BMS,Width): Starting with BMS returns the BMbit offset to first group with sufficent space)
#                         We set Width to have a max size of 16 (1-16) because we'll be using bitwise
#                         operations and are trying to avoid bit strings that can't fit in a word. 
#
# Some things to consider. The Bitmap uses 1's and 0's, but does 1 mean in use with 0 meaning free?
#
# Lets consider the search for a example space of 1KB of disk space, or 4 free blocks.
# Our possible outputs are 0-255 if there is a 4 bit free spot in the first BMS or add 256 for each BMS
# forwad we need to search. The Max value value could be, 31*256+252 (top most three bits and only if every
# spot is full starting from a BMS of zero 0. This will always remain lower than 8192 (0x2000) so return
# values over that indicate and error. (Such as no such block available)
#
# Getting back to the 0's or 1's meaning available question. Ends up which is easier to match
#  ...111... vs ...000...
# If we go with '1's meaning 'free space' then we can use the algorthem of:
#  Fill Search String 1*Width 1 == 0001, 2 == 0011, 3 = 0111, 4 = 1111
#  MATCH=0xffff
#  BMSCurrent=Entered_BMS
#  While No Match and BMSCurrent != (32 + 3)
#  Read to Buffer block BMSCurrent
#  BMSCurrent ++
#  MultiBlockOffset=0
#     We are searching the buffer at word steps. 
#  For i 0  to 127
#     for j  Width to 15
#        SearchBits = 1*Width (one way 2^Windth - 1, or a 0 to Width loop of 1 or'ed with string RTL'd)
#        TestValue=Buffer[i] & 0xff
#        AND SearchBits & TestValue : if == SearchBits Then
#                          MATCH = MultiBlock + i*2 + (j & 0x1)  # We return Byte of match, not word.
#                           Return
#        RTL SearchBits
#  Return (result will be failure)
#        
#
#
# Sub GetBMBut(DKB)
:GetBMbit
@POPI GetBMbit.Return
@POPI GetBMbit.Width
@MC2M -1 GetBMbit.Match
