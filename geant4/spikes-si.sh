#!/bin/bash
#
# USAGE: spikes outfile retaddr /path/to/binary args
#

set -e
set -x

function usage()
{
    echo "usage: $(basename $0) outfile [default | patched] /path/to/binary args" >&2
    exit 1
}

outfile="$1"
shift

retaddr="$1"
shift

dtrace -q -x nspec=5 -x bufsize=16m -x specsize=16m -x switchrate=5hz -x ustackframes=100 -x strsize=5000 -n '
BEGIN
{
	tracing = 0;
	spec = 0;
	spec2 = 0;
}

pid$target::*DoEventLoop*:entry
{
	tracing = 1;
}

pid$target::*DoEventLoop*:return
{
	exit(0);
}

pid$target::_ZN14G4EventManager15ProcessOneEventEP7G4Event:entry
{
	self->pstart = vtimestamp;
	spec = speculation();
}

simple$target:::
/tracing && spec/
{
	speculate(spec);
	printf("%d %d %d %d %d\n", arg0, arg1, arg2, arg3, arg4);
}

pid$target::-:'$retaddr'
/self->pstart/
{
	self->t = (vtimestamp - self->pstart)/1000000;
	self->pstart = 0;
}

pid$target::-:'$retaddr'
/spec && self->t >= 4000/
{
	commit(spec);
	spec = 0;
}

pid$target::-:'$retaddr'
/spec && self->t < 4000/
{
	discard(spec);
	spec = 0;
}

' -c "$*" -o $outfile
