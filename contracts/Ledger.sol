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
		if (msg.value != 0) {
			emit Receive(msg.sender, msg.value);
		}
	}

	function getBalance() view public returns (uint256) {
		return address(this).balance;
	}

	function release(uint256 amount, string memory description) external payable Check(Action_Ledger_Release) {
		receiveBalance();

		uint256 curamount = address(this).balance;
		// require(curamount >= amount, "#Ledger#release insufficient balance");
		if (curamount < amount) revert InsufficientBalance();

		IShare s = _host.share();
		IMember m = _host.member();

		if (address(s) != address(0)) { // Same share but different rights
			// decimals = 5 , 1/100_000
			uint256 totalSupply = s.totalSupply() >> 10;// 1/1024;
			uint256 unit = amount / totalSupply;

			if (unit == 0) revert InsufficientBalance();

			uint256 owners = s.totalOwners();
			address owner;
			uint256 amount1;

			for (uint256 i = 0; i < owners; i++) {
				(owner,amount1) = s.indexAt(i);
				amount1 >>= 10; // 1/1024
				if (amount1 != 0) {
					uint256 balance = amount1 * unit;
					owner.sendValue(balance);
					emit Release(0, owner, balance);
				}
			}
		} else {
			uint256 votes = m.votes();
			uint256 unit = amount / votes;

			// require(unit != 0 , "#Ledger#release insufficient balance release");
			if (unit == 0) revert InsufficientBalance();

			uint256 total = m.total();
			IMember.Info memory info;

			for (uint256 i = 0; i < total; i++) {
				info = m.indexAt(i);
				address owner = m.ownerOf(info.id);
				uint256 balance = info.votes * unit;
				owner.sendValue(balance);
				emit Release(info.id, owner, balance);
			}
		}

		emit ReleaseLog(msg.sender, amount, description);
	}

	function deposit(string memory name, string memory description) public payable {
		if (msg.value == 0) return;
		emit Deposit(msg.sender, msg.value, name, description);
	}

	function assetIncome(
		address token,  uint256 tokenId,
		address source, address from, address to,
		uint256 price,  uint256 count, IAssetShell.SaleType saleType
	) public payable override {
		require(msg.value != 0, "#Ledger.assetIncome profit cannot be zero");
		emit AssetIncome(token, tokenId, source, from, to, msg.value, price, count, saleType);
	}

	function withdraw(uint256 amount, address target, string memory description)
		external payable override Check(Action_Ledger_Withdraw) 
	{
		//require(target != address(0), "#Ledger#withdraw receive assress not address(0)");
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