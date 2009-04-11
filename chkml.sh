#!/bin/sh

# Check argument count
if [ $# -ne 2 ];
then
    echo 1>&2 Usage: chkml.sh target-dir checker-program
    exit 1
fi

# For every section, check the respective man pages
for i in `seq 1 9`;
do
    echo "--- Scanning section $i ---"
    find $1 -name "*.$i" -exec $2 {} \;
done
