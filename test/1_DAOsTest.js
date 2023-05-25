
const somes = require('somes').default;
const buffer = require('somes/buffer').default;
const { assert } = require('chai');
const cryptoTx = require('crypto-tx');
const App = require('./app');
const DAO = artifacts.require("DAO.sol");
const VotePool = artifacts.require('VotePool.sol');

contract('DAOs', ([from]) => {
	let app;
	before(async () => app = await App.create());

	//console.log('DAOs from', from);

	context('Deploy', ()=>{

		// it('VotePool', async()=>{
		// 	let dao = await DAO.at('0x47c5e182b528eB7335972C1D6a69FccE308a2656');
		// 	var data = web3.eth.abi.encodeFunctionCall(dao.abi.find(e=>e.name=='setOperator'), ['0xA953f151bD011A7492A22e1Cea26C8F811d2A4dC']);
		// 	let vp = await VotePool.at(await dao.root());
		// 	var data2 = web3.eth.abi.encodeParameter(vp.abi.find(e=>e.name=='create').inputs[0], {
		// 		id: '0x' + cryptoTx.getRandomValues(32).toString('hex'),
		// 		name: 'setOperator', description: 'setOperator', origin: from,
		// 		originId: '0x5c927e6be76632ceba412ae9e26a433bd68183b109ec9692335f5371b828f81d',
		// 		target: ['0x47c5e182b528eB7335972C1D6a69FccE308a2656'], data: [data],
		// 		lifespan: 0, expiry: 0, passRate: 5001, loopCount: 0,
		// 		loopTime: 0, voteTotal: 0, agreeTotal: 0, executeTime: 0,
		// 		idx: 0, isAgree: false, isClose: false, isExecuted: false,
		// 	});
		// 	console.log('root.create', data2);
		// 	await vp.create2(
		// 		'0x' + cryptoTx.getRandomValues(32).toString('hex'), ['0x47c5e182b528eB7335972C1D6a69FccE308a2656'],
		// 		0, 5001, 0, 0,
		// 		'setOperator', 'setOperator to 0xA953f151bD011A7492A22e1Cea26C8F811d2A4dC',
		// 		'0x5c927e6be76632ceba412ae9e26a433bd68183b109ec9692335f5371b828f81d', [data]);
		// 	console.log('dao', dao.address);
		// 	console.log('dao.setOperator', data);
		// });

		it('deploy()', async()=>{
			if (1) return; // skip
			let name = `Test_${somes.random()}`;

			// string name;
			// string mission;
			// string description;
			// string image;

			await app.DAOs.deploy(
			{ // InitDAOArgs
				name, 
				mission: `${name} mission`,
				description: `${name} description`,
				image: `https://smart-dao-res.stars-mine.com/FtETTzirbnawlTEVb5x7qDcnVyRL`,
				extend: '0x' + buffer.from('{"poster": "https://smart-dao-res.stars-mine.com/FvCDcP23jHCCRbAJY_x3yK0c7vSx"}').toString('hex'),
				unlockOperator: app.DAOs.address,
			},
			from, // operator
			{ // InitMemberArgs
				name: 'Member',
				description: 'Member description',
				baseURI: 'https://smart-dao-rel.stars-mine.com/service-api/utils/printJSON',
				members: [{
					owner: from,
					info: {
						id: 0,
						name: 'Test',
						description: 'Test',
						image: 'https://avatars.githubusercontent.com/u/1221969?v=4',
						votes: 1,
					},
					permissions: [0xdc6b0b72, 0x678ea396],
				}],
				executor: 0,
			}, { //InitVotePoolArgs
				description: 'VotePool description',
				lifespan: 7 * 24 * 60 * 60, /*7 days*/
			});
			let dao = await app.DAOs.get(name);
			// console.log(`   ----------- deploy DAO Ok ${dao} -----------`);
			app.DAO0 = await DAO.at(dao);
		});

		it('deployAssetSalesDAO()', async ()=>{
			let name = `Test_Asset_Sales_DAO_${somes.random()}`;
			await app.DAOs.deployAssetSalesDAO(
			{ // InitDAOArgs
				name,
				mission: `${name} mission`,
				description: `${name} description`,
				image: `https://smart-dao-res.stars-mine.com/FtETTzirbnawlTEVb5x7qDcnVyRL`,
				extend: '0x' + buffer.from('{"poster": "https://smart-dao-res.stars-mine.com/FvCDcP23jHCCRbAJY_x3yK0c7vSx"}').toString('hex'),
				unlockOperator: app.DAOs.address,
			},
			from, // operator
			{ // InitMemberArgs
				name: 'Member',
				description: 'Member description',
				baseURI: 'https://smart-dao-rel.stars-mine.com/service-api/utils/printJSON',
				members: [{
					owner: from,
					info: {
						id: 0,
						name: 'Test',
						description: 'Test',
						image: 'https://avatars.githubusercontent.com/u/1221969?v=4',
						votes: 1,
					},
					permissions: [0xdc6b0b72, 0x678ea396],
				}],
				executor: 0,
			}, { //InitVotePoolArgs
				description: 'VotePool description',
				lifespan: 7 * 24 * 60 * 60, /*7 days*/
			}, { // InitLedgerArgs
				description: 'Ledger description',
			}, { // InitAssetArgs
				name: name, // string  name;
				description: 'Asset description',
				image: 'https://smart-dao-res.stars-mine.com/FvCDcP23jHCCRbAJY_x3yK0c7vSx',
				external_link: 'https://smart-dao-home-rel.stars-mine.com/',
				seller_fee_basis_points_first: 3000, // 30%
				seller_fee_basis_points_second: 1000, // 10%
				fee_recipient: '0x0000000000000000000000000000000000000000', // auto set
				base_contract_uri: 'https://smart-dao-rel.stars-mine.com/service-api/utils/printJSON',
				base_uri: '',
				enable_lock: true,
			});
	
			let addr = await app.DAOs.get(name);
			//console.log(`----------- deploy Asset Sales DAO Ok ${dao} -----------`);
			app.DAO = await DAO.at(addr);
		});

	});

	context('Reads', () => {

		it('length()', async () => {
			assert(await app.DAOs.length() != 0);
		});

		it('get()', async()=>{
			let addr = await app.DAOs.get(await app.DAO.name());
			expect(addr).equal(app.DAO.address);
		});

		it('DAO.extend()', async()=>{
			let extend = Buffer.from((await app.DAO.extend()).slice(2), 'hex');
			console.log(JSON.parse(extend));
		});

		// it('Each All DAOs', async () => {
		// 	for (let i = 0; i < await app.DAOs.length(); i++) {
		// 		let addr = await app.DAOs.at(i);
		// 		let dao = await DAO.at(addr);
		// 		assert(await dao.name() != '');
		// 	}
		// });

	});

});