#!/bin/bash

set -e
#set -x

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
    git clone "$1" >/dev/null 2>/dev/null
}

updaterepo()
{
    cd "$1" && git pull >/dev/null 2>/dev/null
}

mkdir -p "${reposdir}"
(
    cd "${reposdir}"
    for repo in "${repos[@]}"
    do
	echo "-> Fetching repository '${repo}'"
	clonerepo  "${host}/${repo}.git" || updaterepo "${repo}"
    done
)
