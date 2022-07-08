# `FeePlan`




## .Functions
### initialize

```solidity
function initialize()
```







### voterShareRatio

```solidity
function voterShareRatio(bool firstAuction) returns(uint256)
```

returns the auction revenue share ratio for voter.
      @return uint256 is the ratio mantissa (scaned by 18)





### formula

```solidity
function formula(uint256 value, bool firstBid, uint256 votes) returns(uint256 toSeller, uint256 toVoter, uint256 toTeam)
```








## .Event
### OwnershipTransferred

```solidity
OwnershipTransferred(address previousOwner, address newOwner)
```






