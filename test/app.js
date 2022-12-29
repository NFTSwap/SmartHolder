
const { singletons } = require('@openzeppelin/test-helpers');
const configure = require('@openzeppelin/test-helpers/configure');
const fs = require('fs');
const { inherits } = require('util');

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

	static async init() {
		const web3 = Asset.interfaceAdapter.web3;
		const user = web3.utils.toChecksumAddress(config.from);
		// init openzeppelin test config
		configure({
			provider: web3.currentProvider,
			singletons: {
				abstraction: 'truffle',
				defaultGas: 200e3,
				defaultSender: user,
			}
		});
		// reg 1820
		await singletons.ERC1820Registry(user);
	}

	static async create(account) {
		App.init();
		var app = new App();
		await app.deployed(account);
		return app;
	}

}

module.exports = App;
