
I common.mc

. 0x1000
:START
  @PUSH 10           # Number of values to generate
  @POPI Count
  @PUSH FibTable
  @POPI Index

  @PUSH 0
  @POPI Prev
  @PUSH 1
  @POPI Curr

  :LoopTop
    @PUSHI Count
    @CMP 0
    @JMPZ Done

    @PUSHI Curr
    @POPII Index        # Store current value to table
    @PUSHI Index
    @ADD 2
    @POPI Index         # Index += 1 (word address)

    @PUSHI Curr
    @PUSHI Prev
    @ADDS
    @POPI Temp          # Temp = Curr + Prev

    @PUSHI Curr
    @POPI Prev          # Prev = Curr
    @PUSHI Temp
    @POPI Curr          # Curr = Temp

    @PUSHI Count
    @SUB 1
    @POPI Count
    @JMP LoopTop

  :Done
    @PRT "Fibonacci Sequence:\n"
    @PUSH FibTable
    @POPI PrintIndex
    @PUSH 10
    @POPI PrintCount

  :PrintLoop
    @PUSHI PrintCount
    @CMP 0
    @JMPZ End

    @PUSHII PrintIndex
    @PRTTOP
    @PRT "\n"
    @POPNULL

    @PUSHI PrintIndex
    @ADD 2
    @POPI PrintIndex

    @PUSHI PrintCount
    @SUB 1
    @POPI PrintCount

    @JMP PrintLoop

  :End
@END

# Temporary storage variables
:Count        0
:Index        0
:Prev         0
:Curr         0
:Temp         0
:PrintIndex   0
:PrintCount   0

# Output table: space for 10 values
:FibTable
0 0 0 0 0 0 0 0 0 0
