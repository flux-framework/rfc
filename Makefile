HTML = spec_1.html spec_2.html spec_3.html spec_4.html

all: $(HTML)

%.html: %.adoc
	asciidoc -o $@ $^

clean:
	rm -f $(HTML)
