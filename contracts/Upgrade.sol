
pragma solidity >=0.6.0 <=0.8.15;

contract Upgrade {
	address internal _impl; // impl address
}

contract ProxyContext is Upgrade {

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