#!/bin/bash
#
# evtplot - plots some metric (e.g., time spent in bar() call) as a function
# of the event generation (1st, 2nd, ..., n-th).
#
# USAGE: evtplot metric file.1 file.2 | gnuplot > evtplot.png
# USAGE: evtplot metric file.1 file.2 | gnuplot | display -
#

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

awk -F ' t=' '{ if (NF != 0) print $2 }' "$2" > "$2.parsed"
awk -F ' t=' '{ if (NF != 0) print $2 }' "$3" > "$3.parsed"

cat <<EOF
set terminal png enhanced size 1024,768
set xlabel "event generation (1st, 2nd, 3rd, ..., n-th)" 
set ylabel "time (ns)"
set logscale y 

set title 'Time spent in $1'
plot '$2.parsed' using 1 with lines title '$2',\
     '$3.parsed' using 1 with lines title '$3'
EOF
