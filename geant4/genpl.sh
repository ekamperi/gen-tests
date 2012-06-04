#!/bin/bash

################################################################################
#
# It reads all the files from the current directory, containing time series
# data and for each one of the it generates a .plot gnuplot file, runs it,
# and produces a PNG file.
#
# XXX: Replace _Z* with robust code (e.g., exp() won't be matched now)
#
################################################################################

set -e
set -x

PLOTRESULTS_DIR="plotresults"

plotfile()
{
    cat > "$1".plot <<EOF
set terminal png
set xlabel "#n of event (1, 2, 3, ... )"
set ylabel "avg time(ns)"
plot '$1' with lines smooth csplines

EOF
}

rm   -rf "$PLOTRESULTS_DIR"
mkdir -p "$PLOTRESULTS_DIR"

# Generate the gnuplot scripts
for f in _Z*;
do
    cp  "$f" "$PLOTRESULTS_DIR/"
    plotfile "$PLOTRESULTS_DIR/$f"
done

# Generate the graphs
for f in $PLOTRESULTS_DIR/*.plot;
do
    gnuplot < "$f" > "$f.png"
done
