#!/bin/bash

# See `git remote add jb` below for the remotes you need to have before using the script.
#
# To use this script you will need to:
# 1) Either do:
#    a1. `git pull --rebase upstream master` from the jb/master branch
#  or do the following:
#    a2. Pull the latest changes into your jb/master branch
#    b2. `git reset --hard HERE_COMMIT` where HERE_COMMIT is where this SCRIPT
#       was introduced.
#    c2. `git rebase -i jb/master`
#
# Edits to this script must do `git reset --hard HERE_COMMIT`. And then
# amend the HERE_COMMIT with your edits.

set -euf

if [ -n "${MSYSTEM:-}" ]; then
    HOME=$(cygpath "$USERPROFILE")
fi

git remote add jb https://github.com/jonahbeckford/opam.git || true
git fetch jb

git remote add upstream https://github.com/ocaml/opam.git || true
git fetch upstream

# Open PRs and auditing done at https://gist.github.com/jonahbeckford/96f4845998403459cd76049b5fc7e48a
#   PRS=( 4816 4844 )
PRS=()
set +u # workaround bash bug with empty arrays in for loops
for pr in "${PRS[@]}"; do
    git fetch upstream "pull/$pr/head:pr$pr"
done
set -u

git branch -D dkml || true
git switch -c dkml
git merge jb/windows-2-2-opamroot

set +u # workaround bash bug with empty arrays in for loops
for pr in "${PRS[@]}"; do
    git merge "pr$pr"
done
set -u


# Tag before ("-") the next tag ... aka prerelease ... using normal semver
# ordering (which is compatible with Git tag syntax). In Opam semantic
# versioning of prereleases uses "~".
# Ex. 2.2.0~alpha~dev -> 2.2.0-dkml20220503T200645Z
nexttag=$(awk 'BEGIN{FS="[,~]"} /^AC_INIT/{print $2;exit}' configure.ac)
now=$(date -u +%Y%m%dT%H%M%SZ)
git tag "$nexttag-dkml$now"
