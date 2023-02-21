// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../openzeppelin/contracts/utils/Strings.sol';
import './libs/StringsExp.sol';
import './Module.sol';
import './libs/ERC721.sol';

contract ERC721_Module is Module, ERC721 {
	function _registerInterface(bytes4 interfaceId) internal virtual override(ERC165,ERC721) {
		ERC165._registerInterface(interfaceId);
	}
}

contract AssetBase is ERC721_Module {
	using Strings for uint256;
	using Strings for address;
	using StringsExp for bytes;

	struct InitContractURI {
		string  name;
		string  description;
		string  image;
		string  external_link;
		uint32  seller_fee_basis_points;
		address fee_recipient;
		string  contractURIPrefix;
	}

	string  public image;
	string  public external_link;
	address public fee_recipient;
	uint32  public seller_fee_basis_points;

	/*{
		"name": "OpenSea Creatures",
		"description": "OpenSea Creatures are adorable aquatic beings primarily for \
			demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
		"image": "external-link-url/image.png",
		"external_link": "external-link-url",
		"seller_fee_basis_points": 100, # Indicates a 1% seller fee.
		"fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
	}*/
	string public contractURIPrefix;// = "https://smart-dao.stars-mine.com/service-api/utils/printJSON?";

	function initAssetBase(address host, address operator, InitContractURI memory uri) internal {
		initModule(host, uri.description, operator);
		initERC721(uri.name, uri.name);
		image = uri.image;
		external_link = uri.external_link;
		fee_recipient = uri.fee_recipient == address(0) ? address(this): uri.fee_recipient;
		seller_fee_basis_points = uri.seller_fee_basis_points;
		contractURIPrefix = uri.contractURIPrefix;
	}

	function contractURI() view public returns (string memory uri) {
		bytes memory a = abi.encodePacked("?name=0xs",                      bytes(name()).toHexString());
		bytes memory b = abi.encodePacked("&description=0xs",               bytes(_description).toHexString());
		bytes memory c = abi.encodePacked("&image=0xs",                     bytes(image).toHexString());
		bytes memory d = abi.encodePacked("&external_link=0xs",             bytes(external_link).toHexString());
		bytes memory e = abi.encodePacked("&seller_fee_basis_points=",       uint256(seller_fee_basis_points).toString());
		bytes memory f = abi.encodePacked("&fee_recipient=",                 fee_recipient.toHexString());
		uri = string(abi.encodePacked(contractURIPrefix, a, b, c, d, e, f));
	}

	function set_seller_fee_basis_points(uint32 value) external Check(Action_Asset_set_seller_fee_basis_points) {
		seller_fee_basis_points = value;
		emit Change(Change_Tag_Asset_set_seller_fee_basis_points, value);
	}

	function set_fee_recipient(address recipient) external OnlyDAO {
		fee_recipient = recipient;
		emit Change(Change_Tag_Asset_set_fee_recipient, uint160(recipient));
	}
}

contract Asset is AssetBase, IAsset {
	uint256[16] private  __; // reserved storage space

	function initAsset(address host, address operator, InitContractURI memory uri) external {
		initAssetBase(host, operator, uri);
		_registerInterface(Asset_Type);
	}

	function safeMint(address to, uint256 tokenId, string memory _tokenURI, bytes calldata _data) public Check(Action_Asset_SafeMint) {
		_safeMint(to, tokenId, _data);
		_setTokenURI(tokenId, _tokenURI);
	}

	function _burn(uint256 tokenId) internal virtual override {
		// NOOP
	}
}
