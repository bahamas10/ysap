SHELL := bash

.PHONY: build
build: favicon.ico
	mkdir -p _site
	# copy static files
	cat favicon.ico > _site/favicon.ico
	cat style.css > _site/style.css
	cat robots.txt > _site/robots.txt
	# create json
	./make-json episodes > _site/json
	# create help page
	cat <(./make-header) <(echo) <(./make-help) > _site/help
	# create index ascii page for curl users
	cat <(./make-header) <(echo) \
	    <(./make-ascii-table episodes) \
	    <(./make-footer) \
	    > _site/index.txt
	# create nocolor version of that page
	npx strip-ansi-cli < _site/index.txt > _site/nocolor
	# create all pages for each video
	./make-video-pages episodes _site/v
	# create the main HTML page
	cat <(./make-header) <(echo) \
	    <(./make-socials) <(echo) \
	    <(./make-ascii-table episodes) \
	    <(./make-footer) <(echo) \
	    <(./make-help) \
	    <(./make-donate) \
		| sed -e 's/ /\&nbsp;/g' \
		| npx ansi-to-html \
		| sed -e 's|http://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' \
		| sed -e 's|https://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' \
		| sed -e '/CONTENT/{r /dev/stdin' -e 'd;}' index.html.template > _site/index.html
	# create "general" stuff
	mkdir -p _site/general
	# create json
	./make-json general > _site/general/json
	# create index ascii page for curl users
	cat <(./make-header) <(echo) \
	    <(./make-ascii-table general) \
	    <(./make-footer) \
	    > _site/general/index.txt
	# create nocolor version of that page
	npx strip-ansi-cli < _site/general/index.txt > _site/general/nocolor
	# create all pages for each video
	./make-video-pages general _site/general/v
	# create the general HTML page
	cat <(./make-header) <(echo) \
	    <(./make-ascii-table general) \
	    <(./make-footer) <(echo) \
	    <(./make-donate) \
		| sed -e 's/ /\&nbsp;/g' \
		| npx ansi-to-html \
		| sed -e 's|http://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' \
		| sed -e 's|https://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' \
		| sed -e '/CONTENT/{r /dev/stdin' -e 'd;}' index.html.template > _site/general/index.html

favicon.ico:
	curl -o $@ https://secure.gravatar.com/avatar/d6e53a055695ad6488b32a6ac4f6ee5d?s=32

.PHONY: all
all: build deploy

.PHONY: serve
serve:
	python3 -mhttp.server -d _site

.PHONY: check-deps
check-deps:
	./check-deps

.PHONY: check
check:
	shellcheck -x make-* check-*

.PHONY: clean
clean:
	rm -rf _site
	rm -f favicon.ico

.PHONY: deploy
deploy:
	rsync -avh --delete ./_site/ web:/var/www/ysap.sh/
