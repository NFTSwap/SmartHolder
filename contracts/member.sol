
pragma solidity ^0.8.15;

import "./erc721.sol";

contract Member is ERC721 {

	enum Role {
		DEFAULT
	}

	struct Info {
		uint256 id;
		string name;
		string info;
		string avatar;
		Role role;
		uint32 votes; // 投票权
		uint256 idx;
		bytes1[] extended;
	}

	event UpdateInfo(uint256 id);

	/*
	 * bytes4(keccak256('initMember(string,string,address,address,address,address,address,address)')) == 0x98fded77
	 */
	bytes4 public constant ID = 0x98fded77;

	// member id => member info
	mapping(uint256 => Info) private _info; // 成员信息
	uint256[] private _infoList; // 成员列表
	uint256 private _votes; // 投票权总数

	function initMember(address host, string memory info, address operator) external initializer {
		initERC721(host, info, operator);
		_registerInterface(ID);
	}

	function create(address owner, Info memory info) external onlyDAO {
		_mint(owner, info.id);

		Info storage info_ = _info[id];
		info_.id = info.id;
		info_.name = info.name;
		info_.info = info.info;
		info_.avatar = info.avatar;
		info_.role = info.role;
		info_.vote = info.vote == 0 ? 1: info.vote;
		info_.extended = info.extended;
		info_.idx = _infoList.length;

		_votes += info_.vote;

		_infoList.push(info.id);
	}

	function votes() view public returns (uint256) {
		return _votes;
	}

	function setBaseURI(string memory baseURI) external onlyDAO {
		_setBaseURI(baseURI);
	}

	function setTokenURI(uint256 id, string memory uri) external {
		require(ownerOf(id) == _msgSender(), "#Member#setTokenURI: owner no match");
		_setTokenURI(id, uri);
	}

	function setInfo(uint256 id, Info memory info) external {
		require(ownerOf(id), "#Member#setInfo: owner no match");
		Info storage info_ = _info[id];
		info_.name = info.name;
		info_.info = info.info;
		info_.avatar = info.avatar;
		info_.extended = info.extended;
		emit UpdateInfo(id);
	}

	function info(uint256 id) view public returns (Info memory) {
		require(_exists(id), "#Member#info: info query for nonexistent member");
		return _info[id];
	}

	function exists(uint256 id) view public returns (bool) {
		return _exists(id);
	}

	function isApprovedOrOwner(address spender, uint256 id) view public returns (bool) {
		return _isApprovedOrOwner(spender, id);
	}

	function total() view public returns (uint256) {
		return _infoList.length;
	}

}