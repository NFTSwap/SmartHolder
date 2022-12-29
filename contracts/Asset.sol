// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './Module.sol';
import './libs/ERC721.sol';

contract ERC721_Module is Module, ERC721 {
	function _registerInterface(bytes4 interfaceId) internal virtual override(ERC165,ERC721) {
		ERC165._registerInterface(interfaceId);
	}
}

contract Asset is IAsset, ERC721_Module {

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
		address host, string memory name, string memory description, address operator,
		string memory _contractURI
	) external {
		initModule(host, description, operator);
		initERC721(name, name);
		_registerInterface(Asset_Type);
		contractURI = _contractURI;
	}

	function safeMint(address to, uint256 tokenId, string memory _tokenURI, bytes calldata _data) public Check(Action_Asset_SafeMint) {
		_safeMint(to, tokenId, _data);
		_setTokenURI(tokenId, _tokenURI);
	}

	function _burn(uint256 tokenId) internal virtual override {
		// NOOP
	}

}
