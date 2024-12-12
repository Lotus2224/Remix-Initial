// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract ArrayTypes {

    // 固定长度 Array
    uint[8] array1;
    bytes1[5] array2;
    address[100] array3;

    // 可变长度 Array
    uint[] array4;
    bytes1[] array5;
    address[] array6;
    bytes array7;

    // 初始化可变长度 Array
    uint[] array8 = new uint[](5);
    bytes array9 = new bytes(9);
    
    //  给可变长度数组赋值
    function initArray() external pure returns(uint[] memory){
        uint[] memory x = new uint[](3);
        x[0] = 1;
        x[1] = 3;
        x[2] = 4;
        return(x);
    }  
    function arrayPush() public returns(uint[] memory){
        uint[2] memory a = [uint(1),2];
        array4 = a;
        array4.push(3);
        return array4;
    }
}