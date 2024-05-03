SHELL := bash

.PHONY: build
build:
	mkdir -p _site
	# copy static files
	cat episodes.txt > _site/text
	cat style.css > _site/style.css
	# create json
	./make-json < episodes.txt > _site/json
	# create help page
	cat <(./make-header) <(echo) <(./make-help) > _site/help
	# create index ascii page for curl users
	cat <(./make-header) <(echo) \
	    <(./make-ascii-table < episodes.txt) \
	    <(./make-footer) \
	    > _site/index.txt
	# create nocolor version of that page
	npx strip-ansi-cli < _site/index.txt > _site/nocolor
	# create all pagse for each video
	./make-video-pages _site < episodes.txt
	# create the main HTML page
	cat <(./make-header) <(echo) \
	    <(./make-socials) <(echo) \
	    <(./make-ascii-table < episodes.txt) \
	    <(./make-footer) <(echo) \
	    <(./make-help) \
		| sed -e 's/ /\&nbsp;/g' \
		| npx ansi-to-html \
		| sed -e '/CONTENT/{r /dev/stdin' -e 'd;}' index.html.template \
		| sed -e 's|http://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' \
		| sed -e 's|https://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' > _site/index.html

.PHONY: serve
serve:
	python3 -mhttp.server -d _site

.PHONY: check
check:
	./check-deps

.PHONY: clean
clean:
	rm -rf _site

.PHONY: deploy
deploy:
	rsync -avh --delete ./_site/ ysap.daveeddy.com:/var/www/ysap.daveeddy.com/
