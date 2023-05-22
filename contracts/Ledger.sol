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

	uint256[16] private __; // reserved storage space

	function initLedger(address host, string memory description, address operator) external {
		initModule(host, description, operator);
		_registerInterface(Ledger_Type);
	}

	function receiveBalance() internal {
		if (msg.value != 0)
			emit Receive(msg.sender, msg.value);
	}

	function getBalance() view public returns (uint256) {
		return address(this).balance;
	}

	function release(uint256 amount, string memory description, IERC20 erc20) external payable Check(Action_Ledger_Release) {
		receiveBalance();

		bool isERC20 = address(erc20) != address(0);
		uint256 cur_amount;

		if (isERC20) { // is erc20
			_host.first().withdrawERC20(erc20);
			_host.second().withdrawERC20(erc20);
			cur_amount = erc20.balanceOf(address(this));
		} else {
			cur_amount = getBalance();
		}

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
					uint256 balance = share * unit;
					if (isERC20) {
						erc20.transfer(owner, balance);
					} else {
						owner.sendValue(balance);
					}
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
				uint256 balance = info.votes * unit;
				if (isERC20) {
					erc20.transfer(owner, balance);
				} else {
					owner.sendValue(balance);
				}
			}
		}

		emit ReleaseLog(msg.sender, amount, description, address(erc20));
	}

	function deposit(string memory name, string memory description) public payable {
		if (msg.value != 0)
			emit Deposit(msg.sender, msg.value, name, description);
	}

	function assetIncome(
		address token,  uint256 tokenId,
		address source, address from, address to,
		uint256 price,  uint256 count, IAssetShell.SaleType saleType, uint256 amount, address erc20
	) public payable override {
		if (msg.sender != address(_host.first()) && msg.sender != address(_host.second())
		) revert("#Ledger.assetIncome access denied");
		emit AssetIncome(token, tokenId, source, from, to, amount, price, count, saleType, erc20);
	}

	function withdraw(uint256 amount, address target, string memory description)
		external payable override Check(Action_Ledger_Withdraw) 
	{
		if (target == address(0)) revert AddressEmpty();
		receiveBalance();
		target.sendValue(amount);
		emit Withdraw(target, amount, description);
	}

	receive() external payable {
		receiveBalance();
	}

	fallback() external payable {
		receiveBalance();
	}

}