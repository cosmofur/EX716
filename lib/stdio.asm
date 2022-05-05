# Bare Bones stdio functions
! STDIO_DONE
M STDIO_DONE 1

@JMP SkipStdioLib

# I can't see creating the entire full and rich stio, but will concentrate on key functions
#
# open(filename, mode_binary)                 fopen(filename, "mod string" { "r", "w", "rw", "w+" })
# close(fp)                                   seek(fp,offset)
# sprintf(format, arguments...)               fprint is file version of sprintf
#
# In our minual OS, filenames are "[directory/path]A-z[A-z0-9_.]*"
# The file structure starts at block zero which is also the first inode
# inodes are block (not file) structures with the following info.
#    Location: 16b  : Disk block where file data starts
#    Length: 16b    : Number of blocks allocated to file data.
#    Size: 32b      : Number of bytes in total in file.
#    Extent: 16b    : Non zero number,means inode continues in that block.
#    Mode: 16b      : Mode is in set { Used, First, Chain }

