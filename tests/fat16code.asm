! Fat16Mod
M Fat16Mod 1
I common.mc
I fat16suport.asm
L string.ld
L heapmgr.ld
L softstack.ld
L lmath.ld
###############################################################
# Common Storage
:Var01 0 :Var02 0 :Var03 0 :Var04 0 :Var05 0 :Var06 0 :Var07 0 :Var08 0
:Var09 0 :Var10 0 :Var11 0 :Var12 0 :Var13 0 :Var14 0 :Var15 0 :Var16 0
#########
# Key Varaibale used by current active Disk.
:MainHeapID 0
:activeDisk -1         # This is set -1 because there a real chance first disk used might be '0'
:bytesPerSector 0
:sectorsPerCluster 0
:reservedSectors 0
:numberofFATs 0
:rootDirEntries 0
:totalSectors16 0
:FATSize16 0
:rootDirStartSector 0
:totalClusters 0
:rootDirSize 0
:rootDirSizeInSectors 0
:FATSizeInSectors 0
:dataAreaStartSector 0
:totalDataSectors 0
:clusterSize 0
:FATSizeInBytes 0
:ClusterMask 0
:RecordMark "\n\0"        # Default is newline could be possibly changed.

M CheckRequire \
  @IF_EQ_AV 0 MainHeapID \
     @PRT "Error: Heap Not defined. Run initdisk first\n" \
     @END \
  @ENDIF


################## Fat 16 core functions
################################################################
# Function initdisk(HeapID)
# Setups system for handeling memory requirements for FS
:initdisk
@SWP
@POPI MainHeapID
# Zero the key varaibles so no left over from previous set.
@MA2V -1 activeDisk
@MA2V 0 bytesPerSector
@MA2V 0 sectorsPerCluster
@MA2V 0 reservedSectors
@MA2V 0 numberofFATs
@MA2V 0 rootDirEntries
@MA2V 0 totalSectors16
@MA2V 0 FATSize16                # Number of Sectors in single Fat table.
@MA2V 0 rootDirStartSector
@MA2V 0 totalClusters
@MA2V 0 FATSizeInSectors         # Size All the  FAT tables in number of Sectors.
@MA2V 0 dataAreaStartSector
@MA2V 0 totalDataSectors
@MA2V 0 clusterSize
@MA2V 0 FATSizeInBytes

@RET



################################################################
# Function readBootRecord(diskID)
# This will set the 'global' constants  for the current Disk.
# If multiple files on diffrent disks are open, then when ever
# the alternative disk is refrenced, another readBootRecord will be needed.
:readBootRecord
@PUSHRETURN
@LocalVar InDiskID 01
@LocalVar InBuffer 02
#
# Structures we are reading/generating from boot record:
#
#  bytesPerSector   |  sectoresPerCluster       |  reservedSectors     |
#  numberofFATs     |  rootDirEntries           |  totalSectors16      |
#  FATSize16        |                           |  totalClusters       |
#  rootDirSize      |  rootDirSizeInSectors     |  dataAreaStartSector |
#  FATSizeInSectors |  rootDirStartSector       |  totalDataSectors    |
#  clusterSize      |  FATSizeInBytes
#

@POPI InDiskID
#
@CheckRequire
#
@IF_EQ_VV InDiskID activeDisk
   # No Need to reload if its already the active disk
@ELSE
   @PUSHI MainHeapID
   @PUSH 512
   @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 87" @POPNULL @END @ENDIF
   @POPI InBuffer
   #
   @DISKSELI InDiskID
   @DISKSEEK 0
   @DISKREADI InBuffer
   #
   # Set the required globals from that buffer data.
   @PUSHI InBuffer @ADD BRofsbytesPerSector @PUSHS @POPI bytesPerSector
   @PUSHI InBuffer @ADD BRofssectorsPerCluster @PUSHS @AND 0xff @POPI sectorsPerCluster
   @PUSHI InBuffer @ADD BRofsreservedSectors @PUSHS @POPI reservedSectors
   @PUSHI InBuffer @ADD BRofsnumberOfFATs @PUSHS @AND 0xff @POPI numberofFATs
   @PUSHI InBuffer @ADD BRofsrootDirEntries @PUSHS @POPI rootDirEntries
   @PUSHI InBuffer @ADD BRofstotalSectors16 @PUSHS @POPI totalSectors16
   @PUSHI InBuffer @ADD BRofsFATSize16 @PUSHS @POPI FATSize16
   #
   # Calculated fields
   
   # totalClusters=(totalSectors - reservedSectors - FATSizeInSectors)/sectorsPerCluster
   @PUSHI totalSectors16 @SUBI reservedSectors @SUBI FATSizeInSectors
   @PUSHI sectorsPerCluster @CALL DIVU 
   @POPI totalClusters @POPNULL

   # rootDirSize=(rootDirEntries * 32)/bytesPerSector
   @PUSHI rootDirEntries @SHL @SHL @SHL @SHL @SHL  # X 32
   @POPI rootDirSize
   @PUSHI rootDirSize
   @PUSHI bytesPerSector @CALL DIVU @POPI rootDirSizeInSectors @POPNULL

   # dataAreaStartSector = reservedSectors+(numberofFATs*FATSize16)+rootDirSize
   
   @IF_EQ_AV 2 numberofFATs
       # Most of the time, it will be '2' so just use ADD twice
       @PUSHI reservedSectors @ADDI FATSize16 @ADDI FATSize16 @ADDI rootDirSizeInSectors
   @ELSE
       # In rare case it something else, use MUL
       @PUSHI reservedSectors @ADDI FATSize16 @PUSH 2 @CALL MULU  @ADDI rootDirSizeInSectors
   @ENDIF
   @POPI dataAreaStartSector

   # FATSizeInSectors
   @PUSHI numberofFATs @PUSHI FATSize16 @CALL MULU @POPI FATSizeInSectors

   # rootDirStartSector
   
   @PUSHI FATSizeInSectors  @ADDI reservedSectors 
   @POPI rootDirStartSector



   # totalDataSectors = totalSectors16 - reservedSectors - FATSizeInSectors - rootDirSizeInSectors
   @PUSHI totalSectors16 @SUBI reservedSectors @SUBI FATSizeInSectors @SUBI rootDirSizeInSectors
   @POPI totalDataSectors

   # clusterSize = bytesPerSector * sectorsPerCluster
   @PUSHI bytesPerSector @PUSHI sectorsPerCluster @CALL MULU @POPI clusterSize

   # FATSizeInBytes = FATSize16 * bytesPerSector
   @PUSHI FATSize16 @PUSHI bytesPerSector @CALL MULU @POPI FATSizeInBytes

   #
   #
   @MV2V InDiskID activeDisk
   @PUSHI MainHeapID
   @PUSHI InBuffer
   @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 148:" @END @ENDIF
   @POPNULL
   #
   # Setup ClusterMask for IDing what sectors are part of a cluster
   @PUSHI sectorsPerCluster
   @SWITCH
      @CASE 2
         @MA2V 1 ClusterMask
         @CBREAK
      @CASE 4
         @MA2V 3 ClusterMask
         @CBREAK
      @CASE 8
         @MA2V 7 ClusterMask
         @CBREAK
      @CASE 16
         @MA2V 15 ClusterMask
         @CBREAK
      @CASE 32
         @MA2V 31 ClusterMask
         @CBREAK
      @CDEFAULT
         @MA2V 0 ClusterMask
         @CBREAK
   @ENDCASE
   @POPNULL
