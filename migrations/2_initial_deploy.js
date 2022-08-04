
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

module.exports = async function(deployer, networks, accounts) {
	if (process.env.noDeploy == 'true' && fs.existsSync(`${__dirname}/../build/deploy.json`)) return;

	var opts = { deployer, initializer: 'initialize', unsafeAllowCustomTypes: true };
	var from = deployer.options.from;
	var operator = from; // '0x0000000000000000000000000000000000000000';

	var dao = await deploy('DAO', DAO, opts, [], false);
	var asset = await deploy('Asset', Asset, opts, [], false);
	var assetGlobal = await deploy('AssetGlobal', AssetGlobal, opts, [], false);
	var ledger = await deploy('Ledger', Ledger, opts, [], false);
	var member = await deploy('Member', Member, opts, [], false);
	var votePool = await deploy('VotePool', VotePool, opts, [], false);

	// var dao = await DAO.at('0x3b4710ca147372927BC54A45710a3FeD6c188F37');
	// var asset = await Asset.at('0x67E36B30226b9a780cCc4F4621dD3E30f41A6384');
	// var assetGlobal = await AssetGlobal.at('0x07c8802d4aa31b8905dDfdE86D3ecA92b4c724eB');
	// var ledger = await Ledger.at('0xd4ab6cC47DafbD1aDaA8f9186a1fe37989255539');
	// var member = await Member.at('0xCc7b1Ee5BdF9EB7199a5d4B1BB6D4F0FeCEF3E59');
	// var votePool = await VotePool.at('0xB83BB3fE46520c04796090370aB3AC2e5Aa1fF42');

	console.log("DAO:", dao.address, "IMPL:", dao.address);
	console.log("AssetGlobal:", assetGlobal.address, "IMPL:", assetGlobal.address);
	console.log("Asset:", asset.address, "IMPL:", asset.address);
	console.log("Ledger:", ledger.address, "IMPL:", ledger.address);
	console.log("Member:", member.address, "IMPL:", member.address);
	console.log("VotePool:", votePool.address, "IMPL:", votePool.address);

	if (process.env.noInit == 'true') return;

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

	fs.writeFileSync(`${__dirname}/../build/deploy.json`, JSON.stringify({
		dao: dao.address,
		assetGlobal: assetGlobal.address,
		asset: asset.address,
		ledger: ledger.address,
		member: member.address,
		votePool: votePool.address,
	}, null, 2));
};