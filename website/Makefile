SHELL := bash

.PHONY: build
build:
	mkdir -p _site
	cat episodes.txt > _site/text
	cat style.css > _site/style.css
	./make-help > _site/help
	./make-json < episodes.txt > _site/json
	./make-ascii-table < episodes.txt > _site/index.txt
	npx strip-ansi-cli < _site/index.txt > _site/nocolor
	./make-video-pages _site < episodes.txt
	cat _site/index.txt <(./make-help -H) \
		| sed -e 's/ /\&nbsp;/g' \
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
