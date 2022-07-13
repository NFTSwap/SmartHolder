
pragma solidity ^0.8.15;

import "./department.sol";
import "./erc721.sol";

contract AssetGlobal is Department, ERC721, IERC721Receiver, IERC721LockReceiver {

	enum Kind { Lock,Owner }

	struct AssetID {
		address token;
		uint256 tokenId;
		Kind kind;
	}
	/*
	 * bytes4(keccak256('initAssetGlobal(address,string,address)')) == 0x711cc62c
	 */
	bytes4 public  constant ID = 0x711cc62c;
	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
	bytes4 private constant _ERC721_LOCK_RECEIVED = 0x7e154325;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
	bytes4 private constant _INTERFACE_ID_ERC721_LOCK = 0x473eac90;

	mapping(uint256 => AssetID) private _assetsMeta;

	function initAssetGlobal(address host, string memory info, address operator) external {
		initERC721(host, info, operator);
		_registerInterface(ID);
		_registerInterface(_ERC721_RECEIVED);
		_registerInterface(_ERC721_LOCK_RECEIVED);
	}

	// @dev convert addr to standard ERC721 NFT,will be revered if add is invalid.
	function checkERC721(address addr, bytes4 id, string memory message) internal returns (IERC721) {
		require(addr.isContract(), "#AssetGlobal#asERC721: INVLIAD_CONTRACT_ADDRESS");
		require(IERC721(addr).supportsInterface(id), message);
		return IERC721(addr);
	}

	function asERC721(address addr) internal returns (IERC721) {
		return checkERC721(addr, _INTERFACE_ID_ERC721, "#AssetGlobal#asERC721 The NFT contract has an invalid ERC721 implementation");
	}

	function asERC721Lock(address addr) internal returns (IERC721) {
		return checkERC721(addr, _INTERFACE_ID_ERC721_LOCK, "#AssetGlobal#asERC721Lock The NFT contract has an invalid ERC721 Lock implementation");
	}

	function onERC721Received(
		address operator, address from, uint256 tokenId, bytes memory data
	) external override returns (bytes4) {
		IERC721 token = asERC721(_msgSender());
		uint256 id = convertTokenID(token, tokenId);
		AssetID storage asset = _assetsMeta[id];
		require(!asset.token, "#AssetGlobal#onERC721Received mint of asset already exists");
		require(from != address(this), "#AssetGlobal#onERC721Received from not for myself");

		asset.token = address(token);
		asset.tokenId = tokenId;
		asset.kind = Kind.Owner;

		_mint(from, id);

		return _ERC721_RECEIVED;
	}

	function onERC721LockReceived(
		address operator, address from, uint256 tokenId, bytes memory data
	) external override returns (bytes4) {
		IERC721 token = asERC721Lock(_msgSender());
		uint256 id = convertTokenID(token, tokenId);
		AssetID storage asset = _assetsMeta[id];
		require(!asset.token, "#AssetGlobal#onERC721LockReceived mint of asset already exists");
		require(from != address(this), "#AssetGlobal#onERC721LockReceived from not for myself");

		asset.token = address(token);
		asset.tokenId = tokenId;
		asset.kind = Kind.Lock;

		_mint(from, id);

		return _ERC721_LOCK_RECEIVED;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override {
		if (from != address(0) && to != address(0)) {
			AssetID storage asset = _assetsMeta[tokenId];
			require(asset.token, "#AssetGlobal#_beforeTokenTransfer transfer of asset non exists");
			if (asset.kind == Kind.Lock) {
				IERC721(asset.token).safeTransferFrom(from, to, asset.tokenId, _data);
			}
		}
	}

	function convertTokenID(address metaToken, uint256 metaTokenId) view public returns (uint256) {
		return uint256(keccak256(abi.encodePacked(address(token), tokenId)));
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		AssetID memory id = assetMeta(tokenId);
		return IERC721Metadata(id.token).tokenURI(id.tokenId);
	}

	function assetMeta(uint256 tokenId) view private returns (AssetID memory) {
		AssetID storage asset = _assetsMeta[tokenId];
		require(asset.token, "#AssetGlobal#unlock unlock of asset non exists");
		return asset;
	}

	function unlock(address metaToken, uint256 metaTokenId) external {
		uint256 id = convertTokenID(metaToken, metaTokenId);
		require(_assetsMeta[tokenId].token, "#AssetGlobal#unlock unlock of asset non exists");
		IERC721Lock(asset.token).lock(address(0), asset.tokenId);
		delete _assetsMeta[id];
		_burn(id);
	}

	function withdraw(uint256 tokenId) external {
		AssetID storage asset = _assetsMeta[tokenId];
		require(asset.token, "#AssetGlobal#withdraw withdraw of asset non exists");
		require(asset.kind == Kind.Owner, "#AssetGlobal#withdraw withdraw of asset kind no match");
		address owner = ownerOf(tokenId);
		IERC721(asset.token).safeTransferFrom(address(this), ownerOf(tokenId), asset.tokenId);
		delete _assetsMeta[tokenId];
		_burn(id);
	}
}