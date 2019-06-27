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
	spec_16.adoc \
	spec_18.adoc \
	spec_19.adoc \
	spec_20.adoc \
	spec_21.adoc \
	spec_22.adoc \
	spec_23.adoc \
	spec_24.adoc \
	spec_25.adoc


HTML = $(SOURCES:.adoc=.html)

# N.B. 'apt-get install codray' to enable inline source highlighting
ADOC_FLAGS = --attribute=source-highlighter=coderay

all: html

html: $(HTML)

%.html: %.adoc
	asciidoctor $(ADOC_FLAGS) -o $@ $^

clean:
	rm -f $(HTML)

check:
	ASPELL=aspell ./spellcheck *.adoc
	./indexcheck spec_*.adoc
