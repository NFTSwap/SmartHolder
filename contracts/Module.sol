// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './libs/Upgrade.sol';
import './libs/AddressExp.sol';
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

	function initModule(address host, string memory description, address operator) internal {
		initERC165();
		_registerInterface(Module_Type);
		//ERC165(host).checkInterface(DAO_Type, "#Module#initModule dao host type not match");
		_host = IDAO(host);
		_description = description;
		_operator = operator;
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

	function setOperator(address operator) external override OnlyDAO {
		_operator = operator;
		emit Change(Change_Tag_Operator, uint160(operator));
	}

	function upgrade(address impl) external override OnlyDAO {
		_impl = impl;
		emit Change(Change_Tag_Upgrade, uint160(impl));
	}
}
