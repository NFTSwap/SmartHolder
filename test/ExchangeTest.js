const { expectRevert, time } = require("@openzeppelin/test-helpers");
const { inTransaction } = require("@openzeppelin/test-helpers/src/expectEvent");
const { expect, assert } = require("chai");
const { createAPP, help } = require("./app");
const {
    supplyNFTAction, withdrawNFTAction,
    sellNFTAction, buyAsset, voteAction, cancelVoteAction } = require("./Swap.behavior");


contract('NFT SWAP', (accounts) => {
    var user = accounts[3];
    before(async () => {
        this.app = await createAPP(accounts[1]);
        this.nft = await help.newNFTToken();
    })


    context("100-selling nft page search", () => {
        var orders = [];
        var count = 23;
        before(async () => {
            for (var i = 0; i < count; i++) {
                var tokenId = await help.mintNFT(this.nft, user);
                await supplyNFTAction(this.app, user, this.nft, tokenId, true);
                var orderId = await sellNFTAction(this.app, user, this.nft, tokenId, 0, 1, 1, true);
                orders.push(orderId);
            }
        })

        it("Should be include new nft if sell it", async () => {
            let result = await this.app.exchange.getSellingNFT(0, 100, true);
            var finds = [];
            for (var item of result.nfts) {

                for (var o of orders) {
                    if (item.orderId.toString() == o.toString()) {
                        find.push(o);
                        break;
                    }
                }
            }
            expect(finds.length == orders.length, `expect find orders( ${orders} )in list,but only find ${finds}`);
        })

        it("by page", async () => {
            var pageSize = 3;
            //8=23/3
            var fromIndex = 0;
            var finds = {};
            for (var i = 0; i < 8; i++) {
                let result = await this.app.exchange.getSellingNFT(fromIndex, pageSize, false);
                for (var item of result.nfts) {
                    let orderId = item.orderId.toString();
                    assert.isUndefined(finds[orderId], "got repeat order");
                    finds[orderId] = true;
                }
                fromIndex = result.next;
            }
            expect(Object.keys(finds).length == orders.length, `expect search all NFT`);
        })
    })
});