@ENDIF
# M DebugPrint 1

? DebugPrint
@PRT " bytesPerSector = " @PRTHEXI  bytesPerSector @PRTNL
@PRT " sectorsPerCluster = " @PRTHEXI  sectorsPerCluster @PRTNL
@PRT " reservedSectors = " @PRTHEXI  reservedSectors @PRTNL
@PRT " numberofFATs = " @PRTHEXI  numberofFATs @PRTNL
@PRT " rootDirEntries = " @PRTHEXI  rootDirEntries @PRTNL
@PRT " totalSectors16 = " @PRTHEXI  totalSectors16 @PRTNL
@PRT " FATSize16 = " @PRTHEXI  FATSize16 @PRTNL
@PRT " rootDirStartSector = " @PRTHEXI  rootDirStartSector @PRTNL
@PRT " totalClusters  = " @PRTHEXI  totalClusters @PRTNL
@PRT " rootDirSize(bytes) = " @PRTHEXI  rootDirSize @PRTNL
@PRT " rootDirSizeInSectors = " @PRTHEXI  rootDirSizeInSectors  @PRTNL
@PRT " dataAreaStartSector = " @PRTHEXI  dataAreaStartSector @PRTNL
@PRT " FATSizeInSectors = " @PRTHEXI  FATSizeInSectors @PRTNL
@PRT " totalDataSectors = " @PRTHEXI  totalDataSectors @PRTNL
@PRT " clusterSize = " @PRTHEXI  clusterSize @PRTNL
@PRT " FATSizeInBytes = " @PRTHEXI  FATSizeInBytes @PRTNL
ENDBLOCK
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#######################################################
# Function ParsePath(filepath, DiskID):fp
# Functon that builds a File Pointer FP
:ParsePath
@PUSHRETURN
@LocalVar InFilePath 01
@LocalVar DiskID 02
@LocalVar currentSector 03
@LocalVar components 04
@LocalVar numComponents 05
@LocalVar Index1 06
@LocalVar Entry 07
@LocalVar FP 08
@LocalVar Index2 09
@LocalVar DirSector 10
@LocalVar EntryOffset 11
#
@POPI DiskID
@POPI InFilePath

#
@MV2V rootDirStartSector currentSector
#@MA2V 0 currentSector              # We are starting at 'Root' Directory. But later lets allow a CWD concept.
#
@PUSHI InFilePath
@CALL strUpCase      # Changes filePath to be just uppercase
@PUSHI InFilePath
@CALL SplitPath     # Split string filepath into array of string ptrs, return both number of entrys and the array
@POPI numComponents
@POPI components
#
@ForIA2V Index1 0 numComponents
   @PUSHI currentSector
   @PUSHI components @PUSHI Index1 @SHL @ADDS @PUSHS  # put string ptr at array[index] on stack
   @PUSHI DiskID
   @CALL findEntryInDirectory  # (currentSector, compoents[index], diskid)   
   @IF_ZERO
      @PRT "No File Exact Match: State:" @PRTI Index1 @PRT " of " @PRTI numComponents @PRTNL
      # No filename matched.
      @POPNULL
      @MA2V 0 FP
      @FORBREAK
   @ELSE
      # The return is a pointer to an in memory version of the Directory Entry
      @POPI EntryOffset
      @POPI DirSector
      @POPI Entry
      @PUSHI Entry
      @ADD DSofsAttributes @PUSHS @AND 0xff
      # bit mask 0x10 is directory flag
      @AND 0x10
      @IF_NOTZERO
         # Is a Directory. Move down into it.
         @PRT "Directory Name: State:" @PRTI Index1 @PRT " of " @PRTI numComponents @PRTNL         
         @POPNULL
         @PUSHI Entry  @ADD DSofsStartCluster @PUSHS
         @CALL Cluster2Sector
         @POPI currentSector
      @ELSE
         # Found a file. Create a new FP structure
      @PRT "File Matched: State:" @PRTI Index1 @PRT " of " @PRTI numComponents @PRTNL         
         @POPNULL
         @PUSHI MainHeapID
         @PUSH FPofsSize
         @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 236:" @PRTHEXTOP @POPNULL @END @ENDIF
         @POPI FP
         @ForIA2B Index2 0 FPofsSize         # Zero out the FP structure.
            @PUSH 0
            @PUSHI FP @ADDI Index2
            @POPS
         @NextBy Index2 2
         # We need to go though the FP Structure and fill out the fields.
         # We'll use these macros.
      # SetFPConst FPofsOFFSET Constant
         M SetFPConst @PUSH %2 @PUSHI FP @ADD %1 @POPS
      # SetFPEntry FPofsOFFSET ENTRY[offset]
         M SetFPEntry @PUSHI Entry @ADD %2 @PUSHS @PUSHI FP @ADD %1 @POPS
      # SetFPVarI FPofsOFFSET MEM[variable]
         M SetFPVarI @PUSHI %2 @PUSHI FP @ADD %1 @POPS
      # SetFPSVal FPofsOFFSET    < TOS saved to offset >
         M SetFPSVal @PUSHI FP @ADD %1 @POPS              # This is like SetFPVarI but for TOS as value.
         #         
         # Store the current DiskID with the FP so we can do disk to disk copies
         @SetFPVarI FPofsDiskID DiskID
         #
         #
         #  Get the size, which is 2 words
         @SetFPEntry FPofsFileSize DSofsFileSize
         @SetFPEntry FPofsFileSize+2 DSofsFileSize+2
         #
         # Current Sector, start with First Sector.
         @PUSHI Entry @ADD DSofsStartCluster @PUSHS
         @CALL Cluster2Sector
         @SetFPSVal FPofsCurrentSector
         #
         # Offset for latest read/write will always start as zero
         @SetFPConst FPofsCurrentOffset 0
         # current sector by itself only gives us the physical Disk info of the sector
         # we also need to know its relative location in the logical file.
         @SetFPConst FPofsLogicSector 0
         #
         # At first First Sector and Current will be the same
         @PUSHI FP @ADD FPofsCurrentSector @PUSHS
         @DUP
         @SetFPSVal FPofsFirstSector
         @SetFPSVal FPofsCurrentSector
         #
         # Now save the Sector number and offset for this Directory Record.
         @SetFPVarI FPofsDirRecSector DirSector
         @SetFPVarI FPofsDirRecOffset EntryOffset
         # Mark the FP buffer as stale so we'll know to read it.
         @SetFPConst FPofsState -1
         #
         @PUSHI FP @CALL FPrintFPInfo
         @PUSHI FP
      @ENDIF
      # No longer need Entry, clean it up
      @PUSHI MainHeapID
      @PUSHI Entry
      @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 301" @END @ENDIF
      @POPNULL
   @ENDIF
