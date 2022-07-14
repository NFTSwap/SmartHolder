
const constants = require("@openzeppelin/test-helpers/src/constants");
const { web3, BN } = require("@openzeppelin/test-helpers/src/setup");

const DAO = artifacts.require("DAO.sol");
const Asset = artifacts.require("Asset.sol");
const AssetGlobal = artifacts.require("AssetGlobal.sol");
const Ledger = artifacts.require("Ledger.sol");
const Member = artifacts.require("Member.sol");
const VotePool = artifacts.require("VotePool.sol");

// init some thing
require("@openzeppelin/test-helpers");

class App {
	async deployed(account) {
		this.DAO = await DAO.deployed();
		this.Asset = await Asset.deployed();
		this.AssetGlobal = await AssetGlobal.deployed();
		this.Ledger = await Ledger.deployed();
		this.Member = await Member.deployed();
		this.VotePool = await VotePool.deployed();
	}
}

async function createApp(account) {
	var app = new App();
	await app.deployed(account);
	return app;
}

module.exports = {createApp}
