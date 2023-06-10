TYPST ?= typst
SUBDIRS := $(wildcard test/[0-9][0-9]/)

test: $(SUBDIRS) $(patsubst %.tbl,%.png,$(wildcard *.tbl))

help:
	@printf 'Available targets:\n\
	\n\
	test    (default) Run only tests that are out-of-date.\n\
	        -B to run all tests unconditionally.\n\
	        -j to specify the number of tests to run in parallel.\n\
	        -k to keep going after a test fails.\n\
	        -s to silence MAKE messages.\n\
	DIR/    Run only tests in DIR/ (trailing slash required).\n\
	        The above options are also accepted.\n\
	\n\
	clean   Remove newly-generated PNG files.\n\
	reset   Remove *all* PNG files.\n\
	update  Accept newly-generated PNG files as correct.\n\
	'

clean:
	@rm -f test/*/*.png.new

reset:
	@rm -f test/*/*.png*

update:
	@for i in test/*/*.png.new; do \
		mv -f "$$i" "$${i%.new}"; \
	done

%.png: %.tbl options.typ ../driver.typ.in ../../tbl.typ
	@sed \
		-e 's#@PATH_TBL@#"$<"#g' \
		../driver.typ.in > '$*.typ'; \
	mv -f '$@' '$@.old' 2>/dev/null || :; \
	$(TYPST) compile '$*.typ' '$@'; \
	mv -f '$@' '$@.new'; \
	mv -f '$@.old' '$@' 2>/dev/null || :; \
	rm -f '$*.typ'; \
	if ! [ -e '$@' ]; then \
		echo 'MISS $(TEST_DIR)$* (run `make update`?)'; \
	elif diff -q '$@' '$@.new' >/dev/null; then \
		echo 'PASS $(TEST_DIR)$*'; \
		touch '$@'; \
	else \
		echo 'FAIL $(TEST_DIR)$*'; \
		exit 1; \
	fi;

$(SUBDIRS):
	@$(MAKE) -C '$@' -f ../../Makefile TEST_DIR='$@'

.PHONY: test help clean reset update $(SUBDIRS)
