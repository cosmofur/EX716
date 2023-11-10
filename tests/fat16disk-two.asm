I common.mc
L softstack.ld
L string.ld
L DIV.ld

# Local Variables:

:Iindex 0
:Jindex 0
:endIdx 0
:isStart 0
:isEnd 0
:LenVal 0
:inputstr 0
:instring 0
:returnstr 0
:BufferPtr 0
:StateFlag 0
:ClusterPtr 0
# Boot Record Structure
:BootRecord                     # Offset Length
:BR_JmpInst 0 b0                    # 0  3
:BR_OEM 0 0 0 0                     # 3  8
:BR_BytesPerSector 0                # 11 2
:BR_SectorsPerCluster b0            # 13 1
:BR_ReservedSectors 0               # 14 2
:BR_NumberFATs b0                   # 16 1
:BR_RootDirEntries 0                # 17 2
:BR_TotalSectors16 0                # 19 2 we only care about 16bit addresses
:BR_MediaDescriptor b0              # 21 1
:BR_SectorsPerFAT 0                 # 22 2
:BR_SectorsPerTrack 0               # 24 2 NA
:BR_NumberOfHeads 0                 # 26 2 NA
:BR_HiddenSectors 0 0               # 28 4
:BR_TotalSectors 0 0                # 32 4 NA (using 16 bit only)
:BR_DriveNumber b0                  # 36 1
:BR_Reserved b0                     # 37 1
:BR_ExtBootSign b0                  # 38 1
:BR_VolumeNumber 0 0                # 39 4
:BR_VolumeLabel 0 0 0 0 0 b0        # 43 11
:BR_FileSystemType 0 0 0 0          # 54 8
:BootRecordEnd
b0 # For word padding on last byte above
# Now do the 
:DR_Struct
:DR_FileName 0 0 0 0 0 b0    # 11 bytes    0
:DR_ATTRIB b0                #             xb
:DR_Reserve1 b0              #             xc
:DR_CDATE 0 0 b0             # 5 byte create date format. xd
:DR_ADATE 0                  #             x12
:DR_HighCluster 0            # High Cluster, NA for Fat16 x0x14
:DR_WDATE 0 0                #             0x16
:DR_CLUSTER 0                # Cluster     0x1A Where the FileData starts
:DR_SIZE 0 0                 # Filesyste in 32bit format
:DR_Struct_End
:DR_CurrentSect 0            # This is the abs sector of last DR entry read
:DR_CurrentRec 0             # The most recent record within dir strucutre
:DR_CurrentCluster 0         # For larger Dir's that span multiple Clusters of Dir info.



:GL_CWD 0

# Define the Storage and structure of the Boot Record
#
# Function ReadBootRecord(DiskID, BufferPtr)
:ReadBootRecord
@PRT "RBR Start" @StackDump
@PUSHRETURN
@PUSHLOCAL BufferPtr
@PUSHLOCAL Iindex
@POPI BufferPtr
@POPI Iindex    # The DiskID as temporary value
@DISKSELI Iindex
#  Now read Sector 0 into Buffer
@PUSH 0 @PUSHI BufferPtr
@CALL ReadSector  # (Sector, BufferPtr)
@ForIA2B Iindex BootRecord BootRecordEnd
   @PUSHII BufferPtr
   @AND 0xff   
   @POPII Iindex
   @INCI BufferPtr
@Next Iindex
@POPLOCAL Iindex
@POPLOCAL BufferPtr
@POPRETURN
@RET
#
#
# Function ReadSector(Iindex, BufferPtr)
#   This is a basic Read Sector, not awair of clusters or FAT tables
#
:ReadSector
@StackDump
@PUSHRETURN
@PUSHLOCAL BufferPtr
@PUSHLOCAL Iindex
@POPI BufferPtr
@POPI Iindex 
# See if that Buffer already loaded
@PUSHI BufferPtr @ADD SectorOffset @PUSHS
@IF_EQ_V Iindex
  # No change, Buffer already Loaded
