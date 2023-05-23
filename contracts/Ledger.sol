// SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

pragma experimental ABIEncoderV2;

import './libs/Interface.sol';
import './Module.sol';

/**
 * @title Ledger manage
 */
contract Ledger is ILedger, Module {
	using AddressExp for address;

	bool private _IsDisableReceiveLog;

	uint256[16] private __; // reserved storage space

	modifier _DisableReceiveLog() {
		_IsDisableReceiveLog = true;
		_;
		_IsDisableReceiveLog = false;
	}

	receive() external payable {
		receiveBalance();
	}

	fallback() external payable {
		receiveBalance();
	}

	function initLedger(address host, string memory description, address operator) external {
		initModule(host, description, operator);
		_registerInterface(Ledger_Type);
	}

	function getBalance() view public returns (uint256) {
		return address(this).balance;
	}

	function receiveBalance() internal {
		if (msg.value != 0 && !_IsDisableReceiveLog)
			emit Receive(msg.sender, msg.value);
	}

	function deposit(string memory name, string memory description) public payable {
		if (msg.value != 0)
			emit Deposit(msg.sender, msg.value, name, description);
	}

	function withdraw(IERC20 erc20, uint256 amount, address target, string memory description) public
		Check(Action_Ledger_Withdraw)
		_DisableReceiveLog
	{
		if (target == address(0)) revert AddressEmpty();

		_host.first().withdrawBalance(erc20);
		_host.second().withdrawBalance(erc20);

		if (address(erc20) == address(0)) {
			target.sendValue(amount);
		} else {
			erc20.transfer(target, amount);
		}
		emit Withdraw(address(erc20), target, amount, description);
	}

	function release(IERC20 erc20, uint256 amount, string memory description) external
		Check(Action_Ledger_Release)
		_DisableReceiveLog
	{
		_host.first().withdrawBalance(erc20);
		_host.second().withdrawBalance(erc20);

		bool isERC20 = address(erc20) != address(0);
		uint256 cur_amount = isERC20 ? erc20.balanceOf(address(this)): getBalance();

		// insufficient balance;
		if (cur_amount < amount) revert AmountMinimumLimit();

		IShare s = _host.share();
		IMember m = _host.member();

		if (address(s) != address(0)) { // Same share but different rights
			// decimals = 5 , 1/100_000
			uint256 totalSupply = s.totalSupply() >> 10;// 1/1024;
			uint256 unit = amount / totalSupply;

			if (unit == 0) revert InsufficientBalance();

			uint256 owners = s.totalOwners();
			address owner;
			uint256 share;

			for (uint256 i = 0; i < owners; i++) {
				(owner,share) = s.indexAt(i);
				share >>= 10; // 1/1024
				if (share != 0) {
					uint256 value = share * unit;
					if (isERC20) {
						erc20.transfer(owner, value);
					} else {
						owner.sendValue(value);
					}
					emit Release(0, owner, address(erc20), value);
				}
			}
		} else {
			uint256 votes = m.votes();
			uint256 unit = amount / votes;

			// insufficient balance release
			if (unit == 0) revert AmountMinimumLimit();

			uint256 total = m.total();
			IMember.Info memory info;

			for (uint256 i = 0; i < total; i++) {
				info = m.indexAt(i);
				address owner = m.ownerOf(info.id);
				uint256 value = info.votes * unit;
				if (isERC20) {
					erc20.transfer(owner, value);
				} else {
					owner.sendValue(value);
				}
				emit Release(info.id, owner, address(erc20), value);
			}
		}

		emit ReleaseLog(msg.sender,  address(erc20), amount, description);
	}

}