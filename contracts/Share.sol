// SPDX-License-Identifier: MIT

pragma solidity ~0.8.17;

import './Module.sol';
import './libs/ERC20.sol';

contract Share is Module, ERC20, IShare {
	uint256     public   maxSupply;
	uint256[16] private  __; // reserved storage space

	function initShare(
		address host,
		address operator,
		uint256 totalSupply, uint256 maxSupply_,
		string calldata name,
		string calldata symbol, string calldata description
	) external {
		initModule(host, description, operator);
		initERC20(name, symbol);
		_registerInterface(Share_Type);

		maxSupply = maxSupply_;

		IMember m = IDAO(host).member();
		uint256 total = m.total();
		// uint256 unit = decimals() ** 10;
		uint256 unit = m.votes() / totalSupply;
		IMember.Info memory info;

		for (uint256 i = 0; i < total; i++) {
			info =  m.indexAt(i);
			_mint(m.ownerOf(info.id), info.votes * unit);
		}
	}

	function mint(address account, uint256 amount) public OnlyDAO {
		//require(amount + totalSupply() <= maxSupply, "#Share.mint maximum supply limit");
		if (amount + totalSupply() > maxSupply) revert MaximumSupplyLimitInShare();
		_mint(account, amount);
	}

}