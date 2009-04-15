#!/bin/sh

START=1	# Section to start from (1-9)
END=9	# Section to end to (1-9)
MANDIR=/usr/share/man	# Path to directory where man page files reside

# MLINK is valid, if man page references the caller.
validate_file()
{
    SECTION=`basename $1 | awk -F '.' '{ print $(NF-1) }'`
    MANPAGE=`basename $1 | awk -F '.' '{ sub(/\.[^.]*\.[^.]*$/, ""); print }'`

    man $SECTION $MANPAGE 2>&- | col -b | grep -q "$MANPAGE"
    #echo "man $SECTION $MANPAGE | col -b | grep -q $MANPAGE"
    if [ $? -eq 0 ];
    then
	return
    fi

    echo "Possibly bogus MLINK to $MANPAGE($SECTION)"
}

# Scan a directory hierarchy and validate all man page files in it.
scan_path()
{
    for i in `seq $2 $3`
    do
	echo "--- Scanning section  $i ---"
	for j in `find "$1" -name "*.$i.gz"`
	do
	    #echo "Validating $j"
	    validate_file "$j"
	done
    done
}

# Print usage information.
usage()
{
    echo "usage: `basename $0` [-s start] [-e end] [-v] [-h] [man-dir]\n"
    exit 1
}

# Parse user supplied arguments.
while getopts "s:e:vh" f
do
    case $f in
	s)
	    START=$OPTARG
	    ;;
	e)
	    END=$OPTARG
	    ;;
	v)
	    VERBOSE=$f
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

# Fire!
scan_path "$MANDIR" $START $END