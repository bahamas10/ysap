.PHONY: build
build:
	mkdir -p _site
	cat episodes.txt > _site/list.txt
	./make-ascii-table < episodes.txt > _site/index.txt
	./make-redirects < episodes.txt
	npx ansi-to-html _site/index.txt \
		| sed -e '/CONTENT/{r /dev/stdin' -e 'd;}' index.html.template \
		| sed -e 's|http://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' \
		| sed -e 's|https://[a-zA-Z0-9./-]*|<a href="&">&</a>|g' > _site/index.html

.PHONY: deploy
deploy:
	rsync -avh ./_site/ ysap.daveeddy.com:/var/www/ysap.daveeddy.com/
