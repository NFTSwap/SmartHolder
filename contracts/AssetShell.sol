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

	function name() public view override(AssetModule,ERC721,IERC721Metadata)  returns (string memory) {
		return AssetModule.name();
	}
	function _registerInterface721(bytes4 interfaceId) internal virtual override {
		ERC165._registerInterface(interfaceId);
	}

	function initAssetShell(address host, address operator, SaleType _saleType, InitContractURI memory uri) external {
		initAssetModule(host, operator, uri);
		_registerInterface(AssetShell_Type);
		saleType = _saleType;
	}

	function asERC1155(address addr) view internal returns (IERC721) {
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
		uint256 id = convertTokenID(address(token), tokenId);
		AssetData storage ad = _assetsData[id];

		address to;
		uint256 price;
		(to, price) = abi.decode(data, (address, uint256));

		require(ad.meta.token == address(0), "");//, "#AssetShell.onERC1155Received mint of asset already exists");
		require(from != address(this), "");//, "#AssetShell.onERC1155Received from not for myself");

		ad.meta.token = address(token);
		ad.meta.tokenId = tokenId;
		ad.minimumPrice = price;

		_mint(to, id);

		return 0xf23a6e61;
	}

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) external returns (bytes4) {
		return 0xbc197c81;
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
	function withdraw(uint256 tokenId) external override Check(Action_Asset_Shell_Withdraw) {
		// AssetID storage meta = _assetsData[tokenId].meta;
		// // require(meta.token != address(0), "#AssetShell#withdraw withdraw of asset non exists");
		// if (meta.token == address(0)) revert AssetNonExistsInAssetShell();
		// withdrawTo(tokenId, ownerOf(tokenId), "");
	}

	/**
	 * @dev withdrawTo() implement withdraw and unlock meta asset, internal method
	 */
	function withdrawTo(uint256 tokenId, address to, bytes memory data) internal {
		// AssetID storage meta = _assetsData[tokenId].meta;
		// IERC721(meta.token).safeTransferFrom(address(this), to, meta.tokenId, data);
		// delete _assetsData[tokenId]; // delete asset data
		// _burn(tokenId);
	}

	/**
	 * @dev Returns whether the token is locked
	 */
	function isLocked(uint256 tokenId) view public returns (bool) {
		return _assetsData[tokenId].locked != address(0);
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
	function _afterTokenTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override {
		AssetData storage ad = _assetsData[tokenId];

		if (ad.locked != address(0)) { //  transfer out from the exchange
			// Non contract transfer out needs to be unlocked first and the last lock cannot be a contract
			// require(!ad.locked.isContract(), "#AssetShell#_afterTokenTransfer 1 You need to unlock the asset first");
			if (ad.locked.isContract()) revert NeedToUnlockAssetFirst();
			//require(from.isContract(), "#AssetShell#_afterTokenTransfer 2 You need to unlock the asset first");
			if (!from.isContract()) revert NeedToUnlockAssetFirst();
		}
		ad.locked = from; // lock asset
		_lastLocked = tokenId;
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
		// require(value != 0);

		address to = id.owner;//ownerOf(id.tokenId);
		uint256 amount = msg.value * 10_000 / seller_fee_basis_points; // transfer price
		uint256 price = ad.minimumPrice * value; // minimum price

		// check transfer price
		// require(amount >= ad.minimumPrice, "#AssetShell#unlock price >= minimum price"); // price
		if (amount < price) revert PayableInsufficientAmount();

		AssetID storage meta = ad.meta;
		_host.ledger().assetIncome{value: msg.value}(meta.token, meta.tokenId, msg.sender, to, amount, saleType);

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
			withdrawTo(id.tokenId, address(_host.module(Module_ASSET_Second_ID)), data);
		}
	}

	/**
	 * @dev receive eth token
	 */
	receive() external payable {
		unlock(_lastLocked); // unlock last locked
	}
}
