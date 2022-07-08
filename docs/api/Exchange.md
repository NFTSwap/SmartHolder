# `Exchange`
**NFT Exchange**




## .Functions
### initialize

```solidity
function initialize(contract IFeePlan feePlan_, contract ILedger ledger_, address team)
```







### setVotePool

```solidity
function setVotePool(contract IVotePool votePool_)
```







### voteAllowed

```solidity
function voteAllowed(uint256 orderId, address, uint256)
```







### cancelVoteAllowed

```solidity
function cancelVoteAllowed(uint256 orderId, address voter)
```







### orderVoteInfo

```solidity
function orderVoteInfo(uint256 orderId) returns(uint256 buyPrice, uint256 auctionDays, uint256 shareRatio)
```







### withdraw

```solidity
function withdraw(struct ExchangeStore.AssetID asset)
```

withdraw asset from Exchage to `to`.


only withdraw by owner self. and disable withdraw when asset is selling.

**Input**
+ `asset`: ({}) is asset info include token address and tokenId.



### sell

```solidity
function sell(struct ExchangeStore.SellOrder order) returns(uint256 orderId)
```

Bidding asset by owner.


owner can bid asset with information,but only allowed for normal asset.
information include price and expiration. some case:
 1. Buy it Now(at a price): set `order.maxSellPrice` and `order.minSellPrice` to the price you expect.
 2. Low price bidding: set `order.minSellPrice` to the price you expect, the value must be greater than or equal to 0.000001.
 3. One day bidding period: e.g `order.lifespan = 24*60*60s = 1 days`

**Input**
+ `order`: is bid information.

**Output**
+ `orderId`: is current order hash.



### buy

```solidity
function buy(uint256 orderId)
```

Send Ether as price to participate in NFT bidding.


When participating in an auction,
The bidding price must be higher than the current highest bid, otherwise the bidding is invalid.
The offer will be locked until you win or lose.

**Input**
+ `orderId`: is the bidding order ID.



### _getOrder

```solidity
function _getOrder(uint256 orderId) returns(struct ExchangeStore.SellStore order)
```







### tryEndBid

```solidity
function tryEndBid(uint256 orderId)
```



Try and end the bidding.
end time:
  1. buy price has reached the highest bidding price.
  2. or order expired.



### onERC721Received

```solidity
function onERC721Received(address, address from, uint256 tokenId, bytes data) returns(bytes4)
```



Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
by `operator` from `from`, this function is called.

It must return its Solidity selector to confirm the token transfer.
If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.

The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.



### _isERC721

```solidity
function _isERC721(address addr) returns(contract IERC721)
```







### orderStatus

```solidity
function orderStatus(uint256 orderId) returns(enum OrderStatus status)
```







### assetOf

```solidity
function assetOf(struct ExchangeStore.AssetID assetId) returns(struct ExchangeStore.Asset)
```

return the asset info by assetId.




**Input**
+ `assetId`: is a struct of asset unique Key ({token,tokenId}).

**Output**
+ `Asset`: is the asset info.


### getSellingNFT

```solidity
function getSellingNFT(uint256 fromIndex, uint256 pageSize, bool ignoreZeroVote) returns(uint256 next, struct Exchange.SellingNFTData[] nfts)
```

/**
Getselling NFT information by page.


return two data: uint256 nextSearchIndex, nftInfo array.
Note: Explain that there is no data if return nft array include empty data (e.g orderId iz 0).
SellingNFTData:
  +. `orderId`: uint256.
         +. `totalVotes`: uint256.
         +. `order`：
                +. `token`: address;
                +. `tokenId`: uint256;
                +. `maxSellPrice`: uint256;
                +. `minSellPrice`: uint256;
                +. `lifespan`: uint256;
                +. `expiry`: uint256;
                +. `buyPrice`: uint256;
                +. `bigBuyer`: address;
/

**Input**
+ `fromIndex`: is the search begin index of the selling order array.
+ `pageSize`: is the maximum number of records per page. The value range is [1,100].
+ `ignoreZeroVote`: is the filter condition, whether to include bids that have 0 votes.




## .Event
### Supply

```solidity
Supply(address token, uint256 tokenId, address owner)
```

On supply asset to Exchange




### Withdraw

```solidity
Withdraw(address token, uint256 tokenId, address from)
```






### Sell

```solidity
Sell(address token, uint256 tokenId, address seller, uint256 orderId)
```






### BidDone

```solidity
BidDone(uint256 orderId, address winner, uint256 price)
```






### Buy

```solidity
Buy(uint256 orderId, address buyer, uint256 price)
```






### Transfer

```solidity
Transfer(address from, address to, address token, uint256 tokenId, uint256 orderId)
```






### OwnershipTransferred

```solidity
OwnershipTransferred(address previousOwner, address newOwner)
```






