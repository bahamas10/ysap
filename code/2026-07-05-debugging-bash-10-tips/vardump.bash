#!/usr/bin/env bash
#
# Bash library for pretty-printing a variable given by name.
#
# This was inspired by `util.inspect` in Node.js, `p` in or `pp` in ruby,
# `var_dump` in php, etc.  This is intended for developers to use for debugging
# - this should not be parsed by a machine nor should the output format be
# considered stable.
#
# Author: Dave Eddy <dave@daveeddy.com>
# Date: December 18, 2024
# License: MIT

# vardump
#
# Dump the given variable (by name) information and value to stdout.
#
# Usage: vardump [-v] <name>
#
# Example:
#
# ``` bash
# $ declare -A assoc=([foo]=1 [bar]=2)
# $ vardump assoc
# (
#	['foo']='1'
#	['bar']='2'
# )
# $ vardump -v assoc
# --------------------------
# vardump: assoc
# attributes: (A)associative array
# length: 2
# (
#	['foo']='1'
#	['bar']='2'
# )
# --------------------------
# ```
#
# Arguments:
#   -v                      verbose output
#   -C [always|auto|never]  when to colorize output, defaults to auto
#
vardump() {
	# read arguments
	local verbose=false
	local whencolor='auto'
	local OPTIND OPTARG opt
	while getopts 'C:v' opt; do
		case "$opt" in
			C) whencolor=$OPTARG;;
			v) verbose=true;;
			*) return 1;;
		esac
	done
	shift "$((OPTIND - 1))"

	# read variable name
	local name=$1

	if [[ -z $name ]]; then
		echo 'vardump: name required as first argument' >&2
		return 1
	fi

	# optionally load colors
	if [[ $whencolor == always ]] || [[ $whencolor == auto && -t 1 ]]; then
		local color_green=$'\e[32m'
		local color_magenta=$'\e[35m'
		local color_rst=$'\e[0m'
		local color_dim=$'\e[2m'
	else
		local color_green=''
		local color_magenta=''
		local color_rst=''
		local color_dim=''
	fi
	local color_value=$color_green
	local color_key=$color_magenta
	local color_length=$color_magenta

	# optionally print header
	if $verbose; then
		echo "${color_dim}--------------------------${color_rst}"
		echo "${color_dim}vardump: ${color_rst}$name"
	fi

	# ensure the variable is defined
	if ! declare -p "$name" &>/dev/null; then
		echo "variable ${name@Q} not defined" >&2
		return 1
	fi

	# get the variable attributes - this will tell us what kind of variable
	# it is.
	#
	# XXX dave says - is this ideal? when the variable is a nameref (using
	# `declare -n` or `local -n`) it seems like this method follows the
	# nameref, whereas parsing the output of `declare -p <name>` seems to
	# correctly give `-n` as the set of arguments used.  Perhaps just parse
	# the output of `declare -p` from above here instead?
	#
	# also, the atter is a string like "ri" (where r is read only, i is
	# integer) so we have to convert it into an array
	local -a attrs=()
	local attr_string=${!name@a}
	local i
	for ((i = 0; i < ${#attr_string}; i++)); do
		local attr=${attr_string:i:1}
		attrs+=("$attr")
	done

	# parse the variable attributes and construct a human-readable string
	local attributes=()
	local typ=''
	for attr in "${attrs[@]}"; do
		local s=''
		case "$attr" in
			a) s='indexed array'; typ='a';;
			A) s='associative array'; typ='A';;
			r) s='read-only';;
			i) s='integer';;
			g) s='global';;
			x) s='exported';;
			*) s="unknown";;
		esac
		attributes+=("($attr)$s")
	done

	# optionally print the attributes to the user
	if $verbose; then
		echo -n "${color_dim}attributes: ${color_rst}"
		if [[ -n ${attributes[0]} ]]; then
			# separate the list of attributes by a `/` character
			(
			IFS=/
			echo -n "${attributes[*]}"
			)
		else
			echo -n '(none)'
		fi
		echo
	fi

	# print the variable itself! we use $typ defined above to format it
	# appropriately.
	#
	# we *pray* the user doesn't use this variable name in their own code or
	# we'll hit a circular reference error (THAT WE CAN'T CATCH OURSELVES IN
	# CODE - lame)
	local -n __vardump_name="$name"

	if [[ $typ == 'a' || $typ == 'A' ]]; then
		# print this as an array - indexed, sparse, associative,
		# whatever
		local key value

		# optionally print length
		if $verbose; then
			local length=${#__vardump_name[@]}
			printf '%s %s\n' \
			    "${color_dim}length:${color_rst}" \
			    "${color_length}$length${color_rst}"
		fi

		# loop keys and print the data itself
		echo '('
		for key in "${!__vardump_name[@]}"; do
			value=${__vardump_name[$key]}

			# safely quote the key name if it's an associative array
			# (the user controls the key names in this case so we
			# can't trust them to be safe)
			if [[ $typ == 'A' ]]; then
				key=${key@Q}
			fi

			# always safely quote the value
			value=${value@Q}

			printf '\t[%s]=%s\n' \
			    "${color_key}$key${color_rst}" \
			    "${color_value}$value${color_rst}"
		done
		echo ')'
	else
		# we are just a simple scalar value - print this as a regular,
		# safely-quoted,  value.
		echo "${color_value}${__vardump_name@Q}${color_rst}"
	fi

	# optionally print the trailer
	if $verbose; then
		echo "${color_dim}--------------------------${color_rst}"
	fi

	return 0

}

# if we are run directly (not-sourced) then run through some examples
if ! (return &>/dev/null); then
	declare s='some string'
	declare -r read_only='this cant be changed'
	declare -i int_value=5
	declare -ri read_only_int=8

	declare -a simple_array=(foo bar baz "$(tput setaf 1)red$(tput sgr0)")
	declare -a sparse_array=([0]=hi [5]=bye [7]=ok)
	declare -A assoc_array=([foo]=1 [bar]=2)

	vars=(
		s read_only int_value read_only_int
		simple_array sparse_array assoc_array
	)

	echo 'simple vardump'
	for var in "${vars[@]}"; do
		vardump "$var"
	done

	echo 'verbose vardump'
	for var in "${vars[@]}"; do
		vardump -v "$var"
		echo
	done
fi
