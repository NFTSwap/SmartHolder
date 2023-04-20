// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

pragma experimental ABIEncoderV2;

import './libs/Errors.sol';
import './libs/ERC721.sol';
import './Asset.sol';

contract AssetShell is AssetModule, ERC1155, IAssetShell {
	using Address for address;

	struct Locked {
		uint256                     value;
		mapping(address => uint256) previousOwners; // previous asset owner address => value
	}

	struct LockedID {
		uint256 tokenId;
		address owner;
		address previousOwner;
	}

	struct AssetData {
		AssetID meta; // asset meta data
		uint256 minimumPrice; // Minimum transaction price of assets
		mapping(address => Locked) locked; // owner => Locked
	}

	mapping(uint256 => AssetData) private _assetsData;   // tokenId => raw asset id
	LockedID                      private _lastLocked;
	SaleType                      public  saleType; // is opensea first or second sale
	uint256[16]                   private  __; // reserved storage space

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns (bool) {
		return ERC1155.supportsInterface1155(interfaceId) || ERC165.supportsInterface(interfaceId);
	}

	function initAssetShell(address host, address operator, SaleType _saleType, InitContractURI memory uri) external {
		initAssetModule(host, operator, uri);
		_registerInterface(AssetShell_Type);
		saleType = _saleType;
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

	/**
	 * @dev convertTokenID() convert meta token and token id to token id
	 */
	function convertTokenID(address metaToken, uint256 metaTokenId) pure public returns (uint256) {
		return uint256(keccak256(abi.encodePacked(metaToken, metaTokenId)));
	}

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
	function withdraw(uint256 tokenId, address owner, uint256 amount) external override Check(Action_Asset_Shell_Withdraw) {
		AssetID storage meta = _assetsData[tokenId].meta;
		// require(meta.token != address(0), "#AssetShell#withdraw withdraw of asset non exists");
		if (meta.token == address(0)) revert AssetNonExistsInAssetShell();
		withdrawFrom(owner, owner, tokenId, amount, "");
	}

	/**
	 * @dev withdrawFrom() implement withdraw and unlock meta asset, internal method
	 */
	function withdrawFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal {
		AssetID storage meta = _assetsData[id].meta;
		IERC1155(meta.token).safeTransferFrom(address(this), to, meta.tokenId, amount, data);
		_burn(from, id, amount);
	}

	/**
	 * @dev Returns whether the token is locked
	 */
	function lockedOf(uint256 tokenId, address owner) view public returns (uint256) {
		return _assetsData[tokenId].locked[owner].value;
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
		uint256[] memory amounts,
		bytes memory data
	) internal virtual override {

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			AssetData storage ad = _assetsData[id];
			uint256 amount = amounts[i];

			if (ad.minimumPrice != 0) {
				if (from != address(0)) { // not mint
					if (amount > balanceOf(from, id) - ad.locked[from].value) { // locaked
						revert NeedToUnlockAssetFirst();
					}
					if (to != address(0)) { // not burn
						ad.locked[to].value += amount;
						ad.locked[to].previousOwners[from] = amount;
						_lastLocked = LockedID(id,to,from);
					}
				}
			}
		}
	}

	/**
	 * @dev unlock() receive eth transaction and unlock asset
	 */
	function unlock(LockedID memory id) public payable {
		// require(tokenId != 0, "#AssetShell#unlock locked tokenId != 0");
		if (id.tokenId == 0) revert TokenIDEmpty();
		// require(msg.value != 0, "#AssetShell#unlock msg.value != 0"); // price
		if (msg.value == 0) revert PayableAmountZero();
		// require(ad.locked != address(0), "#AssetShell#unlock Lock cannot be empty"); // price
		if (id.owner == address(0)) revert LockTokenIDEmptyInAssetShell();
		if (id.previousOwner == address(0)) revert LockTokenIDPreviousOwnerEmptyInAssetShell();

		AssetData storage ad = _assetsData[id.tokenId];
		Locked storage locked = ad.locked[id.owner];
		uint256 value = locked.previousOwners[id.previousOwner];

		address to = id.owner;
		uint256 price = msg.value * 10_000 / seller_fee_basis_points; // transfer price
		uint256 min_price = ad.minimumPrice * value; // minimum price

		// check transfer price
		// require(amount >= ad.minimumPrice, "#AssetShell#unlock price >= minimum price"); // price
		if (price < min_price) revert PayableInsufficientAmount();

		AssetID storage meta = ad.meta;
		_host.ledger().assetIncome{value: msg.value}(
			meta.token, meta.tokenId, msg.sender, id.previousOwner, to, price, value, saleType
		);

		if (_lastLocked.tokenId == id.tokenId &&
			_lastLocked.owner == id.owner && 
			_lastLocked.previousOwner == id.previousOwner
		) {
			_lastLocked.tokenId = 0;
		}

		// unlock
		locked.value -= value;
		delete locked.previousOwners[id.previousOwner];

		if (saleType == SaleType.kFirst) {
			bytes memory data = abi.encode(to, ad.minimumPrice);
			withdrawFrom(to, address(_host.module(Module_ASSET_Second_ID)), id.tokenId, value, data);
		}
	}

	/**
	 * @dev receive eth token
	 */
	receive() external payable {
		unlock(_lastLocked); // unlock last locked
	}
}
