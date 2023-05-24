
const { expect, assert } = require('chai');
const App = require('./app');

contract('DAO', ([from]) => {
	let app,dao;
	before(async () => {
		app = await App.create();
		dao = await app.getDAO();
	});

	//console.log('DAO from', from);

	context('Settings', () => {
		it('setDescription()', async()=>{
			await dao.setDescription('DAO Description')
		})
		it('setOperator()', async()=>{
			await dao.setOperator(from)
		})
		it('setMission()', async()=>{
			await dao.setMission('DAO Mission')
		})
		it('setMissionAndDesc()', async()=>{
			await dao.setMissionAndDesc('DAO Mission 1', 'DAO Description 1')
		})
	});

	context('Reads', () => {
		it('impl()', async()=>{
			//console.log(await dao.impl());
			//onsole.log((await app.DAOs.defaultIMPLs()).DAO);
			assert(await dao.impl() == (await app.DAOs.defaultIMPLs()).DAO)
		})
		it('operator()', async () => {
			assert(await dao.operator()==from)
		})
		it('description()', async () => {
			assert(await dao.description() == 'DAO Description 1')
		})
		it('root()', async () => {
			assert(await dao.root() != '0x0000000000000000000000000000000000000000');
		})
		it('name()', async () => {
			assert((await dao.name()).indexOf('Test_Asset_Sales_DAO_') == 0);
		})
		it('mission()', async () => {
			assert(await dao.mission() == 'DAO Mission 1');
		})
		it('member()', async () => {
			assert(await dao.member() != '0x0000000000000000000000000000000000000000');
		})
		it('ledger()', async () => {
			assert(await dao.ledger() != '0x0000000000000000000000000000000000000000');
		})
		it('asset()', async () => {
			assert(await dao.asset() != '0x0000000000000000000000000000000000000000');
		})
		it('module()', async () => {
			assert(await dao.module(3) == await dao.asset());
			assert(await dao.module(6) == '0x0000000000000000000000000000000000000000');
		})
	});

});