// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

pragma experimental ABIEncoderV2;

import './libs/Errors.sol';
import './libs/ERC721.sol';
import './Asset.sol';

contract AssetShell is AssetModule, ERC1155, IAssetShell {
	using Address for address;

	struct LockedID {
		uint256 tokenId;
		address owner;
		address previous; // previous owner
	}
	struct LockedItem {
		uint64 count;
		uint64 blockNumber; // block number
		uint64 index; // index for itemsKeys
	}
	struct Locked {
		uint64                         total; // owner locked count total for tokenId
		mapping(address => LockedItem) items; // previous asset owner address => value
		address[]                      itemsKeys; // previous list
	}

	struct AssetData {
		AssetID                    meta; // asset meta data
		uint256                    minimumPrice; // Minimum transaction price of assets
		mapping(address => Locked) locked; // owner => Locked
	}

	mapping(uint256 => AssetData) private _assetsData;   // tokenId => raw asset id
	LockedID                      private _lastLocked;
	SaleType                      public  saleType; // is opensea first or second sale
	bool                          public  isEnableLock;  // enable asset safe lock
	uint256[16]                   private  __; // reserved storage space

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns (bool) {
		return ERC1155.supportsInterface1155(interfaceId) || ERC165.supportsInterface(interfaceId);
	}

	function initAssetShell(
		address host, address operator,
		SaleType saleType_, InitContractURI memory uri_, bool isEnableLock_
	) external {
		initAssetModule(host, operator, uri_);
		_registerInterface(AssetShell_Type);
		saleType = saleType_;
		isEnableLock = isEnableLock_;
	}

	function asERC1155(address addr) view internal returns (IERC1155) {
		if (!addr.isContract()) revert NonContractAddress();
		if (!IERC1155(addr).supportsInterface(type(IERC1155).interfaceId))
			revert CheckInterfaceNoMatch(type(IERC1155).interfaceId);
		return IERC1155(addr);
	}

	function onERC1155Received(
		address operator,
		address from,
		uint256 tokenId,
		uint256 value,
		bytes calldata data
	) external returns (bytes4) {
		IERC1155 token = asERC1155(_msgSender());
		// require(ad.meta.token == address(0), "#AssetShell.onERC1155Received mint of asset already exists");
		require(from != address(this));//, "#AssetShell.onERC1155Received from not for myself");

		address to;
		uint256 price;
		(to, price) = abi.decode(data, (address, uint256));

		uint256   id         = convertTokenID(address(token), tokenId);
		AssetData storage ad = _assetsData[id];

		if (ad.minimumPrice == 0)
			ad.minimumPrice = price;
		ad.meta.token = address(token);
		ad.meta.tokenId = tokenId;

		if (value > 0xffffffffffffffff) {
			revert MINTERC1155QuantityExceedsLimit();
		}
		_mint(to, id, value, "");

		return 0xf23a6e61;
	}

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) external returns (bytes4) {
		revert MethodNotImplemented();
	}

	function _safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data) internal virtual override
	{
		revert MethodNotImplemented();
	}

	/**
	 * @dev convertTokenID() convert meta token and token id to token id
	 */
	function convertTokenID(address metaToken, uint256 metaTokenId) pure public returns (uint256) {
		return uint256(keccak256(abi.encodePacked(metaToken, metaTokenId)));
	}

	/**
	 * @dev overwrite
	 */
	function uri(uint256 tokenId) public view virtual override(ERC1155,IERC1155MetadataURI) returns (string memory) {
		AssetID memory meta = assetMeta(tokenId);
		return IERC1155MetadataURI(meta.token).uri(meta.tokenId);
	}

	/**
	 * @dev assetMeta(tokenId) Returns the asset meta data of this tokenId
	 */
	function assetMeta(uint256 tokenId) view public override returns (AssetID memory meta) {
		meta = _assetsData[tokenId].meta;
		// require(meta.token != address(0), "#AssetShell.assetMeta asset non exists");
		if (meta.token == address(0)) revert AssetNonExistsInAssetShell();
	}

	/**
	 * @dev withdraw() withdraw and unlock meta asset
	 */
	function withdraw(uint256 tokenId, address owner, uint256 count) external override Check(Action_Asset_Shell_Withdraw) {
		AssetID storage meta = _assetsData[tokenId].meta;
		// require(meta.token != address(0), "#AssetShell#withdraw withdraw of asset non exists");
		if (meta.token == address(0)) revert AssetNonExistsInAssetShell();
		withdrawFrom(owner, owner, tokenId, count, "");
	}

	/**
	 * @dev withdrawFrom() implement withdraw and unlock meta asset, internal method
	 */
	function withdrawFrom(address from, address to, uint256 id, uint256 count, bytes memory data) internal {
		AssetID storage meta = _assetsData[id].meta;
		IERC1155(meta.token).safeTransferFrom(address(this), to, meta.tokenId, count, data);
		_burn(from, id, count);
	}

	/**
	 * @dev Returns the owner token locked total count and locked items length
	 */
	function lockedItems(uint256 tokenId, address owner) view public returns (uint256 items, uint64 total) {
		Locked storage locked = _assetsData[tokenId].locked[owner];
		items = locked.itemsKeys.length;
		total = locked.total;
	}

	/**
	 * @dev Returns the owner token locked count for index
	 */
	function lockedAt(uint256 tokenId, address owner, uint256 index) view public 
		returns (address previous, LockedItem memory item) 
	{
		Locked storage locked = _assetsData[tokenId].locked[owner];
		previous = locked.itemsKeys[index];
		item = locked.items[previous];
	}

	/**
	 * @dev Returns the owner token locked count and previous owner address
	 */
	function lockedOf(uint256 tokenId,address owner,address previous) view public returns (LockedItem memory item) {
		item = _assetsData[tokenId].locked[owner].items[previous];
	}

	/**
	 * @dev minimumPrice(tokenId) Returns the minimum price of this tokenId asset
	 */
	function minimumPrice(uint256 tokenId) view public returns (uint256) {
		return _assetsData[tokenId].minimumPrice;
	}

	/**
	 * @dev called after token transfer
	 */
	function _afterTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory counts,
		bytes memory data
	) internal virtual override {

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			AssetData storage asset = _assetsData[id];
			uint256 count = counts[i];

			if (asset.minimumPrice != 0) {
				if (from != address(0)) { // not mint
					if (balanceOf(from, id) < asset.locked[from].total) { // locaked
						revert NeedToUnlockAssetFirst();
					}
					if (to != address(0)) { // not burn
						Locked storage locked = asset.locked[to]; // locked to
						LockedItem storage item = locked.items[from];
						if (item.count != 0)
							revert NeedToUnlockAssetFirstForPreviousOwner();

						locked.total += uint64(count);
						item.index = uint64(locked.itemsKeys.length);
						item.count = uint64(count);
						item.blockNumber = uint64(block.number);
						locked.itemsKeys.push(from);

						_lastLocked = LockedID(id,to,from);
					}
				}
			}
		}
	}

	/**
	 * @dev _unlock() receive eth transaction and unlock asset
	 * @param amount eth value amount
	 * @param erc20 erc20 token for amount
	 */
	function _unlock(LockedID memory lock, address sender, uint256 amount, address erc20) private {
		AssetData storage asset  = _assetsData[lock.tokenId];
		Locked    storage locked = asset.locked[lock.owner];
		LockedItem storage item  = locked.items[lock.previous];
		uint256 count = item.count;

		if (item.count == 0) revert LockTokenIDValueEmptyInAssetShell();

		address to = lock.owner;
		uint256 price = amount * 10_000 / seller_fee_basis_points; // transfer price
		uint256 min_price = asset.minimumPrice * item.count; // minimum price

		// check transfer minimum price
		if (price < min_price) revert PayableInsufficientAmount();

		uint256 value = erc20 == address(0) ? amount: 0;

		_host.ledger().assetIncome{value: value}(
			address(this), lock.tokenId, sender, lock.previous, to, price, item.count, saleType, amount, erc20
		);

		if (_lastLocked.tokenId == lock.tokenId &&
			_lastLocked.owner == lock.owner && 
			_lastLocked.previous == lock.previous
		) {
			_lastLocked.tokenId = 0;
		}

		// unlock
		locked.total -= uint64(count);
		// delete key data
		if (item.index + 1 < locked.itemsKeys.length)
			locked.itemsKeys[item.index] = locked.itemsKeys[locked.itemsKeys.length - 1];
		locked.itemsKeys.pop(); // remove last key in keys
		delete locked.items[lock.previous];

		if (saleType == SaleType.kFirst) {
			bytes memory data = abi.encode(to, asset.minimumPrice);
			withdrawFrom(to, address(_host.module(Module_ASSET_Second_ID)), lock.tokenId, count, data);
		}
	}

	struct UnlockForOperator {
		LockedID lock;
		uint256  payValue; // value
		address  payBank; // erc20 contract address, weth
		address  payer;   // opensea contract => sender
	}

	/**
	 * @dev unlockForOperator()
	 */
	function unlockForOperator(UnlockForOperator[] calldata data) public {
		if (_host.unlockOperator() != msg.sender) {
			revert PermissionDeniedForOnlyUnlockOperator();
		}

		for (uint256 i = 0; i < data.length; i++) {
			UnlockForOperator memory it = data[i];
			_unlock(it.lock, it.payer, it.payValue, it.payBank);
		}
	}

	/**
	 * @dev unlock asset
	 */
	function unlock(LockedID memory lock) public payable {
		_unlock(lock, msg.sender, msg.value, address(0));
	}

	/**
	 * @dev receive eth token
	 */
	receive() external payable {
		_unlock(_lastLocked, msg.sender, msg.value, address(0)); // unlock last locked
	}

	/**
	 * @dev withdraw ERC20 token
	 * @param erc20 address
	 */
	function withdrawERC20(IERC20 erc20) public override {
		if (address(_host.ledger()) != msg.sender) revert("#AssetShell.withdrawERC20 access denied");
		uint256 balance = erc20.balanceOf(address(this));
		erc20.transfer(msg.sender, balance);
	}

	// --------------------------- test ---------------------------------

	// modifier _DisableReceiveUnlock() {
	// 	_IsDisableReceiveUnlock = true;
	// 	_;
	// 	_IsDisableReceiveUnlock = false;
	// }

	// function unlock2(uint256 tokenId, address owner, address previous) public payable { // test
	// 	LockedID memory lock;
	// 	lock.tokenId = tokenId;
	// 	lock.owner = owner;
	// 	lock.previous = previous;
	// 	unlock_(lock, msg.sender, msg.value);
	// }

	// function unlockForOperator2(
	// 	uint256 tokenId, address owner, address previous,
	// 	PayType  payType,
	// 	uint256  payValue, // value
	// 	address  payBank, // erc20 contract address
	// 	address  payer   // opensea contract => sender
	// ) public payable _DisableReceiveUnlock { // test
	// 	if (_host.unlockOperator() != msg.sender) {
	// 		revert PermissionDeniedForOnlyUnlockOperator();
	// 	}
	// 	LockedID memory lock;
	// 	lock.tokenId = tokenId;
	// 	lock.owner = owner;
	// 	lock.previous = previous;

	// 	uint256 value = msg.value;
	// 	if (payType == PayType.kDefault) {
	// 		if (value < payValue) revert PayableInsufficientAmount();
	// 		value -= payValue;
	// 		unlock_(lock, payer, payValue);
	// 	} else {
	// 		IWETH(payBank).withdraw(payValue);
	// 		if (address(this).balance < payValue ) revert PayableInsufficientAmountWETH();
	// 		unlock_(lock, payer, payValue);
	// 	}
	// }

	// function testWithdraw(address payBank, uint256 payValue) public _DisableReceiveUnlock {
	// 	IWETH(payBank).withdraw(payValue);
	// }

}
