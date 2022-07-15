
pragma solidity >=0.6.0 <=0.8.15;

import "./Upgrade.sol";
import "./Interface.sol";
import "./VotePool.sol";
import "./ERC165.sol";
import "./AddressExp.sol";

contract Department is IDepartment, Upgrade, ERC165 {
	using Address for address;
	using AddressExp for address;

	/*
		* bytes4(keccak256('initDepartment(address,string,address)')) == 0x36c6362d
		*/
	bytes4 internal constant Department_ID = 0x36c6362d;
	/*
		* bytes4(keccak256('initAssetGlobal(address,string,address)')) == 0x711cc62c
		*/
	bytes4 internal constant AssetGlobal_ID = 0x711cc62c;
	/*
		* bytes4(keccak256('initAsset(address,string,address)')) == 0xb6f00dcf
		*/
	bytes4 internal constant Asset_ID = 0xb6f00dcf;
	/*
		* bytes4(keccak256('initDAO(string,address,address,address,address,address,address)')) == 0xc7b55336
		*/
	bytes4 internal constant DAO_ID = 0xc7b55336;
	/*
		* bytes4(keccak256('initLedger(address,string,address)')) == 0xf4c38e51
		*/
	bytes4 internal constant Ledger_ID = 0xf4c38e51;
	/*
		* bytes4(keccak256('initMember(address,string,address)')) == 0x23fc76b9
		*/
	bytes4 internal constant Member_ID = 0x23fc76b9;
	/*
		* bytes4(keccak256('initVotePool(address,string)')) == 0x0ddf27bf
		*/
	bytes4 internal constant VotePool_ID = 0x0ddf27bf;

	IVotePool internal _operator; // address
	IDAO internal _host; // address
	string internal _describe;

	/**
		* @dev Throws if called by any account other than the owner.
		*/
	modifier OnlyDAO() {
		address sender = msg.sender;
		if (sender != address(_operator)) {
			if (sender != address(_host.operator())) {
				require(sender == address(_host.root()), "#Upgrade#OnlyDAO caller does not have permission");
			}
		}
		_;
	}

	function initDepartment(address host, string memory describe, address operator) internal {
		initERC165();
		_registerInterface(Department_ID);

		ERC165(host).checkInterface(DAO_ID, "#Department#initDepartment dao host type not match");

		_host = IDAO(host);
		_describe = describe;

		setOperator_internal(operator);
	}

	function host() view external returns (IDAO) {
		return _host;
	}

	function operator() view external override returns (IVotePool) {
		return _operator;
	}

	function describe() view external returns (string memory) {
		return _describe;
	}

	function setOperator_internal(address vote) internal {
		if (vote != address(0)) {
			if (address(vote).isContract()) {
				ERC165(vote).checkInterface(VotePool_ID, "#Department#setOperator_internal operator type not match");
			}
		}
		_operator = IVotePool(vote);
	}

	function setOperator(address vote) external override OnlyDAO {
		setOperator_internal(vote);
	}

	function upgrade(address impl) external override OnlyDAO {
		_impl = impl;
	}
}