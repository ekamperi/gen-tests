#!/bin/bash

function usage()
{
	echo "$(basename $0) stacks.1 stacks.2" >&2
	exit 1
}

if [ ! $# -eq 1 ]; then usage; fi

./stackcollapse.pl "$1" > "$1".collapsed
./stackcollapse.pl "$2" > "$2".collapsed

awk '
     FNR == NR {
	 a[$1] = $2;
	 next
     }
     ($1 in a) {
	 b[$1] = a[$1]-$2;
	 abs = b[$1] < 0 ? -b[$1] : b[$1];
	 
	 if (abs < min)
	     min = abs;
     }
     END {
	 for (i in b) {
	     print i, b[i]+min;
	 }
     }' "$1".collapsed "$2".collapsed