@ELSE
  @DISKSEEKI Iindex
  @DISKREADI BufferPtr
  @PUSH 0                   # Zero the status flag.
  @PUSHI BufferPtr @ADD StatusOffset
  @POPS
  @PUSHI Iindex             # Save value of current sector number
  @PUSHI BufferPtr @ADD SectorOffset
  @POS
@ENDIF
@POPLOCAL Iindex
@POPLOCAL BufferPtr
@POPRETURN
@PRT "End of ReadSector: " @StackDump
@RET

# Function, CopyMem(Src,Dst,Length)
#  This is basily the strcpyn command but with no concern about posisble string legnths.
:CopyMem
@PUSHLOCAL LenVal
@PUSHLOCAL inputstr
@PUSHLOCAL returnstr
@PUSHLOCAL Iindex
@POPI LenVal
@POPI returnstr
@POPI inputstr
@ForIA2V Iindex 0 LenVal
  @PUSHII inputstr
  @AND 0xff00
  @PUSHII returnstr
  @AND 0xff00
  @ORS
  @POPII returnstr
  @INCI inputstr
  @INCI returnstr
@Next Iindex
@POPLOCAL Iindex
@POPLOCAL returnstr
@POPLOCAL inputstr
@POPLOCAL LenVal
@POPRETURN
@RET



# BootSector = {
#     jump_instruction: 3 bytes (Jump instruction or opcode)
#     oem_name: 8 bytes (OEM name of the filesystem)
#     bytes_per_sector: 2 bytes (Number of bytes per sector)
#     sectors_per_cluster: 1 byte (Number of sectors per cluster)
#     reserved_sectors: 2 bytes (Number of reserved sectors)
#     number_of_fats: 1 byte (Number of File Allocation Tables)
#     root_directory_entries: 2 bytes (Number of root directory entries)
#     total_sectors_16: 2 bytes (Total number of sectors in the filesystem, for smaller disks)
#     media_descriptor_type: 1 byte (Media descriptor type)
#     sectors_per_fat_16: 2 bytes (Number of sectors per FAT for FAT16)
#     sectors_per_track: 2 bytes (Number of sectors per track)
#     number_of_heads: 2 bytes (Number of heads/surfaces)
#     hidden_sectors: 4 bytes (Number of hidden sectors)
#     total_sectors_32: 4 bytes (Total number of sectors in the filesystem, for larger disks)
# }

# Function isvalidFAT16Char(int c)
:isValidFAT16Char
@PUSHRETURN
@PUSHLOCAL ValidFlag    # Save 'local' variable for possible reuse.
@SWITCH
   @CASE_RANGE "A\0" "Z\0"
      @MA2V 1 ValidFlag
      @CBREAK
   @CASE_RANGE "a\0" "z\0"
      @AND 0xdf  # mask changes lowercase to uppercase   
      @MA2V 1 ValidFlag
      @CBREAK
   @CASE_RANGE "0\0" "9\0"
#   0x3000 0x3900
      @MA2V 1 ValidFlag
      @CBREAK
   @CASE "_\0"
      @MA2V 1 ValidFlag
      @CBREAK   
   @CASE ".\0"
      @MA2V 1 ValidFlag
      @CBREAK
   @CASE " \0"
      @MA2V 1 ValidFlag
      @CBREAK
   @CASE "/\0"
      @MA2V 1 ValidFlag
      @CBREAK      
   @CDEFAULT

      @MA2V 0 ValidFlag    # Else invalid
      @CBREAK
