#!/bin/bash

#set -e
#set -x

USER="stathis"
HOST="island.quantumachine.net"
FILE="~/public_html/geant4"

if [ ! $# -eq 1 ]; then
    echo "usage: $(basename $0) file"
    exit 1
fi

ITERATION=$1

wget --no-directories --directory-prefix="run-${ITERATION}" \
    "http://${HOST}/~${USER}/geant4/run-${ITERATION}/BENCH"

read BENCH <"run-${ITERATION}/BENCH"

wget -r -l1 -R index.html --no-directories -np --directory-prefix="run-${ITERATION}" \
    "http://${HOST}/~${USER}/geant4/run-${ITERATION}"

(
    cd "run-${ITERATION}"

    # Events
    cat rcmpevts.rplot  | R --vanilla --slave

    # Cycles Per Instruction
    cat cmpcpits.gplot | gnuplot > cmpcpits.png

    # Data Cache misses
    cat cmpdcmts.gplot | gnuplot > cmpdcmts.png

    # Instruction Cache misses
    cat cmpicmts.gplot | gnuplot > cmpicmts.png

    # Histograms
    cat histcmpevts.rplot | R --vanilla --slave
    read HISTEVTSDAT <"HIST.EVTSDAT"
    cp "${HISTEVTSDAT}.png" histcmpevts.png

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
    scp rcmpevts.png     "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp rcmpevts2.png     "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp cmpcpits.png    "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp cmpdcmts.png    "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp cmpicmts.png    "${USER}@${HOST}:${FILE}/run-${ITERATION}"

    scp histcmpevts.png "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp histcmpcpi.png  "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp histcmpdcm.png  "${USER}@${HOST}:${FILE}/run-${ITERATION}"
    scp histcmpicm.png  "${USER}@${HOST}:${FILE}/run-${ITERATION}"

    sed "s/@@iteration@@/${ITERATION}/" smartstack.notes > smartstack.notes2
)

./compnotes.sh ${ITERATION}
