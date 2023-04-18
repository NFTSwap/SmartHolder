// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import './Module.sol';
import './libs/Strings.sol';
import './libs/ERC1155.sol';

contract AssetModule is Module, IOpenseaContractURI {
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
		string  base_contract_uri;
		string  base_uri;
	}

	string  private name_;
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
	string public base_contract_uri;// = "https://smart-dao.stars-mine.com/service-api/utils/printJSON?";

	/**
		* @dev Gets the token name.
		* @return string representing the token name
		*/
	function name() public view virtual returns (string memory) {
		return name_;
	}

	function initAssetModule(address host, address operator, InitContractURI memory uri) internal {
		initModule(host, uri.description, operator);
		name_ = uri.name;
		image = uri.image;
		external_link = uri.external_link;
		fee_recipient = uri.fee_recipient == address(0) ? address(this): uri.fee_recipient;
		seller_fee_basis_points = uri.seller_fee_basis_points;
		base_contract_uri = uri.base_contract_uri;
	}

	function contractURI() view public override returns (string memory uri) {
		bytes memory a = abi.encodePacked("?name=0xs",                      bytes(name_).toHexString());
		bytes memory b = abi.encodePacked("&description=0xs",               bytes(_description).toHexString());
		bytes memory c = abi.encodePacked("&image=0xs",                     bytes(image).toHexString());
		bytes memory d = abi.encodePacked("&external_link=0xs",             bytes(external_link).toHexString());
		bytes memory e = abi.encodePacked("&seller_fee_basis_points=",      uint256(seller_fee_basis_points).toString());
		bytes memory f = abi.encodePacked("&fee_recipient=",                fee_recipient.toHexString());
		uri = string(abi.encodePacked(base_contract_uri, a, b, c, d, e, f));
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

contract Asset is AssetModule, ERC1155, IAsset {

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns (bool) {
		return ERC1155.supportsInterface1155(interfaceId) || ERC165.supportsInterface(interfaceId);
	}

	function initAsset(address host, address operator, InitContractURI memory uri) external {
		initAssetModule(host, operator, uri);
		initERC1155(uri.base_uri);
		_registerInterface(Asset_Type);
	}

	/**
	 * @dev make ERC721 NFT
	 */
	function safeMint(address to, uint256 id, string memory _tokenURI, bytes calldata _data) public Check(Action_Asset_SafeMint) {
		require(id % 2 == 0, "#Asset1155.safeMint ID must be an even number");
		require(!exists(id), "#Asset1155.safeMint ID already exists");
		_mint(to, id, 1, _data);
		_setURI(id, _tokenURI);
	}

	/**
	 * @dev make ERC1155 NFTs
	 */
	function makeNFTs(address to, uint256 id, uint256 amount, bytes calldata _data) public {
		require(id % 2 == 0, "#Asset1155.makeNFTs ID must be an even number");
		require(balanceOf(_msgSender(), id) == 1, "#Asset1155.makeNFTs No permission to create NFTs");
		_mint(to, id + 1, amount, _data);
	}

	function uri(uint256 id) public view virtual override(ERC1155,IERC1155MetadataURI) returns (string memory) {
		if (id % 2 == 0) {
			return ERC1155.uri(id); // 721
		} else {
			return ERC1155.uri(id - 1); // return 721 metadata URI
		}
	}

}