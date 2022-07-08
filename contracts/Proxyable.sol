// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 @dev
 */
abstract contract Proxyable is Initializable, OwnableUpgradeSafe {
    function __Proxyable_init() internal initializer {
        __Ownable_init();
        // tx sender as contract logic administrator
        // transferOwnership(tx.origin);
    }
}
