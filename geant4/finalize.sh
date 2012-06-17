#!/bin/bash

set -e
set -x

USER="beket"
HOST="leaf.dragonflybsd.org"
FILE="~/public_html/geant4"

ITERATION=$1

read BENCH <BENCH

wget -r -l1 --no-directories --directory-prefix="run-$ITERATION" \
    "http://leaf.dragonflybsd.org/~beket/geant4/run-$ITERATION"

(
    cd "run-$ITERATION"

    # Data Cache misses
    cat cmpcmts.gplot "${BENCH}.dc.orig.{$ITERATION}" \
		      "${BENCH}.dc.patc.{$ITERATION}" | gnuplot > cmpdcmts.png

    # Instruction Cache misses
    cat cmpcmts.gplot "${BENCH}.ic.orig.{$ITERATION}" \
                      "${BENCH}.ic.patc.{$ITERATION}" | gnuplot > cmpicmts.png

    # Histograms
    cat histcpmcm.rplot | R --vanilla --slave
)

scp cmpcmts.png   "${USER}@${HOST}:${FILE}/run-${ITERATION}"
scp histcpmcm.png "${USER}@${HOST}:${FILE}/run-${ITERATION}"

sed "s/@@iteration@@/${ITERATION}/" smartstack.notes > smartstack.notes2
