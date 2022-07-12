
pragma solidity ^0.8.15;

import "./department.sol";

contract Exchange is Department {

	/*
	 * bytes4(keccak256('initMember(string,string,address,address,address,address,address,address)')) == 0x98fded77
	 */
	bytes4 public constant ID = 0x98fded77;

	function initExchange(address host, string memory info, address operator) external {
		initDepartment(host, info, operator);
		_registerInterface(ID);
		// TODO
	}

}