
const fs = require('fs');
const { getDeployData } = require('@openzeppelin/truffle-upgrades/dist/utils/deploy-impl');

function pushDefine(type, label, defines, indent) {
	if (label)
		defines.push(Array.from({length:indent}).join('	') + `${type} ${label};`);
	else
		defines.push(type);
}

function joinLayoutItem(types, label, typename, defines, structs, indent) {
	let type = types[typename];
	let type_label = type.label;
	let mat, def;

	if (mat = typename.match(/^t_mapping\((.+?),(.+)\)$/)) { // mapping
		// mapping(address => mapping(address => bool))
		// t_mapping(t_address,t_struct(UintSet)5688_storage):
		let defines_key = [], defines_value = [];
		joinLayoutItem(types, '', mat[1], defines_key, structs, indent);
		joinLayoutItem(types, '', mat[2], defines_value, structs, indent);
		def = `mapping(${defines_key.join('')} => ${defines_value.join('')})`;
	}
	else if (mat = typename.match(/^t_array\((.+)\)/)) { // array
		// t_array(t_struct(MapEntry)4941_storage)dyn_storage
		let defines_arr = [];
		joinLayoutItem(types, '', mat[1], defines_arr, structs, indent);
		def = `${defines_arr.join('')}[]`
	}
	else if (type_label.substring(0,9) == 'contract ') {
		def = `address`;
	}
	else if (type_label.substring(0,7) == 'struct ') {
		var structName = type_label.substring(7).replace('.', '_');
		var structStr = `struct ${structName} {\n`;
		var defines_child = [];
		joinLayout(types, type.members, defines_child, structs, indent);
		structStr += defines_child.join('\n');
		structStr += '\n}';
		structs[structName] = structStr;
		def = structName;
	}
	else if (type_label.substring(0, 5) == 'enum ') {
		var enumName = type_label.substring(5).replace('.', '_');
		var enumStr = `enum ${enumName} {\n ${type.members.join(',')} \n}`;
		structs[enumName] = enumStr;
		def = enumName;
	}
	else {
		def = type_label;
	}

	pushDefine(def, label, defines, indent);
}

function joinLayout(types, storage, defines, structs, indent) {
	for (let {label,type} of storage) {
		joinLayoutItem(types, label, type, defines, structs, indent + 1);
	}
}

async function genProxy(name, Contract, opts) {
	var data = await getDeployData(opts, Contract);
	var templ = fs.readFileSync(`${__dirname}/../contracts/Upgrade.sol`, 'utf-8');
	var defines = [];
	var structs = {};
	joinLayout(data.layout.types, data.layout.storage, defines, structs, 1);
	templ = templ.replaceAll('Upgrade', `${name}Store`);
	templ = templ.replace('ContextProxy', `ContextProxy${name}`);

	var structsStr = '';
	for (let [k,v] of Object.entries(structs)) {
		structsStr += v + '\n';
	}

	templ = templ.replace(/address\s+internal\s+_impl;/, structsStr + '\n' + defines.join('\n'));
	fs.writeFileSync(`${__dirname}/../contracts/ContextProxy${name}.sol`, templ);
}

module.exports = async function(deployer) {
	var opts = { deployer };

	const DAO = artifacts.require("DAO.sol");
	const Asset = artifacts.require("Asset.sol");
	const AssetGlobal = artifacts.require("AssetGlobal.sol");
	const Ledger = artifacts.require("Ledger.sol");
	const Member = artifacts.require("Member.sol");

	await genProxy('DAO', DAO, opts);
	await genProxy('Asset', Asset, opts);
	await genProxy('AssetGlobal', AssetGlobal, opts);
	await genProxy('Ledger', Ledger, opts);
	await genProxy('Member', Member, opts);
}