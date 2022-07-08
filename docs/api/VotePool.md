# `VotePool`
event Voted(uint256 indexed orderId,address in



## .Functions
### initialize

```solidity
function initialize(contract Exchange exchange_, contract ILedger ledger_)
```







### setVoteLockTime

```solidity
function setVoteLockTime(uint256 blocks)
```

uint256 orderId;
        uint256 votes;
        uint256 totalVotes;
        uint256 rate;
        uint256 factor;
        uint256 yie





### calc

```solidity
function calc(uint256 orderId, uint256 totalVotes, uint256 votes, uint256 fixedRate) returns(struct VotePool.MarginVars vars, uint256 weight, uint256 rateFxied)
```







### marginVote

```solidity
function marginVote(uint256 orderId) returns(uint256)
```

nVote(uint256 orderId) public payable returns (uint256) {
        MarginVars memory vars;
        vars.votes = msg.value;
        vars.voter = msg.sender;
        vars.orderId = orderId;
        Exchange center = exchange; //save gas.
        center.v





### cancelVote

```solidity
function cancelVote(uint256 voteId)
```

sender, "#VotePool#cancel: NO_ACCESS");
        require(
            vote.blockNumber.add(voteLockTime) <=





### subCommission

```solidity
function subCommission(uint256 orderId, uint256 commission)
```

require(order.stoped == false, "#VotePool#income: ORDER_I





### orderTotalVotes

```solidity
function orderTotalVotes(uint256 orderId) returns(uint256)
```

}

    /**


implement {ISubLedger}
can release w



### canRelease

```solidity
function canRelease(address holder) returns(uint256)
```

Ledger}
/
    function tryRelease(address holder) public override returns (uint256) {
        return





### tryRelease

```solidity
function tryRelease(address holder) returns(uint256)
```

ion unlockAllowed(uint256 voteId, address vot





### unlockAllowed

```solidity
function unlockAllowed(uint256 voteId, address voter) returns(bool)
```

d];
        if (vote.orderId == 0) {
            return false; //not found
        }
        if





### allVotes

```solidity
function allVotes(address voter) returns(uint256[])
```








## .Event
### Voted

```solidity
Voted(uint256 orderId, address voter, uint256 voteId, uint256 votes, uint256 weight)
```






### Canceled

```solidity
Canceled(uint256 orderId, address voter, uint256 voteId)
```






### CommissionDone

```solidity
CommissionDone(uint256 orderId, uint256 fee, uint256 totalShares)
```






### Settled

```solidity
Settled(uint256 orderId, address voter, uint256 voteId, uint256 profit)
```






### OwnershipTransferred

```solidity
OwnershipTransferred(address previousOwner, address newOwner)
```