@ENDCASE
@PUSHI ValidFlag
@POPLOCAL ValidFlag     # Restoreing 'local' var to whatever it had before.
@POPRETURN
@RET
:ValidFlag 0
#
# Function parseFAT16Path(inputstr, *char returnstr[12])
#          return [bytesConsumed, isStart, isEnd]
#    inputstr is a null terminated path string "/abc/def/jkl"
#    returnstr is a 12 byte buffer where space padded version of current depth value will be returned
#    In return we return character count of consumed path
#    is* flags to indicate if we're at the begining or end of filepath
:parseFAT16Path
@PUSHRETURN
#
# Prepare local variables
@PUSHLOCAL Iindex @PUSHLOCAL Jindex @PUSHLOCAL endIdx @PUSHLOCAL isStart
@PUSHLOCAL isEnd  @PUSHLOCAL LenVal @PUSHLOCAL inputstr
@PUSHLOCAL isStart
@PUSH 0   # Zero out the local variables
@DUP @POPI Iindex
@DUP @POPI Jindex
@DUP @POPI endIdx
@DUP @POPI isStart
@DUP @POPI isEnd
     @POPI LenVal
# Save local copies of passed parameters.
@POPI returnstr
@POPI inputstr
#
@PUSHII inputstr
#
# Check if start of string is '/' root 
@AND 0xff
@IF_EQ_A "/\0"
   @POPNULL
   @MA2V 1 isStart
   @MA2V 1 endIdx
   @INCI inputstr
@ELSE
   @POPNULL
@ENDIF   
#
# get len of input string for end tests
@PUSHI inputstr
@CALL strlen
@POPI LenVal
#
# Fill returnstr with spaces.

@ForIA2B Iindex 0 10
   @PUSH 0x2020    # Two spaces
   @PUSHI returnstr
   @ADDI Iindex
   @POPS
@NextBy Iindex 2
#
@MA2V 0 Iindex
@MA2V 0 Jindex
@PUSH 0     # Loop until we set flag to done
@WHILE_ZERO
   @POPNULL
   @PUSHI Iindex   # Get the Ith character in inputstr
   @ADDI inputstr
   @PUSHS
   @AND 0xff
   @CALL isValidFAT16Char
   @IF_ZERO   # Means it's not valid!
      @PRT "Invalid Character in Filename."
      @POPNULL @POPNULL
      @JMP ParseErrorExit
   @ENDIF
   @POPNULL
   @SWITCH
   @CASE ".\0"   #If "dot" then jump to the Extention part
      @POPNULL
      @MA2V 8 Jindex
      @PUSH 0 # Tell While to continue
      @CBREAK
   @CASE "/\0"   # is "/" so end string.
      @POPNULL
      @INCI endIdx   # Count the "/" as part of the consumed string
      @PUSH 1        # tell while loop to exit
      @CBREAK
   @CDEFAULT
      @OR "\0 "     # Fill high byte with Space
      @PUSHI returnstr @ADDI Jindex @POPS         # put character into returnstr
      @INCI Jindex
      @INCI Iindex
      @INCI endIdx
      @PUSH 0   # Tell While to Continue
      @CBREAK
   @ENDCASE
   @PUSHI LenVal
   @IF_LE_V endIdx
      @POPNULL
      @POPNULL
      @MA2V 1 isEnd
      @PUSH 1 # Reached end based on length, Tell While to end
   @ELSE
      @POPNULL
   @ENDIF
@ENDWHILE
@POPNULL
# Now setup return stack
@PUSHI endIdx @PUSHI isStart @PUSHI isEnd
# Now return the local variable to previous state. It's ok we resetting
# parameters like isStart and isEnd as their values are already saved on return stack
@POPLOCAL isStart @POPLOCAL inputstr @POPLOCAL LenVal @POPLOCAL isEnd
@POPLOCAL isStart @POPLOCAL endIdx @POPLOCAL Jindex @POPLOCAL Iindex
:ParseErrorExit
@POPRETURN
@RET
# Function WalkDir(string8.3, DirCluster)
#  When passed an 11 character 8.3 space padded string, will walk down DirCluster and
#  look for match. THis version does not follow sub-directories but return ptr to the DR structure
#  Returns
#           0 if no match
#           Ptr to DR_Struct if there a match.
:WalkDir
@PUSHRETURN
@PUSHLOCAL Iindex
@PUSHLOCAL ClusterPtr
@PUSHLOCAL inputstr
@POPI ClusterPtr
@POPI inputstr


