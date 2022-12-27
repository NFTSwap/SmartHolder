
pragma solidity >=0.6.0 <=0.8.15;

import './libs/Upgrade.sol';
import './libs/AddressExp.sol';
import './libs/Constants.sol';
import './libs/ERC165.sol';
import './libs/Interface.sol';
import './VotePool.sol';

abstract contract PermissionCheck {
	IDAO internal _host; // address

	function host() view external returns (IDAO) {
		return _host;
	}

	/**
		* @dev Throws if called by any account other than the owner.
		*/
	modifier Check() {
		require(isPermissionDAO(), "#PermissionCheck#Check() caller does not have permission");
		_;
	}

	/**
	 * @dev check call Permission from action
	 */
	modifier Check(uint256 action) {
		if (!isPermissionDAO())
			require(_host.member().isPermission(msg.sender, action), "#PermissionCheck#Check(uint256) caller does not have permission");
		_;
	}

	function isPermissionDAO() view internal virtual returns (bool);
}

contract Module is Upgrade, IModule, ERC165, PermissionCheck {
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

		setOperator1(operator);
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

	function setOperator1(address operator) internal {
		if (operator != address(0)) {
			if (operator.isContract())
				ERC165(operator).checkInterface(VotePool_Type, "#Module#setOperator1 operator type not match");
		}
		_operator = operator;
	}

	function setDescription(string memory value) external Check {
		_description = value;
		emit Change(Change_Tag_Description, 0);
	}

	function setOperator(address operator) external override Check {
		setOperator1(operator);
		emit Change(Change_Tag_Operator, uint256(operator));
	}

	function upgrade(address impl) external override Check {
		_impl = impl;
		emit Change(Change_Tag_Upgrade, uint256(impl));
	}
}