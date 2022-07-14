
pragma solidity >=0.6.0 <=0.8.15;

import "./department.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol";

contract DAO is Department, IDAO {
	using EnumerableSet for EnumerableSet.AddressSet;

	IVotePool private _root;
	IMember private _member;
	ILedger private _ledger;
	IAssetGlobal private _assetGlobal;
	IAsset private _asset;
	address private __exchange;
	EnumerableSet.AddressSet private _departments;
	uint256[50] private __gap;

	function root() view external override returns (IVotePool) { return _root; }
	function member() view external override returns (IMember) { return _member; }
	function ledger() view external override returns (ILedger) { return _ledger; }
	function assetGlobal() view external override returns (IAssetGlobal) { return _assetGlobal; }
	function asset() view external override returns (IAsset) { return _asset; }

	constructor() public {
		_registerInterface(DAO_ID);
	}

	function initDAO(
		string memory info,
		address operator, address root,
		address member, address ledger, address assetGlobal, address asset) external {
		initDepartment(address(this), info, operator);

		ERC165(root).checkInterface(VotePool_ID, "#DAO#initDAO root type not match");
		ERC165(member).checkInterface(Member_ID, "#DAO#initDAO member type not match");
		ERC165(ledger).checkInterface(Ledger_ID, "#DAO#initDAO ledger type not match");
		ERC165(assetGlobal).checkInterface(AssetGlobal_ID, "#DAO#initDAO assetGlobal type not match");
		ERC165(asset).checkInterface(Asset_ID, "#DAO#initDAO asset type not match");

		_root = IVotePool(root);
		_member = IMember(member);
		_ledger = ILedger(ledger);
		_assetGlobal = IAssetGlobal(assetGlobal);
		_asset = IAsset(asset);
	}

	function setLedger(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(Ledger_ID, "#DAO#setLedger type not match");
		_ledger = ILedger(addr);
	}

	function setAssetGlobal(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(AssetGlobal_ID, "#DAO#setAssetGlobal type not match");
		_assetGlobal = IAssetGlobal(addr);
	}

	function setAsset(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(Asset_ID, "#DAO#setAsset type not match");
		_asset = IAsset(addr);
	}

	function setDepartments(address addr, bool isDel) external OnlyDAO {
		ERC165(addr).checkInterface(Department_ID, "#DAO#setDepartments type not match");

		if (_departments.contains(addr)) {
			if (isDel) _departments.remove(addr);
		} else {
			if (!isDel) _departments.add(addr);
		}
	}

}