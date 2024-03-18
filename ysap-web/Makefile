.PHONY: build
build:
	mkdir -p _site
	cat episodes.txt > _site/list.txt
	./make-ascii-table < episodes.txt > _site/index.html
	./make-redirections < episodes.txt

