const {
    BN,
    expectEvent,
    expectRevert,
    constants,
} = require("@openzeppelin/test-helpers");

const BLOCKS_ONEDAY = 24 * 60 * 60;

const { expect } = require('chai');

async function supplyNFTAction(app, user, nft, tokenId, disableCheck) {
    //send nft to swap
    let category = 5;
    let flags = 4;
    let name = "FROM-" + user;
    var data = web3.eth.abi.encodeParameters(
        ["uint16", "uint16", "string"],
        [category, flags, name]
    );

    let result = await nft.methods[
        "safeTransferFrom(address,address,uint256,bytes)"
    ](user, app.exchange.address, tokenId, data, { from: user });

    expectEvent.inTransaction(result.tx, app.exchange, "Supply", {
        token: nft.address,
        tokenId: tokenId.toString(),
        owner: user,
    });

    if (disableCheck) {
        return;
    }

    expect(await nft.ownerOf(tokenId)).to.equal(app.exchange.address);

    // check supply info
    let assetInfo = await app.exchange.assetOf({
        token: nft.address,
        tokenId: tokenId,
    });
    expect(assetInfo.owner).to.equal(user);
    expect(assetInfo.status).to.equal("0");
    expect(assetInfo.category).to.equal(category.toString());
    expect(assetInfo.flags).to.equal(flags.toString());
    expect(assetInfo.name).to.equal(name);
    expect(assetInfo.lastOrderId).to.equal("0");
    expect(assetInfo.lastDealOrderId).to.equal("0");
}

async function withdrawNFTAction(app, user, nft, tokenId,) {
    let asset = { token: nft.address, tokenId: tokenId };

    var result = await app.exchange.withdraw(asset, { from: user });

    expectEvent(result, "Withdraw", {
        token: nft.address,
        tokenId: tokenId.toString(),
        from: user,
    });

    expect(await nft.ownerOf(tokenId)).to.equal(user);

    let assetInfo = await app.exchange.assetOf(asset);
    expect(assetInfo.owner).to.equal(constants.ZERO_ADDRESS);

    //will failed
    await expectRevert(
        app.exchange.withdraw(asset, { from: user }),
        "#Exchange#withdraw: NOT_FOUND_ASSET"
    );
}

async function sellNFTAction(
    app,
    user,
    nft,
    tokenId,
    maxSellPrice,
    minSellPrice,
    days, disableCheck
) {
    var orderId = (await app.exchange.lastOrderId()).toNumber() + 1;
    var order = {
        sender: user,
        token: nft.address,
        tokenId: tokenId.toString(),
        maxSellPrice: maxSellPrice.toString(),
        minSellPrice: minSellPrice.toString(),
        lifespan: days.toString(),
    };
    let result = await app.exchange.sell(order, { from: user });

    expectEvent(result, "Sell", {
        token: order.token,
        tokenId: order.tokenId,
        seller: order.sender,
        orderId: orderId.toString(),
    });

    if (disableCheck) {
        return orderId;
    }

    let assetInfo = await app.exchange.assetOf({
        token: nft.address,
        tokenId: tokenId,
    });
    assert.equal(
        assetInfo.status,
        "1",
        "asset status should be in selling when selling"
    );

    let store = await app.exchange.bids(orderId);
    expect(store.token).to.equal(order.token);
    expect(store.tokenId.toString()).to.equal(order.tokenId);
    expect(store.maxSellPrice.toString()).to.equal(order.maxSellPrice);
    expect(store.minSellPrice.toString()).to.equal(order.minSellPrice);
    expect(store.lifespan.toString()).to.equal(order.lifespan);

    // expect(store.expiry.toNumber()).to.equal(
    //     days * BLOCKS_ONEDAY + result.receipt.blockNumber
    // );
    expect(store.buyPrice.toString()).to.equal("0");
    expect(store.bigBuyer).to.equal(constants.ZERO_ADDRESS);

    //check order status
    let status = await app.exchange.orderStatus(orderId);
    var block = await web3.eth.getBlock(result.receipt.blockHash);
    if (store.expiry.toNumber() > block.timestamp) {
        assert.equal(
            status,
            "0", //Ing
            "order status is selling"
        );
    }
    return orderId;
}

