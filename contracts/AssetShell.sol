
pragma solidity >=0.6.0 <=0.8.15;

pragma experimental ABIEncoderV2;

import "./Department.sol";
import "./ERC721.sol";

contract AssetShell is IAssetShell, ERC721 {

	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

	mapping(uint256 => AssetID) private _assetsMeta;

	/*{
		"name": "OpenSea Creatures",
		"description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
		"image": "external-link-url/image.png",
		"external_link": "external-link-url",
		"seller_fee_basis_points": 100, # Indicates a 1% seller fee.
		"fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
	}*/
	string public contractURI;// = "https://smart-dao.stars-mine.com/service-api/utils/getOpenseaContractJSON?";

	TokenTransfer public lastTransfer;

	function initAssetShell(address host, string memory description, address operator, string memory _contractURI) external {
		initERC721(host, description, operator);
		_registerInterface(AssetShell_ID);
		_registerInterface(_ERC721_RECEIVED);
		contractURI = _contractURI;
	}

	function setContractURI(string memory _contractURI) public {
		contractURI = _contractURI;
	}

	// @dev convert addr to standard ERC721 NFT,will be revered if add is invalid.
	function checkERC721(address addr, bytes4 id, string memory message) internal returns (IERC721) {
		require(addr.isContract(), "#AssetShell#asERC721: INVLIAD_CONTRACT_ADDRESS");
		require(IERC721(addr).supportsInterface(id), message);
		return IERC721(addr);
	}

	function asERC721(address addr) internal returns (IERC721) {
		return checkERC721(addr, _INTERFACE_ID_ERC721, "#AssetShell#asERC721 The NFT contract has an invalid ERC721 implementation");
	}

	function onERC721Received(
		address operator, address from, uint256 tokenId, bytes memory data
	) external override returns (bytes4) {
		IERC721 token = asERC721(_msgSender());
		uint256 id = convertTokenID(address(token), tokenId);
		AssetID storage asset = _assetsMeta[id];

		if (from == address(0)) { // mint
			from = abi.decode(data, (address));
		}
		require(asset.token == address(0), "#AssetShell#onERC721Received mint of asset already exists");
		require(from != address(this), "#AssetShell#onERC721Received from not for myself");

		asset.token = address(token);
		asset.tokenId = tokenId;

		_mint(from, id);

		return _ERC721_RECEIVED;
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
		require(asset.token != address(0), "#AssetShell#assetMeta asset non exists");
		return asset;
	}

	function withdraw(uint256 tokenId) external override OnlyDAO {
		AssetID storage asset = _assetsMeta[tokenId];
		require(asset.token != address(0), "#AssetShell#withdraw withdraw of asset non exists");
		address owner = ownerOf(tokenId);
		IERC721(asset.token).safeTransferFrom(address(this), owner, asset.tokenId);
		delete _assetsMeta[tokenId];
		_burn(tokenId);
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override {
		require(lastTransfer.tokenId == 0, "#AssetShell#_beforeTokenTransfer lastTransfer.tokenId == 0");
		if (from == address(0) || to == address(0)) return;
		lastTransfer.from = from;
		lastTransfer.to = to;
		lastTransfer.blockNumber = block.number;
		lastTransfer.tokenId = tokenId;
	}

	receive() external payable {
		require(lastTransfer.tokenId != 0, "#AssetShell#receive lastTransfer.tokenId != 0");
		require(msg.value != 0, "#AssetShell#receive msg.value != 0"); // check price
		lastTransfer.tokenId = 0;
	}

}
