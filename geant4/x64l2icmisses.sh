#!/bin/bash

set -e
set -x

usage()
{
    echo "usage: $(basename $0) [-h] [-q] command [args]"
    echo "-h: display this message"
    echo "-q: quiet mode (do not display header or footer)"
    exit 1
}

# Parse user supplied arguments
while getopts "hq" opt; do
    case $opt in
	h|\?)
	    usage
	    ;;
	q)
	    quiet=1
	    ;;
    esac
done

shift $((OPTIND-1))

# Check the left overs
if [ "$#" -eq 0 ]; then
    usage
fi

pics='IC_itlb_L1_miss_L2_hit'          # IC L2 hits
pics=$pics,'IC_itlb_L1_miss_L2_miss'   # IC L2 misses

/usr/bin/cputrack -c $pics,umask=31 -T 0.2 "$@" |
{
    if ((quiet)); then
	pbind -b2 $(pgrep full_cms) > /dev/null;
    else
	pbind -b2 $(pgrep full_cms);
    fi
    awk -v quiet=$quiet 'BEGIN {
	if (!quiet) {
	    printf "%16s %16s %8s\n", "IC Hits", "IC Misses", "% Misses/Hits";
	}
	skipped = 0
    }
    NR != 1 {			# skip first line (header)
	hits   = $4 + 0		# to force arithmetic context
	misses = $5 + 0

	if (hits == 0 && misses == 0) {
	    ++skipped
	} else {
	    printf "%16u %16u %8.2f %8.2f\n",
		hits,
		misses,
		100 * hits   / (hits + misses),
		100 * misses / (hits + misses)
	    fflush();   # so that one can tail -f output file and track progress
	}
    }
    END {
	if (!quiet)
	    printf "skipped = %d\n", skipped
    }'
}