@Next Index1
# clean up the components array.
@PUSHI components
@PUSHI MainHeapID
@CALL SplitDelete

@RestoreVar 11
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
###############################################################
# Function findEntryInDirectory(currentSector,FileName, DiskID) [Entry, Sector, Offset] | 0 for EOL
# Scans the current clusters directory entries for matching FileName
:findEntryInDirectory
@PUSHRETURN
@LocalVar currentSector 01     #
@LocalVar FileName 02
@LocalVar InDiskID 03
@LocalVar SectorCnt 04
@LocalVar StartSector 05
@LocalVar Buffer 06
@LocalVar Entry 07
@LocalVar EntryOffset 08
@LocalVar ActSector 09
@LocalVar RetDirCopy 10
@LocalVar IsRoot 11
@LocalVar FNAttribute 12
@LocalVar ReturnCode 13
@LocalVar ResultOffset 14
#
#
@POPI InDiskID
@POPI FileName
@POPI currentSector
#
@MA2V 0 EntryOffset
##@PRTLN "Buffer: " @PUSHI MainHeapID @CALL HeapListMap
@PUSHI MainHeapID
@PUSH 512
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 297" @POPNULL @END @ENDIF
@POPI Buffer
#
@PUSHI InDiskID
@CALL readBootRecord
#
@MV2V currentSector StartSector
@MA2V 0 SectorCnt        # This matters with Sub-Dir's as we keep track of clusters
#
# Before We start Loop, get the first sector.
#
@PUSHI StartSector @POPI ActSector
@DISKSEEKI ActSector
@DISKREADI Buffer
#
# We have a couple of ending condtions for FileName server.
# And they can very if we are in the Root directory vs a sub-directory So set IsRoot for if ActSector < dataArea
@PUSHI ActSector
@IF_LT_V dataAreaStartSector
   @MA2V 1 IsRoot
@ELSE
   @MA2V 0 IsRoot
@ENDIF
@POPNULL
#
#
   # We have two loops,
   #  Outer is reading sectors until we have none left in this Dir
   #  Inner on is testing each DIR entry in the current sector.
   # Our exit contions are:
   #    We reach an END of DIR mark.   Exit 1
   #    We find a match                Exit 2
   #    We ran out of valid Sectors    Exit 3
   #         If root dir, thats limited by 'rootDirEntries'
   #         If non-root, we're looking for a FAT entry that > 0xfff0
@MA2V 0 ReturnCode
@PUSH 0
@WHILE_ZERO
   @POPNULL
   @MA2V 0 EntryOffset
   @PUSHI EntryOffset
   @WHILE_LT_V bytesPerSector
      @POPNULL
      @PUSHI EntryOffset      
      @ADDI Buffer
      @POPI Entry                # Entry points to the 32 byte 'field' inside sector for DIR Entry
      @PUSHI Entry @ADD DSofsAttributes @PUSHS @AND 0xff        # Get Attribute Byte.
      @POPI FNAttribute
      @IF_EQ_AV 0 FNAttribute
         # End of Directory List
         @MA2V 1 ReturnCode                   # Reached end of DIR listing without a match.
         @MV2V bytesPerSector EntryOffset     # Break the inner while loop
      @ELSE
        @PUSHI FNAttribute @AND 0x8
        @IF_NOTZERO
           @POPNULL               # Is a DISK Lable, skip it.
        @ELSE
           @POPNULL
           @PUSHI FNAttribute @AND 0x0f
           @IF_NOTZERO
              @POPNULL            # Is a long filename entry, skip it.
           @ELSE
              @POPNULL
              # Its a basic FileName, so lets run tests.
              @PUSHI FileName
              @PUSHI Entry @ADD DSofsFilename
              @CALL compareFileNames
              @IF_ZERO
                 @POPNULL                 
                 @PUSHI Entry @PUSH 32 @CALL HexDump
                 # Exact match.
                 # Creata a new buffer to be a copy of the entry.
                 @MA2V 2 ReturnCode                   # Found a valid match
                 @MV2V EntryOffset ResultOffset
                 @MV2V bytesPerSector EntryOffset     # Break the inner while loop
              @ELSE
                 # FileNames do not match, skip to next one.
                 @POPNULL
              @ENDIF
           @ENDIF
        @ENDIF
      @ENDIF
      @IF_EQ_AV 0 ReturnCode
          @PUSHI EntryOffset @ADD 32 @POPI EntryOffset      # Move to next entry in buffer,also breaks inner while.
      @ENDIF
      @PUSHI EntryOffset
   @ENDWHILE
   @POPNULL
   #
   # If ReturnCode is still zero, then we had no match, and end of DIR lists wasn't in that buffer.
   #
   @IF_EQ_AV 0 ReturnCode
     # Need to try the next Sector. But getting next sector is diffrent for Root vs Sub-Directory
     @IF_EQ_AV 0 IsRoot
        @INCI SectorCnt
        @IF_EQ_AV 0 ClusterMask      # We need this option for 'odd' sized Clusters
           @PUSHI SectorCnt @PUSHI sectorsPerCluster
           @CALL DIVU
           @POPNULL   # We only want the MOD value
        @ELSE
           @PUSHI SectorCnt @ANDI ClusterMask
        @ENDIF
        @IF_ZERO
           # If MOD or Mask == 0 then time for new Fat table entry
           @POPNULL
           # Create a temporary FAT buffer
           @PUSHI MainHeapID
           @PUSHI bytesPerSector
           @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1340" @POPNULL @END @ENDIF
           @POPI FatBuffer
           @PUSHI SearchSector @SUB 1 # We need to reverse the INC because we need ClusterID of previous Sector
           @CALL Sector2Cluster
           @POPI CurrentCluster
           @PUSHI CurrentCluster
           @SHR @SHR @SHR @SHR @SHR @SHR @SHR @SHR # >> 8 or /256
           @ADDI reservedSectors
           @POPI FatSector
           @DISKSEEKI FatSector
           @DISKREADI FatBuffer
           # have in mem right Fat Sector, now find index within sector
           @PUSHI CurrentCluster @SHL
        @ENDIF
      @IF_EQ_AV 512 bytesPerSector
         # We'll nearly always be dealing with 512 byte sectors
         @AND 0x1ff
      @ELSE
         # On the rare chance it's not, this will handle those cases.
         @PUSHI bytesPerSector
         @CALL MULU
         @POPNULL        # We only need the MOD value
      @ENDIF
      @POPI FatOffset
      @PUSHI FatBuffer @ADDI FatOffset
      @PUSHS            # Save result on Stack
      # Now clear out the unneeded FAT buffer
      @PUSHI MainHeapID
      @PUSHI FatBuffer
      @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 1370: " @PRTTOP @END @ENDIF
      @POPNULL
      # It is a subdirectory so use the FAT tables to find next cluster.
      @PUSHI ActSector @CALL GetNextPossableSector
      @IF_UGE_A 0xfff0        # This code means end of Cluster chain.
         @POPNULL
         @MA2V 3 ReturnCode        # End of valid sectors.
      @ELSE
         @POPI ActSector            # Just read the next valid sector.
         @DISKSEEKI ActSector
         @DISKREADI Buffer
      @ENDIF
      @ELSE
        # It is the ROOT directory, so we continue until ActSector - rootDirStartSector < rootDirSizeInSectors
        @INCI ActSector
        @PUSHI ActSector @SUBI rootDirStartSector
        @IF_LT_V rootDirSizeInSectors
            # Still a valid Sector
            @DISKSEEKI ActSector
            @DISKREADI Buffer
        @ELSE
            @MA2V 3 ReturnCode         # Reached end of Root DIR
        @ENDIF
     @ENDIF
   @ENDIF
   @PUSHI ReturnCode                   # If this is still zero, then continue the search.
