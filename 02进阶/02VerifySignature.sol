// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// 验证签名，VerifySignature
contract VerifySig {
    
    function verify(address _signer, string memory _message, bytes memory _sig) external pure  returns (bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recover(ethSignedMessageHash, _sig) == _signer;
    }

    // 对消息进行哈希运算
    function getMessageHash(string memory _message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    // 对哈希运算之后的消息进行链下的哈希运算（加上\x19Ethereum Signed Message:\n32）
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            _messageHash
        ));
    }

    // 恢复
    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // 分割，bytes类型的数据，前32字节（第0到第31字节）是存储数组的长度，后续的内容才是数据本身
    function _split(bytes memory _sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) { // returns 有隐式返回【return (r, s, v)】
        require(_sig.length == 65, "invalid signature length");

        assembly {
            // mload，从内存中加载数据
            r := mload(add(_sig, 32)) // add(_sig, 32) 跳过32字节，因为前面32字节是用于存储数据长度的，然后读取32字节的内容
            s := mload(add(_sig, 64)) // add(_sig, 64) 跳过64字节，（，0~31 存储数据长度，32~63 r的内容，64~95 s的内容），然后读取32字节的内容
            v := byte(0, mload(add(_sig, 96))) // add(_sig, 96) 跳过96字节，读取后续的32字节的内容。byte(0, xxx)，表示只要xxx中的第一个字节的内容，就是8比特的内容，也就是uint8
        }

        // return (r, s, v)
    }
}