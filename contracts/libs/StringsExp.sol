//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library StringsExp {
	bytes16 private constant _SYMBOLS = "0123456789abcdef";

	/**
	 * @dev toHexString() 
	 */
	function toHexString(bytes memory value) internal pure returns (string memory) {
		uint256 length = 2 * value.length;
		bytes memory buffer = new bytes(length);
		for (uint256 i = 0; i < length; i+=2) {
			uint8 b = uint8(value[i]);
			buffer[i] = _SYMBOLS[b & 0xf];
			buffer[i+1] = _SYMBOLS[(b >> 4)];
		}
		return string(buffer);
	}

}
