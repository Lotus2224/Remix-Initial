// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 时间锁合约

contract TimeLock {
    address public owner;
    mapping(bytes32 => bool) public queued; // 判断txId是否存在
    uint public constant MIN_DELAY = 10; // 最小延迟
    uint public constant MAX_DELAY = 1000; // 最大延迟
    uint public constant GRACE_PERIOD = 100; // 宽限期

    error NotOwnerError(); // 不是所有者错误
    error AlreadyQueuedError(bytes32 txId); // 已存在队列中错误
    error NotQueuedError(bytes32 txId); // 不存在队列中错误
    error TimestampNotInRangeError(uint blockTimestamp, uint timestamp); // 时间戳不在范围内错误
    error TimestampNotPassedError(uint blockTimestamp, uint timestamp); // 时间戳未通过错误
    error TimestampExpiredError(uint blockTimestamp, uint expiresAt); // 时间戳过期错误
    error TxFailedError(); // 发送失败错误

    event Queue(bytes32 indexed txId, address indexed target, uint value, string func, bytes data, uint timestamp); // 队列事件
    event Execute(bytes32 indexed txId, address indexed target, uint value, string func, bytes data, uint timestamp); // 执行事件
    event Cancel(bytes32 indexed txId); // 取消事件

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwnerError();
        }
        _;
    }

    // 获得交易Id
    function getTxId(address _target, uint _value, string calldata _func, bytes calldata _data, uint _timestamp) public pure returns (bytes32 txId) {
        return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
    }

    // 队列函数
    // _target被部署的合约地址，_value是主币数量，_func函数名称，_data输入参数，_timestamp执行函数的时间
    function queue(address _target, uint _value, string calldata _func, bytes calldata _data, uint _timestamp) external onlyOwner {
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }
        if (_timestamp < block.timestamp + MIN_DELAY || _timestamp > block.timestamp + MAX_DELAY) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }

        queued[txId] = true;
        emit Queue(txId, _target, _value, _func, _data, _timestamp);
    }

    // 执行函数
    // _target被部署的合约地址，_value是主币数量，_func函数名称，_data输入参数，_timestamp执行函数的时间
    function execute(address _target, uint _value, string calldata _func, bytes calldata _data, uint _timestamp) external payable onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }
        if (block.timestamp <  _timestamp) {
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(block.timestamp, _timestamp + GRACE_PERIOD);
        }

        queued[txId] = false;
        bytes memory data;
        // 底层调用的编码，对函数名称_func 和 输入参数_data 进行编码
        // 把函数名称编码成bytes4，4位的哈希值，然后后面加上输入的参数_data
        if (bytes(_func).length > 0) { // 证明调用的是一个方法，而不是一个回退函数
            data = abi.encodePacked(
                bytes4(keccak256(bytes(_func))), _data
            );
        } else { // 回退函数
            data = _data;
        }
        (bool success, bytes memory res) = _target.call{value: _value}(data);
        if (!success) {
            revert TxFailedError();
        }
        emit Execute(txId, _target, _value, _func, _data, _timestamp);
        return res;
    }

    // 取消函数
    function cancel(bytes32 _txId) external onlyOwner {
        if (!queued[_txId]) {
            revert NotQueuedError(_txId);
        }
        queued[_txId] = false;
        emit Cancel(_txId);
    }
}

contract TestTimeLock {
    address public timeLock;

    constructor(address _timeLock) {
        timeLock = _timeLock;
    }

    function test() external payable {
        require(msg.sender == timeLock);
    }

    function getTimestamp() external view returns (uint) {
        return block.timestamp + 20;
    }
}