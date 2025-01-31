#!/bin/sh
## Run by l3build release which runs build.sh first
set -e
[ -n "$1" ] || { echo "Usage: $0 version"; exit 1; }
cd "$(dirname "$0")/../build"
version="$1"

mkdir -p release
cd release
rm -fr pdfjam-$version pdfjam-$version.zip pdfjam-$version.tar.gz
ln -Ts ../pdfjam pdfjam-$version
zip -r pdfjam-$version.zip pdfjam-$version
tar -cvhzf pdfjam-$version.tar.gz pdfjam-$version
git push "$(git config branch.master.remote)" "v$version"
gh release create v$version --title "Release v$version" --notes-file ANNOUNCEMENT.md pdfjam-$version.zip pdfjam-$version.tar.gz
