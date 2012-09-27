#!/bin/bash

if [ ! -f "$1" ]; then
    echo "file '$1' does not exist" >&2
    exit 1
fi

cat <<EOF
set terminal png
set xlabel "time (0.1s)" 
set ylabel "CPI/CPU utilization (logscale)"
set logscale y 

plot '$1' using 2 with lines title "Cycles per Instruction",\
     '$1' using 3 with lines title "CPU utilization",\
     0.33 title "Optimal CPI for amd64"
EOF
