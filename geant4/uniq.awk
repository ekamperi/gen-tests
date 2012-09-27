#!/bin/bash

if [ $# -eq 0 ]; then
    echo "usage: $0 <folded.file>"
    exit 1
fi

cat $1									|
sort -r -n -k2								|
awk -F ' ' '{ print $1 }'						|
sed -e 's/full_cms`//g' -e 's/libc.so.1`//g' -e 's/libm.so.2`//g'       |
tee folded.before.awk |
awk '
     function min(x, y)
     {
	 if (x > y)
	     return y
	 else
	     return x
     }

     BEGIN {
	 print "#!/usr/sbin/dtrace -s"
	 print "pid$target::*DoEventLoop*:entry  { self->initialized = 1; }"
	 print "pid$target::*DoEventLoop*:return { self->initialized = 0; }"
	 print
     }
     BEGIN { FS = "," }
     {
	 for (i = 1; i <= NF; i++) {
	     a[$i]++;
	     if (a[$i] == 1)
		 b[n++] = $i
	 }
     }
     END {
	 for (i = 0; i < min(n, 50); i++) {
	     len = length(b[i]);
	     M = 100
	     if (len > 120) {
		 s = "*"  substr(b[i], len/2-M/2,M)  "*"
	     } else {
		 s = b[i]
	     }
	     c[i] = s
	     printf "pid$target::%s:entry", s
	     if (i != n-1 && i != 49)
		 printf ",\n"
	     else
		 printf "\n"
	 }
	 print "/self->initialized/"
	 print "{"
	 print "\tself->ts[probefunc] = vtimestamp;"
	 print "}"

	 for (i = 0; i < min(n, 50); i++) {
             printf "pid$target::%s:return", c[i]
             if (i != n-1 && i != 49)
                 printf ",\n"
             else
                 printf "\n"
	 }
	 print "/self->initialized && self->ts[probefunc]/"
	 print "{"
	 print "\t@[probefunc] = avg(vtimestamp - self->ts[probefunc]);"
	 print "\tself->ts[probefunc] = 0;"
	 printf "}"
     }
'
