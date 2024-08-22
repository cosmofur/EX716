! FAT16Seen
M Fat16Seen 1
I common.mc
L heapmgr.ld
L string.ld
L lmath.ld
#
# HeapObject is allocated memory of given size
# BufferPtr is likely a HeapObheject but could also just be a fixed block of memory of size
# DiskID, sector, cluster are all 16bit numbers
# HeapID is a Heap Structure and make with the HeapDefineMemory call. But it an be inbeded in a heapobject
#
#
G ReadSectorBuffer       # ReadSectorBuffer(DiskID, Sector):New HeapObject
G ReadSector             # ReadSector(sector, BufferPtr):int (0==success else error code)
G SelectDisk             # Selectisk(DiskID,HeapID):New HeapObject
G ParseBootSector        # ParseBootSector(BufferPtr):void()
G ReportParseBootSector  # ReportParseBootSector(BufferPtr):void()
G GetFatAddress          # GetFatAddress(cluster):cluster (or cluster End code)
G ReadRootDir            # ReadRootDir():HeapObject
G ReadDirBuffer          # ReadDir(cluster):New HeapObject
G ListDir                # ListDir(Buffer): List Root Directory
G GetDirectory           # GetDirectory(StartDircluster, FileStringPtr):(AttributeBytes, Cluster)
G ReadDirectoryEntry     # ReadDirectoryEntry(cluster, entry) (by index # rather than string)
G ReadCluster            # ReadCluster(cluster, bufferptr):bufferptr
G ReadClusterBuffer      # ReadClusterBuffer(cluster):HeapObject
G WriteBuffer            # WriteBuffer(sector,dataptr)
G WriteCluster           # WriteCluster(cluster,dataptr)
G GetNextCluster         # GetNextCluster(cluster):newcluster
G AllocateCluster        # AllocateCluster():newcluster
G FileSizeInClusters     # FileSizeInClusters(cluster): int size in clusters
G ReadFile2Mem           # ReadFile2Mem(cluster,int32ptr:startoffset,int16:maxsize):HeapObject
G DateTimeFormat         # DateTimeFormat(mode, data, strptr)
G PrintDirEntryInfo      # (Dir Entry) Prints details about selected Dir Entry
G strFormat



################################################
# Common constants
#
# Boot Record Offsets.
=BytesPerSectorOffset 11          # word
=SectorsPerClusterOffset 13       # Bytes
=ReservedSectorsCountOffset 14    # Word
=NumberOfFATCopiesOffset 16       # Byte
=RootDirectoryEntriesOffset 17    # Word
=TotalSectorsLowOffset 19         # word (if zero use High)
=SectorsPerFatOffset 22           # word
=TotalSectorsHighOffset 32        # 32 bit value, use if Low is zero
# Directory Structure Offsets
=DirAttribOffset 0xb              # byte
=DirDataTimeOffset 0xd            # 5 byte Fat format date
=DirAccessedOffset 0x12           # 2 bytes access date
=DirWrittenOffset 0x16            # 4 bytes
=Dir1stClusterOffset 0x1a         # 2 bytes
=DirFileSizeOffset 0x1c           # 4 bytes
=DirAttribReadOnly 0x1            # 1 bit flags
=DirAttribHidden 0x2
=DirAttribSystem 0x4
=DirAttribVolumeLabel 0x8
=DirAttribDir 0x10
=DirAttribArchive 0x20
###############################################
# Active Disk's shared info.
# While several of these fields are bytes, we store as words for simplicty with math.
# Make these Global for easy refrence:
G BytesPerSector G SectorsPerCluster G ReservedSectorsCount G NumberOfFATCopies
G RootDirectoryEntries G TotalSectorsLow G TotalSectorsHigh G SectorsPerFat G DiskHeapID
G ActiveBuffer G ActiveDisk G CurrentWorkingDirectory G CurrentWorkingCluster 0


:BytesPerSector 0
:SectorsPerCluster 0
:ReservedSectorsCount 0
:NumberOfFATCopies 0
:RootDirectoryEntries 0
:TotalSectorsLow 0
:TotalSectorsHigh 0 0
:SectorsPerFat 0
:DiskHeapID 0
:ActiveBuffer 0
:ActiveDisk -1
:CurrentWorkingDirectory 0
:CurrentWorkingCluster 0
:RootDirSectors 0
:FirstDataSector 0

=MaxDiskHandles 5
:DiskHandles 0 0 0 0 0 0 0 0 0 0  # two words for each handle. 0th=ID 1th=HeapPtr




#
# Local temporary values (Registers)
:Var01 0
:Var02 0
:Var03 0
:Var04 0
:Var05 0
:Var06 0
:Var07 0
:Var08 0
:Var09 0
:Var10 0
:Var11 0
:Var12 0
:Var13 0
###########################################################################
# Function ErrorExit
:ErrorExit
@TTYECHO
@PRT "From Location: " @PRTHEXTOP
@POPNULL
@PRT " Error Code: " @PRTTOP
@PRTNL
@POPNULL
@END
#############################################
# Function ReadSectorBuffer(DiskID,DiskSector)
# Both reads a given sector, and creates a new heapobject buffer for that sectors data.
:ReadSectorBuffer
=WorkingObject Var01
=DiskSector Var02
=DiskID Var03
#
@PUSHRETURN
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
#
@POPI DiskSector
@POPI DiskID
#
@PUSHI DiskHeapID
@PUSH 0x200
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 101 @CALL ErrorExit @ENDIF  # (HeapId, Size)
@POPI WorkingObject
@DISKSELI DiskID
@DISKSEEKI DiskSector
@PUSHI WorkingObject
@DISKREADI WorkingObject @POPNULL
@PUSHI WorkingObject
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

###############################################
# Function ReadSector(sector, bufferptr):(0=success: 1=fail)
# Reads a sector, and saves it in the specified buffer addres.
:ReadSector
@PUSHRETURN
=Bufferptr Var01
=sector Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
#
@POPI Bufferptr
@POPI sector
#
@DISKSEEKI sector
@DISKREADI Bufferptr
#
@POPLOCAL Var02
@POPLOCAL Var01
@PUSH 0              # Have to figure out a failure condition but for now just return success.
@POPRETURN
@RET



###############################################
# Function SelectDisk(DiskID,HeapID):0|1 success failure
# You both select a disk and creates a new 512 byte buffer for it.
# Also makes it the 'ActiveDisk' for the current session, allowing multiple disks
# On exit it passes pointer to 512 buffer for that disk.
#  Behavior for the HeapID, on first call it should point to a 'Main' HeapID > 4K bytes usable space.
#  if later calls use '0' that Main Heap ID will be used, otherwise it will use
#  passed HeapID, but will not 'make' it the Main HeapID, which will remain as with the first call.
#  In usage, that means first call should always be global Heap id, and later calls use local heapid's
#  only if there some reason you don't want to use the global one.
:SelectDisk
@PUSHRETURN
=WorkingObject Var01
=CurrentHandle Var02
=DiskID Var03
=Index1 Var04
=InHeapID Var05
=NewHeapID Var06
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
#
@POPI InHeapID
@POPI DiskID
@PRT "Passed in HeapID: " @PRTHEXI InHeapID @PRTNL
#
# Search for an open Handle
@MA2V 0 Index1
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @PUSHI Index1 @RTL @RTL @ADD DiskHandles # Each Cell is 4 Bytes/2 words long.
   @PUSHS
   @IF_NOTZERO
      # This Index1 handle is in use.
      @POPNULL
      @INCI Index1
      @IF_EQ_AV MaxDiskHandles Index1
         @PRTLN "Error: Ran out of Disk device Handles."
         @PUSH 101 @CALL ErrorExit
      @ENDIF
      @PUSH 0     # Continue Looking for free handle.
   @ELSE
      # Free Handle found. Make it the Current handle
      @POPNULL
      @PUSHI Index1 @RTL @RTL @ADD DiskHandles # again.
      @POPI CurrentHandle
      @PUSH 1
   @ENDIF
