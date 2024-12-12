// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 通过合约部署合约，使用new 或者 内联汇编 或 create2

// 测试合约1
contract TestContract1 {
    address public owner = msg.sender;

    function setOwner(address _owner) public {
        require(msg.sender == owner, "not owner");
        owner = _owner;
    }
}

// 测试合约2
contract TestContract2 {
    address public owner = msg.sender;
    uint public value = msg.value;
    uint public x;
    uint public y;

    constructor(uint _x, uint _y) payable {
        x = _x;
        y = _y;
    }
}

// 代理合约1，通过合约部署合约，new 合约名()
// 硬编码，假如想部署其它合约，需要修改代码，重新部署
contract Proxy1 {
    function deploy() external payable {
        new TestContract1();
    }
}

contract Proxy2 {
    event Deploy(address);

    // 接收以太币的函数
    receive() external payable {}

    // 回退函数接受主币，fallback{}的后面 不能加;分号
    fallback() external payable {}

    // 部署函数
    function deploy(bytes memory _code) external payable returns (address addr) {
        // 内联汇编，内部 和 assembly{}的后面 不能加;分号
        assembly {
            // create(v, p, n)
            // v = amount of ETH to send，部署合约发送以太坊主币的数量
            // p = pointer in memory to start of code，内存中机器码开始的位置
            // n = size of code，内存中机器码的大小
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }
        require(addr != address(0), "deploy failed");
        emit Deploy(addr); // 向链外汇报
    }

    // 执行函数
    // _target 测试合约1 的地址
    // _data TestContract1的setOwner函数加上参数打包之后的16进制编码
    function execute(address _target, bytes memory _data) external payable {
        (bool success, ) = _target.call{value: msg.value}(_data);
        require(success, "failed");
    }
}

// 助手合约
contract Helper {
    // 部署测试合约1 TestContract1
    function getBytecode1() external pure returns (bytes memory) {
        // 得到部署合约所需要的机器码bytecode，type(合约名称).creationCode
        bytes memory bytecode = type(TestContract1).creationCode;
        return bytecode;
    }

    // 部署测试合约2 TestContract2，内部有 有参的构造函数，所以这是有参数的函数
    function getBytecode2(uint _x, uint _y) external pure returns (bytes memory) {
        bytes memory bytecode = type(TestContract2).creationCode;
        // 构造函数的参数就连接在机器码bytecode后面的一串16进制数字
        // 通过打包的方式abi.encodePacked()，连接在bytecode之后，形成新的bytecode
        return abi.encodePacked(bytecode, abi.encode(_x, _y));
    }

    // 设置管理员的函数，丢进我们自己的地址，让助手合约帮我们打包参数
    function getCalldata(address _owner) external pure returns (bytes memory) {
        return abi.encodeWithSignature("setOwner(address)", _owner);
    }
}
// 部署合约所需要的机器码code
// 调用合约所需要的操作码