@PUSHI ClusterPtr
@CALL Open_DirByID

@MA2V 0 Iindex

@CALL ReadNextDir   # Read First one, returns non-zero if not at end of dir yet.
@WHILE_NOTZERO
   @POPNULL
   @PUSHI inputstr
   @PUSH DR_FileName
   @PUSH 11
   @CALL strncmp
   @IF_ZERO     # They match
       @POPNULL
       # First consider if the match is the volume lable, which is possible but not usefull
       @PUSHI DR_ATTRIB
       @AND 0b01000
       @IF_ZERO
         # Both a filename match and its not a volume lable
	 @POPNULL
	 @MA2V 1 Iindex     # This means we found a match. Used bellow.
	 @PUSH 1            # Break the While Loop
       @ELSE
         # Was a volume lable, just continue
         @POPNULL
	 @PUSH 0            # Continue the while loop.
       @ENDIF
    @ENDIF
    @IF_ZERO  # We repeat the test due to possiblity of volume lable match
       @POPNULL
       @CALL ReadNextDir # Read next filename, zero return if at end.
    @ENDIF
@ENDWHILE
@POPNULL
@IF_EQ_VA Iindex 0
   # No filename was found to match. Return zero
   @PUSH 0
@ELSE
   @PUSHI DR_CLUSTER     # Found a file, so return it's cluster value, for ease of use.
@ENDIF
@POPLOCAL inputstr       # Restore the local variables from stack.
@POPLOCAL ClusterPtr
@POPLOCAL Iindex
@POPRETURN
@RET
   
	 

# 
#
# Function OpenDir(string) [ FileCluster, DirCluster ] also the DR_* globals will be set.
# What this function does is take a human style dir/filename path and
# returns the directory structure where that filename exists.
# So input of /foo/bar/text.txt needs to walk from the root directory
# into the foo dir, and search for text.txt returning bar's Cluster and directory Ptr
# and the index of the filestructure text.txt points to.
# In case of /foo/bar, its just returns bar's directory strucutre and a NULL for
# the file part.
# If there is an invalid path, it will return 0,0
# 
:OpenDir
@PUSHRETURN
@PUSHLOCAL Iindex
@PUSHLOCAL Jindex
@PUSHLOCAL inputstr
@POPI inputstr
@PUSHII instring
# First see if we start with a '/' and set to CWD to ROOT
@IF_EQ_A "/\0"
    @PUSHI BR_ReservedSectors
    @ForIA2V Iindex 0 BR_NumberFATs  # By starting at 0 we should get the right numltiplier
       @ADDI BR_SectorsPerFAT
    @Next Iindex
    @POPI GL_CWD
@ENDIF
#
@MA2V 0 Jindex  # Set Returned Filename to default of Null
#
# Our outter loop is stepping down through the CWD to any sub-dir's if any.
#
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @PUSHI instring @PUSH WorkSpace
   @CALL parseFAT16Path
   @DUP
   @ADDI instring @POPI instring  # Returns length of consumed part of string.
   @IF_NOTZERO
      # This means WorkSpace had some 'valid' value, so try walking the cwd for it.
      @POPNULL
      @PUSH WorkSpace
      @PUSHI GL_CWD
      @CALL WalkDir
      @IF_NOTZERO         # A filename of some sort was found, see if it's a directory.
         @POPNULL         # Get Rid of the zero, we don't need it yet.
         @PUSHI DR_ATTRIB
	 @AND 0b010000
	 @IF_NOTZERO
	    # Its a directory, change the GL_CWD to it and continue
	    @POPI GL_CWD
	 @ELSE
	    # Its a 'filename' .. check to see if we are at end of string.
	    @PUSHII inputstr
	    @AND 0xff
	    @IF_NOTZERO
	       # This means we found a filename (not dir) yet still have text left instring
	       # that not a valid situation. Return Error code.
	       @POPNULL           # Get rid of the Flag text, but we still have the Cluster number on stack
	       @POPNULL           # What ever else was on the stack is probably not usefull
	       @PUSH 0            # Return of 0,0 means invalid file path
	       @PUSH 0
	       @JMP BreakWhile
	     @ELSE
	       # We're at end of string, so we have the answer
	       @POPNULL
	       @PUSHI GL_CWD
	       @JMP BreakWhile
	     @ENDIF
	  @ENDIF
	@ENDIF

	       

	      
	    
	       

