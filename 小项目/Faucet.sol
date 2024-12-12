// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./ERC20.sol";

// ERC20代币的水龙头合约
contract Faucet {
    // amountAllowed设定每次能领取代币数量（默认为100，不是一百枚，因为代币有小数位数）。
    uint256 public amountAllowed = 100;

    // tokenContract记录发放的ERC20代币合约地址。
    address public tokenContract;

    // requestedAddress记录领取过代币的地址。
    mapping(address => bool) public requestedAddress;

    // 定义了1个SendToken事件，记录了每次领取代币的地址和数量，在requestTokens()函数被调用时释放
    event SendToken(address indexed Receiver, uint256 indexed amount);

    // 构造函数：初始化tokenContract状态变量，确定发放的ERC20代币地址。
    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    // requestTokens()函数，用户调用它可以领取ERC20代币。
    function requestTokens() external {
        require(!requestedAddress[msg.sender], "Can't Request Multiple Times!"); // 每个地址只能领一次
        IERC20 token = IERC20(tokenContract); // 创建IERC20合约对象
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!"); // 水龙头空了

        token.transfer(msg.sender, amountAllowed); // 发送token
        requestedAddress[msg.sender] = true; // 记录领取地址 
        
        emit SendToken(msg.sender, amountAllowed); // 释放SendToken事件
    }
}