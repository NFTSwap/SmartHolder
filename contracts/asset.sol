
pragma solidity >=0.6.12 <=0.8.15;

import "./ERC721.sol";

contract Asset is ERC721, IAsset {

	// Equals to `bytes4(keccak256("onERC721LockReceived(address,address,uint256,bytes)"))`
	bytes4 private constant _ERC721_LOCK_RECEIVED = 0x7e154325;

	/*
	 *  bytes4(keccak256('lock(address,uint256,bytes)')) == 0xb88d4fde
	 *
	 *  => 0x80ac58cd ^ 0xc792f45d == 0x473eac90
	 */
	bytes4 private constant _INTERFACE_ID_ERC721_LOCK = 0x473eac90;

	// Mapping from token ID to lock address
	mapping (uint256 => address) private _tokenLocks;

	function initAsset(address host, string memory info, address operator) external {
		initERC721(host, "DAO Asset", operator);
		_registerInterface(Asset_ID);
		_registerInterface(_INTERFACE_ID_ERC721_LOCK);
	}

	function _burn(uint256 tokenId) internal virtual override {
		// NOOP
	}

	function lock(address to, uint256 tokenId, bytes calldata data) public virtual override {
		address locked = _tokenLocks[tokenId];
		if (locked == to) {
			return;
		}

		address owner = ownerOf(tokenId);
		require(owner != to, "ERC721: lock to current owner");

		if (to == address(0)) {
			require(locked == _msgSender(), "ERC721: unlock no permission");
			delete _tokenLocks[tokenId];
		} else {
			require(owner == _msgSender() || isApprovedForAll(owner, _msgSender()), "ERC721: lock caller is not owner nor locked for all");
			_tokenLocks[tokenId] = to;
			require(_checkOnERC721LockReceived(owner, to, tokenId, data), "ERC721: transfer to non ERC721LockReceiver implementer");
		}
		emit Lock(tokenId, ownerOf(tokenId), to);
	}

	function _isCanTransfer(address spender, uint256 tokenId) internal view virtual override returns (bool) {
		require(_exists(tokenId), "#ERC721#_isCanTransfer ERC721: operator query for nonexistent token");
		if (_tokenLocks[tokenId] != address(0)) {
			return _tokenLocks[tokenId] == spender;
		} else {
			address owner = ownerOf(tokenId);
			return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
		}
	}

	function _checkOnERC721LockReceived(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
		if (!to.isContract()) return true;
		bytes memory data = abi.encodeWithSelector(
			IERC721Receiver(to).onERC721Received.selector, _msgSender(), from, tokenId, _data
		);
		return checkCall(to, data, "ERC721: lock to non ERC721LockReceiver implementer") == _ERC721_LOCK_RECEIVED;
	}

}
