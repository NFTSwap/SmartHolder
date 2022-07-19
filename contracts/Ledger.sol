
pragma solidity >=0.6.0 <=0.8.15;

pragma experimental ABIEncoderV2;

import "./Interface.sol";
import "./Department.sol";

contract Ledger is ILedger, Department {

	function initLedger(address host, string memory describe, address operator) external {
		initDepartment(host, describe, operator);
		_registerInterface(Ledger_ID);
	}

	function receiveBalance() internal {
		if (msg.value != 0) {
			emit Receive(msg.sender, msg.value);
		}
	}

	function getBalance() view public returns (uint256) {
		return address(this).balance;
	}

	function release(uint256 amount, string memory describe) external payable OnlyDAO {
		receiveBalance();

		uint256 curamount = address(this).balance;
		require(curamount >= amount, "#Ledger#release insufficient balance");

		uint256 votes = _host.member().votes();
		uint256 unit = amount / votes;

		require(unit != 0 , "#Ledger#release insufficient balance release");

		uint256 total = _host.member().total();

		IMember.Info memory info;

		for (uint256 i = 0; i < total; i++) {
			info = _host.member().indexAt(i);
			address owner = _host.member().ownerOf(info.id);
			uint256 balance = info.votes * unit;
			owner.sendValue(balance);
			emit Release(info.id, owner, balance);
		}

		emit ReleaseLog(msg.sender, amount, describe);
	}

	function deposit(string memory name, string memory describe) public {
		if (msg.value != 0) {
			emit Deposit(msg.sender, msg.value, name, describe);
		}
	}

	function withdraw(uint256 amount, address target, string memory describe) external payable override OnlyDAO {
		require(target != address(0), "#Ledger#withdraw receive assress not address(0)");
		receiveBalance();
		target.sendValue(amount);
		emit Withdraw(target, amount, describe);
	}

	receive() external payable {
		receiveBalance();
	}

	fallback() external payable {
		receiveBalance();
	}

}