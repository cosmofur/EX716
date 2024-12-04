! Fat16Mod
M Fat16Mod 1
I common.mc
I fat16suport.asm
L string.ld
L heapmgr.ld
L softstack.ld
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
:rootDirStartCluster 0
:totalClusters 0
:rootDirSize 0
:rootDirSizeInSectors 0
:FATSizeInSectors 0
:dataAreaStartSector 0
:totalDataSectors 0
:clusterSize 0
:FATSizeInBytes 0

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
@MA2V 0 FATSize16
@MA2V 0 rootDirStartCluster
@MA2V 0 totalClusters
@MA2V 0 FATSizeInSectors
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
@LocalVar FatsBySecSize 03
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
   @PRT "NewObject: RBR: InBuffer:" @PRTHEXTOP @PRTNL
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
   @PUSHI bytesPerSector @RTR @POPI FatsBySecSize

   # totalClusters=(totalSectors - reservedSectors - FatsBySecSize)/sectorsPerCluster
   @PUSHI totalSectors16 @SUBI reservedSectors @SUBI FatsBySecSize
   @PUSHI sectorsPerCluster @CALL DIVU 
   @POPI totalClusters @POPNULL

   # rootDirSize=(rootDirEntries * 32)/bytesPerSector
   @PUSHI rootDirEntries @RTL @RTL @RTL @RTL @RTL  # X 32
   @POPI rootDirSize
   @PUSHI rootDirSize
   @PUSHI bytesPerSector @CALL DIVU @POPI rootDirSizeInSectors @POPNULL

   # dataAreaStartSector = reservedSectors+(numberofFATs*FATSize16)+rootDirSize
   
   
   @PUSHI reservedSectors @ADDI FatsBySecSize @ADDI rootDirSize
   @POPI dataAreaStartSector

   # FATSizeInSectors
   @PUSHI numberofFATs @PUSHI FATSize16 @CALL MULU @POPI FATSizeInSectors

   # rootDirStartCluster
   
   @PUSHI FATSizeInSectors  @ADDI reservedSectors 
   @POPI rootDirStartCluster



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
   @PRT "DeleteObject: Delete InBuffer:" @PRTHEXTOP @PRTNL   
   @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 148:" @END @ENDIF
   @POPNULL
@ENDIF
#M DebugPrint 1

? DebugPrint
@PRT " bytesPerSector = " @PRTHEXI  bytesPerSector @PRTNL
@PRT " sectorsPerCluster = " @PRTHEXI  sectorsPerCluster @PRTNL
@PRT " reservedSectors = " @PRTHEXI  reservedSectors @PRTNL
@PRT " numberofFATs = " @PRTHEXI  numberofFATs @PRTNL
@PRT " rootDirEntries = " @PRTHEXI  rootDirEntries @PRTNL
@PRT " totalSectors16 = " @PRTHEXI  totalSectors16 @PRTNL
@PRT " FATSize16 = " @PRTHEXI  FATSize16 @PRTNL
@PRT " FatsBySecSize = " @PRTHEXI  FatsBySecSize @PRTNL
@PRT " rootDirStartCluster = " @PRTHEXI  rootDirStartCluster @PRTNL
@PRT " totalClusters @POPNULL = " @PRTHEXI  totalClusters @PRTNL
@PRT " rootDirSize = " @PRTHEXI  rootDirSize @PRTNL
@PRT " rootDirSizeInSectors = " @PRTHEXI  rootDirSizeInSectors  @PRTNL
@PRT " dataAreaStartSector = " @PRTHEXI  dataAreaStartSector @PRTNL
@PRT " FATSizeInSectors = " @PRTHEXI  FATSizeInSectors @PRTNL
@PRT " totalDataSectors = " @PRTHEXI  totalDataSectors @PRTNL
@PRT " clusterSize = " @PRTHEXI  clusterSize @PRTNL
@PRT " FATSizeInBytes = " @PRTHEXI  FATSizeInBytes @PRTNL
ENDBLOCK
@RestoreVar 03
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
@LocalVar currentCluster 03
@LocalVar components 04
@LocalVar numComponents 05
@LocalVar Index1 06
@LocalVar Entry 07
@LocalVar FP 08
@LocalVar Entry 09
#
@POPI DiskID
@POPI InFilePath

