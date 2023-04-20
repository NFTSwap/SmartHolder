// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import './Module.sol';
import '../openzeppelin/contracts/utils/structs/EnumerableMap.sol';

contract DAO is IDAO, Module {
	using EnumerableMap for EnumerableMap.UintToAddressMap;

	struct BasicInformation {
		string mission;
		string description;
		string image;
		bytes  extend;
	}
	struct InitDAOArgs {
		string name;
		string mission;
		string description;
		string image;
		bytes  extend;
	}

	address            private  _root;
	string             private  _name;
	string             private  _mission;
	EnumerableMap.UintToAddressMap private _modules;
	string             public  image;
	bytes              public  extend; // external data
	IDAOs              public  daos;
	uint256[47]        private  __; // reserved storage space

	function root() view external override returns (address) { return _root; }
	function name() view external returns (string memory) { return _name; }
	function mission() view external returns (string memory) { return _mission; }
	function member() view external override returns (IMember) { return IMember(_modules.get(Module_MEMBER_ID)); }
	function ledger() view external override returns (ILedger) { return ILedger(_modules.get(Module_LEDGER_ID)); }
	function asset() view external override returns (IAsset) { return IAsset(_modules.get(Module_ASSET_ID)); }
	function first() view external override returns (IAssetShell) { return IAssetShell(_modules.get(Module_ASSET_First_ID)); }
	function second() view external override returns (IAssetShell) { return IAssetShell(_modules.get(Module_ASSET_Second_ID)); }
	function share() view external override returns (IShare) { return IShare(_modules.get(Module_Share_ID)); }

	function module(uint256 id) view external returns (IModule) {
		return IModule(_modules.contains(id) ? _modules.get(id): address(0));
	}

	function initDAO(
		IDAOs daos_, InitDAOArgs calldata args,
		address root_, address operator, address member_
	) external {
		initModule(address(this), args.description, operator);
		_registerInterface(DAO_Type);

		ERC165(root_).checkInterface(VotePool_Type);
		ERC165(member_).checkInterface(Member_Type);

		daos = daos_;
		_root = root_;
		_name = args.name;
		_mission = args.mission;
		image = args.image;
		extend = args.extend;

		_modules.set(Module_MEMBER_ID, member_);
		// emit SetModule(Module_MEMBER_ID, member);
	}

	function setExtend(bytes calldata data) external Check(Action_DAO_Settings) {
		extend = data;
		emit Change(Change_Tag_DAO_Extend, 0);
	}

	function setImage(string calldata value) external Check(Action_DAO_Settings) {
		image = value;
		emit Change(Change_Tag_DAO_Image, 0);
	}

	function setMission(string calldata value) external Check(Action_DAO_Settings) {
		_mission = value;
		emit Change(Change_Tag_DAO_Mission, 0);
	}

	function setMissionAndDesc(string calldata mission_, string calldata desc) external Check(Action_DAO_Settings) {
		_mission = mission_;
		_description = desc;
		emit Change(Change_Tag_Description, 0);
		emit Change(Change_Tag_DAO_Mission, 0);
	}

	function setBasicInformation(BasicInformation calldata basic) external Check(Action_DAO_Settings) {
		if (bytes(basic.mission).length > 0) {
			_mission = basic.mission;
			emit Change(Change_Tag_DAO_Mission, 0);
		}
		if (bytes(basic.description).length > 0) {
			_description = basic.description;
			emit Change(Change_Tag_Description, 0);
		}
		if (bytes(basic.image).length > 0) {
			image = basic.image;
			emit Change(Change_Tag_DAO_Image, 0);
		}
		if (basic.extend.length > 0) {
			extend = basic.extend;
			emit Change(Change_Tag_DAO_Extend, 0);
		}
	}

	/**
	 * @dev set new module
	 */
	function setModule(uint256 id, address addr) external Check(Action_DAO_SetModule) {
		//require(id != Module_MEMBER_ID, "#DAO.setModule Disable Updates members");
		//require(id != Module_Share_ID, "#DAO.setModule Disable Updates share");
		require(_modules.get(id) == address(0), "#DAO.setModule module already exists");

		ERC165(addr).checkInterface(Module_Type);
		_modules.set(id, addr);

		emit SetModule(id, addr);
	}

	/**
	 * @dev enable share module
	 */
	function enableShare(string calldata symbol) public OnlyDAO {
		require(_modules.get(Module_Share_ID) == address(0), "#DAO.enableShare Share module already exists");

		address addr = daos.deployShare(this, address(0), _name, symbol, "");

		_modules.set(Module_Share_ID, addr);

		emit SetModule(Module_Share_ID, addr);
	}

}