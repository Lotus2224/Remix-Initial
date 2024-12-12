// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// 自毁合约 selfdestruct，self destruct 自我销毁
// 1. 删除合约，delete contract
// 2. 强制发送主币到一个地址，force send Ether to any address

contract Kill {
    // 因为当前的Kill合约没有主币，所以定义一个构造函数来接受主币
    constructor() payable {}

    // 自毁函数kill()，用于销毁当前合约Kill，然后将Kill合约中的Ether send to msg.sender
    function kill() external {
        selfdestruct(payable(msg.sender));
    }

    // 测试函数，用于排查当前Kill合约是否自毁成功
    function testCall() external pure returns (uint) {
        return 123;
    }
}

contract Helper {

    // 测试函数，用于查看当前函数的主币余额
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    // 传入Kill合约的地址，然后调用Kill合约中的kill()函数，自毁Kill合约，然后将Kill合约的Ether强制发送到Helper合约中，可以用getBalance()函数来查看是否发送成功
    function kill(Kill _kill) external {
        _kill.kill();
    }
}