@ENDWHILE
@POPNULL

# Check the HeapID's values.
@IF_EQ_AV 0 InHeapID    # We allow 'zero' to mean use the main heapid. But it must already been set once.
   @IF_EQ_AV 0 DiskHeapID
      @PRTLN "Error, Heap Storage never set for Disk System. First call to SelectDisk must include valid heap"
      @PUSH 101 @CALL ErrorExit
   @ENDIF
   @MV2V DiskHeapID InHeapID
@ELSE
   # See if this is the first call with a HeapID, which makes it the 'Main' one.
   @IF_EQ_AV 0 DiskHeapID
      @MV2V InHeapID DiskHeapID
   @ENDIF
@ENDIF
#
# Look in DiskHandles array for info about device.
@PUSHII CurrentHandle
@PRT "Mid1 HeapID: " @PRTREF InHeapID @PRTSP  @PRTHEXI InHeapID @PRTNL
@IF_ZERO
   # Handle is 'new' so create it
   @POPNULL
   @PUSHI InHeapID
   @PUSH 0x200
   @CALL HeapNewObject @IF_ULT_A 100 @PUSH 101 @CALL ErrorExit @ENDIF  # (HeapID, size)
   @PUSHI CurrentHandle @ADD 2    # Save to Handle+2
   @POPS
   @PUSHI DiskID
   @POPII CurrentHandle           # Save Disk ID to Handle
   @PUSHI CurrentHandle @ADD 2 @PUSHS
   @POPI ActiveBuffer
   @MV2V DiskID ActiveDisk
@PRT "Mid2 HeapID: " @PRTREF InHeapID @PRTSP  @PRTHEXI InHeapID @PRTNL
@ELSE
   @IF_EQ_VV ActiveDisk DiskID
      # DiskID was already the active disk, no need to do anything.
   @ELSE
      @PUSHI CurrentHandle @ADD 2
      @POPI ActiveBuffer
   @ENDIF
@ENDIF

@PRT "Mid3 HeapID: " @PRTREF InHeapID @PRTSP  @PRTHEXI InHeapID @PRTNL
:Break01
@DISKSELI ActiveDisk
@PUSHI ActiveDisk
@PUSHI ActiveBuffer
@PRT "Before ReadSector " @StackDump
@PRT "Var01: " @PRTHEXI Var01 @PRT " Var02: " @PRTHEXI Var02 @PRT " Var03: " @PRTHEXI Var03 @PRT " Var04: " @PRTHEXI Var04
@PRT " Var05: " @PRTHEXI Var05 @PRT " Var06: " @PRTHEXI Var06 @PRT " Var07: " @PRTHEXI Var07 @PRT " Var08: " @PRTHEXI Var08 @PRTNL
@CALL ReadSector
@PRT "Mid3a HeapID: " @PRTREF InHeapID @PRTSP  @PRTHEXI InHeapID @PRTNL
@PRT "Var01: " @PRTHEXI Var01 @PRT " Var02: " @PRTHEXI Var02 @PRT " Var03: " @PRTHEXI Var03 @PRT " Var04: " @PRTHEXI Var04
@PRT " Var05: " @PRTHEXI Var05 @PRT " Var06: " @PRTHEXI Var06 @PRT " Var07: " @PRTHEXI Var07 @PRT " Var08: " @PRTHEXI Var08 @PRTNL
@PUSHI ActiveBuffer
@CALL ParseBootSector         # ParseBootSector(buffer)
@POPNULL
@PRT "Mid4 HeapID: " @PRTREF InHeapID @PRTSP  @PRTHEXI InHeapID @PRTNL


# We only need to create a CurrentWorkingDirectory once.
@IF_EQ_AV 0 CurrentWorkingDirectory
   # Space for CurrentWorkingDirectory
   @PRT "Heap Starts at: " @PRTHEXI InHeapID @PRTNL
   @PUSHI InHeapID @PUSH 256
   @CALL HeapNewObject @IF_ULT_A 100 @CALL ErrorExit @ENDIF  # (HeapId, Size)
   @POPI CurrentWorkingDirectory
@ENDIF
# Caclulate the RootDirSector
@PUSHI RootDirectoryEntries @RTL @RTL @RTL @RTL @RTL # * 32
@PUSHI BytesPerSector @SUB 1
@ADDS
@PUSHI BytesPerSector
@CALL DIVU
@POPI RootDirSectors
@POPNULL # Remove the un-needed MOD
# Calculate FirstDataSector
@PUSHI NumberOfFATCopies @PUSHI SectorsPerFat
@CALL MULU
@ADDI ReservedSectorsCount
@ADDI RootDirSectors
@POPI FirstDataSector
#
@PUSHI InHeapID
@PUSHI ActiveBuffer
@CALL HeapDeleteObject
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

###############################################
# Function ParseBootSector(bufferptr)
#    Extract BIOS Paramter block from buffer
:ParseBootSector
@PUSHRETURN
=BufferPtr Var01
=RecordPtr Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI BufferPtr
#
@PUSHI BufferPtr @ADD BytesPerSectorOffset @PUSHS @POPI BytesPerSector
@PUSHI BufferPtr @ADD SectorsPerClusterOffset @PUSHS @AND 0xff  @POPI SectorsPerCluster
@PUSHI BufferPtr @ADD ReservedSectorsCountOffset @PUSHS @POPI ReservedSectorsCount
@PUSHI BufferPtr @ADD NumberOfFATCopiesOffset @PUSHS @AND 0xff @POPI NumberOfFATCopies
@PUSHI BufferPtr @ADD RootDirectoryEntriesOffset @PUSHS @POPI RootDirectoryEntries
@PUSHI BufferPtr @ADD TotalSectorsLowOffset @PUSHS @POPI TotalSectorsLow
@IF_EQ_AV 0 TotalSectorsLow
   # Larger disk with 32 bit number of Sectors
   @PUSHI BufferPtr @ADD TotalSectorsHighOffset @POPI RecordPtr
   @COPY32IV RecordPtr TotalSectorsHigh
@ENDIF
@PUSHI BufferPtr @ADD SectorsPerFatOffset @PUSHS @POPI SectorsPerFat

@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
################################################
# Function ReportParseBootSector
# Print values gathered from ParseBootSector
:ReportParseBootSector
@PUSHRETURN
@PRTLN "--------------------------"
@PRT "Bytes Per Sector: " @PRTI BytesPerSector @PRTNL
@PRT "Sectors Per Cluster: " @PRTI SectorsPerCluster @PRTNL
@PRT "Reserved Sectors Count: " @PRTI ReservedSectorsCount @PRTNL
@PRT "Number of FAT Copies: " @PRTI NumberOfFATCopies @PRTNL
@PRT "Root Directory Entries: " @PRTI RootDirectoryEntries @PRTNL
@IF_EQ_AV 0 TotalSectorsLow
   @PRT "Total Sectors " @PRT32 TotalSectorsHigh @PRTNL
@ELSE
   @PRT "Total Sectors: " @PRTI TotalSectorsLow @PRTNL
@ENDIF
@PRT "Sectors Per FAT: " @PRTI SectorsPerFat @PRTNL
@POPRETURN
@RET
#################################################
# Function GetFatAddress(cluster):cluster
:GetFatAddress
@PUSHRETURN
=cluster Var01
=FatSector Var02
=FatTableBuffer Var03

@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
##
@POPI cluster
@PUSHI cluster @RTL   # cluster*2
@PUSHI BytesPerSector
@CALL DIVU            # Returns(DIV,MOD)
@ADDI ReservedSectorsCount
@POPI FatSector
@PUSHI ActiveDisk
@PUSHI FatSector
#
@CALL ReadSectorBuffer       # ReadSectorBuffer(diskID,sector):heapObject
@POPI FatTableBuffer
#
# On stack should still be the MOD value from previous DIV
#@RTR         # MOD/2
@ADDI FatTableBuffer
@PUSHS
@PRT "Next Cluster is: " @PRTHEXTOP @PRTNL
@PUSHI DiskHeapID
@PUSHI FatTableBuffer
@CALL HeapDeleteObject      # Recover space from buffer
#
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


