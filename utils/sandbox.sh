#!/bin/sh
cd "$(dirname "$0")/.."

rm -rf build/bin
mkdir -p build/bin
for i in awk basename bash cat cp cut dirname extractbb file grep gs iconv kpsewhich ksh ln lualatex mkdir mv od paperconf pdfinfo pdflatex realpath repstopdf rungs rm sed sh tee texlua tr tty uname xelatex zsh; do
	ln -s "$(command -v "$i")" "build/bin/$i" || { echo "No $i command found. Something is seriously amiss."; error=1; }
done
[ -n "$error" ] && exit 1

mkdir build/bin/libpaper
mv build/bin/paperconf build/bin/libpaper/

## For clueless people: do a "binary search" for several needles here and watch until all works out
# bin="$(pwd)/build/bin"
# cd /usr/bin
# for i in [a-z]*; do ln -sr "$i" "$bin/" done
