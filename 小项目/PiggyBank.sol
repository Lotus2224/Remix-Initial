// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// 小猪存钱罐
contract PiggyBank {
    address public owner = msg.sender; // 合约的部署者

    event Deposit(uint amount); // 存款事件
    event Withdraw(uint amount); // 取款事件

    // 回退函数
    receive() external payable {
        emit Deposit(msg.value);
    }
    
    // 取款函数，将所有的钱发送到合约的部署者中，然后销毁当前PiggyBank合约
    function withdraw() external {
        require(msg.sender == owner, "not owner");
        emit Withdraw(address(this).balance); // address(this).balance 获取当前合约的Ether数量
        selfdestruct(payable(msg.sender)); // 如果使用owner状态变量，则会多消耗gas
    }
}