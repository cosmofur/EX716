# Stubs to use in place to diskio.ld to save the memory it takes up for debugging.
:DirNewArgTable
:DiskNewBuffer
:DIR_AT_FILENAME
:DIR_AT_FILESIZE
:DIR_FLAGS
:DirReadEntry
:DiskClose
:DiskFileReadLine
:DiskFileWrite
:DiskHeap
:FSFindFile
:LINE_EOF
:LINE_LEN_MASK
:LINE_NO_ROOM
:LINE_PARTIAL
:LINE_STATE_MASK
:MODE_RO
@RET
:file_open
@SWP @POPNULL @SWP @POPNULL
@RET
:FSReadHeader
@SWP
@POPNULL
@PUSH 1
@SWP
@RET
:SetDiskHeap
@StackDump
@SWP
@POPNULL
@RET
