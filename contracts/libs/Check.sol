//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import './Errors.sol';
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
		if (!isPermissionDAO())
			revert PermissionDeniedForOnlyDAO();
		_;
	}

	/**
	 * @dev check call Permission from action
	 */
	modifier Check(uint256 action) {
		if (!isPermissionDAO()) {
			if (!_host.member().isPermission(msg.sender, action))
				revert PermissionDenied(); // caller does not have permission
		}
		_;
	}

	modifier CheckFrom(uint256 memberId, uint256 action) {
		checkFrom(memberId, action);
		_;
	}

	function checkFrom(uint256 memberId, uint256 action) view internal {
		if (!isPermissionDAO()) {
			if (
						_host.member().ownerOf(memberId) != msg.sender // Member owner mismatch
					|| !_host.member().isPermissionFrom(memberId, action) // Check caller does not have permission
				)
				revert PermissionDenied();
		}
	}

	function isPermissionDAO() view internal virtual returns (bool);
}
