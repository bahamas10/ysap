#!/bin/sh -
printf "%d args:" "$#"
[ "$#" -eq 0 ] || printf " <%s>" "$@"
echo
