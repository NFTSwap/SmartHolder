
pragma solidity ^0.8.15;

import "./department.sol";

contract Ledger is Department {

	/*
	 * bytes4(keccak256('initLedger(string,string,address,address,address,address,address,address)')) == 0x98fded77
	 */
	bytes4 public constant ID = 0x98fded77;

	function initLedger(address host, string memory info, address operator) external {
		initDepartment(host, info, operator);
		_registerInterface(ID);
		// TODO
	}

}