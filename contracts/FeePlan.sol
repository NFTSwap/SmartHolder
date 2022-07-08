// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

import {IFeePlan} from "./interface.sol";
import "./Proxyable.sol";

abstract contract FeePlanStore {
    uint256 internal constant feeUnit = 1e18;
    uint256 public feeToVoterAtFirst;
    uint256 public feeToTeamAtFirst;
    uint256 public feeToVoter;
    uint256 public feeToTeam;
}

contract FeePlan is IFeePlan, Proxyable, FeePlanStore {
    using SafeMath for uint256;
    using Address for address;

    function initialize() external {
        __Proxyable_init();

        feeToVoterAtFirst = 0.48 * 1e18; //45.00%
        feeToTeamAtFirst = 0.05 * 1e18; //5.00%
        feeToVoter = 0.09 * 1e18; //9%
        feeToTeam = 0.01 * 1e18; //1%
    }

    /**
      @notice returns the auction revenue share ratio for voter.
      @return uint256 is the ratio mantissa (scaned by 18)
     */
    function voterShareRatio(bool firstAuction)
        external
        view
        override
        returns (uint256)
    {
        return firstAuction ? feeToVoterAtFirst : feeToVoter;
    }

    function formula(
        uint256 value,
        bool firstBid,
        uint256 votes
    )
        public
        view
        override
        returns (
            uint256 toSeller,
            uint256 toVoter,
            uint256 toTeam
        )
    {
        toVoter = votes == 0
            ? 0
            : value
                .mul(firstBid ? uint256(feeToVoterAtFirst) : uint256(feeToVoter))
                .div(feeUnit);

        toTeam = value
            .mul(firstBid ? uint256(feeToTeamAtFirst) : uint256(feeToTeam))
            .div(feeUnit);

        //safe check
        if (toVoter + toTeam >= value) {
            toVoter = 0;
            toTeam = 0;
        }
        toSeller = value.sub(toVoter).sub(toTeam);
    }
}
