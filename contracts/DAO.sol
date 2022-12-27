
pragma solidity >=0.6.0 <=0.8.15;

import './Module.sol';
import '../openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableMap.sol';

contract DAO is IDAO, Module {
	using UintToAddressMap for EnumerableMap.UintToAddressMap;

	address            private  _root;
	string             private  _name;
	string             private  _mission;
	UintToAddressMap   private  _modules;
	uint256[50]        private  __; // Reserved storage space

	function root() view external override returns (address) { return _root; }
	function name() view external returns (string memory) { return _name; }
	function mission() view external returns (string memory) { return _mission; }
	function member() view external override returns (IMember) { return _modules.get(Module_MEMBER_ID); }
	function ledger() view external override returns (ILedger) { return _modules.get(Module_LEDGER_ID); }
	function asset() view external override returns (IAsset) { return _modules.get(Module_ASSET_ID); }

	function module(uint256 id) view external returns (IModule) {
		return IModule(_modules.get(id));
	}

	function initDAO(
		string memory name, string memory mission, string memory description,
		address root, address operator, address member
	) external {
		initModule(address(this), description, operator);
		_registerInterface(DAO_Type);

		ERC165(root).checkInterface(VotePool_Type, "#DAO#initDAO root type not match");
		ERC165(member).checkInterface(Member_Type, "#DAO#initDAO member type not match");

		_root = root;
		_name = name;
		_mission = mission;
		_modules.set(Module_MEMBER_ID, member);
	}

	function setMission(string memory value) external Check(Action_DAO_Settings) {
		_mission = value;
		emit Change(Change_Tag_DAO_Mission, 0);
	}

	function setDescription(string memory desc) external Check(Action_DAO_Settings) {
		_description = value;
		emit Change(Change_Tag_Description, 0);
	}

	function setMissionAndDesc(string memory mission, string memory desc) external Check(Action_DAO_Settings) {
		_mission = mission;
		_description = desc;
		emit Change(Change_Tag_Description, 0);
		emit Change(Change_Tag_DAO_Mission, 0);
	}

	function setModule(uint256 id, address addr) external Check(Action_DAO_SetModule) {
		require(id != Module_MEMBER_ID, "#DAO#setModule Disable Updates members");
		if (addr == address(0)) {
			_modules.remove(id);
		} else {
			ERC165(addr).checkInterface(Module_Type, "#DAO#setModule type not match");
			_modules.set(id, addr);
		}
		emit Change(Change_Tag_DAO_Module, id);
	}

}