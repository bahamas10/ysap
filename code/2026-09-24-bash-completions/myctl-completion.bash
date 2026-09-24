_myctl() {
	# $ myctl   sta
	#
	# COMP_WORDS=(myctl sta)
	# COMP_CWORD=1
	# COMP_LINE='myctl   sta'
	# COMP_POINT=11
	# COMPREPLY=(response array)
	# COMP_WORDBREAKS=...advanced...

	# get input from the user
	local input=${COMP_WORDS[COMP_CWORD]}

	# get current command
	local cmd=${COMP_WORDS[1]}

	if ((COMP_CWORD == 1)); then
		# get the list of all commands possible
		local commands=$(./myctl list-commands) || return 1

		# filter this list based on user input
		COMPREPLY=(
			$(compgen -W "$commands" -- "$input")
		)
	elif ((COMP_CWORD == 2)); then
		case "$cmd" in
			user)
				COMPREPLY=(
					$(compgen -W 'badcop' -- "$input")
					$(compgen -u -- "$input")
				)
				;;
			*)
				;;
		esac
	fi
}

complete -F _myctl myctl
