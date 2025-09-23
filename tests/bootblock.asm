# The Purpse of Boot block is the idenitfy the mininal instructions needed to read in a
# the startsector form a disk, fetch the Boot sector, and jump to that Boot sectors start
# address
#
# Fetch the offsets from the ssfs-ds file
I ssfsds.asm
#
# Rather than load the entire common.mc file we'll just re-create the instructions we need here.
=CastSelectDisk 20
=CastSeekDisk 21
=CastSeekDiskI 25
=PollReadSector 22
=PollReadSectorI 26
# Raw Instructions
=PUSH 1
=CAST 42
=POLL 43
=POPNULL 6
=JMP 39
=dBuffer 0x400
#
M PUSH $$PUSH %1
M CAST $$CAST %1
M POLL $$POLL %1
M POPNULL $$POPNULL
M JMP $$JMP
M DISKSEL @PUSH CastSelectDisk @CAST %1 # @POPNULL
M DISKSEEK @PUSH CastSeekDisk @CAST %1 # @POPNULL
M DISKSEEKI @PUSH CastSeekDiskI @CAST %1 # @POPNULL
M DISKWRITE @PUSH CastWriteSector @CAST %1 # @POPNULL
M DISKREAD @PUSH PollReadSector @POLL %1 # @POPNULL
M DISKREADI @PUSH PollReadSectorI @POLL %1 # @POPNULL

#
# Nothing above this has consumed any actual memory or code space.
#
# Set our Entry point at 0x100 or 256th byte
. 0x100
@DISKSEL 0                # Select Disk 0 (Change to your boot disk)
@DISKSEEK 0               # First block
@DISKREAD dBuffer         # 0x400 to 0x600 will be our 512 byte buffer
# If we where not trying to save every single byte, we could test to make sure SSTypeCode is 1 which means bootable.
# but we're being increadably sparce with our memory use, so skip the test, and just crash if we're wrong.
@DISKSEEKI dBuffer+SSofsBootSector   # At that memory location will be the real sector of boot code.
@DISKREAD dBuffer                      # Overlay the old buffer with the new code
# @JMP dBuffer
#
# When assembled the program is 19 in 16bit hex words
# 0114 002a 0000 0601 1500 2a00 0006 0116
# 002b 0004 0601 1900 2a08 0406 0116 002b
# 0004 0627 0004

# 0100:    PUSH P1:0014 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:39 M.DISKSEL M.PUSH
# 0103:    CAST P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:39 M.CAST
# 0106: POPNULL P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:39 M.POPNULL
# 0107:    PUSH P1:0015 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:40 M.DISKSEEK M.PUSH
# 010a:    CAST P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:40 M.CAST
# 010d: POPNULL P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:40 M.POPNULL
# 010e:    PUSH P1:0016 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:41 M.DISKREAD M.PUSH
# 0111:    POLL P1:0400 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:41 dBuffer M.POLL
# 0114: POPNULL P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:41 M.POPNULL
# 0115:    PUSH P1:0019 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:44 M.DISKSEEKI M.PUSH
# 0118:    CAST P1:0408 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:44 M.CAST
# 011b: POPNULL P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:44 M.POPNULL
# 011c:    PUSH P1:0016 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:45 M.DISKREAD M.PUSH
# 011f:    POLL P1:0400 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:45 dBuffer M.POLL
# 0122: POPNULL P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:45 M.POPNULL
# 0123:     JMP P1:0400 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:46 dBuffer M.JMP
#
# One can imagine wire wrapping this as a handmade 'rom'
# One could also save a few bytes by not bothring with the POPNULL's and have the next bootloader code
# deal with the junk on the stack.
# Also if your confident that memory starts zero'ed out, then that last JMP is un-needed as a chain of NOPs will lead to the code.
#
# The result would look like:
#
# 0114 002a 0000 0115 002a 0000 0116 00b
# 0004 0119 002a 0804 0116 002b 0004
# 0100:    PUSH P1:0014 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:39 M.DISKSEL M.PUSH
# 0103:    CAST P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:39 M.CAST
# 0106:    PUSH P1:0015 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:40 M.DISKSEEK M.PUSH
# 0109:    CAST P1:0000 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:40 M.CAST
# 010c:    PUSH P1:0016 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:41 M.DISKREAD M.PUSH
# 010f:    POLL P1:0400 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:41 dBuffer M.POLL
# 0112:    PUSH P1:0019 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:44 M.DISKSEEKI M.PUSH
# 0115:    CAST P1:0408 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:44 M.CAST
# 0118:    PUSH P1:0016 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:45 M.DISKREAD M.PUSH
# 011b:    POLL P1:0400 [I]:0000 [II]:0000 TOS[ffff,ffff] Z0 N0 C0 O0 SS(0) # bootblock.asm:45 dBuffer M.POLL



