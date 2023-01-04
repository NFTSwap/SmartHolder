
const { expect } = require('chai');
const App = require('./app');
const Ledger = artifacts.require('Ledger.sol');

contract('Ledger', ([from]) => {
	let app, DAO, ledger;
	before(async () =>{
		app = await App.create();
		DAO = await app.getDAO();
		ledger = await Ledger.at(await DAO.ledger());
	});

	context('Settings', () => {

		it('receive()', async () => {
			await web3.eth.sendTransaction({ from, to: ledger.address, value: '10000000000000000' }); // 0.01 eth
			expect(await ledger.getBalance()).to.bignumber.equal('10000000000000000');
		});

		it('assetIncome()', async () => {
			let token = await DAO.asset();
			await ledger.assetIncome(token, 1, from, from, '10000000000000000', 1, { value: '10000000000000000' });
			expect(await ledger.getBalance()).to.bignumber.equal('20000000000000000');
		});

		it('deposit()', async () => {
			await ledger.deposit('Test Deposit', 'Test Deposit Desc', { value: '10000000000000000' });
			expect(await ledger.getBalance()).to.bignumber.equal('30000000000000000');
		});

		it('withdraw()', async () => {
			await ledger.withdraw('10000000000000000', from, 'Test Withdraw');
			expect(await ledger.getBalance()).to.bignumber.equal('20000000000000000');
		});

		it('release()', async () => {
			await ledger.release('20000000000000000', 'Test Release');
		});

	});

	context('Gettings', () => {

		it('getBalance()', async () => {
			let balance = await ledger.getBalance();
			//console.log('   balance = ', balance);
			expect(balance).to.bignumber.lessThan('10000');
		});

	});

});