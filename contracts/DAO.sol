
pragma solidity >=0.6.0 <=0.8.15;

import "./Department.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol";

contract DAO is IDAO, Department {
	using EnumerableSet for EnumerableSet.AddressSet;

	string internal _name;
	string internal _mission;
	IVotePool private _root;
	IMember private _member;
	ILedger private _ledger;
	IAssetShell private _assetShell;
	IAsset private _asset;
	address private __exchange;
	EnumerableSet.AddressSet private _departments;
	uint256[50] private __gap;

	function name() view external returns (string memory) { return _name; }
	function mission() view external returns (string memory) { return _mission; }
	function root() view external override returns (IVotePool) { return _root; }
	function member() view external override returns (IMember) { return _member; }
	function ledger() view external override returns (ILedger) { return _ledger; }
	function assetShell() view external override returns (IAssetShell) { return _assetShell; }
	function assetGlobal() view external override returns (IAssetShell) { return _assetShell; }
	function asset() view external override returns (IAsset) { return _asset; }

	function initInterfaceID() external {
		require(!supportsInterface(DAO_ID), "Can only be called once");
		_registerInterface(DAO_ID);
	}

	function initDAO(
		string memory name,
		string memory mission,
		string memory description,
		address operator, address root,
		address member, address ledger,
		address assetShell, address asset
	) external {
		initDepartment(address(this), description, operator);

		ERC165(root).checkInterface(VotePool_ID, "#DAO#initDAO root type not match");
		ERC165(member).checkInterface(Member_ID, "#DAO#initDAO member type not match");
		ERC165(ledger).checkInterface(Ledger_ID, "#DAO#initDAO ledger type not match");
		ERC165(assetShell).checkInterface(AssetShell_ID, "#DAO#initDAO assetShell type not match");
		ERC165(asset).checkInterface(Asset_ID, "#DAO#initDAO asset type not match");

		_name = name;
		_mission = mission;
		_root = IVotePool(root);
		_member = IMember(member);
		_ledger = ILedger(ledger);
		_assetShell = IAssetShell(assetShell);
		_asset = IAsset(asset);

		emit Change("Init");
	}

	function setMissionAndDesc(string memory mission, string memory description) external OnlyDAO {
		_description = description;
		_mission = mission;
		emit Change("MissionAndDesc");
	}

	function setLedger(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(Ledger_ID, "#DAO#setLedger type not match");
		_ledger = ILedger(addr);
		emit Change("Ledger");
	}

	function setAssetShell(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(AssetShell_ID, "#DAO#setAssetShell type not match");
		_assetShell = IAssetShell(addr);
		emit Change("AssetShell");
	}

	function setAsset(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(Asset_ID, "#DAO#setAsset type not match");
		_asset = IAsset(addr);
		emit Change("Asset");
	}

	function setMember(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(Member_ID, "#DAO#setAsset type not match");
		_member = IMember(addr);
		emit Change("Member");
	}

	function setDepartments(address addr, bool isDel) external OnlyDAO {
		ERC165(addr).checkInterface(Department_ID, "#DAO#setDepartments type not match");

		if (_departments.contains(addr)) {
			if (isDel) _departments.remove(addr);
		} else {
			if (!isDel) _departments.add(addr);
		}
		emit Change("Department");
	}

}