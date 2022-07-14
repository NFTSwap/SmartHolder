
pragma solidity >=0.6.0 <=0.8.15;

import "./Interface.sol";
import "./VotePool.sol";
import "./ERC165.sol";
import "./Address.sol";

contract Department is ERC165, IDepartment {
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


	address private __impl;
	IDAO public host;
	string  public info;
	IVotePool private _operator;

	/**
		* @dev Throws if called by any account other than the owner.
		*/
	modifier OnlyDAO() {
		address sender = msg.sender;
		if (sender != address(_operator)) {
			if (sender != address(host.operator())) {
				require(sender == address(host.root()), "#Department#OnlyDAO caller does not have permission");
			}
		}
		_;
	}

	function initDepartment(address host_, string memory info_, address operator_) internal {
		initERC165();
		_registerInterface(Department_ID);

		ERC165(host_).checkInterface(DAO_ID, "#Department#initDepartment dao host type not match");

		host = IDAO(host_);
		info = info_;

		setOperator_internal(operator_);
	}

	function operator() view external override returns (IVotePool) {
		return _operator;
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
		__impl = impl;
	}

}