#!/bin/sh

usage()
{
    printf "Usage: %s: [-s start] [-e end] [-v] [-h] src-dir validator\n" $(basename $0) >&2
    exit 1
}


# Default values
start=1		# section number to start from (1-9)
end=9		# section number to end to (1-9)
verbose=	# verbose level
srcdir=		# directory where then man pages reside
validator=	# path to the actual program that does the validation


# Parse user supplied arguments
while getopts "s:e:vh" f
do
    case $f in
	s)
	    start=$OPTARG
	    ;;
	e)
	    end=$OPTARG
	    ;;
	v)
	    verbose=$f
	    ;;
	h)
	    usage
	    ;;
	\?)
	    usage
	    ;;
    esac
done
shift `expr $OPTIND - 1`

srcdir=$1
validator=$2

# Validate user input
if [ $start -lt 1 ] || [ $end -gt 9 ] || [ $start -gt $end ] || [ -z "$srcdir" ]
then
    usage
fi


# For every section, check the respective man pages
for i in `seq $start $end`;
do
    echo "--- Scanning section $i ---"
    find "$srcdir" -name "*.$i" -exec "$validator" {} \;
done