# // Calculate the size of the root directory in sectors
#    int16 RootDirSectors = ((RootDirectoryEntries * 32) + (BytesPerSector - 1)) / BytesPerSector;#
#
#    // First data sector
#    int32 FirstDataSector = ReservedSectorsCount + (NumberOfFATCopies * SectorsPerFat) + RootDirSect#ors;
#
#    // First sector of the cluster
#    int32 ClusterSector = ((cluster - 2) * SectorsPerCluster) + FirstDataSector;
###


##################################################
# Function ReadRootDir()
# Create a buffer to read the root directory and return that buffer.
# ReadRootDir and ReadClusterBuffer are very similur, but number of sectors
# read in ReadRootDir is based on fixed value in bootsector.
#
:ReadRootDir
@PUSHRETURN
=rootDirStartSector Var01
=rootDirSize Var02
=rootDirBuffer Var03
=Index1 Var04
=rootDirPtr Var05
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
#
#  rootDirStartSector=ReservedSectorsCount + (NumberOfFATCopies * SectorsPerFat)
@PUSHI NumberOfFATCopies @PUSHI SectorsPerFat
@CALL MULU
@ADDI ReservedSectorsCount
@POPI rootDirStartSector
#
#  rootDirSize = (RootDirectoryEntries * 32) / BytesPerSector
@PUSHI RootDirectoryEntries @PUSH 32
@CALL MULU
@PUSHI BytesPerSector
@CALL DIVU
@SWP @POPNULL  # Get rid of unneeded MOD value
@POPI rootDirSize
#
# rootDirBuffer=NewObject(HeapID, rootDirSize * BytesPerSector)
@PUSHI DiskHeapID
@PUSHI rootDirSize
@PUSHI BytesPerSector
@CALL MULU
@CALL HeapNewObject @IF_ULT_A 100 @CALL ErrorExit @ENDIF # (HeapID, size)
@POPI rootDirBuffer
#
@MV2V rootDirBuffer rootDirPtr
@ForIA2V Index1 0 rootDirSize
   @PUSHI rootDirStartSector
   @ADDI Index1
   @PUSHI rootDirPtr
   @CALL ReadSector @IF_NOTZERO @CALL ErrorExit @ENDIF @POPNULL
   @PUSHI rootDirPtr @ADDI BytesPerSector @POPI rootDirPtr
@Next Index1
@PUSHI rootDirBuffer
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


##################################################
# Function ReadDirBuffer(cluster):buffer
# Create a buffer to read directory from a given cluster
#
:ReadDirBuffer
@PUSHRETURN
=DirStartSector Var01
=DirSize Var02
=DirBuffer Var03
=Index1 Var04
=DirPtr Var05
=cluster Var06
=OnlyRoot Var07
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
#
@POPI cluster
#
@IF_EQ_AV 0 cluster
   # If 0 is passed, the default to root directory.
   @CALL ReadRootDir
   # Leave result on stack as normal return.
@ELSE
   # Otherwise this is a sub-directory, which is much like a readfile2Mem
   @PUSHI cluster
   @PUSH 0
   @PUSH 0
   @CALL ReadFile2Mem  # (cluster, offset, maxsize) maxsize=0 means no limit.
   # Lease result on stack as normal return.
@ENDIF
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###############################################
# Function DateTimeFormat ([1=date,2=time],rawvale,strptr)
:DateTimeFormat
@PUSHRETURN
=Indata Var01
=SelectMode Var02
=strptr Var03
=Month Var04
=Seconds Var04   # Note duplication
=Day Var05
=Minutes Var05
=Year Var06
=Hours Var07
=Object Var08
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08

#
@POPI strptr
@POPI Indata
@POPI SelectMode
@IF_EQ_AV 1 SelectMode
   # Date
   @PUSHI Indata
   @AND 0x1f      # Day is bits 0-4
   @POPI Day
   @PUSH Indata @RTR @RTR @RTR @RTR @RTR # >>5 bits 5-8 is month
   @AND 0x0f
   @POPI Month
   @PUSHI Indata
   @RTR @RTR @RTR
   @RTR @RTR @RTR
   @RTR @RTR @RTR   # << 9 to get year offset
   @ADD 1980
   @POPI Year
   # Format string
    @PUSHI Year
    @PUSHI Month
    @PUSHI Day
    @STRSTACK "%02d/%02d/%02d"
    @PUSHI DiskHeapID
    @CALL strFormat
    @POPI Object
    @PUSHI strptr
    @PUSHI Object
    @CALL strcpy
@ELSE
   # Time   
   @PUSHI Indata
   @AND 0x1f @RTL   # Seconds bits 0-4, *2 as range is only 0-31
   @POPI Seconds
   @PUSHI Indata
   @RTR @RTR @RTR @RTR @RTR  # >> 5
   @AND 0x3f        # Minutes bits 5-10
   @POPI Minutes
   @PUSHI Indata
   @RTR @RTR @RTR @RTR
   @RTR @RTR @RTR @RTR
   @RTR @RTR @RTR     # >> 11
   @AND 0x1f
   @POPI Hours
   @PUSHI Hours
   @PUSHI Minutes
   @PUSHI Seconds
   @STRSTACK "%02d:%02d:%02d"
   @PUSHI DiskHeapID   
   @CALL strFormat
   @POPI Object
   @PUSHI strptr
   @PUSHI Object
   @CALL strcpy
@ENDIF
@PUSHI DiskHeapID @PUSHI Object @CALL HeapDeleteObject
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET




################################################
# Function ListDir(DirBuffer)
:ListDir
@PUSHRETURN
=Index1 Var01
=dirEntry Var02
=Index2 Var03
=attrByte Var04
=DoPrint Var05
=DirCount Var06
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
#
@POPI dirEntry
@MA2V 0 DirCount
@ForIA2V Index1 0 RootDirectoryEntries
    @PUSHI dirEntry @ADD 32 @POPI dirEntry
    @PUSHII dirEntry
    @AND 0xff
    @IF_ZERO
       @PUSHI RootDirectoryEntries @SUB 1 @POPI Index1 # Break Loop
    @ELSE
       @MA2V 1 DoPrint
       @IF_EQ_A 0xe5
           #Skip Deleted Files
           @MA2V 0 DoPrint
       @ELSE
           @PUSHI dirEntry @ADD DirAttribOffset @PUSHS @POPI attrByte
           @PUSHI attrByte @AND 0xff
           @IF_EQ_A 0x8
              # Volume Lable Entry
              @PRT "Volume: "
           @ELSE
              @DUP
              @AND 0x02
              @IF_NOTZERO
                 # Hidden File
                 @MA2V 0 DoPrint
              @ELSE
                 @POPNULL
                 @DUP
                 @AND 0x04
                 @IF_NOTZERO
                     # System File
                     @MA2V 0 DoPrint
                 @ELSE
                     @POPNULL
                     @DUP
                     @AND 0x0f
                     @IF_NOTZERO
                        # Skip long filenames
                        @MA2V 0 DoPrint
                     @ENDIF
                 @ENDIF
              @ENDIF
           @ENDIF
        @ENDIF
        @POPNULL
        @IF_EQ_AV 1 DoPrint
           @INCI DirCount
           @PRTI DirCount @PRT ": "
           @ForIA2B Index2 0 11
              @PUSHI dirEntry @ADDI Index2 @PUSHS @AND 0xff
              @PRTCHS
              @POPNULL
           @Next Index2
           @PRTNL
        @ENDIF
        @POPNULL
    @ENDIF
    @POPNULL
@Next Index1
@PRTLN "End Of Listing:"
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

