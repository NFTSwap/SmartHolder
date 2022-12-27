
pragma solidity >=0.6.0 <=0.8.15;

import './Interface.sol';

/**
 * @title DAOs contract global DAOs manage
 */
contract DAOs {
	mapping(uint256 => IDAO) _DAOs;

	/**
	 * @title make() create DAO from params
	 */
	function make() external returns (IDAO) {
		// TODO ...
	}

	/**
	 * @title DAOs(id) get DAO object from id
	 * @param id uint256 dao id
	 * @return Returns the IDAO interface address
	 */
	function DAOs(uint256 id) view external returns (IDAO) {
		// TODO ...
		_DAOs[id]
	}
}