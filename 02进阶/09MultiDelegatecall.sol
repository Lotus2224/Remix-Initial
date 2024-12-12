// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 多重委托调用

contract MultiDelegatecall {
    error DelegatecallFailed();

    function multiDelegatecall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint i; i < data.length; i++) {
            (bool success, bytes memory res) = address(this).delegatecall(data[i]);
            if (!success) {
                revert DelegatecallFailed();
            }
            results[i] = res;
        }
    }
}

// 委托调用合约只能调用自身合约，所以需要继承 is
contract TestMultiDelegatecall is MultiDelegatecall {
    event Log(address caller, string func, uint i);

    function func1(uint x, uint y) external {
        emit Log(msg.sender, "func1", x + y);
    }

    function func2() external returns (uint) {
        emit Log(msg.sender, "func2", 2);
        return 222;
    }

    mapping(address => uint) public balanceOf;

    // 铸造函数，多重委托调用的漏洞
    function mint() external payable {
        balanceOf[msg.sender] += msg.value;
    }
}

contract Helper {
    function getFunc1Data(uint x, uint y) external pure returns (bytes memory) {
        return abi.encodeWithSelector(TestMultiDelegatecall.func1.selector, x, y);
    }

    function getFunc2Data() external pure returns (bytes memory) {
        return abi.encodeWithSelector(TestMultiDelegatecall.func2.selector);
    }

    function getMintData() external pure returns (bytes memory) {
        return abi.encodeWithSelector(TestMultiDelegatecall.mint.selector);
    }
}