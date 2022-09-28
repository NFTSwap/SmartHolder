
pragma solidity >=0.6.12 <=0.8.15;

import "./ERC721.sol";

contract Asset is IAsset, ERC721 {

	/*{
		"name": "OpenSea Creatures",
		"description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
		"image": "external-link-url/image.png",
		"external_link": "external-link-url",
		"seller_fee_basis_points": 100, # Indicates a 1% seller fee.
		"fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
	}*/
	string public contractURI;// = "https://smart-dao.stars-mine.com/service-api/utils/getOpenseaContractJSON?";

	function initAsset(address host, string memory description, address operator, string memory _contractURI) external {
		initERC721(host, description, operator);
		_registerInterface(Asset_ID);
		contractURI = _contractURI;
	}

	function setContractURI(string memory _contractURI) public {
		contractURI = _contractURI;
	}

	function safeMint(address to, uint256 tokenId, string memory _tokenURI, address lock, bytes calldata _data) public {
		_safeMint(to, tokenId, _data);
		_setTokenURI(tokenId, _tokenURI);
	}

	function _burn(uint256 tokenId) internal virtual override {
		// NOOP
	}

	function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
		require(_havePermission(_msgSender(), tokenId), "#NFTs#setTokenURI: owner no match");
		_setTokenURI(tokenId, _tokenURI);
	}

}
