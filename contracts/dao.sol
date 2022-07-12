
pragma solidity ^0.8.15;

import "./department.sol";
import "./vote_pool.sol";
import "./member.sol";
import "./ledger.sol";
import "./exchange.sol";
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
	Asset public asset;
	Exchange public exchange;
	AddressSet private departments;

	constructor() external {
		_registerInterface(ID);
	}

	function initDAO(
		string memory info,
		address operator,
		address root_,
		address member,
		address ledger,
		address asset,
		address exchange) external {
		initDepartment(address(this), info, operator);

		ERC165(root_).checkInterface(VotePool.ID, "#DAO#initDAO root type not match");
		root = VotePool(root_);
	}

	function setLedger(address addr) external onlyDAO {
		// TODO ...
	}

	function setAsset(address addr) external onlyDAO {
		// TODO ...
	}

	function setExchange(address addr) external onlyDAO {
		// TODO ...
	}

	function setDepartments(address addr, bool isDel) external onlyDAO {
		// TODO ...
	}

}