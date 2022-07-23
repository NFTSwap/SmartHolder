
const DAO = artifacts.require("DAO.sol");
const Asset = artifacts.require("Asset.sol");
const AssetGlobal = artifacts.require("AssetGlobal.sol");
const Ledger = artifacts.require("Ledger.sol");
const Member = artifacts.require("Member.sol");
const VotePool = artifacts.require("VotePool.sol");

async function deploy(name, Contract, opts, args = [], isUpgrade = true) {debugger
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
}

module.exports = async function(deployer, networks, accounts) {

	var opts = { deployer, initializer: 'initialize', unsafeAllowCustomTypes: true };
	var operator = '0x0000000000000000000000000000000000000000';
	var from = deployer.options.from;

	if (process.env.onlyImpl == 'true') {
		return await onlyImpl(opts);
	}

	var dao = await deploy('DAO', DAO, opts);
	var asset = await deploy('Asset', Asset, opts);
	var assetGlobal = await deploy('AssetGlobal', AssetGlobal, opts);
	var ledger = await deploy('Ledger', Ledger, opts);
	var member = await deploy('Member', Member, opts);
	var votePool = await deploy('VotePool', VotePool, opts);

	// var dao = await DAO.at('0x1F978cd7B8eD52c30C743213B8C79Bbe1deD2Ed6');
	// var asset = await Asset.at('0x9b24edF5917b484AAEA96b7b4b108FC0d92D5bc4');
	// var assetGlobal = await AssetGlobal.at('0x174592711b02dFc27030074Eb48a568D0B421183');
	// var ledger = await Ledger.at('0xdf3057268dA671Bad70d260da3D7110aBf901354');
	// var member = await Member.at('0x50523F67f863eB6C5882bb0ea8C807f37c143369');
	// var votePool = await VotePool.at('0x22700b353C4316c4de2B980Df0Bef0A1827E348B');

	await dao.initInterfaceID();
	await asset.initAsset(dao.address, 'Asset', operator);
	await assetGlobal.initAssetGlobal(dao.address, 'AssetGlobal', operator);
	await ledger.initLedger(dao.address, 'Ledger', operator);
	await member.initMember(dao.address, 'Member', operator);
	await votePool.initVotePool(dao.address, 'VotePool');
	await dao.initDAO('Test', from, votePool.address, member.address, ledger.address, assetGlobal.address, asset.address);

	console.log("DAO:", dao.address, "IMPL:", dao.impl.address);
	console.log("AssetGlobal:", assetGlobal.address, "IMPL:", assetGlobal.impl.address);
	console.log("Asset:", asset.address, "IMPL:", asset.impl.address);
	console.log("Ledger:", ledger.address, "IMPL:", ledger.impl.address);
	console.log("Member:", member.address, "IMPL:", member.impl.address);
	console.log("VotePool:", votePool.address, "IMPL:", votePool.impl.address);
};