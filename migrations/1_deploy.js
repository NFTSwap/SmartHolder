
const fs = require('fs');
const deployImpl = require('@openzeppelin/truffle-upgrades/dist/utils/deploy-impl');
const genProxy = require('../gen-proxy');
const {GEN_PROXY} = process.env;

function deployInfo() {
	try {
		return JSON.parse(fs.readFileSync(`${__dirname}/../deployInfo.json`, 'utf-8'));
	} catch(err) {
		return {};
	}
}

function setDeployInfo(networks, key, value, type = 'address') {
	let all = deployInfo();
	let info = (all[networks] || (all[networks] = {}));
	let node = (info[key] ||  (info[key] = {}));
	node[type] = value;
	fs.writeFileSync(`${__dirname}/../deployInfo.json`, JSON.stringify(all, null, 2));
}

async function getDeployData(name, opts, args = []) {
	let Contract = artifacts.require(`${name}.sol`);
	let {
		fullOpts, validations, version, provider, layout
	} = await deployImpl.getDeployData({deployer: opts.deployer, constructorArgs: args}, Contract);
	let info = deployInfo()[opts.networks] || {};
	let infoData = info[name] || {};
	let prevVersion =  infoData.version || '';
	let currentVersion = version.linkedWithoutMetadata || '';
	return {
		opts,
		name,
		Contract,
		address: infoData.address || '0x0000000000000000000000000000000000000000',
		prevVersion,
		currentVersion,
		hasUpdate: prevVersion != currentVersion,
		fullOpts, validations, version, provider, layout,
	};
}

async function deploy(name, opts, args = [], initializer = async ()=>{}) {
	let data = await getDeployData(name, opts, args);
	if (data.hasUpdate) {
		await opts.deployer.deploy(data.Contract, ...args);
		let deployed = await data.Contract.deployed();
		data.address = deployed.address;
		await initializer(deployed);
		if (opts.networks.indexOf('-fork') == -1) { // Not a simulator
			setDeployInfo(opts.networks, name, data.currentVersion, 'version');
			setDeployInfo(opts.networks, name, data.address, 'address');
		}
	}
	return data;
}

module.exports = async function(deployer, networks, accounts) {
	if (GEN_PROXY == '1') {
		await genProxy();
		process.exit(0);
	}
	let opts = { deployer, networks };

	// deploy all impl
	let Asset = await deploy('Asset', opts);
	let AssetShell = await deploy('AssetShell', opts);
	let Ledger = await deploy('Ledger', opts);
	let Member = await deploy('Member', opts);
	let VotePool = await deploy('VotePool', opts);
	let DAO = await deploy('DAO', opts);
	let DAOs = await deploy('DAOs', opts);
	let DAOsProxy = await deploy('DAOsProxy', opts, [DAOs.address], async (deployed)=>{
		await (await DAOs.Contract.at(deployed.address)).initDAOs();
	});

	let DAOsObj = await DAOs.Contract.at(DAOsProxy.address);
	let defaultIMPLs = await DAOsObj.defaultIMPLs();

	if (
		defaultIMPLs.DAO != DAO.address           || defaultIMPLs.Member != Member.address ||
		defaultIMPLs.VotePool != VotePool.address || defaultIMPLs.Ledger != Ledger.address ||
		defaultIMPLs.Asset != Member.Asset        || defaultIMPLs.AssetShell != Member.AssetShell
	) {
		await DAOsObj.setDefaultIMPLs({
			DAO: DAO.address,           Member: Member.address,
			VotePool: VotePool.address, Ledger: Ledger.address,
			Asset: Asset.address,       AssetShell: AssetShell.address,
		});
		console.log('call DAOs.setDefaultIMPLs()');
	}

	//console.log(Asset.address, Asset.version);
	//console.log(DAOsProxy.address, DAOsProxy.version);
	//console.log(defaultIMPLs);
};