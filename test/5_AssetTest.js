
const { expect, assert } = require('chai');
const App = require('./app');
const Asset = artifacts.require('Asset.sol');
const AssetShell = artifacts.require('AssetShell.sol');

contract('Asset', ([from,to]) => {
	let app,dao,asset,first,second, id;
	before(async () => {
		app = await App.create();
		dao = await app.getDAO();
		asset = await Asset.at(await dao.asset());
		first = await AssetShell.at(await dao.module(4));
		second = await AssetShell.at(await dao.module(5));
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
			//console.log('safeMint() first', (await asset.balanceOf(first.address, 0)).toNumber(), (await asset.totalSupply(0)).toNumber());
			//console.log('safeMint() second', (await asset.balanceOf(second.address, 0)).toNumber());
			id = '0x' + (await first.convertTokenID(asset.address, 0)).toString('hex');
		});

		// function makeNFT(address to, uint256 id, string memory _tokenURI, uint256 minPrice)
		it('makeNFT()', async () => {
			await asset.makeNFT(
				from,
				2, // tokenId
				'https://api.opensea.io/api/v1/metadata/\
0x495f947276749ce646f68ac8c248420045cb7b5e/98992976673362451468029657158147997262089202412746295675220817174765200474113',
				'10000000000000000'/*min price 0.01 eth*/
			);
		});

		// function copyNFTs(address to, uint256 id, uint256 amount, uint256 minPrice)
		it('copyNFTs()', async () => {
			await asset.copyNFTs(
				from,
				2, // tokenId
				1000,
				'1000000000000000'/*min price 0.001 eth*/
			);
			let id = '0x' + (await first.convertTokenID(asset.address, 3)).toString('hex');
			assert((await second.balanceOf(from, id)).toNumber() == 1000);
		});

		it('withdraw()', async () => {
			let id = '0x' + (await first.convertTokenID(asset.address, 2)).toString('hex');
			//console.log('balanceOf()', id);
			//console.log('balanceOf(from, id)', first.address, (await first.balanceOf(from, id)).toNumber(),id);
			// function withdraw(uint256 tokenId, address owner, uint256 amount)
			await first.withdraw(id, from, 1);
			// assert(!await first.exists(id));
			//console.log('balanceOf(from, id) 1', (await first.balanceOf(from, id)).toNumber());
			assert((await first.balanceOf(from, id)).toNumber() == 0);
		});

		it('withdraw() NFTs 1155', async () => {
			let id = '0x' + (await second.convertTokenID(asset.address, 3)).toString('hex');
			await second.withdraw(id, from, 9);
			assert((await second.balanceOf(from, id)).toNumber() == 1000-9);
		});

	});

	context('Gettings', () => {

		it('balanceOf()', async () => {
			//console.log('balanceOf()', (await first.balanceOf(to, id)).toNumber(), to);
			assert((await first.balanceOf(from, id)).toNumber() == 1);
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
			console.log('safeTransferFrom()', id);
			await first.safeTransferFrom(from, to, id, 1, "0x");
		});

		it('lockedItems()', async () => {
			let items = await first.lockedItems(id, to);
			//console.log('lockedItems() amount', items.total.toNumber(), of.items.toNumber())
			assert(items.total.toNumber() == 1);
		});

		it('unlock()', async () => {
			await first.unlock({tokenId:id,from,to}, { value: 10000000000000001 * 0.5 });
		});

		it('exists()', async () => {
			assert(!await first.exists(id));
			assert(await second.exists(id));
		});

		it('safeTransferFrom()', async () => {
			// transfer and unlock
			await second.safeTransferFrom(to, from, id, 1, "0x", {from: to});
		});

		it('unlock() 2', async () => {
			await second.unlock({tokenId:id,from:to,to:from}, { value: 10000000000000001 * 0.1 });
		});

		it('lockedItems()', async () => {
			let {total} = await second.lockedItems(id, from);
			assert(total == 0);
		});
	});

});