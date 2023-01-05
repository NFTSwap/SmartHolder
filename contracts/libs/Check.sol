//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './Interface.sol';

abstract contract PermissionCheck {
	IDAO internal _host; // address

	function host() view external returns (IDAO) {
		return _host;
	}

	/**
		* @dev Throws if called by any account other than the owner.
		*/
	modifier OnlyDAO() {
		require(isPermissionDAO(), "#PermissionCheck#Check caller does not have permission");
		_;
	}

	/**
	 * @dev check call Permission from action
	 */
	modifier Check(uint256 action) {
		if (!isPermissionDAO())
			require(_host.member().isPermission(msg.sender, action), "#PermissionCheck#Check caller does not have permission");
		_;
	}

	modifier CheckFrom(uint256 memberId, uint256 action) {
		checkFrom(memberId, action);
		_;
	}

	function checkFrom(uint256 memberId, uint256 action) view internal {
		if (!isPermissionDAO()) {
			require(_host.member().ownerOf(memberId) == msg.sender, "#PermissionCheck#checkFrom member owner mismatch");
			require(_host.member().isPermissionFrom(memberId, action), "#PermissionCheck#checkFrom member does not have permission");
		}
	}

	function isPermissionDAO() view internal virtual returns (bool);
}
