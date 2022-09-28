
pragma solidity >=0.6.0 <=0.8.15;

import "./ERC721.sol";
import "./ERC165.sol";

contract NFTs is ERC165, ERC721_IMPL {

	function initNFTs() external {
		initERC165();
		initERC721_IMPL("NFTs", "NFTs");
	}

	function mint(uint256 tokenId) public {
		_mint(msg.sender, tokenId);
	}

	function safeMintURI(address to, uint256 tokenId, string memory _tokenURI, bytes memory _data) public {
		_safeMint(to, tokenId, _data);
		_setTokenURI(tokenId, _tokenURI);
	}

	function safeMint(address to, uint256 tokenId, bytes memory _data) public {
		_safeMint(to, tokenId, _data);
	}

	function burn(uint256 tokenId) public {
		_burn(tokenId);
	}

	function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
		require(ownerOf(tokenId) == _msgSender(), "#NFTs#setTokenURI: owner no match");
		_setTokenURI(tokenId, _tokenURI);
	}

	function setBaseURI(string memory baseURI_) public {
		_setBaseURI(baseURI_);
	}

	function exists(uint256 tokenId) view public returns (bool) {
		return _exists(tokenId);
	}

	function isApprovedOrOwner(address spender, uint256 tokenId) view public returns (bool) {
		return _havePermission(spender, tokenId);
	}

	function _msgSender() internal view virtual override(Initializable,ERC721_IMPL) returns (address) {
		return Initializable._msgSender();
	}

	function _msgData() internal view virtual override(Initializable,ERC721_IMPL) returns (bytes memory) {
		return Initializable._msgData();
	}

	function _registerInterface(bytes4 interfaceId) internal virtual override(ERC165,ERC721_IMPL) {
		ERC165._registerInterface(interfaceId);
	}

}