@ENDWHILE
@POPNULL
@IF_EQ_AV 2 ReturnCode
    @PUSHI MainHeapID
    @PUSH DSofsSize
    @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 436" @POPNULL @END @ENDIF
    @POPI RetDirCopy
    @PUSHI RetDirCopy @PUSHI Entry @PUSH DSofsSize
    @CALL memcpy
    @PUSHI RetDirCopy @PUSH 32 @CALL HexDump    
@ENDIF

#
# Reached the End, Clean up buffer.
@PUSHI MainHeapID
@PUSHI Buffer
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 368" @POPNULL @END @ENDIF
@POPNULL
# Now we have two types of return results
# Zero by itself means 'no match'
# Otherwise we return 3 words
#        RetDirCopy     Heap Copy of Dir Entry Data
#        ActSector      What disk sector the Entry is in.
#        EntryOffset    Where in that sector it is.
@IF_EQ_AV 2 ReturnCode
    # Valid FileName
    @PUSHI RetDirCopy
    @PUSHI ActSector
    @PUSHI ResultOffset
@ELSE
    @PUSH 0
@ENDIF

@RestoreVar 14
@RestoreVar 13
@RestoreVar 12
@RestoreVar 11
@RestoreVar 10
@RestoreVar 09
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

#####################################################
# Function compareFileNames(FileZ1, FileSP1)
# Compares  Files looking for a match
# inbound FileZ1 is null terminated string
# inbound FileSP1 is a space filled 11 byte string.
:compareFileNames
@PUSHRETURN
@LocalVar FileZ1 01
@LocalVar FileSP1 02
@LocalVar FileSP2 03
@LocalVar Index1 04
@LocalVar Heapinfo 05
@POPI FileSP1
@POPI FileZ1
@PUSHI FileZ1
@CALL str2filename

@POPI FileSP2
@MV2V FileSP2 Heapinfo
@PUSH 0
@ForIA2B Index1 0 11
   @PUSHII FileSP1 @AND 0xff
   @PUSHII FileSP2 @AND 0xff
   @CMPS
   @IF_ZFLAG
   @ELSE
      @POPNULL @POPNULL
      @POPNULL
      @PUSH 1
      @FORBREAK
   @ENDIF
   @POPNULL @POPNULL
   @INCI FileSP1
   @INCI FileSP2
@Next Index1

# The Result of 1 or zero will be TOS
@PUSHI MainHeapID @PUSHI Heapinfo
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 440: " @PRTTOP @END @ENDIF


@POPNULL
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


#####################################################
# Function str2filename(FilePart):Heap Object 12 byte space padded FileName format
:str2filename
@PUSHRETURN
@LocalVar FilePart 01
@LocalVar OutputStr 02
@LocalVar Index1 03
#
@POPI FilePart
#
@PUSHI MainHeapID
@PUSH 12
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 462" @POPNULL @END @ENDIF
@POPI OutputStr
#
@MA2V 0 Index1
@PUSHI Index1
# There's a few layers to this loop so to explain.
# Will loop over the fixed lenth of the 8.3 or 11 character space
# If index < 8, we will copy InFilePart changing to spaces when we hit either '.' or null
# else  skip forward if on '.' and repeat same logic about spaces for the Extention part.
@WHILE_LT_A 11
   @IF_ULT_A 8         # Deal with FILE part
      @PUSHII FilePart @AND 0xff
      @IF_EQ_A ".\0"      # File part terminates on '.' or null or length
         @POPNULL
         @PUSH 0          # Set it to zero so space padding will fill out rest of File Part
      @ENDIF
      @IF_ZERO
         @POPNULL
         @PUSH " \0"
      @ELSE
         @INCI FilePart
      @ENDIF
      @PUSHI OutputStr
      @ADDI Index1
      @POPS               # This also effectivly pops off the TOS character.
   @ELSE
      @PUSHII  FilePart @AND 0xff 
      @IF_EQ_A ".\0"      # File Part had been terminated by '.' so inc.
         @POPNULL
         @INCI FilePart   # Move past the '.'
         @SUB 1           # Because we are not moving, don't move insert point either.
         # Skip rest of block, because there no reason to save '.' anywhere.
      @ELSE
         @IF_ZERO           # Ext part only terminates on null or length
            @POPNULL
            @PUSH " \0"
         @ELSE
            @INCI FilePart
         @ENDIF
         @PUSHI OutputStr
         @ADDI Index1
         @POPS
      @ENDIF
   @ENDIF
   @ADD 1
   @POPI Index1
   @PUSHI Index1
@ENDWHILE
@POPNULL
@PUSHI OutputStr
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

      

   