################################################
# Function GetDirectory(startDIRCluster, FileStringPtr)
# Returns(AttributeByte, Cluster)
# Used to select either filename in current directory or
# a way to switch to a sub-directory. Only one layer at a time.
:SpacePadded "           " 0
:GetDirectory
@PUSHRETURN
=startCluster Var01
=PathStringPtr Var02
=cluster Var03
=dirEntry Var04
=Index1 Var05
=NextCluster Var06
=RootBuffer Var07
=DoFNTest Var08
=BreakInner Var09
=AttributeByte Var10
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08
@PUSHLOCALI Var09
@PUSHLOCALI Var10
#
@POPI PathStringPtr
@POPI startCluster
# Prepare string
# We only use the 8 bit ASCII filenames 8.3 format
# So we must first convert the PathStringPtr to Space Padded Uppercase
@MV2V PathStringPtr Index1
@PUSHII Index1 @AND 0xff
@WHILE_NOTZERO
   @IF_GE_A "a\0"
      @IF_LE_A "z\0"
         @PUSHII Index1
         @AND 0xffdf       # Lower to Upper
         @POPII Index1
      @ENDIF
   @ENDIF
   @POPNULL
   @INCI Index1
   @PUSHII Index1 @AND 0xff
   @IF_EQ_A "/\0"
      # For cases were "dir/filename" was passed, terminate string at "dir/"
      @POPNULL
      @PUSH 0
   @ENDIF
@ENDWHILE
@POPNULL

@PUSHII PathStringPtr @AND 0xff
@IF_EQ_A "/\0"
   # Is filename was "/file" remove the "/"
   @INCI PathStringPtr
@ENDIF
@POPNULL
# Reset SpacePadded to be all spaces.
@ForIA2B Index1 0 11
   @PUSH 0x2020
   @PUSH SpacePadded
   @ADDI Index1
   @POPS
@Next Index1
@PUSH SpacePadded
@PUSHI PathStringPtr
@PUSH 11
# Use strncpy to copy the len(PathStringPtr) upto 11, to SpacePadded
@CALL strncpy
@ForIA2B Index1 0 11
   # Make sure no nulls snuck in.
   @PUSHI Index1
   @ADD SpacePadded
   @PUSHS @AND 0xff
   @IF_ZERO
      @PUSHI Index1
      @ADD SpacePadded
      @PUSHS
      @AND 0xff20
      @PUSHI Index1
      @ADD SpacePadded
      @POPS
   @ENDIF
   @POPNULL
@Next Index1
#
#
@MA2V 0 RootBuffer   # Will be zero if we are Not reading root dir.
@IF_EQ_AV 0 startCluster
   # We need some extra logic to deal with Root Directories as they are not true clusters.
   @CALL ReadRootDir
   @POPI RootBuffer
@ENDIF
@MV2V startCluster cluster
@MA2V 0 NextCluster
@MA2V 0 BreakInner
@MA2V 0 Index1
@IF_EQ_AV 0 RootBuffer
   #Is NOT a ROOT Dir, use the Cluster logic.
   @PUSHI cluster
   @PUSHI Index1
   @CALL ReadDirectoryEntry
   @POPI dirEntry
@ELSE
   # Is a ROOT dir, so we just need dirEntry to be the offset of the buffer.
   @PUSHI RootBuffer
   @POPI dirEntry
@ENDIF

@PUSHI BreakInner
@WHILE_ZERO
    @POPNULL
    @PUSHI dirEntry
    @CALL PrintDirEntryInfo   ###
    @MA2V 0 DoFNTest           # Default is to not test current against filename
    @PUSHII dirEntry   # Tests against the word at dirEntry[0]
    @IF_ZERO
        @PRTLN "Reached End of DIR Listings"
        # Reached end of DIR without match, return -1 as error
        @POPNULL   # Pop 00
        @MA2V -1 NextCluster
        @MA2V 1 BreakInner
    @ELSE
        @IF_EQ_A 0xe5 # This is the Deleted File Mark. Skip it.
           @PRTLN "Deleted Line Entry"
           @POPNULL
        @ELSE
           @POPNULL   # Pop Test on dirEntry[0]
           # Now test against the Attribute Byte
           @PUSHI dirEntry
           @ADD DirAttribOffset
           @PUSHS
           @AND 0xff
           @POPI AttributeByte
           # We only want to check filename against DIR or normal files.
           # Not Volumes, or long filenames.           
           @PUSHI AttributeByte @AND 0xf #long filename
           @IF_EQ_A 0xf
              @PRTLN "Was Long Filename, skip it."
              @POPNULL
           @ELSE
              @POPNULL
              @PUSHI AttributeByte @AND 0x08
              @IF_NOTZERO    # Volume flag
                 @PRTLN "Volume Flag"
                 @POPNULL
              @ELSE
                 @POPNULL  # Remove the test
                 @PRT "Was File type: " @PRTI AttributeByte @PRTNL
                 # Passed all tests, so test against filename
                 @MA2V 1 DoFNTest
              @ENDIF
           @ENDIF
         @ENDIF
         @IF_EQ_AV 1 DoFNTest
            # Here means that we do want to compare this directory to filename
            @PUSHI dirEntry
            @PUSH SpacePadded
            @PUSH 11
            @CALL strncmp
            @IF_ZERO
               @POPNULL            
               # String Matches Directory name.
               @PRTLN "Strings Match:"
               @PUSHI dirEntry
               @ADD Dir1stClusterOffset
               @PUSHS    # Result is new Cluster ID
               @POPI NextCluster
               @MA2V 1 BreakInner
            @ELSE
               @POPNULL  # Get rid of the strncmp result
            @ENDIF
         @ENDIF
    @ENDIF
#
    @INCI Index1
    @IF_EQ_AV 0 BreakInner
       @PRTLN "Move to next DIR entry"
       @PUSHI dirEntry @ADD 32 @POPI dirEntry
    @ENDIF
    @PUSHI BreakInner
@ENDWHILE
@POPNULL
@IF_EQ_AV 0 RootBuffer
   @PRTLN "Was Root Buffer, clear out heap object"
   # dirEntry is a heap object, clean it up
   @PUSHI DiskHeapID
   @PUSHI dirEntry
   @CALL HeapDeleteObject     # (DiskHeapID,dirEntry) Free up the space used by dirEntry
@ELSE
   @PUSHI DiskHeapID
   @PUSHI RootBuffer
   @CALL HeapDeleteObject
@ENDIF
@PUSHI AttributeByte
@PUSHI NextCluster
@POPLOCAL Var10
@POPLOCAL Var09
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###############################################
# Function ReadDirectoryEntry(cluster,entry)
# Read an indexed directory for a specific cluster.
:ReadDirectoryEntry
@PUSHRETURN
=cluster Var01
=entry Var02
=dirEntry Var03
=entriesPerCluster Var04
=clusterOffset Var05
=entryOffset Var06
=currentCuster Var07
=Index1 Var08
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08
#
@POPI entry
@POPI cluster
#
@PUSHI DiskHeapID
@PUSH 32    # Size of a Directory Entry
@CALL HeapNewObject  @IF_ULT_A 100  @CALL ErrorExit @ENDIF  # (HeapId, Size)
@POPI dirEntry
#  entries per cluster calculated by sectory per cluster * bytes per sector / size of dir entry
@PUSHI BytesPerSector @PUSHI SectorsPerCluster
@CALL MULU
@RTR @RTR @RTR @RTR @RTR # Fastest way to divide by 32, size of a directory entry
@POPI entriesPerCluster
# Figure out offset with in the cluster
@PUSHI entry
@PUSHI entriesPerCluster
@CALL DIVU
@POPI clusterOffset       # Result of div
@POPI entryOffset         # Remainder (MOD)
#
@MV2V cluster currentCluster
@ForIA2V Index1 0 clusterOffset
   @PUSHI currentCluster
   @CALL GetNextCluster      # Follow Fat to get the next cluster
   @POPI currentCluster
   @IF_EQ_AV -1 currentCluster
       @PRT "Entry out of bounds"
       @PUSHI DiskHeapID
       @PUSHI dirEntry
       @CALL HeapDeleteObject
       @MA2V currentCluster Index1 @DECI Index1   # Break For Loop now.
   @ENDIF
