// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 多重调用（多重呼叫），同时调用 多个合约中的多个函数，同一个区块调用

contract MultiCall {
    function multiCall(address[] calldata targets, bytes[] calldata data) external view returns (bytes[] memory results) {
        require(targets.length == data.length, "target length != data lenget");
        results = new bytes[](data.length);

        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].staticcall(data[i]);
            require(success, "call failed");
            results[i] = result;
        }
    }
}

contract TestMultiCall {
    function func1() external view returns (uint, uint) {
        return (1, block.timestamp);
    }

    function func2() external view returns (uint, uint) {
        return (2, block.timestamp);
    }

    // 获取函数1的data
    function getData1() external pure returns (bytes memory) {
        // return abi.encodeWithSignature("func1()");
        return abi.encodeWithSelector(this.func1.selector);
    }

    // 获取函数2的data
    function getData2() external pure returns (bytes memory) {
        // return abi.encodeWithSignature("func2()");
        return abi.encodeWithSelector(this.func2.selector);
    }
}

// ["0xd2a5bC10698FD955D1Fe6cb468a17809A08fd005","0xd2a5bC10698FD955D1Fe6cb468a17809A08fd005"]
// ["0x74135154","0xb1ade4db"]