
pragma solidity >=0.6.0 <=0.8.15;

import './Interface.sol';

contract DAOs {
	mapping(bytes32 => IDAO) _DAOs;

	function NewDAO() external returns (IDAO) {
		// TODO ...
	}

	function DAOs(bytes32 id) view external returns (IDAO) {
		// TODO ...
	}
}