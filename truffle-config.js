/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

const Provider = require("./provider").Provider;
try {
	var cfg = require("./.truffle-config");
} catch {
	var cfg = {};
}

const truffle_config = {
	/**
	 * Networks define how you connect to your ethereum client and let you set the
	 * defaults web3 uses to send transactions. If you don't specify one truffle
	 * will spin up a development blockchain for you on port 9545 when you
	 * run `develop` or `test`. You can ask a truffle command to use a specific
	 * network from the command line, e.g
	 *
	 * $ truffle test --network <network-name>
	 */

	networks: {
		// Useful for testing. The `development` name is special - truffle uses it by default
		// if it's defined here and no other network is specified at the command line.
		// You should run a client (like ganache-cli, geth or parity) in a separate terminal
		// tab if you use this network and you must also set the `host`, `port` and `network_id`
		// options below to some value.
		goerli: {
			network_id: 5,
			provider: new Provider(
				'https://goerli.infura.io/v3/6b4f3897597e41d1adc12b7447c84767',
				// 'https://eth-goerli.g.alchemy.com/v2/lwDFslNRvhCjzogUVLPtPzGIN4ZZDa8I',
			),
			production: false,
		},
		matic: {
			network_id: 137,
			provider: new Provider(
				'https://polygon-mainnet.infura.io/v3/6b4f3897597e41d1adc12b7447c84767',
				// 'https://rpc-mainnet.maticvigil.com/v1/ef8f16191b474bb494f33283a81a38487e4dc245'
			),
			production: true,
			gasPrice: process.env.GAS, // 400000000000
		},
		development: {
			host: "127.0.0.1",
			port: "8545",
			gas: 6721975,
			network_id: 1337,
		},
		...cfg.networks,
	},

	// Set default mocha options here, use special reporters etc.
	mocha: {
		// timeout: 100000
		enableTimeouts: false,
	},

	// Configure your compilers
	compilers: {
		solc: {
			version: "0.8.17", // Fetch exact version from solc-bin (default: truffle's version)
			docker: false, // Use "0.5.1" you've installed locally with docker (default: false)
			settings: {
				// See the solidity docs for advice about optimization and evmVersion
				optimizer: {
					enabled: true,
					runs: 200,
				},
				evmVersion: "petersburg",
			},
		},
	},
	// plugins: ["solidity-coverage"]
};


module.exports = truffle_config;