@Next Index1
@PUSHI dirEntry
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
################################################
# Function ReadCluster(cluster,bufferptr):Buffer
:ReadCluster
@PUSHRETURN
=cluster Var01
=Buffer Var02
=sector Var03
=Index1 Var04
=BufferPtr Var05
#
@PUSHLOCALI  Var01
@PUSHLOCALI  Var02
@PUSHLOCALI  Var03
@PUSHLOCALI  Var04
@PUSHLOCALI  Var05
@POPI Buffer
@POPI cluster
# Calculate Sector    (cluster -2 ) * 4 + FistDataSector
@PUSHI cluster @SUB 2 @RTL @RTL
@ADDI FirstDataSector
@POPI sector
#

#@PRT "ReadCluster Called With Buffer: " @PRTHEXI Buffer @PRT " and Cluster: " @PRTHEXI cluster @PRTNL
#
@MV2V Buffer BufferPtr
@ForIA2V Index1 0 SectorsPerCluster
    @PUSHI sector @ADDI Index1  # sector+index
    @PUSHI BufferPtr
    @CALL ReadSector  @IF_NOTZERO @PRT "Sector Read Error:" @CALL ErrorExit @ENDIF
    @POPNULL
    @PUSHI BytesPerSector
    @ADDI BufferPtr
    @POPI BufferPtr
@Next Index1
@PUSHI Buffer             # Return new filled cluster buffer.
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


################################################
# Function ReadClusterBuffer(cluster):bufferobject (Heap object of bytespercluster*ectorspercluster
:ReadClusterBuffer
@PUSHRETURN
=cluster Var01
=Buffer Var02
=sector Var03
=Index1 Var04
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04

@POPI cluster
#
# Find first sector of the cluster.
@PUSHI cluster
@CALL GetFatAddress   # (cluster): sector
@POPI sector
# create Object of right size
@PUSHI DiskHeapID
@PUSHI BytesPerSector @PUSHI SectorsPerCluster
@CALL MULU
@CALL HeapNewObject
@POPI Buffer     # new object
@DISKSELI ActiveDisk

@PUSHI cluster @PUSHI Buffer
@CALL ReadCluster
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


################################################
# Function WriteBuffer(Sector, dataptr)
#  Writes one Sector to Disk, fixed size of Sector
:WriteBuffer
@PUSHRETURN
=Sector Var01
=dataptr Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
#
@POPI dataptr
@POPI Sector
#

@IF_EQ_AV 0 ActiveDisk
   @PRT "Can not call WriteBuffer before selecting active Disk."
   @PUSH 101 @CALL ErrorExit
@ENDIF
@DISKSELI ActiveDisk
@DISKSEEKI Sector
@DISKWRITEI dataptr
#
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


################################################
# Function WriteCluster(cluster,dataptr)
#   Writes to Cluster data from dataptr, size purely based on sectors per cluster.
:WriteCluster
@PUSHRETURN
=cluster Var01
=dataptr Var02
=sector Var03
=Index1 Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
#
@POPI dataptr
@POPI cluster
#
@PUSHI cluster
@CALL GetFatAddress    # (cluster)
@POPI sector
@ForIA2V Index1 0 SectorsPerCluster
   # WriteBuffer(sector+index, *(data+index*BytesPerSector))
   @PUSHI Index1 @ADDI sector            # sector+index
   @PUSHI Index1 @PUSHI BytesPerSector   # index*BytesPerSector
   @CALL MULU
   @ADDI dataptr
   @CALL WriteBuffer
@Next Index1
#
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET



################################################
# Function GetNextCluster(cluster):newcluster
# Returns value of next cluster index, or -1 if there is no next cluster.
:GetNextCluster
=cluster Var01
=fatsector Var02
=Buffer Var03
=offset Var04
=nextCluster Var05
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
#
@POPI cluster
#
# int fatSector = ReservedSectorsCount + ((cluster * 2) / BytesPerSector)
@PUSHI cluster @RTL  # cluster * 2
@PUSHI BytesPerSector
@CALL DIVU   @SWP @POPI offset  # / BytesPerSector (save MOD value as offset)
@ADDI ReservedSectorsCount
@POPI fatSector
#
# Buffer=ReadSectorBuffer(Disk,fatSector)
@PUSHI ActiveDisk
@PUSHI fatSector
@CALL ReadSectorBuffer
@POPI Buffer
#
@PUSHI Buffer
@ADDI offset
@POPI nextCluster
#
# free buffer from heap
@PUSHI DiskHeapID
@PUSHI Buffer
@CALL HeapDeleteObject
#
@PUSHI nextCluster
@IF_UGT_A 0xfff7
   @POPNULL
   @PUSH -1  # End of File
@ENDIF
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
################################################
# Function AllocateCluster():int
# Allocating a new cluster from Fat table.
:AllocateCluster
@PUSHRETURN
=fatStart Var01
=fatEnd Var02
=sector Var03
=Buffer Var04
=entry Var05
=Index1 Var06
=ExitValue Var07
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
#
# Start and end of FAT Area
@MV2V ReservedSectorsCount fatStart
@PUSHI fatStart @ADDI SectorsPerFat
@POPI fatEnd
#
# for(sector = fatstart; sector < fatend; sector++)
@MA2V -1 ExitValue   # Set default value if no valid cluster can be found.
@ForIV2V sector fatStart fatEnd
    # buffer = ReadSectorBuffer(DiskID,sector)
    @PUSHI ActiveDisk
    @PUSHI sector
    @CALL ReadSectorBuffer
    @POPI Buffer
    #
    # for(i=0;i<BytesPerSector; i += 2)
    @ForIA2V Index1 0 BytesPerSector
        @PUSHI Buffer
        @ADDI Index1
        @PUSHS
        @POPI entry  # entry=&(buffer+i)
        @IF_EQ_AV 0 entry
            # Mark this users as the end of a chain
            @PUSH 0xfff8 @POPII entry
            @PUSHI sector
            @PUSHI Buffer
            @CALL WriteBuffer
            # Remove the un-needed Buffer heap
            @PUSHI DiskHeapID
            @PUSHI Buffer
            @CALL HeapDeleteObject
            # Return the newly allocated cluster number.
            # ((sector - fatStart) * (BytesPerSector/2)) + (Index1/2)
            @PUSHI BytesPerSector @RTR     # (BytesPerSector/2)
            @PUSHI sector @SUBI fatStart   # (sector - fatStart)
            @CALL MULU
            @PUSHI Index1 @RTR             # (Index1/2)
            @ADDS                          # Address of the new cluster
            @POPI ExitValue
            # We need to exit both the inner and outer for loops so set exit values.
            @PUSHI BytesPerSector @SUB 2 @POPI Index1   # Force exit inner for loop
            @PUSHI fatEnd @SUB 1 @POPI sector           # force exit outer for loop
        @ENDIF
    @NextBy Index1 2
@Next sector
@IF_EQ_AV -1 ExitValue
   @PRTLN "No more space in FAT Table. Disk is full."
   @PUSH 101 @CALL ErrorExit
@ENDIF
@PUSHI ExitValue
#
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

################################################
# Function WriteFile(startCluster,data, length)
#   Write a block of memory to a file. Limited to memory size.
:WriteFile
@PUSHRETURN
=startCluster Var01
=data Var02
=length Var03
=currentCluster Var04
=dataPtr Var05
=BytesRemaining Var06
=BytesPerCluster Var07
=nextCluster Var08
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08
#
@POPI length
@POPI data
@POPI startCluster
#
@MV2V startCluster currentCluster
@MV2V length BytesRemaining
@MV2V data dataptr
@PUSHI BytesPerSector
@PUSHI SectorsPerCluster
@CALL MULU
@POPI BytesPerCluster

#
@PUSHI BytesRemaining
@IF_GT_A 0
   @POPNULL
   @PUSH 1
@ELSE
   @POPNULL
   @PUSH 0
