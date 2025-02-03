#!/bin/zsh

# https://unix.stackexchange.com/questions/668618/how-to-write-automated-tests-for-zsh-completion

# Set up completions
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' select-prompt ''
autoload -U compinit
compinit

source /home/markus/src/pdfjam/doc/shell-completion/zsh/_pdfjam

comptest () {
    zstyle ':completion:*' list-prompt '<STUPID>'
    zstyle ':completion:*' list-colors 'no=<COMPLETION>' lc= rc= ec= sp=
    zstyle ':completion:*' list-separator '<DESCRIPTION>'
    zstyle ':completion:*:messages' format '<MESSAGE>%d</MESSAGE>'
    zstyle ':completion:*:descriptions' format '<HEADER>%d</HEADER>'
    zstyle ':completion:*' menu select
    # Bind a custom widget to \v.
    bindkey '\v' complete-word
    zle -C {,,}complete-word
    complete-word () {
        # Make the completion system believe we're on a normal command line, not in vared.
        unset 'compstate[vared]'
        _main_complete "$@"
        compadd -J -last- -x '<LAST>'
    }
    vared -c tmp # trigger output
}

# TODO: tables can occur with descriptions as well
# TODO: Fake terminal size to be bigggggg.
compout() {
zmodload zsh/zpty  # Load the pseudo terminal module.
zpty {,}comptest   # Create a new pty and run our function in it.

# Simulate a command being typed, ending with \v to get completions and lots of \t to get all the screens.
zpty -w comptest "$@"$'\v\t\t\t\t'
#zpty -r comptest # for debugging
REPLY=$((zpty -r comptest) | sed -En '
s/(\[J|<STUPID>.*)?<COMPLETION>(\S*).*<COMPLETION>((\S+)( ))?.*<COMPLETION><DESCRIPTION> (.*\S) +(\[J)?$/\2\5\4: \6/p
s/(\[J|<STUPID>.*)?<COMPLETION>(\S*).*<COMPLETION><DESCRIPTION> (.*\S) +(\[J)?$/\2: \3/p
s/<COMPLETION>(.*)/\1<COMPLETION>/
s/(\w*)\s*(\[J( *)?)?<COMPLETION>/\1<COMPLETION>/gp
')
zpty -d comptest  # Delete the pty.
s=(${(M)${(f)REPLY}:#*<COMPLETION>})
a=()
while [[ -n "${(j::)s}" ]]; do
    for ((i=1; i<=$#s; ++i)); do
        a+="${${s[$i]#<COMPLETION>}%%<COMPLETION>*}"
        s[$i]=${s[$i]#*<COMPLETION>}
    done
done
described=(${${(f)REPLY}:#*<COMPLETION>})
echo $REPLY
echo ${(F)described}
echo ${(F)a}
}

# compout "pdfjam --papersize 1"
compout "pdfjam -"
