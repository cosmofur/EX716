! __LIB_RANDOM_LOADED
M __LIB_RANDOM_LOADED 1
# ============================================================
# random.ld  -  Pseudo-Random Number Library for EX716
#
# Provides two families of random number generators:
#   1. Linear Congruential Generator (LCG)
#      - Compatible with the classic C standard library "rand()"
#   2. XORShift Generator
#      - A fast bit-twiddling RNG with good distribution
#
# Public Functions:
#   rnd16()        → 16-bit random number (LCG)
#   rndint(N)      → integer in range 0..N (LCG)
#   rndsetseed(N)  → set RNG seed
#   frnd16()       → 16-bit random number (XORShift)
#   frndint(N)     → integer in range 0..N (XORShift)
#
# Dependencies:
#   - softstack.ld : stack helpers
#   - lmath.ld     : 32-bit add/sub
#   - mul.ld       : 32-bit multiply
# ============================================================

I common.mc
I random.ref
# --- internal build markers ---
M SIZESINCECOMMENT random.ld


# --- External dependencies (not defined in this file) ---
#  DIVU
#  rnd16
#  frnd16


# --- public entry points ---
G rnd16
G rndint
G rndsetseed
G frnd16
G frndint

# ============================================================
# Internal State and Constants
# ============================================================

:Seed             # alias for the current 16-bit seed (used by XORShift)

:Seed32A 0 0      # 32-bit state for LCG RNG
:Modulus32 $$$1103515245   # LCG multiplier constant (ISO/ANSI C)
:MOffset32 $$$12345        # LCG increment constant

:Cval             # counter/perturbation value used in XORShift

=MINSEEDMASK 0x101   # used in rndsetseed to avoid zero seed

# ============================================================
# rnd16()  → 16-bit random number (Linear Congruential Generator)
#
# Algorithm:
#   Seed = (Seed * 1103515245 + 12345) mod 2^32
#   return upper 16 bits of Seed
#
# This is the same recurrence used in the C standard library "rand()".
#
# Notes:
# - Uses @LocalVar for scratch 32-bit storage (avoids global clutter).
# - Updates the global Seed32A value in-place.
# ============================================================
@FUNCTION rnd16
:rnd16
    # --- Allocate locals for 32-bit scratch space ---
    @LocalVar Scratch32A   01   # low word
    @LocalVar Scratch32AHW 02   # high word
    @LocalVar Scratch32B   03   # low word
    @LocalVar Scratch32BHW 04   # high word

    # --- Multiply Seed32A * Modulus32 (32-bit multiply) ---
    @Call32(VV) MUL32U Seed32A Modulus32
    @POP32I(V) Scratch32A

    # --- Add offset constant (32-bit add) ---
    @Call32(VV) ADD32U Scratch32A MOffset32
    @POP32I(V) Scratch32B

    # --- Copy result back into Seed32A (persistent RNG state) ---
    @M32V2V Scratch32B Seed32A

    # --- Return high 16 bits of Seed32A as random value ---
    @PUSHI Seed32A+2
    @SWP     # Reminder: the return address is still on the stack.
             # Before: [ ... , ReturnAddr ]
             # After PUSH: [ ... , ReturnAddr, Value ]
             # After SWP:  [ ... , Value, ReturnAddr ]
             # Now @RET will pop ReturnAddr and leave Value on the stack.    


    # --- Free local variables before returning ---
    @RestoreVar 04
    @RestoreVar 03
    @RestoreVar 02
    @RestoreVar 01
    @RET
ENDBLOCK


# ============================================================
# rndsetseed(N)  →  Set RNG seed (lower 16 bits)
#
# Input:
#   N = initial seed value (16-bit)
#
# Behavior:
#   - Stores N in the low word of Seed32A.
#   - Clears the high word of Seed32A.
#   - Runs one iteration of rnd16() to scramble the seed.
#   - Ensures the seed is never zero (LCG collapses if seed=0).
#     * If result is zero, OR with MINSEEDMASK (0x0101).
#     * Repeat rnd16() until nonzero.
#
# Notes:
#   MINSEEDMASK guarantees at least two bits are set,
#   preventing the generator from entering the "all zero" state.
# ============================================================
@FUNCTION rndsetseed
:rndsetseed
    @PUSHRETURN

    # --- Store user-provided seed in low 16 bits ---
    @POPI Seed32A
    @PUSH 0
    @POPI Seed32A+2        # high 16 bits cleared

    # --- Run one rnd16 to scramble initial seed ---
    @CALL rnd16

    # --- Loop until seed is nonzero ---
    @WHILE_ZERO
        @POPNULL            # discard rnd16 result
        # Force some nonzero bits with MINSEEDMASK
        @PUSHI Seed32A+2
        @PUSHI Seed32A
        @OR MINSEEDMASK
        @POPI Seed32A+2
        @POPI Seed32A
        # Try again
        @CALL rnd16
    @ENDWHILE

    # --- Clean up and return ---
    @POPNULL               # discard last rnd16 result
    @POPRETURN
    @RET