@ENDIF
@WHILE_NOTZERO
   @POPNULL
   # Write the currentCluster out.
   @PUSHI currentCluster
   @PUSHI dataPtr
   @CALL WriteCluster  # (currentCluster, dataPtr)
   #
   @PUSHI BytesPerCluster  @ADDI dataPtr
   @POPI dataPtr # dataPtr += BytesPerSector*SectorsPerCluster
   #
   @PUSHI BytesRemaining
   @SUBI BytesPerCluster
   @POPI BytesRemaining
   @PUSHI BytesRemaining
   @IF_GT_A 0         # if BytesRemaining > 0
      PUSHI currentCluster
      @CALL GetNextCluster
      @POPI nextCluster   # nextCluster=GetNextCluster(currentCluster)
      @IF_EQ_AV -1 nextCluster    # End of Chain, allocate a new cluster
          @CALL AllocateCluster
          @IF_EQ_A -1
             @PRTLN "No Space left on device."
             @PUSH 101 @CALL ErrorExit
          @ENDIF
          @POPI nextCluster
          @PUSHI currentCluster
          @PUSHI nextCluster
          @CALL UpdateFatEntry
      @ENDIF
   @ENDIF
   @MV2V nextCluster currentCluster
   @PUSHI BytesRemaining
   @IF_GT_A 0
      @POPNULL
      @PUSH 1
   @ELSE
      @POPNULL
      @PUSH 0
   @ENDIF
@ENDWHILE
@POPNULL
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

################################################
# Function UpdateFatEntry(cluster,nextCluster)
# Modifies and existing FAT entry to point to a new cluster.
:UpdateFatEntry
@PUSHRETURN
=cluster Var01
=nextCluster Var02
=fatSector Var03
=Buffer Var04
=offset Var05
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
#
@POPI nextCluster
@POPI cluster
#
# fatSector = ReservedSectorsCount + ((cluster*2) / BytesPerSector)
@PUSHI cluster @RTL  # (cluster * 2)
@PUSHI BytesPerSector
@CALL DIVU           # (cluser*2)/BytesPerSector)
@SWP @POPI offset    # offset is the MOD of this DIV
@ADDI ReservedSectorsCount
@POPI fatSector
#
@PUSHI ActiveDisk
@PUSHI fatSector
@CALL ReadSectorBuffer
@POPI Buffer     # Buffer = ReadSectorBuffer(Disk,Sector)
#
@PUSHI nextCluster
@PUSHI Buffer
@ADDI offset
@POPS            # mem[buffer+offset]=nextCluster
#
@PUSHI fatSector
@PUSHI Buffer
@CALL WriteBuffer
#
@PUSHI DiskHeapID
@PUSHI Buffer
@CALL HeapDeleteObject
#
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###############################################
# Function GetFileSizeFAT(cluster,&int32Ptr)
# Returns file size in bytes with possiblity of larger files with 32bit math
:GetFileSize
@PUSHRETURN
=cluster Var01
=return32ptr Var02
=BytesPerCluster Var03
=currentCluster Var04
=ClusterCount Var05
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05

#
@POPI return32ptr
@POPI cluster
#
@PUSHI BytesPerSector
@PUSHI SectorsPerCluster
@CALL MULU
@POPI BytesPerCluster
#
@MA2V 1 ClusterCount
#
@MV2V cluster currentCluster
@PUSHI currentCluster
@WHILE_LT_A 0xfff7
   @POPNULL
   @PUSHI currentCluster
   @CALL GetFatAddress
   @POPI currentCluster
   @INCI ClusterCount
   @PUSHI currentCluster
@ENDWHILE
@POPNULL
@INT2LONGVI ClusterCount return32ptr  # Turn 16 bit count into 32b ptr var
@MULWLII BytesPerCluster return32ptr   # ptrvar=BytesPerCluser * ptrvar
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
###############################################
# Function FileSizeInClusters(cluster):int
:FileSizeInClusters
=StartCluster Var01
=IndexCluster Var02
=Count Var03
@PUSHRETURN
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03

#
@POPI StartCluster
@MV2V StartCluster IndexCluster
@MA2V 0 Count
#
@PUSH 1
@WHILE_NOTZERO
   @POPNULL
   @PUSHI IndexCluster
   @CALL GetFatAddress
   @IF_UGT_A 0xfff7   # Handle any non-zero end code
      @POPNULL
      @PUSH 0
   @ENDIF
   @POPI IndexCluster
   @PUSHI IndexCluster
   @INCI Count
@ENDWHILE
@POPNULL
@PUSHI Count
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET



###############################################
# Function ReadFile2Mem(StartCluster,Offset,MaxSize):int(0=success,1=fail)
# Read numbertoread clusters into memory starting from cluster
# If NumToRead is 0, then read entire file to limits of memory.
:ReadFile2Mem
@PUSHRETURN
=StartCluster Var01
=NumToRead Var02
=DestHeapBuffer Var03
=Offset Var04
=CurrentCluster Var05
=MemPtr Var06
=Index1 Var07
=ClusterSize Var08
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08

#
@POPI NumToRead
@POPI Offset
@POPI StartCluster
#
# We need ClusterSize for sizing memory.
@PUSHI BytesPerSector
@PUSHI SectorsPerCluster
@CALL MULU
@POPI ClusterSize

#
@IF_EQ_AV 0 NumToRead
   # Means the whole file, get its size.
   @PUSHI StartCluster
   @CALL FileSizeInClusters
   @DUP
   @POPI NumToRead        # Save it for later loop.
   # If offset is not zero we can subtract it
   @SUBI Offset
   #
   @PUSHI ClusterSize
   @CALL MULU
   # TOS will be size in bytes we need.
   @PUSHI DiskHeapID
   @SWP        # Reverse order.
   @CALL HeapNewObject @IF_ULT_A 100 @PUSH 101 @CALL ErrorExit @ENDIF  # (HeapId, Size)
   @POPI DestHeapBuffer
@ELSE
   @PUSHI NumToRead
   # If a NumToRead was given, then we don't subtract offset because the user should have already done that.
   @PUSHI ClusterSize
   @CALL MULU
   @PUSHI DiskHeapID
   @SWP        # Reverse order.
   @CALL HeapNewObject @IF_ULT_A 100 @PUSH 101 @CALL ErrorExit @ENDIF  # (HeapId, Size)
   @POPI DestHeapBuffer
@ENDIF
#
@MV2V StartCluster CurrentCluster
# Deal with any offset.
@IF_EQ_AV 0 Offset
    # No Offset, no problem.
@ELSE
    # Walk though FAT table for Offset steps.
    @PUSHI Offset
    @WHILE_NOTZERO
       @SUB 1
       @POPI Offset
       @PUSHI CurrentCluster
       @CALL GetFatAddress
       @IF_UGT_A 0xfff7   #Handle any non-zero end of cluster marker.
          @POPNULL
          @PUSH 0
       @ENDIF
       @IF_ZERO
          @PRT "Offset is past end of file:"
          @CALL ErrorExit
       @ENDIF
       @POPI CurrentCluster
       @PUSHI Offset
    @ENDWHILE
    @POPNULL
@ENDIF
#
# now for NumToRead Clusters read file into buffer.
@MV2V DestHeapBuffer MemPtr
@ForIA2V Index1 0 NumToRead
   @PUSHI CurrentCluster
   @PUSHI MemPtr
   @CALL ReadCluster
   @PUSHI MemPtr      # Move MemPtr to next clustersize block.
   @ADDI ClusterSize
   @POPI MemPtr
   @PUSHI CurrentCluster
   @CALL GetFatAddress   # (cluster): sector
   @IF_UGT_A 0xfff7   #Handle any non-zero end of cluster marker.
      @POPNULL
      @PUSH 0
   @ENDIF
   @IF_ZERO
      # Force For Loop to exit early
      @MV2V NumToRead Index1
      @DECI Index1
   @ENDIF
   @POPI CurrentCluster
@Next Index1
@PUSHI DestHeapBuffer
#
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

