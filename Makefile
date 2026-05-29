LATEXMK = latexmk -halt-on-error -interaction=nonstopmode
COURSE  = "Subj_1000A_$(shell git rev-parse --abbrev-ref HEAD)"

GREEN  = \033[32m
RED    = \033[31m
YELLOW = \033[33m
RESET  = \033[0m

# Timestamp is fixed at parse time so all rules in one invocation share the
# same log file.
TS  := $(shell date +%Y%m%d-%H%M%S)
LOG  = .aux/build-$(TS).log

# run_latex <file>
#   - Appends all latexmk output and executed commands to $(LOG).
#   - set -x is scoped to a subshell ( ) so it cannot leak to the terminal.
#   - Prints [latexmk, ....] <file> while compiling, then overwrites with
#     [latexmk, okay] or [latexmk, fail] when done.
define run_latex
	@mkdir -p .aux
	@ln -sf build-$(TS).log .aux/build.log
	@file='$(1)'; \
	printf '[latexmk, $(YELLOW)....$(RESET)] %s' "$$file"; \
	( set -x; $(LATEXMK) $(1) ) >> $(LOG) 2>&1; \
	if [ $$? -eq 0 ]; then \
	    printf '\r[latexmk, $(GREEN)okay$(RESET)] %s\n' "$$file"; \
	else \
	    printf '\r[latexmk, $(RED)FAIL$(RESET)] %s  (see $(LOG))\n' "$$file"; \
	    exit 1; \
	fi
endef

.PHONY: all clean slides

all: build.pdf
	$(foreach dep,$^,cp $(dep) build/$(COURSE)_$(dep);)

clean:
	rm -f {*,**/*}.pdf
	rm -f {*,**/*}.synctex.gz
	rm -rf **/.aux build

%.pdf: %.tex
	$(call run_latex,$^)

main.pdf: $(wildcard standalones/*.tex) main.tex
	$(call run_latex,$^)

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
