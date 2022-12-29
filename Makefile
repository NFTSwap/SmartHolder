
NET     ?= goerli
NODE    ?= node

.PHONY: build deploy deploy-impl deploy-proxy

# build all and proxy
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

# deploy or upgrade
deploy: build
	$(NODE) ./node_modules/.bin/truffle deploy --network $(NET)