################################################
# PrintDirEntryInfo(directoryPtr)
# prints the DIR information
# Local String
:PrtDirStrBuff "                 "
:PrintDirEntryInfo
@PUSHRETURN
=DirPtr Var01
=Index1 Var02
=CharCode Var03
=Attribute Var04
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@POPI DirPtr
@PUSH DirAttribOffset @ADDI DirPtr @PUSHS @AND 0xff
@POPI Attribute
@IF_EQ_AV 0xf Attribute
#   @PRTLN "Long FileName Record: Skip"
@ELSE
   @PRT "---------------------------------------\n"
   @PUSHII DirPtr
   @IF_ZERO
      @POPNULL
      @PRT "."
   @ELSE
      @POPNULL
      @PRT "Filename: "
      @ForIA2B Index1 0 8
         @PUSHI Index1 @ADDI DirPtr @PUSHS @AND 0xff
         @POPI PrtDirStrBuff
         @PUSHI PrtDirStrBuff
         @IF_GE_A "!\0" # Valid between ! and z
            @IF_LE_A "z\0"
               @PRTCH PrtDirStrBuff
            @ENDIF
         @ENDIF
         @POPNULL
      @Next Index1
      @PRT "."
      @ForIA2B Index1 8 11
         @PUSHI Index1 @ADDI DirPtr @PUSHS @AND 0xff
         @POPI PrtDirStrBuff
         @PUSHI PrtDirStrBuff
         @IF_GE_A "!\0"
            @IF_LE_A "z\0"
               @PRTCH PrtDirStrBuff
            @ENDIF
         @ENDIF
         @POPNULL
      @Next Index1
      @PRT " Atr:"
      @PUSHI Attribute
      @PUSH 11 @ADDI DirPtr @PUSHS @AND 0xff
      @AND 0x1
      @IF_NOTZERO
         @PRT "RO"
      @ELSE
         @PRT "RW"
      @ENDIF
      @POPNULL
      @PUSHI Attribute
      @AND 0x2
      @IF_NOTZERO @PRT ",H"
      @ENDIF
      @POPNULL
      @PUSHI Attribute      
      @AND 0x4
      @IF_NOTZERO @PRT ",SYS"
      @ENDIF
      @POPNULL
      @PUSHI Attribute            
      @AND 0x8
      @IF_NOTZERO @PRT ",VOL" @ENDIF
      @POPNULL
      @PUSHI Attribute      
      @AND 0x10
      @IF_NOTZERO @PRT ",DIR" @ELSE @PRT ",F"
      @ENDIF
      @POPNULL
      @PUSHI Attribute            
      @AND 0x20
      @IF_NOTZERO @PRT ",ARC" @ENDIF
      @POPNULL
      #
      @PUSH 13 @ADDI DirPtr @PUSHS
      # Call DateTimeFormat(2,data,strptr)
      @PRT " C-Time: "
      @PUSH 2 @SWP
      @PUSH PrtDirStrBuff
      @CALL DateTimeFormat
      @PRTS PrtDirStrBuff @PRTSP
      #
      @PUSH 15 @ADDI DirPtr @PUSHS
      @PRT "C-Date: "
      @PUSH 1 @SWP
      @PUSH PrtDirStrBuff
      @CALL DateTimeFormat
      @PRTS PrtDirStrBuff @PRTSP
      #
      @PUSH 21 @ADDI DirPtr @PUSHS
      @PRT "M-Time: "
      @PUSH 2 @SWP
      @PUSH PrtDirStrBuff
      @CALL DateTimeFormat
      @PRTS PrtDirStrBuff @PRTSP
      #
      @PUSH 13 @ADDI DirPtr @PUSHS
      @PRT "M-Date: "
      @PUSH 1 @SWP
      @PUSH PrtDirStrBuff
      @CALL DateTimeFormat
      @PRTS PrtDirStrBuff @PRTSP      #
      #
      @PUSH 26 @ADDI DirPtr @PUSHS
      @PRT "Cluster: "
      @PRTHEXTOP @PRTSP
      @POPNULL
      #
      @PRT "Length: "
      @PUSHI 28 @ADDI DirPtr @PUSHS
      @PRTHEXTOP
      @POPNULL
      @PUSH 30 @ADDI DirPtr @PUSHS
      @PRTHEXTOP
      @POPNULL
   @ENDIF
@ENDIF
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


#########################
# Function strFormat(val1..valn,strptrin,HeapID):stringout(heap object, delete when done)
# Max n == 9
# Formats a string following rules of strptr
# Rules are similure to printf but not an exact match
# "anyText %FSd AnyText"
#  F=is 'fill' default is space.
#  S=is size or length of field.
#  d is for decimal (0-65535) (other options later)
#  MyHeap require an already initilized heap.
:SFBuffer "          "
:strFormat
@PUSHRETURN
=strptrin Var01
=Index1 Var02
=Char Var03
=VarCount Var04
=ValueArray Var05
=strptrOut Var06
=CharOut Var07
=FillChar Var08
=Size Var09
=MyHeap Var10
=Index2 Var11
#
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@PUSHLOCALI Var04
@PUSHLOCALI Var05
@PUSHLOCALI Var06
@PUSHLOCALI Var07
@PUSHLOCALI Var08
@PUSHLOCALI Var09
@PUSHLOCALI Var10
@PUSHLOCALI Var11
#
# At first we can only pop the two 'things' we are certain about.
@POPI MyHeap
@POPI strptrin
# Count %'s
@MV2V strptrin Char
@MA2V 0 VarCount
@PUSHII Char @AND 0xff
@WHILE_NOTZERO
   @IF_EQ_A "%\0"
      @INCI VarCount
   @ENDIF
   @POPNULL
   @INCI Char
   @PUSHII Char @AND 0xff
@ENDWHILE
@POPNULL
# Create a temporary array to store the values
@PUSHI MyHeap
@PUSHI VarCount @ADD 1 @RTL
@CALL HeapNewObject
@POPI ValueArray
@ForIA2V Index1 0 VarCount
   @PUSHI ValueArray
   # Little math trick here, we are working our way from the Nth index of
   # ValueArray down to 0, so ValueArray Index will have the correct indexes
   @PUSHI VarCount @SUBI Index1 @SUB 1 @RTL
   @ADDS
   @POPS    # Saves VarN
