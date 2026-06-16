
DISKNAME=DISK00.disk

[ -e $DISKNAME ] && /bin/rm -f $DISKNAME

dd if=/dev/zero of=$DISKNAME bs=1M count=32

printf '\x44\x30' | dd of=$DISKNAME bs=1 seek=0 conv=notrunc
printf '\x34\x12' | dd of=$DISKNAME bs=1 seek=2 conv=notrunc
printf '\x30\x1A\x0F\x66' | dd of=$DISKNAME bs=1 seek=4 conv=notrunc


