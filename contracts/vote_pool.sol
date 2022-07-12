
pragma solidity ^0.8.15;

import "./dao.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract VotePool is ERC165 {
	using Address for address;
	using SafeMath for uint256;

	struct Proposal {
		uint256 id;
		string name;
		string info;
		address target; // 目标合约
		uint256 lifespan; // 投票生命周期
		uint256 expiry; // 过期时间
		uint256 voteRate; // 投票率不小于全体票数50%
		uint256 passRate; // 通过率不小于全体票数50%
		int256  loop; // 执行循环次数
		uint256 loopTime; // 执行循环间隔时间
		uint256 voteTotal; // 投票总数
		uint256 passTotal; // 通过总数
		uint256 executeTime; // 上次执行的时间
		uint256 idx;
		bool isAdopt; // 是否通过采用
		bool isClose; // 投票是否截止
		bool isExecuted; // 是否已执行完成
		bytes1[] data; // 调用方法与实参
	}

	/*
	 * bytes4(keccak256('initVotePool(string,string,address,address,address,address,address,address)')) == 0xf41fe906
	 */
	bytes4 public constant ID = 0xb3ab15fb;

	// define events
	event Created(uint256);
	event Vote(uint256 indexed id, uint256 member, int256 votes);
	event Close(uint256 id);
	event Execute(uint256 indexed id);

	// define props
	DAO internal host;
	string public info;
	int256 public current; // 当前执行的提案决议
	// proposal id => Proposal
	mapping(uint256 => Proposal) private _proposals; // 提案决议列表
	uint256[] private _proposalList; // 提案列表索引
	// proposal id => map( member id => votes )
	mapping(uint256 => mapping(uint256 => int256)) private _votes; // 成员投票记录

	function initVotePool(address host_, string memory info_) external {
		initERC165();
		_registerInterface(ID);

		DAO(host_).checkInterface(DAO.ID, "#Department#initVotePool dao host type not match");
		host = host_;
		info = info_;
	}

	function getProposal(uint256 id) view public returns (Proposal memory) {
		return _proposal(id);
	}

	function proposal(uint256 id) private returns (Proposal storage) {
		require(exists(id), "#VotePool#proposal proposal not exists");
		return _proposals[id];
	}

	function exists(uint256 id) view public returns (bool) {
		return _proposals[id].idx < _proposalList.length;
	}

	function create(Proposal memory proposal) external {

		require(!exists(proposal.id), "#VotePool#create proposal already exists");

		require(proposal.voteRate > 5000, "#VotePool#create proposal vote rate not less than 50%");
		require(proposal.passRate > 5000, "#VotePool#create proposal vote rate not less than 50%");
		require(host.member.tokenOfOwnerByIndex(msg.sender, 0), "#VotePool#create No call permission");

		Proposal storage obj = _proposals[id];

		if (proposal.loop != 0) {
			require(proposal.loopTime >= 1 minutes, "#VotePool#create Loop time must be greater than 1 minute");
		}

		obj.id = proposal.id;
		obj.name = proposal.name;
		obj.info = proposal.info;
		obj.target = proposal.target;
		// obj.signature = proposal.signature;
		obj.data = proposal.data;
		obj.lifespan = proposal.lifespan;
		obj.expiry = block.timestamp + (proposal.lifespan * 1 minutes);
		obj.voteRate = proposal.voteRate > 10000 ? 10000: proposal.voteRate;
		obj.passRate = proposal.passRate > 10000 ? 10000: proposal.passRate;
		obj.loop = proposal.loop;
		obj.loopTime = proposal.loopTime;
		obj.voteTotal = 0;
		obj.passTotal = 0;
		obj.executeTime = 0;
		obj.idx = _proposalList.length;
		obj.isAdopt = false;
		obj.isClose = false;
		obj.isExecuted = false;

		_proposalList.push(proposal.id);

		emit Created(proposal.id);
	}

	function test(Proposal memory proposal) view external {
		proposal.target.call{ value: msg.value }(proposal.data);
	}

	function abs(int256 value) view public returns (uint256) {
		return value < 0 ? uint256(-value): uint256(value);
	}

	function vote(uint256 id, uint256 member, int256 votes) external {
		Proposal storage obj = proposal(id);
		Member.Info memory info = host.member.info(member);

		require(votes == 0, "#VotePool#vote parameter error, votes==0");
		require(!pro.isClose, "#VotePool#vote Voting has been closed");
		require(host.member.ownerOf(member) == msg.sender, "#VotePool#vote No call permission");
		require(_votes[id][member] == 0, "#VotePool#vote Cannot vote repeatedly");
		require(abs(votes) <= info.votes, "#VotePool#vote Voting limit");

		_votes[id][member] = votes;

		obj.voteTotal += abs(votes);

		if (votes > 0) {
			obj.adoptTotal += uint256(votes);
		}

		emit Vote(id, member, votes);

		tryClose(id); // try close
	}

	/**
	* @dev try close proposal
	*/
	function tryClose(uint256 id) public {
		Proposal storage obj = proposal(id);

		require(!pro.isClose, "#VotePool#tryClose Voting has been closed");

		uint256 votes = host.member.votes();

		// is expiry
		if (obj.expiry && obj.expiry < block.timestamp) {
			obj.isClose = true; //
		} else {
			if (obj.voteTotal * 10000 / votes > obj.voteRate) { // test voteTotal
				if (obj.passTotal * 10000 / votes > obj.passRate) { // test passTotal
					// complete
					obj.isClose = true;
					pro.isAdopt = true;
				}
			}
		}

		if (obj.isClose) {
			emit Close(id);
		}
	}

	function execute(uint256 id) public {
		Proposal storage obj = proposal(id);

		require(pro.isAdopt, "#VotePool#execute Proposal was not passed");
		require(!pro.isExecuted, "#VotePool#execute Resolution has been implemented");

		if (pro.loop != 0) {
			require(obj.executeTime + obj.loopTime < block.timestamp, "#VotePool#execute Execution interval is too short");
			if (pro.loop > 0) {
				exec(obj);
				pro.loop--;
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

	function exec(Proposal storage obj) internal {
		obj.target.call{ value: msg.value }(obj.data);
	}

	function total() view public returns (uint256) {
		return _proposalList.length;
	}

}