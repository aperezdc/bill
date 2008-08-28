#
# Makefile
# Adrián Pérez, 2008-08-14 20:29
#

all_txt_docs    := $(wildcard doc/*.txt)
all_bsh_modules := $(shell find lib -name '*.bsh')
all_html_pages  := $(patsubst %.bsh,doc/%.html,$(all_bsh_modules)) \
                   $(patsubst %.txt,%.html,$(all_txt_docs)) \
                   doc/module-index.html

doc: $(all_html_pages)

doc/%.html: %.bsh
	mkdir -p $(dir $@)
	awk -f scripts/docextract.awk $< | $(rst2html) - $@

doc/module-index.html: $(all_bsh_modules)
	./scripts/bill scripts/gen-module-index lib | $(rst2html) - $@

%.html: %.txt
	$(rst2html) $< $@

.PHONY: doc

SHELL = bash
rst2html := $(shell type -P \
	docutils-rst2html.py \
	docutils-rst2html \
	rst2html.py \
	rst2html \
| head -1) --stylesheet-path=doc/docutils.css


clean:
	$(RM) $(all_html_pages)

# vim:ft=make
#

