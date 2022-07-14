
const DAO = artifacts.require("DAO.sol");
const Asset = artifacts.require("Asset.sol");
const AssetGlobal = artifacts.require("AssetGlobal.sol");
const Ledger = artifacts.require("Ledger.sol");
const Member = artifacts.require("Member.sol");
const VotePool = artifacts.require("VotePool.sol");
const assert = require('assert');

// const { deployProxy, upgradeProxy, prepareUpgrade } = require('@openzeppelin/truffle-upgrades');
const { deployProxy, upgradeProxy, prepareUpgrade } = require('@openzeppelin/truffle-upgrades');

const fs = require('fs');

async function upgradeDeploy(name, Contract, args, opts) {
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

function deploy(name, Contract, args, opts) {
	return opts.deployer.deploy(Contract, ...args);
}

module.exports = async function(deployer, networks, accounts) {
	opts = { deployer, initializer: 'initialize', unsafeAllowCustomTypes: true };

	var dao = await deploy('DAO', DAO, [], opts);
	var asset = await deploy('Asset', Asset, [], opts);
	// var assetGlobal = await deploy('AssetGlobal', AssetGlobal, [], opts);
	// var ledger = await deploy('Ledger', Ledger, [], opts);
	// var member = await deploy('Member', Member, [], opts);
	// var votePool = await deploy('VotePool', VotePool, [], opts);

	debugger

	// await asset.initAsset();

};