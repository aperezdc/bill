#
# Makefile
# Adrián Pérez, 2008-08-14 20:29
#

module_readmes   := $(wildcard lib/*/README)
all_text_docs    := $(wildcard doc/*.txt)
all_bash_modules := $(shell find lib -name '*.bash')
all_html_pages   := $(patsubst %.bash,doc/%.html,$(all_bash_modules)) \
                    $(patsubst %.txt,%.html,$(all_txt_docs)) \
                    doc/module-index.html


doc: $(all_html_pages)

doc/%.txt: %.bash
	mkdir -p $(dir $@)
	awk -f scripts/docextract.awk $< > $@

.SECONDARY:

doc/module-index.html: $(all_bash_modules) $(module_readmes)
	./scripts/bill scripts/gen-module-index lib | $(rst2html) - $@

%.html: %.txt
	$(rst2html) $< $@

.PHONY: doc

rst2html := ./scripts/pygmentrst2html.py \
            --link-stylesheet --stylesheet-path=doc/style.css


clean:
	$(RM) $(all_html_pages)
	$(RM) -r doc/lib
	$(RM) .bill.deb.count
	$(RM) bill*.deb

deb: doc
	./scripts/bill scripts/gen-debian-package

tarball:
	git archive --prefix=bill-$$(./scripts/bill --version)/ HEAD \
		| bzip2 -c > bill-$$(./scripts/bill --version).tar.bz2

.PHONY: deb tarball


ifeq ($(strip $T),)
test:
	@./scripts/bill scripts/butt test/*
else
test:
	@./scripts/bill scripts/butt test/$T
endif

.PHONY: test

# vim:ft=make
#

