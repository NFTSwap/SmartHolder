// SPDX-License-Identifier: MIT
// Created by NTFSWAP Team
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol";

import "./libs/AddressExp.sol";
import {ILedger, ISubLedger} from "./interface.sol";
import "./Proxyable.sol";

abstract contract LedgerStore {
    using SafeMath for uint256;
    using AddressExp for address;
    using Address for address payable;
    using Address for address;

    using EnumerableSet for EnumerableSet.AddressSet;

    struct LockEntry {
        address locker;
        uint256 lockId;
        uint256 amount;
    }
    struct LockInfo {
        // lock detail
        LockEntry[] items;
        // map[ lockId: entry index +1,... ]
        mapping(bytes32 => uint256) indexs;
    }

    mapping(address => LockInfo) internal _lockedByAcct;
    // ISubLedger set
    EnumerableSet.AddressSet internal subLedgerSet;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    // erc20 fields
    uint256 internal _totalSupply;
    string public constant name = "NFTSWAP ETH Ledger";
    string public constant symbol = "LETH";
    uint8 public constant decimals = 18;
}

/**
 * @notice Manage NFTSWap ether ledger.
 * all ethers transfer to NFT Swap will be stored to here.
 * any one can search himself balance on here.
 */
contract Ledger is ILedger, Proxyable, LedgerStore {
    using SafeMath for uint256;
    using AddressExp for address;
    using Address for address payable;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    function initialize() external {
        __Proxyable_init();
    }

    //********************************************
    //*       Admin Function                     *
    //********************************************

    /**
      @notice set new subledger to Ledger
      @dev note: ignore repeat set
     */
    function addNewSubLedger(ISubLedger sub) public onlyOwner {
        address empty = address(0);
        require(address(sub).isContract(), "#Ledger#op: INVALID_CONTROLER");
        require(
            !subLedgerSet.contains(address(sub)),
            "#Ledger#op: REPEAT_LEDGER"
        );
        //try check
        sub.canRelease(empty);
        sub.tryRelease(empty);
        sub.unlockAllowed(0, empty);
        subLedgerSet.add(address(sub));
    }

    function hasSubLedger(ISubLedger sub) public view returns (bool) {
        require(address(sub).isContract(), "#Ledger#op: INVALID_CONTROLER");
        return subLedgerSet.contains(address(sub));
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _realBalanceOf(account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        address(account).toPayable().sendValue(amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from != address(0)) {
            to;
            amount;
            // try release  for `from`
            _tryRelease(from);
        }
    }

    /**
      @notice withdraw ethers to himself
     */
    function withdraw(address receiver, uint256 amount) external override {
        require(receiver != address(0), "ADDRESS_EMPTY");
        _transfer(msg.sender, receiver, amount);
        _burn(receiver, amount);
    }

    /**
     * @notice deposit ethers to here
     */
    function deposit() public payable override {
        _mint(msg.sender, msg.value);
    }

    /**********************lock*********************************/

    modifier onlySubLedger() {
        require(
            subLedgerSet.contains(msg.sender),
            "#ETHLocker#transferAsLock: NO_ACCESS"
        );
        _;
    }

    /**
     * @notice `lockControler` send eth to `to`,and lock at this ledger.
     * @param to is eth reciever.
     * @param lockId is a lock key,will be store in lock array of `to`.
     */
    function lock(address to, uint256 lockId)
        public
        payable
        override
        onlySubLedger
    {
        uint256 amount = msg.value;
        address locker = msg.sender;
        _mint(locker, amount);
        if (amount == 0) {
            return;
        }
        bytes32 idHash = _createLockKey(locker, to, lockId);
        // store lock infomation
        LockInfo storage lockInfo = _lockedByAcct[to];
        require(
            lockInfo.indexs[idHash] == 0,
            "#ETHLocker#transferAsLock: REPEAT_LOCKID"
        );
        lockInfo.items.push(
            LockEntry({locker: locker, lockId: lockId, amount: amount})
        );
        //mapping lockid to index+1
        lockInfo.indexs[idHash] = lockInfo.items.length;
    }

    function unlock(
        address holder,
        uint256 lockId,
        bool withdrawNow
    ) public override onlySubLedger returns (uint256) {
        LockInfo storage lockInfo = _lockedByAcct[holder];
        bytes32 idHash = _createLockKey(msg.sender, holder, lockId);
        uint256 loction = lockInfo.indexs[idHash];
        require(loction > 0, "#ETHLocker#release: NOT_FOUND_LOCK");
        return _unlock(holder, loction - 1, withdrawNow);
    }

    function _createLockKey(
        address locker,
        address holder,
        uint256 lockId
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("LOCK", locker, holder, lockId));
    }

    function _unlock(
        address holder,
        uint256 lockEntryIndex,
        bool withdrawNow
    ) private returns (uint256) {
        LockInfo storage lockInfo = _lockedByAcct[holder];
        LockEntry memory item = lockInfo.items[lockEntryIndex];
        address locker = item.locker;

        //delete item and update index.
        delete lockInfo.indexs[
            _createLockKey(item.locker, holder, item.lockId)
        ];

        LockEntry storage endItem = lockInfo.items[lockInfo.items.length - 1];
        bytes32 endItemKey =
            _createLockKey(endItem.locker, holder, endItem.lockId);
        lockInfo.items[lockEntryIndex] = endItem;
        lockInfo.indexs[endItemKey] = lockEntryIndex + 1;
        lockInfo.items.pop();
        if (lockInfo.items.length == 0) {
            delete _lockedByAcct[holder];
        }

        _transfer(locker, holder, item.amount);
        if (withdrawNow) {
            _burn(holder, item.amount);
        }
        return item.amount;
    }

    /**
        @dev  real-time calculationcan unlock ethers of `holder`,
        add append releaseable ethers as a part of balance of `holder`.
     */
    function _realBalanceOf(address holder)
        private
        view
        returns (uint256 totalBalance)
    {
        totalBalance = _balances[holder];

        // skip special address to avoid invalid search
        if (subLedgerSet.contains(holder)) {
            return totalBalance;
        }

        LockInfo storage lockInfo = _lockedByAcct[holder];

        // try check unlocked
        uint256 len = lockInfo.items.length;
        for (uint256 i = 0; i < len; i++) {
            LockEntry memory item = lockInfo.items[i];
            ISubLedger locker = ISubLedger(item.locker);
            if (locker.unlockAllowed(item.lockId, holder)) {
                totalBalance = totalBalance.add(item.amount);
            }
        }
        // check how many ethers can auto release
        len = subLedgerSet.length();
        for (uint256 i = 0; i < len; i++) {
            ISubLedger locker = ISubLedger(subLedgerSet.at(i));
            totalBalance = totalBalance.add(locker.canRelease(holder));
        }
    }

    /**
        @dev try to unlock and release `owner`'s locked ethers or pending ethers.
        1. earch all lock items of `owner` and check if it can be unlocked.
        2. ask all sub-ledgers if there are any releaseable ethers of `owner` and try release it.
     */
    function _tryRelease(address holder) private {
        // skip special address to avoid invalid search
        if (subLedgerSet.contains(holder)) {
            return;
        }

        LockInfo storage lockInfo = _lockedByAcct[holder];
        uint256 len = lockInfo.items.length;
        //ingnore  item array too longger
        for (uint256 i = 0; i < len; i++) {
            LockEntry storage item = lockInfo.items[i];
            ISubLedger locker = ISubLedger(item.locker);
            if (locker.unlockAllowed(item.lockId, holder)) {
                _unlock(holder, i, false);
                len -= 1;
                i -= 1;
            }
        }

        // check how many ethers can auto release
        len = subLedgerSet.length();
        for (uint256 i = 0; i < len; i++) {
            ISubLedger locker = ISubLedger(subLedgerSet.at(i));
            uint256 amount = locker.tryRelease(holder); // After calling tryrelease(), the money will be transferred to the holder
            // if (amount > 0) {
            //     _transfer(address(locker), holder, amount);
            // }
        }
    }

    /**********************lock end*********************************/

    /**
     * @notice returns all locked collection info of the `holder`
     * @dev just search for chain-off
     */
    function lockedItems(address holder)
        public
        view
        returns (LockEntry[] memory)
    {
        LockInfo storage lockInfo = _lockedByAcct[holder];
        return lockInfo.items;
    }

    ///@dev default deposit
    receive() external payable {
        _mint(msg.sender,msg.value);
    }
}
