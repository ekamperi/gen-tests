#!/bin/bash

set -e
set -x

leafhost="git://gitweb.dragonflybsd.org/~beket"
bitbhost="https://ekamperi@bitbucket.org/ekamperi"
reposdir="git-repos"

leafrepos=(
    "conf-files"
    "dtrace-scripts"
    "gen-tests"
    "mathlib"
    "pcca-dbdump"
    "pcca-tests"
)

bitbrepos=(
    "e-galinos"
)

clonerepo()
{
    ( cd "$1" && git clone "$2" )
}

updaterepo()
{
    ( cd "$1" && git pull )
}

# First argument is host, and second the array with the repos
dohost()
{
    local host="$1"
    shift

    mkdir -p "${reposdir}"
    for repo in "${@}"
    do
	echo "-> Fetching repository '${repo}'"
	clonerepo "${reposdir}" "${host}/${repo}.git" || updaterepo "${reposdir}/${repo}"
    done
}

dohost "${leafhost}" "${leafrepos[@]}"
dohost "${bitbhost}" "${bitbrepos[@]}"
