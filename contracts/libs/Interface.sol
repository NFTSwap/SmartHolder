//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

pragma experimental ABIEncoderV2;

import '../../openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../../openzeppelin/contracts/token/ERC20/IERC20.sol'; // 20
import '../../openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../../openzeppelin/contracts/token/ERC721/IERC721.sol'; // 721
import '../../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '../../openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '../../openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import "../../openzeppelin/contracts/token/ERC1155/IERC1155.sol"; // 1155
import "../../openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../../openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import '../../openzeppelin/contracts/utils/math/SafeMath.sol';
import '../../openzeppelin/contracts/utils/structs/EnumerableMap.sol';

/**
 * @dev IERC20_1 extend IERC20
 */
interface IERC20_1 is IERC20, IERC20Metadata {
	function indexAt(uint256 index) external view returns (address, uint256);
	function totalOwners() external view returns (uint256);
}

/**
 * @dev IERC721_1 extend ERC721
 */
interface IERC721_1 is IERC721, IERC721Metadata, IERC721Enumerable {
	function exists(uint256 tokenId) external view returns (bool);
}

/**
 * @dev IERC1155_1 extend IERC1155
 */
interface IERC1155_1 is IERC1155, IERC1155MetadataURI {
	function totalSupply(uint256 id) external view returns (uint256);
	function exists(uint256 id) external view returns (bool);
}

interface IOpenseaContractURI {
	function contractURI() external view returns (string memory);
}

// DAO interfaces

interface IModule is IERC165 {
	event Change(uint256 indexed tag, uint256 value);
	function operator() view external returns (address);
	function setDescription(string memory description) external;
	function setOperator(address operator) external;
	function upgrade(address impl) external;
}

interface IAssetShell is IModule, IERC1155_1, IERC1155Receiver {
	struct AssetID {
		address token;
		uint256 tokenId;
	}
	enum SaleType {
		kDefault,
		kFirst,
		kSecond
	}
	function withdraw(uint256 tokenId, address owner, uint256 amount) external;
	function assetMeta(uint256 tokenId) view external returns (AssetID memory);
}

interface IAsset is IModule, IERC1155_1, IOpenseaContractURI {}
interface IShare is IERC20_1 {}

interface ILedger is IModule {
	event Receive(address indexed from, uint256 balance);
	event ReleaseLog(address indexed operator, uint256 balance, string log);
	event Deposit(address indexed from, uint256 balance, string name, string description);
	event Withdraw(address indexed target, uint256 balance, string description);
	event Release(uint256 indexed member, address indexed to, uint256 balance);
	event AssetIncome(
		address indexed token, uint256 indexed tokenId,
		address indexed source, address from, address to,
		uint256 balance, uint256 price, uint256 count,
		IAssetShell.SaleType saleType
	);
	function withdraw(uint256 amount, address target, string memory description) external payable;
	function assetIncome(
		address token, uint256 tokenId,
		address source, address from, address to, uint256 price, uint256 count, IAssetShell.SaleType saleType
	) external payable;
}

interface IMember is IModule, IERC721_1, IOpenseaContractURI {
	struct Info {
		uint256 id;
		string name;
		string description;
		string image;
		uint32 votes; // vote power
	}
	event Update(uint256 indexed id); // update info
	event TransferVotes(uint256 indexed from, uint256 indexed to, uint32 votes);
	event AddPermissions(uint256[] ids, uint256[] actions);
	event RemovePermissions(uint256[] ids, uint256[] actions);
	event SetPermissions(uint256 indexed id, uint256[] addActions, uint256[] removeActions);

	function isPermission(address owner, uint256 action) view external returns (bool);
	function isPermissionFrom(uint256 id, uint256 action) view external returns (bool);
	function indexAt(uint256 index) view external returns (Info memory);
	function getMemberInfo(uint256 id) view external returns (Info memory);
	function votes() view external returns (uint256);
	function total() view external returns (uint256);
}

interface IVotePool {
	struct Proposal {
		uint256   id; // 随机256位长度id
		string    name; // 名称
		string    description; // 描述
		address   origin; // 发起人 address
		uint256   originId; // 发起人成员id (member id),如果为0表示匿名成员
		address[] target; // 目标合约,决议执行合约地址列表
		uint256   lifespan; // 投票生命周期单位（分钟）
		uint256   expiry; // 过期时间,为0时永不过期
		uint256   passRate; // 通过率不小于全体票数50% 1/10000
		int256    loopCount; // 执行循环次数, -1表示永久定期执行决议
		uint256   loopTime; // 执行循环间隔时间,不等于0时必须大于1分钟,0只执行一次
		uint256   voteTotal; // 投票总数
		uint256   agreeTotal; // 通过总数
		uint256   executeTime; // 上次执行的时间
		uint256   idx; //
		bool      isAgree; // 是否通过采用
		bool      isClose; // 投票是否截止
		bool      isExecuted; // 是否已执行完成
		bytes[]   data; // 调用方法与实参列表
	}
	// define events
	event Created(uint256 id);
	event Vote(uint256 indexed id, uint256 member, int256 votes);
	event Close(uint256 indexed id);
	event Execute(uint256 indexed id);

	function exists(uint256 id) view external returns(bool);
	function create(Proposal memory arg0) external;
	function tryClose(uint256 id, bool tryExecute) external;
}

interface IDAO is IModule {
	event SetModule(uint256 indexed id, address addr);
	function root() view external returns (address);
	function member() view external returns (IMember);
	function ledger() view external returns (ILedger);
	function asset() view external returns (IAsset);
	function first() view external returns (IAssetShell);
	function second() view external returns (IAssetShell);
	function share() view external returns (IShare);
	function module(uint256 id) view external returns (IModule);
}

interface IDAOs {
	event Created(address indexed dao);
	function deployShare(
		IDAO host, address operator, string calldata name,
		string calldata symbol, string calldata description
	) external returns (address);
}