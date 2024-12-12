// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// Abi解码

contract AbiDecode {
    struct MyStruct {
        string name;
        uint[2] nums;
    }

    // abi编码
    function encode(uint x, address addr, uint[] calldata arr, MyStruct calldata myStruct) external pure returns (bytes memory) {
        return abi.encode(x, addr, arr, myStruct);
    }

    // abi解码
    function decode(bytes calldata data) external pure returns (uint x, address addr, uint[] memory arr, MyStruct memory myStruct) {
        (x, addr, arr, myStruct) = abi.decode(data, (uint, address, uint[], MyStruct));
    }
}