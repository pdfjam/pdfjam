#!/bin/sh
cd "$(dirname -- "$0")"/..
man=doc/pdfjam.1
if [ -n "$(git status --porcelain "$man")" ]; then
	if [ -n "$(git diff --ignore-matching-lines='^\.TH PDFJAM' HEAD "$man")" ]; then
		date=$(date +%F)
	else
		date=$(git log --format=%as "$man"|sort|tail -n1)
	fi
	sed -Ei "1s/\"[0-9]{4}-[0-9]{2}-[0-9]{2}\"/\"$date\"/" "$man"
fi
