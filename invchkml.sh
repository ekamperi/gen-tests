#!/bin/sh

start=1	# section number to start from (1-9)
end=9	# section number to end to (1-9)
mandir=/usr/share/man	# directory where the man pages reside

usage()
{
    printf "Usage: %s: [-s start] [-e end] [-v] [-h] man-dir\n" \
	$(basename $0) >&2
    exit 1
}

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

validate_file()
{
    section=`basename $1 | awk -F '.' '{ print $(NF-1) }'`
    manpage=`basename $1 | awk -F '.' '{ sub(/\.[^.]*\.[^.]*$/, ""); print }'`

    isrefd=`man $section $manpage | col -b | grep $manpage`
    echo "man $section $manpage | col -b | grep $manpage"
    if [ ! -z "$isrefd" ];
    then
	return
    fi

    echo "Possibly bogus MLINK to $manpage($section)"
}

# Validate user input
[ $start -lt 1    ] && usage
[ $end   -gt 9    ] && usage
[ $start -gt $end ] && usage
[ -z "$mandir"    ] && usage

for i in `seq $start $end`
do
    echo "--- Scanning section  $i ---"
    for j in `find "$mandir" -name "z*.$i.gz"`
    do
	echo "Validating $j"
	validate_file "$j"
    done
done
