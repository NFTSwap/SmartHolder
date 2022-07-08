// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Strings.sol";

import {
    ILedger,
    IFeePlan,
    IVotePool,
    IExchange,
    OrderStatus, IERC721_Ext
} from "./interface.sol";
import "./libs/AddressExp.sol";
import "./Proxyable.sol";

abstract contract ExchangeStore {
    enum AssetStatus {List, Selling}
    enum Side {Buy, Sell}
    struct AssetID {
        address token;
        uint256 tokenId;
    }
    struct Asset {
        address owner;
        AssetStatus status;
        uint16 category;
        uint16 flags;
        string name;
        uint256 lastOrderId;
        uint256 lastDealOrderId;
        uint256 arrayIndex;
    }

    struct SellOrder {
        address token;
        uint256 tokenId;
        uint256 maxSellPrice;
        uint256 minSellPrice;
        uint256 lifespan;
    }
    struct SellStore {
        bool end;
        address token;
        uint256 tokenId;
        uint256 maxSellPrice;
        uint256 minSellPrice;
        uint256 lifespan;
        uint256 expiry;
        uint256 buyPrice;
        address bigBuyer;
        uint256 arrayIndex;
    }

    IFeePlan public feePlan;
    ILedger public ledger;
    IVotePool public votePool;
    address public teamAddress;
    uint256 public lastOrderId;

    // Mapping from NFT Token address to their (Map) set of owned assets
    // nft token address => map( tokenID => asset )
    mapping(address => mapping(uint256 => Asset)) assets;
    mapping(uint256 => SellStore) public bids;
    // selling order id list
    uint256[] internal _sellingOrderIds;
    // owner address => AssetID[]
    mapping(address =>AssetID[]) internal _assetsIndexed;
}

/**
 * @title NFT Exchange
 */
