
pragma solidity >=0.6.0 <=0.8.15;

pragma experimental ABIEncoderV2;

import "../openzeppelin/contracts-ethereum-package/contracts/introspection/IERC165.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Metadata.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Enumerable.sol";
import "../openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Receiver.sol";

interface IERC721Lock {
	event Lock(address indexed owner, address indexed locked, uint256 indexed tokenId);
	function lock(address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721LockReceiver {
	function onERC721LockReceived(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC1651 {
	function checkInterface(bytes4 interfaceId, string memory message) view external;
}

interface IERC721_All is IERC721, IERC721Metadata, IERC721Enumerable {}

interface IDepartment is IERC165, IERC1651 {
	function operator() view external returns (IVotePool);
	function setOperator(address vote) external;
	function upgrade(address impl) external;
}

interface IAssetGlobal is IDepartment, IERC721_All, IERC721Receiver, IERC721LockReceiver {
	enum Kind {
		Lock,
		Owner
	}
	struct AssetID {
		address token;
		uint256 tokenId;
		Kind kind;
	}
	function withdraw(uint256 tokenId) external;
	function assetMeta(uint256 tokenId) view external returns (AssetID memory);
	function unlock(address metaToken, uint256 metaTokenId) external;
}

interface IAsset is IDepartment, IERC721_All, IERC721Lock {
	event Lock(uint256 indexed tokenId, address owner, address to);
}

interface ILedger is IDepartment {

	event Receive(address indexed from, uint256 balance);
	event ReleaseLog(address indexed operator, uint256 balance, string log);
	event Deposit(address indexed from, uint256 balance, string name, string description);
	event Withdraw(address indexed target, uint256 balance, string description);
	event Release(uint256 indexed member, address indexed to, uint256 balance);

	function withdraw(uint256 amount, address target, string memory description) external payable;
}

interface IMember is IDepartment, IERC721, IERC721Metadata, IERC721Enumerable {

	enum Role {
		DEFAULT
	}
	struct Info {
		uint256 id;
		string name;
		string description;
		string avatar;
		Role role;
		uint32 votes; // 投票权
		uint256 idx;
		uint256[2] __ext;
	}

	event UpdateInfo(uint256 id);

	function indexAt(uint256 index) view external returns (Info memory);
	function getInfo(uint256 id) view external returns (Info memory);
	function isExists(uint256 id) view external returns (bool);
	function votes() view external returns (uint256);
	function total() view external returns (uint256);
}

interface IVotePool {

	struct Proposal {
		uint256 id; // 随机256位长度id
		string name; // 名称
		string description; // 描述
		address origin; // 发起人 address
		address target; // 目标合约,决议执行合约地址
		uint256 lifespan; // 投票生命周期单位（分钟）
		uint256 expiry; // 过期时间,为0时永不过期
		uint256 passRate; // 通过率不小于全体票数50% 1/10000
		int256  loopCount; // 执行循环次数, -1表示永久定期执行决议
		uint256 loopTime; // 执行循环间隔时间,不等于0时必须大于1分钟,0只执行一次
		uint256 voteTotal; // 投票总数
		uint256 agreeTotal; // 通过总数
		uint256 executeTime; // 上次执行的时间
		uint256 idx; // 
		bool isAgree; // 是否通过采用
		bool isClose; // 投票是否截止
		bool isExecuted; // 是否已执行完成
		bytes data; // 调用方法与实参
	}

	// define events
	event Created(uint256 id);
	event Vote(uint256 indexed id, uint256 member, int256 votes);
	event Close(uint256 id);
	event Execute(uint256 indexed id);

	function tryClose(uint256 id) external;
}

interface IDAO is IDepartment {
	event Change(string tag);
	function root() view external returns (IVotePool);
	function member() view external returns (IMember);
	function ledger() view external returns (ILedger);
	function assetGlobal() view external returns (IAssetGlobal);
	function asset() view external returns (IAsset);
}