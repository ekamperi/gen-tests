#!/usr/bin/env bash

#set -e
set -x

remoteurl="git+ssh://beket@leaf.dragonflybsd.org/home/beket/git"
remotename="leaf"

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
    "pcca-site"
)

bitbrepos=(
    "e-galinos"
)

# $1 is the parent directory which holds all the individual
# git repositories
# $2 is the repo name
clonerepo()
{
    ( cd "$1" && git clone "${host}/${2}.git" &&
	( cd "$2" && git remote add "$remotename" "$remoteurl/${2}.git"))
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
	clonerepo "${reposdir}" "${repo}" || updaterepo "${reposdir}/${repo}"
    done
}

dohost "${leafhost}" "${leafrepos[@]}"
dohost "${bitbhost}" "${bitbrepos[@]}"
