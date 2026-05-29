LATEXMK=latexmk -halt-on-error -interaction=nonstopmode -silent
COURSE="Subj_1000A_$(shell git rev-parse --abbrev-ref HEAD)"

.PHONY: all clean slides 

all: build.pdf slides.pdf polls.pdf
	$(foreach dep,$^,cp $(dep) build/$(COURSE)_$(dep);)

clean: 
	rm -f {*,**/*}.pdf
	rm -f {*,**/*}.synctex.gz
	rm -rf **/.aux build

%.pdf: %.tex
	${LATEXMK} $^

main.pdf: $(wildcard standalones/*.tex) main.tex
	${LATEXMK} $^

build.pdf: build.tex main.pdf
	@mkdir -p build/
	${LATEXMK} $<
	@tail -n +2 .aux/weeks.csv | while IFS=, read i a b; do \
		gs -sDEVICE=pdfwrite -dQUIET -dNOPAUSE -dBATCH -dSAFER \
		   -dFirstPage=$$a -dLastPage=$$b \
		   -sOutputFile=build/${COURSE}_week$$i.pdf \
		   build.pdf; \
	done
