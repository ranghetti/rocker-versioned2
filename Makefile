SHELL=/bin/bash
STACKFILES=$(wildcard stacks/*.json)
STACKS=$(notdir $(basename $(STACKFILES)))
COMPOSEFILES=$(addprefix compose/,$(addsuffix .yml,$(STACKS)))
PUSHES=$(addsuffix .push,$(STACKS))
LATEST_TAG=4.0.3



.PHONY: clean build setup push latest
.PHONY: $(STACKS) $(PUSHES)

all: clean build push
latest: clean setup core-$(LATEST_TAG) geospatial-$(LATEST_TAG)

setup: $(COMPOSEFILES)
$(COMPOSEFILES): make-dockerfiles.R write-compose.R $(STACKFILES)
	./make-dockerfiles.R
	./write-compose.R

build: $(STACKS)

$(STACKS): %: compose/%.yml
	docker-compose -f compose/$@.yml build

## Dependency order
binder-$(LATEST_TAG): geospatial-$(LATEST_TAG)
shiny-$(LATEST_TAG): core-$(LATEST_TAG)
geospatial-$(LATEST_TAG): core-$(LATEST_TAG) core-devel
geospatial-unstable: geospatial-$(LATEST_TAG)

## Assumes we are logged into the Docker Registry already
push: $(PUSHES)

$(PUSHES): %.push: %
	docker-compose -f compose/$<.yml push; \
	./tag.sh $< $(LATEST_TAG)
clean:
	rm -f dockerfiles/* compose/*
