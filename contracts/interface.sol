// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team

pragma solidity ^0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IFeePlan {
    /**
     * @notice fee share after bid done
     * @param value is bidding order transaction price.
     * @param firstBid is whether the asset is the first bidding.
     * @param votes is how many addresses voted for the bindding.
     */
    function formula(
        uint256 value,
        bool firstBid,
        uint256 votes
    )
        external
        view
        returns (
            uint256 toSeller,
            uint256 toVoter,
            uint256 toTeam
        );

    function voterShareRatio(bool firstAuction) external view returns (uint256);
}

interface IVotePool {
    function subCommission(uint256 orderId, uint256 commission) external payable;

    function orderTotalVotes(uint256 orderId) external view returns (uint256);
}

interface ILedger is IERC20 {
    function lock(address receiver, uint256 lockId) external payable;

    function unlock(
        address owner,
        uint256 lockId,
        bool withdrawNow
    ) external returns (uint256);

    function deposit() external payable;

    function withdraw(address receiver, uint256 amount) external;
}

interface ISubLedger {
    function canRelease(address holder) external view returns (uint256);

    function tryRelease(address holder) external returns (uint256);

    function unlockAllowed(uint256 lockId, address holder)
        external
        view
        returns (bool);
}

enum OrderStatus {Ing, Expired, DealDone}

interface IExchange {
    function orderVoteInfo(uint256 orderId)
        external
        returns (
            uint256 minSellPrice,
            uint256 auctionDays,
            uint256 shareRatio
        );

    function voteAllowed(
        uint256 orderId,
        address voter,
        uint256 margin
    ) external;

    function cancelVoteAllowed(uint256 orderId, address voter) external;

    function orderStatus(uint256 orderId)
        external
        view
        returns (OrderStatus status);
}

interface IERC721_Ext {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}