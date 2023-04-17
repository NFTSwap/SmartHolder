// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import './libs/Upgrade.sol';
import './libs/Address.sol';
import './libs/Constants.sol';
import './libs/ERC165.sol';
import './libs/Interface.sol';
import './libs/Check.sol';

contract Module is Upgrade, ERC165, PermissionCheck, IModule {
	using Address for address;
	using AddressExp for address;
	address internal _operator; // address
	string  internal _description;
	uint256[8] private __; // reserved storage space

	function initModule(address host, string memory description_, address operator_) internal {
		initERC165();
		_registerInterface(Module_Type);
		_host = IDAO(host);
		_description = description_;
		_operator = operator_;
	}

	function isPermissionDAO() view internal override returns (bool) {
		address sender = msg.sender;
		if (sender != _operator) {
			if (sender != _host.operator())
				return sender == _host.root();
		}
		return true;
	}

	function impl() view external returns (address) {
		return _impl;
	}

	function operator() view external override returns (address) {
		return _operator;
	}

	function description() view external returns (string memory) {
		return _description;
	}

	function setDescription(string memory value) external Check(Action_DAO_Settings) {
		_description = value;
		emit Change(Change_Tag_Description, 0);
	}

	function setOperator(address operator_) external override OnlyDAO {
		_operator = operator_;
		emit Change(Change_Tag_Operator, uint160(operator_));
	}

	function upgrade(address impl_) external override OnlyDAO {
		_impl = impl_;
		emit Change(Change_Tag_Upgrade, uint160(impl_));
	}
}
