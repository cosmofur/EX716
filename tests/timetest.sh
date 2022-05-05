#!/bin/bash

rm -f /tmp/mtime.$$

for x in {1..10}
do
  /usr/bin/time -f "real %e user %U sys %S" -a -o /tmp/mtime.$$ $@
  tail -1 /tmp/mtime.$$
done

awk '{ et += $2; ut += $4; st += $6; count++ } END {  count=count / 2;printf "Average:\nreal %.3f user %.3f sys %.3fn (raw %f %f %f %d)\n", et/count, ut/count, st/count, et,ut,st, count }' /tmp/mtime.$$

