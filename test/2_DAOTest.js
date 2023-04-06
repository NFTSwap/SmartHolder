
const { expect, assert } = require('chai');
const App = require('./app');

contract('DAO', ([from]) => {
	let app;
	before(async () => app = await App.create());

	//console.log('DAO from', from);

	context('Settings', () => {
		it('setDescription()', async()=>{
			await app.DAO.setDescription('DAO Description')
		})
		it('setOperator()', async()=>{
			await app.DAO.setOperator(from)
		})
		it('setMission()', async()=>{
			await app.DAO.setMission('DAO Mission')
		})
		it('setMissionAndDesc()', async()=>{
			await app.DAO.setMissionAndDesc('DAO Mission 1', 'DAO Description 1')
		})
		it('setModule()', async()=>{
			await app.DAO.setModule(4, await app.DAO.module(4))
		})
	});

	context('Reads', () => {
		it('impl()', async()=>{
			//console.log(await app.DAO.impl());
			//onsole.log((await app.DAOs.defaultIMPLs()).DAO);
			assert(await app.DAO.impl() == (await app.DAOs.defaultIMPLs()).DAO)
		})
		it('operator()', async () => {
			assert(await app.DAO.operator()==from)
		})
		it('description()', async () => {
			assert(await app.DAO.description() == 'DAO Description 1')
		})
		it('root()', async () => {
			assert(await app.DAO.root() != '0x0000000000000000000000000000000000000000');
		})
		it('name()', async () => {
			assert((await app.DAO.name()).indexOf('Test_Asset_Sales_DAO_') == 0);
		})
		it('mission()', async () => {
			assert(await app.DAO.mission() == 'DAO Mission 1');
		})
		it('member()', async () => {
			assert(await app.DAO.member() != '0x0000000000000000000000000000000000000000');
		})
		it('ledger()', async () => {
			assert(await app.DAO.ledger() != '0x0000000000000000000000000000000000000000');
		})
		it('asset()', async () => {
			assert(await app.DAO.asset() != '0x0000000000000000000000000000000000000000');
		})
		it('module()', async () => {
			assert(await app.DAO.module(3) == await app.DAO.asset());
			assert(await app.DAO.module(6) == '0x0000000000000000000000000000000000000000');
		})
	});

});