contract Exchange is IERC721Receiver, Proxyable, ExchangeStore {
    using SafeMath for uint256;
    using Address for address;
    using AddressExp for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    uint256 private constant _MIN_SELL_PRICE = 1;
    uint256 private constant _ONE_YEAR_DAYS = 365;

    ///@notice On supply asset to Exchange
    event Supply(
        address indexed token,
        uint256 indexed tokenId,
        address indexed owner
    );
    event Withdraw(
        address indexed token,
        uint256 indexed tokenId,
        address indexed from
    );

    event Sell(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 orderId
    );
    event BidDone(uint256 orderId, address winner, uint256 price);

    event Buy(uint256 indexed orderId, address buyer, uint256 price);
    event Transfer(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 tokenId,
        uint256 orderId
    );

    function initialize(
        IFeePlan feePlan_,
        ILedger ledger_,
        address team
    ) external {
        __Proxyable_init();
        feePlan = feePlan_;
        ledger = ledger_;
        teamAddress = team;
    }

    function setVotePool(IVotePool votePool_) external onlyOwner {
        votePool = votePool_;
    }

    function setFeePlan(IFeePlan feePlan_) external onlyOwner {
        feePlan = feePlan_;
    }

    function setLedger(ILedger ledger_) external onlyOwner {
        ledger = ledger_;
    }

    function _removeAssetsIndexed(Asset storage asset) private {
        AssetID[] storage idx = _assetsIndexed[asset.owner];
        if (idx.length > 0) {
            if (idx.length > 1) {
                AssetID storage last = idx[idx.length - 1];
                idx[asset.arrayIndex] = last;
                assets[last.token][last.tokenId].arrayIndex = asset.arrayIndex;
            }
            idx.pop();
        }
    }

    ///@dev token owner send asset to Exchange, save send info
    function _supply(
        address from,
        IERC721 token,
        uint256 tokenId,
        bytes memory data
    ) private {
        require(from != address(0), "#Exchange#supply: FROM_IS_EMPTY");

        uint16 category;
        uint16 flags;
        string memory name;

        (category, flags, name) = abi.decode(data, (uint16, uint16, string));

        require(bytes(name).length <= 60, "#Exchange#supply: NAME_TOO_LONG");

        AssetID[] storage idx = _assetsIndexed[from];

        idx.push(AssetID({ token: address(token), tokenId: tokenId }));
        assets[address(token)][tokenId] = Asset({
            owner: from,
            status: AssetStatus.List,
            category: category,
            flags: flags,
            name: name,
            lastOrderId: 0,
            lastDealOrderId: 0,
            arrayIndex: idx.length - 1
        });

        emit Supply(address(token), tokenId, from);
    }

    function voteAllowed(
        uint256 orderId,
        address, //voter,
        uint256 //margin
    ) external view {
        _requireOrderIsBidding(orderId);
    }

    function cancelVoteAllowed(uint256 orderId, address voter) external {
        // OrderStatus status = orderStatus(orderId);
        // require(status != OrderStatus.DealDone, "#Exchange: ORDER_SOLD");
    }

    function orderVoteInfo(uint256 orderId)
        external
        view
        returns (
            uint256 buyPrice,
            uint256 auctionDays,
            uint256 shareRatio
        )
    {
        SellStore storage order = _getOrder(orderId);
        Asset storage asset = assets[order.token][order.tokenId];

        buyPrice = order.buyPrice;
        if (buyPrice == 0) buyPrice = order.minSellPrice;
        auctionDays = order.lifespan;
        shareRatio = feePlan.voterShareRatio(asset.lastDealOrderId == 0);
    }

    /**
     * @notice withdraw asset from Exchage to `to`.
     * @param asset ({}) is asset info include token address and tokenId.
     * @dev only withdraw by owner self. and disable withdraw when asset is selling.
     */
    function withdraw(AssetID memory asset) public {
        Asset storage info = assets[asset.token][asset.tokenId];
        address assetOwner = info.owner;
        require(
            assetOwner != address(0),
            "#Exchange#withdraw: NOT_FOUND_ASSET"
        );
        require(assetOwner == msg.sender, "#Exchange#withdraw: NO_ACCESS");
        require(
            info.status == AssetStatus.List,
            "#Exchange#withdraw: ONLY_WITHDRAW_NORMAL"
        );
        _removeAssetsIndexed(info); // delete indexed
        delete assets[asset.token][asset.tokenId];
        IERC721 token = IERC721(asset.token);
        token.safeTransferFrom(address(this), assetOwner, asset.tokenId);

        emit Withdraw(asset.token, asset.tokenId, assetOwner);
    }

    /**
     * @notice Bidding asset by owner.
     * @param order is bid information.
     * @return orderId is current order hash.
     * @dev owner can bid asset with information,but only allowed for normal asset.
     * information include price and expiration. some case:
     *  1. Buy it Now(at a price): set `order.maxSellPrice` and `order.minSellPrice` to the price you expect.
     *  2. Low price bidding: set `order.minSellPrice` to the price you expect, the value must be greater than or equal to 0.000001.
     *  3. One day bidding period: e.g `order.lifespan = 24*60*60s = 1 days`
     */
    function sell(SellOrder memory order) public returns (uint256 orderId) {
        //check owner
        Asset storage info = assets[order.token][order.tokenId];
        require(info.owner == msg.sender, "#Exchange#sell: NO_ACCESS");
        require(
            info.status == AssetStatus.List,
            "#Exchange#sell: ONLY_SELL_NORMAL"
        );

        //check input info
        require(
            order.minSellPrice >= _MIN_SELL_PRICE,
            "#Exchange#sell: INVLIAD_MIN_SELLPRICE"
        );
        require(
            order.maxSellPrice == 0 || order.maxSellPrice >= order.minSellPrice,
            "#Exchange#sell: INVLIAD_MAX_SELLPRICE"
        );
        require(
            order.lifespan >= 1 && order.lifespan < _ONE_YEAR_DAYS,
            "#Exchange#sell: INVLIAD_LIFESPAN"
        );

        orderId = ++lastOrderId;
        //store order infomation
        _sellingOrderIds.push(orderId);
        bids[orderId] = SellStore({
            end: false,
            token: order.token,
            tokenId: order.tokenId,
            maxSellPrice: order.maxSellPrice,
            minSellPrice: order.minSellPrice,
            lifespan: order.lifespan,
            expiry: block.timestamp + (order.lifespan * 1 days),
            buyPrice: 0,
            bigBuyer: address(0),
            arrayIndex: _sellingOrderIds.length - 1 //never overflow.
        });

        // update asset status and store orderid
        info.status = AssetStatus.Selling;
        info.lastOrderId = orderId;

        emit Sell(order.token, order.tokenId, msg.sender, orderId);
    }

    function _requireOrderIsBidding(uint256 orderId) private view {
        SellStore storage order = bids[orderId];
        require(order.token != address(0), "#Exchange: ORDER_NOT_FOUND");
        require(!order.end, "#Exchange: ORDER_OVER");
        require(order.expiry > block.timestamp, "#Exchange: ORDER_EXPIRED");
    }

    /**
     * @notice Send Ether as price to participate in NFT bidding.
     * @param orderId is the bidding order ID.
     * @dev When participating in an auction,
     * The bidding price must be higher than the current highest bid, otherwise the bidding is invalid.
     * The offer will be locked until you win or lose.
     */
    function buy(uint256 orderId) public payable {
        _requireOrderIsBidding(orderId);

        SellStore storage order = bids[orderId];
        uint256 price = msg.value;
        address buyer = msg.sender;
        uint256 lastBuyPrice = order.buyPrice;
        require(price >= order.minSellPrice, "#Exchange#buy: INVLIAD_PRICE");
        require(price > lastBuyPrice, "#Exchange#buy: PRICE_TOO_SAMLL");

        // refound ethers to last buyer before update.
        ILedger _wallet = ledger; //save gas
        address lastBuyer = order.bigBuyer;
        uint256 amount = order.buyPrice;
        if (amount > 0 && lastBuyer != address(0)) {
            // _wallet.transfer(lastBuyer, amount);
            _wallet.withdraw(lastBuyer, amount);
        }
        // transfer to ledger
        _wallet.deposit{value: price}();

        // update
        order.buyPrice = price;
        order.bigBuyer = buyer;
        emit Buy(orderId, buyer, price);

        tryEndBid(orderId);
    }

    function _getOrder(uint256 orderId)
        internal
        view
        returns (SellStore storage order)
    {
        order = bids[orderId];
        require(order.token != address(0), "#Exchange#buy: ORDER_NOT_FOUND");
    }

    /**
        @dev Try and end the bidding.
        * end time:
        *   1. buy price has reached the highest bidding price.
        *   2. or order expired.
     */
    function tryEndBid(uint256 orderId) public returns (bool) {
        SellStore storage order = _getOrder(orderId);

        uint256 price = order.buyPrice;
        // transfer asset to winner now when buyer is winner
        //
        bool canEnd =
            order.expiry <= block.timestamp ||
                (price > 0 &&
                    order.maxSellPrice > 0 &&
                    price >= order.maxSellPrice);

        if (!canEnd) {
            return false;
        }
        // do someting before end it.
        // 1. update asset status and delete bidding order.
        Asset storage asset = assets[order.token][order.tokenId];
        address token = order.token;
        uint256 tokenId = order.tokenId;
        uint256 arrayIndex = order.arrayIndex;

        // remove
        uint256 last = _sellingOrderIds[_sellingOrderIds.length - 1];
        _sellingOrderIds[arrayIndex] = last;
        bids[last].arrayIndex = arrayIndex;
        _sellingOrderIds.pop();

        // Recovery asset status
        asset.status = AssetStatus.List;
        order.end = true;
        // 2. transfer asset to the winner,if any.
        address winner = order.bigBuyer;
        if (winner != address(0)) {
            _sellDone(orderId, token, tokenId, price, winner);
        }

        // 3. send evnet
        emit BidDone(orderId, winner, price);

        return true;
    }

    function _sellDone(
        uint256 orderId,
        address token,
        uint256 tokenId,
        uint256 price,
        address winner
    ) private {
        uint256 orderId_ = orderId;
        IVotePool pool = votePool; //save gas
        Asset storage asset = assets[token][tokenId];
        uint256 votes = pool.orderTotalVotes(orderId_);
        // sub-commission
        (uint256 toSeller, uint256 toVoter, uint256 toTeam) = feePlan.formula(price, asset.lastDealOrderId == 0, votes); //prettier-ignore

        {
            // owner get income
            ILedger wallet = ledger; //save gas
            wallet.transfer(address(pool), toVoter);
            pool.subCommission(orderId_, toVoter);
            wallet.withdraw(asset.owner, toSeller); // Must be executed after subCommission()
            wallet.transfer(teamAddress, toTeam);
        }

        address oldOwner = asset.owner;
        if (oldOwner != winner) {
            _removeAssetsIndexed(asset); // remove old indexed
            AssetID[] storage idx = _assetsIndexed[winner];
            idx.push(AssetID({ token: address(token), tokenId: tokenId }));
            asset.arrayIndex = idx.length - 1; // new indexed
        }
        asset.lastDealOrderId = orderId_;
        asset.owner = winner;
        
        emit Transfer(oldOwner, winner, token, tokenId, orderId_);
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external override returns (bytes4) {
        //check
        IERC721 token = _isERC721(msg.sender);
        require(
            token.ownerOf(tokenId) == address(this),
            "#Exchange#onERC721Received: NOT_OWN_TOKEN"
        );

        _supply(from, token, tokenId, data);
        return _ERC721_RECEIVED;
    }

    // @dev convert addr to standard ERC721 NFT,will be revered if add is invalid.
    function _isERC721(address addr) internal view returns (IERC721) {
        require(
            addr.isContract(),
            "#Exchange#_isERC721: INVLIAD_CONTRACT_ADDRESS"
        );
        require(
            IERC721(addr).supportsInterface(_INTERFACE_ID_ERC721),
            "The NFT contract has an invalid ERC721 implementation"
        );
        return IERC721(addr);
    }

    function orderStatus(uint256 orderId)
        external
        view
        returns (OrderStatus status)
    {
        SellStore storage order = _getOrder(orderId);
        if (order.end) {
            status = OrderStatus.DealDone;
        } else {
            // when order is bidding:
            // case1: Expired but there are buyers -> DealDone
            // case2: Expired but there are not any buyers -> Expired
            // case3: Not expired ->Ing
            if (order.expiry > block.timestamp) {
                status = OrderStatus.Ing;
            } else if (order.bigBuyer != address(0)) {
                status = OrderStatus.DealDone;
            } else {
                status = OrderStatus.Expired;
            }
        }
    }

    /************************************ */

    /**
     * @notice return the asset info by assetId.
     * @param assetId is a struct of asset unique Key ({token,tokenId}).
     * @return Asset is the asset info.
     */
    function assetOf(AssetID memory assetId)
        public
        view
        returns (Asset memory)
    {
        return assets[address(assetId.token)][assetId.tokenId];
    }

    struct SellingNFTData {
        uint256 orderId;
        uint256 totalVotes;
        SellStore order;
    }

    struct NFTAsset {
        Asset asset;
        address token;
        uint256 tokenId;
        string tokenURI;
        SellingNFTData selling;
    }

    /**
     * @notice Getselling NFT information by page.
     * @param fromIndex is the search begin index of the selling order array.
     * @param pageSize is the maximum number of records per page. The value range is [1,100].
     * @param ignoreZeroVote is the filter condition, whether to include bids that have 0 votes.
     * @dev return two data: uint256 nextSearchIndex, nftInfo array.
     * Note: Explain that there is no data if return nft array include empty data (e.g orderId iz 0).
     * SellingNFTData:
     *   +. `orderId`: uint256.
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
     */
    function getSellingNFT(
        uint256 fromIndex,
        uint256 pageSize,
        bool ignoreZeroVote, bool isTokenURI
    ) external view returns (uint256 next, NFTAsset[] memory nfts) {
        require(
            pageSize > 0 && pageSize <= 100,
            "#Exchange:search: INVLIAD_PAGESIZE"
        );
        uint256 total = _sellingOrderIds.length; //save gas.
        uint256 size;
        uint256[] memory orderIds = new uint256[](pageSize);

        for (next = fromIndex; next < total && size < pageSize; next++) {
            uint256 orderId = _sellingOrderIds[next];
            if (ignoreZeroVote) {
                orderIds[size] = orderId;
                size++;
            } else if (votePool.orderTotalVotes(orderId) > 0) {
                orderIds[size] = orderId;
                size++;
            }
        }

        nfts = new NFTAsset[](size);

        for (uint256 i = 0; i < size; i++) {
            uint256 orderId = orderIds[i];
            SellStore memory order = bids[orderId];
            nfts[i] = NFTAsset({
                asset: assets[order.token][order.tokenId],
                token: order.token,
                tokenId: order.tokenId,
                tokenURI: isTokenURI ? IERC721_Ext(order.token).tokenURI(order.tokenId): "",
                selling: SellingNFTData({
                    orderId: orderId,
                    order: order,
                    totalVotes: votePool.orderTotalVotes(orderId)
                })
            });
        }

        return (next, nfts);
    }

    function assetsFrom(address owner, bool isTokenURI) public view returns(NFTAsset[] memory nft_assets) {
        AssetID[] storage idx = _assetsIndexed[owner];
        nft_assets = new NFTAsset[](idx.length);
        for (uint256 i = 0; i < idx.length; i++) {
            AssetID storage id = idx[i];
            Asset storage asset = assets[id.token][id.tokenId];
            SellingNFTData memory selling;
            
            if (asset.status == AssetStatus.Selling) {
                selling.orderId = asset.lastOrderId;
                selling.order = bids[asset.lastOrderId];
                selling.totalVotes = votePool.orderTotalVotes(asset.lastOrderId);
            }

            nft_assets[i] = NFTAsset({
                asset: asset,
                token: id.token,
                tokenId: id.tokenId,
                tokenURI: isTokenURI ? IERC721_Ext(id.token).tokenURI(id.tokenId): "",
                selling: selling
            });
        }
    }

    function getSellingNFTTotal() external view returns(uint256 total) {
        total = _sellingOrderIds.length;
    }
}
