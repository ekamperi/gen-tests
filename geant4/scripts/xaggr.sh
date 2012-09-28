#!/bin/bash

################################################################################
#
# This script takes as argument the output of the output of stack2dtrace.sh
# script (i.e., takes as argument the output of test.d), and extracts the
# aggregations for every simulated event.
#
# Each aggregation is directed to its own file named 'run.j', j=1,2,...,N
# under the directory $TARGETDIR (default: aggreresults)
#
# Summarily, a typical usage case would be the following:
#
#	... collect stack traces with the flamegraph approach ...
#	stack2dtrace.sh folded.file > test.d
#	./test.d -Z -x dynvarsize=4m "/path/to/bin/full_cms ./bench_1.g4" \
#		| tee dtrace.out
#	./xaggr.sh dtrace.out
#
#
################################################################################

TARGETDIR="aggrresults"

if [ ! $# -eq 1 ]; then
    echo "usage: $(basename $0) dtrace.out"
    exit 1
fi

mkdir -p "$TARGETDIR"
awk -v targetdir="$TARGETDIR" '
BEGIN{c=1}
/entry/,/Edep/ {
    if ($0 ~ /Edep/) {
	c++
    } else if ($0 !~ /entry/) {
	print > targetdir "/run." c
    }
}' $1
