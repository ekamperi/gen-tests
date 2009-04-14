#!/bin/sh

START=1
END=9
MANDIR=/usr/share/man

# MLINK is valid, if man page references the caller.
validate_file()
{
    SECTION=`basename $1 | awk -F '.' '{ print $(NF-1) }'`
    MANPAGE=`basename $1 | awk -F '.' '{ sub(/\.[^.]*\.[^.]*$/, ""); print }'`

    ISREFD=`man $SECTION $MANPAGE | col -b | grep $MANPAGE`
    #echo "man $SECTION $MANPAGE | col -b | grep $MANPAGE"
    if [ ! -z "$ISREFD" ];
    then
	return
    fi

    echo "Possibly bogus MLINK to $MANPAGE($SECTION)"
}

# Scan a directory hierarchy and validate all man page files in it.
scan_path()
{
    for i in `seq $START $END`
    do
	echo "--- Scanning section  $i ---"
	for j in `find "$MANDIR" -name "*.$i.gz"`
	do
	    #echo "Validating $j"
	    validate_file "$j"
	done
    done
}

# Print usage information.
usage()
{
    echo "usage: `basename $0` [-s start] [-e end] [-v] [-h] man-dir\n"
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

# Make sure user input is valid.
[ $START -lt 1    ] && usage
[ $END   -gt 9    ] && usage
[ $START -gt $END ] && usage
[ -z "$MANDIR"    ] && usage
