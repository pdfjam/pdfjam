#!/bin/zsh -fi

# https://unix.stackexchange.com/questions/668618/how-to-write-automated-tests-for-zsh-completion

usage() { echo "Usage: $0 [ -p prefix] [-s file] [--] input [input ...]"; exit 1; }

prefix=
source=
while :; do
	case "$1" in
		-s) source="$2" && shift 2 || usage ;;
		-p) prefix="$2" && shift 2 || usage ;;
		--) shift ;&
		*) break ;;
	esac
done

compfake () {
	autoload -Uz compinit
	compinit -D
	[ -n "$source" ] && source "$source"
	zstyle ':completion:*' list-prompt '<irrelevant>'
	# matches print as "Xmatch^D", where X=^A for normal text and ^F for all kinds of files; alignment spaces start with ^B
	zstyle ':completion:*' list-colors $'no=\CA' lc= rc= $'ec=\CD' $'sp=\CB' \
		$'fi=\CF' $'ln=\CF' $'pi=\CF' $'so=\CF' $'bd=\CF' $'cd=\CF' $'or=\CF' $'mi=\CF' $'su=\CF' $'su=\CF' $'sg=\CF' $'tw=\CF' $'ow=\CF' $'sa=\CF' $'st=\CF' $'ex=\CF'
	zstyle ':completion:*' list-separator '<DESCRIPTION>'
	zstyle ':completion:*:descriptions' format '<HEADER>%d</HEADER>'
	zstyle ':completion:*' force-list always
	# Bind a custom widget to \v.
	bindkey '\v' complete-word
	zle -C {,,}complete-word
	complete-word () {
		unset 'compstate[vared]'  # Ignore that we are in a vared
		_main_complete "$@"
	}
	stty rows 100000 cols 2000
	vared -c tmp # invoke line editor
}

comptest() {
	zmodload zsh/zpty  # Load the pseudo terminal module.
	zpty pty compfake  # Create a new pty and run our function in it.
	zpty -w pty "BEGIN_COMMAND_MARKER= $@"$'\v'  # Write into vared
	(zpty -r pty) | # Read from pty using a subshell, ...
		cat
	# 	grep -E $'\CA|\CF|<HEADER>' | # ... filter for relevant lines ...
	# 	sed -E $' # ... and parse into a format of our liking.
	# s/(\e[[0-9;]*[A-Za-z]|\r)*BEGIN_COMMAND_MARKER=.*//
	# s/\e\\[J//g
	# s/(\CB? +\CD)?\r$//
	# s/\CA<DESCRIPTION>/:/
	# s/(^|( )(\CD))[\CA\CF]([^\CD]+)\CD/\\3\\2\\4/g
	# s/\CB *\CD//g
	# s/\CA\CD//g
	# '
	zpty -d pty  # Delete the pty.
}

for input; do
	echo -E ">>> $prefix$input..."
	comptest "$prefix$input"
done
