// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team

pragma solidity ^0.6.12;

import { ISubLedger, ILedger } from "../interface.sol";

contract SubLedgerMock is ISubLedger {
    mapping(address => uint256) _releases;
    mapping(address => mapping(uint256 => bool)) _locked;
    ILedger public ledger;

    constructor(ILedger ledger_) public {
        ledger = ledger_;
    }

    function lock(address holder, uint256 lockId) public payable {
        _locked[holder][lockId] = true;
        uint256 amount = msg.value;
        ledger.lock{ value: amount }(holder, lockId);
    }

    function unlock(address holder, uint256 lockId) public {
        _locked[holder][lockId] = false;
        ledger.unlock(holder, lockId, false);
    }

    function setRelease(address holder, uint256 release) public {
        _releases[holder] = release;
    }

    function setLockStatus(
        address holder,
        uint256 lockId,
        bool locked
    ) public {
        _locked[holder][lockId] = locked;
    }

    function canRelease(address holder)
        external
        view
        override
        returns (uint256)
    {
        return _releases[holder];
    }

    function tryRelease(address holder) external override returns (uint256) {
        uint256 b = _releases[holder];
        _releases[holder] = 0;
        return b;
    }

    function unlockAllowed(uint256 lockId, address holder)
        external
        view
        override
        returns (bool)
    {
        return _locked[holder][lockId] == false;
    }
}
