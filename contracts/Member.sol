
pragma solidity >=0.6.0 <=0.8.15;

pragma experimental ABIEncoderV2;

import "./ERC721.sol";

contract Member is IMember, ERC721 {

	// event UpdateInfo(uint256 id);

	// member id => member info
	mapping(uint256 => Info) private _infoMap; // 成员信息
	uint256[] private _infoList; // 成员列表
	uint256 private _votes; // 投票权总数

	struct InitMemberArgs {
		address owner;
		Info info;
	}

	function initMember(address host, string memory description, address operator, InitMemberArgs[] memory members) external initializer {
		initERC721(host, description, operator);
		_registerInterface(Member_ID);

		for (uint256 i = 0; i < members.length; i++) {
			create0(members[i].owner, members[i].info);
		}
	}

	function create0(address owner, Info memory info) private {
		_mint(owner, info.id);

		Info storage info_ = _infoMap[info.id];
		info_.id = info.id;
		info_.name = info.name;
		info_.description = info.description;
		info_.avatar = info.avatar;
		info_.role = info.role;
		info_.votes = info.votes == 0 ? 1: info.votes;
		// info_.extended = info.extended;
		info_.idx = _infoList.length;

		_votes += info_.votes;

		_infoList.push(info.id);
	}

	function remove(uint256 id) public {
		require(isApprovedOrOwner(msg.sender, id) || isPermissionDAO(), "#Member#remove No permission");
		_burn(id);

		Info storage info = _infoMap[id];
		uint256 idx = info.idx;

		if (_infoList.length > 1) {
			uint256 lastId = _infoList[_infoList.length - 1];
			_infoMap[lastId].idx = idx;
			_infoList[idx] = lastId;
		}
		_votes -= info.votes;
		delete _infoMap[id];
		_infoList.pop();
	}

	function create(address owner, Info memory info) external OnlyDAO {
		create0(owner, info);
	}

	function create2(
		address owner, uint256 id, uint32 votes,
		string memory name, string memory description, string memory avatar
	) external OnlyDAO 
	{
		Info memory info;
		info.id = id;
		info.name = name;
		info.votes = votes;
		info.avatar = avatar;
		info.description = description;
		create0(owner, info);
	}

	function votes() view external override returns (uint256) {
		return _votes;
	}

	function setBaseURI(string memory baseURI) external OnlyDAO {
		_setBaseURI(baseURI);
	}

	function setTokenURI(uint256 id, string memory uri) external {
		require(ownerOf(id) == _msgSender(), "#Member#setTokenURI: owner no match");
		_setTokenURI(id, uri);
	}

	function setInfo(uint256 id, Info memory info) external {
		require(ownerOf(id) == _msgSender(), "#Member#setInfo: owner no match");
		Info storage info_ = _infoMap[id];
		info_.name = info.name;
		info_.description = info.description;
		info_.avatar = info.avatar;
		// info_.extended = info.extended;
		emit UpdateInfo(id);
	}

	function getInfo(uint256 id) view external override returns (Info memory) {
		require(_exists(id), "#Member#info: info query for nonexistent member");
		return _infoMap[id];
	}

	function indexAt(uint256 index) view public override returns (Info memory) {
		require(index < _infoList.length, "#Member#indexAt Index out of bounds");
		return _infoMap[_infoList[index]];
	}

	function isExists(uint256 id) view public override returns (bool) {
		return _exists(id);
	}

	function isApprovedOrOwner(address spender, uint256 id) view public returns (bool) {
		return _havePermission(spender, id);
	}

	function total() view public override returns (uint256) {
		return _infoList.length;
	}

}