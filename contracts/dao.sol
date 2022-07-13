
pragma solidity ^0.8.15;

import "./department.sol";
import "./vote_pool.sol";
import "./member.sol";
import "./ledger.sol";
import "./asset_global.sol";
import "./asset.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol";

contract DAO is Department {
	using EnumerableSet for EnumerableSet.AddressSet;

	/*
	 * bytes4(keccak256('initDAO(string,string,address,address,address,address,address,address)')) == 0x98fded77
	 */
	bytes4 public constant ID = 0x98fded77;

	VotePool public root;
	Member public member;
	Ledger public ledger;
	AssetGlobal public assetGlobal;
	Asset public asset;
	address private __exchange;
	AddressSet private departments;
	uint256[50] private __gap;

	constructor() external {
		_registerInterface(ID);
	}

	function initDAO(
		string memory info,
		address operator, address root_,
		address member_, address ledger_, address assetGlobal_, address asset_) external {
		initDepartment(address(this), info, operator);

		ERC165(root_).checkInterface(VotePool.ID, "#DAO#initDAO root type not match");
		ERC165(member_).checkInterface(Member.ID, "#DAO#initDAO member type not match");
		ERC165(ledger_).checkInterface(Ledger.ID, "#DAO#initDAO ledger type not match");
		ERC165(assetGlobal_).checkInterface(AssetGlobal.ID, "#DAO#initDAO assetGlobal type not match");
		ERC165(asset_).checkInterface(Asset.ID, "#DAO#initDAO asset type not match");

		root = VotePool(root_);
		member = VotePool(member_);
		ledger = Ledger(ledger_);
		assetGlobal = AssetGlobal(assetGlobal_);
		asset = Asset(asset_);
	}

	function setLedger(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(Ledger.ID, "#DAO#setLedger type not match");
		ledger = Ledger(addr);
	}

	function setAssetGlobal(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(AssetGlobal.ID, "#DAO#setAssetGlobal type not match");
		assetGlobal = AssetGlobal(addr);
	}

	function setAsset(address addr) external OnlyDAO {
		ERC165(addr).checkInterface(Asset.ID, "#DAO#setAsset type not match");
		asset = Asset(addr);
	}

	function setDepartments(address addr, bool isDel) external OnlyDAO {
		ERC165(addr).checkInterface(Department.ID, "#DAO#setDepartments type not match");

		if (departments.contains(addr)) {
			if (isDel) {
				departments.remove(addr);
			}
		} else {
			if (!isDel) {
				departments.add(addr);
			}
		}
	}

}