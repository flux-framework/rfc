all: states.svg

clean:
	rm -f states.svg

%.svg: %.dot
	dot -Tsvg $^ -o $@
