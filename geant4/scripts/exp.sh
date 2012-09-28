#!/bin/bash

set -e
#set -x

FULLCMS_ORIG=/home/stathis/gen-tests/geant4/geant4.9.5.p01-default-initialcopy/bin/Linux-g++/full_cms
FULLCMS_PATCHED=/home/stathis/gen-tests/geant4/geant4.9.5.p01-default-initialcopy/bin/Linux-g++/full_cms
BENCH="bench1_10.g4"
USER=stathis
HOST=island.quantumachine.net
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
    err "usage: $(basename $0) exp-id"
else
    ITERATION=$1
fi

function check_ifroot()
{
    # EUID = 0 root, or non 0 otherwise
    ((!EUID)) ||
    err "You need to run this script as root!"
}

function invalidate_cpucaches()
{
    # This is a special pseudo device driver that calls wbinvd,
    # whenever we open it.
    cat /devices/pseudo/dummy@0:0 ||
    echo "WARNING: pseudo device driver for invalidating CPU caches not found"
}

# XXX: To be done- check if $BENCH exists

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

function timeflame()
{
    ./timeflame.sh "$@"
}

function dcmflame()
{
    ./dcmflame.sh "$@"
}

function icmflame()
{
    ./icmflame.sh "$@"
}

function icmisses()
{
    ./x64l2icmisses.sh -q "$@"
}

function cmpevts()
{
    ./cmpevts.sh "$@"
}

function rcmpevts()
{
    ./rcmpevts.sh "$@"
}

function rsummary()
{
    ./rsummary.sh "$@"
}

function cmpcpits()
{
    ./cmpcpits.sh "$@"
}

function cmpcmts()
{
    ./cmpcmts.sh "$@"
}

function histcmpevts()
{
    ./histcmpevts.sh "$@"
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
	"8c8fbe8"			     \
	"${FULLCMS_ORIG} ${BENCH}"

    invalidate_cpucaches
    procevts				     \
	"$1/${BENCH}.evts.patc.${ITERATION}" \
	"8c8fbe8"			     \
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

################################################################################
#				Flame graphs
################################################################################

function do_timeflame()
{
    rm -f timeflame.orig
    invalidate_cpucaches
    timeflame timeflame.orig "$FULLCMS_ORIG" "$BENCH"
    mv timeflame.orig.svg "$1/timeflame.orig.svg"

    rm -f timeflame.patc
    invalidate_cpucaches
    timeflame timeflame.patc "$FULLCMS_PATCHED" "$BENCH"
    mv timeflame.patc.svg "$1/timeflame.patc.svg"
}

function do_dcmflame()
{
    rm -f dcmflame.orig
    invalidate_cpucaches
    dcmflame dcmflame.orig "$FULLCMS_ORIG" "$BENCH"
    mv dcmflame.orig.svg "$1/dcmflame.orig.svg"

    rm -f dcmflame.patc
    invalidate_cpucaches
    dcmflame dcmflame.patc "$FULLCMS_PATCHED" "$BENCH"
    mv dcmflame.patc.svg "$1/dcmflame.patc.svg"
}

function do_icmflame()
{
    rm -f icmflame.orig
    invalidate_cpucaches
    icmflame icmflame.orig "$FULLCMS_ORIG" "$BENCH"
    mv icmflame.orig.svg "$1/icmflame.orig.svg"

    rm -f icmflame.patc
    invalidate_cpucaches
    icmflame icmflame.patc "$FULLCMS_PATCHED" "$BENCH"
    mv icmflame.patc.svg "$1/icmflame.patc.svg"
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

function do_rcmpevts()
{
    rcmpevts '::ProcessOneEvent()'                \
	     "$1/${BENCH}.evts.orig.${ITERATION}" \
	     "$1/${BENCH}.evts.patc.${ITERATION}" > "$1/rcmpevts.rplot"
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

function do_histcmpevts()
{
    datfile=${BENCH}.evts.orig.${ITERATION}-${BENCH}.evts.patc.${ITERATION}.dat
    histcmpevts "$1/$datfile" > "$1/histcmpevts.rplot"
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
#			Descriptive Statistics				       #
################################################################################
function do_rsummary()
{
    rsummary "$1/${BENCH}.evts.orig.${ITERATION}" \
             "$1/${BENCH}.evts.patc.${ITERATION}" > "$1/rsummary.rplot"
}

################################################################################
#				Upload results				       #
################################################################################
function upload_results()
{
    echo $BENCH > "run-${ITERATION}/BENCH"

    echo ${BENCH}.evts.orig.${ITERATION}-${BENCH}.evts.patc.${ITERATION}.dat \
        > "run-${ITERATION}/HIST.EVTSDAT"

    echo ${BENCH}.cpi.orig.${ITERATION}-${BENCH}.cpi.patc.${ITERATION}.dat \
	> "run-${ITERATION}/HIST.CPIDAT"

    echo ${BENCH}.dc.orig.${ITERATION}-${BENCH}.dc.patc.${ITERATION}.dat \
	> "run-${ITERATION}/HIST.DCMDAT"

    echo ${BENCH}.ic.orig.${ITERATION}-${BENCH}.ic.patc.${ITERATION}.dat \
        > "run-${ITERATION}/HIST.ICMDAT"

    files=(general smartstack)
    for file in "${files[@]}"
    do
	cp "../notes/${file}.notes" "run-$ITERATION"
    done

    cp compnotes.sh "run-$ITERATION"
    scp -r "run-$ITERATION" "${USER}@${HOST}:${FILE}"
}

# DTrace needs escalated privileges
check_ifroot

mkdir -p    "run-$ITERATION"

# Gather data with respect to time
do_procevts   "run-$ITERATION"
do_cpi        "run-$ITERATION"
do_dcmisses   "run-$ITERATION"
do_icmisses   "run-$ITERATION"
do_timeflame  "run-$ITERATION"
do_dcmflame   "run-$ITERATION"
do_icmflame   "run-$ITERATION"

# Generate the time series graphs
do_cmpevts    "run-$ITERATION"
do_rcmpevts   "run-$ITERATION"
do_cmpcpits   "run-$ITERATION"
do_cmpdcmts   "run-$ITERATION"
do_cmpicmts   "run-$ITERATION"

# Generate the histograms
do_histcmpevts "run-$ITERATION"
do_histcmpcpi  "run-$ITERATION"
do_histcmpdcm  "run-$ITERATION"
do_histcmpicm  "run-$ITERATION"

# Generate descriptive statistics
do_rsummary    "run-$ITERATION"

# Upload the results
upload_results
