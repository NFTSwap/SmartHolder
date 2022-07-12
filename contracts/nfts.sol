
pragma solidity ^0.8.15;

import "./erc721.sol";

contract NFTs is ERC721 {

	function initNFTs() external {
			initERC721("NFTs", "NFTs");
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

	function exists(uint256 tokenId) public returns (bool) {
		return _exists(tokenId);
	}

	function isApprovedOrOwner(address spender, uint256 tokenId) public returns (bool) {
		return _isApprovedOrOwner(spender, tokenId);
	}

}
