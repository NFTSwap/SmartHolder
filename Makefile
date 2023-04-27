
ifeq ($(DEBUG),1)
	DEBUG = --inspect-brk=9230
endif

ENV     ?= goerli
NODE    ?= node $(DEBUG)
DEBUG   ?=
TRUFFLE ?= $(NODE) ./node_modules/.bin/truffle

.PHONY: build deploy test

# Build all and proxy
build:
	rm -rf build
	$(NODE)    gen-proxy.js --placeholder
	$(TRUFFLE) compile --all
	$(TRUFFLE) exec --network $(ENV) gen-proxy.js
	$(TRUFFLE) compile --all

# Deploy or upgrade
deploy:
	GAS=$(shell node gas $(ENV)) $(TRUFFLE) deploy --network $(ENV)

# Deploy contracts before testing
test:
	GAS=$(shell node gas $(ENV)) $(TRUFFLE) test --network $(ENV) --compile-none