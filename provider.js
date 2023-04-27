
const somes = require('somes').default;
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
		this.request(payload).then(e=>callback(null, e)).catch(callback);
	}
	sendAsync(payload, callback) {
		this.request(payload).then(e=>callback(null, e)).catch(callback);
	}
	async request(payload) {
		let retry = 3;
		while(1) {
			let matic_gas = payload.method == 'eth_gasPrice' && this.host.chainId == 137;
			let warp = (result)=>({ id: payload.id, jsonrpc: payload.jsonrpc, result });
			try {
				if (matic_gas) { // matic get gasPrice
					this.matic_eth_gasPrice = '0x' + (await gas.matic()).toString(16);
					return warp(this.matic_eth_gasPrice);
				}
				//let url = this.url[somes.random(0, this.url.length-1)];
				// console.log('--------------', this.url, payload);
				let r = await req.request(this.url, { params: payload, method: 'POST', dataType: 'json' });
				let data = JSON.parse(r.data.toString('utf-8'));
				// console.log('--------------', data)
				return data;
			} catch (err) {
				if (retry--) {
					// console.warn(`   --- retry rpc request ${retry}`);
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
		super({ privateKeys: walletKeys, provider: base });
		base.host = this;
	}
}

exports.Provider = Provider;