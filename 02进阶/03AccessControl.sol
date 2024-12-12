// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// 权限控制合约，控制访问的
contract AccessControl {

    // 定义两个事件，用于记录哪些账户地址被赋予了角色权限
    // Tips：当我们修改了状态变量的值，就需要事件来向链外汇报我们做出的修改。定义事件event，触发事件emit
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);

    // 映射，role => account => bool，角色 => 账户地址 => 判断账户地址是否具有该角色权限
    mapping(bytes32 => mapping(address => bool)) public roles;

    // 定义两个角色常量，常量constant
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN")); // 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 private constant USER = keccak256(abi.encodePacked("USER")); // 0x2db9fd3d099848027c2383d0a083396f6c41510d7acfd92adc99b6cffcf31e96

    // 定义一个修饰器modifier，用于运行函数前的检查，判断当前用户是否角色权限，not authorized 未授权
    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "not authorized");
        _;
    }

    // 定义构造器，给部署合约的account账户，ADMIN管理员权限
    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    // 内部赋予角色的函数，不需要校验
    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    // 外部赋予角色的函数，需要校验
    function grantRole(bytes32 _role, address _account) external onlyRole(ADMIN) {
        _grantRole(_role, _account);
    }

    // 移出account role权限
    function revokeRole(bytes32 _role, address _account) external onlyRole(ADMIN) {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }
}