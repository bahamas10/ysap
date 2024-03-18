SHELL := bash

.PHONY: build
build:
	mkdir -p _site
	cat episodes.txt > _site/text
	./make-help > _site/help
	./make-json < episodes.txt > _site/json
	./make-ascii-table < episodes.txt > _site/index.txt
	npx strip-ansi-cli < _site/index.txt > _site/nocolor
	./make-redirects < episodes.txt
	cat _site/index.txt <(./make-help -H) \
		| npx ansi-to-html \
		| sed -e '/CONTENT/{r /dev/stdin' -e 'd;}' index.html.template \
		| sed -e 's|http://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' \
		| sed -e 's|https://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' > _site/index.html

.PHONY: clean
clean:
	rm -rf _site

.PHONY: deploy
deploy:
	rsync -avh --delete ./_site/ ysap.daveeddy.com:/var/www/ysap.daveeddy.com/
