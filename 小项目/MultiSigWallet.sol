// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// 多签钱包
// 必须在合约中有多个签名人同意的情况下，才能将合约的主币向外转出
// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db]
// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB，给这个账户地址转钱
contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount); // 存款事件
    event Submit(uint indexed txIndex); // 提交交易申请事件
    event Approve(address indexed owner, uint indexed txIndex); // 批准事件，由合约中的多个签名人进行多次批准
    event Revoke(address indexed owner, uint indexed txIndex); // 撤销批准，交易没有被提交之前，可以撤销批准
    event Execute(uint indexed txIndex); // 执行交易Transaction(TX)

    address[] public owners; // owner集合，签名人集合
    mapping(address => bool) public isOwner; // 判断是否为签名人
    uint public required; // 最少确认数

    // 结构体
    struct Transaction {
        address to; // 交易发送的目标地址
        uint value; // 交易发送的主币数量
        bytes data; // 交易地址假如是合约地址，那么还可以执行合约中的函数
        bool executed; // 交易是否执行成功
    }

    Transaction[] public transactions; // 合约中的所有交易，其数组值就是交易的id号
    mapping(uint => mapping(address => bool)) public approved; // 交易号 -> 签名人 -> 是否批准交易（ tx index => owner => bool）

    // 构造函数，签名人集合、最小确认数
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid required number of owners");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner"); // 签名人地址为0地址，无效地址
            require(!isOwner[owner], "owner is not unique"); // 签名人已存在
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    // 判断是否为签名人
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner"); // 不是签名人
        _;
    }

    // 判断交易是否存在，交易号存在才可以
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist"); // 现在只有一笔交易，交易号=0 < 1，可以执行
        _;
    }

    // 判断当前账户是否批准过当前交易
    modifier notApproved(uint _txIndex) {
        require(!approved[_txIndex][msg.sender], "tx already approved"); // 交易已批准
        _;
    }

    // 判断当前交易是否没有被执行过
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    // 让合约可以接受主币，定义回调函数receive()
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // 提交交易
    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1); // 当推入一笔Tx之后，Tx长度为1，索引从0开始
    }

    // 批准
    function approve(uint _txIndex) external onlyOwner txExists(_txIndex) notApproved(_txIndex) notExecuted(_txIndex) {
        approved[_txIndex][msg.sender] = true;
        emit Approve(msg.sender, _txIndex);
    }

    // 撤销批准
    function revoke(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(approved[_txIndex][msg.sender], "tx not approved"); // 交易没有批准
        approved[_txIndex][msg.sender] = false;
        emit Revoke(msg.sender, _txIndex);
    }

    // 执行交易
    function execute(uint _txIndex) external txExists(_txIndex) notExecuted(_txIndex) {
        require(_getApprovalCount(_txIndex) >= required, "approvals < required"); // 批准数量 < 数量
        Transaction storage transaction = transactions[_txIndex];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed"); // 交易失败
        emit Execute(_txIndex);
    }

    // 计算当前批准的人数(内部函数)
    function _getApprovalCount(uint _txIndex) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved[_txIndex][owners[i]]) {
                count += 1;
            }
        }
    }
}

// // 给多签钱包转钱的合约
// contract {
    
// }