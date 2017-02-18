SOURCES = \
	README.adoc \
	spec_1.adoc \
	spec_2.adoc \
	spec_3.adoc \
	spec_4.adoc \
	spec_5.adoc \
	spec_6.adoc \
	spec_7.adoc \
	spec_8.adoc \
	spec_9.adoc \
	spec_10.adoc \
	spec_11.adoc \
	spec_12.adoc \
	spec_13.adoc \
	spec_14.adoc \
	spec_15.adoc \

HTML = $(SOURCES:.adoc=.html)
PDF = $(SOURCES:.adoc=.pdf)

all: html

html: $(HTML)

pdf: $(PDF)

%.html: %.adoc
	asciidoc -o $@ $^

%.pdf: %.adoc
	a2x -f pdf $^

clean:
	rm -f $(HTML) $(PDF)

check:
	ASPELL=aspell ./spellcheck *.adoc
