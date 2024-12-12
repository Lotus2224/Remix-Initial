// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Owanable {
    address public owner; // 所有者

    // 构造函数
    constructor() {
        owner = msg.sender;
    }

    // 函数修改器
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // 修改所有者
    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "invalid address"); // invalid address 无效的地址
        owner = _newOwner;
    }

    // 只能给当前所有者调用的方法
    function onlyOwnerCanCall() external onlyOwner {
        // code
    }

    // 能给所有人调用的方法
    function anyOneCanCall() external {
        // code
    }
}

