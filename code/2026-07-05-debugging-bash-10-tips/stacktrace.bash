#!/usr/bin/env bash
#
# Construct and print a stack trace in bash
#
# Author: Dave Eddy <dave@daveeddy.com>
# Date: December 18, 2024
# License: MIT

# stacktrace
#
# Construct and print a stack trace to stdout
#
# Usage: stacktrace [-C <always|never|auto>]
#
# Example:
#
# ``` bash
# #!/usr/bin/env bash
#
# . ./stacktrace.bash
#
# foo() { bar; }
# bar() { baz; }
# baz() { stacktrace; }
#
# stacktrace
# ```
#
# Arguments:
#   -C [always|auto|never]  when to colorize output, defaults to auto
#
stacktrace() {
	# read arguments
	local whencolor='auto'
	local OPTIND OPTARG opt
	while getopts 'C:v' opt; do
		case "$opt" in
			C) whencolor=$OPTARG;;
			*) return 1;;
		esac
	done
	shift "$((OPTIND - 1))"

	# optionally load colors
	if [[ $whencolor == always ]] || [[ $whencolor == auto && -t 1 ]]; then
		local color_cyan=$'\e[36m'
		local color_rst=$'\e[0m'
	else
		local color_cyan=''
		local color_rst=''
	fi

	local i=0
	local file func line

	echo
	echo 'Stack trace'
	while true; do
		file=${BASH_SOURCE[i+1]}
		func=${FUNCNAME[i]}
		line=${BASH_LINENO[i]}
		[[ -n $file ]] || break

		printf '    at `%s` %s(%s:%s)%s\n' \
		    "$func" \
		    "$color_cyan" \
		    "$file" \
		    "$line" \
		    "$color_rst"

		((i++))
	done
	echo
}

# if we are invoked directly then run a simple example
if ! (return &>/dev/null); then
	foo() {
		bar
	}
	bar() {
		baz
	}
	baz() {
		stacktrace
	}
	foo
fi
