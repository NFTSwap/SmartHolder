const constants = require("@openzeppelin/test-helpers/src/constants");
const { web3, BN } = require("@openzeppelin/test-helpers/src/setup");

var Exchange = artifacts.require("Exchange.sol");
var FeePlan = artifacts.require("FeePlan.sol");
var Ledger = artifacts.require("Ledger.sol");
var VotePool = artifacts.require("VotePool.sol");
// init some thing
require("@openzeppelin/test-helpers");

function APP() {
    this.init = async function (team) {
        this.ledger = await Ledger.deployed();
        this.feePlan = await FeePlan.deployed();
        this.votePool = await VotePool.deployed();
        this.exchange = await Exchange.deployed();
    }
}

var help = {
    newNFTToken: async function () {
        // var ERC721=artifacts.require("@openzeppelin/contracts/ERC721")
        // return await ERC721.new("MY TEST ERC721","NFT");
        return await artifacts.require("MYNFT").new();
    },

    getTxFee: async function (txHash) {
        var tx = await web3.eth.getTransaction(txHash)
        var receipt = await web3.eth.getTransactionReceipt(txHash)

        return new BN(tx.gasPrice).mul(new BN(receipt.gasUsed))
    },

    mintNFT: async function (nftToken, user) {
        for (; ;) {
            var id = (new Date()).getTime();
            await nftToken.mint(id, { from: user })
            return id;
        }
    }
}

async function createAPP(team) {
    var app = new APP();
    await app.init(team);
    return app;
}

Number.prototype.toHex = function () { return h.hex(this) };
Number.prototype.toStr = function () { return this.toLocaleString("fullwide", { useGrouping: false }) };


module.exports = { createAPP, help }