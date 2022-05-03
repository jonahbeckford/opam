#!/bin/sh

# To use this script you will need to:
# 1) Pull the latest changes into your master branch
# 2) `git reset --hard HERE_COMMIT` where HERE_COMMIT is where this SCRIPT
#    was introduced.
# 3) `git rebase -i master`
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

for i in 4816 4844; do git fetch upstream pull/$i/head:pr$i; done

git merge windows-2-2-opamroot
git merge pr4816
git merge pr4844

# Tag before ("-") the next tag ... aka prerelease ... using normal semver
# ordering (which is compatible with Git tag syntax). In Opam semantic
# versioning of prereleases uses "~".
# Ex. 2.2.0~alpha~dev -> 2.2.0-dkml20220503T200645Z
nexttag=$(awk 'BEGIN{FS="[,~]"} /^AC_INIT/{print $2;exit}' configure.ac)
now=$(date -u +%Y%m%dT%H%M%SZ)
git tag "$nexttag-dkml$now"
