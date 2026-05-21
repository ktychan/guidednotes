LATEXMK=latexmk -halt-on-error -interaction=nonstopmode -silent
COURSE=Subj_1000B_W24
AUXDIR=.aux

.PHONY: all clean standalones main publish

all: main

clean: 
	rm -rf **/*.pdf
	rm -rf **/*.synctex.gz

main: main.tex
	$(if $(wildcard standalones/*.tex), $(LATEXMK) standalones/*.tex)
	${LATEXMK} main.tex
	cp main.pdf ${COURSE}.pdf
	@tail -n +2 ${AUXDIR}/weeks.csv | while IFS=, read i a b; do \
		gs -sDEVICE=pdfwrite -dQUIET -dNOPAUSE -dBATCH -dSAFER \
		   -dFirstPage=$$a -dLastPage=$$b \
		   -sOutputFile=$(COURSE)_week$$i.pdf \
		   main.pdf; \
	done
