
const fs = require('fs');

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
		var json = JSON.parse(fs.readFileSync(`${__dirname}/../build/deploy.json`, 'utf-8'));
		this.dao = await DAO.at(json.dao);//deployed();
		this.asset = await Asset.at(json.asset);//deployed();
		this.assetGlobal = await AssetGlobal.at(json.assetGlobal);//deployed();
		this.ledger = await Ledger.at(json.ledger);//deployed();
		this.member = await Member.at(json.member);//deployed();
		this.votePool = await VotePool.at(json.votePool);//deployed();
	}
}

async function createApp(account) {
	var app = new App();
	await app.deployed(account);
	return app;
}

module.exports = {createApp}
