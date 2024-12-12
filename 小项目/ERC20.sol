// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.21;

import "./IERC20.sol";

// ERC20同质化代币
contract ERC20 is IERC20 {
    // 账户余额(balanceOf())
    mapping(address => uint256) public override balanceOf;

    // 授权转账额度(allowance())
    mapping(address => mapping(address => uint256)) public override allowance;

    // 代币总供给(totalSupply())
    uint256 public override totalSupply;

    // 代币信息（可选）：名称(name())，代号(symbol())，小数位数(decimals())
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // 转账(transfer())
    function transfer(address to, uint amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // 授权转账(transferFrom())
    // 我给女盆友发钱，然后扣的钱是我爸的钱
    // 我爸    批准额度的账户，扣钱人，sender
    // 我      被批准额度的账户，发钱人，我发钱，但是不扣我自己的钱，扣我爸的钱，spender
    // 女盆友   收钱人，recipient
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool){
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // 授权(approve())
    function approve(address spender, uint amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // 铸造代币函数
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // 销毁代币函数
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }
}