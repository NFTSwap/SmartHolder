
const { expect, assert } = require("chai");
const { createApp } = require("./app");
const cryptoTx = require('crypto-tx');
const DAO = artifacts.require("DAO.sol");

contract('SmartHolder All', (accounts) => {
	var app;
	var users = [
		'0x90f15922028B0fA3C5eA37B6351E5CD4fb8F9957', // unlock account
		'0xddcf547a221f813918ad0853f305e15881e54c94',
		'0x667bc23f2177db5dddac0ee8d7f208d27819bc1d',
		'0xd152ddd70de37703307e9b1dcde3d16a632347b3',
	];
	var web3 = DAO.interfaceAdapter.web3;
	var user = users[0];
	var tokenId = '0x' + cryptoTx.genPrivateKey().toString('hex');
	// var tokenId = '0xfff96262b7ebdad7ac58a0e882910c5c489ffa2588ed11a92182d1c13727a9a4';

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
			assert(user == await app.asset.ownerOf(tokenId));
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
			await app.assetGlobal.methods['safeTransferFrom(address,address,uint256)'](users[0], users[1], tokenId);
			assert(app.asset.ownerOf(tokenId)==users[1], 'app.asset.ownerOf(tokenId)==users[1]');
		});

		it("safeTransferFrom to account 0", async () => {
			await app.assetGlobal.methods['safeTransferFrom(address,address,uint256)'](users[1], users[0], tokenId);
			assert(app.asset.ownerOf(tokenId)==users[0], 'app.asset.ownerOf(tokenId)==users[1]');
		});

		it("unlock", async () => {
			await app.assetGlobal.unlock(app.asset.address, tokenId, '0x');
		});
	});

	context("Member", () => {
		it('create2 0', async () => {
			if ((await app.member.ownerOf('0x1')).toLowerCase() != users[0].toLowerCase()) {
				await app.member.create2(users[0], '0x1', 1, 'Test1', 'Test1', 'None');
				assert(await app.member.ownerOf('0x1') == users[0], 'app.member.ownerOf()');
			}
		});
		it('create2 1', async () => {
			if ((await app.member.ownerOf('0x2')).toLowerCase() != users[1].toLowerCase()) {
				await app.member.create2(users[1], '0x2', 1, 'Test1', 'Test1', 'None');
				assert(await app.member.ownerOf('0x2') == users[1], 'app.member.ownerOf()');
			}
		});
		it('create2 2', async () => {
			if ((await app.member.ownerOf('0x3')).toLowerCase() != users[2].toLowerCase()) {
				await app.member.create2(users[2], '0x3', 2, 'Test1', 'Test1', 'None');
				assert(await app.member.ownerOf('0x3') == users[2], 'app.member.ownerOf()');
			}
		});
	});

	context("Ledger", () => {
		it('deposit', async () => {
			var balance = BigInt(await app.ledger.getBalance());
			await app.ledger.deposit('Test', 'Test', { value: 20000 });
			var newBalance = BigInt(await app.ledger.getBalance());
			assert(newBalance == balance + 20000n, 'newBalance == balance + 10000n');
		});
		it('withdraw', async () => {
			var balance = BigInt(await app.ledger.getBalance());
			await app.ledger.withdraw(5000, 'Test', 'Test');
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
				await app.votePool.vote(id, '0x1', 1, {from: users[0]});
		});
		it('vote 2', async()=>{
			await app.votePool.vote(id, '0x2', 1, {from: users[1]});
		});
		it('vote 3', async()=>{
			await app.votePool.vote(id, '0x3', 1, {from: users[2]});
		});
		it('execute', async()=>{
			await app.votePool.execute(id);
			assert(app.dao.operator() == app.votePool.address, 'app.dao.operator() == app.votePool.address');
		});
	});

});