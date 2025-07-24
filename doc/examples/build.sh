#!/bin/bash
cd -- "$(dirname "$0")"

(
while read -r OPT VAR; do
	case "$OPT" in
		--*) ;;
		*) continue ;;
	esac
	eval pdfjam --outfile "'${OPT#--}.pdf'" $OPT "$VAR"
done
) <options
