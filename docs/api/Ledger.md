# `Ledger`
Manage NFTSWap ether ledger.
all ethers transfer to NFT Swap will be stored to here.
any one can search himself balance on here.



## .Functions
### initialize

```solidity
function initialize()
```







### addNewSubLedger

```solidity
function addNewSubLedger(contract ISubLedger sub)
```

set new subledger to Ledger
      @dev note: ignore repeat set





### totalSupply

```solidity
function totalSupply() returns(uint256)
```



See {IERC20-totalSupply}.



### balanceOf

```solidity
function balanceOf(address account) returns(uint256)
```



See {IERC20-balanceOf}.



### transfer

```solidity
function transfer(address recipient, uint256 amount) returns(bool)
```



See {IERC20-transfer}.

Requirements:

- `recipient` cannot be the zero address.
- the caller must have a balance of at least `amount`.



### allowance

```solidity
function allowance(address owner, address spender) returns(uint256)
```



See {IERC20-allowance}.



### approve

```solidity
function approve(address spender, uint256 amount) returns(bool)
```



See {IERC20-approve}.

Requirements:

- `spender` cannot be the zero address.



### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) returns(bool)
```



See {IERC20-transferFrom}.

Emits an {Approval} event indicating the updated allowance. This is not
required by the EIP. See the note at the beginning of {ERC20}.

Requirements:

- `sender` and `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`.
- the caller must have allowance for ``sender``'s tokens of at least
`amount`.



### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) returns(bool)
```



Atomically increases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

- `spender` cannot be the zero address.



### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) returns(bool)
```



Atomically decreases the allowance granted to `spender` by the caller.

This is an alternative to {approve} that can be used as a mitigation for
problems described in {IERC20-approve}.

Emits an {Approval} event indicating the updated allowance.

Requirements:

- `spender` cannot be the zero address.
- `spender` must have allowance for the caller of at least
`subtractedValue`.



### _transfer

```solidity
function _transfer(address sender, address recipient, uint256 amount)
```



Moves tokens `amount` from `sender` to `recipient`.

This is internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.

Emits a {Transfer} event.

Requirements:

- `sender` cannot be the zero address.
- `recipient` cannot be the zero address.
- `sender` must have a balance of at least `amount`.



### _mint

```solidity
function _mint(address account, uint256 amount)
```



Creates `amount` tokens and assigns them to `account`, increasing
the total supply.

Emits a {Transfer} event with `from` set to the zero address.

Requirements:

- `to` cannot be the zero address.



### _burn

```solidity
function _burn(address account, uint256 amount)
```



Destroys `amount` tokens from `account`, reducing the
total supply.

Emits a {Transfer} event with `to` set to the zero address.

Requirements:

- `account` cannot be the zero address.
- `account` must have at least `amount` tokens.



### _approve

```solidity
function _approve(address owner, address spender, uint256 amount)
```



Sets `amount` as the allowance of `spender` over the `owner` s tokens.

This internal function is equivalent to `approve`, and can be used to
e.g. set automatic allowances for certain subsystems, etc.

Emits an {Approval} event.

Requirements:

- `owner` cannot be the zero address.
- `spender` cannot be the zero address.



### _beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address from, address to, uint256 amount)
```



Hook that is called before any token transfer. This includes
calls to {send}, {transfer}, {operatorSend}, minting and burning.

Calling conditions:

- when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
will be to transferred to `to`.
- when `from` is zero, `amount` tokens will be minted for `to`.
- when `to` is zero, `amount` of ``from``'s tokens will be burned.
- `from` and `to` are never both zero.

To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].



### withdraw

```solidity
function withdraw(address receiver, uint256 amount)
```

withdraw ethers to himself





### deposit

```solidity
function deposit()
```

deposit ethers to here





### lock

```solidity
function lock(address to, uint256 lockId)
```

`lockControler` send eth to `to`,and lock at this ledger.




**Input**
+ `to`: is eth reciever.
+ `lockId`: is a lock key,will be store in lock array of `to`.


### unlock

```solidity
function unlock(address holder, uint256 lockId, bool withdrawNow) returns(uint256)
```







### lockedItems

```solidity
function lockedItems(address holder) returns(struct LedgerStore.LockEntry[])
```

returns all locked collection info of the `holder`


just search for chain-off



### receive

```solidity
function receive()
```



default deposit




## .Event
### OwnershipTransferred

```solidity
OwnershipTransferred(address previousOwner, address newOwner)
```






### Transfer

```solidity
Transfer(address from, address to, uint256 value)
```



Emitted when `value` tokens are moved from one account (`from`) to
another (`to`).
Note that `value` may be zero.


### Approval

```solidity
Approval(address owner, address spender, uint256 value)
```



Emitted when the allowance of a `spender` for an `owner` is set by
a call to {approve}. `value` is the new allowance.


