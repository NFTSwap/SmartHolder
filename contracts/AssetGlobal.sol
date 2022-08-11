
pragma solidity >=0.6.0 <=0.8.15;

pragma experimental ABIEncoderV2;

import "./Department.sol";
import "./ERC721.sol";

contract AssetGlobal is IAssetGlobal, ERC721 {

	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
	bytes4 private constant _ERC721_LOCK_RECEIVED = 0x7e154325;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
	bytes4 private constant _INTERFACE_ID_ERC721_LOCK = 0x473eac90;

	string private _contractURI;// = "https://smart-dao.stars-mine.com/service-api/utils/getOpenseaContractJSON?";

	mapping(uint256 => AssetID) private _assetsMeta;

	function initAssetGlobal(address host, string memory description, address operator, string memory contractURI) external {
		initERC721(host, description, operator);
		_registerInterface(AssetGlobal_ID);
		_registerInterface(_ERC721_RECEIVED);
		_registerInterface(_ERC721_LOCK_RECEIVED);
		_contractURI = contractURI;
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
		uint256 id = convertTokenID(address(token), tokenId);
		AssetID storage asset = _assetsMeta[id];
		require(asset.token == address(0), "#AssetGlobal#onERC721Received mint of asset already exists");
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
		uint256 id = convertTokenID(address(token), tokenId);
		AssetID storage asset = _assetsMeta[id];
		require(asset.token == address(0), "#AssetGlobal#onERC721LockReceived mint of asset already exists");
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
			require(asset.token != address(0), "#AssetGlobal#_beforeTokenTransfer transfer of asset non exists");
			if (asset.kind == Kind.Lock) {
				IERC721(asset.token).safeTransferFrom(from, to, asset.tokenId, _data);
			}
		}
	}

	function convertTokenID(address metaToken, uint256 metaTokenId) pure public returns (uint256) {
		return uint256(keccak256(abi.encodePacked(metaToken, metaTokenId)));
	}

	function _tokenURI(uint256 tokenId) internal view override returns (string memory) {
		AssetID memory id = assetMeta(tokenId);
		return IERC721Metadata(id.token).tokenURI(id.tokenId);
	}

	function assetMeta(uint256 tokenId) view public override returns (AssetID memory) {
		AssetID storage asset = _assetsMeta[tokenId];
		require(asset.token != address(0), "#AssetGlobal#unlock unlock of asset non exists");
		return asset;
	}

	function unlock(address metaToken, uint256 metaTokenId) external override {
		uint256 id = convertTokenID(metaToken, metaTokenId);
		AssetID storage asset = _assetsMeta[id];
		require(asset.token != address(0), "#AssetGlobal#unlock unlock of asset non exists");
		IERC721Lock(asset.token).lock(address(0), asset.tokenId, "");
		delete _assetsMeta[id];
		_burn(id);
	}

	function withdraw(uint256 tokenId) external override {
		AssetID storage asset = _assetsMeta[tokenId];
		require(asset.token != address(0), "#AssetGlobal#withdraw withdraw of asset non exists");
		require(asset.kind == Kind.Owner, "#AssetGlobal#withdraw withdraw of asset kind no match");
		address owner = ownerOf(tokenId);
		IERC721(asset.token).safeTransferFrom(address(this), owner, asset.tokenId);
		delete _assetsMeta[tokenId];
		_burn(tokenId);
	}

	function contractURI() public view returns (string memory) {
		/*{
			"name": "OpenSea Creatures",
			"description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
			"image": "external-link-url/image.png",
			"external_link": "external-link-url",
			"seller_fee_basis_points": 100, # Indicates a 1% seller fee.
			"fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
		}*/

		return _contractURI;
	}

	function setContractURI(string memory uri) public {
		_contractURI = uri;
	}

}
