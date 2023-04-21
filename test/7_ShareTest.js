
const { assert } = require('chai');
const App = require('./app');
const Ledger = artifacts.require('Ledger.sol');
const Share = artifacts.require('Share.sol');

contract('Share', ([from,to]) => {
	let app, dao, share, ledger;
	before(async () =>{
		app = await App.create();
		dao = await app.getDAO();
		ledger = await Ledger.at(await dao.ledger());
	});

	context('Setting', () => {

		// function enableShare(uint256 totalSupply, uint256 maxSupply, string calldata symbol)
		it('enableShare()', async () => {
			assert(await dao.share() == '0x0000000000000000000000000000000000000000');
			await dao.enableShare(10000000, 20000000, await dao.name());
			share = await Share.at(await dao.share());
			assert(await share.address != '0x0000000000000000000000000000000000000000');
		});

		it('mint()', async () => {
			await share.mint(to, 100000);
			assert(BigInt(await share.balanceOf(to) + '') == 100000n);
		});

		it('VotePool.deposit()', async () => {
			let balance = BigInt(await ledger.getBalance() + '');
			await ledger.deposit('Test Share Deposit', 'Test Share Deposit Desc', { value: '10000000000000000' /*0.01*/ });
			assert(BigInt(await ledger.getBalance() + '') == balance + 10000000000000000n);
		});

		it('VotePool.release()', async () => {
			await ledger.release('10000000000000000', 'Test Share Release');
		});

	});

});