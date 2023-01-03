
const { expect, assert } = require("chai");
const App = require("./util");
const cryptoTx = require('crypto-tx');
const DAO = artifacts.require("DAO.sol");
// const Asset = artifacts.require("Asset.sol");

contract('Asset', (accounts) => {
	let DAOs;

	before(async () => {
		DAOs = await App.create();
	});

	context("A", () => {
		it("A1", async () => {
			// await app.asset.safeMint(user, tokenId,
			// 	'https://nftmvp-img.stars-mine.com/EDbzQFCnP4uhXs4DeSsRN1JdftDCH1CnBJ6eBRuk1iJU.gif',
			// 	'0x0000000000000000000000000000000000000000', // lock
			// 	'0x', // _data
			// );
			// assert(user == (await app.asset.ownerOf(tokenId)).toLowerCase());
		});
		it("A2", async () => {
			//await app.asset.setTokenURI(tokenId, 'https://mvp-img.stars-mine.com/3HemwVuQuseF2XUC7Jxbo5VBJwDHMKcMFSrrH1F1yh1a.png');
			// console.log(await app.asset.tokenURI(tokenId));
		});
	});

});