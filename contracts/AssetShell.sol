// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

pragma experimental ABIEncoderV2;

import './Asset.sol';

contract AssetShell is ERC721_Module, IAssetShell {
	using Address for address;

	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

	mapping(uint256 => AssetID) private _assetsMeta;

	struct TokenTransfer {
		address from;
		address to;
		uint256 blockNumber;
		uint256 tokenId;
	}

	TokenTransfer public lastTransfer;
	SaleType public saleType; // is opensea first or second sale

	/*{
		"name": "OpenSea Creatures",
		"description": "OpenSea Creatures are adorable aquatic beings primarily for \
		demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
		"image": "external-link-url/image.png",
		"external_link": "external-link-url",
		"seller_fee_basis_points": 100, # Indicates a 1% seller fee.
		"fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
	}*/
	string public contractURI;// = "https://smart-dao.stars-mine.com/service-api/utils/getOpenseaContractJSON?";

	function initAssetShell(
		address host,      string memory name,          string memory description,
		address operator,  string memory _contractURI,  SaleType _saleType
	) external {
		initModule(host, description, operator);
		initERC721(name, name);
		_registerInterface(AssetShell_Type);
		_registerInterface(_ERC721_RECEIVED);
		contractURI = _contractURI;
		saleType = _saleType;
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

		if (data.length != 0) { // mint or withdrawTo
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

	function assetMeta(uint256 tokenId) view public override returns (AssetID memory asset) {
		asset = _assetsMeta[tokenId];
		require(asset.token != address(0), "#AssetShell#assetMeta asset non exists");
	}

	function withdraw(uint256 tokenId) external override OnlyDAO {
		AssetID storage asset = _assetsMeta[tokenId];
		require(asset.token != address(0), "#AssetShell#withdraw withdraw of asset non exists");
		withdrawTo(tokenId, ownerOf(tokenId), "");
	}

	function withdrawTo(uint256 tokenId, address to, bytes memory data) internal {
		AssetID storage asset = _assetsMeta[tokenId];
		IERC721(asset.token).safeTransferFrom(address(this), to, asset.tokenId, data);
		delete _assetsMeta[tokenId];
		_burn(tokenId);
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override {
		if (from == address(0) || to == address(0)) return;
		if (lastTransfer.tokenId != 0) {
			revert(string(abi.encodePacked("#AssetShell#_beforeTokenTransfer lastTransfer.tokenId == 0, from=", from, 
				",to=", to,
				",tokenId=", tokenId
			)));
		}
		lastTransfer.from = from;
		lastTransfer.to = to;
		lastTransfer.blockNumber = block.number;
		lastTransfer.tokenId = tokenId;
	}

	receive() external payable {
		require(msg.value != 0, "#AssetShell#receive msg.value != 0"); // price
		require(lastTransfer.tokenId != 0, "#AssetShell#receive lastTransfer.tokenId != 0");
		AssetID memory asset = assetMeta(lastTransfer.tokenId);
		_host.ledger().assetIncome{value: msg.value}(lastTransfer.to, asset.token, asset.tokenId, msg.sender, saleType);
		if (saleType == SaleType.kOpenseaFirst) {
			bytes memory data = abi.encode(lastTransfer.to);
			withdrawTo(lastTransfer.tokenId, address(_host.module(Module_OPENSEA_Second_ID)), data);
		}
		lastTransfer.tokenId = 0;
	}
}
