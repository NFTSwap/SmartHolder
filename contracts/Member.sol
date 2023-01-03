// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

pragma experimental ABIEncoderV2;

import './Asset.sol';
import '../openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract Member is IMember, ERC721_Module {
	using EnumerableSet for EnumerableSet.UintSet;

	struct Info0 {
		Info                  info;
		EnumerableSet.UintSet permissions; // permissions
	}

	mapping(uint256=>Info0) private  _infoMap; // member info, member id => member info
	EnumerableSet.UintSet   private  _infoList; // member table list
	uint256                 private  _votes; // all vote total
	uint256                 internal _executor; // executor
	uint256[16]             private  __; // reserved storage space

	struct MintMemberArgs {
		address   owner;
		Info      info;
		string    tokenURI;
		uint256[] permissions;
	}

	function initMember(
		address host, string memory name, string memory description,
		address operator, MintMemberArgs[] memory members) external
	{
		initModule(host, description, operator);
		initERC721(name, name);
		_registerInterface(Member_Type);

		for (uint256 i = 0; i < members.length; i++)
			mint(members[i].owner, members[i].info, members[i].tokenURI, members[i].permissions);
	}

	function mint(address owner, Info memory info, string memory tokenURI, uint256[] memory permissions) private {
		_mint(owner, info.id);

		Info0 storage i0 = _infoMap[info.id];
		Info storage info_ = i0.info;
		info_.id           = info.id;
		info_.name         = info.name;
		info_.description  = info.description;
		info_.avatar       = info.avatar;
		info_.votes        = info.votes == 0 ? 1: info.votes; // limit votes to 1

		_votes += info_.votes;

		_infoList.add(info.id);

		// set token uri
		if (bytes(tokenURI).length != 0)
			_setTokenURI(info.id, tokenURI);

		// add permissions
		for (uint256 i = 0; i < permissions.length; i++)
			i0.permissions.add(permissions[i]);
	}

	function remove(uint256 id) public {
		require(isApprovedOrOwner(msg.sender, id) || isPermissionDAO(), "#Member#remove No permission");
		_burn(id);
		_votes -= _infoMap[id].info.votes;
		delete _infoMap[id];
		_infoList.remove(id);
	}

	function create(
		address owner,      string memory tokenURI,
		Info memory info,   uint256[] memory permissions
	) external Check(Action_Member_Create)
	{
		mint(owner, info, tokenURI, permissions);
	}

	function createFrom(
		address owner,             uint256 id,
		string memory tokenURI,    uint256[] memory permissions,
		uint32 votes,              string memory name,
		string memory description, string memory avatar
	) external Check(Action_Member_Create)
	{
		Info memory info;
		info.id = id;
		info.name = name;
		info.votes = votes;
		info.avatar = avatar;
		info.description = description;
		mint(owner, info, tokenURI, permissions);
	}

	function votes() view external override returns (uint256) {
		return _votes;
	}

	function getMemberInfo(uint256 id) view external override returns (Info memory) {
		require(_exists(id), "#Member#info: info query for nonexistent member");
		return _infoMap[id].info;
	}

	function setMemberInfo(uint256 id, string memory name, string memory description, string memory avatar) public {
		require(ownerOf(id) == _msgSender(), "#Member#setMemberInfo: owner no match");
		Info storage info_ = _infoMap[id].info;
		if (bytes(name).length != 0)        info_.name        = name;
		if (bytes(description).length != 0) info_.description = description;
		if (bytes(avatar).length != 0)      info_.avatar      = avatar;
		emit Update(id);
	}

	function setInfo(uint256 id, Info memory info) external {
		setMemberInfo(id, info.name, info.description, info.avatar);
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

	function setExecutor(uint256 id) public OnlyDAO {
		require(_exists(id), "#Member#setExecutor: info query for nonexistent member");
		_executor = id;
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

	function addPermissions(uint256[] memory IDs, uint256[] memory actions) external OnlyDAO {
		for (uint256 i = 0; i < IDs.length; i++) {
			EnumerableSet.UintSet storage permissions = _infoMap[IDs[i]].permissions;
			for (uint256 j = 0; j < actions.length; j++)
				permissions.add(actions[j]);
		}
		emit AddPermissions(IDs, actions);
	}

	function removePermissions(uint256[] memory IDs, uint256[] memory actions) external OnlyDAO {
		for (uint256 i = 0; i < IDs.length; i++) {
			EnumerableSet.UintSet storage permissions = _infoMap[IDs[i]].permissions;
			for (uint256 j = 0; j < actions.length; j++)
				permissions.remove(actions[j]);
		}
		emit RemovePermissions(IDs, actions);
	}

	function addVotes(uint256 id, int32 votes) external OnlyDAO {
		require(_exists(id), "#Member#setVotes: info query for nonexistent member");
		Info storage info = _infoMap[id].info;

		info.votes += uint32(votes);
		_votes += uint32(votes);

		if (votes > 0)
			emit TransferVotes(0, id, uint32(votes));
		else
			emit TransferVotes(id, 0, uint32(-votes));
	}

	function transferVotes(uint256 from, uint256 to, uint32 votes) external OnlyDAO {
		require(_exists(from), "#Member#transferVotes: info query for nonexistent member from");
		require(_exists(to), "#Member#transferVotes: info query for nonexistent member to");
		Info storage infoFrom = _infoMap[from].info;
		Info storage infoTo = _infoMap[to].info;
		require(infoFrom.votes >= votes, "#Member#transferVotes: not votes power enough");

		infoFrom.votes -= uint32(votes);
		infoTo.votes += uint32(votes);

		emit TransferVotes(from, to, votes);
	}

}