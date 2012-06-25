#!/bin/bash

set -e
#set -x

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

pics='BU_cpu_clk_unhalted'                      # cycles
pics=$pics,'FR_retired_x86_instr_w_excp_intr'   # instructions

/usr/bin/cputrack -tc $pics -T 0.2 "$@" |
{
    if ((quiet)); then
        pbind -b2 $(pgrep full_cms) > /dev/null;
    else
        pbind -b2 $(pgrep full_cms);
    fi
    awk -v quiet=$quiet 'BEGIN {
	if (!quiet) {
	    printf "%16s %8s %8s\n", "Instructions", "CPI", "%CPU";
	}
	skipped = 0
    }
    NR != 1 {			# skip first line (header)
	total  = $4 + 0		# to force arithmetic context
	cycles = $5 + 0
	instrs = $6 + 0

	if (total != 0 && cycles != 0 && instrs != 0) {
	    printf "%16u %8.2f %8.2f\n",
		instrs,
		instrs ?       cycles / instrs : 0,
		total  ? 100 * cycles / total  : 0
	} else {
	    ++skipped
	}
    }
    END {
	if (!quiet) {
	    printf "skipped = %d\n", skipped
	}
    }'
}
