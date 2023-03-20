SOURCES=$(wildcard src/*.md)
TARGETS=$(patsubst src/%.md,docs/%.html,$(SOURCES))

all: $(TARGETS)


docs/%.html: src/%.md 
	pandoc \
		--mathjax \
		--filter pandoc-sidenote \
		--to html5+smart \
		--template=template \
		--css="css/theme.css" \
		--css="css/skylighting.css" \
		--css="css/fonts.css" \
		--toc \
		--wrap=none \
		--output "$@" \
		"$<"

clean:
	rm -rf docs/*.html
