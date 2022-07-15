
const DAO = artifacts.require("DAO.sol");
const Asset = artifacts.require("Asset.sol");
const AssetGlobal = artifacts.require("AssetGlobal.sol");
const Ledger = artifacts.require("Ledger.sol");
const Member = artifacts.require("Member.sol");
const VotePool = artifacts.require("VotePool.sol");

async function deploy(name, Contract, opts, args = [], isUpgrade = true) {
	await opts.deployer.deploy(Contract, ...args);
	var impl = await Contract.deployed();
	if (isUpgrade) {
		var ContextContract = artifacts.require(`ContextProxy${name}`);
		var ctx = await opts.deployer.deploy(ContextContract, impl.address);
		var c = await Contract.at(ctx.address);
		return c;
	} else {
		return impl;
	}
}

module.exports = async function(deployer, networks, accounts) {
	debugger

	var opts = { deployer, initializer: 'initialize', unsafeAllowCustomTypes: true };
	var operator = '0x0000000000000000000000000000000000000000';
	var from = deployer.options.from;

	var dao = await deploy('DAO', DAO, opts);
	var asset = await deploy('Asset', Asset, opts);
	var assetGlobal = await deploy('AssetGlobal', AssetGlobal, opts);
	var ledger = await deploy('Ledger', Ledger, opts);
	var member = await deploy('Member', Member, opts);
	var votePool = await deploy('VotePool', VotePool, opts, []);

	await asset.initAsset(dao.address, 'Asset', operator);
	await assetGlobal.initAssetGlobal(dao.address, 'AssetGlobal', operator);
	await ledger.initLedger(dao.address, 'Ledger', operator);
	await member.initMember(dao.address, 'Member', operator);
	await votePool.initVotePool(dao.address, 'VotePool', [], false);
	await dao.initDAO('Test', from, votePool.address, member.address, ledger.address, assetGlobal.address, asset.address);

	debugger

	console.log("DAO:", dao.address);
	console.log("AssetGlobal:", assetGlobal.address);
	console.log("Asset:", asset.address);
	console.log("Ledger:", ledger.address);
	console.log("Member:", member.address);
	console.log("VotePool:", votePool.address);
};