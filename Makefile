# vim:number
LATEXMK = latexmk -halt-on-error -interaction=nonstopmode -silent
COURSE  = "Subj_1000A_$(shell git rev-parse --abbrev-ref HEAD)"

GREEN  = \033[32m
RED    = \033[31m
YELLOW = \033[33m
RESET  = \033[0m

# Timestamp is fixed at parse time so all rules in one invocation share the
# same log file.
TS  := $(shell date +%Y%m%d-%H%M%S)
LOG  = .aux/build-$(TS).log

# RUN_ONE: single-line shell function body called with one argument (the file).
# Single-line avoids all tab/newline ambiguity when embedded in recipes or
# inside other shell constructs.  Wrap as: run_one() { $(RUN_ONE); }
RUN_ONE = \
	printf '[latexmk, $(YELLOW)....$(RESET)] %s' "$$1"; \
	( set -x; $(LATEXMK) "$$1" ) >> $(LOG) 2>&1; \
	if [ $$? -eq 0 ]; then \
	    printf '\r[latexmk, $(GREEN)okay$(RESET)] %s\n' "$$1"; \
	else \
	    printf '\r[latexmk, $(RED)fail$(RESET)] %s  (see $(LOG))\n' "$$1"; \
	    exit 1; \
	fi

# run_latex <file>: make-level wrapper for a single file.
define run_latex
	@mkdir -p .aux
	@ln -sf build-$(TS).log .aux/build.log
	@run_one() { $(RUN_ONE); }; run_one '$(1)'
endef

clean:
	rm -f {*,**/*}.pdf
	rm -f {*,**/*}.synctex.gz
	rm -rf **/.aux build

%.pdf: %.tex
	$(call run_latex,$^)

main.pdf: $(wildcard standalones/*.tex) main.tex
	@mkdir -p .aux
	@ln -sf build-$(TS).log .aux/build.log
	@run_one() { $(RUN_ONE); }; for dep in $^; do run_one "$$dep"; done

build.pdf: build.tex main.pdf
	@mkdir -p build/
	$(call run_latex,$<)
	@tail -n +2 .aux/weeks.csv | while IFS=, read i a b; do \
		( set -x; \
		  gs -sDEVICE=pdfwrite -dQUIET -dNOPAUSE -dBATCH -dSAFER \
		     -dFirstPage=$$a -dLastPage=$$b \
		     -sOutputFile=build/$(COURSE)_week$$i.pdf \
		     build.pdf ) >> $(LOG) 2>&1; \
	done
