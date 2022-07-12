var Exchange = artifacts.require("Exchange.sol");
var FeePlan = artifacts.require("FeePlan.sol");
var Ledger = artifacts.require("Ledger.sol");
var VotePool = artifacts.require("VotePool.sol");
var NFTs = artifacts.require("NFTs.sol");
var assert = require('assert');

const { deployProxy, upgradeProxy, prepareUpgrade } = require('@openzeppelin/truffle-upgrades');

const fs = require('fs');

async function deploy(name, Contract, args, opts) {
	const deployer = opts.deployer;
	const cache_src = `${process.env.HOME || '/tmp'}/.nft101_${deployer.network}_proxy`;
	const isFork = deployer.network.indexOf('fork') != -1;

	if (isFork) {
		var contract = await deployProxy(Contract, args, opts);
		await upgradeProxy(contract.address, Contract, {deployer});
		return contract;
	}

	var caches = {};

	if (fs.existsSync(cache_src)) {
		try {
			caches = JSON.parse(fs.readFileSync(cache_src, 'utf-8'));
		} catch(err) {}
	}

	var contract;
	var obj = caches[name];

	if (obj && obj.address) {
		contract = new Contract(obj.address);
		contract.cached = true;
		if (cache.impl == await prepareUpgrade(contract.address, Contract, {deployer}))
			return contract;
	}

	if (!contract)
		contract = await deployProxy(Contract, args, opts);
	await upgradeProxy(contract.address, Contract, {deployer});

	caches[name] = {
		address: contract.address,
		impl: await prepareUpgrade(contract.address, Contract, {deployer}),
	};
	fs.writeFileSync(cache_src, JSON.stringify(caches, null, 2));

	return contract;
}

module.exports = async function(deployer, networks, accounts) {
	// https://docs.openzeppelin.com/upgrades-plugins/1.x/faq#why-cant-i-use-custom-types
	let opts = { deployer, initializer: 'initialize', unsafeAllowCustomTypes: true };

	// TODO ...

};