#!/bin/sh
## Run by l3build unpack
set -e
[ -n "$1" ] || { echo "Usage: $0 version"; exit 1; }
cd "$(dirname "$0")/.."
target=build/pdfjam
version="$1"

rm -fr build/unpacked "$target"
mkdir -p build/local "$target/bin" "$target/man" build/unpacked build/release
cp COPYING pdfjam.conf README.md "$target"
<pdfjam.1 sed "1s/N\\.NN/${version}/"'
s+$repository+https://github.com/pdfjam/pdfjam+' >"$target/man/pdfjam.1"

echo "This is pdfjam $version" >"$target/VERSION-$version"
<pdfjam sed "1,20s/N\\.NN/${version}/" \
	| sed -e '/pdfjam-help.txt/{r pdfjam-help.txt' -e 'd}' >"$target/bin/pdfjam"
chmod a+x "$target"/bin/pdfjam

cp "$target/bin/pdfjam" build/unpacked

echo "Built pdfjam $version"
