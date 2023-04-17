// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

pragma experimental ABIEncoderV2;

import './Asset.sol';
import './libs/Strings.sol';
import '../openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract Member is IMember, ERC721Module {
	using EnumerableSet for EnumerableSet.UintSet;
	using StringsExp for bytes;
	using Strings for uint256;
	using Strings for address;

	struct Info_ {
		Info                  info;
		EnumerableSet.UintSet permissions; // permissions
	}

	mapping(uint256=>Info_) private  _infoMap; // member info, member id => member info
	EnumerableSet.UintSet   private  _infoList; // member table list
	uint256                 private  _votes; // all vote total
	uint256                 internal _executor; // executor
	uint256[16]             private  __; // reserved storage space

	struct MintMemberArgs {
		address   owner;
		Info      info;
		uint256[] permissions;
	}

	function initMember(
		address host, string memory name, string memory description,
		string memory baseURI, address operator, MintMemberArgs[] memory members) external
	{
		initModule(host, description, operator);
		initERC721(name, name);
		_registerInterface(Member_Type);
		_setBaseURI(baseURI);

		for (uint256 i = 0; i < members.length; i++)
			mint(members[i].owner, members[i].info, members[i].permissions);
	}

	function mint(address owner, Info memory info, uint256[] memory permissions) private {
		_mint(owner, info.id);

		Info_ storage i0   = _infoMap[info.id];
		Info storage info_ = i0.info;
		info_.id           = info.id;
		info_.name         = info.name;
		info_.description  = info.description;
		info_.image       = info.image;
		info_.votes        = info.votes == 0 ? 1: info.votes; // limit votes to 1

		_votes += info_.votes;

		_infoList.add(info.id);

		// add permissions
		for (uint256 i = 0; i < permissions.length; i++)
			i0.permissions.add(permissions[i]);
	}

	function remove(uint256 id) public {
		if (!isApprovedOrOwner(msg.sender, id) && !isPermissionDAO()) revert PermissionDenied();
		_burn(id);
		_votes -= _infoMap[id].info.votes;
		delete _infoMap[id];
		_infoList.remove(id);
	}

	function create(
		address owner, Info memory info, uint256[] memory permissions
	) external Check(Action_Member_Create)
	{
		mint(owner, info, permissions);
	}

	function createFrom(
		address owner,       uint256 id,
		uint32 votes_,        uint256[] memory permissions,
		string memory name,  string memory description, string memory image
	) external Check(Action_Member_Create)
	{
		Info memory info;
		info.id = id;
		info.name = name;
		info.votes = votes_;
		info.image = image;
		info.description = description;
		mint(owner, info, permissions);
	}

	/**
	 * @dev request join to DAO, create join vote proposal
	 */
	function requestJoin(address owner, Info memory info, uint256[] memory permissions) public returns (uint256 id) {
		if (owner == address(0)) revert AddressEmpty(); // mint to the zero address
		if (_exists(info.id)) revert MemberAlreadyExists(); // token already minted

		uint256 salt = block.number / 5000;
		id = uint256(keccak256(abi.encodePacked("requestJoin", msg.sender.toHexString(), salt.toString())));

		if (IVotePool(_host.root()).exists(id)) revert MemberRequestJoinAlreadyExists();

		address[] memory target = new address[](1);
		bytes[] memory data = new bytes[](1);

		target[0] = address(this);
		data[0] = abi.encodeWithSelector(this.create.selector, owner, info, permissions);

		IVotePool.Proposal memory pro;
		pro.id          = id;
		pro.originId    = 0; // member id
		pro.target      = target;
		pro.lifespan    = 0;
		pro.passRate    = 5001;
		pro.loopCount   = 0;
		pro.loopTime    = 0;
		pro.name        = "request join to DAO";
		pro.description = info.name;
		pro.data        = data;

		IVotePool(_host.root()).create(pro);
	}

	/**
	 * @dev Returns the token URI of member
	 */
	function tokenURI(uint256 tokenId) view public override(ERC721,IERC721Metadata) returns (string memory uri) {
		Info storage info = _infoMap[tokenId].info;
		bytes memory a = abi.encodePacked("?name=0xs",                      bytes(info.name).toHexString());
		bytes memory b = abi.encodePacked("&description=0xs",               bytes(info.description).toHexString());
		bytes memory c = abi.encodePacked("&image=0xs",                     bytes(info.image).toHexString());
		uri = string(abi.encodePacked(baseURI(), a, b, c));
	}

	function votes() view external override returns (uint256) {
		return _votes;
	}

	function getMemberInfo(uint256 id) view external override returns (Info memory) {
		checkExists(id); // info query for nonexistent member
		return _infoMap[id].info;
	}

	function setMemberInfo(uint256 id, string memory name, string memory description, string memory image) public {
		// require(ownerOf(id) == _msgSender(), "#Member#setMemberInfo: owner no match");
		if (ownerOf(id) != _msgSender()) revert PermissionDenied();
		Info storage info_ = _infoMap[id].info;
		if (bytes(name).length != 0)        info_.name        = name;
		if (bytes(description).length != 0) info_.description = description;
		if (bytes(image).length != 0)       info_.image      = image;
		emit Update(id);
	}

	function setInfo(uint256 id, Info memory info) external {
		setMemberInfo(id, info.name, info.description, info.image);
	}

	function indexAt(uint256 index) view public override returns (Info memory) {
		return _infoMap[_infoList.at(index)].info;
	}

	function isApprovedOrOwner(address spender, uint256 id) view public returns (bool) {
		return _havePermission(spender, id);
	}

	function total() view public override returns (uint256) {
		return _infoList.length();
	}

	function executor() view public returns(uint256) {
		return _executor;
	}

	function checkExists(uint256 id) view internal {
		if (!_exists(id)) revert MemberNonExists();
	}

	function setExecutor(uint256 id) public OnlyDAO {
		checkExists(id); // info query for nonexistent member
		_executor = id;
		emit Change(Change_Tag_Member_Set_Executor, uint160(id));
	}

	function isPermission(address owner, uint256 action) view external override returns (bool) {
		uint256 len = balanceOf(owner);
		for (uint256 i = 0; i < len; i++) {
			uint256 id = tokenOfOwnerByIndex(owner, i);
			if (isPermissionFrom(id, action))
				return true;
		}
		return false;
	}

	function isPermissionFrom(uint256 id, uint256 action) view public override returns (bool) {
		return _infoMap[id].permissions.contains(action);
	}

	function setPermissions(uint256 id, uint256[] memory addActions, uint256[] memory removeActions) external OnlyDAO {
		checkExists(id); // check info query for nonexistent member

		EnumerableSet.UintSet storage permissions = _infoMap[id].permissions;
		for (uint256 j = 0; j < addActions.length; j++)
			permissions.add(addActions[j]);
		for (uint256 j = 0; j < removeActions.length; j++)
			permissions.remove(removeActions[j]);
		emit SetPermissions(id, addActions, removeActions);
	}

	function addVotes(uint256 id, int32 votes) external OnlyDAO {
		checkExists(id); // check info query for nonexistent member

		Info storage info = _infoMap[id].info;

		info.votes += uint32(votes);
		_votes += uint32(votes);

		if (votes > 0)
			emit TransferVotes(0, id, uint32(votes));
		else
			emit TransferVotes(id, 0, uint32(-votes));
	}

	function transferVotes(uint256 from, uint256 to, uint32 votes) external OnlyDAO {
		checkExists(from); // check info query for nonexistent member from
		checkExists(to); // check info query for nonexistent member to

		Info storage infoFrom = _infoMap[from].info;
		Info storage infoTo = _infoMap[to].info;
		// require(infoFrom.votes >= votes, "#Member#transferVotes: not votes power enough");
		if (infoFrom.votes < votes) revert InsufficientVotesInMember();

		infoFrom.votes -= uint32(votes);
		infoTo.votes += uint32(votes);

		emit TransferVotes(from, to, votes);
	}

}