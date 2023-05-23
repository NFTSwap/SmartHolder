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
		address unlockOperator;
	}

	address            private  _root;
	string             private  _name;
	string             private  _mission;
	EnumerableMap.UintToAddressMap private _modules;
	string             public  image;
	bytes              public  extend; // external data
	IDAOs              private  _daos;
	address            private  _unlockOperator; // operator address for asset auto unlock
	uint256[46]        private  __; // reserved storage space

	function daos() view public override returns (IDAOs) { return _daos; }
	function root() view external override returns (address) { return _root; }
	function name() view external returns (string memory) { return _name; }
	function mission() view external returns (string memory) { return _mission; }
	function member() view external override returns (IMember) { return IMember(module(Module_MEMBER_ID)); }
	function ledger() view external override returns (ILedger) { return ILedger(module(Module_LEDGER_ID)); }
	function asset() view external override returns (IAsset) { return IAsset(module(Module_ASSET_ID)); }
	function first() view external override returns (IAssetShell) { return IAssetShell(module(Module_ASSET_First_ID)); }
	function second() view external override returns (IAssetShell) { return IAssetShell(module(Module_ASSET_Second_ID)); }
	function share() view external override returns (IShare) { return IShare(module(Module_Share_ID)); }
	function unlockOperator() view public override returns (address) { return _unlockOperator; }

	function module(uint256 id) view public override returns (address) {
		return address(uint160( uint256(_modules._inner._values[bytes32(id)])));
	}

	function initDAO(
		IDAOs daos, InitDAOArgs calldata args,
		address root, address operator, address member
	) external {
		initModule(address(this), args.description, operator);
		_registerInterface(DAO_Type);

		ERC165(root).checkInterface(VotePool_Type);
		ERC165(member).checkInterface(Member_Type);

		_daos = daos;
		_root = root;
		_name = args.name;
		_mission = args.mission;
		image = args.image;
		extend = args.extend;
		_unlockOperator = args.unlockOperator;

		_modules.set(Module_MEMBER_ID, member);
		// emit SetModule(Module_MEMBER_ID, member);
	}

	function setUnlockOperator(address addr) external Check(Action_DAO_Settings) {
		_unlockOperator = addr;
		emit Change(Change_Tag_DAO_UnlockOperator, 0);
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
		require(!_modules.contains(id), "#DAO.setModule module already exists");

		ERC165(addr).checkInterface(Module_Type);
		_modules.set(id, addr);

		emit SetModule(id, addr);
	}

	/**
	 * @dev enable share module
	 */
	function enableShare(uint256 totalSupply, uint256 maxSupply, string calldata symbol) public OnlyDAO {
		require(!_modules.contains(Module_Share_ID), "#DAO.enableShare Share module already exists");

		address addr = _daos.deployShare(this, address(0), totalSupply, maxSupply, _name, symbol, "");

		_modules.set(Module_Share_ID, addr);

		emit SetModule(Module_Share_ID, addr);
	}

}