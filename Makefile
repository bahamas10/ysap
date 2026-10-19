.PHONY: all
all:
	@echo 'make check    run style checks'

.PHONY: check
check:
	cd website && make check
