// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

/**
	*@dev All contracts that need to implement upgrades should inherit this `Upgrade` contract, 
	* and it should be the first parent class inherited
	*/
contract Upgrade {
	address internal _impl; // impl address
}

/**
 * @dev The context here is that the externally exposed contract entities are only used to store data, 
 * and the implemented business logic should be placed in the impl
 * Any method that calls this contract will be directed to `fallback()`, 
 * and then use `delegatecall()` to call the actual implementation and pass the current data context to impl
 */
contract ProxyStore is Upgrade {
	// The size allocated by Layout Store should be specified by dynamic compilation, 
	// and the storage size needs to be read from the original contract

	constructor(address impl_) {
		_impl = impl_;
	}

	fallback() external payable {
		(bool suc, bytes memory _data) = _impl.delegatecall(msg.data);
		assembly {
			let len := mload(_data)
			let data := add(_data, 0x20)
			switch suc
			case 0 { revert(data, len) }
			default { return(data, len) }
		}
	}
}