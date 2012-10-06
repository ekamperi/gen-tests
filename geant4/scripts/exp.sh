#!/bin/bash

set -e
#set -x

fullcms_orig=/home/stathis/gen-tests/geant4/geant4.9.5.p01-default-initialcopy/bin/Linux-g++/full_cms
fullcms_patc=/home/stathis/gen-tests/geant4/geant4.9.5.p01-default-initialcopy/bin/Linux-g++/full_cms
bench="bench1_10.g4"
user=stathis
host=island.quantumachine.net
file="~/public_html/geant4"

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
    iteration=$1
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
	"$1/${bench}.evts.orig.${iteration}" \
	"8c8fbe8"			     \
	"${fullcms_orig} ${bench}"

    invalidate_cpucaches
    procevts				     \
	"$1/${bench}.evts.patc.${iteration}" \
	"8c8fbe8"			     \
	"${fullcms_patc} ${bench}"
}

function do_cpi()
{
    invalidate_cpucaches
    cpi "$fullcms_orig" "$bench" > "$1/${bench}.cpi.orig.${iteration}"

    invalidate_cpucaches
    cpi "$fullcms_patc" "$bench" > "$1/${bench}.cpi.patc.${iteration}"
}

function do_dcmisses()
{
    invalidate_cpucaches
    dcmisses			\
	"$fullcms_orig"		\
	"$bench"		> "$1/${bench}.dc.orig.${iteration}"

    invalidate_cpucaches
    dcmisses			\
	"$fullcms_patc"	\
	"$bench"		> "$1/${bench}.dc.patc.${iteration}"
}

################################################################################
#				Flame graphs
################################################################################

function do_timeflame()
{
    rm -f timeflame.orig
    invalidate_cpucaches
    timeflame timeflame.orig "$fullcms_orig" "$bench"
    mv timeflame.orig.svg "$1/timeflame.orig.svg"

    rm -f timeflame.patc
    invalidate_cpucaches
    timeflame timeflame.patc "$fullcms_patc" "$bench"
    mv timeflame.patc.svg "$1/timeflame.patc.svg"
}

function do_dcmflame()
{
    rm -f dcmflame.orig
    invalidate_cpucaches
    dcmflame dcmflame.orig "$fullcms_orig" "$bench"
    mv dcmflame.orig.svg "$1/dcmflame.orig.svg"

    rm -f dcmflame.patc
    invalidate_cpucaches
    dcmflame dcmflame.patc "$fullcms_patc" "$bench"
    mv dcmflame.patc.svg "$1/dcmflame.patc.svg"
}

function do_icmflame()
{
    rm -f icmflame.orig
    invalidate_cpucaches
    icmflame icmflame.orig "$fullcms_orig" "$bench"
    mv icmflame.orig.svg "$1/icmflame.orig.svg"

    rm -f icmflame.patc
    invalidate_cpucaches
    icmflame icmflame.patc "$fullcms_patc" "$bench"
    mv icmflame.patc.svg "$1/icmflame.patc.svg"
}

function do_icmisses()
{
    invalidate_cpucaches
    icmisses                    \
        "$fullcms_orig"         \
        "$bench"                > "$1/${bench}.ic.orig.${iteration}"

    invalidate_cpucaches
    icmisses                    \
        "$fullcms_patc"      \
        "$bench"                > "$1/${bench}.ic.patc.${iteration}"
}

################################################################################
#				Graphs					       #
################################################################################

function do_cmpevts()
{
    cmpevts '::ProcessOneEvent()'		  \
	     "$1/${bench}.evts.orig.${iteration}" \
	     "$1/${bench}.evts.patc.${iteration}" > "$1/cmpevts.gplot"
}

function do_rcmpevts()
{
    rcmpevts '::ProcessOneEvent()'                \
	     "$1/${bench}.evts.orig.${iteration}" \
	     "$1/${bench}.evts.patc.${iteration}" > "$1/rcmpevts.rplot"
}

