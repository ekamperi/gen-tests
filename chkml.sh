#/bin/sh

for i in `seq 1 9`; do
    echo "--- Scanning section $i ---"
    find $1 -name "*.$i" -exec ./chkml {} \;
done
