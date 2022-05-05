# Provides a simple 'printf' "like"
# Uses ^ rathan than % or \ as the escape code
# Push values onto stack in reverse order they appear in the format string
#   ^d  == print value at pushed 'label'
#   ^i  == print value at the mem[pushed 'label']
#   ^b  == print binary at pushed 'label'
#   ^e  == print binary at mem[pushed 'label']
#   ^n  acts as linefeed
#   ^s  == print the string starting at mem[push 'label']
# Use 'call PrintSF' after setting up stack, last item pushed should be pointer to format string, zero terminated.
I common.mc
@JMP __Skip_Lib
G PrintSF


# Sub Print Stack
:__ReturnPS
0
:__StrPtr
0
:__Char
b0
:__Char2
b0
b0
:__Unused
0
:__ValueHold
0
b0
#  Push Values, then Push PTR to Format String
:PrintSF
@POPI __ReturnPS
@POPI __StrPtr
:__StrLoop
@PUSHII __StrPtr @AND 0x00ff @POPI __Char     # Char=mem[Strptr]
@PUSH 0 @CMPI __Char @POPI __Unused           # Exit look when Char == 0
@JMPZ __EndLoop
@PUSH "^\0" @CMPI __Char @POPI __Unused         # If Char == "^" then StartEscape
@JMPZ __StartEscape
@PUSH 1 @CAST __Char @POPI __Unused          # Print Char
:__ContinueLoop                             # Switch
@PUSHI __StrPtr @ADD 1 @POPI __StrPtr
@JMP __StrLoop
:__StartEscape
@PUSHI __StrPtr @ADD 1 @POPI __StrPtr         # StrPtr ++
@PUSHII __StrPtr @AND 0x00ff @POPI __Char     # Char=mem[StrPtr]
@PUSH "^\0" b0 @CMPI __Char @POPI __Unused         # If "^^" then output "^"
@JMPZ __TwoPercent
@PUSH "d\0" b0 @CMPI __Char @POPI __Unused         # If ^d then output int as if passed by value
@JMPZ __IntByValue
@PUSH "i\0" b0 @CMPI __Char @POPI __Unused         # if ^i then output in as if passed by refrence
@JMPZ __IntByRef
@PUSH "b\0" b0 @CMPI __Char @POPI __Unused         # if ^b then output as binary if passed by value
@JMPZ __BinByValue
@PUSH "e\0" b0 @CMPI __Char @POPI __Unused         # if ^e then output as binary if passed by refrence
@JMPZ __BinByRef
@PUSH "n\0" b0 @CMPI __Char @POPI __Unused         # if ^n then linefeed.
@JMPZ __LineFeed
@PUSH "s\0" b0 @CMPI __Char @POPI __Unused         # if ^s then string print by refrence.
@JMPZ __PrintString
@PRT "Error: ("
@PUSH 1 @CAST __Char
@PRTLN ") not understood as valid ^ code. Try ^^ ^d(val) ^i(ref) ^b(val) ^e(ref) ^s(ref) ^n"
@END
:__TwoPercent
@PRT "^" @JMP __ContinueLoop
:__IntByValue
@POPI __ValueHold @PUSH 3 @CAST __ValueHold @POPI __Unused @JMP __ContinueLoop
:__IntByRef
@POPII __ValueHold @PUSH 3 @CAST __ValueHold @POPI __Unused @JMP __ContinueLoop
:__BinByValue
@POPI __ValueHold @PUSH 5 @CAST __ValueHold @POPI __Unused @JMP __ContinueLoop
:__BinByRef
@POPII __ValueHold @PUSH 5 @CAST __ValueHold @POPI __Unused @JMP __ContinueLoop
:__LineFeed
@PRTNL @JMP __ContinueLoop
b0 b0
:__PrintString
@POPI $__StrPtrHold
@PUSH 1
b29
:__StrPtrHold
0
@POPI __Unused @JMP __ContinueLoop

:__EndLoop
@PUSHI __ReturnPS
@RET
:__SkipLib
