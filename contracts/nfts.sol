
pragma solidity >=0.6.0 <=0.8.15;

import "./erc721.sol";
import "./erc165.sol";

contract NFTs is ERC165, ERC721_Base {

	function initNFTs() external {
		initERC165();
		initERC721_Base("NFTs", "NFTs");
	}

	function mint(uint256 tokenId) public {
		_mint(msg.sender, tokenId);
	}

	function safeMintURI(address to, uint256 tokenId, string memory _tokenURI, bytes memory _data) public {
		_mint(msg.sender, tokenId);
		_setTokenURI(tokenId, _tokenURI);
		safeTransferFrom(msg.sender, to, tokenId, _data);
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
		return _isCanTransfer(spender, tokenId);
	}

	function _msgSender721() internal view virtual override returns (address) {
		return super._msgSender();
	}

	function _msgData721() internal view virtual override returns (bytes memory) {
		return super._msgData();
	}

	function _registerInterface721(bytes4 interfaceId) internal virtual override {
		super._registerInterface(interfaceId);
	}

}
