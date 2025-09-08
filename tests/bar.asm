I common.mc
# Example, Loop though data table until end of table marked with -1
# Find the largest value and return it
#
. 0x1000           # Start at address 1000h
:START
  @PUSH DataTable
  @POPI Index
  @PUSH 0
  @POPI MaxFound
  :LoopTop
     @PUSHII Index
     @CMP -1
     @JMPZ EndLoop
     @CMPI MaxFound
     @JMPN ReturnFromIsLarger
     @JMP IsLarger
     :ReturnFromIsLarger
     @PUSHI Index
     @ADD 2
     @POPI Index
     @JMP LoopTop
   :IsLarger
     @POPI MaxFound
     @JMP ReturnFromIsLarger
   :EndLoop
     @PRT "Largest value found:"
     @PRTI MaxFound
  @END
:Index 0
:MaxFound 0
:DataTable
17 23 14 98 45 -1