#
@MV2V rootDirStartCluster currentCluster
#@MA2V 0 currentCluster
#
@PUSHI InFilePath
@CALL strUpCase      # Changes filePath to be just uppercase
@PUSHI InFilePath
@CALL SplitPath     # Split string filepath into array of string ptrs, return both number of entrys and the array
@POPI numComponents
@POPI components
#
@ForIA2V Index1 0 numComponents
   @PUSHI currentCluster
   @PUSHI components @PUSHI Index1 @RTL @ADDS @PUSHS  # put string ptr at array[index] on stack
   @PUSHI DiskID
   @CALL findEntryInDirectory  # (currentcluster, compoents[index], diskid)
   @IF_ZERO
      # No filename matched.
      @POPNULL
      @MA2V 0 FP
      @FORBREAK
   @ELSE
      # The return is a pointer to an in memory version of the Directory Entry
      @POPI Entry
      @PUSHI Entry
      @ADD DSofsattributes @PUSHS @AND 0xff
      # bit mask 0x10 is directory flag
      @AND 0x10
      @IF_NOTZERO
         # Is a Directory. Move down into it.
         @POPNULL
         @PUSHI Entry  @ADD DSofsstartCluster @PUSHS
         @POPI currentCluster
      @ELSE
         # Found a file. Create a new FP structure
         @POPNULL
         @PUSHI MainHeapID         
         @PUSH FPofsSize
         @CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 236:" @PRTHEXTOP @POPNULL @END @ENDIF
         @PRT "NewObject: PP: FP:" @PRTHEXTOP @PRTNL         
         @POPI FP
         # fp.currentCluster=entry.startCluster
         @PUSHI Entry @ADD DSofsstartCluster
         @PUSHI FP @ADD FPofscurrentCluster
         @POPS
         # fp.currentSize=entry.fileSize
         @PUSHI Entry @ADD DSofsfileSize
         @PUSHI FP @ADD FPofscurrentSize
         @POPS
         # fp.diskID=DiskID
         @PUSHI DiskID
         @PUSHI FP @ADD FPofsdiskID
         @POPS
         @PUSHI numComponents @SUB 1 @POPI Index1 # Break out for For loop, when FORBREAK is not right.
      @ENDIF
      # No longer need Entry, clean it up
      @PUSHI MainHeapID
      @PUSHI Entry
      @PRT "DeleteObject: Delete Entry:" @PRTHEXTOP @PRTNL         
      @CALL HeapDeleteObject
   @ENDIF
@Next Index1
# clean up the components array.
@PUSHI components
@PUSHI MainHeapID
@CALL SplitDelete

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
# Function findEntryInDirectory(currentCluster,Filename, DiskID)
# Scans the current clusters directory entries for matching FileName
:findEntryInDirectory
@PUSHRETURN
@LocalVar currantCluster 01
@LocalVar FileName 02
@LocalVar InDiskID 03
@LocalVar sectorOffset 04
@LocalVar entryOffset 05
@LocalVar Sector 06
@LocalVar StartSector 07
@LocalVar Buffer 08
@LocalVar Entry 09
@LocalVar EntryOffset 10
@LocalVar Temp1 11
@LocalVar Temp2 12
#
#
@POPI InDiskID
@POPI FileName
@POPI currentCluster
@MA2V 0 sectorOffset
@MA2V 0 entryOffset
@PUSHI MainHeapID
@PUSH 512
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 297" @POPNULL @END @ENDIF
@PRT "NewObject: FED: Buffer:" @PRTHEXTOP @PRTNL
@POPI Buffer

#
@PUSHI InDiskID
@CALL readBootRecord
#
@PUSHI FATSizeInSectors
@ADDI reservedSectors
@POPI StartSector

#
@ForIA2V Sector 0 sectorsPerCluster

    @PUSHI Sector @ADDI Sector @ADDI StartSector @POPI Temp1
    @DISKSEEKI Temp1
    @DISKREADI Buffer
    @PRT "Buffer Starts at: " @PRTHEXI Buffer @PRT " Offset: " @PRTHEXI Temp1 @PRTNL
    @MA2V 0 EntryOffset
    @PUSHI EntryOffset
    @PRT "Var bytesPerSector = " @PRTHEXI bytesPerSector @PRTNL
    @WHILE_LT_V bytesPerSector
        @POPNULL
        #
#        @PUSHI Buffer @ADDI EntryOffset @PUSH 32 @CALL HexDump
        @PRT "EntryOffset: " @PRTI EntryOffset
        @PUSHI Buffer @ADDI EntryOffset
        @POPI Entry
        @PRT " = Entry: " @PRTI Entry
        @PUSHI Entry @ADD DSofsfilename @PUSHS @AND 0xff
        @IF_ZERO
           # Zero byte in filename, end of directory list
           @JMP BreakFindEntry
        @ENDIF
        @POPNULL
        @PUSHI Entry @ADD DSofsattributes @PUSHS @AND 0xff
        @PRT " Disk Attribute: " @PRTHEXTOP @PRTNL
        @AND 0x08    # Is it a DISK Lable entry?
        @IF_NOTZERO
           @POPNULL
           @PUSH 1   # Then Skip it.
        @ELSE
           @POPNULL
           @PUSHI Entry @ADD DSofsattributes @PUSHS @AND 0xff
           @AND 0x0f  # Is it a long filename entry?
           @IF_NOTZERO
              @POPNULL
              @PUSH 1   # Skip It
           @ELSE
              @POPNULL
              @PUSH 0   # Its a simple filename, run the tests.
           @ENDIF
        @ENDIF
        @IF_ZERO
           @POPNULL
           @PUSHI FileName           
           @PUSHI Entry @ADD DSofsfilename
           @CALL compareFileNames
           
           @IF_ZERO
              # Exact match
              # We need to create a new 'entry' heap object so we can delete it later.
              @PRT " Exact Match: " @PRTNL
              @POPNULL
              @PUSHI MainHeapID
              @PUSH DSofsSize
              
              @CALL HeapNewObject
              @IF_ULT_A 100 @PRT "Memory Error 362" @POPNULL @END @ENDIF
              # Copy just the Entry part of buffer to new Temp2 heap object
              @PRT "NewObject: FED: Temp2:" @PRTHEXTOP @PRTNL              
              @POPI Temp2   # Will use this for destinatin of Entry.
              @PUSHI Temp2 @PUSHI Entry @PUSH DSofsSize
              @CALL memcpy
              # Now clean up the buffer
              
              @PUSHI MainHeapID
              @PUSHI Buffer
              @PRT "DeleteObject: Delete Buffer:" @PRTHEXTOP @PRTNL   
              
              @CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 368" @POPNULL @END @ENDIF
              @POPNULL
              # Return Result
              @PUSHI Temp2
              @JMP  BreakFindEntry
           @ELSE           
              @POPNULL
           @ENDIF
        @ELSE
           @POPNULL
        @ENDIF
        @PUSHI EntryOffset @ADD 32
        @POPI EntryOffset
        @PUSHI EntryOffset
     @ENDWHILE
 @Next Sector
 # Reach here then there was no match, not even an 'end of list' entry.