# Function Open_DirByID(Cluster)
# clears the current DR_ values and reads in first entry from Cluster
:Open_DirByID
@PUSHRETURN
@PUSHLOCAL Iindex
#
@POPI Iindex    # save the cluster
@PUSHI Iindex
@PUSH BufferDir
@CALL ReadSector
@PUSH BufferDir
@CALL CopyDRdata
@MA2V 0 DR_CurrentRec 0
@MV2V Iindex DR_CurrentCluster
@MV2V Iindex DR_CurrentSect
#
@POPLOCAL Iindex
@POPRETURN
@RET

# Function Read Next Dir
# Reads down the Directory structure. It knows about Clusters to if it runs out of one it will ask the FAT Table when the next it.

:ReadNextDir
@PUSHRETURN

# Each DIR Record is 32 bytes or 16 such records in 512 byte segment
# We need to calculate how many 512 sectors into the DIR structure the currentRec represents
# So 15 or less would be 1 sector, 16-31 be 2 sectors etc etc
# So divide CurrentRec by 16 to get an sector count from 0 to max
@PUSHI DR_CurrentRec
@RTR @RTR @RTR @RTR  # Div 16
#
# add that to the CurrentSect to find how many sectors into the DIR structure we are looking.
#
@ADDI DR_CurrentSect
# Now we need to figure out if the new value is overflowing the size of the Cluster
#
@PUSHI DR_SectorsPerCluster @AND 0xff     # Byte size value so turn into valid 16b
@CALL DIVU
# On return TOS will be (Next Sector / Sectors Per Cluster)
#           SFT will be the Modular value
@SWP
@IF_ZERO
   # This means we moved to a new Cluster, need to query FAT table for that.
   @POPNULL    # Get rid of the Mod % part
   @SUB 1      # Now find the FAT table entry
   @CALL GetNextFatEntry
   @IF_GE_A 0xfff8     # fff8 to ffff are a range of values that all mean End of Chain
      # End of Chain
      @POPNULL
      @PUSH 0
   @ELSE
      @POPI DR_CurrentCluster
      @MA2V 0 DR_CurrentRec        # zero, the record id, within this cluster.
      @PUSHI DR_CurrentCluster     # We don't need to add record since this cases is always zero
   @ENDIF
@ELSE
   # Here we know that this sector falls inside the current cluster, we just need to figureout
   # which sector inside the cluster it is.
   @SWP @POPNUL      # This is to get rid of the un-needed division result
   @ADDI DR_CurrentCluster   # Its possible there will be a chain of multiple clusters, so we keep the pointer moving.
@ENDIF
# At this point the sector number of the DR entry should be on the Stack
# OF it might be zero, if we reached the end of the chain, so check for that.
@IF_NOTZERO
  @PUSH BufferDir
  @CALL ReadSector
  # The DIRBuffer will now have the 512 sectore, we now need to figure out the offset within that 512 block is our DIR
  @PUSHI DR_CurrentRec       # DR_CurrentRec is a count from 0 to max, but the offset is CR*32 
  @AND 0x01ff
  @RTL @RTL @RTL @RTL @RTL   # Mul by 32 to get the offset in sector
  @PUSH DR_Struct
  @PUSH 32
  @CALL CopyMem              # Copy the Dir record to the Global buffer
  @INCI DR_CurrentRec
