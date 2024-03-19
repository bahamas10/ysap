```
type -a echo
alias echo='echo foo'
function echo() { command echo bar "$@"; }

echo -e hello world
```
