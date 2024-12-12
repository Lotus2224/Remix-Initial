// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 通过合约部署合约，create2方法

// 被部署的合约，使用create2方法部署
contract DeployWithCreate2 {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

// 工厂合约
contract Create2Factory {
    event Deploy(address addr);

    // 部署合约函数
    function deploy(uint _salt) external {
        DeployWithCreate2 _contract = new DeployWithCreate2{
            salt: bytes32(_salt)
        }(msg.sender);
        emit Deploy(address(_contract));
    }

    // 计算地址
    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                // 常量前缀0xff
                // 工厂合约地址
                // 盐值，bytes32类型，输入参数中而来
                // 被部署合约的机器码bytecode的哈希值
                bytes1(0xff), address(this), _salt, keccak256(bytecode)
            )
        );

        // uint160 是地址的标准格式
        return address(uint160(uint(hash)));
    }

    // 获取bytecode的函数
    function getCalldata(address _owner) external pure returns (bytes memory) {
        bytes memory bytecode = type(DeployWithCreate2).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }
}