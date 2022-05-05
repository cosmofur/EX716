I common.mc
L mul.ld

# Do a tight loop for time tests

@PRTLN "Start"
@PUSH 4
@PUSH 25000
:TopLoop
# Put the test OPT Code here
#
@NOP
@NOP
@NOP
@NOP
@NOP
@NOP
@NOP
@NOP
@NOP
@NOP
@CMP 0
@JMPZ OuterLoop
@SUB 1
@JMP TopLoop
:OuterLoop
@PRT "Outer Loop "
@CMPS
@POPNULL
@JMPZ EndLoop
@SUB 1
@PUSH 25000
@JMP TopLoop
:EndLoop
@PRTLN "End"
@END
:Scratch 0
:Scratch2

