#!/usr/bin/env bash
#
# Create a box around incoming text.
#
# $ cat message.txt | box -t About
# ┌About────────────────────────────────┐
# │                                     │
# │ Yo what's up everyone my name's     │
# │ Dave and you suck at programming.   │
# │ Connect with my socials or use this │
# │ site to easily find my content!     │
# │                                     │
# └─────────────────────────────────────┘
#
# Author: Dave Eddy <dave@daveeddy.com>
# Date: March 28, 2025
# License: MIT

# ansi reset
RST=$'\x1b[0m'

# example: repeat-char '=' 50
repeat-char() {
	local char=$1
	local n=$2
	local s
	printf -v s "%${n}s"
	echo -n "${s// /$char}"
}

# example: cat thing.txt | strip-ansi
strip-ansi() (
	shopt -s extglob
	local IFS=
	local line
	while read -r line || [[ -n $line ]]; do
		printf '%s\n' "${line//$'\e'[\[(]*([0-9;])[@-n]/}"
	done
)

usage() {
	local prog=${0##*/}
	cat <<-EOF
	Usage: $prog [-t title] [...] < input

	Create a unicode or ASCII box around input text (from stdin)

	Options
	  -h, --help     Print this message and exit
	  -bc <color>    Color to use for the box (as ANSI escape sequence)
	  -tc <color>    Color to use for the title (as ANSI escape sequence)
	  -vp <padding>  Number of spaces to pad the box vertically, defaults to 0
	  -hp <padding>  Number of spaces to pad the box horizontally, defaults to 0
	  -s <sep>       Specify the separator character, defaults to none
	  -t <title>     Title for the box, defaults to nothing
	  -T <theme>     Theme to use (possible: unicode, ascii, plain)
	EOF
}

fatal() {
	echo '[FATAL]' "$@" >&2
	exit 1
}

title=
sep=
vpadding=0
hpadding=0
color=''
tcolor=
theme='unicode'
while [[ -n $1 ]]; do
	case "$1" in
		-h|--help) usage; exit 0;;
		-bc) color=$2; shift 2;;
		-tc) tcolor=$2; shift 2;;
		-vp) vpadding=$2; shift 2;;
		-hp) hpadding=$2; shift 2;;
		-s) sep=$2; shift 2;;
		-t) title=$2; shift 2;;
		-T) theme=$2; shift 2;;
		*) fatal "invalid argument: $1";;
	esac
done

# horizontal padding
hpadding=$(repeat-char ' ' "$hpadding")

# these variables are named for the junctions they connect
case "$theme" in
	unicode)
		WE='─'
		NS='│'
		SE='┌'
		NE='└'
		SW='┐'
		NW='┘'
		SWE='┬'
		NWE='┴'
		;;
	ascii)
		WE='-'
		NS='|'
		SE='+'
		NE='+'
		SW='+'
		NW='+'
		SWE='+'
		NWE='+'
		;;
	plain)
		WE=' '
		NS=' '
		SE=' '
		NE=' '
		SW=' '
		NW=' '
		SWE=' '
		NWE=' '
		;;
	*) fatal "invalid theme name: $theme";;
esac

# read the entire input first
mapfile -t input

# process input
max_width=0
max_cols=()
num_cols=1
for line in "${input[@]}"; do
	s=${line//$sep}
	len=${#s}

	if ((len > max_width)); then
		max_width=$len
	fi

	# count how many cells there are
	if [[ -n $sep ]]; then
		seps=${line//[^$sep]}
		num_cols=$((${#seps} + 1))
	else
		num_cols=1
	fi

	IFS=$sep read -ra cells <<< "$line"
	for ((i = 0; i < num_cols; i++)); do
		cell=$hpadding${cells[i]}$hpadding
		cell_stripped=$(strip-ansi <<< "$cell")

		cell_len=${#cell_stripped}
		if ((cell_len > max_cols[i])); then
			max_cols[i]=$cell_len
		fi
	done
done
((max_width += num_cols - 1))

# print title
#line=$color
line=$color$SE$WE$RST
line+=$tcolor$title$RST$color
offset=$((${#title} + 1))
for ((i = 0; i < num_cols; i++)); do
	max_len=${max_cols[i]}
	copy=$max_len
	((i < num_cols - 1)) && ((copy++))

	if ((offset > 0)); then
		((max_len -= offset))
	fi

	if ((max_len < 0)); then
		((offset -= copy))
		continue
	fi
	offset=0

	line+=$(repeat-char "$WE" "$max_len")
	((i < num_cols - 1)) && line+=$SWE
done
line+=$SW$RST
echo "$line"

# add vertical padding (top)
for ((i = 0; i < vpadding; i++)); do
	s=$(repeat-char "$sep" "$num_cols")
	input=("$s" "${input[@]}" "$s")
done

# process each row
for line in "${input[@]}"; do
	IFS=$sep read -ra cells <<< "$line"

	# process each cell
	line=$color$NS$RST
	for ((i = 0; i < num_cols; i++)); do
		cell=$hpadding${cells[i]}$hpadding
		cell_stripped=$(strip-ansi <<< "$cell")
		max_len=${max_cols[i]}
		len=${#cell_stripped}

		# write the cell data
		line+=$cell

		# pad it with spaces (left-align)
		line+=$(repeat-char ' ' "$((max_len - len))")

		# add the terminator char
		line+=$color$NS$RST
	done

	# print the final line
	echo "$line"
done

# print footer
line=$color
line+=$NE
for ((i = 0; i < num_cols; i++)); do
	max_len=${max_cols[i]}
	line+=$(repeat-char "$WE" "$max_len")
	((i < num_cols - 1)) && line+=$NWE
done
line+=$NW
line+=$RST
echo "$line"
