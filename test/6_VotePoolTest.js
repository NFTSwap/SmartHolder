
const { assert } = require('chai');
const cryptoTx = require('crypto-tx');
const App = require('./app');
const VotePool = artifacts.require('VotePool.sol');
const Member = artifacts.require('Member.sol');

contract('VotePool', ([_,owner]) => {
	let app, dao, vp, member;
	before(async () =>{
		app = await App.create();
		dao = await app.getDAO();
		vp = await VotePool.at(await dao.root());
		member = await Member.at(await dao.member());
	});
	let id = '0x' + cryptoTx.getRandomValues(32).toString('hex');

	context('Setting', () => {

		it('create2()', async () => {
			console.log('DAO address', dao.address);
			console.log('VotePool vite id', id);
	
			var data = web3.eth.abi.encodeFunctionCall(dao.abi.find(e=>e.name=='setDescription'), ['DAO Description vote 4']);
			await vp.create2(id, [dao.address], 0, 5001, 0, 0, 'Test pr', 'Test pr desc', 0, [data]);
			assert(await vp.exists(id), 'vp.exists(id)');
		});

		// votes total = 6
		// function vote(uint256 id, uint256 member, int256 votes, bool tryExecute)
		it('vote() 1', async () => {
			await vp.vote(id, 1, 2, true);
		});

		it('vote() 2', async () => {
			await vp.vote(id, 2, 2, true);
			//console.log(await vp.getProposal(id));
			assert(await dao.description() == 'DAO Description vote 4', 'DAO.description() == DAO Description vote 4');
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

	context('Test votes of member request join action', () => {
		let p2;

		it('Member.requestJoin()', async () => {
			await member.requestJoin(owner, {
				id: 4, name: 'Test join', description: 'Test', image: 'https://avatars.githubusercontent.com/u/1221969?v=4', votes: 1,
			}, [0xdc6b0b72, 0x678ea396]);
			p2 = await vp.indexAt(await vp.total() - 1);
			assert(p2.target[0] == member.address, 'pro.target[0] == member.address');
		});

		// votes total = 6
		it('vote() request join 1', async () => {
			await vp.vote(p2.id, 1, 2, true);
		});

		it('vote() request join 2', async () => {
			await vp.vote(p2.id, 2, 2, true);
		});

		it('Member.getMemberInfo(4)', async () => {
			let info = await member.getMemberInfo(4);
			assert(info.name == 'Test join', 'info.name == Test join');
		});

	});

});