// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

import "./libs/SafeDecimalMath.sol";
import "./libs/AddressExp.sol";
import {ILedger, ISubLedger, OrderStatus} from "./interface.sol";
import "./Proxyable.sol";
import "./Exchange.sol";

//投票质押信息，用于记录每一张投票信息
struct Vote {
    // 投票人
    address voter;
    // 所参与的竞拍活动
    uint256 orderId;
    //投票质押数量
    uint256 votes;
    //投票质押系数
    uint256 weight;
    // 投票区块搞定
    uint256 blockNumber;
}

// 竞拍活动的投票质押信息总览
struct OrderSummary {
    // 总投票质押数量
    uint256 totalVotes;
    uint256 totalCanceledVotes;
    uint256 fixedRate;
    // 当前有效投票质押总股份（凭证）
    uint256 totalShares;
    // 竞拍成功时质押投票分成佣金额
    uint256 commission;
    bool stoped;
}

abstract contract VotePoolStore {
    uint256 public constant MAX_WEIGTH = 20e18; // prettier-ignore
    uint256 public constant MIN_WEIGTH = 1e18; // prettier-ignore
    //single addres can only be 100 pending vote.
    uint256 public constant MAX_PENDING_VOTES = 100;
    uint256 public constant Voteing = uint256(-1);
    uint256 public constant MAX_FIXED_AROR = 0.2 * 1e18; //20%
    uint256 public constant MIN_VOTE = 0.0001 * 1e18;

    uint256 internal constant YEAR_DAYS = 365;

    uint256 public lastVoteId;
    ILedger public ledger;
    Exchange public exchange;

    uint256 public voteLockTime;
    ///@notice 投票人的投票凭据ID集合
    mapping(address => uint256[]) public votesByVoter;
    ///@notice 所有投票凭据，key 为 投票凭据ID
    mapping(uint256 => Vote) public votesById;
    ///@notice 竞拍活动的投票质押总览，key 为竞选订单ID
    mapping(uint256 => OrderSummary) public ordersById;
}

/**
 * @title NFTSwap Bidding Vote Manager.
 */
