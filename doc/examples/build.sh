#!/bin/bash
cd -- "$(dirname "$0")"
mkdir -p out

(
while read -r OPT VAR; do
	case "$OPT" in
		--*) ;;
		*) continue ;;
	esac
	eval pdfjam --outfile "'out/${OPT#--}.pdf'" $OPT "$VAR"
done
) <options
