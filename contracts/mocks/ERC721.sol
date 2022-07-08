// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team

pragma solidity ^0.6.12;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol";

contract MYNFT is ERC721UpgradeSafe {
    constructor() public {
        __ERC721_init("MY TEST NFT", "NFT");
    }

    function mint(uint256 tokenId) public {
        _mint(msg.sender, tokenId);
    }
}
