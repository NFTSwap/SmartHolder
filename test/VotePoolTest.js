const { expectRevert, time } = require("@openzeppelin/test-helpers");
const { inTransaction } = require("@openzeppelin/test-helpers/src/expectEvent");
const { BN } = require("@openzeppelin/test-helpers/src/setup");
const { createAPP, help } = require("./app");
const {
    supplyNFTAction, withdrawNFTAction,
    sellNFTAction, buyAsset, voteAction, cancelVoteAction } = require("./Swap.behavior");
const algo = require("./VoteRule")
const { expect } = require('chai');

contract('NFT SWAP', (accounts) => {
    var user = accounts[3];
    var app;
    var nft;
    before(async () => {
        app = await createAPP(accounts[1]);
        nft = await help.newNFTToken();
    });

    newBid = async function () {
        var tokenId = (new Date()).getTime();
        await nft.mint(tokenId, { from: user })
        await supplyNFTAction(app, user, nft, tokenId);
        var orderId = await sellNFTAction(app, user, nft, tokenId, 0, 0.01 * 1e18, 7)
        return { orderId, tokenId };
    }

    context("vote weights", function () {
        it("vote weights calculation", async () => {
            var { orderId, tokenId } = await newBid();
            var votes = [1, 2, 5, 5, 5, 6, 7, 8, 9, 10];
            for (var vote of votes) {
                algo.init({ minPrice: 0.01, percent: 0.45, day: 7 });
                var info = await app.votePool.calc(orderId, 0, (vote * 1e18).toString(), 0);
                var want = algo.newVote(vote);
                var diff = info.weight / 1e18 - want.weight;
                expect(Math.abs(diff)).to.lt(0.000001);
            }
        })

        it("vote weights calculation with more votes", async () => {
            var { orderId, tokenId } = await newBid();

            var votes = [1, 2, 5, 5, 5, 6, 7, 8, 9, 10];
            algo.init({ minPrice: 0.01, percent: 0.45, day: 7 });
            for (var vote of votes) {
                var info = await app.votePool.calc(orderId,
                    (algo.total * 1e18).toStr(),
                    (vote * 1e18).toStr(),
                    (algo.rate * 1e18).toStr());

                var want = algo.newVote(vote);
                var diff = info.weight / 1e18 - want.weight;
                expect(Math.abs(diff)).to.lt(0.000001);

                if (algo.isFixed) {
                    var diff2 = info.rateFxied / 1e18 - algo.rate;
                    expect(Math.abs(diff2)).to.lt(0.000001);
                } else {
                    expect(info.rateFxied).to.bignumber.equal("0")
                }
            }
        })

        it("vote weights", async () => {
            var { orderId, tokenId } = await newBid();
            var votes = [1, 2, 5, 5, 6, 0.01, 0.01];
            algo.init({ minPrice: 0.01, percent: 0.45, day: 7 });

            var votePool = app.votePool;
            for (var vote of votes) {
                await votePool.marginVote(orderId, { from: user, value: (vote * 1e18).toStr() })
                var want = algo.newVote(vote);
                var got = await votePool.votesById(await votePool.lastVoteId());
                var diff = got.weight / 1e18 - want.weight;
                expect(Math.abs(diff)).to.lt(0.000001);
            }
        })

        it("vote weights with new buyyer", async () => {
            var { orderId, tokenId } = await newBid();
            var votes = [1, 2, 5];
            algo.init({ minPrice: 0.01, percent: 0.45, day: 7 });
            var votePool = app.votePool;
            for (var vote of votes) {
                await votePool.marginVote(orderId, { from: user, value: (vote * 1e18).toStr() })
                var want = algo.newVote(vote);
                var got = await votePool.votesById(await votePool.lastVoteId());

                // console.log(want)
                var diff = got.weight / 1e18 - want.weight;
                expect(Math.abs(diff)).to.lt(0.000001);

                //new buy for change factor
                var price = vote;
                await app.exchange.buy(orderId, { from: user, value: (price * 1e18).toStr() });
                algo.newBuy(price);
            }
        })
    })
});