contract VotePool is ISubLedger, Proxyable, VotePoolStore {
    using SafeDecimalMath for uint256;
    using SafeMath for uint256;
    using AddressExp for address;
    using Address for address;

    // new vote added
    event Voted(uint256 indexed orderId,address indexed voter,uint256 voteId, uint256 votes,uint256 weight); // prettier-ignore
    // vote cancel
    event Canceled(uint256 indexed orderId,address indexed voter,uint256 voteId); // prettier-ignore
    // one order done and sub commission finish
    event CommissionDone(uint256 orderId, uint256 fee, uint256 totalShares);

    // vote profit settled
    event Settled(
        uint256 indexed orderId,
        address indexed voter,
        uint256 voteId,
        uint256 profit
    );

    modifier onlyExchange() {
        require(
            msg.sender == address(exchange),
            "#VotePool: CALL_BY_EXCCHANGE"
        );
        _;
    }

    //********************************************
    //*       Admin Function                     *
    //********************************************
    function initialize(Exchange exchange_, ILedger ledger_) external {
        __Proxyable_init();
        ledger = ledger_;
        exchange = exchange_;
        voteLockTime = 100;
    }

    function setExchange(Exchange exchange_) external onlyOwner {
        exchange = exchange_;
    }

    function setLedger(ILedger ledger_) external onlyOwner {
        ledger = ledger_;
    }

    /**
      @notice change vote lock time (block count)
      @param blocks means that blocks need to be passed to cancel the vote.
     */
    function setVoteLockTime(uint256 blocks) external onlyOwner {
        voteLockTime = blocks;
    }

    struct MarginVars {
        uint256 orderId;
        uint256 votes;
        uint256 totalVotes;
        uint256 rate;
        uint256 factor;
        uint256 yield;
        uint256 weight;
        uint256 voteId;
        address voter;
        uint256 buyPrice;
        uint256 auctionDays;
        uint256 shareRatio;
    }

    function calc(
        uint256 orderId,
        uint256 totalVotes,
        uint256 votes,
        uint256 fixedRate
    )
        public
        view
        returns (
            MarginVars memory vars,
            uint256 weight,
            uint256 rateFxied
        )
    {
        vars.totalVotes = totalVotes + votes;
        vars.votes = votes;
        vars.voter = msg.sender;

        Exchange center = exchange; //save gas.
        (vars.buyPrice, vars.auctionDays, vars.shareRatio) = center
            .orderVoteInfo(orderId);
        vars.factor = vars
            .buyPrice
            .multiplyDecimal(vars.shareRatio)
            .mul(YEAR_DAYS)
            .div(vars.auctionDays);

        if (fixedRate > 0) {
            vars.rate = fixedRate;
            rateFxied = vars.rate;
        } else {
            vars.rate = vars.factor.divideDecimal(
                vars.factor.add(vars.totalVotes)
            );
            vars.yield = vars.factor.divideDecimal(vars.totalVotes);
            if (vars.yield < MAX_FIXED_AROR) {
                rateFxied = vars.rate;
                assert(rateFxied > 0);
            }
        }
        vars.weight = vars.votes.multiplyDecimal(vars.rate);
        weight = vars.weight;
    }

    /**
     * @notice any address can vote for bidding
     * @param orderId is bidding order id
     * @return voteId is the unique ID of this vote
     * @dev order status should be running.
     * Note: Each address can only vote for 100 bids.
     */
    function marginVote(uint256 orderId) public payable returns (uint256) {
        MarginVars memory vars;
        vars.votes = msg.value;
        vars.voter = msg.sender;
        vars.orderId = orderId;
        Exchange center = exchange; //save gas.
        center.voteAllowed(vars.orderId, vars.voter, vars.votes);

        require(vars.votes > 0, "#VotePool#vote: VALUE_IS_ZERO");
        //
        require(
            votesByVoter[vars.voter].length <= MAX_PENDING_VOTES,
            "VotePool#vote: OVER_LIMIT_PENDING_VOTE"
        );
        OrderSummary storage order = ordersById[orderId];

        (, vars.weight, vars.rate) = calc(
            orderId,
            order.totalVotes,
            vars.votes,
            order.fixedRate
        );
        require(vars.weight > 0, "#VotePool#vote: WEIGHT_IS_ZERO");
        vars.voteId = ++lastVoteId; // from 1

        order.totalVotes = order.totalVotes.add(vars.votes);
        order.totalShares = order.totalShares.add(vars.weight);
        order.fixedRate = vars.rate;

        votesByVoter[vars.voter].push(vars.voteId);
        votesById[vars.voteId] = Vote({
            voter: vars.voter,
            orderId: vars.orderId,
            votes: vars.votes,
            weight: vars.weight,
            blockNumber: block.number
        });
        // lock ethers for voter
        ledger.lock{value: vars.votes}(vars.voter, vars.voteId);
        emit Voted(
            vars.orderId,
            vars.voter,
            vars.voteId,
            vars.votes,
            vars.weight
        );

        return vars.voteId;
    }

    /**
     * @notice voter cancel vote by `voteId`
     * @dev vote can be unlocked after 100 blocks.
     */
    function cancelVote(uint256 voteId) external {
        Vote memory vote = votesById[voteId];
        address voter = vote.voter;
        require(voter == msg.sender, "#VotePool#cancel: NO_ACCESS");
        require(
            vote.blockNumber.add(voteLockTime) <= block.number,
            "#VotePool# VOTE_LOCKED"
        );
        uint256 orderId = vote.orderId;
        exchange.cancelVoteAllowed(orderId, voter);

        // Decrease shares
        OrderSummary storage order = ordersById[orderId];
        order.totalShares = order.totalShares.sub(vote.weight, "ERROR_WEIGHT");
        order.totalCanceledVotes = order.totalCanceledVotes.add(vote.votes);

        // Remove canceled;
        delete votesById[voteId];

        uint256[] storage items = votesByVoter[voter];
        // ignore array too longger , max length is 100
        for (uint256 i = 0; i < items.length; i++) {
            if (items[i] == voteId) {
                if (!_removeVoteIndex(voter, i)) {
                    i--; //continue next
                }
                break;
            }
        }

        // release vote margin
        ledger.unlock(voter, voteId, true);

        emit Canceled(orderId, voter, voteId);
    }

    /**
      @dev remove vote info from voter's voteing list.
      note: unsafe
     */
    function _removeVoteIndex(address voter, uint256 removeIndex)
        private
        returns (bool isLastItem)
    {
        uint256[] storage items = votesByVoter[voter];
        uint256 last = items.length - 1;
        isLastItem = removeIndex == last;
        if (!isLastItem) items[removeIndex] = items[last];
        items.pop(); //remove last one
    }

    /**
     * @notice send vote commission to all voters
     */
    function subCommission(uint256 orderId, uint256 commission)
        external
        onlyExchange
    {
        //payable fee
        OrderSummary storage order = ordersById[orderId]; // new or exist
        require(order.stoped == false, "#VotePool#income: ORDER_INCOME_REPEAT");
        require(ledger.balanceOf(address(this)) >= commission, "#VotePool#subCommission: BALANCE_NOT_ENOUGH");

        order.commission = commission;
        order.stoped = true;

        // transfer fee to ledger,then voter can auto withdrew himself commission.
        emit CommissionDone(orderId, commission, order.totalShares);
    }

    /**
      @notice help holder calculate proft and send proft to ledger.
      @dev holder is target address.
     */
    function _settle(address holder) private returns (uint256 sumProfit) {
        uint256[] storage items = votesByVoter[holder];
        // ignore array too longger , max length is 100
        for (uint256 i = 0; i < items.length; i++) {
            uint256 voteId = items[i];
            Vote storage vote = votesById[voteId];
            uint256 profit = _voteProfit(vote);
            if (profit != uint256(-1)) {
                emit Settled(vote.orderId, holder, voteId, profit);
                sumProfit = sumProfit.add(profit);

                if (!_removeVoteIndex(holder, i)) {
                    i--; //continue next
                }
            }
        }

        // last transfer to holder.
        if (sumProfit > 0) {
            ledger.transfer(holder, sumProfit);
        }
    }

    function _voteProfit(Vote storage vote)
        private
        view
        returns (uint256 profit)
    {
        uint256 orderId = vote.orderId;
        OrderStatus status = exchange.orderStatus(orderId);
        if (status == OrderStatus.DealDone) {
            // profit = commission * weight / totalShares
            OrderSummary storage order = ordersById[orderId];
            profit = order.commission.mul(vote.weight).div(order.totalShares); //prettier-ignore
        } else {
            profit = uint256(-1);
        }
    }

    function _canSettleAmount(address holder)
        private
        view
        returns (uint256 sumProfit)
    {
        uint256[] storage items = votesByVoter[holder];
        // ignore array too longger , max length is 100
        for (uint256 i = 0; i < items.length; i++) {
            Vote storage vote = votesById[items[i]];
            uint256 profit = _voteProfit(vote);
            if (profit != 0 && profit != uint256(-1)) {
                sumProfit = sumProfit.add(profit);
            }
        }
    }

    /**
     * @dev return the total votes of the bidding order.
     */
    function orderTotalVotes(uint256 orderId) public view returns (uint256) {
        OrderSummary storage order = ordersById[orderId];
        return order.totalVotes.sub(order.totalCanceledVotes);
    }

    /**
     * @dev implement {ISubLedger}
     * can release when:
     *  2. settle when bid success
     */
    function canRelease(address holder) public view override returns (uint256) {
        return _canSettleAmount(holder);
    }

    /**
      @dev implement {ISubLedger}
     */
    function tryRelease(address holder) public override returns (uint256) {
        return _settle(holder);
    }

    /**
     * @dev implement {ISubLedger}
     *  can unlock when bid status is not voting
     */
    function unlockAllowed(uint256 voteId, address voter)
        public
        view
        override
        returns (bool)
    {
        Vote memory vote = votesById[voteId];
        if (vote.orderId == 0) {
            return false; //not found
        }
        if (vote.voter != voter) {
            return false;
        }
        OrderStatus status = exchange.orderStatus(vote.orderId);
        return status != OrderStatus.Ing;
    }

    /**
     * @notice return all pending votes of `voter`
     */
    function allVotes(address voter) public view returns (uint256[] memory) {
        return votesByVoter[voter];
    }
}
