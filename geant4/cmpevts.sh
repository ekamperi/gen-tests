#!/bin/bash
#
# cmpevts - plots some metric (e.g., time spent in bar() call) as a function
# of the event generation (1st, 2nd, ..., n-th).
#
# USAGE: cmpevts metricname file.1 file.2 | gnuplot > cmpevts.png
# USAGE: cmpevts metricname file.1 file.2 | gnuplot | display -
#
# Example: cmpevts '::ProcessOneEvent()' 
#

set -e
set -x

function erx()
{
    echo "$@" >&2
    exit 1
}

if [ ! $# -eq 3 ]; then
    erx "usage: $(basename $0) metric file.1 file.2"
fi

if [ ! -f "$2" ]; then erx "file '$2' does not exist"; fi
if [ ! -f "$3" ]; then erx "file '$3' does not exist"; fi

b2=$(basename $2)
b3=$(basename $3)

# Escape _ as gnuplot will think that what follows it, is a subscript
e2=${b2//_/\\_}
e3=${b3//_/\\_}

awk -F ' t=' '{ if (NF != 0) print $2 }' "$2" > "$2.parsed"
awk -F ' t=' '{ if (NF != 0) print $2 }' "$3" > "$3.parsed"

paste "$2.parsed" "$3.parsed" > $(dirname $2)/$b2-$b3.dat

cat <<EOF
set terminal png enhanced size 1024,768
set xlabel "event generation (1st, 2nd, 3rd, ..., n-th)" 
set ylabel "time (ns)"
set logscale y 

set title 'Time spent in $1'
plot '$b2-$b3.dat' using 1 with lines title '$e2',\
     '$b2-$b3.dat' using 2 with lines title '$e3'
EOF
