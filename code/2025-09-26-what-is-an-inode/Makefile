stat-deleted-file: stat-deleted-file.c
	cc -o $@ $<

.PHONY: dirs
dirs:
	# dir0 (empty)
	mkdir -p dirs/dir0
	# dir1 (1 file)
	mkdir -p dirs/dir1
	echo hi > dirs/dir1/foo.txt
	# dir2 (2 separate files)
	mkdir -p dirs/dir2
	echo hi > dirs/dir2/foo.txt
	echo bye > dirs/dir2/bar.txt
	# dir3 (2 files, 1 hardlinked)
	mkdir -p dirs/dir3
	echo hi > dirs/dir3/foo.txt
	cd dirs/dir3 && ln foo.txt bar.txt
	# dir4 (2 files, 1 symlinked)
	mkdir -p dirs/dir4
	echo hi > dirs/dir4/foo.txt
	cd dirs/dir4 && ln -s foo.txt bar.txt
	# dir5 (3 files, 2 symlinked)
	mkdir -p dirs/dir5
	echo hi > dirs/dir5/foo.txt
	cd dirs/dir5 && ln -s foo.txt bar.txt
	cd dirs/dir5 && ln -s bar.txt baz.txt
	# dir6 (circular symlinks)
	mkdir -p dirs/dir6
	cd dirs/dir6 && ln -s foo bar
	cd dirs/dir6 && ln -s bar foo
	# dir7 (subdir)
	mkdir -p dirs/dir7
	mkdir -p dirs/dir7/subdir
	# dir8 (subdir with files)
	mkdir -p dirs/dir8
	touch dirs/dir8/foo.txt
	mkdir -p dirs/dir8/subdir
	touch dirs/dir8/subdir/foo.txt

.PHONY: clean
clean:
	rm -rf dirs
	rm -f stat-deleted-file
