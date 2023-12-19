
const req = require('somes/request').default;
const buffer = require('somes/buffer').default;

try {
	var cfg = require('./.config');
} catch { var cfg = {} }

async function matic(scale,fast) {
	let url = 'https://gpoly.blockscan.com/gasapi.ashx?apikey=key&method=gasoracle';
	// let url = 'https://dao.smartholder.jp/service-api/utils/printJSON';
	// if (cfg.shsProxy) {
	// 	url = `${cfg.shsProxy}?pathname=${buffer.from(url).toString('base58')}`;
	// }
	let {data} = await req.get(url);
	// {
	// 	"LastBlock": "42009802",
	// 	"SafeGasPrice": "503.4",
	// 	"ProposeGasPrice": "536.3",
	// 	"FastGasPrice": "540.3",
	// 	"suggestBaseFee": "502.349930113",
	// 	"gasUsedRatio": "0.7663592,0.789767766666667,0.839163843493171,0.732857252881441,0.654532866188378",
	// 	"UsdPrice": "1.007"
	// }
	let {ProposeGasPrice,FastGasPrice} = JSON.parse(data + '').result;

	return parseInt(fast?FastGasPrice:ProposeGasPrice) * 1000000000 * (scale?Number(scale)||1:1);
}

module.exports = {matic}

if (require.main === module) {
	const [a0,a1,network,scale,fast] = process.argv;
	// console.log(process.argv);
	(async function() {
		if (network == 'matic') {
			console.log(await matic(scale,fast));
		}
	})();
}