// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

pragma experimental ABIEncoderV2;

import './Asset.sol';

contract AssetShell is AssetBase, IAssetShell {
	using Address for address;

	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

	mapping(uint256 => AssetID) private _assetsMeta;   // tokenId => raw asset id
	mapping(uint256 => uint256) private _minimumPrices; // tokenId => minimum price

	struct Locked {
		address from;
		address to;
		uint256 tokenId;
	}

	Locked    public locked;
	SaleType  public saleType; // is opensea first or second sale
	bool      private _RollBACK;

	function initAssetShell(address host, address operator, SaleType _saleType, InitContractURI memory uri) external {
		initAssetBase(host, operator, uri);
		_registerInterface(AssetShell_Type);
		_registerInterface(_ERC721_RECEIVED);
		saleType = _saleType;
		_RollBACK = false;
	}

	// @dev convert addr to standard ERC721 NFT,will be revered if add is invalid.
	function checkERC721(address addr, bytes4 id, string memory message) view internal returns (IERC721) {
		require(addr.isContract(), "#AssetShell#asERC721: INVLIAD_CONTRACT_ADDRESS");
		IERC165_1(addr).checkInterface(id, message);
		return IERC721(addr);
	}

	function asERC721(address addr) view internal returns (IERC721) {
		return checkERC721(addr, _INTERFACE_ID_ERC721, "#AssetShell#asERC721 The NFT contract has an invalid ERC721 implementation");
	}

	function onERC721Received(
		address operator, address from, uint256 tokenId, bytes memory data
	) external override returns (bytes4) {
		IERC721 token = asERC721(_msgSender());
		uint256 id = convertTokenID(address(token), tokenId);
		AssetID storage asset = _assetsMeta[id];

		address to;
		uint256 minimumPrice;

		(to,minimumPrice) = abi.decode(data, (address, uint256));

		require(asset.token == address(0), "#AssetShell#onERC721Received mint of asset already exists");
		require(from != address(this), "#AssetShell#onERC721Received from not for myself");

		asset.token = address(token);
		asset.tokenId = tokenId;
		_minimumPrices[id] = minimumPrice;

		_mint(from, id);

		return _ERC721_RECEIVED;
	}

	/**
	 * @dev convertTokenID() convert meta token and token id to token id
	 */
	function convertTokenID(address metaToken, uint256 metaTokenId) pure public returns (uint256) {
		return uint256(keccak256(abi.encodePacked(metaToken, metaTokenId)));
	}

	function _tokenURI(uint256 tokenId) internal view override returns (string memory) {
		AssetID memory id = assetMeta(tokenId);
		return IERC721Metadata(id.token).tokenURI(id.tokenId);
	}

	/**
	 * @dev assetMeta(tokenId) Returns the asset meta data of this tokenId
	 */
	function assetMeta(uint256 tokenId) view public override returns (AssetID memory asset) {
		asset = _assetsMeta[tokenId];
		require(asset.token != address(0), "#AssetShell#assetMeta asset non exists");
	}

	/**
	 * @dev withdraw() withdraw and unlock meta asset
	 */
	function withdraw(uint256 tokenId) external override Check(Action_Asset_Shell_Withdraw) {
		AssetID storage asset = _assetsMeta[tokenId];
		require(asset.token != address(0), "#AssetShell#withdraw withdraw of asset non exists");
		withdrawTo(tokenId, ownerOf(tokenId), "");
	}

	function withdrawTo(uint256 tokenId, address to, bytes memory data) internal {
		AssetID storage asset = _assetsMeta[tokenId];
		IERC721(asset.token).safeTransferFrom(address(this), to, asset.tokenId, data);
		delete _assetsMeta[tokenId];
		delete _minimumPrices[tokenId];
		_burn(tokenId);
	}

	/**
	 * @dev minimumPrice(tokenId) Returns the minimum price of this tokenId asset
	 */
	function minimumPrice(uint256 tokenId) view public returns (uint256) {
		return _minimumPrices[tokenId];
	}

	function _afterTokenTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override {
		if (_RollBACK) return;

		if (locked.tokenId != 0) { // RollBACK last transfer action
			require(tokenId != locked.tokenId, "#AssetShell#_beforeTokenTransfer The transfer has been blocked");
			_RollBACK = true;
			_safeTransfer(locked.to, locked.from, locked.tokenId, "");
			_RollBACK = false;
		}

		if (from != address(0) && to != address(0)) {
			// lock asset
			locked.from = from;
			locked.to = to;
			locked.tokenId = tokenId;

			if (msg.value != 0) {
				_receive(); // receive eth
			}
		}
	}

	/**
	 * @dev _receive() receive eth transaction collection
	 */
	function _receive() private {
		// require(locked.tokenId != 0, "#AssetShell#receive locked.tokenId != 0");
		if (locked.tokenId == 0) return;
		require(msg.value != 0, "#AssetShell#_receive msg.value != 0"); // price

		address to      = locked.to;
		uint256 tokenId = locked.tokenId;
		uint256 price = msg.value * 10_000 / seller_fee_basis_points; // transfer price

		// check transfer price
		require(price >= _minimumPrices[tokenId], "#AssetShell#_receive price >= minimum price"); // price

		AssetID memory asset = assetMeta(tokenId);
		_host.ledger().assetIncome{value: msg.value}(asset.token, asset.tokenId, msg.sender, to, price, saleType);

		Locked memory tmp;
		locked = tmp; // unlock

		if (saleType == SaleType.kFirst) {
			bytes memory data = abi.encode(to, _minimumPrices[tokenId]);
			withdrawTo(tokenId, address(_host.module(Module_ASSET_Second_ID)), data);
		}
	}

	receive() external payable {
		_receive();
	}
}
