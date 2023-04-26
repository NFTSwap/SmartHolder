
ENV     ?= goerli
NODE    ?= node
DEBUG   ?=

ifeq ($(DEBUG),1)
	DEBUG = --inspect-brk=9230
endif

.PHONY: build deploy test

# Build all and proxy
build:
	if [ -f contracts/DAOs.sol ]; \
		then mv contracts/DAOs.sol contracts/DAOs.sol.bk;\
	fi
	rm -rf build
	npm run build
	npm run build-proxy
	mv contracts/DAOs.sol.bk contracts/DAOs.sol
	npm run build
	npm run build-proxy
	npm run build

# Deploy or upgrade
deploy: build
	$(NODE) $(DEBUG) ./node_modules/.bin/truffle deploy --network $(ENV)

# Deploy contracts before testing
test:
	TEST=1 $(NODE) $(DEBUG)  ./node_modules/.bin/truffle test --network $(ENV) --compile-none