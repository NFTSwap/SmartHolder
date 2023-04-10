
const somes = require('somes').default;
const buffer = require('somes/buffer').default;
const { assert } = require('chai');
const App = require('./app');
const DAO = artifacts.require("DAO.sol");

contract('DAOs', ([from]) => {
	let app;
	before(async () => app = await App.create());

	//console.log('DAOs from', from);

	context('Deploy', ()=>{

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
				image: `https://smart-dao-home-rel.stars-mine.com/assets/logo.c5133168.png`,
				extend: '0x' + buffer.from('{"poster": "https://img-blog.csdnimg.cn/20200502175449751.png"}').toString('hex'),
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
						image: 'https://picx.zhimg.com/v2-72e9fd76f8d5b941acb976826ff2ba90_l.jpg?source=32738c0c',
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
				image: `https://smart-dao-home-rel.stars-mine.com/assets/logo.c5133168.png`,
				extend: '0x' + buffer.from('{"poster": "https://img-blog.csdnimg.cn/20200502175449751.png"}').toString('hex'),
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
						image: 'https://picx.zhimg.com/v2-72e9fd76f8d5b941acb976826ff2ba90_l.jpg?source=32738c0c',
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
				image: 'https://smart-dao-home-rel.stars-mine.com/assets/logo.c5133168.png',
				external_link: 'https://smart-dao-home-rel.stars-mine.com/',
				seller_fee_basis_points_first: 3000, // 30%
				seller_fee_basis_points_second: 1000, // 10%
				fee_recipient: '0x0000000000000000000000000000000000000000', // auto set
				contractURIPrefix: 'https://smart-dao-rel.stars-mine.com/service-api/utils/printJSON',
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