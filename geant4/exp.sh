#!/bin/bash

set -e
set -x

FULLCMS_ORIG=/home/stathis/gen-tests/geant4/geant4.9.5.p01/bin/Linux-g++/full_cms
FULLCMS_PATCHED=/home/stathis/gen-tests/geant4/geant4.9.5.p01/bin/Linux-g++/full_cms
BENCH="bench1_10.g4"
USER=beket
HOST=leaf.dragonflybsd.org
FILE="~/public_html/geant4"

function log()
{
    echo >&2 "$@"
}

function err()
{
    echo 1>&2 "$@"
    exit 1
}

if [ ! $# -eq 1 ]; then
    err "usage: $(basename $0)"
else
    ITERATION=$1
fi

function invalidate_cpucaches()
{
    # This is a special pseudo device driver that calls wbinvd,
    # whenever we open it.
    cat /devices/pseudo/dummy@0:0
}

function dcmisses()
{
    ./x64l2dcmisses.sh -q "$@"
}

function icmisses()
{
    ./x64l2icmisses.sh -q "$@"
}

function cmpcmts()
{
    ./cmpcmts.sh "$@"
}

function histcmpcm()
{
    ./histcmpcm.sh "$@"
}

function do_dcmisses()
{
    invalidate_cpucaches
    dcmisses			\
	"$FULLCMS_ORIG"		\
	"$BENCH"		> "$1/${BENCH}.dc.orig.${ITERATION}"

    invalidate_cpucaches
    dcmisses			\
	"$FULLCMS_PATCHED"	\
	"$BENCH"		> "$1/${BENCH}.dc.patc.${ITERATION}"
}

function do_cmpcmts()
{
    cmpcmts "$1/${BENCH}.dc.orig.${ITERATION}" \
	    "$1/${BENCH}.dc.patc.${ITERATION}" > "$1/cmpcmts.gplot"
}

function do_histcmpcm()
{
    datfile=${BENCH}.dc.orig.${ITERATION}-${BENCH}.dc.patc.${ITERATION}.dat
    log $datfile

    histcmpcm "$1/$datfile" > "$1/histcpmcm.rplot"
}

function upload_results()
{
    scp -r "run-$ITERATION" "${USER}@${HOST}:${FILE}"
}

mkdir -p     "run-$ITERATION"
do_dcmisses  "run-$ITERATION"
do_cmpcmts   "run-$ITERATION"
do_histcmpcm "run-$ITERATION"

upload_results