#####################################################
# Function SplitPath(filepath):(outarray, numentries)
# Local String
:Divider "/\0"
:SplitPath
@PUSHRETURN
@LocalVar InFilePath 01
@POPI InFilePath

#
@PUSHI InFilePath
@PUSH Divider
@PUSHI MainHeapID
@CALL splitstr

@RestoreVar 01
@POPRETURN
@RET
   
#################################################
# Function HexDump(address, length)
:HexDump
@PUSHRETURN
@LocalVar Start 01
@LocalVar Length 02
@LocalVar Index01 03
@LocalVar ColumnCnt 04

@POPI Length
@POPI Start
@PRTLN "ADDR:-0-1-2-3 -4-5-6-7 -8-9-A-B -C-D-E-F"
@MV2V Start Index01
#
@PUSHI Index01
M NibbleHexS @ADD "0\0" @IF_GT_A "9\0" @ADD 7 @ENDIF @PRTCHS
@WHILE_NOTZERO
   @POPNULL
   @PRTHEXI Index01 @PRT ":"
   @MA2V 0 ColumnCnt
   @PUSHI ColumnCnt                   # (
   @WHILE_ULT_A 16
      @POPNULL                        # )
      @PUSHI Index01 @ADDI ColumnCnt @PUSHS @AND 0xff
      @DUP                            # 
      @SHR @SHR @SHR @SHR  # >> 4
      #
      @NibbleHexS
      @POPNULL
      @AND 0x0f
      @NibbleHexS
      @POPNULL
      #
      @PUSHI ColumnCnt
      @SWITCH
      @CASE 3
         @PRTSP
         @CBREAK
      @CASE 7
         @PRTSP
         @CBREAK
      @CASE 11
         @PRTSP
         @CBREAK
      @CDEFAULT
         @CBREAK
      @ENDCASE
      @ADD 1 @POPI ColumnCnt      
      @PUSHI ColumnCnt
   @ENDWHILE
   @POPNULL
   @PRT "    "
   @MA2V 0 ColumnCnt
   @PUSHI ColumnCnt
   @WHILE_ULT_A 16
        @POPNULL
        @PUSHI Index01 @ADDI ColumnCnt @PUSHS @AND 0xff
        @IF_GE_A "0\0"
           @IF_LE_A "z\0"
               @PRTCHS
               @POPNULL
               @PUSH 0
           @ELSE
               @PRT "+"
           @ENDIF
        @ELSE
           @PRT "-"
        @ENDIF
        @POPNULL
        @INCI ColumnCnt
        @PUSHI ColumnCnt
   @ENDWHILE
   @POPNULL
   @PRTNL
   @PUSHI Index01 @ADD 16 @POPI Index01
   @PUSHI Start @ADDI Length
   @IF_LE_V Index01
      # Time to exit loop
      @POPNULL
      @PUSH 0
   @ELSE
      @POPNULL
      @PUSH 1
   @ENDIF
@ENDWHILE
@POPNULL
#@DEBUGTOGGLE
#
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

#######################################################
# Function FPrintFPInfo
:FPrintFPInfo
@PUSHRETURN
@LocalVar InFP 01
@POPI InFP

@PRT "--------------------------------------------------------\n"
@PRT "|         File Pointer: " @PRTHEXI InFP @PRT "\t\t\t\t|\n"
@PRT "--------------------------------------------------------\n"
@PRT "| FPofsFileSize: " @PUSHI InFP @ADD FPofsFileSize @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t\t|\n"
@PRT "| FPofsCurrentSector: " @PUSHI InFP @ADD FPofsCurrentSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsCurrentOffset: " @PUSHI InFP @ADD FPofsCurrentOffset @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsFirstSector: " @PUSHI InFP @ADD FPofsFirstSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsDirRecSector: " @PUSHI InFP @ADD FPofsDirRecSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsDirRecOffset: " @PUSHI InFP @ADD FPofsDirRecOffset @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsLogicSector: " @PUSHI InFP @ADD FPofsLogicSector @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t|\n"
@PRT "| FPofsDiskID: " @PUSHI InFP @ADD FPofsDiskID @PUSHS @PRTHEXTOP @POPNULL @PRT "\t\t\t\t\t|\n"
@PRT "|-------------------------------------------------------|\n"
@RestoreVar 01
@POPRETURN
@RET


####################################################
# Function GetNextPossableSector(InSector)
# Use logic about sectors and Fat table to return next sector.
:GetNextPossableSector
@PUSHRETURN
@LocalVar InSector 01
@LocalVar TempBuffer 02
@LocalVar SpotInCluster 03
@POPI InSector
#
@PUSHI sectorsPerCluster
@CASE 2
    @POPNULL
    @PUSHI InSector @ADD 1
    @AND 0x1
    @POPI SpotInCluster
   
@CASE 4
    @POPNULL
    @PUSHI InSector @ADD 1
    @AND 0x3
    @POPI SpotInCluster
    @CBREAK
@CASE 8
    @POPNULL
    @PUSHI InSector @ADD 1
    @AND 0x7
    @POPI SpotInCluster
    @CBREAK
@CASE 16
    @POPNULL
    @PUSHI InSector @ADD 1
    @AND 0xf
    @POPI SpotInCluster
    @CBREAK
@CDEFAULT
    @POPNULL
    @PUSHI InSector
    @PUSHI sectorsPerCluster
    @CALL DIVU
    @POPNULL
    @POPI SpotInCluster
    @CBREAK
@ENDCASE
@IF_EQ_AV 0 SpotInCluster
    # Try to Fetch FAT Table entry.
    @PUSHI InSector
    @CALL Sector2Cluster         # This will turn InSector into its matching Cluster Number
    @CALL Cluster2Sector         # This will check the FAT table and return the new Cluster for next 1st Sector
@ELSE
    # For cases where we are still inside the range of sectors in a cluster, so just jump to next sector.
    @PUSHI InSector
    @ADD 1
@ENDIF
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET

  


####################################################
# Function Sector2Cluster(sectorid):cluster
:Sector2Cluster
@PUSHRETURN
@LocalVar SectorIn 01
@POPI SectorIn

# FirstDataSector = reservedSectors+(2*FATSize)+rootDirSizeInSectors
# NewClusterID = ( SectorIn - FirstDataSector) >> 2) + 2
@PUSHI FATSize16 @SHL               
@ADDI rootDirSizeInSectors          
@ADDI reservedSectors                # == FirstDataSector
@PUSHI SectorIn
@SWP @SUBS                           # (SectorID - FirstDatSector)
@SHR @SHR                            # /2
@ADD 2                               # Clusters start at 2 in FAT16
@RestoreVar 01
@POPRETURN
@RET

