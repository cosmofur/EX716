# Project Euler sample projects
# See the website for Projet Euler for find ideas for simple test programs:
#
#
# Even Fibonacci numbers
# Submit
# Problem 2
# Each new term in the Fibonacci sequence is generated by adding the previous two terms. By starting with 1 and 2, the first 10 terms will be:

# 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, ...

# By considering the terms in the Fibonacci sequence whose values do not exceed four million, find the sum of the even-valued terms.

# Have to use the 32bit math library again, as we can't reach 4 million with 16 bits.
#
I common.mc
L lmath.ld

# First logic of Fabonacci Series is
#  A,B,OUT,Idx = 0,1,0,2
#  While Idx < 4,000,0000
#    OUT=A+B
#    A=B
#    B=OUT
#    Idx++
#
# Our 32b math library provides following for refrence:
# ADD32(^A,^B,^Result) SUB32, AND32, OR32
# CMP32(^A,^B):int16(-1,0,1) 
# RTR32(^A,^Result), RTL32, INV32
#
# Utility:
# COPY32VV Ptr1 Ptr2, COPY32VIV [Ptr1] Ptr
# MOVE32AV $$$### Ptr1
# INT2LONG LWptr1 LWptr2
# INT2LONGI [SWPtr1] LWPtr1
# LONG2INT LWptr1 SWPtr1
#
# Storage all 32 bit values
:Aptr $$$0
:Bptr $$$0
:Outptr $$$0
:IdxPtr $$$0
:SumPtr $$$0
:One32 $$$1
:ResultPtr $$$0
:FourMil $$$4000000
#
#
:main . main
@MOVE32AV $$$0 Aptr   # A,B,OUT,Idx=0,1,0,2
@MOVE32AV $$$1 Bptr
@MOVE32AV $$$0 Outptr
@MOVE32AV $$$2 IdxPtr
#
:MainLoop
   @PUSH FourMil
   @PUSH Outptr
   @CALL CMP32    # Returns on stack -1(IdxPtr<FM) 0(Idx==FM) +1(IdxPtr>FM)
   @CMP 1
   @POPNULL
   @JMPZ EndLoop
   @PUSH Aptr @PUSH Bptr @PUSH Outptr  # OUT=A+B
   @CALL ADD32
   @COPY32VV Bptr Aptr     # A=B
   @COPY32VV Outptr Bptr   # B=OUTptr
   @PUSH One32 @PUSH IdxPtr @PUSH IdxPtr
   @CALL ADD32
   #
   # Now see if Out is Ever or Odd and add it to the Sum if even
   @PUSHI Outptr   # Only considering Lowerword bit 1
   @AND 0x1
   @CMP 1
   @POPNULL
   @JMPZ NotEven
      @PUSH SumPtr @PUSH Outptr @PUSH SumPtr
      @CALL ADD32
   :NotEven
   @JMP MainLoop
:EndLoop
@PRT "Result is: " @PRT32I SumPtr
@END

   