@PUSH 0
@PUSHI MainHeapID
@PUSHI Buffer
@PRT "DeleteObject: Delete Buffer(2):" @PRTHEXTOP @PRTNL   

@CALL HeapDeleteObject
:BreakFindEntry
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
# Function compareFilenames(FileZ1, FileSP1)
# Compares  Files looking for a match
# inbound FileZ1 is null terminated string
# inbound FileSP1 is a space filled 11 byte string.
:compareFileNames
@PUSHRETURN
@LocalVar FileZ1 01
@LocalVar FileSP1 02
@LocalVar FileSP2 03
@LocalVar Index1 04
@POPI FileSP1
@POPI FileZ1
@PUSHI FileZ1
@CALL str2filename

@POPI FileSP2
@PRT "COMPARE: " @PRTSTRI FileZ1 @PRTSP @PRTSTRI FileSP1 @PRTNL
@PUSH 1
@ForIA2B Index1 0 11
   @PUSHII FileSP1 @AND 0xff
   @PUSHII FileSP2 @AND 0xff
   @CMPS
   @IF_ZFLAG
      @POPNULL @POPNULL
      @POPNULL
      @PUSH 0
      @FORBREAK
   @ENDIF
   @POPNULL @POPNULL
@Next Index1
# The Result of 1 or zero will be TOS
@PUSHI MainHeapID @PUSHI FileSP2
@PRT "DeleteObject: Delete FileSP2:" @PRTHEXTOP @PRTNL
@CALL HeapDeleteObject @IF_NOTZERO @PRT "Memory Error 440: " @PRTTOP @END @ENDIF


@POPNULL
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET


#####################################################
# Function str2filename(FilePart):Heap Object 12 byte space padded Filename format
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
@PRT "NewObject: S2FN: OutputStr:" @PRTHEXTOP @PRTNL
@POPI OutputStr
#
@MA2V 0 Index1
@PUSHI Index1
# There's a few layers to this loop so to explain.
# Will loop over the fixed lenth of the 8.3 or 11 character space
# If index < 8, we will copy InFilePart changing to spaces when we hit either '.' or null
# else  skip forward if on '.' and repeat same logic about spaces for the Extention part.
@WHILE_LT_A 11
   @IF_ULT_A 8
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
@LocalVar WorkSpace 05

@POPI Length
@POPI Start
@PUSHI MainHeapID
@PUSH 50
@CALL HeapNewObject @IF_ULT_A 100 @PRT "Memory Error 556" @POPNULL @END @ENDIF
@PRT "NewObject: HD: WorkSpace:" @PRTHEXTOP @PRTNL
@POPI WorkSpace
@PRTLN "ADDR:-0-1-2-3 -4-5-6-7 -8-9-A-B -C-D-E-F"
@MV2V Start Index01
#
@PUSHI Index01
@WHILE_NOTZERO
   @POPNULL
   @PRTHEXI Index01 @PRT ":"
   @MA2V 0 ColumnCnt
   @PUSHI ColumnCnt
   @WHILE_ULT_A 16
      @POPNULL
      @PUSHI WorkSpace
      @PUSHI Index01 @ADDI ColumnCnt @PUSHS @AND 0xff
      @PUSH 16
      @CALL itos
      @PUSHII WorkSpace @AND 0xff00
      @IF_LT_A "0\0"
         # Simple test if result is 2 dit
         @PRT "0"
         @PRTSTRI WorkSpace
      @ELSE
         @PRTSTRI WorkSpace
      @ENDIF
      @POPNULL
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
               @PUSH 1
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
#
@RestoreVar 05
@RestoreVar 04
@RestoreVar 03
@RestoreVar 02
@RestoreVar 01
@POPRETURN
@RET
