// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

pragma experimental ABIEncoderV2;

import './Asset.sol';

contract AssetShell is AssetBase, IAssetShell {
	using Address for address;

	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

	struct AssetData {
		AssetID meta; // asset meta data
		uint256 minimumPrice; // Minimum transaction price of assets
		address locked; // Previous asset owner address
	}

	mapping(uint256 => AssetData) private _assetsData;   // tokenId => raw asset id
	uint256                       private _lastLocked;
	SaleType                      public  saleType; // is opensea first or second sale

	function initAssetShell(address host, address operator, SaleType _saleType, InitContractURI memory uri) external {
		initAssetBase(host, operator, uri);
		_registerInterface(AssetShell_Type);
		_registerInterface(_ERC721_RECEIVED);
		saleType = _saleType;
	}

	/**
	 * @dev convert addr to standard ERC721 NFT,will be revered if add is invalid.
	 */ 
	function checkERC721(address addr, bytes4 id, string memory message) view internal returns (IERC721) {
		require(addr.isContract(), "#AssetShell#asERC721: INVLIAD_CONTRACT_ADDRESS");
		IERC165_1(addr).checkInterface(id, message);
		return IERC721(addr);
	}

	function asERC721(address addr) view internal returns (IERC721) {
		return checkERC721(addr, _INTERFACE_ID_ERC721, "#AssetShell#asERC721 The NFT contract has an invalid ERC721 implementation");
	}

	/**
	 * @dev implement ERC721 asset receiving agreement
	 */
	function onERC721Received(
		address operator, address from, uint256 tokenId, bytes memory data
	) external override returns (bytes4) {
		IERC721 token = asERC721(_msgSender());
		uint256 id = convertTokenID(address(token), tokenId);
		AssetData storage ad = _assetsData[id];

		address to;
		uint256 price;

		(to,price) = abi.decode(data, (address, uint256));

		require(ad.meta.token == address(0), "#AssetShell#onERC721Received mint of asset already exists");
		require(from != address(this), "#AssetShell#onERC721Received from not for myself");

		ad.meta.token = address(token);
		ad.meta.tokenId = tokenId;
		ad.minimumPrice = price;

		_mint(to, id);

		return _ERC721_RECEIVED;
	}

	/**
	 * @dev convertTokenID() convert meta token and token id to token id
	 */
	function convertTokenID(address metaToken, uint256 metaTokenId) pure public returns (uint256) {
		return uint256(keccak256(abi.encodePacked(metaToken, metaTokenId)));
	}

	function _tokenURI(uint256 tokenId) internal view override returns (string memory) {
		AssetID memory meta = assetMeta(tokenId);
		return IERC721Metadata(meta.token).tokenURI(meta.tokenId);
	}

	/**
	 * @dev assetMeta(tokenId) Returns the asset meta data of this tokenId
	 */
	function assetMeta(uint256 tokenId) view public override returns (AssetID memory meta) {
		meta = _assetsData[tokenId].meta;
		require(meta.token != address(0), "#AssetShell#assetMeta asset non exists");
	}

	/**
	 * @dev withdraw() withdraw and unlock meta asset
	 */
	function withdraw(uint256 tokenId) external override Check(Action_Asset_Shell_Withdraw) {
		AssetID storage meta = _assetsData[tokenId].meta;
		require(meta.token != address(0), "#AssetShell#withdraw withdraw of asset non exists");
		withdrawTo(tokenId, ownerOf(tokenId), "");
	}

	/**
	 * @dev withdrawTo() implement withdraw and unlock meta asset, internal method
	 */
	function withdrawTo(uint256 tokenId, address to, bytes memory data) internal {
		AssetID storage meta = _assetsData[tokenId].meta;
		IERC721(meta.token).safeTransferFrom(address(this), to, meta.tokenId, data);
		delete _assetsData[tokenId]; // delete asset data
		_burn(tokenId);
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
			require(!ad.locked.isContract(), "#AssetShell#_afterTokenTransfer 1 You need to unlock the asset first");
			require(from.isContract(), "#AssetShell#_afterTokenTransfer 2 You need to unlock the asset first");
		}
		ad.locked = from; // lock asset
		_lastLocked = tokenId;
	}

	/**
	 * @dev unlock() receive eth transaction and unlock asset
	 */
	function unlock(uint256 tokenId) public payable {
		require(tokenId != 0, "#AssetShell#unlock locked tokenId != 0");
		require(msg.value != 0, "#AssetShell#unlock msg.value != 0"); // price

		AssetData storage ad = _assetsData[tokenId];
		require(ad.locked != address(0), "#AssetShell#unlock Lock cannot be empty"); // price

		address to = ownerOf(tokenId);
		uint256 price = msg.value * 10_000 / seller_fee_basis_points; // transfer price

		// check transfer price
		require(price >= ad.minimumPrice, "#AssetShell#unlock price >= minimum price"); // price

		AssetID storage meta = ad.meta;
		_host.ledger().assetIncome{value: msg.value}(meta.token, meta.tokenId, msg.sender, to, price, saleType);

		if (_lastLocked == tokenId)
			_lastLocked = 0;

		ad.locked = address(0); // unlock

		if (saleType == SaleType.kFirst) {
			bytes memory data = abi.encode(to, ad.minimumPrice);
			withdrawTo(tokenId, address(_host.module(Module_ASSET_Second_ID)), data);
		}
	}

	/**
	 * @dev receive eth token
	 */
	receive() external payable {
		unlock(_lastLocked); // unlock last locked
	}
}
