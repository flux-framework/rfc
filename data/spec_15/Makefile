imp.png: impish.pdf
	convert -density 300 $< -quality 90 $@
impish.pdf: impish.tex
	pdflatex impish.tex
clean:
	rm -f *.pdf
