
const DAO = artifacts.require("DAO.sol");
const Asset = artifacts.require("Asset.sol");
const AssetGlobal = artifacts.require("AssetGlobal.sol");
const Ledger = artifacts.require("Ledger.sol");
const Member = artifacts.require("Member.sol");
const VotePool = artifacts.require("VotePool.sol");
const fs = require('fs');

async function deploy(name, Contract, opts, args = [], isUpgrade = true) {
	console.log('Deploy', name);
	await opts.deployer.deploy(Contract, ...args);
	var impl = await Contract.deployed();
	if (isUpgrade) {
		var ContextContract = artifacts.require(`ContextProxy${name}`);
		var ctx = await opts.deployer.deploy(ContextContract, impl.address);
		var c = await Contract.at(ctx.address);
		c.impl = impl;
		return c;
	} else {
		return impl;
	}
}

async function onlyImpl(opts) {
	var operator = '0x0000000000000000000000000000000000000000';
	var from = opts.deployer.options.from;

	var dao = await deploy('DAO', DAO, opts, [], false);
	var asset = await deploy('Asset', Asset, opts, [], false);
	var assetGlobal = await deploy('AssetGlobal', AssetGlobal, opts, [], false);
	var ledger = await deploy('Ledger', Ledger, opts, [], false);
	var member = await deploy('Member', Member, opts, [], false);
	var votePool = await deploy('VotePool', VotePool, opts, [], false);

	console.log("DAO:", dao.address);
	console.log("AssetGlobal:", assetGlobal.address);
	console.log("Asset:", asset.address);
	console.log("Ledger:", ledger.address);
	console.log("Member:", member.address);
	console.log("VotePool:", votePool.address);

	if (!await dao.supportsInterface('0xc7b55336')) {
		await dao.initInterfaceID(); console.log('initInterfaceID ok');
	}
	if (await asset.host() != dao.address) {
		await asset.initAsset(dao.address, 'Asset', operator); console.log('initAsset ok');
	}
	if (await assetGlobal.host() != dao.address) {
		await assetGlobal.initAssetGlobal(dao.address, 'AssetGlobal', operator); console.log('initAssetGlobal ok');
	}
	if (await ledger.host() != dao.address) {
		await ledger.initLedger(dao.address, 'Ledger', operator); console.log('initLedger ok');
	}
	if (await member.host() != dao.address) {
		await member.initMember(dao.address, 'Member', operator); console.log('initMember ok');
	}
	if (await votePool.host() != dao.address) {
		await votePool.initVotePool(dao.address, 'VotePool'); console.log('initVotePool ok');
	}
	if (await dao.asset() != asset.address) {
		await dao.initDAO('Test', '', '', from, votePool.address, member.address, ledger.address, assetGlobal.address, asset.address);
		console.log('initDAO ok');
	}

	fs.writeFileSync(`${__dirname}/../build/_impls.json`, JSON.stringify({
		dao: dao.address,
		assetGlobal: assetGlobal.address,
		asset: asset.address,
		ledger: ledger.address,
		member: member.address,
		votePool: votePool.address,
	}));

	return {dao,assetGlobal,asset,ledger,member,votePool};
}

module.exports = async function(deployer, networks, accounts) {

	var opts = { deployer, initializer: 'initialize', unsafeAllowCustomTypes: true };
	var operator = '0x0000000000000000000000000000000000000000';
	var from = deployer.options.from;

	if (process.env.onlyImpl == 'true') {
		return await onlyImpl(opts);
	}

	if (process.env.onlyTest) {
		return;
	}

	var dao = await deploy('DAO', DAO, opts);
	var asset = await deploy('Asset', Asset, opts);
	var assetGlobal = await deploy('AssetGlobal', AssetGlobal, opts);
	var ledger = await deploy('Ledger', Ledger, opts);
	var member = await deploy('Member', Member, opts);
	var votePool = await deploy('VotePool', VotePool, opts);

	await dao.initInterfaceID();
	await asset.initAsset(dao.address, 'Asset', operator);
	await assetGlobal.initAssetGlobal(dao.address, 'AssetGlobal', operator);
	await ledger.initLedger(dao.address, 'Ledger', operator);
	await member.initMember(dao.address, 'Member', operator);
	await votePool.initVotePool(dao.address, 'VotePool');
	await dao.initDAO('Test', '', '', from, votePool.address, member.address, ledger.address, assetGlobal.address, asset.address);

	console.log("DAO:", dao.address, "IMPL:", dao.impl.address);
	console.log("AssetGlobal:", assetGlobal.address, "IMPL:", assetGlobal.impl.address);
	console.log("Asset:", asset.address, "IMPL:", asset.impl.address);
	console.log("Ledger:", ledger.address, "IMPL:", ledger.impl.address);
	console.log("Member:", member.address, "IMPL:", member.impl.address);
	console.log("VotePool:", votePool.address, "IMPL:", votePool.impl.address);
};