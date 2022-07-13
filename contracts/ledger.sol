
pragma solidity ^0.8.15;

import "./department.sol";
import "./member.sol";

contract Ledger is Department {

	/*
	 * bytes4(keccak256('initLedger(address,string,address)')) == 0xf4c38e51
	 */
	bytes4 public constant ID = 0xf4c38e51;

	event Receive(address indexed from, uint256 balance);
	event Release(uint256 indexed member, address addr, uint256 balance);
	event Withdraw(address indexed target, uint256 balance);

	function initLedger(address host, string memory info, address operator) external {
		initDepartment(host, info, operator);
		_registerInterface(ID);
	}

	function getBalance() view public returns (uint256) {
		return address(this).balance;
	}

	function release(uint256 amount) external payable OnlyDAO {
		receiveBalance();

		uint256 curamount = address(this).balance;
		require(curamount >= amount, "#Ledger#release insufficient balance");

		uint256 votes = host.member.votes();
		uint256 unit = amount / votes;

		require(unit != 0 , "#Ledger#release insufficient balance release");

		uint256 total = host.member.total();

		for (uint256 i = 0; i < total; i++) {
			Member.Info memory info = host.member.indexAt(i);
			address owner = host.member.ownerOf(info.id);
			uint256 balance = info.votes * unit;
			owner.sendValue(balance);
			emit Release(info.id, owner, balance);
		}

		emit Withdraw(address(0), amount);
	}

	function withdraw(uint256 amount, address target) external payable OnlyDAO {
		require(target != address(0), "#Ledger#withdraw receive assress not address(0)");
		address(target).sendValue(amount);
		emit Withdraw(target, amount);
	}

	function receiveBalance() internal {
		if (msg.value != 0) {
			emit Receive(msg.sender, msg.value);
		}
	}

	receive() external payable {
		receiveBalance();
	}

	fallback() external payable {
		receiveBalance();
	}

}