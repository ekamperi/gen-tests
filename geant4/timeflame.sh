#!/bin/bash
#
# USAGE: timeflame outfile /path/to/binary args
#

set -e
set -x

function usage()
{
    echo "usage: $(basename $0) outfile /path/to/binary args" >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

outfile="$1"
shift

binary=$(basename $1)
title="Flame Graph of ${binary} CPU time - ${outfile}"

dtrace -x ustackframes=100 -x strsize=5000 -n '
BEGIN
{
	tracing = 0;
}

pid$target::*DoEventLoop*:entry
{
	tracing = 1;
}

pid$target::*DoEventLoop*:return
{
	exit(0);
}

profile-97
/pid == $target && tracing != 0/
{
	@[ustack()] = count();
}' -c "$*" -o "$outfile"

./stackcollapse.pl "$outfile"    |
c++filt -n -p			 |
sed "s/${binary}\`//g"           |
grep -v StatAccepTest            |
./flamegraph.pl			 |
sed "s/Flame Graph/${title}/g" > "${outfile}.svg"
