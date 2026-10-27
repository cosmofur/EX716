! __EX716_FARPTR_LOADED
M __EX716_FARPTR_LOADED 1
# Explicit far-data access helpers for segmented CPU24 programs.
# The descriptor itself is a near object in the current DS.  Its segment word
# selects ES; @ESO then applies that bank only to the target load or store.
# ES is restored before returning, so these calls preserve the caller's bank.

I commonDS.mc

G ex716_far_get16
G ex716_far_put16
G ex716_far_get16v
G ex716_far_put16v

@FUNCTION ex716_far_get16
:ex716_far_get16
@PUSHRETURN
@Locals
    @Local Pointer
    @Local SavedES

    @POPI Pointer
    @SGET SegES @POPI SavedES

    # ES = pointer->segment; result = *(unsigned short ES: pointer->offset)
    @PUSHI Pointer @ADD 2 @PUSHS @SSET SegES
    @PUSHI Pointer @PUSHS @ESO @PUSHS

    @PUSHI SavedES @SSET SegES
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION ex716_far_get16v
:ex716_far_get16v
@PUSHRETURN
@Locals
    @Local SourceDescriptor
    @Local Destination
    @Local Source
    @Local Count
    @Local SavedES

    @POPI Count
    @POPI Destination
    @POPI SourceDescriptor
    @SGET SegES @POPI SavedES
    @PUSHI SourceDescriptor @ADD 2 @PUSHS @SSET SegES
    @PUSHI SourceDescriptor @PUSHS @POPI Source
    @PUSHI Count
    @WHILE_NOTZERO
        @POPNULL
        @PUSHI Source @ESO @PUSHS
        @PUSHI Destination @POPS
        @PUSHI Source @ADD 2 @POPI Source
        @PUSHI Destination @ADD 2 @POPI Destination
        @DECI Count
        @PUSHI Count
    @ENDWHILE
    @POPNULL
    @PUSHI SavedES @SSET SegES
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION ex716_far_put16v
:ex716_far_put16v
@PUSHRETURN
@Locals
    @Local DestinationDescriptor
    @Local Source
    @Local Destination
    @Local Count
    @Local SavedES

    @POPI Count
    @POPI Source
    @POPI DestinationDescriptor
    @SGET SegES @POPI SavedES
    @PUSHI DestinationDescriptor @ADD 2 @PUSHS @SSET SegES
    @PUSHI DestinationDescriptor @PUSHS @POPI Destination
    @PUSHI Count
    @WHILE_NOTZERO
        @POPNULL
        @PUSHI Source @PUSHS
        @PUSHI Destination @ESO @POPS
        @PUSHI Source @ADD 2 @POPI Source
        @PUSHI Destination @ADD 2 @POPI Destination
        @DECI Count
        @PUSHI Count
    @ENDWHILE
    @POPNULL
    @PUSHI SavedES @SSET SegES
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

@FUNCTION ex716_far_put16
:ex716_far_put16
@PUSHRETURN
@Locals
    @Local Pointer
    @Local Value
    @Local SavedES

    # C arguments are pushed left-to-right, so value arrives first.
    @POPI Value
    @POPI Pointer
    @SGET SegES @POPI SavedES

    # *(unsigned short ES: pointer->offset) = value
    @PUSHI Pointer @ADD 2 @PUSHS @SSET SegES
    @PUSHI Value
    @PUSHI Pointer @PUSHS @ESO @POPS

    @PUSHI SavedES @SSET SegES
@EndLocals
@POPRETURN
@RET
@ENDFUNCTION

ENDBLOCK
