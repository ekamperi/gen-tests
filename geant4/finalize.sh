#!/bin/bash

set -e
set -x

USER="beket"
HOST="leaf.dragonflybsd.org"
FILE="~/public_html/geant4"

if [ ! $# -eq 1 ]; then
    echo "usage: $(basename $0) file"
    exit 1
fi

ITERATION=$1

wget --no-directories --directory-prefix="run-${ITERATION}" \
    "http://leaf.dragonflybsd.org/~beket/geant4/run-${ITERATION}/BENCH"

read BENCH <"run-${ITERATION}/BENCH"

wget -r -l1 -R index.html --no-directories -np --directory-prefix="run-${ITERATION}" \
    "http://leaf.dragonflybsd.org/~beket/geant4/run-${ITERATION}"

(
    cd "run-${ITERATION}"

    # Cycles Per Instruction
    cat cmpcpits.gplot | gnuplot > cmpcpits.png

    # Data Cache misses
    cat cmpdcmts.gplot | gnuplot > cmpdcmts.png

    # Instruction Cache misses
    cat cmpicmts.gplot | gnuplot > cmpicmts.png

    # Histograms
    cat histcmpcpi.rplot | R --vanilla --slave
    read HISTCPIDAT <"HIST.CPIDAT"
    cp "${HISTCPIDAT}.png" histcmpcpi.png

    cat histcmpdcm.rplot | R --vanilla --slave
    read HISTDCMDAT <"HIST.DCMDAT"
    cp "${HISTDCMDAT}.png" histcmpdcm.png

    cat histcmpicm.rplot | R --vanilla --slave
    read HISTICMDAT <"HIST.ICMDAT"
    cp "${HISTICMDAT}.png" histcmpicm.png

    # Upload the results
    scp cmpcpits.png   "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp cmpdcmts.png   "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp cmpicmts.png   "${USER}@${HOST}:${FILE}/run-${ITERATION}"

    scp histcmpcpi.png "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp histcmpdcm.png "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp histcmpicm.png "${USER}@${HOST}:${FILE}/run-${ITERATION}"

    sed "s/@@iteration@@/${ITERATION}/" smartstack.notes > smartstack.notes2
)
