#!/bin/zsh

# https://unix.stackexchange.com/questions/668618/how-to-write-automated-tests-for-zsh-completion

scriptname="$0"
usage() { echo "Usage: $scriptname [ -p prefix] [-s file] [-d debuglog] (--|input) [input ...]"; exit 1; }

local source=
local prefix=
local debug=cat
local -a ignore
local accept_no_files=
while :; do
	case "$1" in
		-s) source="$2" && shift 2 || usage ;;
		-p) prefix="$2" && shift 2 || usage ;;
		-d) debug=(tee -a "$2") && shift 2 || usage ;;
		-i) ignore+="$2" && shift 2 || usage ;;
		--) accept_no_files=1; shift ;&
		*) break ;;
	esac
done

[[ $# = 0 ]] && [[ -z "$accept_no_files" ]] && usage

# Simulate completion by invoking the zle (zsh command line editor) in a zpty (pseudo terminal)
#
# After running this function in a zpty, writing "${text}\v" into that zpty
# will perform completion as if ${text} were written at command position in a command line.
compfake () {
	# 0. Assumption: This is called inside a pseudo terminal (i.e. zpty)
	# 0a) Set the size of this pty to gigantic
	stty rows 100000 cols 2000
	# 1. Initialize the completion system
	autoload -Uz compinit
	compinit
	# 2. Setup the completion system
	# 2a) Source completion scripts into the system
	[ -n "$source" ] && source "$source"
	# 2b) Setup completion styles
	zstyle ':completion:*:descriptions' format '<HEADER>%d</HEADER>'
	zstyle ':completion:*' list-separator '<DESCRIPTION>'
	zstyle ':completion:*' list-prompt '<YOUR-SCREEN-IS-TO-SMALL>' # If you ever see this, just increase the terminal’s size.
	# completion matches print as "Xmatch^D", where
	#   X=^A for normal text, X=^F for all kinds of files and directories
	#   alignment spaces start with ^S, some files/directories end in ^D^Tx^D with x indicating file type
	zstyle ':completion:*' list-colors $'no=\CA' lc= rc= tc=$'\CT' $'ec=\CD' $'sp=\CS' \
		$'fi=\CF' $'di=\CF' $'ln=\CF' $'pi=\CF' $'so=\CF' $'bd=\CF' $'cd=\CF' $'or=\CF' $'mi=\CF' \
		$'su=\CF' $'su=\CF' $'sg=\CF' $'tw=\CF' $'ow=\CF' $'sa=\CF' $'st=\CF' $'ex=\CF'
	zstyle ':completion:*' group-name '' # Give each tag its own group of completions, possibly naming the same entry twice
	zstyle ':completion:*' force-list always # Show completions even if only one suggestion exists
	zstyle ':completion:*' ignored-patterns "$ignore[@]"
	# 2c) Define and bind a widget to fire the _main_completion function as if in command position and not in a vared.
	bindkey '\v' fake-complete
	zle -C fake-complete complete-word breakout-of-vared-completer
	breakout-of-vared-completer() {
		unset 'compstate[vared]'
		_main_complete "$@"
	}
	# 3. Profit: Invoke the line editor, waiting for input
	vared -c tmp
}

comptest() {
	zmodload zsh/zpty  # Load the pseudo terminal module.
	zpty pty compfake  # Create a new pty and run our function in it.
	zpty -w pty "BEGIN_COMMAND_MARKER= $@"$'\v'  # Write into vared
	(zpty -r pty) | # Read from pty using a subshell, ...
		$debug | # ... append to log for debugging, ...
		grep -E $'\CA|\CF|<HEADER>' | # ... filter for relevant lines, ...
		sed -E $' # ... and parse into a format of our liking.
	s/(\e[[0-9;]*[A-Za-z]|\r)*BEGIN_COMMAND_MARKER=.*//
	s/\e\\[J//g
	s/(\CS? +\CD)?\r$//
	s/\CA<DESCRIPTION>/:/
	s/\CD\CT//g
	s/(^|( )(\CD))[\CA\CF]([^\CD]+)\CD/\\3\\2\\4/g
	s/\CS *\CD//g
	s/\CA\CD//g
	'
	zpty -d pty  # Delete the pty.
}

for input; do
	echo -E ">>> $prefix$input..."
	comptest "$prefix$input"
done
