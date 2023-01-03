//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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