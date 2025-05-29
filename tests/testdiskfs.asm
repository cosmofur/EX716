I common.mc
L softstack.ld
L random.ld
L heapmgr.ld
L fat16lib.ld
#
#
# Static Variables
:MainHeapID 0
:RootDirInfo 0
:StringBuffer 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   # 32 byte buffer for short strings
:FormatStr1 "TA:%-5d TB:%#9d\0"
:FormatStr2 "Words:%-15s\0"
:TestOutStr "One Two\0"
#
#############################################################################
# Function Init, setup heap and memory
:Init
# Defined memory between endofcode and 0xf000 as available
@PUSH ENDOFCODE @PUSH 0xf000 @SUB ENDOFCODE
@CALL HeapDefineMemory
@POPI MainHeapID
#
# Expands the Soft Stack so we can use deeper recursion, about 1K should do for now.
@PUSHI MainHeapID @PUSH 0x400
@CALL HeapNewObject @IF_ULT_A 100 @PUSH 1 @CALL ErrorExit @ENDIF   # Error code 1
@DUP @ADD 0x400 @SWP
@CALL SetSSStack
#
# The 'Root' Obejct will always just contain the ID of 0, and one pointer to first available room.
@CALL RunIntro
@RET
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

###########################################################################
# Function RunIntro
:RunIntro

@PUSHRETURN
#
=UserKey Var01
=SeedCount Var02
=FileAttribute Var03
@PUSHLOCALI UserKey
@PUSHLOCALI SeedCount

#
@PUSH 0   # Set this to 1 if we need a random seed
@IF_NOTZERO
   @TTYNOECHO
   # First When is to 'drain' and keybuffer
   @WHEN
      @READCNW UserKey
      @PUSHI UserKey
      @DO_NOTZERO
         @POPNULL
   @ENDWHEN
   @POPNULL
   @WHEN
      @READCNW UserKey
      @PUSHI UserKey
      @IF_EQ_AV 0 UserKey
      @ELSE
         @PRTSTR UserKey
      @ENDIF
      @DO_ZERO
         @POPNULL
         @INCI SeedCount
   @ENDWHEN
   @POPNULL
   @TTYECHO
   @PUSHI SeedCount @ADDI UserKey @AND 0x7fff
   @PRT "Random Seed: " @PRTTOP @PRTNL
   @CALL rndsetseed
@ENDIF
@POPNULL
@POPLOCAL SeedCount
@POPLOCAL UserKey
@POPRETURN
@RET
#
:Main . Main
#
=BootSector Var01
=rootBuffer Var02
=rootCluster Var03
=subdirCluster Var04
=entry Var05
=returnstr Var06
@CALL Init
@PRTLN "Initializing Filesystem.."
@PUSH 0 @PUSHI MainHeapID
@PRT "Main HeapID: " @PRTHEXI MainHeapID @PRTNL
@CALL SelectDisk
#
@PUSHI MainHeapID @PUSHI returnstr @CALL HeapDeleteObject
@PUSH TestOutStr
@PUSH FormatStr2
@PUSHI MainHeapID
@CALL strFormat
@POPI returnstr
@PRT "String: "
@PRTSI returnstr @PRTNL
@PRTLN "---------------------"

#
@PUSH 0 @PUSH 0
@PRTLN "Calling Read Sector 0"
@CALL ReadSectorBuffer
@POPI BootSector
#
@IF_EQ_AV 0 BootSector
   @PRTLN "Failed to read boot sector\n"
   @END
@ENDIF
#
@PRTLN "Calling ParseBootSector"
@PUSHI BootSector
@CALL ParseBootSector
#
@PRTLN "Calling ReportParseBootSector"
@CALL ReportParseBootSector
#
@PUSHI DiskHeapID @PUSHI BootSector @CALL HeapDeleteObject  # free(BootSector)
#
@PRTLN "Reading and listing root directory..."
#
@PRTLN "Calling ReadRootDir"
@CALL ReadRootDir
@POPI rootBuffer
#
@PUSHI rootBuffer
@PRTLN "Calling ListDir"
@CALL ListDir
@PUSHI DiskHeapID @PUSHI rootBuffer @CALL HeapDeleteObject  # free(rootBuffer)
#
@PRTLN "Changeing dir1..."
# Root Dir starting cluster
@MA2V 0 rootCluster
#
@PUSHI rootCluster
@STRSET "/dir1\0" StringBuffer
@PUSH StringBuffer
@PRTLN "Calling GetDirectory"
@CALL GetDirectory   # (rootCluster, "subdir")
@POPI subdirCluster
@POPI FileAttribute
@PRT "Dir Cluster:" @PRTI subdirCluster @PRTNL
#
@IF_EQ_AV -1 subdirCluster
   @PRTLN "dir1 not found."
   @END
@ENDIF

@PRT "Successfully changed to /dir1 which points to cluster: " @PRTI subdirCluster
@PRT " Attribute: " @PRTI FileAttribute
@PRTNL
#
@PUSHI subdirCluster
@PRTLN "Calling ReadDirBuffer"
@CALL ReadDirBuffer

@POPI entry
#
@IF_EQ_AV 0 entry
   @PRTLN "Failed to read directory entry"
   @END
@ENDIF
@PUSHI entry
@PRTLN "Calling HexDumpMemory"
@CALL HexDumpMemory
@PUSHI entry
@CALL ListDir
@END




@POPI RootDirInfo
@PUSHI RootDirInfo
@PRTLN "Calling ListDir"
@CALL ListDir
@PRTLN "Calling ReadRootDir"
@CALL ReadRootDir

@PRTLN "List first 5 Fat Addresses"
@PRT "1 =" @PUSH 1 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@PRT "2 =" @PUSH 2 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@PRT "3 =" @PUSH 3 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@PRT "4 =" @PUSH 4 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@PRT "5 =" @PUSH 5 @CALL GetFatAddress @PRTTOP @POPNULL @PRTNL
@END


:HexDumpMemory
@PUSHRETURN
=Index1 Var01
=Index2 Var02
=MemPtr Var03
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
#
@POPI MemPtr
@PRTLN  "ADDR 0000 0001 0002 0003 0004 0005 0006 0007 0008 0009 000A 000B 000C 000D 000E 000F"
@ForIA2B Index1 0 24
    @PRTHEXI MemPtr @PRT ":"
    @ForIA2B Index2 0 16
       @PUSHII MemPtr
       @PRTHEXTOP @PRT " "
       @POPNULL
       @INCI MemPtr
    @Next Index2
    @PRTNL
@Next Index1
@PRTLN
:Break02
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET





:ENDOFCODE

#
#  $ ls /mnt/DISK00/
# dir1  test.txt  test2.txt
#  $ ls /mnt/DISK00/dir1/
# subfile.txt
#


#
#
#
