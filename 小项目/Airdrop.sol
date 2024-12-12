// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./ERC20.sol";

// 空投合约
contract Airdrop {
    mapping(address => uint) public failTransferList; // 失败传输列表

    // 获取需要发放的token数量
    function getSum(uint256[] calldata _arr) public pure returns (uint sum) {
        uint length = _arr.length;
        for (uint i = 0; i < length; ++i) {
            sum += _arr[i];
        }
    }

    // 发送ERC20代币空投
    // @notice 向多个地址转账ERC20代币，使用前需要先授权
    //
    // @param _token 转账的ERC20代币地址
    // @param _addresses 空投地址数组
    // @param _amounts 代币数量数组（每个地址的空投数量）
    function multiTransferToken(address _token, address[] calldata _addresses, uint256[] calldata _amounts) external {
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        IERC20 token = IERC20(_token); // 声明IERC合约变量
        uint _amountSum = getSum(_amounts); // 计算空投代币总量
        // 检查：检查了空投合约的授权额度大于要空投的代币数量总和。
        require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token"); // 当前用户msg.sender 给当前合约address(this)的授权代币数量 需要大于需要发送的代币数量

        // for循环，利用transferFrom函数发送空投
        uint length = _addresses.length;
        for (uint i; i < length; ++i) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    // 向多个地址转账QM代币
    function multiTransferQM (address payable[] calldata _addresses, uint256[] calldata _amounts) public payable {
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        uint _amountSum = getSum(_amounts); // 计算空投QM总量
        // 检查转入QM等于空投总量
        require(msg.value == _amountSum, "Transfer amount error");
        // for循环，利用transfer函数发送QM
        for (uint256 i = 0; i < _addresses.length; i++) {
            // 防范了DOS攻击
            (bool success, ) = _addresses[i].call{value: _amounts[i]}("");
            if (!success) {
                failTransferList[_addresses[i]] = _amounts[i];
            }
        }
    }
}