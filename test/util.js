
const helpers = require('@openzeppelin/test-helpers');
const configure = require('@openzeppelin/test-helpers/configure');

const DAOs = artifacts.require("DAOs.sol");
const somes = require('somes').default;

let app;

class Application {

	async initConfigure() {
		const web3 = DAOs.interfaceAdapter.web3;
		const account = config.from;
		// init openzeppelin test config
		configure({
			provider: web3.currentProvider,
			singletons: {
				abstraction: 'truffle',
				defaultGas: 200e3,
				defaultSender: account,
			}
		});
		// reg 1820
		await helpers.singletons.ERC1820Registry(account);
	}

	async init() {
		this.deployInfo = require('../deployInfo')[config.network];
		await this.initConfigure();
		this.DAOs = await DAOs.at(this.deployInfo.DAOsProxy.address);
		this.DAO = await this.deployAssetSalesDAO(); // deploy DAO
		return this;
	}

	async deploy() {
		let name = `Test_${somes.random()}`;
		await this.DAOs.deploy(name, `${name} mission`, `${name} description`, config.from,
		{ // InitMemberArgs
			name: 'Member',
			description: 'Member description',
			members: [{
				owner: config.from,
				info: {
					id: 0,
					name: 'Test',
					description: 'Test',
					avatar: 'https://picx.zhimg.com/v2-72e9fd76f8d5b941acb976826ff2ba90_l.jpg?source=32738c0c',
					votes: 1,
				},
				tokenURI: 'https://picx.zhimg.com/v2-72e9fd76f8d5b941acb976826ff2ba90_l.jpg?source=32738c0c',
				permissions: [0xdc6b0b72, 0x678ea396],
			}]
		}, { //InitVotePoolArgs
			description: 'VotePool description',
			lifespan: 7 * 24 * 60 * 60, /*7 days*/
		});
		let dao = await this.DAOs.get(name);
		// console.log(`   ----------- deploy DAO Ok ${dao} -----------`);
		return dao;
	}

	async deployAssetSalesDAO() {
		let name = `Test_Asset_Sales_DAO_${somes.random()}`;
		await this.DAOs.deployAssetSalesDAO(name, `${name} mission`, `${name} description`, config.from,
		{ // InitMemberArgs
			name: 'Member',
			description: 'Member description',
			members: [{
				owner: config.from,
				info: {
					id: 0,
					name: 'Test',
					description: 'Test',
					avatar: 'https://picx.zhimg.com/v2-72e9fd76f8d5b941acb976826ff2ba90_l.jpg?source=32738c0c',
					votes: 1,
				},
				tokenURI: 'https://picx.zhimg.com/v2-72e9fd76f8d5b941acb976826ff2ba90_l.jpg?source=32738c0c',
				permissions: [0xdc6b0b72, 0x678ea396],
			}]
		}, { //InitVotePoolArgs
			description: 'VotePool description',
			lifespan: 7 * 24 * 60 * 60, /*7 days*/
		}, { // InitLedgerArgs
			description: 'Ledger description',
		}, { // InitAssetArgs
			name: name, // string  name;
			description: 'Asset description',
			image: 'https://smart-dao-home-rel.stars-mine.com/assets/logo.c5133168.png',
			external_link: 'https://smart-dao-home-rel.stars-mine.com/',
			seller_fee_basis_points_first: 3000, // 30%
			seller_fee_basis_points_second: 1000, // 10%
			fee_recipient: '0x0000000000000000000000000000000000000000', // auto set
			contractURIPrefix: 'https://smart-dao-rel.stars-mine.com/service-api/utils/printJSON',
		});

		let dao = await this.DAOs.get(name);
		console.log(`----------- deploy Asset Sales DAO Ok ${dao} -----------`);
		return dao;
	}

	static async create() {
		if (!app) {
			app = await (new Application()).init();
		}
		return app;
	}

}

module.exports = Application;
