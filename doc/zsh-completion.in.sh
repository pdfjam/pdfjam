#compdef pdfjam

_pdfjam() {
	local paperformats=(a0 a1 a2 a3 a4 a5 a6 b0 b1 b2 b3 b4 b5 b6 c0 c1 c2 c3 c4 c5 c6 ansia ansib ansic ansid ansie letter legal executive b0j b1j b2j b3j b4j b5j b6j)
	local paperflags=(
		--${^paperformats:#b?j}paper
		--${(M)^paperformats:#b?j}
	)
	local options=(
		!!!OPTIONS!!!
	)

	_file_or_pagespec() {
		_files -g '*.(pdf|ps|eps|jpg|png)'
		# If the previous word is a pdf or ps file and a normal argument then it may be a pagespec.
		[[ "${(L)words[$CURRENT-1]}" = *.(pdf|ps) ]] && _normal_argument_follows "$words[1,$CURRENT-2]" && _pagespec
	}

	_arguments -S '*:file or pagespec:_file_or_pagespec' $options
}

_normal_argument_follows() {
	while shift 2>/dev/null; do
		if [[ "$1" = -- ]]; then
			return
		elif _option_expects_argument "$1"; then
			shift 2>/dev/null || return
		fi
	done
}

_option_expects_argument() {
	[[ "$1" = -* ]] &&
	! [[ "${(M)#flags:#"$1"\[*}" = 1 ]] &&
	! [[ "${(M)#paperflags:#"$1"}" = 1 ]]
}

_pagespec() {
	compset -P '*,'
	if compset -P 1 '*-'; then
		_numbers -l 1
		if ! compset -P '[0-9]##|last'; then
			_description -x last expl 'last page' && compadd -S, -r ' \t\n\-' "$expl[@]" last
		fi
		_description -x comma expl 'comma' && compadd -R _remove_comma -S '' "$expl[@]" ,
	else
		_numbers -l 1
		if compset -P '[0-9]##|last'; then
			_description -x range expl 'range' && compadd -S '' "$expl[@]" - -
			_description -x comma expl 'comma' && compadd -R _remove_comma "$expl[@]" ,
		else
			_description -x range expl 'range from 1' && compadd -S '' "$expl[@]" - -
			_description -x empty expl 'empty page' && compadd -Q -qS, "$expl[@]" {}
			_description -x last expl 'last page' && compadd -S '' "$expl[@]" last
			# _description -x none expl 'implicit empty page' && compadd -S '' "$expl[@]" , # valid but not recommended
		fi
	fi
}

_remove_comma() { # Remove comma which was likely added only accidentally. NB: Would add an empty page otherwise.
	case "$KEYS" in
		' '|$'\n'|$'\t'|$'\r') LBUFFER=${LBUFFER%,} ;;
	esac
}

_output() {
	_alternative 'file:pdf:_files -g \*.pdf' 'directory:path:_files -/'
}

_dimen() {
	local units=(
		':bp:point (1/72 in)'
		'pt:point (1/72.27 in)'
		mm:millimeter
		cm:centimeter
		'in:inch (2.54 cm)'
		'sp:scaled point (1/65536 pt)'
		'pc:pica (12 pt)'
		'dd:Didot point (1.07 pt)'
		'cc:Cicero (12 dd)'
		'ex:x-height (height of lowercase x)'
		'em:font size (height of capital M)'
	)
	_numbers -f -u bp "$@" $units
}

_dimens() {
	local sep="$argv[-2]"
	typeset -a names=("${(s:,:)argv[-1]}")
	typeset -i i=$#names
	shift -p 2
	if [[ "$QIPREFIX" = (\'|\") ]]; then
		close="$QIPREFIX"
	else
		close=
		[[ "$sep" = ' ' ]] && sep="\\$sep"
	fi
	while ((--i)); do compset -P $i "*$sep" && break; done
	((++i))
	[[ $i = $#names ]] && sep="$close "
	_dimen "$@" -S "$sep" "$names[$i]"
}

_nup() {
	setopt extendedglob
	case "$PREFIX" in
		[0-9]##x[0-9]#) compset -P '*x'; _numbers -l 1 "$@" vertical ;;
		[0-9]##) compset -P '*'; _numbers -l 1 "$@" horizontal; compadd "$@" -S '' x ;;
		[0-9]#) _numbers -l 1 "$@" horizontal ;;
		*) return 1 ;;
	esac
}

_pagecolor() {
	if compset -P 3 '*,'; then return 1
	elif compset -P 2 '*,'; then
		_numbers -l 0 -m 255 "$@" blue
	elif compset -P 1 '*,'; then
		_numbers -l 0 -m 255 "$@" green
	else
		_numbers -l 0 -m 255 "$@" red
	fi
}

_linkfit() {
	local expl tag
	if compset -P 1 '*\ '; then
		_numbers 'distance in points (1/72 in)'
	else
		compadd "$@" Fit FitB Region
		compadd -S '\ ' "$@" FotV FotBH FitBV
	fi
}

_addtotoc() { # {page number, section, level, heading, label}
	local close expl
	if compset -P '*\{'; then close='\}'
	elif compset -P '*{'; then close='}'
	fi
	if ! compset -P 1 '*,'; then
		compset -P '*'
		_description -x string expl 'page number' && compadd "$expl[@]"
		_description -x separator expl comma && compadd "$expl[@]" ,
	elif ! compset -P 2 '*,'; then
		_alternative 'level:level:(part,0, section,1, subsection,2, subsubsection,3,)'
	elif ! compset -P 1 '*,'; then
		compset -P '*'
		_description -x string expl heading && compadd "$expl[@]"
		_description -x separator expl comma && compadd "$expl[@]" ,
	elif ! compset -P 1 '*,' && ! compset -P "*$close"; then
		compset -P '*'
		_description -x string expl 'LaTeX label' && compadd "$expl[@]"
		[[ -n "$close" ]] && _description -x delimiter expl brace && compadd -Q "$expl[@]" - "$close"
	fi
}

_addtolist() { # {page number, type, heading, label}
	local close
	if compset -P '*\{'; then close='\}'
	elif compset -P '*{'; then close='}'
	fi
	if ! compset -P 1 '*,'; then
		compset -P '*'
		_description -x string expl 'page number' && compadd "$expl[@]"
		_description -x separator expl comma && compadd "$expl[@]" ,
	elif ! compset -P 1 '*,'; then
		_alternative 'type:type:(figure, table,)'
	elif ! compset -P 1 '*,'; then
		compset -P '*'
		_description -x string expl heading && compadd "$expl[@]"
		_description -x separator expl comma && compadd "$expl[@]" ,
	elif ! compset -P 1 '*,' && ! compset -P "*$close"; then
		compset -P '*'
		_description -x string expl 'LaTeX label' && compadd "$expl[@]"
		[[ -n "$close" ]] && _description -x delimiter expl brace && compadd -Q "$expl[@]" - "$close"
	fi
}

_enc() {
	local enc=$(iconv -l)
	enc=${(@q)${(ou)${${(f)enc}%//}}}
	_alternative "encoding:code set:($enc)"
}

if [[ $zsh_eval_context[-1] == loadautofunc ]]; then
	_pdfjam "$@"
else
	compdef _pdfjam pdfjam
fi
