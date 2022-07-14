
const constants = require("@openzeppelin/test-helpers/src/constants");
const { web3, BN } = require("@openzeppelin/test-helpers/src/setup");

const Exchange = artifacts.require("Exchange.sol");
const FeePlan = artifacts.require("FeePlan.sol");
const Ledger = artifacts.require("Ledger.sol");
const VotePool = artifacts.require("VotePool.sol");
// init some thing
require("@openzeppelin/test-helpers");

class App {
	async deployed(account) {
		this.ledger = await Ledger.deployed();
		this.feePlan = await FeePlan.deployed();
		this.votePool = await VotePool.deployed();
		this.exchange = await Exchange.deployed();
	}
}

module.exports = async function createApp(account) {
	var app = new App();
	await app.deployed(account);
	return app;
}