####################################################
# Function Cluster2Sector(clusterid)
# Given a particular Cluster number, returns the first sector in that cluster.
# Assumes 'current disk'
:Cluster2Sector
@PUSHRETURN
@LocalVar InClusterID 01
@POPI InClusterID
@DEC2I InClusterID         # Skip 2 because cluster 0 and 1 are not part of table
@PUSHI InClusterID
@SHL @SHL                  # X 2
@ADDI dataAreaStartSector
@RestoreVar 01
@POPRETURN
@RET

####################################################
# Function F32to16(In32Ptr):[sectorcount,Offset]
# Takes a ptr to a 32 bit FileSize/FilePostion and returns what sectorcount, offset as two 16 bit numbers
:F32to16
@PUSHRETURN
@LocalVar In32Ptr 01
@LocalVar OutSectCount 02
@LocalVar OutOffset 03
@LocalVar In32PtrHigh 04

@DUP
@POPI In32Ptr
#
@ADD 2 @POPI In32PtrHigh
#
# Get the lowest 9 bit (0-511) offset.
@PUSHII In32Ptr
@AND 0x1ff
@POPI OutOffset
#
@PUSHII In32Ptr @POPI F36LWLB
@PUSHII In32PtrHigh @POPI F36HWLB
#
# The 15 bits that start at F32LWHB and go through F32HWLB need to be shifted Right one bit
@PUSHI F36LWHB
@SHR
@POPI OutSectCount
# This 16th bit comes from what was the 1st bit on F36HWHB
@PUSHI F36HWHB @AND 0x1
@IF_NOTZERO
   @POPNULL
   @PUSH 0x8000           # Set Just the highest bit.
   @ORI OutSectCount
   @POPI OutSectCount
@ELSE
   @POPNULL
@ENDIF
# Now return both values.
@PUSHI OutSectCount
@PUSHI OutOffset
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET





# Field Formated Stroage to allow 8 bit 'shifts'
:F36LWLB $$0
:F36LWHB $$0
:F36HWLB $$0
:F36HWHB $$0



###############################################
# Function ReadSectorWorker1(FP,LogicIndex):HWSector
# Support function that does some of the 'hard' work
# of figuring out what HW sector maps to a given LogicalSector
:ReadSectorWorker1
@PUSHRETURN
@LocalVar FP 01
@LocalVar LogicIndex 02
@LocalVar SearchPoint 03
@LocalVar SearchSector 04
@LocalVar FatBuffer 05
@LocalVar FatSector 06
@LocalVar FatOffset 07
@LocalVar CurrentCluster 08
#
@POPI LogicIndex
@POPI FP
#
# Get the last used LogicSector value.
#@PRT "Requested Logic Sector is: " @PRTHEXI LogicIndex @PRTNL
@PUSHI FP @ADD FPofsLogicSector @PUSHS
@POPI SearchPoint

@MA2V 0 SearchPoint               # In logical sector units
@PUSHI FP @ADD FPofsFirstSector @PUSHS
@POPI SearchSector                # In HW Sector Units

@PUSH 1
@WHILE_NOTZERO
   @POPNULL
#   @PRT "Checking Logical: " @PRTHEXI SearchPoint @PRT " HW: " @PRTHEXI SearchSector @PRTNL
   #
   @IF_EQ_VV LogicIndex SearchPoint
      # Match Found
      # SearchSector should have result
      @PUSH 0
   @ELSE
      @INCI SearchPoint
      @INCI SearchSector
      # Test to see if we've rolled over to next cluster.
      @IF_EQ_AV 0 ClusterMask
          # Handle the rare case where ClusterMask is not a simple number.
          @PUSHI SearchPoint @PUSHI sectorsPerCluster
          @CALL DIVU
          @POPNULL
      @ELSE
          @PUSHI SearchPoint @ANDI ClusterMask
      @ENDIF
      @IF_EQ_A 0
         # We've stepped though all the sectors in a given cluster, check FAT for next cluster ID
         @POPNULL
         @PUSHI SearchSector     # We may have to dec this so it points to previous FAT.
         @SUB 1
         @CALL Sector2Cluster
         @PUSHI FP @SWP
         @CALL FatSectorFromCluster  # Does the work of searching the FAT table for next sector.
         @POPI SearchSector
      @ELSE
         # Still in Cluster, just move to next sector.
         @POPNULL
      @ENDIF
      @PUSH 1        # Continue Loop
   @ENDIF
@ENDWHILE
@POPNULL
@PUSHI SearchSector
#
@RestoreVar 08
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


#################################################
# Function ReadSector(FP,Index,BufferPtr):AcutalSize(<512 means EOF)
# Reads a full 512 byte sector from file FP based on Index.
:ReadSector
@PUSHRETURN
@LocalVar FP 01
@LocalVar InIndex 02
@LocalVar OutBuffer 03
@LocalVar Temp1 04        # Short lived value
@LocalVar SearchSector 05
@LocalVar FileSizeSectors 06
@LocalVar FileRemainder 07
#
@POPI OutBuffer         # Points to 512 bytes to write the buffer
@POPI InIndex           # Logical index within the file
@POPI FP                # File Pointer
# First see if Index is even in range
@PUSHI FP @ADD FPofsFileSize
@CALL F32to16           # takes 32 bit number pointed at, into 2 16 values
@POPI FileRemainder
@POPI FileSizeSectors
# Do some tests to make sure PF even valid
@PUSH 1                       # If none of the fail tests work, then leave 1 on stack
@IF_EQ_AV 0 FileSizeSectors
   @IF_EQ_AV 0 FileRemainder
       # File is empty, just return with 0
       @POPNULL
       @PUSH 0
   @ENDIF
@ENDIF
@PUSHI InIndex
@IF_GT_V FileSizeSectors
#   @PRT "InIndex is too large\n"
#   @PRT "InIndex: " @PRTHEXI InIndex @PRT " FileSectors: " @PRTHEXI FileSizeSectors @PRTNL
   @POPNULL
   @POPNULL              # Also get rid of that 'fall through 1'
   @PUSH 0
   @JMP ReadSectorQuickExit   
@ELSE
   @POPNULL
@ENDIF
#
@IF_ZERO
   @POPNULL
   @PRT "Not Valid FP\n"
   # FP not valid or empty, skip tests and just return 0
   #
   @PUSH 0
   @JMP ReadSectorQuickExit
@ELSE
   @POPNULL      # Get Rid of that 1 flag.
