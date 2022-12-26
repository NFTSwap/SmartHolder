
pragma solidity >=0.6.0 <=0.8.15;

// 所有需要实现升级的合约都应该继承此`Upgrade`合约,并且应该是首要第一个继承的父类
contract Upgrade {
	address internal _impl; // impl address
}

// 这里的上下文是对外部暴露的合约实体只用来存储数据,实现的业务逻辑应该放到impl中
// 调用此合约的任何方法都会被导向`fallback()`中,然后使用`delegatecall()`调用实际实现并把当前数据上下文传递给impl
contract ContextProxy is Upgrade {
	// 这里分配的大小应该是动态编译指定,需从原始合约读取存储大小
	// ... storage ...
	// ...............

	constructor(address impl) public {
		require(impl != address(0));
		_impl = impl;
	}

	fallback() external payable {
		require(_impl != address(0), "Proxy call not implemented");
		(bool suc, bytes memory _data) = _impl.delegatecall(msg.data);
		assembly {
			let len := mload(_data)
			let data := add(_data, 0x20)
			switch suc
			case 0 { revert(data, len) }
			default { return(data, len) }
		}
	}
}