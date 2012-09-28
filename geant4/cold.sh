#!/bin/bash

set -e
set -x

function usage()
{
	echo "$(basename $0) stacks.1 stacks.2" >&2
	exit 1
}

if [ ! $# -eq 2 ]; then usage; fi

./stackcollapse.pl "$1" > "$1".collapsed
./stackcollapse.pl "$2" > "$2".collapsed

awk '
     FNR == NR {
	 a[$1] = $2;
	 next
     }
     ($1 in a) {
	 b[$1] = a[$1] - $2;
	 abs = b[$1] < 0 ? -b[$1] : b[$1];

	 if (abs < min)
	     min = abs;
     }
     END {
	 for (i in b) {
	     print i, b[i] + min;
	 }
     }' "$1".collapsed "$2".collapsed > "$1-$2".collapsed.diff

awk '{
    if ($2 > 0) {
	print $1, $2 > "collapsed.diff.dec"
    } else {
        print $1,-$2 > "collapsed.diff.inc"
    }
}' "$1-$2".collapsed.diff

cat collapsed.diff.dec | c++filt -np | sed 's/full_cms`//g' | ./2flamegraph.pl cold > dec.svg
cat collapsed.diff.inc | c++filt -np | sed 's/full_cms`//g' | ./2flamegraph.pl hot  > inc.svg

scp dec.svg stathis@island.quantumachine.net:~/public_html/geant4/dec.svg
scp inc.svg stathis@island.quantumachine.net:~/public_html/geant4/inc.svg
