
// const Migrations = artifacts.require("Migrations");
const Asset = artifacts.require("Asset");
const { singletons } = require('@openzeppelin/test-helpers');
const configure = require('@openzeppelin/test-helpers/configure');

async function settings() {
	// const from = deployer.options.from;
	const from = config.from;
	const adapter = Asset.interfaceAdapter;
	const web3 = adapter.web3;
	const user = web3.utils.toChecksumAddress(from);

	// init openzeppelin test config
	configure({
		provider: adapter.web3.currentProvider,
		singletons: {
			abstraction: 'truffle',
			defaultGas: 200e3,
			defaultSender: user,
		}
	});
	// reg 1820
	await singletons.ERC1820Registry(user);
};

module.exports = async function (deployer, network, accounts) {
	await settings();
	if (process.env.onlyBuild == 'true') {
		await require('../scripts/gen_proxy')();
		process.exit(0);
	}
	// await deployer.deploy(Migrations);
};