@ENDIF
@POPRETURN
@RET
#
# Function GetNextFatEntry
# Given a Sector number, will return the 









# Function CopyDRdata(SrcBuffer)
@PUSHRETURN
@PUSHLOCAL Iindex
@POPI Iindex
#
@PUSHI Iindex @PUSH DR_FileName @PUSH 32 @CALL CopyMem
#
@POPLOCAL Iindex
@POPRETURN
@RET





	 
  




:TestString "/Test/Test2/test3\0"
:WorkSpace "0123456789ABC" 0
:PathPtr 0
# here we define the space for 3 buffers.
# [BufferName-4] == sector number
# [BufferName-2] == state flag, 0=unchanged, 1=read only, 2=Modified and needs sync
=SectorOffset -4
=StateOffSet -2
:BufferFileSector 0
:BufferFileState 0
:BufferFile
. BufferFile+512
:BufferFATSector 0
:BufferFATeState 0
:BufferFAT
. BufferFAT+512
:BufferDirSector 0
:BufferDirState 0
:BufferDir
. BufferDir+512


:Main . Main
# @PUSH 0
# @MA2V TestString PathPtr
# @WHILE_ZERO
#    @POPNULL
#    @PUSHI PathPtr  @PUSH WorkSpace
#    @CALL parseFAT16Path
#    @PRTS WorkSpace @PRTNL
#    @IF_ZERO   # IsEnd is first flag
#       @POPNULL @POPNULL
#       @ADDI PathPtr @POPI PathPtr
#       @PUSH 0
#    @ELSE
#       @POPNULL @POPNULL @POPNULL
#       @PUSH 1
#    @ENDIF
# @ENDWHILE
# @POPNULL

# Test Reading Boot Record
@PUSH 0 @PUSH Buffer1
@CALL ReadBootRecord
#
@PRT "Boot Record Fields"

@PRT ":BR_JmpInst>" @PRTI BR_JmpInst @PRTNL
@PRT ":BR_OEM>" @PRTI BR_OEM @PRTNL
@PRT ":BR_BytesPerSector>" @PRTI BR_BytesPerSector @PRTNL
@PRT ":BR_SectorsPerCluster>" @PRTI BR_SectorsPerCluster @PRTNL
@PRT ":BR_ReservedSectors>" @PRTI BR_ReservedSectors @PRTNL
@PRT ":BR_NumberFATs>" @PRTI BR_NumberFATs @PRTNL
@PRT ":BR_RootDirEntries>" @PRTI BR_RootDirEntries @PRTNL
@PRT ":BR_TotalSectors16>" @PRTI BR_TotalSectors16 @PRTNL
@PRT ":BR_MediaDescriptor>" @PRTI BR_MediaDescriptor @PRTNL
@PRT ":BR_SectorsPerFAT>" @PRTI BR_SectorsPerFAT @PRTNL
@PRT ":BR_SectorsPerTrack>" @PRTI BR_SectorsPerTrack @PRTNL
@PRT ":BR_NumberOfHeads>" @PRTI BR_NumberOfHeads @PRTNL
@PRT ":BR_HiddenSectors>" @PRTI BR_HiddenSectors @PRTNL
@PRT ":BR_TotalSectors>" @PRTI BR_TotalSectors @PRTNL
@PRT ":BR_DriveNumber>" @PRTI BR_DriveNumber @PRTNL
@PRT ":BR_Reserved>" @PRTI BR_Reserved @PRTNL
@PRT ":BR_ExtBootSign>" @PRTI BR_ExtBootSign @PRTNL
@PRT ":BR_VolumeNumber>" @PRTI BR_VolumeNumber @PRTNL
@PRT ":BR_VolumeLabel>" @PRTI BR_VolumeLabel @PRTNL
@PRT ":BR_FileSystemType>" @PRTI BR_FileSystemType @PRTNL
@PRTLN "--------------------------------------------------"

#
#
@END

