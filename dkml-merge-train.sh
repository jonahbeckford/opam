#!/bin/sh

# To use this script you will need to:
# 1) `git switch master` (see `git remote add jb` below)
# 2) `git merge --ff-only upstream/master`
# 3) `git cherry-pick HERE_COMMIT` where HERE_COMMIT are all the commits of this
#    script in the 'dkml' branch; it may be labeled "... (2/n)", "... (3/n)",
#    etc.
# 4) `with-dkml ./dkml-merge-train.sh`
#
# Edits to this script must do `git reset --hard HERE_COMMIT`. And then
# amend the HERE_COMMIT with your edits.
#
# The following older build notes may be of use:
#
#   2. `opam install . --with-test --deps-only`
#      which will fail on dose3. But keep the other packages.
#   3. `opam uninstall cudf`
#   4. ```bash
#      git clean -d -x -f src_ext && make -C src_ext clone-pkg
#      PKGSKIP=() && for i in findlib ocamlbuild cppo extlib re ocamlgraph cudf; do PKGSKIP+=(-o $i.pkgbuild); done
#      PKGSKIP=() && for i in dune-local findlib ocamlbuild cppo extlib re ocamlgraph; do PKGSKIP+=(-o $i.pkgbuild); done
#      rm -f src_ext/dose3.pkgbuild src_ext/mccs.pkgbuild src_ext/cudf.pkgbuild && make -C src_ext "${PKGSKIP[@]}" mccs.pkgbuild cudf.pkgbuild dose3.pkgbuild
#      ```
#   5. `MSVS_PREFERENCE='VS16.*;VS15.*;VS14.0;VS12.0;VS11.0;10.0;9.0;8.0;7.1;7.0' ./configure --enable-developer-mode`
#      (`--enable-developer-mode` is optional)
#   6. `make`
#   7. Optional: `make install`

set -euf

if [ -n "${MSYSTEM:-}" ]; then
    HOME=$(cygpath "$USERPROFILE")
fi

git remote add jb https://github.com/jonahbeckford/opam.git || true
git fetch jb

git remote add upstream https://github.com/ocaml/opam.git || true
git fetch upstream

# Open PRs and auditing done at https://gist.github.com/jonahbeckford/96f4845998403459cd76049b5fc7e48a

# shellcheck disable=SC2043
# for i in 4816; do
#     git fetch upstream pull/$i/head:pr$i
# done

git branch -D dkml || true
git switch -c dkml
git merge jb/windows-2-2-opamroot
git merge feature-opam-env-spaces-more
# git merge pr4816

# Tag before ("-") the next tag ... aka prerelease ... using normal semver
# ordering (which is compatible with Git tag syntax). In Opam semantic
# versioning of prereleases uses "~".
# Ex. 2.2.0~alpha~dev -> 2.2.0-dkml20220503T200645Z
nexttag=$(awk 'BEGIN{FS="[,~]"} /^AC_INIT/{print $2;exit}' configure.ac)
now=$(date -u +%Y%m%dT%H%M%SZ)
git tag "$nexttag-dkml$now"
