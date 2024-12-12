// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// 测试合约
contract TestDelegateCall {
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) external payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

// 委托调用合约
contract DelegateCall {
    uint public num;
    address public sender;
    uint public value;

    // 设置变量的函数
    function setVars(address _test, uint _num) external payable {
        // DelegateCall合约 委托调用 TestDelegateCall合约
        // (bool success, bytes memory data) = _test.delegatecall(
        //     abi.encodeWithSignature("setVars(uint256)", _num)
        // );
        (bool success, bytes memory data) = _test.delegatecall(
            abi.encodeWithSelector(TestDelegateCall.setVars.selector, _num)
        );
        require(success, "delegatecall failded");
    }
}

// 我们这个合约 调用-委托调用合约DelegateCall 的setVars函数，然后函数内部 委托调用-测试合约TestDelegateCall
// A   ->             B                                     ->                   C
// 只能使用被委托调用的合约的逻辑来改变当前合约的内容（使用被调用合约C的逻辑setVars方法，来改变当前合约DelegateCall的状态变量）




