// SPDX-License-Identifier: MIT

pragma solidity ~0.8.17;

import './Module.sol';
import './libs/ERC20.sol';
import './libs/Interface.sol';

contract Share is Module, ERC20, IShare {
	uint256[16] private  __; // reserved storage space

	struct InitShare {
		string name;
		string symbol;
		string description;
	}

	function initShare(
		address host,
		address operator,
		InitShare calldata init
	) external {
		initModule(host, init.description, operator);
		initERC20(init.name, init.symbol);

		IMember m = IDAO(host).member();
		uint256 total = m.total();
		uint256 decimals_ = decimals() ** 10;
		IMember.Info memory info;

		for (uint256 i = 0; i < total; i++) {
			info =  m.indexAt(i);
			_mint(m.ownerOf(info.id), info.votes * decimals_);
		}
	}

	function mint(address account, uint256 amount) public OnlyDAO {
		_mint(account, amount);
	}

}