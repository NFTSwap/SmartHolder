// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ~0.8.17;

import '../../openzeppelin/contracts/utils/Strings.sol';

/**
 * @dev String operations.
 */
library StringsExp {
	bytes16 private constant _SYMBOLS = "0123456789abcdef";

	/**
		* @dev toHexString()
		*/
	function toHexString(bytes memory value) internal pure returns (string memory) {
		bytes memory buffer = new bytes(2 * value.length);
		for (uint256 i = 0; i < value.length; i++) {
			uint8 b = uint8(value[i]);
			buffer[(i<<1)  ] = _SYMBOLS[b >> 4];
			buffer[(i<<1)+1] = _SYMBOLS[b & 0xf];
		}
		return string(buffer);
	}

}