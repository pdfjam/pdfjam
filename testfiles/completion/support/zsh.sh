#!/bin/zsh

# https://unix.stackexchange.com/questions/668618/how-to-write-automated-tests-for-zsh-completion

usage() { echo "Usage: $0 [ -p prefix] [-s file] input [input ...]"; exit 1; }

# Set up completions
autoload -U compinit
compinit

prefix=
while :; do
	case "$1" in
		-s) source "$2" && shift 2 || usage ;;
		-p) prefix="$2" && shift 2 || usage ;;
		*) break ;;
	esac
done

compfake () {
	zstyle ':completion:*' list-prompt '<irrelevant>'
	zstyle ':completion:*' list-colors $'no=\CA' lc= rc= $'ec=\CD' $'sp=\CB' $'fi=\CF'
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
	zpty pty compfake   # Create a new pty and run our function in it.
	zpty -w pty "$@"$'\v'  # Write into vared
	(zpty -r pty) | # Read from pty using a subshell, ...
		grep -E $'\CA|\CF|<HEADER>' | # ... filter for relevant lines ...
		sed -E $' # ... and parse into a format of our liking.
	s/\e\\[J//g
	s/(\CB? +\CD)?\r$//
	s/\CA<DESCRIPTION>/:/
	s/(^|( )(\CD))[\CA\CF]([^\CD]+)\CD/\\3\\2\\4/g
	s/\CB *\CD//g
	s/\CA\CD//g
	'
	zpty -d pty  # Delete the pty.
}

for input; do
	echo -E ">>> $prefix$input..."
	comptest "$prefix$input"
done
