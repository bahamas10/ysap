```
a=(foo bar baz)
echo "${a[*]}"

unset IFS
echo "${a[*]}"

IFS=''
echo "${a[*]}"

IFS=_abcde
echo "${a[*]}"
```