@Next Index1
# Now we are going to need a destination string that is reasonable
# Will linit ourselves to 250 characters.
@PUSHI MyHeap
@PUSH 250
@CALL HeapNewObject
@POPI strptrOut
#
# Start walking though the format string left to right.
@MA2V 0 Index1
@MV2V strptrin Char
@MV2V strptrOut CharOut
@PUSHII Char @AND 0xff
@WHILE_NOTZERO
   @MA2V " \0" FillChar # Default fill is space
   @MA2V 0 Size         # Default field width is 0 which means use what's needed.
   @IF_EQ_A "%\0"
       @INCI Char
       @POPNULL
       @PUSHII Char @AND 0xff
       # Rule is 'Fill' character can not also be a format character like 'd' or 's' or a number
       @IF_EQ_A "d\0"
          # Then its not a fill char
       @ELSE
          @IF_EQ_A "s\0"
             # Then its not a fill character.
          @ELSE
             # Next test is true if < '0' OR > '9' OR will store 0/1 in SFT
             @PUSH 1
             @SWP        # Need test character at TOS and OR flag at SFT
             @IF_LT_A "0\0"
                @SWP
                @POPNULL
                @PUSH 0
                @SWP
             @ENDIF
             @IF_GT_A "9\0"
                @SWP
                @POPNULL
                @PUSH 0
                @SWP
             @ENDIF
             @SWP
             @IF_ZERO
                # If flag is zero, then Character is a Fill character.
                @POPNULL
                @POPI FillChar
                @INCI Char
                @PUSHII Char @AND 0xff
             @ELSE
                @POPNULL        # Not fill character, so drop OR Flag.
             @ENDIF
          @ENDIF
       @ENDIF
       # Now see if there is a number before type code.

       @SWITCH
       @CASE "d\0"
          # No number, just a type code.
          @CBREAK
       @CASE "s\0"
          # No number, just a type code.
          @CBREAK
       @CASE_RANGE "0\0" "9\0"
          # a number between 1-99 is field width
          @SUB "0\0"
          @POPI Size     # First Digit always Replaces Size
          @INCI Char
          @PUSHII Char @AND 0xff
          @IF_GE_A "0\0"
             @IF_LE_A "9\0"
             # Its a second digit, mul first by ten then add.
                @PUSHI Size @RTL  # x2
                @DUP
                @RTL @RTL         # x8
                @ADDS             # x10
                @POPI Size
                @SUB "0\0"
                @ADDI Size
                @POPI Size        # two digits...move Char
                @INCI Char
                @PUSHII Char @AND 0xff
             @ENDIF
          @ENDIF
          @CBREAK
       @CDEFAULT
          @PRT "Not a valid format character: " @PRTTOP @PRTNL
          @CBREAK
       @ENDCASE
       @SWITCH
      # Eventully we may add long ints and other formats, but for now, we'll handly 'd' and 's' only
       @CASE "s\0"
          # Printing a string...or rather a pointer to a string.
          @POPNULL
          @PUSHI Index1 @RTL
          @ADDI ValueArray
          @INCI Index1
          @PUSHS       # Value of String Ptr
          @POPI SFBuffer  # first word in buffer can hold pointer.
          @PUSHI SFBuffer
          @CALL strlen    # Get the length of buffer
          @IF_EQ_AV 0 Size
             # If size is zero we just replace whole string in place.
             @PUSHI CharOut
             @PUSHI SFBuffer   # note, we're using pointers not buffer
             @CALL strcat
             # len value should still be on stack.
             @ADDI CharOut
             @POPI CharOut
          @ELSE
             # Len still on stack
             @IF_LT_V Size
                # This is the case when the field is larger than the string.
                @ForIA2V Index2 0 Size
                   @PUSHI FillChar
                   @PUSHI CharOut
                   @ADDI Index2
                   @POPS
                @Next Index2
                # Now move CharOut to CharOut+Size-Len
                @PUSHI Size
                @ADDI CharOut
                @SWP       # We want (CharOut+Size)-Len not Len-(CharOut+Size)
                @SUBS
                @POPI CharOut
             @ENDIF
             @PUSHI CharOut
             @PUSHI SFBuffer
             @CALL strcpy
             @PUSHI SFBuffer
             @CALL strlen
             @ADDI CharOut
             @POPI CharOut
          @ENDIF
          @CBREAK
       @CASE "d\0"
          # we replace the d with the number based on the formatting rules
          @POPNULL
          @PUSH SFBuffer # Temporary destination buffer for itos
          @PUSHI Index1 @RTL
          @ADDI ValueArray
          @INCI Index1
          @PUSHS    #This puts the selected value
          @PUSH 10  # At this time 'd' means base ten. Future version migh allow 'x'
          @CALL itos
          # Fill from current CharOut to CharOut+Size will FillChar
          @ForIA2V Index2 0 Size
              @PUSHI FillChar
              @PUSHI CharOut
              @ADDI Index2
              @POPS
          @Next Index2

          # Call to strncat(CharOut+(Size-len(SFBuffer),SFBuffer)
          @PUSHI CharOut      # dest string start
          @PUSHI Size         # size-strlen(SFBuffer)
          @PUSH SFBuffer
          @CALL strlen
          @SUBS
          @ADDS              # move dest to Size-Len(SFBuffer)
          @PUSH SFBuffer     # src string
          @CALL strcpy
          # Move CharOut to end of field.
          @PUSHI CharOut
          @ADDI Size
          @POPI CharOut
          @CBREAK
       @CDEFAULT
          @PRT "Not supported format code:"
          @PRTCHS
          @PRTNL
          @CBREAK
      @ENDCASE
   @ELSE
      # Here is for all non %d text
      @POPII CharOut
      @INCI CharOut
   @ENDIF
   @INCI Char
   @PUSHII Char @AND 0xff
@ENDWHILE
@POPNULL
# Get rid of the temporary Array
@PUSHI MyHeap
@PUSHI ValueArray
@CALL HeapDeleteObject
@PUSHI strptrOut
@POPLOCAL Var11
@POPLOCAL Var10
@POPLOCAL Var09
@POPLOCAL Var08
@POPLOCAL Var07
@POPLOCAL Var06
@POPLOCAL Var05
@POPLOCAL Var04
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET

ENDBLOCK



####################### TO Be Written
#
# Core OS Service Calls, modeled after DOS INT calls
#
###########################
# Function LLOpenFile(FileNanemPtr, AccessMode):FileHandle(CF!=0 error)
:LLOpenFile
@PUSHRETURN
=FileNamePtr Var01
=AccessMode Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI AccessMode
@POPI FileNamePtr
#
# Code
#
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
#######################################
# Function LLCloseFile(FileHandle):(CF!=0 error)
:LLCloseFile
@PUSHRETURN
=FileHandle Var01
@PUSHLOCALI Var01
@POPI FileHandle
#
# Code
#
@POPLOCAL Var01
@POPRETURN
#######################################
# Function LLReadFile(FileHandle,BytesToRead):BytesRead (CF!=0 error)
:LLReadFile
@PUSHRETURN
=FileHandle Var01
=BytesToRead Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI BytesToRead
@POPI FileHandle
#
# Code
#
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
#######################################
# Function LLWriteFile(FileHandle,BytesToWrite,BufferPtr):BytesRead (CF!=0 error)
:LLReadFile
@PUSHRETURN
=FileHandle Var01
=BytesToRead Var02
=BufferPtr Var03
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@POPI BufferPtr
@POPI BytesToRead
@POPI FileHandle
#
# Code
#
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
#######################################
# Function LLDeleteFile(FileNamePtr):BytesRead (CF!=0 error)
:LLReadFile
@PUSHRETURN
=FileNamePtr Var01
@PUSHLOCALI Var01
@POPI FileNamePtr
#
# Code
#
@POPLOCAL Var01
@POPRETURN
#######################################
# Function LLMovePointerFile(FileHandle,Offset,Origin)(CF!=0 error)
:LLReadFile
@PUSHRETURN
=FileHandle Var01
=BytesToRead Var02
=BufferPtr Var03
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@POPI BufferPtr
@POPI BytesToRead
@POPI FileHandle
#
# Code
#
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
#######################################
# Function LLFileAttribute(GetSet,FileName,Attribute):Attribute (CF!=0 error)
#             GetSet=(1:Set value, 0: Get Value) Passed Attribute ignored if 'Get'
:LLFileAttribute
@PUSHRETURN
=GetSet Var01
=FileName Var02
=Attribute Var03
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@POPI Attribute
@POPI FileName
@POPI GetSet
#
# Code
#
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#######################################
# Function LLFileRename(OldFileName, NewFileName):(CF!=0 error)
:LLFileRename
@PUSHRETURN
=OldFileName Var01
=NewFileName Var02
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@POPI OldFileName
@POPI NewFileName
#
# Code
#
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET
#####################################################
# Here are the Service functions that LLfunctions will require
#
# Data Structure SystemFileTables
:HeadSystemFileTables 0      #Ptr to first system File table.
=SFTNextItem 0
=SFTActiveFlag 2
=SFTFileTablePtr 4
#######
# DataStructure FileTables
:FileTablesHead 0
=FTDirSector 0                   # Identify What Directory manages this file
=FTDirOffset FTDirSector+2       # Offset within sector
=FTFileSize  FTDirOffset+2       # 32 bit filesize
=FTFilePosition FTFileSize+4     # 32 bit Cursor within file for next read/write
=FTFileCache1 FTFilePosition+4   # Ptr to File IO Cache
=FTFileCache2 FTFileCache1+2     # Ptr to low level (Dir/Fat table) Cache
=FTFatHead FTFileCache2+2        # Startng Fattable entry for first cluster.
=FTFatEntry FTFatHead+2          # Current Fattable entry for active cluster.
=FTTableSize FTFatEntry+2









