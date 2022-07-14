
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

interface IAssetGlobal is IERC721_All, IERC721Receiver, IERC721LockReceiver, IDepartment {
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

interface IAsset is IERC721_All, IERC721Lock, IDepartment {
	event Lock(uint256 indexed tokenId, address owner, address to);
}

interface ILedger is IDepartment {

	event Receive(address indexed from, uint256 balance);
	event Release(uint256 indexed member, address addr, uint256 balance);
	event Withdraw(address indexed target, uint256 balance);

	function withdraw(uint256 amount, address target) external payable;
}

interface IMember is IERC721, IERC721Metadata, IERC721Enumerable, IDepartment {

	enum Role {
		DEFAULT
	}
	struct Info {
		uint256 id;
		string name;
		string info;
		string avatar;
		Role role;
		uint32 votes; // 投票权
		uint256 idx;
		uint256[2] __ext;
	}

	function indexAt(uint256 index) view external returns (Info memory);
	function getInfo(uint256 id) view external returns (Info memory);
	function exists(uint256 id) view external returns (bool);
	function votes() view external returns (uint256);
	function total() view external returns (uint256);
}

interface IVotePool {

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
		uint256 agreeTotal; // 通过总数
		uint256 executeTime; // 上次执行的时间
		uint256 idx;
		bool isAgree; // 是否通过采用
		bool isClose; // 投票是否截止
		bool isExecuted; // 是否已执行完成
		bytes data; // 调用方法与实参
	}

	function tryClose(uint256 id) external;
}

interface IDAO is IDepartment {
	function root() view external returns (IVotePool);
	function member() view external returns (IMember);
	function ledger() view external returns (ILedger);
	function assetGlobal() view external returns (IAssetGlobal);
	function asset() view external returns (IAsset);
}