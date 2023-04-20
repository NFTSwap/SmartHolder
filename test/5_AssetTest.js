
const { expect, assert } = require('chai');
const App = require('./app');
const Asset = artifacts.require('Asset.sol');
const AssetShell = artifacts.require('AssetShell.sol');

contract('Asset', ([from,to]) => {
	let app,DAO,asset,first,second, id;
	before(async () => {
		app = await App.create();
		DAO = await app.getDAO();
		asset = await Asset.at(await app.DAO.asset());
		first = await AssetShell.at(await app.DAO.module(4));
		second = await AssetShell.at(await app.DAO.module(5));
	});

	context('Settings', () => {

		it("safeMint()", async () => {
			await asset.safeMint(
				first.address, // lock to asset shell
				0, // tokenId
				'https://testnets-api.opensea.io/api/v1/metadata/\
0xf4910c763ed4e47a585e2d34baa9a4b611ae448c/0x83b6cb4e2482ce9786498d071d6fe63061de853c000000000000010000000032',
				// (to,price) = abi.decode(data, (address, uint256));
				web3.eth.abi.encodeParameters(['address','uint256'], [from, '10000000000000000'/*min price 0.01 eth*/]),
			);
			id = '0x' + (await first.convertTokenID(asset.address, 0)).toString('hex');
		});

		it('makeNFT()', async () => {
			// function makeNFT(address to, uint256 id, string memory _tokenURI, uint256 minPrice)
			await asset.makeNFT(
				from,
				//first.address, // lock to asset shell
				2, // tokenId
				'https://api.opensea.io/api/v1/metadata/\
0x495f947276749ce646f68ac8c248420045cb7b5e/98992976673362451468029657158147997262089202412746295675220817174765200474113',
				'10000000000000000'/*min price 0.01 eth*/
			);
		});

		it('withdraw()', async () => {
			let id = await first.convertTokenID(asset.address, 2);
			await first.withdraw(id, from, 2);
			// assert(!await first.exists(id));
			assert(await first.balanceOf(id, from) == 0);
		});

	});

	context('Gettings', () => {

		it('balanceOf()', async () => {
			assert(await first.balanceOf(from, id) == 1);
		});

		it('minimumPrice()', async () => {
			expect(await first.minimumPrice(id)).to.bignumber.equal('10000000000000000');
		});

		it('assetMeta()', async () => {
			let meta = await first.assetMeta(id);
			assert(meta.token == asset.address);
			assert(meta.tokenId == 0);
		});

	});

	context('Transfer', () => {

		it('safeTransferFrom()', async () => {
			await first.methods.safeTransferFrom(from, to, id, 1, "");
		});

		it('lockedOf()', async () => {
			let {amount} = await first.lockedOf(id, to);
			assert(amount == 1);
		});

		it('unlock()', async () => {
			await first.unlock({tokenId:id,owner:to,previousOwner:from}, { value: 10000000000000001 * 0.3 });
		});

		it('exists()', async () => {
			assert(!await first.exists(id));
			assert(await second.exists(id));
		});

		it('safeTransferFrom()', async () => {
			// transfer and unlock
			await second.methods.safeTransferFrom(to, from, id, 1, "", {from: to});
		});

		it('unlock() 2', async () => {
			await second.unlock({tokenId:id,owner:from,previousOwner:to}, { value: 10000000000000001 * 0.1 });
		});

		it('lockedOf()', async () => {
			let {amount} = await second.lockedOf(id, from);
			assert(amount == 0);
		});
	});

});