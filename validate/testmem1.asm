I common.mc
L memmng.ld
:Main 
@PUSH CodeBottom          # Low Water
@PUSH MemBottom           # High Water
@PUSH 256                 # Block Size
@CALL MemInit
@PUSH 700
@CALL MemAlloc
@POPI FirstMemBlock
@PRT "First Block Starts at: " @PRTHEXI FirstMemBlock @PRTNL
@PUSH 1500
@CALL MemAlloc
@POPI SecondMemBlock
@PRT "Second Block Starts at: " @PRTHEXI SecondMemBlock @PRTNL
@PUSH 3000
@CALL MemAlloc
@POPI ThirdMemBlock
@PRT "Third Block Starts at: " @PRTHEXI ThirdMemBlock @PRTNL
#
#
@PUSHI SecondMemBlock
@CALL MemFree
@PRT "Second Mem Block is free\n"
#
@PUSH 2000
@CALL MemAlloc
@POPI FourthMemBlock
@PRT "Fourth Block Starts at: " @PRTHEXI FourthMemBlock @PRTNL
@PUSH 900
@CALL MemAlloc
@POPI SecondMemBlock
@PRT "NEW Second Block Starts at: " @PRTHEXI SecondMemBlock @PRTNL

@END
:FirstMemBlock 0
:SecondMemBlock 0
:ThirdMemBlock 0
:FourthMemBlock
:CodeBottom
. CodeBottom+15000
:MemBottom
. Main
