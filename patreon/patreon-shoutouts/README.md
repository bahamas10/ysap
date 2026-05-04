do everything

```
# compile "writer"
make

# run the program with the default "sleep" argument
./patreon-shoutouts example.csv

# run the program with a custom "sleep" arg (time in usecs)
./patreon-shoutouts example.csv 16000
```

just print the output

```
cd member-shoutouts
cargo run -q -- < ../example.csv
```