@ENDIF
@PUSHI FP
@PUSHI InIndex
@CALL ReadSectorWorker1
@POPI SearchSector
@PUSHI FP @ADD FPofsDiskID @PUSHS        # Get FP.DiskID
@POPI Temp1
@DISKSELI Temp1
@DISKSEEKI SearchSector
@DISKREADI OutBuffer                        # Load disk sector to Buffer.
@PUSHI SearchSector
@PUSHI FP @ADD FPofsCurrentSector @POPS
@PUSHI InIndex @ADD 1
@PUSHI FP @ADD FPofsLogicSector @POPS
# We will drop here, whether or not we changed our current sector number
@IF_EQ_VV InIndex FileSizeSectors
   # Means we're on the last sector, which may not be a full 512 bytes long, so zero out buffer that over size
   @ForIV2A Temp1 FileRemainder 512
      @PUSHI OutBuffer @ADDI Temp1
      @DUP
      @PUSHS
      @AND 0xff
      @SWP
      @POPS
   @Next Temp1
   @PUSHI FileRemainder
@ELSE
   @PUSH 512            # All other cases its a full sector.
@ENDIF
:ReadSectorQuickExit
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
############################################
# Function FatSectorFromCluster(FP,ClusterIn)
# Gien a Cluster number, query the FAT table for the next cluster.
:FatSectorFromCluster
@PUSHRETURN
@LocalVar FP 01
@LocalVar ClusterIN 02
@LocalVar ByteOffset 03
@LocalVar sectorOffsetInFAT 04
@LocalVar offsetInSector 05
@LocalVar Temp1 06
@LocalVar FATBuffer 07
#
@POPI ClusterIN
@POPI FP
#
#
@PUSHI ClusterIN
@SHL    # Fat entires are 2 bytes long  (may need to sub 2)
@POPI ByteOffset
#
@PUSHI ByteOffset
@PUSHI bytesPerSector
@CALL DIVU            # Div returns both // and %
@POPI sectorOffsetInFAT
@POPI offsetInSector
#
#
# Now select the DISK and fetch the FAT table entry
@PUSHI FP @ADD FPofsDiskID @POPI Temp1
@DISKSELI Temp1
#
@PUSHI sectorOffsetInFAT
@ADDI reservedSectors
@POPI Temp1
@DISKSEEKI Temp1
# Create buffer
@PUSHI MainHeapID
@PUSHI bytesPerSector
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 1267" @POPNULL @END @ENDIF
@POPI FATBuffer
#
@DISKREADI FATBuffer
#
@PUSHI FATBuffer
@ADDI offsetInSector
@PUSHS           # Result on stack
@IF_UGT_A 0xfff0
@ELSE
   @CALL Cluster2Sector
@ENDIF
#
@PUSHI MainHeapID @PUSHI FATBuffer
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 1308: " @PRTTOP @END @ENDIF
@POPNULL

#
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
#################################################
# Function Fseek(FP,IndexPtr)
# Moves the next 'insert/read' point, IndexPtr is ptr to 32 bit integer.
# Returns 0 on error or trying to seek past end of file.
:Fseek
@PUSHRETURN
@LocalVar FP 01
@LocalVar IndexPtr 02
@LocalVar TargOffset 03
@LocalVar TargSector 04
@LocalVar FileOffset 05
@LocalVar FileSizeSect 06
#
@POPI IndexPtr
@POPI FP
#
# Get the requested location in file
@PUSHI IndexPtr
@CALL F32to16
@POPI TargOffset
@POPI TargSector
# Get real size of file
@PUSHI FP @ADD FPofsFileSize @PUSHS
@CALL F32to16           # takes 32 bit number pointed at, into 2 16 values
@POPI FileOffset
@POPI FileSizeSect
#
# Test that location is within file size
@PUSHI TargSector
@IF_GT_V FileSizeSect
   # Target is beyond the end of File.
   @POPNULL
   @PUSH 0
   @JMP FSeekExit
@ENDIF
@POPNULL
@IF_EQ_VV FileSizeSect TargSector
   # The case when both are equal, we need to check the offsets.
   @PUSHI TargOffset
   @IF_GT_V FileOffset
      # Targe is beyond end of file.
      @POPNULL
      @PUSH 0
      @JMP FSeekExit
   @ENDIF
   # Here means it's on last block , but not yet used every byte.
   @POPNULL
@ENDIF
#
# Save the new target values.
@PUSHI TargSector
@PUSHI FP @ADD FPofsCurrentSector @POPS
@PUSHI TargOffset
@PUSHI FP @ADD FPofsCurrentOffset @POPS
@PUSH 1           # Setting this to 'not 0' means successfull.
:FSeekExit
# Exit function
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
   


#################################################
# Function Read_worker2(WorkerType,FP,Size,Buffer)
# This worker will support both the readblock and readline code
# There will just be diffrent front ends on them.
# WorkerType 1 = Size based buffer
# WorkerType 2 = Newline or RecordMark fields.
#
:Read_worker2
@PUSHRETURN
@LocalVar WType 01
@LocalVar FP 02
@LocalVar InSize 03
@LocalVar OutBuffer 04
@LocalVar ReadBuffer 05
@LocalVar TotalRead 06  # Total Bytes read for cmp to InSize
@LocalVar RBIndex 07   # Sector byte index from start to 512
#
@POPI OutBuffer
@POPI InSize
@POPI FP
@POPI WType
#
# First question, is the current buffer stale, or can we use it as is?
@PUSHI FP @ADD FPofsState @PUSHS
@IF_EQ_A -1
   # Data is stale, read cluster into FP.Buffer
   @POPNULL
   # ReadSector(FP,FP.CurrentSector,FP.Buffer)
   @PUSHI FP
   @PUSHI FP @ADD FPofsLogicSector @PUSHS
   @PUSHI FP @ADD FPofsBuffer      # Note Buffer is IN FP so its no need for PUSHS
   @CALL ReadSector
   @POPNULL # Not testing for EOF because it won't make a diffrence.
   @PUSHI FP @ADD FPofsLogicSector @PUSHS
   @PUSHI FP @ADD FPofsState @POPS   # Over write State with current LogicSector
@ELSE
   @POPNULL
