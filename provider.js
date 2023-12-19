
const somes = require('somes').default;
const buffer = require('somes/buffer').default;
const req = require('somes/request');
const aes = require('crypto-tx/aes');
const gas = require('./gas');
const HDWalletProvider = require('@truffle/hdwallet-provider');

try {
	var cfg = require('./.config');
} catch { var cfg = {} }

somes.assert(cfg.walletKeys[0], 'config.walletKeys[0] not empty');
somes.assert(cfg.walletKeys[1], 'config.walletKeys[1] not empty');

const walletKeys = cfg.blur ?
	cfg.walletKeys.map(e=>
		aes.aes256cbcDecrypt(Buffer.from(e, 'base64'), cfg.blur).plaintext_hex.slice(2)
	): cfg.walletKeys;

class ProviderBase {
	constructor(url) {
		this.url = url;
		this.matic_eth_gasPrice = '';
	}
	send(payload, callback) {
		this.request(payload).then(e=>
			callback(null, e)
		).catch(
			callback
		);
	}
	sendAsync(payload, callback) {
		this.request(payload).then(e=>
			callback(null, e)
		).catch(
			callback
		);
	}
	async request(payload) {
		let retry = 10;
		// console.log(payload, this.url);

		while(1) {
			let matic_gas = payload.method == 'eth_gasPrice' && this.host.chainId == 137;
			let warp = (result)=>({ id: payload.id, jsonrpc: payload.jsonrpc, result });
			try {
				if (matic_gas) { // matic get gasPrice
					let gasPrice = await gas.matic(1,1);
					this.matic_eth_gasPrice = '0x' + gasPrice.toString(16);
					// console.log('matic eth_gasPrice', gasPrice);
					return warp(this.matic_eth_gasPrice);
				}

				let r;
				if (cfg.shsProxy) {
					r = await req.request(`${cfg.shsProxy}?pathname=${buffer.from(this.url).toString('base58')}`, {
						params: payload, method: 'POST', dataType: 'json' 
					});
				} else {
					r = await req.request(this.url, { params: payload, method: 'POST', dataType: 'json', proxy: cfg.proxy });
				}

				let data = JSON.parse(r.data.toString('utf-8'));

				// if (data.error) debugger;
				// console.log(payload, data);
				return data;
			} catch (err) {
				if (retry--) {
					// console.warn(`   --- retry rpc request ${retry}`, err.message);
				} else {
					if (matic_gas && this.matic_eth_gasPrice) {
						return warp(this.matic_eth_gasPrice);
					}
					throw err;
				}
			}
		} // end while(1)
	}
}

class Provider extends HDWalletProvider {
	constructor(provider) {
		let base = new ProviderBase(provider);
		super({ privateKeys: walletKeys, provider: base, pollingInterval: 5e3 });
		base.host = this;
	}
}

exports.Provider = Provider;