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

pid$target::_ZN14G4EventManager15ProcessOneEventEP7G4Event:entry
{
	self->pstart = vtimestamp;
}

pid$target::-:'$retaddr'
/self->pstart && (this->t = (vtimestamp - self->pstart)/1000000) > 500/
{
	@[ustack()] = sum(this->t);
}

pid$target::-:'$retaddr'
/self->pstart/
{
	self->pstart = 0;
}

' -c "$*" -o $outfile
