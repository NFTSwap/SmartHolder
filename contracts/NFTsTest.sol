
pragma solidity >=0.6.0 <=0.8.15;

import "./ERC721.sol";
import "./ERC165.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/utils/Strings.sol";

contract NFTsTest is ERC165, ERC721_IMPL {
	using Strings for uint256;

	string public contractURI;

	function initNFTs() external {
		initERC165();
		initERC721_IMPL("NFTs", "NFTs");
		string memory addr = uint256(address(this)).toString();
		contractURI = string(abi.encodePacked("https://smart-dao-rel.stars-mine.com/service-api/test1/getOpenseaContractJSON?address=", addr));
		// contractURI = "https://smart-dao-rel.stars-mine.com/service-api/test1/getOpenseaContractJSON?address=0x87Ae5AB6e5A7F925dCC091F3a2247786D5E26349";
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

	struct TokenTransfer {
		address from;
		address to;
		uint256 blockNumber;
		uint256 tokenId;
		bytes data;
	}

	TokenTransfer public lastTransfer;

	function _beforeTokenTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override {
		require(lastTransfer.blockNumber == 0, "#NFTs#_beforeTokenTransfer lastTransfer.blockNumber == 0");
		if (from == address(0) || to == address(0)) return;
		lastTransfer.from = from;
		lastTransfer.to = to;
		lastTransfer.blockNumber = block.number;
		lastTransfer.tokenId = tokenId;
		lastTransfer.data = _data;
	}

	receive() external payable {
		require(msg.value != 0, "#NFTs#receive msg.value != 0"); // price
		require(lastTransfer.blockNumber != 0, "#NFTs#receive lastTransfer.blockNumber != 0");
		lastTransfer.blockNumber = 0;
	}

}
