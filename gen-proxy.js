
const fs = require('fs');
const deployImpl = require('@openzeppelin/truffle-upgrades/dist/utils/deploy-impl');

function pushDefine(type, label, defines, names, indent) {
	if (label) {
		let count = names[label];
		if (count) {
			label += `_${count}`;
			names[label]++;
		} else {
			names[label] = 1;
		}
		defines.push(Array.from({length:indent}).join('	') + `${type} ${label};`);
	}
	else
		defines.push(type);
}

function joinLayoutItem(types, label, typename, defines, names, structs, indent) {
	let type = types[typename];
	let type_label = type.label;
	let mat, def;

	if (mat = typename.match(/^t_mapping\((.+?),(.+)\)$/)) { // mapping
		// mapping(address => mapping(address => bool))
		// t_mapping(t_address,t_struct(UintSet)5688_storage):
		let defines_key = [], defines_value = [];
		joinLayoutItem(types, '', mat[1], defines_key, {}, structs, indent);
		joinLayoutItem(types, '', mat[2], defines_value, {}, structs, indent);
		def = `mapping(${defines_key.join('')} => ${defines_value.join('')})`;
	}
	else if (mat = typename.match(/^t_array\((.+)\)/)) { // array
		// t_array(t_struct(MapEntry)4941_storage)dyn_storage
		let defines_arr = [];
		let len = type_label.match(/\[\d+\]/);
		joinLayoutItem(types, '', mat[1], defines_arr, {}, structs, indent);
		def = `${defines_arr.join('')}${len?len[0]:'[]'}`;
	}
	else if (type_label.substring(0,9) == 'contract ') {
		def = `address`;
	}
	else if (type_label.substring(0,7) == 'struct ') {
		let structName = type_label.substring(7).replace('.', '_');
		let structStr = `struct ${structName} {\n`;
		let defines_child = [];
		joinLayout(types, type.members, defines_child, {}, structs, indent);
		structStr += defines_child.join('\n');
		structStr += '\n}';
		structs[structName] = structStr;
		def = structName;
	}
	else if (type_label.substring(0, 5) == 'enum ') {
		let enumName = type_label.substring(5).replace('.', '_');
		let enumStr = `enum ${enumName} {\n ${type.members.join(',')} \n}`;
		structs[enumName] = enumStr;
		def = enumName;
	}
	else {
		def = type_label;
	}

	pushDefine(def, label, defines, names, indent);
}

function joinLayout(types, storage, defines, names, structs, indent) {
	for (let {label,type} of storage) {
		joinLayoutItem(types, label, type, defines, names, structs, indent + 1);
	}
}

async function genStore(name, Contract, opts) {
	let data = await deployImpl.getDeployData(opts, Contract);
	// {
	// 	withMetadata: '0846ec7062f5e60e29b48ca6e0bccdbe43c881f4fad2d7c26a05476ba44673a2',
	// 	withoutMetadata: 'f8ef373b58307a883693d440bc08fe245bfc73b9b047a2a76184358c27a1e625',
	// 	linkedWithoutMetadata: 'f8ef373b58307a883693d440bc08fe245bfc73b9b047a2a76184358c27a1e625'
	// }
	//console.log(name, data.version.linkedWithoutMetadata);
	let templ = fs.readFileSync(`${__dirname}/contracts/libs/Upgrade.sol`, 'utf-8');
	let defines = [];
	let defineStructs = {};
	joinLayout(data.layout.types, data.layout.storage, defines, {}, defineStructs, 1);
	templ = templ.replaceAll('Upgrade', `${name}Store`);
	templ = templ.replace('ProxyStore', `${name}Proxy`);

	let structsStr = '';
	for (let [k,v] of Object.entries(defineStructs)) {
		structsStr += v + '\n';
	}

	templ = templ.replace(/address\s+internal\s+_impl;/, structsStr + '\n' + defines.join('\n'));
	fs.writeFileSync(`${__dirname}/contracts/gen/${name}Proxy.sol`, templ);
}

module.exports = async function(deployer) {
	let opts = { deployer };

	fs.mkdirSync(`${__dirname}/contracts/gen`, {recursive: true});

	await genStore('Asset', artifacts.require("Asset.sol"), opts);
	await genStore('AssetShell', artifacts.require("AssetShell.sol"), opts);
	await genStore('Ledger', artifacts.require("Ledger.sol"), opts);
	await genStore('Member', artifacts.require("Member.sol"), opts);
	await genStore('VotePool', artifacts.require("VotePool.sol"), opts);
	await genStore('Share', artifacts.require("Share.sol"), opts);
	await genStore('DAO', artifacts.require("DAO.sol"), opts);

	if (fs.existsSync(`${__dirname}/contracts/DAOs.sol`)) {
		await genStore('DAOs', artifacts.require("DAOs.sol"), opts);
	}
}