ENDBLOCK

# ============================================================
# rndint(N)  →  Random integer in range 0..N
#
# Input:
#   N = upper bound (inclusive) for the random result
#
# Behavior:
#   - Calls rnd16() to get a base 16-bit random value.
#   - For N = 2, 4, or 8: uses fast bit-masking.
#   - Otherwise: divides by N, returns the remainder.
# ============================================================
@FUNCTION rndint
:rndint
    @PUSHRETURN
    @LocalVar Range1 01

    # --- Store argument ---
    @POPI Range1

    # --- Generate base random number ---
    @CALL rnd16

    # --- Handle special cases with SWITCH ---
    @PUSHI Range1
    @SWITCH
        @CASE 2
            @POPNULL
            @AND 0x1
            @CBREAK
        @CASE 4
            @POPNULL
            @AND 0x3
            @CBREAK
        @CASE 8
            @POPNULL
            @AND 0x7
            @CBREAK
        @CDEFAULT
            @POPNULL
            @PUSHI Range1
            @CALL DIVU
            @POPNULL    # discard quotient, keep remainder
            @CBREAK
    @ENDCASE

    # --- Restore locals and return result ---
    @RestoreVar 01
    @POPRETURN
    @RET
ENDBLOCK
# ============================================================
# frndint(N)  →  Fast random integer in range 0..N
#
# Input:
#   N = upper bound (inclusive) for the random result
#
# Behavior:
#   - Calls frnd16() for a fast random 16-bit value.
#   - For N = 2, 4, or 8: uses fast bit-masking.
#   - Otherwise: divides by N, returns the remainder.
#
# Notes:
#   - XORShift is faster than the LCG (rnd16), but less traditional.
#   - Uses @LocalVar for range argument (no permanent storage).
# ============================================================
@FUNCTION frndint
:frndint
    @PUSHRETURN
    @LocalVar RIRange 01

    # --- Store argument ---
    @POPI RIRange

    # --- Generate base random number (XORShift) ---
    @CALL frnd16

    # --- Handle special cases with SWITCH ---
    @PUSHI RIRange
    @SWITCH
        @CASE 2
            @POPNULL
            @AND 0x1
            @CBREAK
        @CASE 4
            @POPNULL
            @AND 0x3
            @CBREAK
        @CASE 8
            @POPNULL
            @AND 0x7
            @CBREAK
        @CDEFAULT
            @POPNULL
            @PUSHI RIRange
            @CALL DIVU       # quotient, remainder
            @POPNULL         # discard quotient, keep remainder
            @CBREAK
    @ENDCASE

    # --- Restore locals and return result ---
    @RestoreVar 01
    @POPRETURN
    @RET
ENDBLOCK

# ============================================================
# frnd16()  →  Fast 16-bit random number
#
# Algorithm:
#   George Marsaglia’s XORShift, tuned for 16-bit state.
#   Sequence of rotate/shift/xor steps mutates the Seed value.
#
# State:
#   - Uses the global :Seed value (16-bit).
#   - Updates Seed in place each call.
#
# Notes:
#   - Macros ROLn/RORn/SHRn from common.mc provide *pure* rotates/shifts.
#   - Deterministic: doesn’t depend on previous carry state.
# ============================================================

@FUNCTION frnd16
:frnd16 
    @PUSHRETURN
    @LocalVar S1Seed 01

    # --- Copy Seed into local working variable ---
    @MV2V Seed S1Seed

    # --- XORShift transformations ---
    @PUSHI S1Seed @ROL5    # rotate left 5
    @XORI S1Seed @POPI S1Seed

    @PUSHI S1Seed @ROR3    # rotate right 3
    @XORI S1Seed @POPI S1Seed

    @PUSHI S1Seed @SHR7    # shift right 7
    @XORI S1Seed @POPI S1Seed

    @PUSHI S1Seed @SHL2    # shift left 2
    @XORI S1Seed @POPI S1Seed

    # --- Push result for caller ---
    @PUSHI S1Seed

    # --- Update global Seed with counter perturbation ---
    @INCI Cval
    @PUSHI Cval @ROL5
    @XORI S1Seed @POPI Seed

    # --- Clean up ---
    @RestoreVar 01
    @POPRETURN
    @RET
ENDBLOCK
@SIZESINCE
ENDBLOCK
