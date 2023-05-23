// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ~0.8.17;

import './Interface.sol';
import './Address.sol';
import './Strings.sol';
import './Context.sol';

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155 is Context, IERC1155_1 {
	using Address for address;

	// Mapping from token ID to account balances
	mapping(uint256 => mapping(address => uint256)) private _balances;

	// Mapping from account to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	// Optional base URI
	string public baseURI;

	// Optional mapping for token URIs
	mapping(uint256 => string) internal _tokenURIs;
	mapping(uint256 => uint256) private _totalSupply;

	/**
	 * @dev init ERC1155
	 */
	function initERC1155(string memory baseURI_) internal {
		baseURI = baseURI_;
	}

	/**
		* @dev Total amount of tokens in with a given id.
		*/
	function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _totalSupply[id];
	}

	/**
		* @dev Indicates whether any token exist with a given id, or not.
		*/
	function exists(uint256 id) public view virtual returns (bool) {
			return ERC1155.totalSupply(id) > 0;
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface1155(bytes4 interfaceId) internal pure returns (bool) {
		return
			interfaceId == type(IERC1155).interfaceId ||
			interfaceId == type(IERC1155MetadataURI).interfaceId
		;
	}

	/**
		* @dev See {IERC1155MetadataURI-uri}.
		*
		* This implementation returns the concatenation of the `_baseURI`
		* and the token-specific uri if the latter is set
		*
		* This enables the following behaviors:
		*
		* - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
		*   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
		*   is empty per default);
		*
		* - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
		*   which in most cases will contain `ERC1155._uri`;
		*
		* - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
		*   uri value set, then the result is empty.
		*/
	function uri(uint256 tokenId) public view virtual override returns (string memory) {
		string memory tokenURI = _tokenURIs[tokenId];

		// If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
		return bytes(tokenURI).length > 0 ? string(abi.encodePacked(baseURI, tokenURI)): baseURI;
	}

	/**
		* @dev Sets `tokenURI` as the tokenURI of `tokenId`.
		*/
	function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
		_tokenURIs[tokenId] = tokenURI;
		emit URI(uri(tokenId), tokenId);
	}

	/**
	 * @dev See {IERC1155-balanceOf}.
	 *
	 * Requirements:
	 *
	 * - `account` cannot be the zero address.
	 */
	function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
		require(account != address(0), "ERC1155: address zero is not a valid owner");
		return _balances[id][account];
	}

	/**
	 * @dev See {IERC1155-balanceOfBatch}.
	 *
	 * Requirements:
	 *
	 * - `accounts` and `ids` must have the same length.
	 */
	function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
		public
		view
		virtual
		override
		returns (uint256[] memory)
	{
		require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

		uint256[] memory batchBalances = new uint256[](accounts.length);

		for (uint256 i = 0; i < accounts.length; ++i) {
			batchBalances[i] = balanceOf(accounts[i], ids[i]);
		}

		return batchBalances;
	}

	/**
	 * @dev See {IERC1155-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(_msgSender(), operator, approved);
	}

	/**
	 * @dev See {IERC1155-isApprovedForAll}.
	 */
	function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
		return _operatorApprovals[account][operator];
	}

	/**
	 * @dev See {IERC1155-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not token owner or approved"
		);
		_safeTransferFrom(from, to, id, amount, data);
	}

	/**
	 * @dev See {IERC1155-safeBatchTransferFrom}.
	 */
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		/*require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not token owner or approved"
		);
		_safeBatchTransferFrom(from, to, ids, amounts, data);*/
		revert MethodNotImplemented();
	}

	/**
	 * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `from` must have a balance of tokens of type `id` of at least `amount`.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
	 * acceptance magic value.
	 */
	function _safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: transfer to the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer0(operator, from, to, ids, amounts, data);

		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}
		_balances[id][to] += amount;

		emit TransferSingle(operator, from, to, id, amount);

		uint256 balance = _balances[id][to];

		_afterTokenTransfer(operator, from, to, ids, amounts, data);

		if (_balances[id][to] == balance)
			_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
	 *
	 * Emits a {TransferBatch} event.
	 *
	 * Requirements:
	 *
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	 * acceptance magic value.
	 */
	/*
	function _safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
		require(to != address(0), "ERC1155: transfer to the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer0(operator, from, to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; ++i) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
			unchecked {
				_balances[id][from] = fromBalance - amount;
			}
			_balances[id][to] += amount;
		}

		emit TransferBatch(operator, from, to, ids, amounts);

		_afterTokenTransfer(operator, from, to, ids, amounts, data);

		_doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
	}*/

	/**
	 * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
	 * acceptance magic value.
	 */
	function _mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer0(operator, address(0), to, ids, amounts, data);

		_balances[id][to] += amount;
		emit TransferSingle(operator, address(0), to, id, amount);

		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

		_doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
	 *
	 * Emits a {TransferBatch} event.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	 * acceptance magic value.
	 */
	/*
	function _mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer0(operator, address(0), to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; i++) {
			_balances[ids[i]][to] += amounts[i];
		}

		emit TransferBatch(operator, address(0), to, ids, amounts);

		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

		_doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
	}*/

	/**
	 * @dev Destroys `amount` tokens of token type `id` from `from`
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `from` must have at least `amount` tokens of token type `id`.
	 */
	function _burn(
		address from,
		uint256 id,
		uint256 amount
	) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer0(operator, from, address(0), ids, amounts, "");

		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}

		emit TransferSingle(operator, from, address(0), id, amount);

		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
	 *
	 * Emits a {TransferBatch} event.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 */
	/*
	function _burnBatch(
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer0(operator, from, address(0), ids, amounts, "");

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
			unchecked {
				_balances[id][from] = fromBalance - amount;
			}
		}

		emit TransferBatch(operator, from, address(0), ids, amounts);

		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}*/

	/**
	 * @dev Approve `operator` to operate on all of `owner` tokens
	 *
	 * Emits an {ApprovalForAll} event.
	 */
	function _setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) internal virtual {
		require(owner != operator, "ERC1155: setting approval status for self");
		_operatorApprovals[owner][operator] = approved;
		emit ApprovalForAll(owner, operator, approved);
	}

	function _beforeTokenTransfer0(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal {
		_beforeTokenTransfer(operator,from,to,ids,amounts,data);

		if (from == address(0)) {
			for (uint256 i = 0; i < ids.length; ++i) {
				_totalSupply[ids[i]] += amounts[i];
			}
		}

		if (to == address(0)) {
			for (uint256 i = 0; i < ids.length; ++i) {
				uint256 id = ids[i];
				uint256 amount = amounts[i];
				uint256 supply = _totalSupply[id];
				require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
				unchecked {
					_totalSupply[id] = supply - amount;
				}
			}
		}
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting
	 * and burning, as well as batched variants.
	 *
	 * The same hook is called on both single and batched variants. For single
	 * transfers, the length of the `ids` and `amounts` arrays will be 1.
	 *
	 * Calling conditions (for each `id` and `amount` pair):
	 *
	 * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * of token type `id` will be  transferred to `to`.
	 * - When `from` is zero, `amount` tokens of token type `id` will be minted
	 * for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
	 * will be burned.
	 * - `from` and `to` are never both zero.
	 * - `ids` and `amounts` have the same, non-zero length.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}

	/**
	 * @dev Hook that is called after any token transfer. This includes minting
	 * and burning, as well as batched variants.
	 *
	 * The same hook is called on both single and batched variants. For single
	 * transfers, the length of the `id` and `amount` arrays will be 1.
	 *
	 * Calling conditions (for each `id` and `amount` pair):
	 *
	 * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * of token type `id` will be  transferred to `to`.
	 * - When `from` is zero, `amount` tokens of token type `id` will be minted
	 * for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
	 * will be burned.
	 * - `from` and `to` are never both zero.
	 * - `ids` and `amounts` have the same, non-zero length.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _afterTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}

	function _doSafeTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
				if (response != IERC1155Receiver.onERC1155Received.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non-ERC1155Receiver implementer");
			}
		}
	}

	/*
	function _doSafeBatchTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
				bytes4 response
			) {
				if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non-ERC1155Receiver implementer");
			}
		}
	}*/

	function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;

		return array;
	}
}
