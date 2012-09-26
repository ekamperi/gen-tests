#!/bin/bash

set -e
set -x

host="git://gitweb.dragonflybsd.org/~beket"
reposdir="git-repos"

repos=(
    "conf-files"
    "dtrace-scripts"
    "gen-tests"
    "mathlib"
    "pcca-dbdump"
    "pcca-tests"
)

clonerepo()
{
    ( cd "$1" && git clone "$2" )
}

updaterepo()
{
    ( cd "$1" && git pull )
}

mkdir -p "${reposdir}"
for repo in "${repos[@]}"
do
    echo "-> Fetching repository '${repo}'"
    clonerepo "${reposdir}" "${host}/${repo}.git" || updaterepo "${reposdir}/${repo}"
done
