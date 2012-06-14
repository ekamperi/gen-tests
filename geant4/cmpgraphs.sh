#!/bin/bash
#
# cmpgraphs - generate gnuplot code that plots two data time series in the same
# graph to allow for comparison
#
# USAGE: cmpgraphs file1 file2 | gnuplot > graph.png
#
# The script takes as arguments 2 files generated by the x64l2{dc,ic}misses.sh
# scripts, and subsequently plots them in the same graph for comparison. A
# complete usage pattern would be something like:
#
# x64l2dcmisses.sh -q /path/to/binary > file1
# x64l2dcmisses.sh -q /path/to/binary > file2
# cmpgraphs file1 file2 | gnuplot > graph.png
#

set -e
#set -x

paste <(awk '{ print $4 }' $1) \
      <(awk '{ print $4 }' $2) > $1-$2.dat

# Escape _ as gnuplot will think that what follows it, is a subscript
e1=${1//_/\\_}
e2=${2//_/\\_}

cat<<EOF
set terminal png enhanced size 1024,768

set xlabel "time (0.1s)"
set ylabel "% Cache Misses (logscale)"
set logscale y

plot '$1-$2.dat' using 1 with points pointtype 6 title '$e1', \
     '$1-$2.dat' using 2 with points pointtype 7 title '$e2'
EOF
