
pragma solidity >=0.6.0 <=0.8.15;

import './Department.sol';
import '../openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableMap.sol';

contract DAO is IDAO, Department {
	using UintToAddressMap for EnumerableMap.UintToAddressMap;

	string internal _name;
	string internal _mission;
	UintToAddressMap private _departments;
	uint256[50] private __gap; // Reserved storage space

	function name() view external returns (string memory) { return _name; }
	function mission() view external returns (string memory) { return _mission; }
	function member() view external override returns (IMember) { return _departments.get(Departments_MEMBER_ID); }
	function ledger() view external override returns (ILedger) { return _departments.get(Departments_LEDGER_ID); }
	function asset() view external override returns (IAsset) { return _departments.get(Departments_ASSET_ID); }

	function department(uint256 id) view external returns (IDepartment) {
		return IDepartment(_departments.get(id));
	}

	function initDAO(
		string memory name, string memory mission,
		string memory description, address operator, address member
	) external {
		initDepartment(address(this), description, operator);
		_registerInterface(DAO_Type);

		_name = name;
		_mission = mission;

		ERC165(member).checkInterface(Member_Type, "#DAO#initDAO member type not match");
		_departments.set(Departments_MEMBER_ID, member);
	}

	function setMission(string memory value) external OnlyDAO {
		_mission = value;
		emit Change(Change_Tag_DAO_Mission);
	}

	function setMissionAndDesc(string memory mission, string memory desc) external OnlyDAO {
		_mission = mission;
		_description = desc;
		emit Change(Change_Tag_Description);
		emit Change(Change_Tag_DAO_Mission);
	}

	function setDepartment(uint256 id, address addr) external OnlyDAO {
		require(id != Departments_MEMBER_ID, "#DAO#setDepartment Disable Updates members");
		if (addr == address(0)) {
			_departments.remove(id);
		} else {
			ERC165(addr).checkInterface(Department_Type, "#DAO#setDepartments type not match");
			_departments.set(id, addr);
		}
		emit Change(Change_Tag_DAO_Department);
	}

}