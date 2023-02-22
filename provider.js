
const somes = require('somes').default;
const req = require('somes/request');
const aes = require('crypto-tx/aes');
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
			try {
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
					throw err;
				}
			}
		}
	}
}

class Provider extends HDWalletProvider {
	constructor(provider) {
		super({
			privateKeys: walletKeys,
			provider: new ProviderBase(provider),
		})
	}
}

exports.Provider = Provider;