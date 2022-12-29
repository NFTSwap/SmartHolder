// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './libs/Ownable.sol';
// Module impl
import './DAO.sol';
import './Asset.sol';
import './AssetShell.sol';
import './Ledger.sol';
import './Member.sol';
import './VotePool.sol';
// Proxy
import './gen/DAOProxy.sol';
import './gen/AssetProxy.sol';
import './gen/AssetShellProxy.sol';
import './gen/LedgerProxy.sol';
import './gen/MemberProxy.sol';
import './gen/VotePoolProxy.sol';

/**
 * @title DAOs contract global DAOs manage
 */
contract DAOs is Upgrade, Initializable, Ownable, IDAOs {
	using EnumerableSet for EnumerableSet.AddressSet;

	EnumerableSet.AddressSet    private  _DAOs;
	// proxy logic impl
	DAO           private  _DAO;
	Member        private  _Member;
	VotePool      private  _VotePool;
	Ledger        private  _Ledger;
	Asset         private  _Asset;
	AssetShell    private  _AssetShell;

	uint256[50]   private  __; // reserved storage space

	struct InitMemberArgs {
		string name;
		string description;
		Member.MintMemberArgs[] members;
	}

	struct InitVotePoolArgs {
		string  description;
		uint256 lifespan;
	}

	function initDAOs() external initializer {
		initOwnable();
		_DAO = new DAO();
		_Member = new Member();
		_VotePool = new VotePool();
		_Ledger = new Ledger();
		_Asset = new Asset();
		_AssetShell = new AssetShell();
	}

	/**
	 * @dev makeDAO() create voting DAO
	 */
	function makeDAO(
		string           memory    name,              string           memory    mission,
		string           memory    description,       address                    operator,
		InitMemberArgs   memory    memberArgs,        InitVotePoolArgs memory    votePoolArgs
	) external returns (IDAO) {
		DAO host = new DAO();
		Member member = new Member();
		VotePool root = new VotePool();

		member.initMember(address(host), memberArgs.name, memberArgs.description, address(0), memberArgs.members);
		root.initVotePool(address(host), votePoolArgs.description, votePoolArgs.lifespan);
		host.initDAO(name, mission, description, address(root), operator, address(member));

		emit Created(address(host));

		return host;
	}

	/**
	 * @dev makeAssetSales() create asset sales DAO
	 */
	function makeAssetSalesDAO(
		string           memory    name,              string           memory    mission,
		string           memory    description,       address                    operator,
		InitMemberArgs   memory    memberArgs,        InitVotePoolArgs memory    votePoolArgs
	) external returns (IDAO) {
		//
		// address host, string memory name, string memory description, address operator,
		// string memory _contractURI
		//
		// address host,      string memory name,          string memory description,
		// address operator,  string memory _contractURI,  SaleType _saleType
	}

	/**
	 * @dev length() Returns DAOs length
	 */
	function length() view public returns (uint256) {
		return _DAOs.length();
	}

	/**
	 * @dev contains(address) is contains dao address
	 */
	function contains(address addr) view public returns (bool) {
		return _DAOs.contains(addr);
	}

	/**
	 * @dev at(id) get DAO object from index
	 * @param index uint256 dao index
	 * @return Returns the IDAO interface address
	 */
	function at(uint256 index) view external returns (IDAO) {
		return IDAO(_DAOs.at(index));
	}

	/**
	 * @dev upgrade(address) upgrade contracts
	 */
	function upgrade(address impl) public onlyOwner {
		_impl = impl;
	}
}