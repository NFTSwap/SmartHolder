const Migrations = artifacts.require("Migrations");

const { singletons } = require('@openzeppelin/test-helpers');
const configure = require('@openzeppelin/test-helpers/configure');

module.exports = async function (deployer, network, accounts) {
	var adapter = Migrations.interfaceAdapter;
	const web3 = adapter.web3;

	const user = web3.utils.toChecksumAddress(accounts[0]);
	// init openzeppelin test config
	configure({
		provider: adapter.web3.currentProvider,
		singletons: {
			abstraction: 'truffle',
			defaultGas: 200e3,
			defaultSender: user,
		}
	})
	// reg 1820
	await singletons.ERC1820Registry(user);
};
