
pragma solidity >=0.6.0 <=0.8.15;

pragma experimental ABIEncoderV2;

import "./Interface.sol";
import "./ERC165.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

contract VotePool is IVotePool, ERC165 {
	using Address for address;
	using SafeMath for uint256;

	bytes4 internal constant DAO_ID = 0xc7b55336;
	bytes4 internal constant VotePool_ID = 0x0ddf27bf;

	// define events
	event Created(uint256);
	event Vote(uint256 indexed id, uint256 member, int256 votes);
	event Close(uint256 id);
	event Execute(uint256 indexed id);

	// define props
	IDAO private _host;
	string private _describe;
	uint256 private _current; // 当前执行的提案决议
	// proposal id => Proposal
	mapping(uint256 => Proposal) private _proposalMap; // 提案决议列表
	uint256[] private _proposalList; // 提案列表索引
	// proposal id => map( member id => votes )
	mapping(uint256 => mapping(uint256 => int256)) private _votes; // 成员投票记录

	function initVotePool(address host, string memory describe) external {
		initERC165();
		_registerInterface(VotePool_ID);

		IDAO(host).checkInterface(DAO_ID, "#Department#initVotePool dao host type not match");
		_host = IDAO(host);
		_describe = describe;
	}

	function host() view external returns (IDAO) {
		return _host;
	}

	function describe() view external returns (string memory) {
		return _describe;
	}

	function current() view public returns (uint256) {
		return _current;
	}

	function getProposal(uint256 id) view public returns (Proposal memory) {
		require(exists(id), "#VotePool#proposal proposal not exists");
		return _proposalMap[id];
	}

	function proposal(uint256 id) private returns (Proposal storage) {
		require(exists(id), "#VotePool#proposal proposal not exists");
		return _proposalMap[id];
	}

	function exists(uint256 id) view public returns (bool) {
		return _proposalMap[id].idx < _proposalList.length;
	}

	function create(Proposal memory proposal) external {

		require(!exists(proposal.id), "#VotePool#create proposal already exists");

		require(proposal.voteRate > 5000, "#VotePool#create proposal vote rate not less than 50%");
		require(proposal.passRate > 5000, "#VotePool#create proposal vote rate not less than 50%");
		require(_host.member().tokenOfOwnerByIndex(msg.sender, 0) != 0, "#VotePool#create No call permission");

		Proposal storage obj = _proposalMap[proposal.id];

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
		obj.agreeTotal = 0;
		obj.executeTime = 0;
		obj.idx = _proposalList.length;
		obj.isAgree = false;
		obj.isClose = false;
		obj.isExecuted = false;

		_proposalList.push(proposal.id);

		emit Created(proposal.id);
	}

	function abs(int256 value) pure internal returns (uint256) {
		return value < 0 ? uint256(-value): uint256(value);
	}

	function vote(uint256 id, uint256 member, int256 votes) external {
		Proposal storage obj = proposal(id);
		IMember.Info memory info = _host.member().getInfo(member);

		require(votes == 0, "#VotePool#vote parameter error, votes==0");
		require(!obj.isClose, "#VotePool#vote Voting has been closed");
		require(_host.member().ownerOf(member) == msg.sender, "#VotePool#vote No call permission");
		require(_votes[id][member] == 0, "#VotePool#vote Cannot vote repeatedly");
		require(abs(votes) <= info.votes, "#VotePool#vote Voting limit");

		_votes[id][member] = votes;

		obj.voteTotal += abs(votes);

		if (votes > 0) {
			obj.agreeTotal += uint256(votes);
		}

		emit Vote(id, member, votes);

		tryClose(id); // try close
	}

	/**
	* @dev try close proposal
	*/
	function tryClose(uint256 id) public override {
		Proposal storage obj = proposal(id);

		require(!obj.isClose, "#VotePool#tryClose Voting has been closed");

		uint256 votes = _host.member().votes();

		// is expiry
		if (obj.expiry != 0 && obj.expiry < block.timestamp) {
			obj.isClose = true; //
		} else {
			if (obj.voteTotal * 10000 / votes > obj.voteRate) { // test voteTotal
				if (obj.agreeTotal * 10000 / votes > obj.agreeTotal) { // test agreeTotal
					// complete
					obj.isClose = true;
					obj.isAgree = true;
				}
			}
		}

		if (obj.isClose) {
			emit Close(id);
		}
	}

	function execute(uint256 id) public {
		Proposal storage obj = proposal(id);

		require(obj.isAgree, "#VotePool#execute Proposal was not passed");
		require(!obj.isExecuted, "#VotePool#execute Resolution has been implemented");

		if (obj.loop != 0) {
			require(obj.executeTime + obj.loopTime < block.timestamp, "#VotePool#execute Execution interval is too short");
			if (obj.loop > 0) {
				exec(obj);
				obj.loop--;
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
		_current = obj.id;
		obj.target.call{ value: msg.value }(obj.data);
		_current = 0;
	}

	function total() view public returns (uint256) {
		return _proposalList.length;
	}

}