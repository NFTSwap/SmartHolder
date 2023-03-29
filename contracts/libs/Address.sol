//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../../openzeppelin/contracts/utils/Address.sol';
import './Errors.sol';

library AddressExp {
	//@dev Converts an address to address payable.
	function toPayable(address account)
		internal
		pure
		returns (address payable)
	{
		return payable(address(uint160(account)));
	}

	function sendValue(address recipient, uint256 amount) internal {
		if (address(this).balance < amount)
			revert InsufficientBalance();
		(bool success, ) = recipient.call{ value: amount }("");
		if (!success)
			revert SendValueFail();
	}

}