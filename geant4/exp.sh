#!/bin/bash

set -e
set -x

FULLCMS_ORIG=/home/stathis/gen-tests/geant4/geant4.9.5.p01-default/bin/Linux-g++/full_cms
FULLCMS_PATCHED=/home/stathis/gen-tests/geant4/geant4.9.5.p01-smart/bin/Linux-g++/full_cms
BENCH="bench1_1.g4"
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

################################################################################
#				External scripts wrappers		       #
################################################################################

function procevts()
{
    ./procevts.sh "$@"
}

function cpi()
{
    ./x64ipc.sh -q "$@"
}

function dcmisses()
{
    ./x64l2dcmisses.sh -q "$@"
}

function icmisses()
{
    ./x64l2icmisses.sh -q "$@"
}

function cmpevts()
{
    ./cmpevts.sh "$@"
}

function cmpcpits()
{
    ./cmpcpits.sh "$@"
}

function cmpcmts()
{
    ./cmpcmts.sh "$@"
}

function histcmpcpi()
{
    ./histcmpcpi.sh "$@"
}

function histcmpcm()
{
    ./histcmpcm.sh "$@"
}

################################################################################
#				Gather data				       #
################################################################################

function do_procevts()
{
    invalidate_cpucaches
    procevts				     \
	"$1/${BENCH}.evts.orig.${ITERATION}" \
	"${FULLCMS_ORIG} ${BENCH}"

    invalidate_cpucaches
    procevts				     \
	"$1/${BENCH}.evts.patc.${ITERATION}" \
	"${FULLCMS_PATCHED} ${BENCH}"
}

function do_cpi()
{
    invalidate_cpucaches
    cpi "$FULLCMS_ORIG" "$BENCH" > "$1/${BENCH}.cpi.orig.${ITERATION}"

    invalidate_cpucaches
    cpi "$FULLCMS_PATCHED" "$BENCH" > "$1/${BENCH}.cpi.patc.${ITERATION}"
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

function do_icmisses()
{
    invalidate_cpucaches
    icmisses                    \
        "$FULLCMS_ORIG"         \
        "$BENCH"                > "$1/${BENCH}.ic.orig.${ITERATION}"

    invalidate_cpucaches
    icmisses                    \
        "$FULLCMS_PATCHED"      \
        "$BENCH"                > "$1/${BENCH}.ic.patc.${ITERATION}"
}

################################################################################
#				Graphs					       #
################################################################################

function do_cmpevts()
{
    cmpevts '::ProcessOneEvent()'		  \
	     "$1/${BENCH}.evts.orig.${ITERATION}" \
	     "$1/${BENCH}.evts.patc.${ITERATION}" > "$1/cmpevts.gplot"
}

function do_cmpcpits()
{
    cmpcpits "$1/${BENCH}.cpi.orig.${ITERATION}" \
             "$1/${BENCH}.cpi.patc.${ITERATION}" > "$1/cmpcpits.gplot"
}

function do_cmpdcmts()
{
    cmpcmts "$1/${BENCH}.dc.orig.${ITERATION}" \
	    "$1/${BENCH}.dc.patc.${ITERATION}" > "$1/cmpdcmts.gplot"
}

function do_cmpicmts()
{
    cmpcmts "$1/${BENCH}.ic.orig.${ITERATION}" \
            "$1/${BENCH}.ic.patc.${ITERATION}" > "$1/cmpicmts.gplot"
}

function do_histcmpcpi()
{
    datfile=${BENCH}.cpi.orig.${ITERATION}-${BENCH}.cpi.patc.${ITERATION}.dat
    histcmpcpi "$1/$datfile" > "$1/histcmpcpi.rplot"
}

function do_histcmpdcm()
{
    datfile=${BENCH}.dc.orig.${ITERATION}-${BENCH}.dc.patc.${ITERATION}.dat
    histcmpcm "$1/$datfile" > "$1/histcmpdcm.rplot"
}

function do_histcmpicm()
{
    datfile=${BENCH}.ic.orig.${ITERATION}-${BENCH}.ic.patc.${ITERATION}.dat
    histcmpcm "$1/$datfile" > "$1/histcmpicm.rplot"
}

################################################################################
#				Upload results				       #
################################################################################
function upload_results()
{
    echo $BENCH > "run-${ITERATION}/BENCH"

    echo ${BENCH}.cpi.orig.${ITERATION}-${BENCH}.cpi.patc.${ITERATION}.dat \
	> "run-${ITERATION}/HIST.CPIDAT"

    echo ${BENCH}.dc.orig.${ITERATION}-${BENCH}.dc.patc.${ITERATION}.dat \
	> "run-${ITERATION}/HIST.DCMDAT"

    echo ${BENCH}.ic.orig.${ITERATION}-${BENCH}.ic.patc.${ITERATION}.dat \
        > "run-${ITERATION}/HIST.ICMDAT"

    cp smartstack.notes "run-$ITERATION"
    scp -r "run-$ITERATION" "${USER}@${HOST}:${FILE}"
}

mkdir -p    "run-$ITERATION"

# Gather data with respect to time
do_procevts   "run-$ITERATION"
do_cpi        "run-$ITERATION"
do_dcmisses   "run-$ITERATION"
do_icmisses   "run-$ITERATION"

# Generate the time series graphs
do_cmpevts    "run-$ITERATION"
do_cmpcpits   "run-$ITERATION"
do_cmpdcmts   "run-$ITERATION"
do_cmpicmts   "run-$ITERATION"

# Generate the histograms
do_histcmpcpi "run-$ITERATION"
do_histcmpdcm "run-$ITERATION"
do_histcmpicm "run-$ITERATION"

upload_results