function do_cmpcpits()
{
    cmpcpits "$1/${bench}.cpi.orig.${iteration}" \
             "$1/${bench}.cpi.patc.${iteration}" > "$1/cmpcpits.gplot"
}

function do_cmpdcmts()
{
    cmpcmts "$1/${bench}.dc.orig.${iteration}" \
	    "$1/${bench}.dc.patc.${iteration}" > "$1/cmpdcmts.gplot"
}

function do_cmpicmts()
{
    cmpcmts "$1/${bench}.ic.orig.${iteration}" \
            "$1/${bench}.ic.patc.${iteration}" > "$1/cmpicmts.gplot"
}

function do_histcmpevts()
{
    datfile=${bench}.evts.orig.${iteration}-${bench}.evts.patc.${iteration}.dat
    histcmpevts "$1/$datfile" > "$1/histcmpevts.rplot"
}

function do_histcmpcpi()
{
    datfile=${bench}.cpi.orig.${iteration}-${bench}.cpi.patc.${iteration}.dat
    histcmpcpi "$1/$datfile" > "$1/histcmpcpi.rplot"
}

function do_histcmpdcm()
{
    datfile=${bench}.dc.orig.${iteration}-${bench}.dc.patc.${iteration}.dat
    histcmpcm "$1/$datfile" > "$1/histcmpdcm.rplot"
}

function do_histcmpicm()
{
    datfile=${bench}.ic.orig.${iteration}-${bench}.ic.patc.${iteration}.dat
    histcmpcm "$1/$datfile" > "$1/histcmpicm.rplot"
}

################################################################################
#			Descriptive Statistics				       #
################################################################################
function do_rsummary()
{
    rsummary "$1/${bench}.evts.orig.${iteration}" \
             "$1/${bench}.evts.patc.${iteration}" > "$1/rsummary.rplot"
}

################################################################################
#				Upload results				       #
################################################################################
function upload_results()
{
    echo "$bench" > "run-${iteration}/BENCH"

    echo ${bench}.evts.orig.${iteration}-${bench}.evts.patc.${iteration}.dat \
        > "run-${iteration}/HIST.EVTSDAT"

    echo ${bench}.cpi.orig.${iteration}-${bench}.cpi.patc.${iteration}.dat \
	> "run-${iteration}/HIST.CPIDAT"

    echo ${bench}.dc.orig.${iteration}-${bench}.dc.patc.${iteration}.dat \
	> "run-${iteration}/HIST.DCMDAT"

    echo ${bench}.ic.orig.${iteration}-${bench}.ic.patc.${iteration}.dat \
        > "run-${iteration}/HIST.ICMDAT"

    files=(general smartstack)
    for file in "${files[@]}"
    do
	cp "../notes/${file}.notes" "run-${iteration}"
    done

    cp compnotes.sh "run-${iteration}"
    scp -r "run-${iteration}" "${user}@${host}:${file}"
}

# DTrace needs escalated privileges
check_ifroot

mkdir -p    "run-${iteration}"

# Gather data with respect to time
do_procevts   "run-${iteration}"
do_cpi        "run-${iteration}"
do_dcmisses   "run-${iteration}"
do_icmisses   "run-${iteration}"
do_timeflame  "run-${iteration}"
do_dcmflame   "run-${iteration}"
do_icmflame   "run-${iteration}"

# Generate the time series graphs
do_cmpevts    "run-${iteration}"
do_rcmpevts   "run-${iteration}"
do_cmpcpits   "run-${iteration}"
do_cmpdcmts   "run-${iteration}"
do_cmpicmts   "run-${iteration}"

# Generate the histograms
do_histcmpevts "run-${iteration}"
do_histcmpcpi  "run-${iteration}"
do_histcmpdcm  "run-${iteration}"
do_histcmpicm  "run-${iteration}"

# Generate descriptive statistics
do_rsummary    "run-${iteration}"

# Upload the results
upload_results
