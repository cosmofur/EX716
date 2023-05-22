I common.mc
# Ways of dealing with more complex structures in memory.
#
# The only built in 'type' is the 16b integer, we have some librarys and small parts of the
# assembler setup to help support strings and 32b integers.
#
L strings.ld     # Load the strings libary
L lmath.ld       # Load the 32b math library
L mul.ld         # Load the 16b MUL library
#

# First example case. An Address Struture.
#
# FirstName: String maxsize:12
# SurName: String maxsize: 20
# Addressline1: String maxsize: 128
# Addressline2: String Maxsize: 128
# ZIPCode: String MaxSize 15
#
# So we have 5 fields, all strings, all with various 'max' sizes.
# We can define them with Lables like this
# We force 'memory' to start at zero so we can use lables to idenify offsets.
:WhereMemoryAfterHeadersStart
. 0
=FirstName 0
=SurName FirstName+12
=AddressLine1 SurName+20
=AddressLine2 AddressLine1+128
=ZIPCode AddressLine2+128
:EndOfStruct1
=AddrStructSize EndOfStruct1
#
#
# We would use this structure with code like this:
#
# First we return the 'origin' point to where ever the loading of the header files left us.
. WhereMemoryAfterHeaders
#
# Now set the bottom of the array to a clear spot in memory
@MA2V ArrayStart Struct1ArrayBottom
#
@MA2V 4 Index1         # Loading a value at Index 4 of Struct (index starts at zero)
@PUSHI Index1 @PUSH AddrStructSize   # Multiple Index1 * Structure Size
@CALL MUL
@ADD StructArrayBottom               # Result + Structure Size
@POPI ArrayCursor                    # Cursor points to lowest memory cell of Record we want to use.
#
# Now we have a performance vs Space issue
# We could copy the block of memory from ArrayCursor to ArrayCurst+Struture Size to a known fixed
# memory location, then we will not need run time additions to find the offsets of the various fields
# as that can be pre-calculated at assembly time.
# or
# We could use ADDs + Offsets, to the exiting ArrayCursor to read/modify field entries in place.
#
# Example of the first: Result of this would be a series of Ptr variables pointing to the named fields.
#
@PUSHI ArrayCursor @PUSHI FixedBlock @PUSH AddrStructSize @CALL moveblock
@MA2V FixedBlock+FirstName FirstNamePtr       # The '+'s here would be calculated at assembly time.
@MA2V FixedBlock+SurName SurNamePtr           # Or we could even get away with using fixed lables
@MA2V FixedBlock+AddressLine1 Address1Ptr     # All preset at the right locations of the FixedBlock
@MA2V FixedBlock+AddressLine2 Address2Ptr     # Chages to the FixedBlock data would not automaticly be saved
@MA2V FixedBlock+ZIPCode ZipCodePtr           # to the original array.
# the main dissadvantage of the FixedBlock  method is we have no fast way to execute 'moveblock' it will
# both require use to reserve extra memory, and loop though that memory, slowing down the code. 
#
# 
# Example of the Second, here we set our Ptr's to the spots in the Array memory directly
@PUSHI ArrayCursor @ADD FirstName @POPI FirstNamePtr  # Note that this ADD is calculated at 'RunTime'
@PUSHI ArrayCursor @ADD SurName @POPI SurNamePtr
@PUSHI ArrayCursor @ADD AddressLine1 @POPI Address1Ptr
@PUSHI ArrayCursor @ADD AddressLine2 @POPI Address2Ptr
@PUSHI ArrayCursor @ADD ZipCode @POPI ZipCodePtr      # Note that any modification of the values will
                                                      # Imeditily affect the Array storage
# the main dissadanges of the @ADD offset method is the need to keep doing ADD math for every active field
# when we move from one record to another. We also do not get the free 'undo' that the FixedBlock gives us
# as any modification affects the original data, without a copy to go back to.
