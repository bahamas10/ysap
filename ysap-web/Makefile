.PHONY: build
build:
	mkdir -p _site
	cat episodes.txt > _site/list.txt
	cat index.html > _site/index.html
	./make-ascii-table < episodes.txt > _site/index.txt
	./make-redirects < episodes.txt

.PHONY: deploy
deploy:
	rsync -avh ./_site/ ysap.daveeddy.com:/var/www/ysap.daveeddy.com/