@ENDIF
#
# Setup initial read/write locations.
@PUSHI FP @ADD FPofsBuffer
@POPI ReadBuffer
@MA2V 0 TotalRead
@PUSHI FP @ADD FPofsCurrentOffset @PUSHS
@POPI RBIndex
#
# To Read buffers we'll be reading blocks in the destination buffer until one of the End conditions are met.
# The WType will control the end conditions.
@PUSH 0
@WHILE_ZERO
   @POPNULL
   # We have a few ways to determin EOR, and exit when any of them are true.
   @PUSHI WType
   @SWITCH
   @CASE 1      # Size Based
      @PUSHI TotalRead
      @IF_GE_V InSize
         @POPNULL
         @PUSH 1      # End of loop
      @ELSE
         @POPNULL
         @PUSH 0      # Continue so far.
      @ENDIF
      @CBREAK
   @CASE 2      # Records with seperator character (newline)
     @PUSHI ReadBuffer @ADDI RBIndex @PUSHS @AND 0xff
     @IF_EQ_V RecordMark
         @POPNULL
         @PUSH 1      # Reached end of record, exist while loop.
     @ELSE
         @POPNULL
         @PUSH 0
     @ENDIF
     @CBREAK
   @CDEFAULT
     @PRT "Not a valid worker flag. (1435)" @END
     @CBREAK
   @ENDCASE
#   @PRT "Doing Char: " @PRTHEXI RBIndex @StackDump
   @SWP
   @POPNULL
   @IF_ZERO
      # Not yet End of Record, so write byte and check if we need to go to a new sector.
      @POPNULL
      @PUSHI ReadBuffer @ADDI RBIndex @PUSHS @AND 0xff
      @PUSHI OutBuffer @ADDI TotalRead @POPS
      @INCI TotalRead
      @INCI RBIndex
      # Test if we need to read next block.
      @PUSHI RBIndex
      @IF_GE_A 0x200
         @POPNULL
         # Get Next Sector (FP,LogicSector,Buffer)
         @PUSHI FP         
         @PUSHI FP @ADD FPofsLogicSector @PUSHS @ADD 1  # Move to next logical sector.
         @PUSHI FP @ADD FPofsLogicSector @POPS
         @PUSHI FP @ADD FPofsLogicSector @PUSHS
         @PUSHI FP @ADD FPofsBuffer
         @CALL ReadSector
         @IF_ZERO
            @POPNULL
            # Reached end of File exit loop.
            @PUSH 2
         @ELSE
            @POPNULL
            @MA2V 0 RBIndex     # reset 0-512
            @PUSH 0             # Still in loop
         @ENDIF
      @ELSE
         @POPNULL
         @PUSH 0
      @ENDIF
   @ELSE
      @PRT "End of Record: " @PRTHEXI RBIndex @PRTSP @StackDump @PRTNL
      # Reached End of Record.
      # Handle case were End of record and End of Sector are the same:
      @PRT "EOR: " @PRTHEXI RBIndex @StackDump
      @POPNULL
      @PUSHI RBIndex
      @IF_GE_A 0x1ff
         @IF_EQ_AV 2 WType
            # Handle odd case where last character in full Sector is also RecordMark
            @POPNULL
            @PUSHI ReadBuffer @ADDI RBIndex @PUSHS @AND 0xff
            @IF_EQ_V RecordMark
               @POPNULL
               @PUSH 1  # Reached of line, exit while loop
               @MA2V 0 RBIndex
               # Mark the old readbuffer as stale
               @PUSH -1
               @PUSHI FP @ADD FPofsState @POPS
            @ELSE
               @POPNULL
               # OK so its not that odd case, so just check for normal EOF logic
               @POPNULL
               @PUSHI FP         
               @PUSHI FP @ADD FPofsLogicSector @PUSHS @ADD 1  # Move to next logical sector.
               @PUSHI FP @ADD FPofsLogicSector @POPS
               @PUSHI FP @ADD FPofsLogicSector @PUSHS
               @PUSHI FP @ADD FPofsBuffer
               @CALL ReadSector   # This is just to test if we reached EOF
               @MA2V 0 RBIndex   # Reset to zero for next read.
               @IF_ZERO
                  @POPNULL
                  @PUSH 2    # Reached real EOF.. last line is not terminated with RecordMark
               @ELSE
                  @POPNULL
               @ENDIF
            @ENDIF
         @ELSE
            # This is nearly identical to the block above but for WorkerType 1.
            # Due to the way the IF's are nested its not trivial to reused same code. Cost is about 50 bytes.
            @POPNULL
            @PUSHI FP         
            @PUSHI FP @ADD FPofsLogicSector @PUSHS @ADD 1  # Move to next logical sector.
            @PUSHI FP @ADD FPofsLogicSector @POPS
            @PUSHI FP @ADD FPofsLogicSector @PUSHS
            @PUSHI FP @ADD FPofsBuffer
            @CALL ReadSector   # This is just to test if we reached EOF
            @MA2V 0 RBIndex   # Reset to zero for next read.         
            @IF_ZERO
               @POPNULL
               @PUSH 2  # Reached EOF and End of Sector as same time.
            @ELSE
               @POPNULL
               @PUSH 1  # Reach end of block, but not end of fie.
            @ENDIF
         @ENDIF
      @ENDIF      
   @ENDIF
@ENDWHILE
@IF_EQ_A 2
   # Exit is with EOF use 0 for return
   POPNULL
   @PUSH 0
@ELSE
   # Else return is total number of bytes read.
   @POPNULL
   @PUSHI TotalRead
@ENDIF

   
# Whatever the current RBIndex is the new FP.CurrentOffset
@PUSHI RBIndex
@PUSHI FP @ADD FPofsCurrentOffset @POPS
@RestoreVar 07
@RestoreVar 06
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
################################################
# Function ReadBuffer(FP,Size,Buffer)
:ReadBuffer
@PUSHRETURN
@LocalVar FP 01
@LocalVar Size 02
@LocalVar Buffer 03
#
@POPI Buffer
@POPI Size
@POPI FP
@PUSH 1
@PUSHI FP
@PUSHI Size
@PUSHI Buffer
@CALL Read_worker2
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
################################################
# Function ReadLine(FP,Buffer)
# Reads one line ending with newline to buffer.
:ReadLine
@PUSHRETURN
@LocalVar FP 01
@LocalVar Buffer 02
#
@POPI Buffer
@POPI FP
@PUSH 2
@PUSHI FP
@PUSHI 0
@PUSHI Buffer
@CALL Read_worker2
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
################################################
# DeleteFile(FP):SuccessCode
:DeleteFile
@PRT "Not yet implimented.\n"
@PUSH 0
@SWP
@RET
   
################################################
# Function CreateNewFile(FileName):FP
# If FileName exists, erases it, then creates new File/FP
:CreateNewFile
@PUSHRETURN
@LocalVar FileName 01
@LocalVar FP 02
@LocalVar Index 03
#
@POPI FileName
#
@IF_EQ_AV -1 activeDisk
   @PRT "No Disk Selected, Use readBootRecord before CreateNewFile\n"
   @END
@ENDIF
#
# Refresh the boot record, if needed.
@PUSHI activeDisk
@CALL readBootRecord
#
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


   
