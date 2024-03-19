```
date +'the time is %H:%M:%S'

printf 'hello %s\n' "$USER"

printf '%T\n'
printf '%()T\n'
printf '%(%H:%M:%S)T\n' -1

date +%s
printf '%(%s)T\n' -1
echo $EPOCHSECONDS
echo $EPOCHREALTIME
```
