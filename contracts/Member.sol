
pragma solidity >=0.6.0 <=0.8.15;

pragma experimental ABIEncoderV2;

import "./ERC721.sol";

contract Member is IMember, ERC721 {

	// event UpdateInfo(uint256 id);

	// member id => member info
	mapping(uint256 => Info) private _infoMap; // 成员信息
	uint256[] private _infoList; // 成员列表
	uint256 private _votes; // 投票权总数

	function initMember(address host, string memory describe, address operator) external initializer {
		initERC721(host, describe, operator);
		_registerInterface(Member_ID);
	}

	function create(address owner, Info memory info) external OnlyDAO {
		_mint(owner, info.id);

		Info storage info_ = _infoMap[info.id];
		info_.id = info.id;
		info_.name = info.name;
		info_.describe = info.describe;
		info_.avatar = info.avatar;
		info_.role = info.role;
		info_.votes = info.votes == 0 ? 1: info.votes;
		// info_.extended = info.extended;
		info_.idx = _infoList.length;

		_votes += info_.votes;

		_infoList.push(info.id);
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
		info_.describe = info.describe;
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

	function exists(uint256 id) view public override returns (bool) {
		return _exists(id);
	}

	function isApprovedOrOwner(address spender, uint256 id) view public returns (bool) {
		return _isCanTransfer(spender, id);
	}

	function total() view public override returns (uint256) {
		return _infoList.length;
	}

}