async function buyAsset(app, user, orderId, price, wantEndBid) {
    var balance = await app.ledger.balanceOf(app.exchange.address);
    let storeBefore = await app.exchange.bids(orderId);
    let lastBuyerBalance = await app.ledger.balanceOf(storeBefore.bigBuyer);

    let asset = {
        token: storeBefore.token,
        tokenId: storeBefore.tokenId.toString(),
    }
    let assetInfo = await app.exchange.assetOf(asset);
    let oldOwner = assetInfo.owner;
    let ownerBalance = new BN(await web3.eth.getBalance(oldOwner));

    var priceBN = new BN(price.toString());

    var result = await app.exchange.buy(orderId, { from: user, value: priceBN });

    expectEvent(result, "Buy", {
        orderId: orderId.toString(),
        buyer: user,
        price: priceBN,
    });

    if (storeBefore.bigBuyer == user) {
        assert.equal(
            (await app.ledger.balanceOf(storeBefore.bigBuyer)).toString(),
            lastBuyerBalance.add(storeBefore.buyPrice).toString()
        );
    } else {
        assert.equal(
            (await app.ledger.balanceOf(storeBefore.bigBuyer)).toString(),
            lastBuyerBalance.add(storeBefore.buyPrice).toString()
        );
    }
    let status = await app.exchange.orderStatus(orderId);

    expect(status.toNumber()).to.equal(wantEndBid ? 2 : 0)

    let storeNow = await app.exchange.bids(orderId);
    expect(storeNow.end).to.equal(wantEndBid);

    if (wantEndBid) {
        let assetInfo = await app.exchange.assetOf(asset);
        expect(assetInfo.owner).to.equal(user);
        expect(assetInfo.status).to.bignumber.equal("0");
        expect(assetInfo.lastOrderId).to.equal(orderId.toString());

        // owner income= priceBN * 45%
        expectEvent.inTransaction(result.tx, app.ledger, "Transfer", {
            from: app.exchange.address,
            to: oldOwner,
            value: priceBN.mul(new BN(45)).div(new BN(100))
        });
        // "expect send ETH to owner"
        expectEvent.inTransaction(result.tx, app.ledger, "Transfer", {
            from: oldOwner,
            to: constants.ZERO_ADDRESS,
            value: priceBN.mul(new BN(45)).div(new BN(100))
        })
    } else {
        // reback to losser
        if (storeBefore.bigBuyer != constants.ZERO_ADDRESS) {
            expectEvent.inTransaction(result.tx, app.ledger, "Transfer", {
                from: app.exchange.address,
                to: storeBefore.bigBuyer,
                value: storeBefore.buyPrice
            });
        }
        // receive  locked ETH(price)
        expectEvent.inTransaction(result.tx, app.ledger, "Transfer", {
            from: constants.ZERO_ADDRESS,
            to: app.exchange.address,
            value: priceBN
        });
        expect(storeNow.bigBuyer).to.equal(user);
        expect(storeNow.buyPrice.toString()).to.equal(price.toString());
    }
}

async function voteAction(app, user, orderId, margin) {
    var marginBN = new BN(margin.toString())
    var oldVotes = Array.from(await app.votePool.allVotes(user), x => x.toString());
    var balance = await app.ledger.balanceOf(app.votePool.address);
    var voteId = (await app.votePool.lastVoteId()).add(new BN("1"));
    let store = await app.exchange.bids(orderId);

    // vote
    var result = await app.votePool.marginVote(orderId, { from: user, value: marginBN })
    let voteInfo = await app.votePool.votesById(voteId)


    expectEvent(result, "Voted", {
        orderId: orderId.toString(),
        voter: user,
        voteId: voteId.toString(),
        weight: voteInfo.weight,
    })

    expect(
        await app.ledger.balanceOf(app.votePool.address)
    ).to.bignumber.equal(
        balance.add(marginBN)
    )

    //can load vote info by voteId
    expect(voteInfo.voter).to.equal(user);
    expect(voteInfo.orderId).to.bignumber.equal(orderId.toString());
    expect(voteInfo.votes).to.bignumber.equal(marginBN);
    expect(voteInfo.blockNumber).to.bignumber.equal(result.receipt.blockNumber.toString());

    //include vote info in array
    expect(
        Array.from(await app.votePool.allVotes(user), x => x.toString())
    ).to.eql(
        oldVotes.concat(voteId.toString())
    )
    // include lock info in ledger
    var lockedItemsNow = (await app.ledger.lockedItems(user))
    var last = lockedItemsNow[lockedItemsNow.length - 1];
    expect(last.locker).to.equal(app.votePool.address)
    expect(last.lockId).to.equal(voteId.toString())
    expect(last.amount).to.equal(margin.toString())

    // deposit
    expectEvent.inTransaction(result.tx, app.ledger, "Transfer", {
        from: constants.ZERO_ADDRESS,
        to: app.votePool.address,
        value: margin.toString()
    });


    return voteId
}


async function cancelVoteAction(app, user, voteId) {
    let voteInfo = await app.votePool.votesById(voteId)
    let marginBN = new BN(voteInfo.votes.toString())
    var oldVotes = Array.from(await app.votePool.allVotes(user), x => x.toString());
    var balance = await app.ledger.balanceOf(app.votePool.address);
    var orderId = voteInfo.orderId
    // vote
    var result = await app.votePool.cancelVote(voteId, { from: user })

    expectEvent(result, "Canceled", {
        orderId: orderId.toString(),
        voter: user,
        voteId: voteId.toString(),
    })

    expect(
        await app.ledger.balanceOf(app.votePool.address)
    ).to.bignumber.equal(
        balance.sub(marginBN)
    )

    // vote clear
    var info = await app.votePool.votesById(voteId)
    expect(info.voter).to.equal(constants.ZERO_ADDRESS)

    //include vote info in array
    var voteIds = Array.from(await app.votePool.allVotes(user), x => x.toString())
    expect(voteIds).to.not.include(voteId.toString())
    expect(oldVotes).to.include.members(voteIds)

    // lock remove  canceled vote
    var lockedItemsNow = Array.from(await app.ledger.lockedItems(user), x => x.lockId.toString())
    expect(lockedItemsNow).to.not.include(voteId.toString())
}

module.exports = {
    supplyNFTAction,
    withdrawNFTAction,
    sellNFTAction,
    buyAsset,
    voteAction,
    cancelVoteAction
};
