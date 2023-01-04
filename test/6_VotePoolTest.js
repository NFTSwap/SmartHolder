
const { assert } = require('chai');
const cryptoTx = require('crypto-tx');
const App = require('./app');
const VotePool = artifacts.require('VotePool.sol');

contract('VotePool', () => {
	let app, DAO, vp;
	before(async () =>{
		app = await App.create();
		DAO = await app.getDAO();
		vp = await VotePool.at(await DAO.root());
	});
	let id = '0x' + cryptoTx.getRandomValues(32).toString('hex');

	context('Setting', () => {

		it('create2()', async () => {
			var data = web3.eth.abi.encodeFunctionCall(DAO.abi.find(e=>e.name=='setDescription'), ['DAO Description vote 2']);
			await vp.create2(id, [DAO.address], 0, 5001, 0, 0, 'Test pr', 'Test pr desc', 0, [data]);
			assert(await vp.exists(id), 'vp.exists(id)');
		});

		// votes total = 6
		it('vote() 1', async () => {
			await vp.vote(id, 1, 2, true);
		});

		it('vote() 2', async () => {
			await vp.vote(id, 2, 2, true);
			assert(await DAO.description() == 'DAO Description vote 2', 'DAO.description() == DAO Description vote 2');
		});

	});

	context('Gettings', () => {

		it('description()', async () => {
			assert(await vp.description() == 'VotePool description');
		});

		it('getProposal()', async () => {
			let pr = await vp.getProposal(id);
			assert(pr.name == 'Test pr', 'pr.name == Test pr');
			assert(pr.isExecuted, 'pr.isExecuted');
		});
	});

});