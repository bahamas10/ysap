# Create, manage, and deploy the YSAP website
#
# Author: Dave Eddy <dave@daveeddy.com>
# Date: April 05, 2025
# License: MIT

# duh
SHELL := bash

.PHONY: help
help:
	@echo 'make build         default target, builds the site into ./_site'
	@echo 'make check-deps    check to ensure needed dependencies are installed'
	@echo 'make check         check tools syntax using shellcheck'
	@echo 'make serve         serve site locally out of ./_site'
	@echo 'make deploy        deploy the site (using rsync)'
	@echo 'make all           build and deploy the site'
	@echo 'make clean         remove any generated files'

.PHONY: build
build: static/favicon.ico static/ysap.png static/favicon.jpg
	mkdir -p _site _site/contact _site/static _site/episodes _site/resources
	# disable indexing for certain dirs
	echo -n > _site/static/index.html
	# copy static files
	cat static/favicon.ico > _site/favicon.ico
	cat static/favicon.jpg > _site/static/favicon.jpg
	cat static/robots.txt > _site/robots.txt
	cat static/ysap.png > _site/static/ysap.png
	cat static/style.css > _site/static/style.css
	cat static/ansi.css > _site/static/ansi.css
	cat static/terminal.js > _site/static/terminal.js
	cat static/index.html > _site/index.html
	cat static/contact.html > _site/contact/index.html
	cat static/episodes.html > _site/episodes/index.html
	cat static/resources.html > _site/resources/index.html
	# make /ping endpoint (nginx handles this for me, but just in case)
	echo 'pong' > _site/ping
	# create ASCII index page for curl users
	./make-index > _site/index.txt
	# create ASCII help page
	./make-help > _site/help
	# create episodes ASCII table
	./make-episodes > _site/episodes/index.txt
	# make episodes JSON file for curl
	./make-episodes-json > _site/json
	# make jsonp for our HTML files
	./make-commands-jsonp > _site/static/commands.js
	./make-episodes-json EPISODES > _site/static/episodes.js
	cat _site/json > _site/episodes.json
	# create all pages for each video
	./make-video-pages

static/favicon.ico:
	curl -o $@ https://files.daveeddy.com/ysap/favicon.ico

static/favicon.jpg:
	curl -o $@ https://files.daveeddy.com/ysap/favicon.jpg

static/ysap.png:
	curl -o $@ https://files.daveeddy.com/ysap/ysap.png

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
	shellcheck -x check-* make-* tools/*

.PHONY: clean
clean:
	rm -rf _site
	rm -f static/favicon.{ico,jpg}
	rm -f static/ysap.png

.PHONY: deploy
deploy:
	rsync -avh --delete ./_site/ web:/var/www/ysap.sh/
