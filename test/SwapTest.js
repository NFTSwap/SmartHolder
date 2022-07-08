const { expectRevert, time } = require("@openzeppelin/test-helpers");
const { createAPP, help } = require("./app");
const {
    supplyNFTAction, withdrawNFTAction,
    sellNFTAction, buyAsset, voteAction, cancelVoteAction } = require("./Swap.behavior");

const ONEDAY = 1;

contract('NFT SWAP', (accounts) => {
    var lastTokenId = 0;
    var user = accounts[3];
    before(async () => {
        this.app = await createAPP(accounts[1]);
        this.nft = await help.newNFTToken();
    })

    context("supply", () => {
        it("supply and move NFT", async () => {
            var user = accounts[3];

            lastTokenId++;
            await this.nft.mint(lastTokenId, { from: user })
            await supplyNFTAction(this.app, user, this.nft, lastTokenId);
            await withdrawNFTAction(this.app, user, this.nft, lastTokenId);
        })

        it("should be failed when withdraw others asset", async () => { });
        it("should be failed when withdraw repeat", async () => { });
        it("should be failed when withdraw bidding asset", async () => { });
    })


    context("bid", () => {

        var asset;
        var orderId;
        var minPrice = 3;
        var maxPrice = 2e18;

        before(async () => {
            lastTokenId++;
            asset = { token: this.nft.address, tokenId: lastTokenId }

            await this.nft.mint(lastTokenId, { from: user })
            await supplyNFTAction(this.app, user, this.nft, lastTokenId);

            //bid
            orderId = await sellNFTAction(this.app, user, this.nft, lastTokenId, maxPrice, minPrice, ONEDAY)
        })

        it("should be failed when withdraw bidding asset", async () => {
            await expectRevert(
                this.app.exchange.withdraw(asset, { from: user }),
                "#Exchange#withdraw: ONLY_WITHDRAW_NORMA"
            )
        })
        it("can not end bid when bidding is voting", async () => {
            await this.app.exchange.tryEndBid(orderId, { from: user });

            let status = await this.app.exchange.orderStatus(orderId)
            expect(status.toString()).to.equal("0")
        })

        context("buy", () => {

            it("buy three times", async () => {
                await buyAsset(this.app, user, orderId, minPrice, false)
                await buyAsset(this.app, accounts[5], orderId, minPrice + 1, false)
                await buyAsset(this.app, user, orderId, minPrice + 2, false)
                await buyAsset(this.app, user, orderId, minPrice + 3, false)
            })
            it("buy with max price", async () => {
                await buyAsset(this.app, user, orderId, maxPrice, true)
            })
        })
    })

    context("vote", () => {
        var asset;
        var orderId;
        var minPrice = 0.000001 * 1e18;
        var maxPrice = 2e18;

        before(async () => {
            lastTokenId++;
            asset = { token: this.nft.address, tokenId: lastTokenId }

            await this.nft.mint(lastTokenId, { from: user })
            await supplyNFTAction(this.app, user, this.nft, lastTokenId);

            //bid
            orderId = await sellNFTAction(this.app, user, this.nft, lastTokenId, maxPrice, minPrice, ONEDAY)
        })

        it("vote again", async () => {
            await voteAction(this.app, accounts[5], orderId, 0.01 * 1e18)
            await voteAction(this.app, accounts[4], orderId, 0.02 * 1e18)
            await voteAction(this.app, accounts[5], orderId, 0.03 * 1e18)
        })

        it.skip("should be failed when vote store limit", async () => {
            // pass but stop it (spend long time)

            var user = accounts[6];
            let votePool = this.app.votePool;
            var maxLimit = (await votePool.MAX_PENDING_VOTES()).toNumber();
            var voteItems = await votePool.allVotes(user)
            var currVoteTimes = voteItems.length;

            // success
            while (currVoteTimes <= maxLimit) {
                await votePool.marginVote(orderId, { from: user, value: minPrice })
                currVoteTimes++;
            }
            //will be failed
            await expectRevert(
                votePool.marginVote(orderId, { from: user, value: 1 }),
                "VotePool#vote: OVER_LIMIT_PENDING_VOTE"
            )
        })

        it("should be failed before 100 blocks", async () => {
            var user = accounts[7];
            let votePool = this.app.votePool;
            await votePool.marginVote(orderId, { from: user, value: 0.00001 * 1e18 })
            var voteItems = await votePool.allVotes(user)
            var lastVoteId = voteItems[voteItems.length - 1];
            expectRevert(
                votePool.cancelVote(lastVoteId, { from: user }),
                "#VotePool# VOTE_LOCKED"
            )
        })
        it("should be canceled after unlocked", async () => {
            var user = accounts[7];
            let votePool = this.app.votePool;

            var voteIds = [];
            for (var i = 0; i < 3; i++) {
                voteIds.push(await voteAction(this.app, user, orderId, Math.ceil((i + 1) * 0.00001 * 1e18)))
            }

            await votePool.setVoteLockTime(2);
            await time.advanceBlock();
            await time.advanceBlock();
            for (var id of voteIds) {
                await cancelVoteAction(this.app, user, id)
            }
        })
    })

})