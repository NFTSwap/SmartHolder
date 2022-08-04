
const { expect, assert } = require("chai");
const { createApp } = require("./app");
const cryptoTx = require('crypto-tx');
const DAO = artifacts.require("DAO.sol");

contract('SmartHolder All', (accounts) => {
	var app;
	var users = [
		'0x90f15922028B0fA3C5eA37B6351E5CD4fb8F9957'.toLowerCase(), // unlock account
		'0xddcf547a221f813918ad0853f305e15881e54c94'.toLowerCase(),
		'0x667bc23f2177db5dddac0ee8d7f208d27819bc1d'.toLowerCase(),
		'0xd152ddd70de37703307e9b1dcde3d16a632347b3'.toLowerCase(),
	];
	var web3 = DAO.interfaceAdapter.web3;
	var user = users[0];
	var tokenId = '0x' + cryptoTx.genPrivateKey().toString('hex');
	// var tokenId = '0x1cf8ee266012053335fbfec23b8afbff37d61b0558ad301598b4afe9f27cdf9f';
	console.log(tokenId);
	var mid1 = '0x1cf8ee266012053335fbfec23b8afbff37d61b0558ad301598b4afe9f27cdf90';
	var mid2 = '0x1cf8ee266012053335fbfec23b8afbff37d61b0558ad301598b4afe9f27cdf91';
	var mid3 = '0x1cf8ee266012053335fbfec23b8afbff37d61b0558ad301598b4afe9f27cdf92';

	before(async () => {
		app = await createApp(users[0]);
	});

	context("ETH", () => {
		it("account", async () => {
			for (var to of users.slice(1)) {
				if (await web3.eth.getBalance(to) == '0') {
					await web3.eth.sendTransaction({ from: users[0], to, value: '1000000000000000000' });
					// expect(await web3.eth.getBalance(to)).to.bignumber.equal(BigInt(balance).add(unlocked), "expect balance+=unlocked");
				}
			}
		});
	});

	context("Asset", () => {
		it("safeMint", async () => {
			await app.asset.safeMint(user, tokenId,
				'https://nftmvp-img.stars-mine.com/EDbzQFCnP4uhXs4DeSsRN1JdftDCH1CnBJ6eBRuk1iJU.gif',
				'0x0000000000000000000000000000000000000000', // lock
				'0x', // _data
			);
			assert(user == (await app.asset.ownerOf(tokenId)).toLowerCase());
		});
		it("setTokenURI", async () => {
			await app.asset.setTokenURI(tokenId, 'https://mvp-img.stars-mine.com/3HemwVuQuseF2XUC7Jxbo5VBJwDHMKcMFSrrH1F1yh1a.png');
			// console.log(await app.asset.tokenURI(tokenId));
		});
	});

	context("AssetGlobal", () => {
		it("lock", async () => {
			await app.asset.lock(app.assetGlobal.address, tokenId, '0x');
		});
		it("safeTransferFrom to account 1", async () => {
			var id = await app.assetGlobal.convertTokenID(app.asset.address, tokenId);
			await app.assetGlobal.methods['safeTransferFrom(address,address,uint256)'](users[0], users[1], id, {from: users[0]});
			assert(await app.asset.ownerOf(tokenId)==users[1], 'await app.asset.ownerOf(tokenId)==users[1]');
		});
		it("safeTransferFrom to account 0", async () => {
			var id = await app.assetGlobal.convertTokenID(app.asset.address, tokenId);
			await app.assetGlobal.methods['safeTransferFrom(address,address,uint256)'](users[1], users[0], id, {from: users[1]});
			assert(await app.asset.ownerOf(tokenId)==users[0], 'await app.asset.ownerOf(tokenId)==users[1]');
		});
		it("unlock", async () => {
			await app.assetGlobal.unlock(app.asset.address, tokenId);
		});
	});

	context("Member", () => {
		it('create2 0', async () => {
			if (!await app.member.exists(mid1)) {
				await app.member.create2(users[0], mid1, 1, 'Test1', '', '');
				assert((await app.member.ownerOf(mid1)).toLowerCase() == users[0], 'app.member.ownerOf()');
			}
		});
		it('create2 1', async () => {
			if (!await app.member.exists(mid2)) {
				await app.member.create2(users[1], mid2, 1, 'Test1', '', '');
				assert((await app.member.ownerOf(mid2)).toLowerCase() == users[1], 'app.member.ownerOf()');
			}
		});
		it('create2 2', async () => {
			if (!await app.member.exists(mid3)) {
				await app.member.create2(users[2], mid3, 2, 'Test1', '', '');
				assert((await app.member.ownerOf(mid3)).toLowerCase() == users[2], 'app.member.ownerOf()');
			}
		});
	});

	context("Ledger", () => {
		it('deposit', async () => {
			var balance = BigInt(await app.ledger.getBalance());
			await app.ledger.deposit('Test', 'Test', { value: 20000 });
			var newBalance = BigInt(await app.ledger.getBalance());
			assert(newBalance == balance + 20000n, 'newBalance == balance + 20000n');
		});
		it('withdraw', async () => {
			var balance = BigInt(await app.ledger.getBalance());
			await app.ledger.withdraw(5000, user, 'Test');
			var newBalance = BigInt(await app.ledger.getBalance());
			assert(newBalance == balance - 5000n, 'newBalance == balance - 5000n');
		});
		it('release', async () => {
			var user0 = BigInt(await web3.eth.getBalance(users[0]));
			var balance = BigInt(await app.ledger.getBalance());
			await app.ledger.release(15000, 'release Test');
			var newBalance = BigInt(await app.ledger.getBalance());
			assert(newBalance == balance - 15000n, 'newBalance == balance - 15000n');
			assert(user0 < BigInt(await web3.eth.getBalance(users[0])), 'user0 < BigInt(await web3.eth.getBalance(users[0]))');
		});
	});

	context("VotePool", () => {
		var id = '0x' + cryptoTx.genPrivateKey().toString('hex');
		it('create2', async()=>{
			var data = web3.eth.abi.encodeFunctionCall(app.dao.abi.find(e=>e.name=='setOperator'), [app.votePool.address]);
			await app.votePool.create2(id, app.dao.address, 1000, 5001, 5001, 0, 0, 'dao.setOperator', '', data);
		});
		it('vote 1', async()=>{
				await app.votePool.vote(id, mid1, 1, {from: users[0]});
		});
		it('vote 2', async()=>{
			await app.votePool.vote(id, mid2, 1, {from: users[1]});
		});
		it('vote 3', async()=>{
			await app.votePool.vote(id, mid3, 1, {from: users[2]});
		});
		it('execute', async()=>{
			await app.votePool.execute(id);
			assert((await app.dao.operator()).toLowerCase() == app.votePool.address.toLowerCase(), 'app.dao.operator() == app.votePool.address');
		});
	});

});