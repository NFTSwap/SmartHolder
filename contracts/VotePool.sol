// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

pragma experimental ABIEncoderV2;

import './libs/Interface.sol';
import './libs/Constants.sol';
import './libs/ERC165.sol';
import './libs/Upgrade.sol';
import './libs/Check.sol';

contract VotePool is Upgrade, ERC165, PermissionCheck, IVotePool {
	using Address for address;
	using SafeMath for uint256;

	bytes4 internal constant DAO_ID = 0xc7b55336;
	bytes4 internal constant VotePool_ID = 0x0ddf27bf;

	// define props
	string private _description;
	// proposal id => Proposal
	mapping(uint256 => Proposal) private _proposalMap; // 提案决议列表
	uint256[] private _proposalList; // 提案列表索引
	// proposal id => map( member id => votes )
	mapping(uint256 => mapping(uint256 => int256)) private _votes; // 成员投票记录

	// @public
	uint256 public lifespan; // 提案生命周期限制

	uint256[16] private __; // reserved storage space

	/**
	 * @dev Init vote pool
	 */
	function initVotePool(address host, string memory description, uint256 _lifespan) external {
		initERC165();
		_registerInterface(VotePool_Type);
		_host = IDAO(host);
		_description = description;
		setLifespan(_lifespan);
	}

	function isPermissionDAO() view internal override returns (bool) {
		if (msg.sender != address(_host.operator()))
			return msg.sender == address(_host.root());
		return true;
	}

	/**
	 * @dev Upgrade vote pool
	 */
	function upgrade(address impl) public OnlyDAO {
		_impl = impl;
	}

	function setLifespan(uint256 _lifespan) private {
		// require(_lifespan >= 12 hours, "#VotePool.setLifespan proposal lifespan not less than 12 hours");
		if (_lifespan < 12 hours) revert ProposalDefaultLifespanLimitError();
		lifespan = _lifespan;
	}

	/**
	 * @dev Returns the description of vote pools
	 */
	function description() view external returns (string memory) {
		return _description;
	}

	/**
	 * @dev Gettings proposal object from id
	 */
	function getProposal(uint256 id) view public returns (Proposal memory) {
		return proposal(id);
	}

	function proposal(uint256 id) view private returns (Proposal storage) {
		// require(exists(id), "#VotePool#proposal proposal not exists");
		if (!exists(id)) revert ProposalNonExistsInVotePool();
		return _proposalMap[id];
	}

	/**
	 * @dev Return whether the proposal object exists
	 */
	function exists(uint256 id) view public returns (bool) {
		return _proposalMap[id].id != 0;
	}

	/**
	 * @dev Create proposal object from proposal arg
	 */
	function create(Proposal memory arg0) public {
		// check permission
		if (msg.sender != address(_host.member())) {
			checkFrom(arg0.originId, Action_VotePool_Create);
		}

		if (exists(arg0.id)) revert ProposalAlreadyExistsInVotePool();

		if (arg0.passRate <= 5_000) revert CreateProposalVotePassEateLimitError();

		if (arg0.lifespan != 0) {
			if (arg0.lifespan < lifespan) revert CreateProposalLifespanLimitError();
		}
		if (arg0.loopCount != 0) {
			if (arg0.loopTime < 1 minutes) revert CreateProposalLoopTimeLimitError(); 
		}
		Proposal storage obj = _proposalMap[arg0.id];

		obj.id          = arg0.id;
		obj.name        = arg0.name;
		obj.description = arg0.description;
		obj.target      = arg0.target;
		obj.origin      = msg.sender;
		obj.originId    = arg0.originId;
		obj.data        = arg0.data;
		obj.lifespan    = arg0.lifespan;
		obj.expiry      = arg0.lifespan == 0 ? 0: block.timestamp + arg0.lifespan;
		obj.passRate    = arg0.passRate > 10_000 ? 10_000: arg0.passRate;
		obj.loopCount   = arg0.loopCount;
		obj.loopTime    = arg0.loopTime;
		obj.voteTotal   = 0;
		obj.agreeTotal  = 0;
		obj.executeTime = 0;
		obj.idx         = _proposalList.length;
		obj.isAgree     = false;
		obj.isClose     = false;
		obj.isExecuted  = false;

		_proposalList.push(arg0.id);

		emit Created(arg0.id);
	}

	/**
	 * @dev Create proposal object
	 */
	function create2(
		uint256       id,          address[] memory target,
		uint256       lifespan,    uint256 passRate,
		int256        loopCount,   uint256 loopTime,
		string memory name,        string memory description,
		uint256       originId,    bytes[] memory  data
	) external {
		Proposal memory pro;
		pro.id          = id;
		pro.originId    = originId; // member id
		pro.target      = target;
		pro.lifespan    = lifespan;
		pro.passRate    = passRate;
		pro.loopCount   = loopCount;
		pro.loopTime    = loopTime;
		pro.name        = name;
		pro.description = description;
		pro.data        = data;
		create(pro);
	}

	function abs(int256 value) pure internal returns (uint256) {
		return value < 0 ? uint256(-value): uint256(value);
	}

	/**
	 * @dev Vote on the proposal
	 */
	function vote(uint256 id, uint256 member, int256 votes, bool tryExecute) external Check(Action_VotePool_Vote) {
		Proposal storage obj = proposal(id);
		IMember.Info memory info = _host.member().getMemberInfo(member);

		if (votes == 0) revert VotesZero();
		if (obj.isClose) revert ProposalClosed();
		if (_host.member().ownerOf(member) != msg.sender) revert VotingMemberNoMatch();
		if (_votes[id][member] != 0) revert DuplicateVoteError();
		if (abs(votes) > info.votes) revert VoteInsufficientVotes();

		_votes[id][member] = votes;

		obj.voteTotal += abs(votes);

		if (votes > 0) {
			obj.agreeTotal += uint256(votes);
		}

		emit Vote(id, member, votes);

		tryClose(id, tryExecute); // try close
	}

	/**
	* @dev try close proposal
	*/
	function tryClose(uint256 id, bool tryExecute) public override {
		Proposal storage obj = proposal(id);
		// require(!obj.isClose, "#VotePool.tryClose Voting has been closed");
		if (obj.isClose) revert ProposalClosed();

		uint256 votes  = _host.member().votes();
		uint256 passRate = obj.passRate;

		if ((obj.expiry != 0 && obj.expiry <= block.timestamp)) { // block time expiry
			// Include only participating members
			obj.isClose = true;
			obj.isAgree = (obj.agreeTotal * 10_000 / obj.voteTotal) > passRate;
		} else {
			if ((obj.agreeTotal * 10_000 / votes) > passRate) { // test passRate
				obj.isClose = true;
				obj.isAgree = true; // complete
			} else if (((obj.voteTotal - obj.agreeTotal) * 10_000 / votes) > 10_000 - passRate) { // test rejectRate
				obj.isClose = true;
				obj.isAgree = false; // complete
			}
		}

		if (obj.isClose) {
			emit Close(id);
			if (tryExecute && obj.isAgree) {
				execute(id);
			}
		}
	}

	/**
	 * @dev Execute proposal resolution
	 */
	function execute(uint256 id) public {
		Proposal storage obj = proposal(id);

		if (!obj.isAgree) revert ProposalNotPassed();
		require(!obj.isExecuted, "#VotePool.execute Resolution has been implemented");

		if (obj.loopCount != 0) {
			require(obj.executeTime + obj.loopTime < block.timestamp, "#VotePool.execute Execution interval is too short");
			if (obj.loopCount > 0) {
				exec(obj);
				obj.loopCount--;
			} else { // permanent loop
				exec(obj);
			}
		} else { // execute once
			exec(obj);
			obj.isExecuted = true;
		}

		obj.executeTime = block.timestamp;

		emit Execute(id);
	}

	/**
	 * @dev Execute proposal resolution, internal methods
	 */
	function exec(Proposal storage obj) internal {
		for (uint256 i = 0; i < obj.target.length; i++) {
			(bool suc, bytes memory _data) = obj.target[i].call{ value: msg.value }(obj.data[i]);
			assembly {
				let len := mload(_data)
				let data := add(_data, 0x20)
				switch suc
				case 0 { revert(data, len) }
				default {
					// return(data, len)
				}
			}
		}
	}

	/**
	 * @dev Returns the total of Proposal object
	 */
	function total() view public returns (uint256) {
		return _proposalList.length;
	}

	/**
	 * @dev Returns the Proposal object from index
	 */
	function indexAt(uint256 index) view public returns (Proposal memory pro) {
		require(index < _proposalList.length, "#VotePool#at Index out of bounds");
		pro = _proposalMap[_proposalList[index]];
	}

}