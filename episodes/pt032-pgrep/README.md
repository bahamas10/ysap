```
make
./my-program &

ps -ef | grep my-program | grep -v grep | awk '{ print $2 }'

pgrep my-program
pgrep -l my-program
pkill my-program
```
