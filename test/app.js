
const helpers = require('@openzeppelin/test-helpers');
const configure = require('@openzeppelin/test-helpers/configure');

const DAOs = artifacts.require("DAOs.sol");
const DAO = artifacts.require("DAO.sol");

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
		this.web3 = web3;
	}

	async getDAO() {
		if (!this.DAO) {
			let len = await this.DAOs.length();
			let addr = await this.DAOs.at(len - 1);
			this.DAO = await DAO.at(addr);
		}
		return this.DAO;
	}

	async init() {
		this.deployInfo = require('../deployInfo')[config.network];
		await this.initConfigure();
		this.DAOs = await DAOs.at(this.deployInfo.DAOsProxy.address);
		return this;
	}

	static async create() {
		if (!app)
			app = await (new Application()).init();
		return app;
	}

}

module.exports = Application;
