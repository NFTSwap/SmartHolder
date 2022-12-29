// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import '../openzeppelin/contracts/utils/structs/EnumerableSet.sol';
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

	struct DAOIMPLs {
		address   DAO;
		address   Member;
		address   VotePool;
		address   Ledger;
		address   Asset;
		address   AssetShell;
	}

	struct InitMemberArgs {
		string name;
		string description;
		Member.MintMemberArgs[] members;
	}

	struct InitVotePoolArgs {
		string  description;
		uint256 lifespan;
	}

	EnumerableSet.AddressSet private  _DAOs; // global DAOs list
	DAOIMPLs                 public   defaultIMPLs; // default logic impl
	uint256[50]              private  __; // reserved storage space

	function initDAOs() external initializer {
		initOwnable();
	}

	function setDefaultIMPLs(DAOIMPLs memory IMPLs) public onlyOwner {
		defaultIMPLs = IMPLs;
	}

	/**
	 * @dev deploy() deploy common voting DAO
	 */
	function deploy(
		string           memory    name,              string           memory    mission,
		string           memory    description,       address                    operator,
		InitMemberArgs   memory    memberArgs,        InitVotePoolArgs memory    votePoolArgs
	) external returns (IDAO) {
		DAO host      = DAO( address(new DAOProxy(defaultIMPLs.DAO)) );
		Member member = Member( address(new MemberProxy(defaultIMPLs.Member)) );
		VotePool root = VotePool( address(new VotePoolProxy(defaultIMPLs.VotePool)) );

		member.initMember(address(host), memberArgs.name, memberArgs.description, address(0), memberArgs.members);
		root.initVotePool(address(host), votePoolArgs.description, votePoolArgs.lifespan);
		host.initDAO(name, mission, description, address(root), operator, address(member));

		emit Created(address(host));

		return host;
	}

	/**
	 * @dev makeAssetSales() deploy asset sales DAO
	 */
	function deployAssetSalesDAO(
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