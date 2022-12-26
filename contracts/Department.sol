
pragma solidity >=0.6.0 <=0.8.15;

import './libs/Upgrade.sol';
import './libs/AddressExp.sol';
import './libs/Constants.sol';
import './libs/ERC165.sol';
import './libs/Interface.sol';
import './VotePool.sol';

contract Department is Upgrade, IDepartment, ERC165 {
	using Address for address;
	using AddressExp for address;

	IVotePool internal _operator; // address
	IDAO internal _host; // address
	string internal _description;

	/**
		* @dev Throws if called by any account other than the owner.
		*/
	modifier OnlyDAO() {
		require(isPermissionDAO(), "#Department#OnlyDAO caller does not have permission");
		_;
	}

	function isPermissionDAO() view internal returns (bool) {
		address sender = msg.sender;
		if (sender != address(_operator)) {
			if (sender != address(_host.operator())) {
				return sender == address(_host.root());
			}
		}
		return true;
	}

	function initDepartment(address host, string memory description, address operator) internal {
		initERC165();
		_registerInterface(Department_Type);
		//ERC165(host).checkInterface(DAO_Type, "#Department#initDepartment dao host type not match");
		_host = IDAO(host);
		_description = description;

		setOperator_1(operator);
	}

	function impl() view external returns (address) {
		return _impl;
	}

	function host() view external returns (IDAO) {
		return _host;
	}

	function operator() view external override returns (IVotePool) {
		return _operator;
	}

	function description() view external returns (string memory) {
		return _description;
	}

	function setOperator_1(address vote) internal {
		if (vote != address(0)) {
			if (address(vote).isContract()) {
				ERC165(vote).checkInterface(VotePool_Type, "#Department#setOperator_1 operator type not match");
			}
		}
		_operator = IVotePool(vote);
	}

	function setDescription(string memory value) external OnlyDAO {
		_description = value;
		emit Change(Change_Tag_Description);
	}

	function setOperator(address vote) external override OnlyDAO {
		setOperator_1(vote);
		emit Change(Change_Tag_Operator);
	}

	function upgrade(address impl) external override OnlyDAO {
		_impl = impl;
		emit Change(Change_Tag_Upgrade);
	}
}