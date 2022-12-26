
pragma solidity >=0.6.0 <=0.8.15;

import './Department.sol';
import './libs/ERC721.sol';

contract ERC721_Department is Department, ERC721 {

	function initERC721_Department(
		address host, string memory description,
		string memory name, string memory symbol,
		address operator
	) internal {
		initDepartment(host, description, operator);
		initERC721(name, symbol);
	}

	function _msgSender() internal view virtual override(ERC721) returns (address) {
		return Initializable._msgSender();
	}

	function _msgData() internal view virtual override(ERC721) returns (bytes memory) {
		return Initializable._msgData();
	}

	function _registerInterface(bytes4 interfaceId) internal virtual override(ERC721) {
		ERC165._registerInterface(interfaceId);
	}

}

contract Asset is IAsset, ERC721_Department {

	/*{
		"name": "OpenSea Creatures",
		"description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
		"image": "external-link-url/image.png",
		"external_link": "external-link-url",
		"seller_fee_basis_points": 100, # Indicates a 1% seller fee.
		"fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
	}*/
	string public contractURI;// = "https://smart-dao.stars-mine.com/service-api/utils/getOpenseaContractJSON?";

	function initAsset(
		address host, string memory description, address operator,
		string memory _contractURI, string memory name
	) external {
		initERC721_Department(host, description, name, name, operator);
		_registerInterface(Asset_Type);
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
