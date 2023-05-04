// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

// import '../openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './libs/Ownable.sol';
// Module impl
import './DAO.sol';
import './Asset.sol';
import './AssetShell.sol';
import './Ledger.sol';
import './Member.sol';
import './VotePool.sol';
import './Share.sol';
// Proxy
import './gen/DAOProxy.sol';
import './gen/AssetProxy.sol';
import './gen/AssetShellProxy.sol';
import './gen/LedgerProxy.sol';
import './gen/MemberProxy.sol';
import './gen/VotePoolProxy.sol';
import './gen/ShareProxy.sol';

/**
 * @title DAOs contract global DAOs manage
 */
contract DAOs is Upgrade, Initializable, Ownable, IDAOs {
	// using EnumerableSet for EnumerableSet.AddressSet;
	using EnumerableMap for EnumerableMap.UintToAddressMap;

	struct DAOIMPLs {
		address   DAO;
		address   Member;
		address   VotePool;
		address   Ledger;
		address   Asset;
		address   AssetShell;
		address   Share;
	}
	struct InitMemberArgs {
		string name;
		string description;
		string baseURI;
		Member.MintMemberArgs[] members;
		uint256 executor;
	}

	struct InitVotePoolArgs {
		string  description;
		uint256 lifespan;
	}

	struct InitLedgerArgs {
		string  description;
	}

	struct InitAssetArgs {
		string  name;
		string  description;
		string  image;
		string  external_link;
		uint32  seller_fee_basis_points_first;
		uint32  seller_fee_basis_points_second;
		address fee_recipient;
		string  base_contract_uri;
		string  base_uri;
	}

	EnumerableMap.UintToAddressMap private  _DAOs; // global DAOs list
	DAOIMPLs                       public   defaultIMPLs; // default logic impl
	address                        private  _operator;
	uint256[49]                    private  __; // reserved storage space

	function initDAOs() external initializer {
		initOwnable();
	}

	function setDefaultIMPLs(DAOIMPLs memory IMPLs) public onlyOwner {
		defaultIMPLs = IMPLs;
	}

	function operator() view public override returns (address) {
		return _operator;
	}

	function setOperator(address operator) public onlyOwner {
		_operator = operator;
	}

	/**
	 * @dev deploy() deploy common voting DAO
	 */
	function deploy(
		DAO.InitDAOArgs  calldata    daoArgs,           address                      operator,
		InitMemberArgs   calldata    memberArgs,        InitVotePoolArgs calldata    votePoolArgs
	) public returns (DAO host) {
		uint256 id = uint256(keccak256(bytes(daoArgs.name)));

		require(!_DAOs.contains(id), "#DAOs.deploy DAO with corresponding name already exists");

		host          = DAO( address(new DAOProxy(defaultIMPLs.DAO)) );
		Member member = Member( address(new MemberProxy(defaultIMPLs.Member)) );
		VotePool root = VotePool( address(new VotePoolProxy(defaultIMPLs.VotePool)) );

		member.initMember(address(host), memberArgs.name, memberArgs.description, memberArgs.baseURI, address(0), memberArgs.members);
		root.initVotePool(address(host), votePoolArgs.description, votePoolArgs.lifespan);
		host.initDAO(this, daoArgs, address(root), operator, address(member));

		_DAOs.set(id, address(host));

		if (memberArgs.executor != 0)
			member.setExecutor(memberArgs.executor);

		emit Created(address(host));
	}

	/**
	 * @dev makeAssetSales() deploy asset sales DAO
	 */
	function deployAssetSalesDAO(
		DAO.InitDAOArgs    calldata    daoArgs,           address                        operator,
		InitMemberArgs     calldata    memberArgs,        InitVotePoolArgs   calldata    votePoolArgs,
		InitLedgerArgs     calldata    ledgerArgs,        InitAssetArgs      calldata    assetArgs
	) public returns (DAO host) {

		host = deploy(daoArgs, address(this), memberArgs, votePoolArgs);
		// sales
		Ledger      ledger      = Ledger( payable(address(new LedgerProxy(defaultIMPLs.Ledger))) );
		Asset       asset       = Asset( address(new AssetProxy(defaultIMPLs.Asset)));
		AssetShell  assetFirst  = AssetShell( payable(address(new AssetShellProxy(defaultIMPLs.AssetShell))));
		AssetShell  assetSecond = AssetShell( payable(address(new AssetShellProxy(defaultIMPLs.AssetShell))));

		Asset.InitContractURI memory uri;
		uri.name                    = assetArgs.name;
		uri.description             = assetArgs.description;
		uri.image                   = assetArgs.image;
		uri.external_link           = assetArgs.external_link;
		uri.base_contract_uri       = assetArgs.base_contract_uri;
		uri.base_uri                = assetArgs.base_uri;
		uri.fee_recipient           = assetArgs.fee_recipient;
		//uri.seller_fee_basis_points = 0;

		ledger.initLedger(address(host), ledgerArgs.description, address(0));
		asset.initAsset(address(host), address(0), uri);

		uri.seller_fee_basis_points = assetArgs.seller_fee_basis_points_second;
		assetSecond.initAssetShell(address(host), address(0), IAssetShell.SaleType.kSecond, uri);

		uri.seller_fee_basis_points = assetArgs.seller_fee_basis_points_first;
		assetFirst.initAssetShell(address(host), address(0), IAssetShell.SaleType.kFirst, uri);

		// set modules
		host.setModule(Module_LEDGER_ID, address(ledger));
		host.setModule(Module_ASSET_ID, address(asset));
		host.setModule(Module_ASSET_First_ID, address(assetFirst));
		host.setModule(Module_ASSET_Second_ID, address(assetSecond));

		host.setOperator(operator); // change to raw operator
	}

	function deployShare(
		IDAO host, address operator,
		uint256 totalSupply, uint256 maxSupply,
		string calldata name, string calldata symbol, string calldata description) public override returns (address) {
		Share share = Share( address(new ShareProxy(defaultIMPLs.Share)));
		share.initShare(address(host), operator, totalSupply, maxSupply, name, symbol, description);
		return address(share);
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
	function get(string memory name) view public returns (DAO) {
		return DAO(_DAOs.get(uint256(keccak256(bytes(name)))));
	}

	/**
	 * @dev at(id) get DAO object from index
	 * @param index uint256 dao index
	 * @return Returns the IDAO interface address and key
	 */
	function at(uint256 index) view external returns (DAO) {
		address addr;
		(, addr) = _DAOs.at(index);
		return DAO(addr);
	}

	/**
	 * @dev Returns the implementation contract address
	 */
	function impl() view external returns (address) {
		return _impl;
	}

	/**
	 * @dev upgrade(address) upgrade contracts
	 */
	function upgrade(address impl_) public onlyOwner {
		_impl = impl_;
	}
}