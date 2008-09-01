#
# Makefile
# Adrián Pérez, 2008-08-14 20:29
#

module_readmes  := $(wildcard lib/*/README)
all_txt_docs    := $(wildcard doc/*.txt)
all_bsh_modules := $(shell find lib -name '*.bsh')
all_html_pages  := $(patsubst %.bsh,doc/%.html,$(all_bsh_modules)) \
                   $(patsubst %.txt,%.html,$(all_txt_docs)) \
                   doc/module-index.html


doc: $(all_html_pages)

doc/%.txt: %.bsh
	mkdir -p $(dir $@)
	awk -f scripts/docextract.awk $< > $@

.SECONDARY:

doc/module-index.html: $(all_bsh_modules) $(module_readmes)
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

.PHONY: deb

# vim:ft=make
#

