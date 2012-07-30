#!/bin/bash

set -e
set -x

function erx()
{
    echo "$@" >&2
    exit 1
}

if [ ! $# -eq 2 ]; then
    erx "usage: $(basename $0) file.1 file.2"
fi

if [ ! -f "$1" ]; then erx "file '$1' does not exist"; fi
if [ ! -f "$2" ]; then erx "file '$2' does not exist"; fi

b1=$(basename $1)
b2=$(basename $2)

awk -F ' t=' '{ if (NF != 0) print $2 }' "$1" > "$1.parsed"
awk -F ' t=' '{ if (NF != 0) print $2 }' "$2" > "$2.parsed"

paste "$1.parsed" "$2.parsed" > $(dirname $1)/$b1-$b2.dat

cat <<EOF
dat <- read.table('$b1-$b2.dat')

## First column is always the original data, and second is always the
## patched version of them.
names(dat) <- c('orig', 'patc')

## Start a diversion of R output to a file named 'summary.txt'.
## We will be importing the contents of 'summary.txt' to our
## asciidoc-generated report.
sink('summary.txt')

## Calculate some descriptive statistics, including standard deviation.
cat('---- Summary statistics ----\n')
summary(dat)

cat('\n---- Standard deviation ----\n')
sapply(dat, sd)

## End the last diversion.
sink()
EOF
