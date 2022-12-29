
//const fs = require('fs');
const genProxy = require('../gen-proxy');
const {GEN_PROXY,IMPL,PROXY} = process.env;

async function deploy(name, opts, args = []) {
	let Contract = artifacts.require(`${name}.sol`);
	await opts.deployer.deploy(Contract, ...args);
	return await Contract.deployed();
}

module.exports = async function(deployer, networks, accounts) {
	if (GEN_PROXY == '1') {
		await genProxy();
		process.exit(0);
	}
	let opts = { deployer, initializer: 'initialize', unsafeAllowCustomTypes: true };

	if (IMPL == '1') { // only deploy impl
		await deploy('DAOs', opts, []);
	}
	else if (PROXY == '1') { // only deploy proxy
		await deploy('DAOsProxy', opts, []);
	}
	else { // upgrade deploy
		// TODO ...
	}

	// var dao = await deploy(DAOs, opts, []);

	// console.log("DAOs:", dao.address);

	// fs.writeFileSync(`${__dirname}/../build/${networks}_deploy.json`, JSON.stringify({
	// 	dao: dao.address,
	// 	member: member.address,
	// 	votePool: votePool.address,
	// 	ledger: ledger.address,
	// 	asset: asset.address,
	// 	AssetShell: AssetShell.address,
	// }, null, 2));
};