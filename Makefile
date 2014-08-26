.PHONY: all syntax main.js
SOURCES = main.coffee

all: syntax main.js

syntax: $(SOURCES)
	coffee -c main.coffee

main.js: $(SOURCES)
	coffee -cbj main.js $(SOURCES)

