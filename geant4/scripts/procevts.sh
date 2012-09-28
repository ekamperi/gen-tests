#!/bin/bash
#
# USAGE: procevts outfile retaddr /path/to/binary args
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

dtrace -n '
BEGIN
{
	evtcnt = 0;
}

pid$target::_ZN14G4EventManager15ProcessOneEventEP7G4Event:entry
{
	self->pstart = vtimestamp;
}

pid$target::-:'$retaddr'
/self->pstart/
{
	t = (vtimestamp - self->pstart)/1000000;
	printf("evtcnt=%d t=%d\n", ++evtcnt, t);
	self->pstart = 0;
}' -c "$*" -o $outfile
