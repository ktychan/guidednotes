# vim:number
LATEXMK = latexmk -halt-on-error -interaction=nonstopmode -silent
COURSE  = "Subj_1000A_$(shell git rev-parse --abbrev-ref HEAD)"

GREEN  = \033[32m
RED    = \033[31m
YELLOW = \033[33m
ORANGE = \033[38;5;208m
RESET  = \033[0m

# Timestamp is fixed at parse time so all rules in one invocation share the
# same log file.
TS  := $(shell date +%Y%m%d-%H%M%S)
LOG  = .aux/build-$(TS).log

# RUN_ONE: shell function body.
# Runs latexmk synchronously, then prints okay/fail with the elapsed time
# in orange brackets on the right edge of the terminal.
# Called as: run_one() { $(RUN_ONE); }; run_one 'file.tex'
RUN_ONE = \
	_cols=$$(tput cols 2>/dev/null || echo $${COLUMNS:-80}); \
	printf '[latexmk, $(YELLOW)....$(RESET)] %s' "$$1"; \
	_start=$$(date +%s); \
	( set -x; $(LATEXMK) "$$1" ) >> $(LOG) 2>&1; \
	_rc=$$?; _el=$$(( $$(date +%s) - $$_start )); \
	_timer=$$(printf '[%d:%02d]' "$$(( $$_el / 60 ))" "$$(( $$_el % 60 ))"); \
	_tlen=$$(printf '%s' "$$_timer" | wc -c); \
	_col=$$(( $$_cols - $$_tlen + 1 )); \
	if [ $$_rc -eq 0 ]; then \
	    printf '\r[latexmk, $(GREEN)okay$(RESET)] %s\033[%dG$(ORANGE)%s$(RESET)\n' \
	        "$$1" "$$_col" "$$_timer"; \
	else \
	    printf '\r[latexmk, $(RED)FAIL$(RESET)] %s  (see $(LOG))\033[%dG$(ORANGE)%s$(RESET)\n' \
	        "$$1" "$$_col" "$$_timer"; \
	    exit 1; \
	fi

# run_latex <file>: make-level wrapper for a single file.
define run_latex
	@mkdir -p .aux
	@ln -sf build-$(TS).log .aux/build.log
	@run_one() { $(RUN_ONE); }; run_one '$(1)'
endef

%.pdf: %.tex
	$(call run_latex,$^)

# Standalone figures to build before the notes. A course Makefile can list
# fragments here -- files under standalones/ that are \input by another
# figure rather than compiled on their own -- by setting STANDALONE_EXCLUDE
# *before* including this file.
STANDALONE_EXCLUDE ?=
STANDALONES = $(filter-out $(STANDALONE_EXCLUDE),$(wildcard standalones/*.tex))

main.pdf: $(STANDALONES) main.tex
	@mkdir -p .aux
	@ln -sf build-$(TS).log .aux/build.log
	@run_one() { $(RUN_ONE); }; for dep in $^; do run_one "$$dep"; done

# main.tex writes weeks.csv into the aux directory latexmk hands to lualatex,
# so it lands in .aux/ when .latexmkrc sets $$aux_dir and in the project root
# when it does not. Look in both rather than assuming one.
WEEKS_CSV = .aux/weeks.csv weeks.csv

build.pdf: build.tex main.pdf
	@mkdir -p build/
	$(call run_latex,$<)
	@csv=$$(ls -1 $(WEEKS_CSV) 2>/dev/null | head -1); \
	if [ -z "$$csv" ]; then \
	    printf '[weeks,  $(RED)FAIL$(RESET)] no weeks.csv in $(WEEKS_CSV)\n'; \
	    exit 1; \
	fi; \
	tail -n +2 "$$csv" | while IFS=, read i a b; do \
		( set -x; \
		  gs -sDEVICE=pdfwrite -dQUIET -dNOPAUSE -dBATCH -dSAFER \
		     -dFirstPage=$$a -dLastPage=$$b \
		     -sOutputFile=build/$(COURSE)_week$$i.pdf \
		     build.pdf ) >> $(LOG) 2>&1; \
	done
