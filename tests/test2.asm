I common.mc
@PUSH 0x100
@SUB 0x200
@PRTTOP
@END

@PUSH 0x7ffe
@PUSH 2
@ADDS     # Expect Overflow
@POPNULL
@PUSH 0xffff
@PUSH 0xffff
@ADDS     # Expect Overflow
@POPNULL
@PUSH 0xffff
@PUSH 0x7fff
@ADDS     # No further overflows expected.
@POPNULL
@PUSH 0x7fff
@PUSH 0xffff
@ADDS
@POPNULL
@PUSH 0x7ffe
@PUSH 0xfffe
@ADDS
@POPNULL
@END
:TwoHundred 0x200
:Fifty 0x50
:OneHundred 0x100
:one 1
:largepos 32767
:largeneg -32768
:negone -1

