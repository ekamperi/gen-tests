#!/bin/bash

################################################################################
#
# It accepts as argument a file generated by x64pic.sh -q /path/to/full_cms file
# and it plots the CPI, CPU utilisation, and optimal CPI for amd64. Example
#
# cpiplot.sh file | gnuplot > cpiplot.png
#
################################################################################


if [ ! $# -eq 1 ]; then
    echo "usage: $(basename $0) file" >&2
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "file '$1' does not exist" >&2
    exit 1
fi

cat <<EOF
set terminal png enhanced size 1024,768

set xlabel "time (0.1s)" 
set ylabel "CPI/CPU utilization (logscale)"
set logscale y 

plot '$1' using 2 with lines title "Cycles per Instruction",\
     '$1' using 3 with lines title "CPU utilization",\
     0.33 title "Optimal CPI for amd64"
EOF
