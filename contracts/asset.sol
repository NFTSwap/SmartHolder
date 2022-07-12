
pragma solidity ^0.8.15;

import "./erc721.sol";

contract Asset is Department, ERC721 {

	/*
	 * bytes4(keccak256('initMember(string,string,address,address,address,address,address,address)')) == 0x98fded77
	 */
	bytes4 public constant ID = 0x98fded77;

	function initAsset(address host, string memory info, address operator) external {
		initDepartment(host, info, operator);
		initERC721("Asset", "DAO Asset");
		_registerInterface(ID);
		// TODO
	}

}
