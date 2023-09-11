.PHONY: all
all: c-env rust-env

c-env: c-env.c
	cc -o $@ $^

rust-env: rust-env.rs
	rustc -o $@ $^
