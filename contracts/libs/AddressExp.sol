// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team

pragma solidity ^0.6.12;

library AddressExp {
    //@dev Converts an address to address payable.
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }
}
