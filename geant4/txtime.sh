#!/bin/bash
#
# txtime - track the total execution time of an executable
#
# USAGE: txtime iterations executable
# For example:
#	txtime 10 sleep 1
#

set -e
set -x

iterations=$1
shift
command=("$@")

TIMEFORMAT=%R

j=0
times=();
for ((j=0; j<$iterations; j++))
do
    sudo cat /devices/pseudo/dummy@0:0
    times+=("$({ time "${command[@]}"  >/dev/null 2>&1;} 2>&1)" )
done
echo "${times[*]}"
