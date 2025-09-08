! FFDISKSeen
M FFDISKSeen
I common.mc
L heapmgr.ld
M SIZESINCECOMMENT ffile.ld
:DiskHeapID 0

###############################################
# Function FSinit(HeapID). Initilize Disksystem
# Creates a new FST and zeros it. Setting up stdio for File Descriptors 0 and 1
:FSinit
@PUSHRETURN
@POPI DiskHeapID        # This is a global but we set it here.
#
# Allocate space for SystemTables and FileTables
# To allow for Stdin and StdOut as FT 0 and 1, allocate 2 SystemTables
@PUSH 0
@POPI HeadSystemFileTables
#
# Calling SFTCreateEntry creates the SFT and allocates space for the FileTable.
# It returns zero on error
@PUSHI DiskHeapID
@PUSH 0
@CALL SFTCreateEntry
@IF_ZERO    @PRTLN "Error Could Not Allocate System File Entry. Too many open Files." @END @ENDIF
@POPNULL
@PUSHI DiskHeapID
@PUSH 1
@CALL SFTCreateEntry
@IF_ZERO    @PRTLN "Error Could Not Allocate System File Entry. Too many open Files." @END @ENDIF
@POPNULL
#
# CreateFileTable fills in default or initial values to the file table structure.
# There are 9 possible fields, but we control which ones we care about by the mask.
#
# First record is StdOut or File Handle 0
@PUSH 0           # 1st Parameter Value (stdout)
@PUSH 0           # SFT record
@PUSH 0b001       # We only need to set DIR sector to 0 or 1 for stdio.
@PUSHI HeadSystemFileTables
@CALL CreateFileTable
# Second record is StdIn for File Handle 1
@PUSH 1           # 1st Paramter value (stdin)
@PUSH 1           # SFT record
@PUSH 0b001       # Just Dir sector stores the value
@PUSHI HeadSystemFileTables
@CALL CreateFileTable
#
@POPRETURN
@RET
###################################################
# Function SFTCreateEntry(inIndex)
#   Create a new SFT entry at index, if it already exists remove old one.
:SFTCreateEntry
@PUSHRETURN
=inIndex Var01
=SelectIdx Var02
=CurrentEntry Var03
@PUSHLOCALI Var01
@PUSHLOCALI Var02
@PUSHLOCALI Var03
@POPI inIndex
#
@IF_EQ_AV 0 HeadSystemFileTables
   # Need to create first entry.
   @PUSHI DiskHeapID @PUSH SFTFileSize
   @CALL HeapNewObject   
   @POPI HeadSystemFileTables
   @MA2V 0 SFTMaxUsed
   @PUSH 0xffff @POPII HeadSystemFileTables # SFT[0][0]=0xffff mark as end of list
@PUSHI inIndex
# Make sure all entries less than inIndex also exist, at least as empty structures.
@INCI inIndex   # For i = N to inIndex-1 (so make inIndex+1)
@MV2V HeadSystemFileTables CurrentEntry
@ForIA2V SelectIdx 0 inIndex
     @PUSHII CurrentEntry
     @IF_EQ_A 0xffff
         # If current entry is 'last' entry, point it to a New 'last' entry
         @POPNULL
         @PUSH DiskHeapID @PUSH SFTFileSize
         @CALL HeapNewObject
         @POPII CurrentEntry    # CurrentEntry[0] => New
         # Now mark that new entry as being 'last'         
         @PUSH 0xffff
         @PUSHII CurrentEntry
         @POPS                  # CurrentEntry[CurrentEntry[0]] => Last_Code 0xffff
         @PUSHII CurrentEntry
     @ENDIF
     @POPI CurrentEntry
@Next SelectIdx
# CurrentEntry should point the SFT[inIndex] item
@POPLOCAL Var03
@POPLOCAL Var02
@POPLOCAL Var01
@POPRETURN
@RET


#####################################################
#
# Data Structure SystemFileTables
:HeadSystemFileTables 0      # Ptr to first system File table.
:SFTMaxUsed 0                # Counter for size of SFT
=SFTNextItem 0
=SFTActiveFlag 2
=SFTFileTablePtr 4
=SFTFileSize 6
#######
# DataStructure FileTables
:FileTablesHead 0
=FTDirSector 0                   # Identify What Disk Sectron stores files DIR    # Field 0
=FTDirOffset FTDirSector+2       # Offset within sector                           # Field 1
=FTFileSize  FTDirOffset+2       # 32 bit filesize                                # Field 2
=FTFilePosition FTFileSize+4     # 32 bit Cursor within file for next read/write  # Field 3
=FTFileCache1 FTFilePosition+4   # Ptr to File IO Cache                           # Field 4
=FTFileCache2 FTFileCache1+2     # Ptr to low level (Dir/Fat table) Cache         # Field 5
=FTFatHead FTFileCache2+2        # Startng Fattable entry for first cluster.      # Field 6
=FTFatEntry FTFatHead+2          # Current Fattable entry for active cluster.     # Field 7
=FTTableSize FTFatEntry+2                                                         # Field 8
@SIZESINCE


