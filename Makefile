LATEXMK=latexmk -lualatex -halt-on-error -interaction=nonstopmode
COURSE=Subj_1000B_W24

.PHONY: all clean standalones main publish 

all: publish

clean: 
	rm -rf build
	rm -rf standalones/build
	rm -rf publish/*.tex publish/build

standalones:
	${LATEXMK} standalones/*.tex

main: standalones
	rm -f publish/*.tex
	${LATEXMK} main.tex

publish: main
	${LATEXMK} -jobname="${COURSE}_%A" publish/*.tex
