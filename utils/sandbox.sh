#!/bin/sh
cd "$(dirname "$0")/.."

rm -rf build/bin
mkdir -p build/bin
for i in awk basename cat cp cut dirname extractbb file grep gs iconv kpsewhich ln lualatex mkdir mv od paperconf pdfinfo pdflatex realpath repstopdf rungs rm sed tee texlua tr tty uname xelatex; do
	ln -s "$(command -v "$i")" "build/bin/$i" || { echo "No $i command found. Something is seriously amiss."; exit 1; }
done

mkdir build/bin/libpaper
mv build/bin/paperconf build/bin/libpaper/

## For clueless people: do a "binary search" for several needles here and watch until all works out
# bin="$(pwd)/build/bin"
# cd /usr/bin
# for i in [a-z]*; do ln -sr "$i" "$bin/" done
