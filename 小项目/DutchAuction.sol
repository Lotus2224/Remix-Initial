// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC721.sol";

// 荷兰拍卖
contract DutchAuction {
    uint private constant DURATION = 7 days; // 持续时间

    IERC721 public immutable nft; // 不变量
    uint public immutable nftId; // 一个nft地址下的一个nftId

    address payable  public immutable seller; // 卖方
    uint public immutable startingPrice; // 起拍价格
    uint public immutable startAt; // 拍卖开始时间
    uint public immutable expiresAt; // 拍卖过期时间
    uint public immutable discountRate; // 每秒折扣率

    constructor(uint _startingPrice, uint _discountRate, address _nft, uint _nftId) {
        require(_startingPrice >= _discountRate * DURATION, "starting price < discount");
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        nft = IERC721(_nft);
        nftId = _nftId;

        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;
    }

    // 获取当前价格
    function getPrice() public view returns (uint) {
        uint timeElapsed = block.timestamp - startAt; // 流失时间
        uint discount = discountRate * timeElapsed; // 折扣价格
        return startingPrice - discount;
    }

    // 购买函数
    function buy() external payable {
        require(block.timestamp < expiresAt, "auction expired"); // 拍卖已到期
        uint price = getPrice();
        require(msg.value >= price, "ETH < price"); // 你的出价 < 当前商品的价格
        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price; // 退款
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        selfdestruct(seller); // 自毁合约，将销售的主币发送给seller卖家
    }
}