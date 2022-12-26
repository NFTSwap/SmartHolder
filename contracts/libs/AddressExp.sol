
pragma solidity >=0.6.0 <=0.8.15;

import '../../openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol';

library AddressExp {
	//@dev Converts an address to address payable.
	function toPayable(address account)
		internal
		pure
		returns (address payable)
	{
		return address(uint160(account));
	}

	function sendValue(address recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

}
